require('Module:No globals')

local getArgs = require('Module:Arguments').getArgs
local p = {}

local function usedRow(args, maxLine)
	local usedRow = {}
	
	for lineNum = 1, 3 do -- rowHeader has 3 items
		local row = string.char(lineNum + 64) -- 1 => 'A', 2 => 'B'
		for line = 1, maxLine do
			if args[line .. row] then
				table.insert(usedRow, row)
				break
			end
		end
	end
	
	return usedRow
end

local function row(builder, args, usedRow, line)
	if args[line] == nil then return end
	
	local tr = builder:tag('tr')
	local th = tr:tag('th')
	th
		:wikitext(args[line])
		:attr('scope', 'row')
		:css('background-color', 'transparent')
		:css('text-align', 'center')
		:css('vertical-align', 'middle')
	
	if args[line .. 'W'] then -- 'W' for worldwide
		tr:tag('td')
			:css('text-align', 'center')
			:css('vertical-align', 'middle')
			:attr('colspan', table.maxn(usedRow))
			:wikitext(args[line .. 'W'])
		return
	end
	
	for index, row in ipairs(usedRow) do
		local text = args[line .. row] or ''
		if string.lower(text) ~= 'left' then
			local colspan = 1
			for flag = index + 1, table.maxn(usedRow) do
				if string.lower(args[line .. usedRow[flag]] or '') == 'left' then
					colspan = colspan + 1
				else
					break
				end
			end
			local td = tr:tag('td')
			td
				:css('text-align', 'center')
				:css('vertical-align', 'middle')
			if string.lower(text) == 'n/a' then
				td:wikitext('N/A')
					:addClass('table-na')
					:css('background-color', '#ececec')
					:css('color', 'grey')
			else
				td:wikitext(text)
			end
			if colspan > 1 then
				td:attr('colspan', colspan)
			end
		end
	end
	
end

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	-- Main module code goes here.
	local builder = mw.html.create('table')
	local maxLine = 24
	local usedRow = usedRow(args, maxLine)
	local rowHeader = {
		A = '<abbr title="Japan">JP</abbr>',
		B = '<abbr title="North America">NA</abbr>',
		C = '<abbr title="Europe and/or Australasia">EU</abbr>',
	}

	builder:addClass('infobox wikitable'):css('margin-top', '0')
	builder:tag('caption'):wikitext(args.title or 'Release years by platforms'):css('padding', '0')
	
	local tr = builder:tag('tr')

	tr:tag('th'):attr('scope', 'col')
	for _, row in ipairs(usedRow) do
		if args['region' .. row] then
			rowHeader[row] = args['region' .. row]
		end
		tr:tag('th'):wikitext(rowHeader[row]):attr('scope', 'col')
	end
	
	for line = 1, maxLine do
		row(builder, args, usedRow, line)
	end
	
	return builder
end

return p