--
-- This module is being used to orphan the various Fb team and competition templates
-- It will not have any transclusions since it is substituted
--
local p = {}

function p.ground(frame)
	local ground = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	local g = frame.args['g']
	local tc = frame.args['tc']
	if ground == '' then
		return ''
	end
	if mw.title.new('Template:Fb ground ' .. ground).exists then
		res = frame:expandTemplate{title = 'Fb ground ' .. ground, args = {g = g, tc = tc}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{[Uu]nicode[_ ]*%|([^{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '&#32;', ' ')
		res = mw.ustring.gsub(res, '_', ' ')
		res = mw.ustring.gsub(res, '  ', ' ')
		
		local rt = mw.text.split(res, '[%{%}]')
		if #rt == 5 then
			res = rt[3]
			local targs = {}
			for k,v in pairs(mw.text.split(mw.ustring.gsub(res, '[%{%}]', ''), '[%|]')) do
				if v:find('=') then
					kk = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%1')
					vv = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%2')
					targs[kk] = vv
				end
			end
			res = frame:expandTemplate{title = 'fb ground', args = targs}
			res = rt[1] .. res .. rt[5]
		end
		res = mw.ustring.gsub(res, '%s*%{%{#ifeq:%s*(.-)%s*%|%s*%1%s*%|%s*%|%s*(%{%{[^%{%}]*%}%})%s*%}%}', '<!-- %2 -->')
		res = mw.ustring.gsub(res, '%s*%{%{#ifeq:%s*.-%s*%|%s*.-%s*%|%s*%|%s*(%{%{[^%{%}]*%}%})%s*%}%}', ' %1')
	end
	
	res = mw.ustring.gsub(res, '(%|)%s*', '%1')
	res = mw.ustring.gsub(res, '(%[%[)([^%[%]%|]*)%|%2(%]%])', '%1%2%3')

	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
	
end
function p.team_ground(frame)
	local ground = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	
	local g = frame.args['g']
	local tc = frame.args['tc']
	if ground == '' then
		return ''
	end
	if mw.title.new('Template:Fb team ground ' .. ground).exists then
		res = frame:expandTemplate{title = 'Fb team ground ' .. ground, args = {g = g, tc = tc}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{[Uu]nicode[_ ]*%|([^{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '&#32;', ' ')
		res = mw.ustring.gsub(res, '_', ' ')
		res = mw.ustring.gsub(res, '  ', ' ')
		
		local rt = mw.text.split(res, '[%{%}]')
		if #rt == 5 then
			res = rt[3]
			local targs = {}
			for k,v in pairs(mw.text.split(mw.ustring.gsub(res, '[%{%}]', ''), '[%|]')) do
				if v:find('=') then
					kk = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%1')
					vv = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%2')
					targs[kk] = vv
				end
			end
			res = frame:expandTemplate{title = 'fb team ground', args = targs}
			res = rt[1] .. res .. rt[5]
		end
		res = mw.ustring.gsub(res, '%s*%{%{#ifeq:%s*(.-)%s*%|%s*%1%s*%|%s*%|%s*(%{%{[^%{%}]*%}%})%s*%}%}', '<!-- %1 -->')
		res = mw.ustring.gsub(res, '%s*%{%{#ifeq:%s*.-%s*%|%s*.-%s*%|%s*%|%s*(%{%{[^%{%}]*%}%})%s*%}%}', ' %1')
	end
	
	res = mw.ustring.gsub(res, '(%|)%s*', '%1')
	res = mw.ustring.gsub(res, '(%[%[)([^%[%]%|]*)%|%2(%]%])', '%1%2%3')

	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end
function p.nat(frame)
	local team = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	local res = ''
	if team == '' then
		return ''
	end
	if team == 'YS' then
		team = '<small>[[Youth system]]</small>'
	elseif mw.title.new('Template:Fb team ' .. team).exists then
		res = frame:expandTemplate{title = 'Fb team ' .. team}
		res = mw.text.killMarkers(res)
		if mw.ustring.find(res, '^.-%|[ ]*tc[ ]*=[ ]*[^%|%{%}]*%|.-$') then
			res = mw.ustring.gsub(res, '^.-%|[ ]*tc[ ]*=[ ]*([^%|%{%}]*)%|.-$', '%1')
		else
			res = ''
		end
	end
	
	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end

function p.round(frame)
	local comp = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	local res = comp
	local qr = frame.args['qr'] or ''
	if comp == '' then
		return ''
	end

	if qr ~= '' then
		qr = 'y'
	end
	
	if mw.title.new('Template:Fb round ' .. comp).exists then
		res = frame:expandTemplate{title = 'Fb round ' .. comp, args = {qr = qr}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{[Uu]nicode[_ ]*%|([^{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '&#32;', ' ')
		res = mw.ustring.gsub(res, '_', ' ')
		res = mw.ustring.gsub(res, '  ', ' ')
	end
	res = mw.ustring.gsub(res, '(%|)%s*', '%1')
	res = mw.ustring.gsub(res, '(%[%[)([^%[%]%|]*)%|%2(%]%])', '%1%2%3')

	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end

function p.round2(frame)
	local comp = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	local res = comp
	local dc = frame.args['dc'] or ''
	if comp == '' then
		return ''
	end

	if dc ~= '' then
		dc = 'y'
	end
	
	if mw.title.new('Template:Fb round2 ' .. comp).exists then
		res = frame:expandTemplate{title = 'Fb round2 ' .. comp, args = {dc = dc}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{[Uu]nicode[_ ]*%|([^{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '&#32;', ' ')
		res = mw.ustring.gsub(res, '_', ' ')
		res = mw.ustring.gsub(res, '  ', ' ')
	end
	res = mw.ustring.gsub(res, '(%|)%s*', '%1')
	res = mw.ustring.gsub(res, '(%[%[)([^%[%]%|]*)%|%2(%]%])', '%1%2%3')

	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end

function p.competition(frame)
	local comp = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	local res = comp
	local dc = frame.args['dc'] or ''
	if comp == '' then
		return ''
	end

	if dc ~= '' then
		dc = 'y'
	end
	
	if mw.title.new('Template:Fb competition ' .. comp).exists then
		res = frame:expandTemplate{title = 'Fb competition ' .. comp, args = {dc = dc}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{[Uu]nicode[_ ]*%|([^{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}%|]*%{%{%{[^%{%}]*%}%}%}[^%{%}%|]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}%|]*)|[^%{%}%|]%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '&#32;', ' ')
		res = mw.ustring.gsub(res, '_', ' ')
		res = mw.ustring.gsub(res, '  ', ' ')
	end
	res = mw.ustring.gsub(res, '(%|)%s*', '%1')
	res = mw.ustring.gsub(res, '(%[%[)([^%[%]%|]*)%|%2(%]%])', '%1%2%3')
	
	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end

function p.team(frame)
	local team = mw.ustring.gsub(mw.text.killMarkers(frame.args[1]), '^%s*(.-)%s*$', '%1')
	team = mw.ustring.gsub(team, '%s+', ' ')
	if team == '' then
		return ''
	end
	
	local sort = frame.args['sort'] or ''
	if sort ~= '' then
		sort = 'y'
	else
		sort = 'n'
	end
	local abb = frame.args['abb'] or ''
	if abb ~= '' then
		abb = 'y'
	end
	
	local st = frame.args['st']

	local res = team

	if team == 'YS' then
		team = '<small>[[Youth system]]</small>'
		res = team
	elseif mw.title.new('Template:Fb team ' .. team).exists then
		res = frame:expandTemplate{title = 'Fb team ' .. team, args = {abb = abb, st = st}}
		res = mw.text.killMarkers(res)
		res = mw.ustring.gsub(res, '%s+', ' ')
		res = mw.ustring.gsub(res, '%{%{#invoke:[Nn]oinclude[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{[Tt]emplate[_ ]*for[_ ]*discussion[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{%{[^%{%}]*%}%}%}', '')
		res = mw.ustring.gsub(res, '%{%{nowrap[_ ]*%|([^%{%}%[%]%|]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*%|[^%{%}]*%}%}', '')
		res = mw.ustring.gsub(res, '%{%{#if:[ ]*y[ ]*%|([^%{%}]*)%}%}', '%1')
		res = mw.ustring.gsub(res, '%{%{#ifeq:[ ]*%|[ ]*%|[ ]*(%{%{[^%{%}]*%}%})[ %|]*%}%}', '%1')

		res = mw.ustring.gsub(res, '({%{)sort%|[^%|]*%|%[%[([^%{%}%|]*)%]%](%}%})', '%1|t=%2|tan=%2%3')
		res = mw.ustring.gsub(res, '({%{)sort%|[^%|]*%|%[%[([^%{%}%|]*)%|([^%{%}%|]*)%]%](%}%})', '%1|t=%3|tan=%2%4')

		local rt = mw.text.split(res, '[%{%}]')
		if #rt == 5 then
			res = rt[3]
			local targs = {}
			-- targs['abb'] = abb
			for k,v in pairs(mw.text.split(mw.ustring.gsub(res, '[%{%}]', ''), '[%|]')) do
				if v:find('=') then
					kk = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%1')
					vv = mw.ustring.gsub(v, '^([^=]*)=([^=]*)$', '%2')
					targs[kk] = vv
				end
			end
			res = frame:expandTemplate{title = 'fb team', args = targs}
			res = rt[1] .. res .. rt[5]
		end
		if sort == 'n' then
			res = mw.ustring.gsub(res, '^{%{sort%|[^%|]*%|([^%{%}]*)%}%}', '%1')
		end
	end
	
	res = mw.ustring.gsub(mw.text.killMarkers(res), '^%s*(.-)%s*$', '%1')
	return res
end

return p