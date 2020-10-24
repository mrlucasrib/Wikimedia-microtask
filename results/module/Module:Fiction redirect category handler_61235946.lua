local getArgs = require('Module:Arguments').getArgs

local p = {}

--[[ 
Local function which handles all the shared character, element and location redirect handling code.
--]]
local function main(args, objectType, validArgs)
	local redirectTemplateHandler = require('Module:Redirect template handler')
	local redirectCategoryShell, mainRedirect, unknownParametersErrors = redirectTemplateHandler.setFictionalObjectRedirect(args, objectType, validArgs)
	if (unknownParametersErrors) then
		return redirectCategoryShell .. unknownParametersErrors
	else
		return redirectCategoryShell
	end
end

--[[ 
Public function from other modules.
Function handles the unique character redirect code.
Do not merge with other sections to allow for future changes.
--]]
function p._character(args, validArgs)
	return main(args, "character", validArgs)
end

--[[ 
Public function from other modules.
Function handles the unique element redirect code.
Do not merge with other sections to allow for future changes.
--]]
function p._element(args, validArgs)
	return main(args, "element", validArgs)
end

--[[ 
Public function from other modules.
Function handles the unique location redirect code.
Do not merge with other sections to allow for future changes.
--]]
function p._location(args, validArgs)
	return main(args, "location", validArgs)
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for fictional character redirects.

Parameters: See module documentation for details.
--]]
function p.character(frame)
	local args = getArgs(frame)
	return p._character(args, nil)
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for fictional element redirects.

Parameters: See module documentation for details.
--]]
function p.element(frame)
	local args = getArgs(frame)
	return p._element(args, nil)
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for fictional location redirects.

Parameters: See module documentation for details.
--]]
function p.location(frame)
	local args = getArgs(frame)
	return p._location(args, nil)
end

return p