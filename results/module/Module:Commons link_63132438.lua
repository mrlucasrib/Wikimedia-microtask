-- Module to find commons galleries and categories based on wikidata entries
local getArgs = require('Module:Arguments').getArgs
local p = {}

-- Check if string is a valid QID
-- Argument: QID to check
-- Returns: valid (bool)
local function _validQID(qid)
	return qid and mw.ustring.find(qid,"^[Qq]%d+$")
end

-- Check if string is a valid wikidata property string
-- Argument: property string to check
-- Returns: valid (bool)
local function _validProp(prop)
	return prop and mw.ustring.find(prop,"^[Pp]%d+$")
end

function _lcfirst(doit,s)
	if doit then
		return mw.ustring.lower(mw.ustring.sub(s,1,1))..mw.ustring.sub(s,2)
	end
	return s
end

local function warning(msg)
  local frame = mw.getCurrentFrame():getParent()
  local html = ""
  if frame:preprocess( "{{REVISIONID}}" ) == "" then 
  	html = '<div style="color:red"><strong>Warning:</strong> '..msg
  	html = html..' <small>(this message is shown only in preview)</small></div>'
  end
  return html
end

-- Get title, namespace, and QID for current page
-- Arguments:
--   qid = testing only: get title of alternative page with QID=qid
--   nsQid = whether to return the ns of the qid page or current
-- Returns:
--   title, namespace (string), qid of current page (or test page)
local function _getTitleQID(qid,nsQid)
	local titleObject = mw.title.getCurrentTitle()
	-- look up qid for current page (if not testing)
	local nsText = mw.ustring.gsub(titleObject.nsText,"_"," ")
	if not _validQID(qid) then
		qid = mw.wikibase.getEntityIdForCurrentPage()
		return titleObject.text, nsText, qid
	end
	-- testing-only path: given a qid, determine title
	-- always use namespace from current page (to suppress tracking cat)
	qid = qid:upper()
	local title = mw.wikibase.getSitelink(qid) or ""
	-- strip any namespace from sitelink
	local firstColon = mw.ustring.find(title,':',1,true)
	local qidNsText = ""
	if firstColon then
		qidNsText = mw.ustring.sub(title,1,firstColon-1)
		title = mw.ustring.sub(title,firstColon+1)
	end
	if nsQid then
		return title, qidNsText, qid
	end
	return title, nsText, qid
end

-- Lookup Commons gallery in Wikidata
-- Arguments:
--   qid = QID of current article
--   fetch = whether to lookup Commons sitelink (bool)
--   commonsSitelink = default value for Commons sitelink
-- Returns:
--   categoryLink = name of Commons category, nil if nothing is found
--   consistent = multiple wikidata fields are examined: are they consistent?
--   commonsSitelink = commons sitelink for current article
local function _lookupGallery(qid,fetch,commonsSitelink)
	if not _validQID(qid) then
		return nil, true, nil
	end
	qid = qid:upper()
	local galleryLink = nil
	local consistent = true
	-- look up commons sitelink for article, use if not category
	if fetch then
		commonsSitelink = mw.wikibase.getSitelink(qid,"commonswiki") or commonsSitelink
	end
	if commonsSitelink and mw.ustring.sub(commonsSitelink,1,9) ~= "Category:" then
		galleryLink = commonsSitelink
	end
	-- P935 is the "commons gallery" property for this article
	local P935 = mw.wikibase.getBestStatements(qid, "P935")[1]
	if P935 and P935.mainsnak.datavalue then
		local gallery = P935.mainsnak.datavalue.value
		if galleryLink and galleryLink ~= gallery then
			consistent = false
		else
			galleryLink = gallery
		end
	end
	return galleryLink, consistent, commonsSitelink
end

-- Find fallback category by looking up Commons sitelink of different page
-- Arguments:
--    qid = QID for current article
--    property = property that refers to other article whose sitelink to return
-- Returns: either category-stripped name of article, or nil
local function _lookupFallback(qid,property)
	if not _validQID(qid) or not _validProp(property) then
		return nil
	end
	qid = qid:upper()
	property = property:upper()
	-- If property exists on current article, get value (other article qid)
	local value = mw.wikibase.getBestStatements(qid, property)[1]
	if value and value.mainsnak.datavalue and value.mainsnak.datavalue.value.id then
		-- Look up Commons sitelink of other article
		local sitelink = mw.wikibase.getSitelink(value.mainsnak.datavalue.value.id,"commonswiki")
		-- Check to see if it starts with "Category:". If so, strip it and return
		if sitelink and mw.ustring.sub(sitelink,1,9) == "Category:" then
			return mw.ustring.sub(sitelink,10)
		end
	end
	return nil
end

