local randomModule = require('Module:Random')

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

function makeOutput(allItems, maxItems, more, notRandom)
	local output
	if notRandom then
		output = ''
		local itemIndex = 1
		local maxCount = math.min(#allItems, maxItems)
		while itemIndex <= maxCount do
			output = output .. allItems[itemIndex] .. '\n'
			itemIndex = itemIndex + 1
		end
	else
		local randomiseArgs = {
			['t'] = allItems,
			['limit'] = maxItems
		}
		local randomisedItems = randomModule.main('array', randomiseArgs )
		output = table.concat(randomisedItems, '\n')
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

function makeCollapsed(outerText, innerText)
	return "{{Hidden begin | titlestyle = font-weight:normal | title = " .. outerText .. "}}" .. innerText .. "{{Hidden end}}"
end


-- Get current events for a "YYYY Month D" date. Returns a table of list items.
function getRecentAdditions(subpage, keepPatterns, skipPatterns, showWikitext)
	local title = mw.title.new('Wikipedia:Recent additions' .. subpage)
	local raw = title:getContent()
	local itemPattern = '%*%s?%.%.%.[%S ]*'
	local items = {}
	for item in mw.ustring.gmatch(raw, itemPattern) do
		local keep = false
		local skip = false
		local isListItem = ( string.sub(item, 0, 1) == '*' )
		if isListItem then
			local text = cleanForPatternMatching(item)
			for ii, keepPatt in pairs(keepPatterns) do
				if not keep and mw.ustring.find(text, keepPatt) then
					keep = true
				end
			end
			if #skipPatterns > 0 then
				for iii, skipPatt in pairs(skipPatterns) do
					if not skip and mw.ustring.find(text, skipPatt) then
						skip = true			
					end
				end
			end
		end
		if keep and not skip then
			-- remove (pictured) inline note
			local cleanItem = mw.ustring.gsub(item, "%s*''%(.-pictured.-%)''", "")
			-- remove (illustrated) inline note
			cleanItem = mw.ustring.gsub(cleanItem, "%s*''%(.-illustrated.-%)''", "")
			if showWikitext then
				-- remove html comments
				cleanItem = mw.ustring.gsub(cleanItem, "%<%!%-%-(.-)%-%-%>", "")
				local itemWikitext = "<pre>" .. mw.text.nowiki( cleanItem ) .. "</pre>"
				cleanItem = makeCollapsed(cleanItem, itemWikitext)
			end
			table.insert(items, cleanItem)
		end
	end
	return items
end

function getItems(maxMonths, patterns, skipPatterns, showWikitext)
	local allItems = {}
	local lang = mw.language.new('en')
	local currentYear  = tonumber(lang:formatDate('Y', 'now'))
	local currentMonth = tonumber(lang:formatDate('n', 'now'))
	local monthsAgo = 0
	while monthsAgo < maxMonths do
		local subpage
		if monthsAgo == 0 then
			subpage = ''
		else
			local year = currentYear - math.modf( (monthsAgo+12-currentMonth)/12 ) 
			local month = math.fmod(12 + currentMonth - math.fmod(monthsAgo, 12), 12)
			month = ( month ~= 0 ) and month or 12
			subpage = lang:formatDate('/Y/F', year .. '-' .. month)
		end
		local monthlyItems = getRecentAdditions(subpage, patterns, skipPatterns, showWikitext)
		for i, item in ipairs(monthlyItems) do
			table.insert(allItems, item)
		end
		monthsAgo = monthsAgo + 1
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

	local months = tonumber(args.months) or 30
	
	local showWikitext = isAffirmed(args.wikitext)

	local allItems = getItems(months, patterns, skipPatterns, showWikitext)
	if #allItems < 1 then
		return args.header and '' or args.none or 'No recent additions'
	end

	local maxItems = tonumber(args.max) or 6

	local more = args.more
	if isAffirmed(args.more) then
		more = "'''[[Wikipedia:Recent additions|More recent additions...]]'''"
	end

	local nonRandom = isAffirmed(args.latest)

	local output = makeOutput(allItems, maxItems, more, nonRandom)
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