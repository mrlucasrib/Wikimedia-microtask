local p = {}

function p._error( error_str )
    return '[[Category:Duration with input error]]<strong class="error">Error in Module:Duration: ' .. error_str .. '</strong>'
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {wrappers = {'Template:Duration', 'Template:Duration/sandbox'}})
	local tmp = args.duration or args[1] or ''
	local duration = {}
	if tonumber(args[1]) or args[2] or args[3] then
		if args[4] then return p._error('Parameter number 4 should not be specified') end
		if not args[1] or args[1] == '' then
			duration = {args[2] or 0, args[3] or 0}
		else
			duration = {args[1], args[2] or 0, args[3] or 0}
		end
		tmp = nil
		for k, v in ipairs(duration) do
			duration[k] = tonumber(v)
			if not duration[k] then return p._error('Invalid values') end
		end
	elseif args.h or args.m or args.s then
		if not args.h or args.h == '' then
			duration = {args.m or 0, args.s or 0}
		else
			duration = {args.h, args.m or 0, args.s or 0}
		end
		tmp = nil
		for k, v in ipairs(duration) do
			duration[k] = tonumber(v)
			if not duration[k] then return p._error('Invalid values') end
		end
	else
		if mw.ustring.find(tmp, 'class="duration"', 1, yes) then return tmp end -- if there is already a microformat, don't do anything
		duration = mw.text.split(mw.ustring.match(tmp, '%d*:?%d+:%d+%.?%d*') or '', ':') -- split into table
		if duration[4] then return p._error('Maximum of two colons allowed') end
		for k, v in ipairs(duration) do duration[k] = tonumber(v) or 0 end -- convert values to numbers
	end
	if duration[3] then
		if (duration[1] + duration[2] + duration[3]) == 0 then return nil end
		if (duration[1] ~= math.ceil(duration[1])) or (duration[2] ~= math.ceil(duration[2])) then return p._error('Hours and minutes values must be integers') end
		if duration[3] >= 60 then return p._error('Seconds value must be less than 60') end
		if duration[2] >= 60 then return p._error('Minutes value must be less than 60 if hours value is specified') end
		if duration[2] < 10 then duration[2] = '0'..duration[2] end -- zero padding
		if duration[3] < 10 then duration[3] = '0'..duration[3] end
		duration = '<span class="duration"><span class="h">' .. duration[1] .. '</span>:<span class="min">' .. duration[2] .. '</span>:<span class="s">' .. duration[3] .. '</span></span>'
	elseif duration[2] then
		if (duration[1] + duration[2]) == 0 then return nil end
		if duration[1] ~= math.ceil(duration[1]) then return p._error('Hours and minutes values must be integers') end
		if duration[2] >= 60 then return p._error('Seconds value must be less than 60') end
		if duration[2] < 10 then duration[2] = '0'..duration[2] end -- zero padding
		duration = '<span class="duration"><span class="min">' .. duration[1] .. '</span>:<span class="s">' .. duration[2] .. '</span></span>'
	else
		duration = ''
	end
	
	if tmp and tmp ~= '' then
		if duration ~= '' then tmp = mw.ustring.gsub(tmp, '%d*:?%d+:%d+%.?%d*', duration, 1) else tmp = tmp .. ' [[Category:Duration without hAudio microformat]]' end
	else
		if duration ~= '' then tmp = duration end
	end
	return tmp
end

return p