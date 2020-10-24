local p = {}
local excerptModule =  require('Module:Excerpt/portals')
local slideshowModule = require('Module:Random slideshow')
local randomModule = require('Module:Random')

local DEFAULT_LIMIT = 25 -- max number of excerpts to be shown in the slideshow
local SOURCE_PAGES_LIMIT = 10 -- max number of pages to check for links / list items

-- begin BHG addition for tracking source pages
local sourcepgagesused = {};
local sourcepgagesusedcounter = 0;
local articlelistcount = -1;
local usesEmbeddedList = false;
-- end BHG addition for tracking source pages

function cleanupArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				cleanArgs[key] = val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

function isDeclined(val)
	if not val then return false end
	local declinedWords = " decline declined exclude excluded false none not no n off omit omitted remove removed "
	return string.find(declinedWords , ' '..val..' ', 1, true ) and true or false
end

--[[
	@param {String} wikitext: Wikitext of just the list (i.e. each line is a list item)
	@param {String} symbol:   Special character used in the wikitext markup for the list, e.g. '*' or '#'
	@param {String} outerTag: Text portion of the tag for each list or sublist, e.g. 'ul' or 'ol'
	@param {String} innerTag: Text portion of the tag for each list item, e.g. 'li'
]]
local wikitextToHtmlList = function(wikitext, symbol, outerTag, innerTag)
	local listParts = {}
	for level, item in mw.ustring.gmatch('\n'..wikitext..'\n', '\n(%'..symbol..'+)(.-)%f[\n]') do
	    table.insert(listParts, {level=level, item=item})
	end
	table.insert(listParts, {level='', item=''})
	
	local htmlList = {}
	for i, this in ipairs( listParts ) do
		local isFirstItem = (i == 1)
		local isLastItem = (i == #listParts)
	    local lastLevel = isFirstItem and '' or listParts[i-1]['level']
	    local tags
	    if #lastLevel == #this.level then
	    	tags = '</'..innerTag..'><'..innerTag..'>'
	    elseif #this.level > #lastLevel then
	    	tags = string.rep('<'..outerTag..'><'..innerTag..'>', #this.level - #lastLevel)
	    elseif isLastItem then
	    	tags = string.rep('</'..innerTag..'></'..outerTag..'>', #lastLevel)
	    else -- ( #this.level < #lastLevel ) and not last item
	    	tags = string.rep('</'..innerTag..'></'..outerTag..'>', #lastLevel - #this.level ) .. '</'..innerTag..'><'..innerTag..'>'
	    end
	    table.insert(htmlList, tags .. this.item)
	end
	return table.concat(htmlList)
end

--[[
	@param {String} wikitext: Wikitext excertp containg zero or more lists
	@param {String} symbol:   Special character used in the wikitext markup for the list, e.g. '*' or '#'
	@param {String} outerTag: Text portion of the tag for each list or sublist, e.g. 'ul' or 'ol'
	@param {String} innerTag: Text portion of the tag for each list item, e.g. 'li'
]]
local gsubWikitextLists = function(wikitext, symbol, outerTag, innerTag)
	-- temporarily remove list linebreaks... 
	wikitext = mw.ustring.gsub(wikitext..'\n', '\n%'..symbol, '¿¿¿'..symbol) 
	-- ...so we can grab the whole list (and just the list)...
	return mw.ustring.gsub(
		wikitext,
		'¿¿¿%'..symbol..'[^\n]+', 
		function(listWikitext)
			-- ...and then reinstate linebreaks...
			listWikitext = mw.ustring.gsub(listWikitext, '¿¿¿%'..symbol, '\n'..symbol)
			-- ...and finally do the conversion
			return wikitextToHtmlList(listWikitext, symbol, outerTag, innerTag)
		end
	)
end

local replacePipesWithMagicword = function(t)
	return mw.ustring.gsub(t, '|', '{{!}}')
end

--[[ help gsub strip tables and templates that aren't part of the prose,
     and remove linebreaks from within other templates,
     and preprocess parser functions ]]
local processBraces = function(t)
	local isTable = mw.ustring.sub(mw.text.trim(t), 2, 2) == '|'
	if isTable then
		return ''
	end
	-- else it's a template or parser function
	local first = mw.ustring.sub(t, 1, 1)
	local last = mw.ustring.sub(t, -1)
	local isNotPartOfProse = first == '\n' and last == '\n'
	if isNotPartOfProse then
		return ''
	end
	local isParserFunction = mw.ustring.sub(mw.text.trim(t), 3, 3) == '#'
	if isParserFunction then
		local frame = mw.getCurrentFrame()
		return frame:preprocess(t)
	end
	-- else replace pipes and remove internal linebreaks
	return replacePipesWithMagicword(mw.ustring.gsub(t, '\n*', ''))
end

function makeGalleryArgs(titles, options, limit, nonRandom)
	local galleryArgs = {}
	local titlesSequence = {}
	local i = 1
	while titles[i] do
		titlesSequence[i] = titles[i]
		i  = i + 1
	end
	local sortedTitles = nonRandom and titlesSequence or randomModule.main('array', {t=titlesSequence, limit=limit})
	for _i, title in ipairs(sortedTitles) do
		if (#galleryArgs / 2) < limit then
			local success, excerpt = pcall(excerptModule.get, title, options)
			if not success then
				mw.log("require('Module:Excerpt').get failed: " .. excerpt) -- probably got a redlink
				excerpt = nil
			end
			if excerpt and excerpt ~= '' and #excerpt > 10 then
				-- temporarily take off the '''[[Page title|Read more...]]''' link if present
				readmore_start_index, readmore_end_index, readmore_text = mw.ustring.find(excerpt, "(%s*'''%b[]''')$", -350) --- Starting from end should improve efficiency. 350 characters allows for long page titles and/or a long custom label for the link
				if readmore_start_index then
					excerpt = mw.ustring.sub(excerpt, 1, readmore_start_index-1)
				end
			end
			if excerpt and excerpt ~= '' and #excerpt > 10 then -- check again in case we had a few characters plus Read more...
				-- strip galleries
				excerpt = mw.ustring.gsub(excerpt, "<%s*[Gg]allery.->.-<%s*/%s*[Gg]allery%s*>", "")
				-- strip tables and block templates; strip newlines and replace pipes within inline templates
				excerpt = mw.ustring.gsub(excerpt..'\n', '\n?%b{}\n?', processBraces)
				-- replace pipes within links
				excerpt = mw.ustring.gsub(excerpt, '%b[]', replacePipesWithMagicword)
				-- replace other pipes with html entity
				excerpt = mw.ustring.gsub(excerpt, '|', '&#124;')
				-- replace wikitext bulleted lists with html bulleted lists
				excerpt = gsubWikitextLists(excerpt, '*', 'ul', 'li')
				-- replace wikitext numbered lists with html numbered lists
				excerpt = gsubWikitextLists(excerpt, '#', 'ol', 'li')
				excerpt = mw.text.trim(excerpt)
				-- add back the "Read more..." link if it was present
				if readmore_text then
					excerpt = excerpt .. readmore_text
				end
				local text = '<div style{{=}}text-align:left;>' .. mw.ustring.gsub(excerpt, '%c', '<br>') .. '</div>'
				table.insert(galleryArgs, 'File:Blank.png')
				table.insert(galleryArgs, text)
			end
		end
	end
	if nonRandom then
		galleryArgs.random = 'false'
	end
	if #galleryArgs == 0 and options.nostubs then
		-- try again, this time including stubs
		options.nostubs = false
		return makeGalleryArgs(titles, options, limit, nonRandom)
	else
		return galleryArgs
	end
end

local makeOptions = function(args)
	local options = args -- pick up miscellaneous options: more, errors, fileargs
	options.paraflags = excerptModule.numberFlags(args.paragraphs or "") -- parse paragraphs, e.g. "1,3-5" → {"1","3-5"}
	options.fileflags = excerptModule.numberFlags(args.files or "") -- parse file numbers
	if args.nostubs and isDeclined(args.nostubs) then
		options.nostubs = false
	else 
		options.nostubs = true
	end
	return options
end

local isArticle = function(pagetitle)
	local titleObject = mw.title.new(pagetitle)
	return ( titleObject and titleObject.namespace == 0 ) and true or false
end

local getLinkedTitles = function(args, method, limit)
	local pagenames = {}
	local ii = 1
	local isNotCategory
	while args[ii] and ii < limit do
		local pageContent = excerptModule.getContent(args[ii])
		if pageContent then
			local pageSection = args["section"..ii] or args["section"]
			local sectionOnly = args["sectiononly"..ii] or args["sectiononly"]
			local text = pageContent
			if pageSection then -- check relevant section only
				local success, result = pcall(excerptModule.getSection, pageContent, pageSection, sectionOnly)
				if not success then
					mw.log("require('Module:Excerpt').getSection failed on the content of " .. args[ii] .. ": " .. result)
					result = nil
				end
				text = result or pageContent
			end
			-- begin BHG addition for tracking source pages
			local thisPage = mw.title.getCurrentTitle().nsText .. ":" .. mw.title.getCurrentTitle().text
			local thisBareParam = mw.ustring.gsub(args[ii], "^([^#]+).*$", "%1", 1) -- strip any section anchor from the parameter's page name
			if (thisPage == thisBareParam) then
				usesEmbeddedList = true;
			end
			-- end BHG addition for tracking source pages
			-- replace annotated links with real links
			text = mw.ustring.gsub(text, "{{%s*[Aa]nnotated[ _]link%s*|%s*(.-)%s*}}", "[[%1]]")
			if method == "linked" then
				for p in mw.ustring.gmatch(text, "%[%[%s*([^%]|\n]*)") do
					if isArticle(p) then
						table.insert(pagenames, p)
					end
				end
			else
				-- listitem: first wikilink on a line beginning *, :#, etc. except in "See also" or later section
				text = mw.ustring.gsub(text, "\n== *See also.*", "")
				for p in mw.ustring.gmatch(text, "\n:*[%*#][^\n]-%[%[%s*([^%]|\n]*)") do
					if isArticle(p) then
						table.insert(pagenames, p)
					end
				end
			end
			-- begin BHG addition for tracking source pages
			if ((method == "listitem") or (method == "linked")) then
				table.insert(sourcepgagesused, args[ii])
				sourcepgagesusedcounter = sourcepgagesusedcounter + 1
			end
			-- end BHG addition for tracking source pages
		end
		ii = ii + 1
	end
	-- begin BHG addition for tracking
	articlelistcount = #pagenames
	-- end BHG addition for tracking
	return pagenames
end

-- Template entry points:

-- randomExcerpt: Titles specified in template parameters (equivalent to {{Transclude random excerpt}})
p.randomExcerpt = function(frame)
	local parent = frame.getParent(frame)
	local output = p._excerpt(parent.args, 'random')
	return frame:preprocess(output)
end

-- linkedExcerpt: Titles from links on one or more pages (similar to {{Transclude linked excerpt}})
p.linkedExcerpt = function(frame)
	local parent = frame.getParent(frame)
	local output = p._excerpt(parent.args, 'linked')
	return frame:preprocess(output)
end

-- listItemExcerpt: Titles from linked list items one one or more pages (similar to {{Transclude list item excerpt}})
p.listItemExcerpt = function(frame)
	local parent = frame.getParent(frame)
	local output = p._excerpt(parent.args, 'listitem')
	return frame:preprocess(output)
end


-- Module entry point:

p._excerpt = function(_args, method)
	local args = cleanupArgs(_args)
	-- check for blank value in more parameter
	if _args.more and not args.more then
		args.more = "Read more..." -- default text for blank more=
	end
	local galleryArgs = {}
	local options = makeOptions(args)
	local limit = args.limit and tonumber(args.limit) or DEFAULT_LIMIT
	local titles
	if method == 'linked' or method == 'listitem' then
		titles = getLinkedTitles(args, method, SOURCE_PAGES_LIMIT)
	else
		titles = args
	end
	local galleryArgs = makeGalleryArgs(titles, options, limit, isDeclined(_args.random))
	return slideshowModule._main(galleryArgs, false, 'excerptSlideshow-container') .. checksourcepages()
end

-- begin BHG addition for tracking source pages
function checksourcepages()
	-- no tracking unless we are in Portal namespace
	if (mw.title.getCurrentTitle().nsText ~= "Portal") then
		return ""
	end
	local pagecounter = 0;
	local templatecount = 0;
	local outlinecount = 0;
	local retval ="";
	local usesEponymousArticle = false;
	local debugging = false;
	local thisPageBareName = mw.title.getCurrentTitle().text;
	if debugging then
		retval = '<div style="display:block; border:10px solid green; background-color:#efe; padding:1em; margin:1em">\n----\n'
		retval = retval .. "sourcepgagesusedcounter: " .. sourcepgagesusedcounter .. "\n----\n"
		retval = retval .. "pages used:"
	end
	local apage
	for apage in arrayvalues(sourcepgagesused) do
		if debugging then 
			retval = retval .. "\n# [[:" .. apage .. "]]"
			retval = retval .. " — " .. "First 999 = /" .. string.sub(apage, 1, 999) .. "/"
		end
		if (string.find(apage, "^[tT]emplate ?:") == 1) then
			templatecount = templatecount + 1;
		end
		if (string.find(apage, "^[oO]utline +of ") == 1) then
			outlinecount = outlinecount + 1;
		end
		if (apage == thisPageBareName) then
			usesEponymousArticle = true;
		end
		pagecounter = pagecounter + 1
	end
	if debugging then
		retval = retval .. "\nTotal pages: " .. pagecounter
		retval = retval .. "\ntemplatecount: " .. templatecount
		retval = retval .. "</div>"
	end
	-- first do a sanity check that both counting methods have produced the same result
	if (sourcepgagesusedcounter == pagecounter) then
		-- if all pages are templates, then populate tracking categories
		if (pagecounter == templatecount) then
			if (templatecount == 1) then
				retval = retval .. "[[Category:Automated article-slideshow portals with article list built solely from one template]]"
			elseif (templatecount == 2) then
				retval = retval .. "[[Category:Automated article-slideshow portals with article list built solely from two templates]]"
			elseif (templatecount == 3) then
				retval = retval .. "[[Category:Automated article-slideshow portals with article list built solely from three templates]]"
			elseif (templatecount > 3) then
				retval = retval .. "[[Category:Automated article-slideshow portals with article list built solely from four or more templates]]"
			end
		elseif (templatecount > 0) then
			retval = retval .. "[[Category:Automated article-slideshow portals with article list built using one or more templates, and other sources]]"
		end
	end
	if (outlinecount >= 1) then
		retval = retval .. "[[Category:Automated article-slideshow portals with article list built using one or more outline pages]]"
	end
	if (articlelistcount < 2) then
		retval = retval .. "[[Category:Automated article-slideshow portals with less than 2 articles in article list]]"
	elseif (articlelistcount <= 5) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 2–5 articles in article list]]"
	elseif (articlelistcount <= 10) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 6–10 articles in article list]]"
	elseif (articlelistcount <= 15) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 11–15 articles in article list]]"
	elseif (articlelistcount <= 20) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 16–20 articles in article list]]"
	elseif (articlelistcount <= 25) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 21–25 articles in article list]]"
	elseif (articlelistcount <= 30) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 26–30 articles in article list]]"
	elseif (articlelistcount <= 40) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 31–40 articles in article list]]"
	elseif (articlelistcount <= 50) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 41–50 articles in article list]]"
	elseif (articlelistcount <= 100) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 51–100 articles in article list]]"
	elseif (articlelistcount <= 200) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 101–200 articles in article list]]"
	elseif (articlelistcount <= 500) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 201–500 articles in article list]]"
	elseif (articlelistcount <= 1000) then
		retval = retval .. "[[Category:Automated article-slideshow portals with 501–1000 articles in article list]]"
	elseif (articlelistcount > 1000) then
		retval = retval .. "[[Category:Automated article-slideshow portals with over 1000 articles in article list]]"
	end
	if usesEmbeddedList then
		retval = retval .. "[[Category:Automated article-slideshow portals with embedded list]]"	
	end
	if usesEponymousArticle then
		retval = retval .. "[[Category:Automated article-slideshow portals with article list built using eponymous article]]"
	end
	return retval
end

function arrayvalues(t)
	local i = 0
	return function() i = i + 1; return t[i] end
end

-- end BHG addition for tracking source pages
return p