local p = {}

local types = mw.loadData("Module:Road data/RJL types")
local getArgs = require('Module:Arguments').getArgs -- Import module function to work with passed arguments

local row

local function parameterParser(args)
	local keysParam = args.keys
	if not(keysParam) then return {} end
	local keys = mw.text.split(keysParam, ",")
	table.sort(keys)
	return keys
end

local function createLegend(key)
	local format = mw.ustring.format
	local legend = row:tag('div'):attr('class', "hlist"):cssText("margin-left: 1.6em; text-align: center; font-size:90%;"):tag('ul')
	for k,v in ipairs(key) do
		local type = types[v]
		if type then
			legend:tag('li'):tag('span'):css('border', '1px solid #000'):css('background-color', type.color):css('color', type.color):wikitext("&nbsp;&nbsp;&nbsp;&nbsp;"):done():wikitext("&nbsp; "):wikitext(type.routelist)
		end
	end
end

function p._bottom(args)
	local root = mw.html.create('tr'):attr('class', "sortbottom")
	row = root:tag('td')
	row:attr('colspan', "9"):attr('class', "wikitable hlist"):css("text-align", "center"):css("background-color", "#f2f2f2") -- Define the footer.
	
	local conversion
	local conv = args.conv or 'no'
	if conv == 'yes' then
		conversion = "1.000&nbsp;mi = 1.609&nbsp;km; 1.000&nbsp;km = 0.621&nbsp;mi<br>"
	end
	row:wikitext(conversion)
	
	local key = parameterParser(args)
	if key[1] then createLegend(key) end
	
	local nodes = row.nodes
	if #nodes == 0 then
		return '|-\n|}'
	else
		return tostring(root) .. '\n|-\n|}'
	end
end

function p.bottom(frame)
	local args = getArgs(frame)
	return p._bottom(args)
end

return p