-- Find Commons category by looking in wikidata
-- Arguments:
--   qid = QID of current article
--   fetch = whether to lookup Commons sitelink (bool)
--   commonsSitelink = default value for Commons sitelink
-- Returns:
--   categoryLink = name of Commons category, nil if nothing is found
--   consistent = multiple wikidata fields are examined: are they consistent?
--   commonsSitelink = commons sitelink for current article
local function _lookupCategory(qid, fetch, commonsSitelink)
	if not _validQID(qid) then
		return nil, true, nil
	end
	qid = qid:upper()
	local categoryLink = nil
	local consistent = true
	-- look up commons sitelink for article, use if starts with "Category:"
	if fetch then
		commonsSitelink = mw.wikibase.getSitelink(qid,"commonswiki") or commonsSitelink
	end
	if commonsSitelink and mw.ustring.sub(commonsSitelink,1,9) == "Category:" then
		categoryLink = mw.ustring.sub(commonsSitelink,10)
	end
	-- P373 is the "commons category" property for this article
	local P373 = mw.wikibase.getBestStatements(qid, "P373")[1]
	if P373 and P373.mainsnak.datavalue then
		P373 = P373.mainsnak.datavalue.value
		if categoryLink and categoryLink ~= P373 then
			consistent = false
			qid = nil  -- stop searching on inconsistent data
		else
			categoryLink = P373
		end
	end
	-- P910 is the "topic's main category". Look for commons sitelink there
	local fallback = _lookupFallback(qid,"P910")
	if fallback then
		if categoryLink and categoryLink ~= fallback then
			consistent = false
			qid = nil
		else
			categoryLink = fallback
		end
	end
	-- P1754 is the "list's main category". Look for commons sitelink there
	fallback = _lookupFallback(qid,"P1754")
	if fallback then
		if categoryLink and categoryLink ~= fallback then
			consistent = false
		else
			categoryLink = fallback
		end
	end
	return categoryLink, consistent, commonsSitelink
end

-- Does the article have a corresponding Commons gallery?
-- Arguments:
--   qid = QID to lookup in wikidata (for testing only)
-- Returns:
--   filename at Commons if so, nil if not
function p._hasGallery(qid)
	local wp_title, wp_ns
	wp_title, wp_ns, qid = _getTitleQID(qid)
	local galleryLink, consistent = _lookupGallery(qid,true)
	if galleryLink and consistent then
		return galleryLink
	end
	return nil
end

-- Does the article have a corresponding Commons category?
-- Arguments:
--   qid = QID to lookup in wikidata (for testing only)
--   prefix = whether to add "Category:" to return string (default true)
-- Returns:
--   filename at Commons if so, blank if not
function p._hasCategory(qid,prefix)
	if prefix == nil then
		prefix = true
	end
	local wp_title, wp_ns
	wp_title, wp_ns, qid = _getTitleQID(qid)
	local categoryLink, consistent = _lookupCategory(qid,true)
	if categoryLink and consistent then
		if prefix then
			categoryLink = "Category:"..categoryLink
		end
		return categoryLink
	end
	return nil
end

-- Create Commons link corresponding to current article
-- Arguments:
--   namespace = namespace in Commons ("" for galleries)
--   default = use as Commons link, don't access wikidata
--   linktext = text to display in link
--   search = string to search for
--   lcfirst = lower case the first letter in linktext
--   qid = QID to lookup in wikidata (for testing only)
-- Returns:
--   formatted wikilink to Commons in specified namespace
function p._getCommons(namespace,default,linktext,search,lcfirst,qid)
	local nsColon
	if not namespace or namespace == "" then
		nsColon = ""
	else
		nsColon = namespace..":"
	end
	if default then
		return "[[Commons:"..nsColon..default.."|".._lcfirst(lcfirst,linktext or default).."]]"
	end
	if search then
		return "[[Commons:Special:Search/"..nsColon..search.."|".._lcfirst(lcfirst,linktext or search).."]]"
	end
	local wp_title, wp_ns
	wp_title, wp_ns, qid = _getTitleQID(qid)
	-- construct default result (which searches for title)
	local searchResult = "[[Commons:Special:Search/"..nsColon..wp_title.."|".._lcfirst(lcfirst,linktext or wp_title).."]]"
	local commonsLink = nil
	local consistent = true
	if nsColon == "" then
		commonsLink, consistent = _lookupGallery(qid,true)
	elseif namespace:lower() == "category" then
		commonsLink, consistent = _lookupCategory(qid,true)
	end
	-- use wikidata if consistent
	if commonsLink and consistent then
		return "[[Commons:"..nsColon..commonsLink.."|".._lcfirst(lcfirst,linktext or commonsLink).."]]"
	end
	-- if not consistent, fall back to search and add to tracking cat
	if not consistent and wp_ns == "" then
		local friendlyNS
		if nsColon == "" then
			friendlyNS = "gallery"
		else
			friendlyNS = namespace:lower()
		end
		searchResult = searchResult.."[[Category:Inconsistent wikidata for Commons "..friendlyNS.."]]"
	end
	return searchResult
