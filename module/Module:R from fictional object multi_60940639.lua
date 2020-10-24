local p = {}

--[[
Local function which creates the relevent category, either with or without a sort key.
--]]
local function createCategory(categoryScheme, name, sortKey)
	local category = name .. " " .. categoryScheme

	if (sortKey) then
		category = category .. "|" .. sortKey
	end

	return "[[Category:" .. category .. "]]"
end

--[[
Local function which handles the main process.

Parameters:
	-- |1...8=		— required; Positional or numbered parameters for each series name.
	-- |category=	— required; The redirect category scheme to be used.
	-- |sort=		— optinal; A sort key for the category.
--]]
local function _main(args)
	-- If category wasn't set, return error.
	if (not args.category) then
		return error
	end
	
	local categories = ""
	for i = 1, 10 do
		if (args[i]) then
			categories = categories .. createCategory(args.category, args[i], args["sort"])
		end
	end

	return categories
end

--[[
Entry point.
--]]
function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	return _main(args)
end

return p