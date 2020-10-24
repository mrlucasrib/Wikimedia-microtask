-- 
-- Lua functions for personal use
-- 

p = {}

-- carousel returns one of a list of image filenames
-- the index of the one chosen increments every 'switchsecs'
-- which is a parameter giving the number of seconds between switches
-- 3600 would switch every hour
-- 43200 would be every 12 hours (the default)
-- 86400 would be daily
-- {{#invoke:RexxS|carousel|switchsecs=<number-of-seconds>}}
-- {{#invoke:RexxS|carousel}} for 12 hours between switches
p.carousel = function(frame)
	local switchtime = tonumber(frame.args.switchsecs) or 43200
	if switchtime < 1 then switchtime = 43200 end
	local imgs = {
		"Pelicans 11.3.2007.jpg",
        "Little Chief Mountain.jpg",
		"Great Blue Heron and immature Bald Eagle on the Platte River.jpg",
		"Green Heron4.jpg",
		"Canada Goose mating ritual2.jpg",
		"North Swiftcurrent Glacier (2).jpg", 
		"Adhela and Guy Fawkes 1873.jpg",
		"Flock of Cedar Waxwings3.jpg",
		"Fusillade Peak 2.jpg",
		"Lightning 7.11.2008.jpg",
		"Ursus americanus.jpg",
		"Jackson Glacier 7.2017.jpg",
		"Stone Creek Nebraska.jpg",
		"Grus canadensis2.jpg",
		"Scaphirhynchus platorynchus 6.14.2014a.jpg",
		"Painted Tepee.jpg",
		"Bison Bull in Nebraska.jpg",
		"Horses and thunderstorm1.jpg",
		"Going to the Sun Falls.jpg",
		"Lillypads at Desoto.jpg",
		"Steamboat Geyser.jpg",
		"Fusillade Mountain.jpg",
		"Lake view from Beartooth Pass.jpg",
		"Tetons from Togwotee Pass.jpg",
		"Inspiration Point.jpg",
		"Flowers b grow to 6 feet.jpg",
		"Storm Front2.jpg",
		"Bird Woman Falls 2017.jpg"
	}
	local numimgs = #imgs
	local now = math.floor(os.time()/switchtime)
	local idx = now % numimgs +1
	return imgs[idx]
end

-- wobble returns CSS which rotates the container
-- possible angles are -4, -2, 0, 2, 4 degrees
-- they may be changed by the |tilt parameter (defaults to 2)
-- a different angle is selected every <switchtime> seconds - default is 4
-- {{#invoke:RexxS|wobble|switchsecs=<number-of-seconds>}}
-- {{#invoke:RexxS|wobble}} for 4 seconds between switches
p.wobble = function(frame)
	local tilt = tonumber(frame.args.tilt) or 2
	local switchtime = tonumber(frame.args.switchsecs) or 4
	if switchtime < 1 then switchtime = 4 end
	local now = math.floor(os.time()/switchtime)
	local angle = tilt * (now % 5 - 2)
	return "-moz-transform:rotate(" .. angle .. "deg);-webkit-transform:rotate(" .. angle .. "deg); transform:rotate(" .. angle .. "deg);"
end

-- prevwarn returns a hatnote-style warning message in red
-- the customisable text of the warning is passed in the parameter 'message'
-- it only returns the warning in preview mode
-- note that a blank {{REVISIONID}} is a way of identifying preview mode.
-- {{#invoke:RexxS|prevwarn|message=the religion parameter will be removed soon.}}
p.prevwarn = function(frame)
	local msg = frame.args.message
	if frame:preprocess( "{{REVISIONID}}" ) == "" then
		return '<div class="hatnote" style="color:red"><strong>Warning:</strong> ' .. msg .. ' (this message is shown only in preview).</div>'
	end
end

-- sandyrock returns a pseudo-random message inline
-- the style is customisable with the 'style' parameter
-- other messages may be added or substituted, just separate with a comma
-- {{#invoke:RexxS|sandyrock|style=color:#C00;}}
p.sandyrock = function(frame)
	local style = frame.args.style or ""
	local msgs = {
		"You make [[Vogon]]s look frivolous",
		"You're the poster-child for the phrase 'bureaucratic nightmare'",
		"How much did they pay for your life-story when they were filming [[Brazil]]?",
		"''Discretion''-ary sanctions? You are to 'discretion' what 'bull' is to 'china-shop'.",
		"Using you for Arbitration Enforcement is like employing King Herod as a baby-sitter."
		}
	local idx = os.time() % #msgs +1
	return '<span style="'.. style .. '">' .. msgs[idx] .. '</span>'
end

-- getLink returns the label for a Qid linked to the article
p.getLink = function(frame)
	local itemID = mw.text.trim(frame.args[1] or "")
	if itemID == "" then return end
	local sitelink = mw.wikibase.sitelink(itemID)
	local label = mw.wikibase.label(itemID)
	if not label then label = itemID end
	if sitelink then
		return "[[" .. sitelink .. "|" .. label .. "]]"
	else
		return label
	end
end

-- getTitle returns the label for a Qid linked to the article, without the link that getLink returns
p.getTitle = function(frame)
    local itemID = mw.text.trim(frame.args[1] or "")
    if itemID == "" then return end
    local label = mw.wikibase.label(itemID)
    if not label then label = itemID end
    return label
end

-- getAT returns the article title for a Qid
p.getAT = function(frame)
	local itemID = mw.text.trim(frame.args[1] or "")
	if itemID == "" then return end
	return mw.wikibase.sitelink(itemID)
end

-- getDescription returns the Wikidata item description for a Qid
p.getDescription = function(frame)
	local qid = frame.args.qid
	if qid and (#qid == 0) then qid = nil end
	local desc = mw.wikibase.description(qid)
	if desc then return mw.text.nowiki(desc) else return nil end
end

-- getIdentifierQualifier returns the value of a qualifier for an Identifier
-- such as 'Art UK artist ID', P1367
-- the assumption is that one value exists for the property
-- and only one qualifier exists for that value
-- Constraint violations for P1367 are at:
-- https://www.wikidata.org/wiki/Wikidata:Database_reports/Constraint_violations/P1367#Single_value
-- Now in [[Module:WikidataIdentifiers]]
p.getIdentifierQualifier = function(frame)
	local propertyID = mw.text.trim(frame.args[1] or "")

	-- The PropertyID of the qualifier
	-- whose value is to be returned is passed in named parameter |qual=
	local qualifierID = frame.args.qual
	
	-- Can take a named parameter |qid which is the Wikidata ID for the article.
	-- This will not normally be used because it's an expensive call.
	local qid = frame.args.qid
	if qid and (#qid == 0) then qid = nil end

	local entity = mw.wikibase.getEntityObject(qid)
	local props
	if entity and entity.claims then
		props = entity.claims[propertyID]
	end
	if props then
		-- Check that the first value of the property is an external id
		if props[1].mainsnak.datatype == "external-id" then
			-- get any qualifiers of the first value of the property
			local quals = props[1].qualifiers
			if quals and quals[qualifierID] then
				-- check what the dataype of the first qualifier value is
				-- if it's quantity return the amount
				if quals[qualifierID][1].datatype == "quantity" then
					return tonumber(quals[qualifierID][1].datavalue.value.amount)
				end
				-- checks for other datatypes go here:
			end
			return "no qualifier"
		else
			return "not external id"
		end
		return "no property"
	end
	return "no claims"
end

-- getValueIndirect returns the value of a property of a value of a property
-- for example the 'headquarters location property, P159' (property1) may be a city (value 1)
-- that city should be a wikibase-entity with its own entry
-- that entry should have a 'country property, P17' (property2), which will have a value which is the country (value2)
-- the assumption is that one value (value1) exists for property1
-- and only one value exists for that property2 of value1
-- Constraint violations for P17 are at:
-- https://www.wikidata.org/wiki/Wikidata:Database_reports/Constraint_violations/P17#Single_value
-- This is intrinsically an expensive call
p.getValueIndirect = function(frame)
	local property1 = mw.text.trim(frame.args[1] or "")
	local property2 = mw.text.trim(frame.args[2] or "")
	
	-- Can take a named parameter |qid which is the Wikidata ID for the article.
	-- This will not normally be used because it's an expensive call.
	local qid1 = frame.args.qid
	if qid1 and (#qid1 == 0) then qid1 = nil end

	local entity1 = mw.wikibase.getEntityObject(qid1)
	local props1
	if entity1 and entity1.claims then
		props1 = entity1.claims[property1]
	end
	if props1 then
		-- Check that the first value of the property is a wikibase-item
		if props1[1].mainsnak.datatype == "wikibase-item" then
			local qid2 = props1[1].mainsnak.datavalue.value.id
			local entity2 = mw.wikibase.getEntityObject(qid2)
			if entity2.claims then
				-- only need props2 if we want a more sophisticated parsing, e.g. mdy dates
				-- local props2 = entity2.claims[property2]
				return entity2:formatPropertyValues(property2).value
			else
				return qid2 .. " has no claims."
			end
		else
			return "not wikibase-item: " .. props1[1].mainsnak.datatype --debug
		end
	end
	return "no claims"
end

-- checkPage creates a "title object" for the given title and namespace
-- named parameters:
-- art = title of article/page
-- ns = namespace number - defaults to 0 (mainspace) if omitted
-- returns 0 if page does not exist or a positive number if it does
-- {{#invoke:RexxS|checkPage|art=<pagename>}}
-- {{#invoke:RexxS|checkPage|art=<pagename>|ns=<number>}}
p.checkPage = function(frame)
	local article = mw.text.trim(frame.args.art or "")
	local ns = tonumber(frame.args.ns or 0)
	if mw.site.namespaces[ns] then
		if article>"" then
			local t = mw.title.new(article, ns)
			return t.id
		end
		return "No article name given"
	end
	return "Invalid namespace"
end

-- checkRedirect creates a "title object" for the given title and namespace
-- named parameters:
-- art = title of article/page
-- ns = namespace number - defaults to 0 (mainspace) if omitted
-- returns Redirect / Not Redirect / Does not exist
-- {{#invoke:RexxS|checkPage|art=<pagename>}}
-- {{#invoke:RexxS|checkPage|art=<pagename>|ns=<number>}}
p.checkRedirect = function(frame)
	local article = mw.text.trim(frame.args.art or "")
	local ns = tonumber(frame.args.ns or 0)
	if mw.site.namespaces[ns] then
		if article > "" then
			local t = mw.title.new(article, ns)
			if t.id > 0 then
				if t.isRedirect then
					return "Redirect"
				end
				return "Not Redirect"
			end
			return "Does not exist"
		end
		return "No article name given"
	end
	return "Invalid namespace"
end


-- getAuthors for Andy 
-- pass the Q-id of the source (book, etc.) in qid
-- returns a list in the form |author1=firstname secondname |author2= ...
p.getAuthors = function(frame)
	local propertyID = "P50"
	
	local qid = frame.args.qid
	if qid and (#qid == 0) then qid = nil end
	
	-- wdlinks is a boolean passed to enable links to Wikidata when no article exists
	-- if "false" or "no" or "0" is passed set it false
	-- if nothing or an empty string is passed set it false
	local wdl = frame.args.wdlinks
	if wdl and (#wdl > 0) then
		wdl = wdl:lower()
		if (wdl == "false") or (wdl == "no") or (wdl == "0") then
			wdl = false
		else
			wdl = true
		end
	else
		-- wdl is empty, so
		wdl = false
	end
	
	local entity, props
	local entity = mw.wikibase.getEntity(qid)
	if entity and entity.claims then
		props = entity.claims[propertyID]
	else
		-- there's no such entity or no claims for the entity
		return nil
	end
	
	-- Make sure it actually has the property requested
	if not props or not props[1] then 
		return nil
	end
	
	-- So now we have something to return:
	-- table 'out' is going to to store the return value(s):
	local out = {}
	if props[1].mainsnak.datavalue.type == "wikibase-entityid" then
		-- it's wiki-linked value, so output as link if possible
		for k, v in pairs(props) do
			local qnumber = "Q" .. v.mainsnak.datavalue.value["numeric-id"]
			local sitelink = mw.wikibase.sitelink(qnumber)
			local label = mw.wikibase.label(qnumber)
			if label then
				label = mw.text.nowiki(label)
			else
				label = qnumber
			end
			if sitelink then
				out[#out + 1] = "[[" .. sitelink .. "|" .. label .. "]]"
			else
				-- no sitelink, so check first for a redirect with that label
				local artitle = mw.title.new(label, 0)
				if artitle.id > 0 then
					if artitle.isRedirect then
						-- no sitelink, but there's a redirect with the same title as the label; let's link to that
						out[#out + 1] = "[[" .. label .. "]]"
					else
						-- no sitelink and not a redirect but an article exists with the same title as the label
						-- that's probably a dab page, so output the plain label
						out[#out + 1] = label
					end
				else
					-- no article or redirect with the same title as the label
					if wdl then
						-- show that there's a Wikidata entry available
						out[#out + 1] = "[[:d:Q" .. v.mainsnak.datavalue.value["numeric-id"] .. "|" .. label .. "]]&nbsp;<span title='" .. i18n["errors"]["local-article-not-found"] .. "'>[[File:Wikidata-logo.svg|16px|alt=|link=]]</span>"
					else
						-- no wikidata links wanted, so just give the plain label
						out[#out + 1] = label
					end
				end
			end
		end
	else
		-- not a linkable article title
		out[#out+1] = entity:formatPropertyValues(propertyID).value
	end
	
	-- if there's anything to return, then return a list
	-- in the form |author1=firstname secondname |author2= ...
	if #out > 0 then
		-- construct the list in the format we want
		for k,v in ipairs(out) do
			out[k] = "|author" .. k .. "=" .. v
		end
		return table.concat(out, " ")
	end
end

p.checkBlacklist = function(frame)
	local blacklist = frame.args.suppressfields
	local fieldname = frame.args.name
	if blacklist and fieldname then
		if blacklist:find(fieldname) then return nil end
		return true
	end
end

-- anytext returns nil if its argument is just punctuation, whitespace or html tags
-- otherwise it returns the argument
p.anytext = function(frame)
	local s = frame.args[1]
	if not s or #s == 0 then return nil end
	sx = s:gsub("<%w*>", ""):gsub("</%w*>", ""):gsub("%p", ""):gsub("%s", "")
	if #sx == 0 then
		return nil
	else 
		return s
	end
end

-- getValueQualIndirect scans a property prop1 in the current page (or another page if qid is given)
-- for each value of the property that is a wikibase item, it fetches all of the values of prop2
-- and for each value of prop2 it also retrieves each qualifier and its value
p.getValueQualIndirect = function(frame)
	local qid = frame.args.qid or ""
	if qid == "" then qid = nil end
	local prop1 = frame.args.prop1 or ""
	if prop1 == "" then return "No prop1" end
	local prop2 = frame.args.prop2 or ""
	if prop2 == "" then return "No prop2" end
	
	local ent1 = mw.wikibase.getEntity(qid)
	if not ent1 then return "No Wikidata entry" end
	if not ent1.claims then return "No claims" end
	
	local props1 = ent1.claims[prop1]
	if not props1 then return "No properties" end
	local out = ""
	for k1, v1 in pairs(props1) do
		if v1.mainsnak.datatype  == "wikibase-item" then
			local qval1 = v1.mainsnak.datavalue.value.id
			local label1 = mw.wikibase.label(qval1)
			if label1 then
				label1 = mw.text.nowiki(label1)
			else
				label1 = qval1
			end
			-- start building an output string
			out = out .. "<br>" .. label1 .. "<br>"
			-- look at entry for qval and get its prop2 values
			local ent2 = mw.wikibase.getEntity(qval1)
			if ent2.claims and ent2.claims[prop2] then
				for k2, v2 in pairs(ent2.claims[prop2]) do
					if v2.mainsnak.datatype  == "wikibase-item" then
						local qval2 = v2.mainsnak.datavalue.value.id
						local label2 = mw.wikibase.label(qval2)
						if label2 then
							label2 = mw.text.nowiki(label2)
						else
							label2 = qval2
						end
						out = out .. "+ " .. label2 .. "<br>"
						-- scan through qualifiers
						if v2.qualifiers then
							for k3, v3 in pairs(v2.qualifiers) do
								for k4, v4 in pairs(v3) do
									local val = ""
									-- handler for wikibase-item
									if v4.datatype == "wikibase-item" then
										val = v4.datavalue.value.id
										val = mw.wikibase.label(val) or val
									else
										val = mw.wikibase.renderSnak(v4)
									end
									-- assemble qualifiers
									out = out .. "++ " .. (mw.wikibase.label(k3) or k3) .. " = " .. val .. "<br>"
								end -- loop through posible multiple qual values
							end -- loop through qualifiers
						end -- test for qualifiers
					end -- test for wikibase item
				end -- loop through props2 values
			end -- test for claims in indirect item
		end -- test for wikibase item
	end -- loop through props1 values
	return out
end

-- nowiki ensures that a string of text is treated by the MediaWiki software as just a string
-- it takes an unnamed parameter and trims whitespace
p.nowiki = function(frame)
	local str = mw.text.trim(frame.args[1] or "")
	return mw.text.nowiki(str)
end

p.stripApost = function(frame)
	txt = frame.args[1] or ""
	txt = txt:gsub("'''''", ""):gsub("''''", ""):gsub("'''", ""):gsub("''", "")
	return txt
end

-- mwlangs examines all the fallback languages set in MediaWiki
-- outputs the sizes of all the longest chains
p.mwlangs = function(frame)
	thold = tonumber(frame.args[1]) or 2
	local langtbl = mw.language.fetchLanguageNames()
	local sizetbl = {}
	out = ""
	for code, name in pairs(langtbl) do
		local fbtbl = mw.language.getFallbacksFor(code)
		local num = #fbtbl
		if num > thold then
			sizetbl[code] = num
			out = out .. code .. " -- " .. num .. " -- " .. table.concat(fbtbl, ", ") .. "<br>"
		end
	end
	return out
end

-- getSitelinks returns the collection of sitelinks for qid and the number of sitelinks
local _getsitelinks = function(qid)
	local ent = mw.wikibase.getEntity(qid)
	if not ent then return {}, -1 end
	local slinks = ent.sitelinks
	if not slinks then return {}, 0 end
	local out = {}
	local count = 0
	for k, v in pairs( slinks ) do
		out[k] = v.title
		count = count + 1
	end
	return out, count
end
p.getSitelinks = function(frame)
	local qid = (frame.args[1] or frame.args.qid or ""):upper()
	if qid == "" then qid = nil end
	local sltbl, sizesltbl = _getsitelinks(qid)
	if sizesltbl == -1 then return "No Wikidata entry" end
	if sizesltbl == 0 then return "No sitelinks" end
	return mw.dumpObject( sltbl )
end

-- just a placeholder for doing tests
p.test = function(frame)
	local thisTitle = mw.title.getCurrentTitle().text
	return thisTitle
end

-- cvt2m takes a string containing a number and some length symbol
-- and converts it into metres, returning just the plain number of metres
p.cvt2m = function(frame)
	local len = mw.text.trim(frame.args[1] or "")
	if len == "" then len = "0 m" end
	local amt = len:match("([%d%.%,]+)") or "0"
	local unit = len:match("(%w+)$") or "m"
	local conv = frame:expandTemplate{ title = "Cvt", args = {amt, unit, "m"} }
	return conv:match("%(([%d%.%,]+)") or ""
end

return p