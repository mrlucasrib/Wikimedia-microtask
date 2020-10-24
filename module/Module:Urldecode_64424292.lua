local p = {}

function p.urlDecode( frame )
	local enctype = frame.args[2]
	local ret = nil;
	if (frame.args[2] ~= nil) then
		enctype = mw.ustring.upper(enctype)
		if ((enctype == "QUERY") or (enctype == "PATH") or (enctype == "WIKI")) then
			ret = mw.uri.decode(frame.args[1],frame.args[2])
		end
	else
		ret = mw.uri.decode(frame.args[1])
	end
	ret = string.gsub(ret, "{", "&#x7B;")
	ret = string.gsub(ret, "}", "&#x7D;")

	return ret
end

return p