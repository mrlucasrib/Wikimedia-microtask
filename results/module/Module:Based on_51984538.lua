local p = {}

function p.lua_main(frame)
	local s = frame.args[1]
	
	if frame.args[3] then
		local args = {}
		
		for i, v in ipairs(frame.args) do
			if i >= 2 then
				args[#args+1] = v
			end
		end
		
		args['style'] = 'display: inline'
		args['list_style'] = 'display: inline'
		args['item1_style'] = 'display: inline'
		
		h = mw.html.create('div')
		h:wikitext(s)
		h:tag('br')  -- h:newline() is not working for some reason
		h:wikitext('by ')
		h:wikitext(frame:expandTemplate{ title = 'Unbulleted list', args = args })
		
		return h
	elseif frame.args[2] then
		s = s .. '<br />by ' .. frame.args[2]
		return s
	end
	
	return s
end

function p.main(frame)
	return p.lua_main(frame:getParent())
end

return p