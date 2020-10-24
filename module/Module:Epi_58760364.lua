local p = {}
local lang = mw.getContentLanguage()

local function formatnum(num)
	return lang:parseFormattedNumber(num) and lang:formatNum(lang:parseFormattedNumber(num)) or num
end

local function ntsh(outvalue)
	-- This code was copied from [[Template:Convert]]	
	if outvalue == 0 then
		sortkey = '5000000000000000000'
	else
		local mag = math.floor(math.log10(math.abs(outvalue)) + 1e-14)
		local prefix
		if outvalue > 0 then
			prefix = 7000 + mag
		else
			prefix = 2999 - mag
			outvalue = outvalue + 10^(mag+1)
		end
		sortkey = string.format('%d', prefix) .. string.format('%015.0f', math.floor(outvalue * 10^(14-mag)))
	end
	return '<span style="display:none" data-sort-value="' .. sortkey .. '♠"></span>'
end

local function cvt(n1, u1, e, u2, d, fac, fmt, l, flip)

	local rnd = require('Module:Math')._round
	local so, sc = '', ''
	if n1 < 0 then
		so, sc = '<span style="color:red">', '</span>'
	end
	local n2 = formatnum(rnd(n1/fac,tonumber(d) or 0)) .. '&nbsp;' .. u2
	if fmt then
		n1 = formatnum(rnd(n1,tonumber(e) or 0)) .. '&nbsp;' .. u1
	else
		n1 = rnd(n1,tonumber(e) or 0) .. '&nbsp;' .. u1
	end
	if flip then
		if l == '1' then
			return so .. n2 .. ' (' .. n1 .. ')'
		else
			return so .. n2 .. '<br/>' .. n1
		end
	else
		if l == '1' then
			return so .. n1 .. ' (' .. n2 .. ')'
		else
			return so .. n1 .. '<br/>' .. n2
		end
	end
	
	return n1
end

local function moft(n, e, d, l, s, p, flip)
	if tonumber(n) then
		n = tonumber(n)
		fmt = true
		if (math.abs(n) > 900) and (math.abs(n) < 9000) then fmt = false end
		return ntsh(n) .. cvt(n, 'm', e, 'ft', d, 0.3048, fmt, l, flip)
	end
	return ntsh(0) .. s .. p .. n .. s
end

local function kmomi(n, l, s, p, flip)
	if tonumber(n) then
		n = tonumber(n)
		local fmt = true
		local e, d = 0, 0
		if n < 19.995 then
			e = 2
		elseif n < 199.95 then
			e = 1
		end
		if n < 32.179 then
			d = 2
		elseif n < 321.789 then
			d = 1
		end
		return ntsh(n * 1000) .. cvt(n, 'km', e, 'mi', d, 1.609344, fmt, l, flip)
	end
	return ntsh(-1e10) .. s .. p .. n .. s
end

function p.main(frame)
	local args = frame:getParent().args
	local elev_m = (args[1] or '')
	local prom_m = (args[2] or '')
	local iso_km = (args[3] or '')
	local a = 'align=' .. (args['a'] or 'center')
	local r = (args['r'] or '1') ~= '1' and (' rowspan=' .. args['r']) or ''
	local d = args['d'] or '0' -- input precision
	local e = args['e'] or d   -- output precision
	local l = args['l'] or '2' -- ?
	local p = args['p'] or ''  -- prefix
	local s = args['s'] or ''  -- italics and/or bold formatting
	
	if prom_m == '>500' then
		prom_m = '500'
		p = p .. '>'
	end
	
	local flip = (args['m'] or '1') == '2'
	local elev = '|' .. a .. r .. '|' .. moft(elev_m, e, d, l, s, p, flip) 
	local prom = '|' .. a .. r .. '|' .. moft(prom_m, d, d, l, s, p, flip)
	local iso  = '|' .. a .. r .. '|' .. kmomi(iso_km, l, s, p, flip) 
	return elev .. '|' .. prom .. '|' .. iso
end

return p