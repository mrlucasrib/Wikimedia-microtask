-- This module implements {{anchor}}.

local getArgs = require('Module:Arguments').getArgs
local tableTools = require('Module:TableTools')

local p = {}

function p.main(frame)
	-- Get the positional arguments from #invoke, remove any nil values,
	-- and pass them to p._main.
	local args = getArgs(frame)
	local argArray = tableTools.compressSparseArray(args)
	return p._main(unpack(argArray))
end

function p._main(...)
	-- Generate the list of anchors.
	local anchors = {...}
	local ret = {}
	for _, anchor in ipairs(anchors) do
		ret[#ret + 1] = '<span class="anchor" id="' .. anchor .. '"></span>'
	end
	return table.concat(ret)
end

return p