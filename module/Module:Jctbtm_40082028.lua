local p = {}

local types = mw.loadData("Module:Road data/RJL types")

local row

local columns = {   -- Constants for how many columns different list types should have.
	default = 6,    -- default
	exit = 7,       -- default + exit number
	old = 8,        -- default + exit number + old exit number
}

local function parameterParser(args)
	local keysParam = args.keys
	if not(keysParam) then return {} end
	local keys = mw.text.split(keysParam, ",")
	table.sort(keys)
	return keys
end

local function createLegend(key)
	local legend = row:tag('div'):addClass('hlist'):cssText("margin-left:1.6em;text-align:center;font-size:90%"):tag('ul')
	for k,v in ipairs(key) do
		local type = types[v]
		if type then
			legend:tag('li'):tag('span'):css('border', '1px solid #000'):css('background-color', type.color):css('color', type.color):wikitext("&nbsp;&nbsp;&nbsp;&nbsp;"):done():wikitext("&nbsp; "):wikitext(type.jctbtm)
		end
	end
end

function p._jctbtm(args)
	local root = mw.html.create()
	row = root:tag('tr'):tag('td')
	local cols = args.col or columns[args[1]] or columns.default -- Compute the number of columns, either from an explicit parameter, or by looking at the columns table.
	row:attr('colspan', cols):addClass('wikitable hlist'):css("text-align", "center"):css("background-color", "#eaecf0") -- Define the footer.
	
	if (args.conv or 'yes') == 'yes' then
		row:wikitext("1.000&nbsp;mi = 1.609&nbsp;km; 1.000&nbsp;km = 0.621&nbsp;mi<br>")
	end
	
	local key = parameterParser(args)
	if key[1] then createLegend(key) end
	
	local keyParam = args.key
	if keyParam then -- This is a deprecated parameter
		local page = mw.title.getCurrentTitle()
		local pagename = page.prefixedText
		row:wikitext(string.format("[[Category:Jctbtm temporary tracking category|# %s]]", pagename))
	end
	
	row:wikitext(args.notes or args.key) -- If additional notes are provided, display them.
	
	if #row.nodes == 0 then
		return '|-\n|}'
	else
		return tostring(root) .. '\n|-\n|}'
	end
end

function p.jctbtm(frame)
	return p._jctbtm(require('Module:Arguments').getArgs(frame))
end

return p