end

-- Returns "best" Commons link: first look for gallery, then try category
-- Arguments:
--   default = use as Commons link, don't access wikidata
--   linktext = text to display in link
--   search = string to search for
--   qid = QID to lookup in wikidata (for testing only)
-- Returns:
--   formatted wikilink to Commons "best" landing page
function p._getGalleryOrCategory(default,linktext,search,qid)
	if default then
		return "[[Commons:"..default.."|"..(linktext or default).."]]"
	end
	if search then
		return "[[Commons:Special:Search/"..search.."|"..(linktext or search).."]]"
	end
	local wp_title, wp_ns
	wp_title, wp_ns, qid = _getTitleQID(qid)
	-- construct default result (which searches for title)
	local searchResult = "[[Commons:Special:Search/"..wp_title.."|"..(linktext or wp_title).."]]"
	local trackingCats = ""
	local galleryLink, consistent, commonsSitelink = _lookupGallery(qid,true)
	-- use wikidata if either sitelink or P935 exist, and they both agree
	if galleryLink and consistent then
		return "[[Commons:"..galleryLink.."|"..(linktext or galleryLink).."]]"
	end
	if not consistent and wp_ns == "" then
		trackingCats = "[[Category:Inconsistent wikidata for Commons gallery]]"
	end
	-- if gallery is not good, fall back looking for category
	local categoryLink
	categoryLink, consistent = _lookupCategory(qid,false,commonsSitelink)
	if categoryLink and consistent then
		return "[[Commons:Category:"..categoryLink.."|"..(linktext or categoryLink).."]]"..trackingCats
	end
	if not consistent and wp_ns == "" then
		trackingCats = trackingCats.."[[Category:Inconsistent wikidata for Commons category]]"
	end
	return searchResult..trackingCats
end

-- Make a string bold, italic, or both
-- Arguments:
--   s = string to format
--   bold = make it bold
--   italic = make it italic
-- Returns:
--   string modified with html tags
local function _formatResult(s,bold,italic)
	local resultVal = ""
	if bold then resultVal = "<b>" end
	if italic then resultVal = resultVal.."<i>" end
	resultVal = resultVal..s
	if italic then resultVal = resultVal.."</i>" end
	if bold then resultVal = resultVal.."</b>" end
	return resultVal
end

-- Return link(s) Commons gallery, or category, or both from wikidata
-- Arguments:
--   defaultGallery = default gallery link to use, instead of wikidata
--   defaultCategory = default category link to use, instead of wikidata
--   categoryText = if both gallery and category, text to use in category link ("category" by default)
--   bold = whether to make first link bold
--   italic = whether to make first link italic
--   qid = qid of page to lookup in wikidata (testing only)
function p._getGalleryAndCategory(defaultGallery,defaultCategory,linkText,categoryText,bold,italic,oneSearch,qid)
	local wp_title, wp_ns
	wp_title, wp_ns, qid = _getTitleQID(qid)
	categoryText = categoryText or "category"
	-- construct default result (which searches for title)
	local searchResult = _formatResult("[[Commons:Special:Search/"..wp_title.."|"..(linkText or wp_title).."]]",bold,italic)
	if not oneSearch then
		searchResult = searchResult.." ([[Commons:Special:Search/Category:"..wp_title.."|"..categoryText.."]])"
	end
	local trackingCats = ""
	local galleryLink, galleryConsistent
	local commonsSitelink = nil
	if defaultGallery then
		galleryLink = defaultGallery
		galleryConsistent = true
	else
		galleryLink, galleryConsistent, commonsSitelink = _lookupGallery(qid,true)
	end
	local galleryGood = galleryLink and galleryConsistent
	if not galleryConsistent and wp_ns == "" then
		trackingCats = "[[Category:Inconsistent wikidata for Commons gallery]]"
	end
	local categoryLink, categoryConsistent
	if defaultCategory then
		categoryLink = defaultCategory
		categoryConsistent = true
	else
		categoryLink, categoryConsistent = _lookupCategory(qid,defaultGallery,commonsSitelink)
	end
	local categoryGood = categoryLink and categoryConsistent
	if not categoryConsistent and wp_ns == "" then
		trackingCats = trackingCats.."[[Category:Inconsistent wikidata for Commons category]]"
	end
	local firstLink
	if galleryGood then
		firstLink = galleryLink
		linkText = linkText or galleryLink
	elseif categoryGood then
		firstLink = "Category:"..categoryLink
		linkText = linkText or categoryLink
	else
		return searchResult..trackingCats
	end
	local resultVal = _formatResult("[[Commons:"..firstLink.."|"..linkText.."]]",bold,italic)
	if galleryGood and categoryGood then
		resultVal = resultVal.." ([[Commons:Category:"..categoryLink.."|"..categoryText.."]])"
	end
	return resultVal..trackingCats
