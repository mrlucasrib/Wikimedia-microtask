-- This module converts German Wikipedia-style coordinates to a formatted 
-- invocation of the [[template:coord]] template
local p = {}

function p.main(frame)
	local latstr = frame.args[1] or ''
	local lonstr = frame.args[2] or ''
	local tstr   = frame.args[3] or ''
	local fstr   = frame.args['format'] or ''
	local dstr   = frame.args['display'] or ''
	local nmstr  = frame.args['name'] or ''
	local ntstr  = frame.args['notes'] or ''
	local issubst= frame.args['subst'] or ''

	latstr = mw.ustring.gsub(latstr, '[%s]', '')
	lonstr = mw.ustring.gsub(lonstr, '[%s]', '')
	latstr = mw.ustring.gsub(latstr, ',', '.')
	lonstr = mw.ustring.gsub(lonstr, ',', '.')
	lonstr = mw.ustring.gsub(lonstr, '[Oo]', 'E')
	
	while mw.ustring.match(tstr, 'region:[^_/:%s]*/') do
		tstr = mw.ustring.gsub(tstr, '(region:[^_/:%s]*)%s*/', '%1_region:')
	end
	tstr = mw.ustring.gsub(tstr, '%s', '_')
	tstr = mw.ustring.gsub(tstr, '___*', '_')
	
	if (issubst ~= '') then
		local res = ''
		if (tstr ~= '' ) then
			res = '|' .. tstr
		end
		if (fstr ~= '' ) then
			res = res .. '|format=' .. fstr
		end
		if (dstr ~= '' ) then
			res = res .. '|display=' .. dstr
		end
		if (nmstr ~= '' ) then
			res = res .. '|name=' .. nmstr
		end
		if (ntstr ~= '' ) then
			res = res .. '|notes=' .. ntstr
		end
   		latstr = mw.ustring.gsub(latstr, '/[/]*', '|')
   		lonstr = mw.ustring.gsub(lonstr, '/[/]*', '|')
   		return '{{coord|' .. latstr .. '|' .. lonstr .. res .. '}}'
   	else
   		local targs = mw.text.split( latstr .. '/' .. lonstr .. '/' .. tstr, '%s*/[%s/]*')
	   	if fstr ~= '' then
	   		targs['format'] = fstr
	   	end
	   	if dstr ~= '' then
	   		targs['display'] = dstr
	   	end
	   	if nmstr ~= '' then
	   		targs['name'] = nmstr
	   	end
	   	if ntstr ~= '' then
	   		targs['notes'] = ntstr
	   	end
   		return frame:expandTemplate{ title = 'coord', args = targs }
	end
end

return p