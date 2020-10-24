require('Module:No globals')

local getArgs = require('Module:Arguments').getArgs
local roundAndPad = require('Module:Math')._precision_format

local p = {}

local function total(frame, played, won, drawn, lost, category)
	if played == '-' or played == '—' then
		return '—'
	elseif not played then
		if not won and not drawn and not lost then
			return ''
		end
		return frame:expandTemplate{title = 'Number table sorting', args = { (won or 0) + (drawn or 0) + (lost or 0) }}
	elseif tonumber(played) ~= (won or 0) + (drawn or 0) + (lost or 0) then
		return '<span class="error" style="font-size:100%"><abbr title="GP not equal to W + D + L">error</abbr>' .. (category or '') .. '</span>'
	else
		return frame:expandTemplate{title = 'Number table sorting', args = { played }}
	end
end

local function displayWinPercent(frame, winPercent, decimals)
	local retval = ''
	if winPercent < 10 then
		retval = '<span style="visibility:hidden;color:transparent;">00</span>'
	elseif winPercent < 100 then
		retval = '<span style="visibility:hidden;color:transparent;">0</span>'
	end
	return retval .. frame:expandTemplate{title = 'Number table sorting', args = { roundAndPad(winPercent, decimals or 2) }}
end

local function pct(frame, played, won, drawn, lost, decimals)
	if played == '-' or played == '—' then
		return '—'
	elseif not played then
		if not won and not drawn and not lost then
			return ''
		elseif (won or 0) + (drawn or 0) + (lost or 0) <= 0 then
			return '<span style="display:none">!</span>—'
		end
		return displayWinPercent(frame, 100 * (won or 0) / (((won or 0) + (drawn or 0) + (lost or 0)) or 1), decimals)
	elseif tonumber(played) <= 0 then
		return '<span style="display:none">!</span>—'
	else
		return displayWinPercent(frame, 100 * (won or 0) / played, decimals)
	end
end

function p.main(frame, otherargs)
	local args = otherargs or getArgs(frame)
	local tableprefix = string.format('| style="%stext-align:%s" |', args.total and 'font-weight:bold;background:#efefef;' or '', args.align or 'center')
	local retval = tableprefix .. total(frame, args[1], args[2], args[3], args[4], args.demospace and '' or '[[Category:WDL error]]') .. '\n'
	retval = retval .. tableprefix .. frame:expandTemplate{title = 'Number table sorting', args = { args[2] }} .. '\n'
	retval = retval .. tableprefix .. frame:expandTemplate{title = 'Number table sorting', args = { args[3] }} .. '\n'
	retval = retval .. tableprefix .. frame:expandTemplate{title = 'Number table sorting', args = { args[4] }} .. '\n'
	if args['for'] then
		retval = retval .. tableprefix .. frame:expandTemplate{title = 'Number table sorting', args = { args['for'] }} .. '\n'
	end
	if args.against then
		retval = retval .. tableprefix .. frame:expandTemplate{title = 'Number table sorting', args = { args.against }} .. '\n'
	end
	if args.diff == 'yes' then
		if tonumber(args['for']) and tonumber(args.against) then
			retval = retval .. tableprefix .. string.format('%s%d\n', tonumber(args['for']) < tonumber(args.against) and '−' or '+', math.abs(args['for'] - args.against))
		else
			retval = retval .. tableprefix .. '<span style="display:none">!</span>—\n'
		end
	end
	return retval .. tableprefix .. pct(frame, args[1], args[2], args[3], args[4], args.decimals)
end

return p