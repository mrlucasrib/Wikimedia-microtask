-- This module implements [[Template:Alternating rows table section]]
local p = {}

function p._buildrows(args)
	local ostyle = args['os'] and ' style="' .. args['os'] .. '"' or ''
	local estyle = args['es'] and ' style="' .. args['es'] .. '"' or ''
	
	local rownums = {}
	for k, _ in pairs( args ) do
		local i = tonumber(tostring(k):match( '^%s*([%d]+)%s*$' ) or '0')
		if( i > 0) then
			table.insert( rownums, i )
		end
	end
	-- sort the row numbers
	table.sort(rownums)
	
	local res = {}
	for k, idx in ipairs( rownums ) do
		table.insert(res, '|-' .. ((k % 2 == 0) and estyle or ostyle) )
		table.insert(res, args[idx])
	end
	
	return res
end

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame, {parentFirst = true})
	return table.concat(p._buildrows(args), '\n')
end

return p