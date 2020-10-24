--[[
Module that returns one value from a list of unnamed parameters
Named parameter idx is the index of the parameter that is to be returned
Negative indices count backward from the end of the list
==]]

local p = {}

p.getVal = function(frame)
	local args = {}
	-- copy arguments from frame object and its parent
	for k, v in pairs(frame.args) do
		args[k] = v
	end
	for k, v in pairs(frame:getParent().args) do
		args[k] = v
	end
	if not args[1] then
		return nil
	end
	local idx = tonumber(args.idx) or 1
	if idx < 0 then idx = #args + idx + 1 end
	return args[idx]
end

return p