-- This module implements [[Template:Album ratings]].

local mTableTools = require('Module:TableTools')
local yesno = require('Module:Yesno')
local p = {}

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
			:css('background', background ~= false and '#d1dbdf' or nil)
			:css('font-size', '120%')
			:wikitext(header)
	return row
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

	-- Aggregate rows
	local aggregateNums = mTableTools.affixNums(args, 'aggregate')
	if args.MC or args.ADM or args.AOTY or #aggregateNums > 0 then
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
		if args.ADM then
			table.insert(aggregates, {
				name = '[[AnyDecentMusic?]]',
				sort = 'AnyDecentMusic?',
				score = args.ADM,
			})
		end
		if args.AOTY then
			table.insert(aggregates, {
				name = '[[Album of the Year (website)|Album of the Year]]',
				sort = 'Album of the Year?',
				score = args.AOTY,
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

	-- Tracking category
	if mw.title.getCurrentTitle().namespace == 0 and yesno(args.noprose) then
		root:wikitext('[[Category:Articles with album ratings that need to be turned into prose]]')
	end
	if duplicateScores then
		root:wikitext('[[Category:Pages using album ratings with duplicate score parameters]]')
	end

	return tostring(root)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Album ratings'
	})
	return p._main(args)
end

return p