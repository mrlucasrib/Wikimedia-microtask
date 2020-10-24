local p = {}

function p._trim(s)
	if s then
		if s:match([[^(['"]).*%1$]]) then return p._trim(string.sub(s,2,-2)) else return s end
	else
		return ""
	end
end

function p.trim(frame)
	local s = (frame.args['s'] or frame.args[1]) or (frame:getParent().args['s'] or frame:getParent().args[1])
	return p._trim(s)
end

return p