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

function isAffirmed(val)
	if not(val) then return false end
	local affirmedWords = ' add added affirm affirmed include included on true yes y '
	return string.find(affirmedWords, ' '..string.lower(val)..' ', 1, true ) and true or false
end

function makeOutput(allItems, maxItems, more)
	local output = ''
	local itemIndex = 1
	local maxCount = math.min(#allItems, maxItems)
	while itemIndex <= maxCount do
		output = output .. allItems[itemIndex] .. '\n'
		itemIndex = itemIndex + 1
	end
	if more then
		output = output .. more
	end
	return mw.text.trim(output)
end

function cleanForPatternMatching(wikitext)
	-- remove wikilink brackets
	local cleaned = mw.ustring.gsub(wikitext, "%[%[(.-)%]%]","%1")
	-- remove pipes that would have been in piped links
	cleaned = mw.ustring.gsub(cleaned, "%|"," ")
	-- remove external links
	cleaned = mw.ustring.gsub(cleaned, "%[.-%]"," ")
	return cleaned
end

function formatDateString(dateString, mdyDates)
	if mdyDates then
		formattedDatePattern = "%2 %3, %1"
	else
		formattedDatePattern = "%3 %2 %1"
	end
	return '<span style="font-weight:normal;">' .. string.gsub(dateString, "(.*) (.*) (.*)", formattedDatePattern) .. ' –</span>'
end

function makeCollapsed(outerText, innerText)
	return "{{Hidden begin | titlestyle = font-weight:normal | title = " .. outerText .. "}}" .. innerText .. "{{Hidden end}}"
end

-- Get current events for a "YYYY Month D" date. Returns a table of list items.
function getCurrentEvents(date, mdyDates, keepPatterns, skipPatterns, showWikitext)
	local title = mw.title.new("Portal:Current events/" .. date)
	local raw = title:getContent()
	if (not raw) or raw == '' then
		return {}
	end
	local lines = mw.text.split( raw , '\n')
	local items = {}
	local itemHeading = ''
	local cleanItemHeading = ''
	local previousItemPrefix = ''

	local formattedDate = formatDateString(date, mdyDates)

	for i, v in ipairs(lines) do
		local keep = false
		local skip = false
		local isSublistItem = ( string.sub( v, 0, 2 ) == '**' )
		local isListItem = not isSublistItem and ( string.sub( v, 0, 1) == '*' )
		local hasSublistItem = isListItem and i < #lines and ( string.sub( lines[i+1], 0, 2 ) == '**' )

		if hasSublistItem then
			itemHeading = mw.text.trim(mw.ustring.gsub(v, '%*', '', 1))
			cleanItemHeading = cleanForPatternMatching(itemHeading)
		elseif isListItem then
			itemHeading = ""
			cleanItemHeading = ""
		end

		if (isListItem and not hasSublistItem) or isSublistItem then
			local text = cleanForPatternMatching(v)
			for ii, keepPatt in pairs(keepPatterns) do
				if not keep and ( mw.ustring.find(text, keepPatt) or mw.ustring.find(cleanItemHeading, keepPatt) ) then
					keep = true
				end
			end
			if #skipPatterns > 0 then
				for iii, skipPatt in pairs(skipPatterns) do
					if not skip and ( mw.ustring.find(text, skipPatt) or mw.ustring.find(cleanItemHeading, skipPatt) ) then
						skip = true			
					end
				end
			end
		end

		if keep and not skip then
			local itemPrefix = ";" .. formattedDate
			if itemHeading ~= "" then itemPrefix = itemPrefix .. " '''"..itemHeading.."'''" end
			itemPrefix = itemPrefix .. "\n:"
			if previousItemPrefix == itemPrefix then
				itemPrefix = ':'
			else
				previousItemPrefix = itemPrefix
			end
			local item = mw.ustring.gsub(v, '%*+', itemPrefix)
			if showWikitext then
				-- remove html comments
				local itemWikitext = mw.ustring.gsub(item, "%<%!%-%-(.-)%-%-%>", "")
				-- remove prefix from wikitext
				itemWikitext = mw.ustring.gsub(itemWikitext, ";(.-)\n", "")
				itemWikitext = "<pre>" .. mw.text.nowiki( itemWikitext ) .. "</pre>"
				-- remove prefix from item
				itemWithoutPrexix = mw.ustring.gsub(v, '%*+', '')
				item = itemPrefix .. makeCollapsed(itemWithoutPrexix, itemWikitext)
			end
			table.insert(items, item)
		end
	end
	return items
end

function getItems(maxDays, mdyDates, patterns, skipPatterns, showWikitext)
	local allItems = {}
	local lang = mw.language.new('en')
	local daysAgo = 0
	while daysAgo < maxDays do
		local day = lang:formatDate('Y F j', 'now - '..daysAgo..' days')
		local dailyItems = getCurrentEvents(day, mdyDates, patterns, skipPatterns, showWikitext)
		for i, item in ipairs(dailyItems) do
			table.insert(allItems, item)
		end
		daysAgo = daysAgo + 1
	end
	return allItems
end

function getPatterns(args, prefix)
	local patterns = {}
	local ii = 1
	while args[prefix and prefix..ii or ii] do
		patterns[ii] = args[prefix and prefix..ii or ii]
		ii = ii + 1
	end
	return patterns
end

local p = {}

p.main = function(frame)
	local parent = frame.getParent(frame)
	local parentArgs = parent.args
	local args = cleanupArgs(parentArgs)

	if args['not'] and not args['not1'] then
		args['not1'] = args['not']
	end
	
	local patterns = getPatterns(args)
	if #patterns < 1 then
		return error("Search pattern not set")
	end

	local skipPatterns = getPatterns(args, 'not')

	local days = tonumber(args.days) or 30

	local mdyDates = args.dates and string.lower(args.dates) == 'mdy'
	
	local showWikitext = isAffirmed(args.wikitext)

	local allItems = getItems(days, mdyDates, patterns, skipPatterns, showWikitext)
	if #allItems < 1 then
		return args.header and '' or args.none or 'No recent news'
	end

	local maxItems = tonumber(args.max) or 6

	local more = args.more
	if isAffirmed(args.more) then
		more = "'''[[Portal:Current events|More current events...]]'''"
	end

	local output = makeOutput(allItems, maxItems, more)
	if args.header then
		output = args.header .. '\n' .. output .. '\n' .. (args.footer or '{{Box-footer}}')
	end
	local needsExpansion = mw.ustring.find(output, '{{', 0, true)	
	if needsExpansion then
		return frame:preprocess(output)
	else 
		return output
	end

end

return p