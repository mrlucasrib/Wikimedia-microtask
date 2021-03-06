local p = {}

local function trim(s)
	return s:match('^%s*(.-)%s*$')
end

local function isnotempty(s)
	return s and s:match('%S')
end

function p.check(frame)
	local args = frame.args
	local pargs = frame:getParent().args
	local checknested = isnotempty(args['nested'])
	local delimiter = isnotempty(args['delimiter']) and args['delimiter'] or ';'
	local cat = ''
	if args['cat'] and mw.ustring.match(args['cat'],'^[Cc][Aa][Tt][Ee][Gg][Oo][Rr][Yy]:') then
		cat = args['cat']
	end
	local res = ''

	local argpairs = {}
	for k, v in pairs(args) do
		if type(k) == 'number' then
			local plist = mw.text.split(v, delimiter)
			local pfound = {}
			local count = 0
			for ii, vv in ipairs(plist) do
				vv = trim(vv)
				if checknested and pargs[vv] or isnotempty(pargs[vv]) then
					count = count + 1
					table.insert(pfound, vv)
				end
			end
			if count > 1 then
				table.insert(argpairs, pfound)
			end
		end
	end
	
	local warnmsg = {}
	if #argpairs > 0 then
		for i, v in ipairs( argpairs ) do
			table.insert(warnmsg, 'Using more than one of the following parameters: <code>' ..
				table.concat(v, '</code>, <code>') .. '</code>')
			if cat ~= '' then
				res = res .. '[[' .. cat .. '|' .. (v[1] == '' and ' ' or '') .. v[1] .. ']]'
			end	
		end
	end
	
	if #warnmsg > 0 then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			local ptxt = args['template'] and args['template'] .. ' warning' or 'Warning'
			res = '<div class="hatnote" style="color:red"><strong>' .. ptxt .. ':</strong> ' .. table.concat(warnmsg, '<br>') .. '</div>' .. res
		end
	end
	
	return res
end

return p