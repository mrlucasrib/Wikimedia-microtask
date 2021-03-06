require('Module:No globals')

local newBuffer = require('Module:OutputBuffer')
local mt = {}

function mt.__index(t, title)
	return function(frame)
		local getBuffer, print, printf = newBuffer()
		printf('{{%s', title)
		local ipairsArgs = {}
		for k,v in ipairs(frame.args) do
			if string.find(v, '=', 1, true) then
				break
			end
			ipairsArgs[k] = true
			printf('|%s', v)
		end
		for k,v in pairs(frame.args) do
			if not ipairsArgs[k] then
				printf('|%s=%s', string.gsub(k, '=', '{{=}}'), v)
			end
		end
		print('}}')
		local buffer = getBuffer()
		-- rather than calling expandTemplate with the title and args we have, call preprocess, so that our code example will always match our output, even in the cases of pipes or other things we should have escaped but didn't
		return string.format('<code>%s</code> &rarr; %s', mw.text.nowiki(buffer), frame:preprocess(buffer))
	end
end

return setmetatable({}, mt)