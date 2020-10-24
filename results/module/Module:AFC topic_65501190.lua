local getArgs = require('Module:Arguments').getArgs
local JSON = require('Module:jf-JSON')

local p = {}

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	local ns = mw.title.getCurrentTitle().namespace
	if ns ~= 118 and ns ~= 2 then
		return '[[Category:AFC topic used in wrong namespace]]'
	end
	
	local jsondata = mw.title.new('Wikipedia:WikiProject Articles for creation/AFC topic map.json'):getContent()
	local data = JSON:decode(jsondata)
	
	local topic = args[1]
	local match = data[topic]
	
	if match ~= nil then
		return '[[Category:' .. match.category .. ']]'
	else 
		return '[[Category:AFC topic: invalid parameter]]'
	end
	
end

return p