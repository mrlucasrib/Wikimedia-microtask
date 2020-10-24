--[[
Efficient (fast) functions to implement cells in tables of weather data.
Temperature conversion is built-in, but for simplicity, temperatures
are assumed to be for habitable locations (from -100 to 100 °C).
]]

local MINUS = '−'  -- Unicode U+2212 MINUS SIGN

local function temperature_style(palette, value, out_rgb)
	-- Return style for a table cell based on the given value which
	-- should be a temperature in °C.
	local function style(bg, fg)
		local min, max = unpack(palette.white or { -23, 35 })
		if not fg and value and (value < min or value >= max) then
			fg = 'FFFFFF'
		end
		if fg then
			fg = 'color:#' .. fg .. ';'
		else
			fg = ''
		end
		return 'style="background:#' .. bg .. ';' .. fg .. ' font-size:100%;"'
	end
	if type(value) ~= 'number' then
		return style('FFFFFF', '000000')
	end
	local rgb = out_rgb or {}
	for i, v in ipairs(palette) do
		local a, b, c, d = unpack(v)
		if value <= a then
			rgb[i] = 0
		elseif value < b then
			rgb[i] = (value - a) * 255 / (b - a)
		elseif value <= c then
			rgb[i] = 255
		elseif value < d then
			rgb[i] = 255 - ( (value - c) * 255 / (d - c) )
		else
			rgb[i] = 0
		end
	end
	return style(string.format('%02X%02X%02X', rgb[1], rgb[2], rgb[3]))
end

local function format_cell(palette, value, intext, outtext)
	-- Return one line of wikitext to make a cell in a table.
	if not value then
		return '|\n'
	end
	local text
	if outtext then
		text = intext .. '<br>(' .. outtext .. ')'
	else
		text = intext
	end
	return '| ' .. temperature_style(palette, value) .. ' | ' .. text .. '\n'
end

local function process_temperature(intext, inunit, swap)
	--[[	Convert °C to °F or vice versa, assuming the temperature is for a
			habitable location, well inside the range -100 to 100 °C.
			That simplifies determining precision and formatting (no commas are needed).
			Return (celsius_value, intext, outtext) if valid; otherwise return nil.
			The returned input and output are swapped if requested.
			Each returned string has a Unicode MINUS as sign, if negative.	]]
	local invalue = tonumber(intext)
	if not invalue then return nil end
	local integer, dot, decimals = intext:match('^%s*%-?(%d+)(%.?)(%d*)%s*$')
	if not integer then return nil end
	if invalue < 0 then
		intext = MINUS .. integer .. dot .. decimals
	end
	local outtext
	if inunit == 'C' or inunit == 'F' then
		local celsius_value, outvalue
		if inunit == 'C' then
			outvalue = invalue * (9/5) + 32
			celsius_value = invalue
		else
			outvalue = (invalue - 32) * (5/9)
			celsius_value = outvalue
		end
		local precision = dot == '' and 0 or #decimals
		outtext = string.format('%.' .. precision .. 'f', math.abs(outvalue) + 2e-14)
		if outvalue < 0 and tonumber(outtext) ~= 0 then
			-- Don't show minus if result is negative but rounds to zero.
			outtext = MINUS .. outtext
		end
		if swap then
			return celsius_value, outtext, intext
		end
		return celsius_value, intext, outtext
	end
	-- LATER Think about whether a no-conversion option would be useful.
	return invalue, intext, outtext
end

local function temperature_row(palette, row, inunit, swap)
	--[[
	Return 13 lines specifying the style/content of 13 table cells.
	Input is 13 space-separated words, each a number (°C or °F).
	Any word that is not a number gives a blank cell ("M" for a missing cell).
	Any excess words are ignored.
	
	Function  Input   Output
	------------------------
	CtoF        C       C/F
	FfromC      C       F/C
	CfromF      F       C/F
	FtoC        F       F/C		]]
	local nrcol = 13
	local results, n = {}, 0
	for word in row:gmatch('%S+') do
		n = n + 1
		if n > nrcol then
			break
		end
		results[n] = format_cell(palette, process_temperature(word, inunit, swap))
	end
	for i = n + 1, nrcol do
		results[i] = format_cell()
	end
	return table.concat(results)
