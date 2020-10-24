local p = {}

local function format_it(tbl, name)
	for i, v in ipairs(tbl) do
		tbl[i] = string.format("%06x", tbl[i])	
	end
	p[name] = tbl
end

local function mod(a, b)
	return a - math.floor(a/b) * b
end

-- takes hex color as string, gives back table
local function colorTable(color)
	local clen = string.len(color)
	assert(clen >= 6 and clen <= 8)
	assert(string.gmatch("^"..("[0-9a-fA-F]"):rep(6)..("[0-9a-fA-F]?"):rep(2).."$", color))
	local ret = {}
	ret["R"] = tonumber(color:sub(1,2), 16)
	ret["G"] = tonumber(color:sub(3,4), 16)
	ret["B"] = tonumber(color:sub(5,6), 16)
	ret["A"] = tonumber(color:sub(7,8), 16) or 255
	return ret
end
local black = colorTable("000000")
local white = colorTable("FFFFFF")

local function colorAsRGBA(colorTbl)
	return string.format("rgba(%.2f,%.2f,%.2f,%.2f)", 
						 colorTbl["R"], colorTbl["G"], 
						 colorTbl["B"], colorTbl["A"])
end

-- simple mix of two colors. t_ means target. percent is as float (.4=40%)
local function colorMix(colorTbl, t_colorTbl, percent)
	local ret = {}
	local diff = {}
	diff["R"] = t_colorTbl["R"] - colorTbl["R"] 
	diff["G"] = t_colorTbl["G"] - colorTbl["G"] 
	diff["B"] = t_colorTbl["B"] - colorTbl["B"] 
	diff["A"] = t_colorTbl["A"] - colorTbl["A"]
	ret["R"] = colorTbl["R"] + (diff["R"] * percent)
	ret["G"] = colorTbl["G"] + (diff["G"] * percent)
	ret["B"] = colorTbl["B"] + (diff["B"] * percent)
	ret["A"] = colorTbl["A"] + (diff["A"] * percent)
	return ret
end

p.HTML = function(frame, page)
	local args = require('Module:Arguments').getArgs(frame)
	p.args = args
	local ret = ''
	local inp = args[1]
	if not inp then return nil end
	local steps = mw.ustring.len(inp)
	local repeat_ = (args["repeat"] and tonumber(args["repeat"])) or 1
	
	local newcolors = {}
	if args.colors then
		for k = 1, repeat_, 1 do
			nc = mw.text.gsplit(args.colors, ",", true)

			for c in nc do
				newcolors[#newcolors+1] = tonumber(c:sub(2, -1), 16)
			end
		end
	end

	format_it(#newcolors > 0 and newcolors or
	--         red       orange    yellow    green     blue      indigo-violet
			  {0xFF0000, 0xFF7F00, 0xFFFF00, 0x00FF00, 0x0000FF, 0x8B00FF}, "roygbiv")

	-- lua pattern from https://stackoverflow.com/questions/13235091/extract-the-first-letter-of-a-utf-8-string-with-lua
	local i = 0
	for c in inp:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		local color = colorTable(p.roygbiv[mod(i, #p.roygbiv)+1])
		
		local s_per = steps / #p.roygbiv
		local j = (i / s_per)
		local jf = math.floor(j)
		if args.gradient then
			local cidx = mod(jf, #p.roygbiv)+1
			if mod(cidx, 2) == 0 then cidx = cidx + 1 end
			if cidx > #p.roygbiv then cidx = #p.roygbiv end
			color = colorTable(p.roygbiv[cidx])
			
			local tidx = mod(jf+1, #p.roygbiv)+1
			if mod(tidx, 2) == 1 then tidx = tidx + 1 end
			if tidx > #p.roygbiv then tidx = cidx end
			local tcolor = colorTable(p.roygbiv[tidx])
			
			color = colorMix(color, tcolor, mod(j, 1))
		end
		local subdued = nil
		if args.theme then 
			subdued = args.theme:match("^subdued(%d+)%%$")
		end
		if subdued then
			color = colorMix(color, black, tonumber(subdued) / 100)	
		end
		assert(color)
		if args.bg ~= "y" then
		local rgba = colorAsRGBA(color)
		ret = (ret .. "<span style='" .. (args.bg == "black" and "background-color:black;" or "")
			       .. "color:" .. rgba .. ";'>" .. c .."</span>")
		else
		local rgba = colorAsRGBA(args.fgcolor and colorTable(args.fgcolor:sub(2, -1)) or black)
		ret = (ret .. "<span style='background-color:" .. colorAsRGBA(color) .. ";"
			       .. "color:" .. rgba .. "'>" .. c .."</span>")
		end
		i = i + 1
	end
	
	return ret
end

return p