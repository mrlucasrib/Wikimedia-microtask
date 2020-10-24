local p = {};
local getArgs = require('Module:Arguments').getArgs
local buffer = require("Module:Buffer")('{|')
function p.main(frame)
	local args =  getArgs(frame, {removeBlanks=false, trim=false} )
	for k, v in pairs(args) do
		if type(k) ~= 'number' then buffer:_(string.format(string.match(v, '^["\']') and ' %s=%s' or ' %s="%s"', k, v)) end
	end
	buffer:_'\n'
	for _, v in ipairs(args) do
		if not string.match(v, '^!') then buffer:_'|' end
		buffer:_(v)
	end
	return table.concat(buffer:_'\n|}')
end
return p;