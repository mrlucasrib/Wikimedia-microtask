-- This implements {{change}}
local p = {}

local function ntsh(outvalue)
	local sortkey = '0000000000000000000'
	if outvalue == nil then
		return '<span style="display:none" data-sort-value="' .. sortkey .. '♠"></span>'
	end
	
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

local function trim(s)
	return s:match('^%s*(.-)%s*$')
end

local function isnotempty(s)
	return s and trim(s) ~= ''
end

function change(args)
	local rnd = require('Module:Math')._round
	local prec_format = require('Module:Math')._precision_format
	local lang = mw.getContentLanguage()
	local function formatnum(num)
		return lang:parseFormattedNumber(num) and lang:formatNum(lang:parseFormattedNumber(num)) or num
	end
	
	local errorflag = nil
	
	local dsp = args['disp'] or 'row'
	local inv = args['invert'] or 'off'
	local srt = args['sort'] or ((isnotempty(args['pre']) or isnotempty(args['sort'])) and 'on' or 'off')
	local n1 = (inv == 'on') and tonumber(lang:parseFormattedNumber(args['2'])) or tonumber(lang:parseFormattedNumber(args['1']))
	local n2 = (inv == 'on') and tonumber(lang:parseFormattedNumber(args['1'])) or tonumber(lang:parseFormattedNumber(args['2']))
	local dec = args['dec'] or '2'
	local s = ((args['italics'] or 'off') == 'on' and "''" or "")
			.. ((args['bold'] or 'off') == 'on' and "'''" or "")
	
	local pc, pcr, pcrf = 'NA', 'NA'
	
	if n1 and n2 and n1 ~= 0 then
		pc = 100*(n2/n1 - 1)
		pcr = rnd(pc, dec)
		if pcr > 0 then
			pcrf = '<span style="color:green">' ..
				s .. '+' .. prec_format(pc, dec) .. '%' .. s .. '</span>'
		elseif pcr < 0 then
			pcrf = '<span style="color:red">' ..
				s .. prec_format(pc, dec) .. '%' .. s .. '</span>'
		else
			pcrf = s .. prec_format(0, dec) .. '%' .. s
		end
		pcrf = ntsh(pcr) .. pcrf
	else
		pcrf = ntsh(nil) .. s .. 'NA' .. s
		if n1 == nil or n2 == nil then
			errorflag = 1
		end
	end
	
	if dsp == 'out' then
		return pcrf, errorflag
	else
		local pre1 = args['pre1'] or args['pre'] or ''
		local pre2 = args['pre2'] or args['pre'] or ''
		local suf1 = args['suf1'] or args['suf'] or ''
		local suf2 = args['suf2'] or args['suf'] or ''

		local rspn = 'rowspan=' .. (args['rowspan'] or '1') .. ' '
		local algn = 'text-align:' .. (args['align'] or 'right') .. ';'
		local bg = 'background-color:' .. (args['bgcolour'] or args['bgcolor'] or 'inherit') .. ';'

		if rspn == 'rowspan=1 ' then rspn = '' end
		if bg == 'background-color:inherit;' then bg = '' end
		local style = rspn .. 'style="' .. algn .. bg .. '"'
		
		local sk1, sk2 = '', ''
		
		if srt == 'on' then
			sk1 = ntsh(n1)
			sk2 = ntsh(n2)
		end
		
		if n1 ~= nil then
			if n1 < 0 then
				n1 = '−' .. formatnum(-1*n1)
			else
				n1 = formatnum(n1)
			end
		else
			n1 = (inv == 'on') and (args['2'] or '') or (args['1'] or '')
		end
		
		if n2 ~= nil then
			if n2 < 0 then
				n2 = '−' .. formatnum(-1*n2)
			else
				n2 = formatnum(n2)
			end
		else
			n2 = (inv == 'on') and (args['1'] or '') or (args['2'] or '')
		end
		
		if dsp == 'row2' then
			return style .. '|' .. s .. pre2 .. n2 .. suf2 .. s
				.. '\n|' .. style .. '|' .. pcrf, errorflag
		else
			if inv == 'off' then
				return style .. '|' .. s .. pre1 .. n1 .. suf1 .. s
					.. '\n|' .. style .. '|' .. s .. pre2 .. n2 .. suf2 .. s
					.. '\n|' .. style .. '|' .. pcrf, errorflag
			else
				return style .. '|' .. s .. pre1 .. n2 .. suf1 .. s
					.. '\n|' .. style .. '|' .. s .. pre2 .. n1 .. suf2 .. s
					.. '\n|' .. style .. '|' .. pcrf, errorflag
			end
		end
	end
end

function p.main(frame)
	local res, eflag = change((frame.args[1] or frame.args[2]) and frame.args or frame:getParent().args)
	if eflag then
		res = res .. frame:expandTemplate{title = 'change/error'}
	end
	return res
end

return p