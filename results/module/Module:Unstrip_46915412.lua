-- This module provides a frontend to the mw.text.unstrip and unstripNoWiki functions
local p = {}

function p.unstrip(frame)
	return mw.text.unstrip(frame.args[1] or '')
end

function p.unstripNoWiki(frame)
	return mw.text.unstripNoWiki(frame.args[1] or '')
end
function p.killMarkers(frame)
	local text = frame.args[1]
	text = mw.text.killMarkers(text)
		:gsub("^%s+", "") --strip leading
		:gsub("%s+$", "") --and trailing spaces
	return text
end
return p