end

-- Compare two titles with their namespaces stripped
local function titleMatch(s1,s2)
	s1 = s1 or ""
	s2 = s2 or ""
    s1 = mw.ustring.gsub(s1,"^[^:]+:","")
    s2 = mw.ustring.gsub(s2,"^[^:]+:","")
    return s1 == s2
end

-- Figure out tracking categories and editor warnings
-- Arguments:
--   default = Commons link argument passed to template
--   fetchGallery = whether to fetch a gallery from Wikidata
--   fetchCategory = whether to fetch a category from Wikidata
--   qid = force a qid for testing
-- Returns:
--   tracking category and possible user warning
--
-- Note: the logic for the tracking is quite different than the logic
-- for generating Commons links (above). Thus, it is separated into another
-- function for code clarity and maintainability. This should not seriously 
-- affect performance: server time is dominated by fetching wikidata entities,
-- and those entities should be cached and shared between the Commons generating
-- code and this tracking code.
function p._tracking(default, fetchGallery, fetchCategory, qid)
	local title, wp_ns, wp_qid = _getTitleQID(qid,true)
	if wp_ns ~= "" then
		title = wp_ns..":"..title
	end
	-- only track if test or namespace=article or namespace=category
	if not (qid or wp_ns == "" or wp_ns == "Category") then
		return ""
	end
	-- construct warning message
	local msg = "Commons link does not match Wikidata"
	msg = msg.."– [[Template:Commons_category#Resolving_discrepancies|please check]]"
	local prefix = "[[Category:Commons "
	if not fetchGallery and fetchCategory then
		prefix = prefix.."category "
	end
	prefix = prefix.."link "
	-- determine title and namespace of wikidata and wp article
	local wikidata = nil
	-- Tracking code works for all 4 cases of states of fetchGallery/Category
	-- fetchGallery takes precedence
	if fetchGallery then
		wikidata = p._hasGallery(qid)
	end
	if wikidata == nil and fetchCategory then
		wikidata = p._hasCategory(qid,true)
	end
    local wp_cat = (wp_ns == "Category")

	if default then
		if default == wikidata then
			return prefix.."is on Wikidata]]"
		end
		if titleMatch(default,title) then
			return prefix.."is defined as the pagename]]"..warning(msg)
		end
		return prefix.."is locally defined]]"..warning(msg)
	end
	if wikidata then
		return prefix.."from Wikidata]]"
	end
	return prefix.."is the pagename]]"
end

-- Testing-only entry point for _getTitleQID
function p.getTitleQID(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	local text, ns, qid = _getTitleQID(args[1],args[2])
	return text..","..ns..","..(qid or "nil")
end

-- Testing-only entry point for _lookupFallback
function p.lookupFallback(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	local fallback = _lookupFallback(args[1],args[2])
	return fallback or "nil"
end

-- Find the Commons gallery page associated with article
function p.getGallery(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._getCommons("",args[1],args.linktext,args.search,args.lcfirst,args.qid)
end

-- Find the Commons category page associated with article
function p.getCategory(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	local retval = p._getCommons("Category",args[1],args.linktext,args.search,args.lcfirst,args.qid)
	if args.tracking then
		local default = nil
		if args[1] then
			default = "Category:"..args[1]
		end
		retval = retval..p._tracking(default,false,true,args.qid)
	end
	return retval
end

function p.getGalleryOrCategory(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	local retval = p._getGalleryOrCategory(args[1],args.linktext,args.search,args.qid)
	if args.tracking then
		retval = retval..p._tracking(args[1],true,true,args.qid)
	end
	return retval
end

function p.hasGallery(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._hasGallery(args.qid) or ""
end

function p.hasCategory(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._hasCategory(args.qid) or ""
end

function p.hasGalleryOrCategory(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._hasGallery(args.qid) or p._hasCategory(args.qid) or ""
end

function p.getGalleryAndCategory(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._getGalleryAndCategory(args[1],args[2],args.linktext,args.categoryText,
		args.bold,args.italic,args.oneSearch,args.qid)
end

function p.tracking(frame)
	local args = getArgs(frame,{frameOnly=true,parentOnly=false,parentFirst=false})
	return p._tracking(args[1],args.fetchGallery,args.fetchCategory,args.qid)
end

return p