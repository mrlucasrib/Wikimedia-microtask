-- This module implements [[Template:TV ratings]].
-- This module implements [[Template:Film and game ratings]]

local mTableTools = require('Module:TableTools')
local yesno = require('Module:Yesno')
local data = require('Module:TV ratings/data')
local p = {}
local getArgs

local function getActiveSeasons(args)
	local activeSeasons = {}
	for k, v in pairs(args) do
		if data.seasons[k] and yesno(v) then
			table.insert(activeSeasons, k)
		end
	end
	table.sort(activeSeasons, function(a, b)
		return data.seasons[a].sortkey < data.seasons[b].sortkey
	end)
	return activeSeasons
end

local function makeCell(html, s)
	html
		:tag('td')
			:css('text-align', 'center')
			:css('vertical-align', 'middle')
			:wikitext(s)
end

local function makeRow(review, score)
	local row = mw.html.create('tr')
	makeCell(row, review)
	makeCell(row, score)
	return row
end

local function makeHeaderRow(header, background, scope)
	local row = mw.html.create('tr')
	row
		:tag('th')
			:attr('scope', scope ~= false and 'col' or nil)
			:attr('colspan', 2)
			:css('text-align', 'center')
			:css('background', background ~= false and '#CCCCFF' or nil)
			:css('font-size', '120%')
			:wikitext(header)
	return row
end

