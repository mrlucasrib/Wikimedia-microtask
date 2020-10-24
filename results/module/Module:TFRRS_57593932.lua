local p = {}

function p.TFRRS(frame)
	local f = frame.args
	local pf = frame:getParent().args
	local turls = {}
	local ids = {}
	local xcs = {}
	local labels = {}
	local nameslugs = {}
	local teamslugs = {}
	local maxparam = 0
	if pf[1] or pf['id'] then
		ids[1] = pf[1] or pf['id']
		maxparam = 1
	end
	if pf['nameslug'] then
		nameslugs[1] = pf['nameslug']
	end
	if pf['teamslug'] then
		teamslugs[1] = pf['teamslug']
	end
	if pf['xc'] then
		xcs[1] = pf['xc']
	end
	for k, v in pairs(pf) do
		if type(k) == 'string' then
			paramno = tonumber(string.match(k, '^%a*([1-9][0-9]*)$'))
			if paramno then
				if paramno > maxparam then
			    	maxparam = paramno
			    end
				if k:find('^id[1-9][0-9]*$') then
					ids[paramno] = v
				elseif k:find('^label[1-9][0-9]*$') then
					labels[paramno] = v
				elseif k:find('^xc[1-9][0-9]*$') then
					xcs[paramno] = v
				elseif k:find('^nameslug[1-9][0-9]*$') then
					nameslugs[paramno] = v
				elseif k:find('^teamslug[1-9][0-9]*$') then
					teamslugs[paramno] = v
				end
			end
		end
	end
	for i = 1, maxparam do
		if xcs[i] then
			turls[i] = 'https://xc.tfrrs.org/athletes/'
		else
			turls[i] = 'https://www.tfrrs.org/athletes/'
		end
		turls[i] = turls[i] .. ids[i]
		if nameslugs[i] and teamslugs[i] then
			turls[i] = turls[i] .. '/' .. teamslugs[i] .. '/' .. nameslugs[i] .. '.html'
		end
		if labels[i] then
			turls[i] = turls[i] .. ' ' .. labels[i]
		end
    end
	if maxparam == 1 then
		return '[' .. turls[1] .. ' ' .. f['name'] .. '] profile at [https://tfrrs.org TFRRS]'
	else
		for i = 1, maxparam do
			turls[i] = '[' .. turls[i] .. ']'
		end
	end
	local prefix = '\'\'\'' .. f['name'] .. '\'\'\' ' .. ' profiles at [https://tfrrs.org TFRRS]: '
	return prefix .. table.concat(turls, ', ')
end

return p