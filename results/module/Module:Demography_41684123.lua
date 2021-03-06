-- This module implements {{demography}}.

local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')

local p = {}

-- Often-used functions.
local floor = math.floor

----------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------

function p.isInteger(v)
	if type(v) == 'number' and floor(v) == v then
		return true
	else
		return false
	end
end

function p.getArgNums(args)
	local isInteger = p.isInteger
	local nums = {}
	for k, v in pairs(args) do
		if isInteger(k) then
			nums[#nums + 1] = k
		end
	end
	table.sort(nums)
	return nums
end			

----------------------------------------------------------------------------
-- Main functions
----------------------------------------------------------------------------

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	local years = p.getArgNums(args)
	local isEmbedded = yesno(args.embed)
	local border = not isEmbedded and '1px solid #999' or nil
	local padding = not isEmbedded and '4px' or nil
	local dateRows = p.renderDateRows(args, years, border, padding)
	local dateRowLength = #years + 1
	local root
	if isEmbedded then
		root = mw.html.create()
	else
		root = mw.html.create('table')
		root
			:css('margin-left', 'auto')
			:css('margin-right', 'auto')
			:css('border', border)
			:css('border-collapse', 'collapse')
			:css('background-color', '#f3fff3')
		if not args.noheader then
			local currentTitle = mw.title.getCurrentTitle()
			local source = args.source
			root:tag('caption')
				:css('margin-bottom', '0.5em')
				:css('font-size', '1.1em')
				:css('font-weight', 'bold')
				:wikitext(
					(args.caption or 'Historical population of ' .. currentTitle.prefixedText)
					.. (source and ' <br /><small>(Source: ' .. source .. ')</small>' or '')
				)
		end
	end
	root:wikitext(dateRows)
	local noDoubleYear = args.sansdoublescomptes or args.withoutdoublecount
	if noDoubleYear then
		local annualSurvey = args['enquêteannuelle'] or args.annualsurvey
		root:tag('tr')
			:tag('td')
				:attr('colspan', dateRowLength)
				:css('border', border)
				:css('padding', padding)
				:css('text-align', 'center')
				:tag('small')
					:wikitext(
						'From the year ' .. noDoubleYear .. ' on: No double counting&mdash;'
						.. 'residents of multiple communes (e.g. students and military personnel)'
						.. ' are counted only once.'
						.. (
							annualSurvey
							and ' <br />' .. annualSurvey .. ': Provisional population (annual survey).'
							or ''
						)
					)
	end
	return tostring(root)
end

function p.renderDateRows(args, years, border, padding)
	local root = mw.html.create()
	local hrow = root:tag('tr')
	hrow
		:css('background', '#ddffdd')
		:tag('th')
			:attr('scope', 'row')
			:css('border', border)
			:css('padding', padding)
			:wikitext('Year')
	for i, year in ipairs(years) do
		if year < 0 then
			year = '&minus;' .. tostring(year * -1)
		else
			year = tostring(year)
		end
		hrow:tag('th')
			:css('border', border)
			:css('padding', padding)
			:wikitext(year)
	end
	local drow = root:tag('tr')
	drow
		:tag('th')
			:attr('scope', 'row')
			:css('border', border)
			:css('padding', padding)
			:wikitext('Population')
	for i, year in ipairs(years) do
		drow:tag('td')
			:css('border', border)
			:css('padding', padding)
			:css('text-align', 'center')
			:wikitext(args[year])
	end
	return tostring(root)
end

return p