local function makeHeaderRowWithSeasons(builder, mainHeading, activeSeasons)
	renderMainHeading(builder, #activeSeasons + 1, mainHeading)
	builder:tag('tr')
		   :tag('th')
		   :attr('rowspan', '2')
		   :css('background', '#CCCCFF')
		   :css('text-align', 'center')
		   :css('vertical-align', 'middle')
		   :wikitext(data.i18n.publication)
		   :done()
		   :tag('th')
		   :attr('colspan', #activeSeasons)
		   :css('background', '#CCCCFF')
		   :css('vertical-align', 'middle')
		   :wikitext(data.i18n.score)
	builder = builder:tag('tr')
	for _, v in ipairs(activeSeasons) do
		builder:tag('th'):wikitext(data.seasons[v].name)
	end
end

local function makeRatingHeaderRow()
	local row = mw.html.create('tr')
	row
		:tag('th')
			:attr('scope', 'col')
			:wikitext('Source')
			:done()
		:tag('th')
			:attr('scope', 'col')
			:wikitext('Rating')
	return row
end

local function getScore(scoreArgs, length)
	for i = 1, length do
		local arg = scoreArgs[i]
		if arg then
			return arg
		end
	end
	return nil
end

local function hasDuplicateScores(scoreArgs, length)
	local count = 0
	for i = 1, length do
		local arg = scoreArgs[i]
		if arg then
			count = count + 1
		end
	end
	return count > 1
end

local function makeRatingsBySystem(builder, code, name, activeSeasons, args, na)
	builder = builder:tag('tr')
	builder:tag('td')
		   :css('vertical-align', 'middle')
		   :wikitext(name)

	for _, v in ipairs(activeSeasons) do
		local combinedCode = code .. '_' .. v
		local cell = builder:tag('td')
		if args[combinedCode] then
			cell
					:css('vertical-align', 'middle')
					:css('text-align', 'center')					
					:wikitext(args[combinedCode])
		elseif na then
			cell
					:css('color', '#707070')
					:css('vertical-align', 'middle')
					:css('text-align', 'center')
					:addClass('table-na')
					:wikitext(data.i18n.na)
		end
	end
end

local function ucfirst(s)
	local first = s:sub(1, 1)
	local others = s:sub(2, -1)
	return first:upper() .. others
end

local function getArgPermutations(args, prefix, num, suffix)
	local prefixUpper = ucfirst(prefix)
	local suffixUpper = ucfirst(suffix)
	return {
		args[prefix .. num .. suffix],
		args[prefixUpper .. num .. suffix],
		args[prefix .. num .. suffixUpper],
		args[prefixUpper .. num .. suffixUpper],
	}, 4 -- The 4 is the length of the array; this is needed as the args may be nil
end

local function makeWikilink(page, display)
	if not page and not display then
		error('no arguments provided to makeWikilink', 2)
	elseif display and not page then
		return display
	elseif page and not display or page == display then
		return string.format('[[%s]]', page)
	else
		return string.format('[[%s|%s]]', page, display)
	end
end

local function findSortText(wikitext)
	-- Simplified wikitext parser that returns a value that can be used for
	-- sorting.
	wikitext = mw.text.killMarkers(wikitext)
	-- Replace piped links with their display values
	wikitext = wikitext:gsub('%[%[[^%]]*|([^%]]-)%]%]', '%1')
	-- Replace non-piped links with their display values
	wikitext = wikitext:gsub('%[%[([^%]]-)%]%]', '%1')
	-- Strip punctuation
	wikitext = wikitext:gsub('%p', '')
	-- Trim whitespace
	wikitext = wikitext:gsub('^%s*', ''):gsub('%s*$', '')
	return wikitext
end

function p._main(args)
	local root = mw.html.create()
	local tableRoot = root:tag('table')

	-- Table base
	tableRoot
		:addClass('wikitable')
		:addClass( (args.align == 'left') and 'floatleft' or 'floatright' )
		:css('float', (args.align == 'left') and 'left' or 'right')
		:css('clear', (args.align == 'left') and 'left' or 'right')
		:css('width', args.width or '24.2em')
		:css('font-size', '80%')
		:css('text-align', 'center')
		:css('margin', (args.align == 'left') and '0.5em 1em 0.5em 0' or '0.5em 0 0.5em 1em')
		:css('padding', 0)
		:css('border-spacing', 0)
		:tag('caption')
			:attr('scope', 'col')
			:attr('colspan', 2)
			:css('font-size', '120%')
			:wikitext(args.title or 'Professional ratings')

	-- Subtitle
	if args.subtitle then
		tableRoot:node(makeHeaderRow(args.subtitle, false, false))
	end
	
	-- Season columns
	local function getProvidedSeasons(args, useSeasons)
	local providedSeasons = {}
	if useSeasons then
		local seen = {}
		for k in pairs(args) do
			local splitPos = string.find(k, '_')
			if splitPos then
				local halfarg = string.sub(k, 1, splitPos - 1)
				if not seen[halfarg] then
					seen[halfarg] = true
					if data.seasons[halfarg] then
						table.insert(providedSeasons, halfarg)
					end
				end
			end
		end
	else
		for k in pairs(args) do
			if not string.find(k, '_') then
				if data.seasons[k] then
					table.insert(providedSeasons, k)
				end
			end
		end
	end
	table.sort(providedSeasons, function(a, b)
		return data.seasons[a].sortkey < data.seasons[b].sortkey
	end)
	return providedSeasons
end

	-- Aggregate rows
	local aggregateNums = mTableTools.affixNums(args, 'aggregate')
	if args.MC or args.RT or #aggregateNums > 0 then
		tableRoot:node(makeHeaderRow('Aggregate scores', true, true))
		tableRoot:node(makeRatingHeaderRow())

		-- Assemble all of the aggregate scores
		local aggregates = {}
		if args.MC then
			table.insert(aggregates, {
				name = '[[Metacritic]]',
				sort = 'Metacritic',
				score = args.MC,
			})
		end
		if args.RT then
			table.insert(aggregates, {
				name = '[[Rotten Tomatoes]]',
				sort = 'Rotten Tomatoes',
				score = args.RT,
			})
		end
		for i, num in ipairs(aggregateNums) do
			local name = args['aggregate' .. num]
			local sort = findSortText(name)
			local score = args['aggregate' .. num .. 'score']
			table.insert(aggregates, {
				name = name,
				sort = sort,
				score = score,
			})
		end

		-- Sort the aggregates
		if not args.aggregatenosort then
			table.sort(aggregates, function (t1, t2)
				return t1.sort < t2.sort
			end)
		end

		-- Add the aggregates to the HTML
		for i, t in ipairs(aggregates) do
			tableRoot:node(makeRow(t.name, t.score))
		end
	end

	-- Review rows
	local reviewNums = mTableTools.affixNums(args, 'rev')
	local duplicateScores = false
	tableRoot:node(makeHeaderRow('Review scores', true, true))
	tableRoot:node(makeRatingHeaderRow())
	for i, num in ipairs(reviewNums) do
		local scoreArgs, nScoreArgs = getArgPermutations(args, 'rev', num, 'score')
		tableRoot:node(makeRow(
			args['rev' .. num],
			getScore(scoreArgs, nScoreArgs)
		))
		if not duplicateScores and hasDuplicateScores(scoreArgs, nScoreArgs) then
			duplicateScores = true
		end
	end

	return tostring(root)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = {
					'Template:TV ratings',
					'Template:Film and game ratings'
					}
	})
	return p._main(args)
end

return p