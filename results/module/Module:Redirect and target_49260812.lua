local getTarget = require('Module:Redirect').getTarget
local p = {}

function p.line(frame)
	local pageTitle = frame.args[1]
	local target = getTarget(pageTitle)
	if target then
   	        return string.format('[[%s]] → [[%s]]', pageTitle, target)
	end
	return string.format('[[%s]] is not a redirect', pageTitle)
end

return p