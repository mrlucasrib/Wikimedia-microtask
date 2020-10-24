-- This module implements {{no ping}}.

local p = {}

function p.main(frame)
	local args = frame:getParent().args
	return p._main(args)
end

function p._main(args)
	local ret = {}
	local fullUrl = mw.uri.fullUrl
	local format = string.format
	for i, username in ipairs(args) do
		local url = fullUrl(mw.site.namespaces.User.name .. ':' .. username)
		url = tostring(url)
		local label = args['label' .. tostring(i)]
		url = format('[%s %s]', url, label or username)
		ret[#ret + 1] = url
	end
	ret = mw.text.listToText(ret)
	ret = '<span class="plainlinks">' .. ret .. '</span>'
	return ret
end

return p