end

local palettes = {
	-- A background color entry in a palette is a table of four numbers,
	-- say { 11, 22, 33, 44 } (values in °C).
	-- That means the color is 0 below 11 and above 44, and is 255 from 22 to 33.
	-- The color rises from 0 to 255 between 11 and 22, and falls between 33 and 44.
	cool = {
		{ -42.75,   4.47, 41.5, 60   },
		{ -42.75,   4.47,  4.5, 41.5 },
		{ -90   , -42.78,  4.5, 23   },
		white = { -23.3, 37.8 },
	},
	cool2 = {
		{ -42.75,   4.5 , 41.5, 56   },
		{ -42.75,   4.5 ,  4.5, 41.5 },
		{ -90   , -42.78,  4.5, 23   },
		white = { -23.3, 35 },
	},
	cool2avg = {
		{ -38,   4.5, 25  , 45   },
		{ -38,   4.5,  4.5, 30   },
		{ -70, -38  ,  4.5, 23   },
		white = { -23.3, 25 },
	},
}

local function temperatures(frame, inunit, swap)
	local palette = palettes[frame.args.palette] or palettes.cool
	return temperature_row(palette, frame.args[1], inunit, swap)
end

local function CtoF(frame)
	return temperatures(frame, 'C')
end

local function CfromF(frame)
	return temperatures(frame, 'F', true)
end

local function FtoC(frame)
	return temperatures(frame, 'F')
end

local function FfromC(frame)
	return temperatures(frame, 'C', true)
end

local chart = [[
{{Graph:Chart
|width=600
|height=180
|xAxisTitle=Celsius
|yAxisTitle=__COLOR
|type=line
|x=__XVALUES
|y=__YVALUES
|colors=__COLOR
}}
]]

local function show(frame)
	--[[	For testing, return wikitext to show graphs of how the red/green/blue colors
			vary with temperature, and a table of the resulting colors.		]]
	local function collection()
		-- Return a table to hold items.
		return {
			n = 0,
			add = function (self, item)
				self.n = self.n + 1
				self[self.n] = item
			end,
			join = function (self, sep)
				return table.concat(self, sep)
			end,
		}
	end
	local function make_chart(result, color, xvalues, yvalues)
		result:add('\n')
		result:add(frame:preprocess((chart:gsub('__[A-Z]+', {
			__COLOR = color,
			__XVALUES = xvalues:join(','),
			__YVALUES = yvalues:join(','),
		}))))
	end
	local function with_minus(value)
		if value < 0 then
			return MINUS .. tostring(-value)
		end
		return tostring(value)
	end
	local args = frame.args
	local first = args[1] or -90
	local last = args[2] or 59
	local palette = palettes[args.palette] or palettes.cool
	local xvals, reds, greens, blues = collection(), collection(), collection(), collection()
	local wikitext = collection()
	wikitext:add(
[[
{| class="wikitable"
|-
]]
	)
	local columns = 0
	for celsius = first, last do
		local rgb = {}
		local style = temperature_style(palette, celsius, rgb)
		local R = math.floor(rgb[1])
		local G = math.floor(rgb[2])
		local B = math.floor(rgb[3])
		xvals:add(celsius)
		reds:add(R)
		greens:add(G)
		blues:add(B)
		wikitext:add('| ' .. style .. ' | ' .. with_minus(celsius) .. '\n')
		columns = columns + 1
		if columns >= 10 then
			columns = 0
			wikitext:add('|-\n')
		end
	end
	wikitext:add('|}\n')
	make_chart(wikitext, 'Red', xvals, reds)
	make_chart(wikitext, 'Green', xvals, greens)
	make_chart(wikitext, 'Blue', xvals, blues)
	return wikitext:join()
end

return {
	CtoF = CtoF,
	CfromF = CfromF,
	FtoC = FtoC,
	FfromC = FfromC,
	show = show,
}