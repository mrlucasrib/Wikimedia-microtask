local getArgs = require('Module:Arguments').getArgs

local p = {}

local tvSeriesNameList  = {
	{argName = "arrow", seriesName = "Arrow (TV series)"},
	{argName = "flash", seriesName = "The Flash (2014 TV series)"},
	{argName = "constantine", seriesName = "Constantine (TV series)"},
	{argName = "legends", seriesName = "Legends of Tomorrow"},
	{argName = "supergirl", seriesName = "Supergirl (TV series)"},
	{argName = "vixen", seriesName = "Vixen (web series)"},
	{argName = "ray", seriesName = "Freedom Fighters: The Ray"},
	{argName = "batwoman", seriesName = "Batwoman (TV series)"},
	{argName = "black_lightning", seriesName = "Black Lightning (TV series)"},
}

local FRANCHISE = "Arrowverse"

--[[ 
Local function which handles the main operation.
--]]
local function main(args, objectType)
	local franchiseHandlerModule = require('Module:Fiction redirect category handler/Franchise')
	return franchiseHandlerModule.main(args, objectType, FRANCHISE, tvSeriesNameList)
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for Arrowverse-related character redirects.

Parameters:
	-- |arrow=				— optional; Any value will tag the redirect as belonging to Arrow.
	-- |flash=				— optional; Any value will tag the redirect as belonging to The Flash.
	-- |constantine=		— optional; Any value will tag the redirect as belonging to Constantine.
	-- |legends=			— optional; Any value will tag the redirect as belonging to Legends of Tomorrow.
	-- |supergirl=			— optional; Any value will tag the redirect as belonging to Supergirl.
	-- |vixen=				— optional; Any value will tag the redirect as belonging to Vixen.
	-- |ray=				— optional; Any value will tag the redirect as belonging to Freedom Fighters: The Ray.
	-- |batwoman=			— optional; Any value will tag the redirect as belonging to Batwoman.
	-- |black_lightning=	— optional; Any value will tag the redirect as belonging to Black Lightning.

Notes:
	-- A: The redirect will automatically be tagged with "R from fictional character", "R from fictional element" or "R from fictional location",
			depending on the function used, and be placed in the category "Arrowverse (object) redirects to lists".
	-- B: Using any of the series parameters will place the redirect in a series-specific category: "(series) (object) redirects to lists".
	-- F: If the redirect does not use one of the following correct disambiguation —
			"Arrowverse", "Arrowverse character", "Arrowverse element" or "Arrowverse character" —
			the redirect will be tagged with "R from incorrect disambiguation" and "R unprintworthy".
	
--]]
function p.character(frame)
	local args = getArgs(frame)
	return main(args, "character")
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for Arrowverse-related element redirects.

Parameters: See character() for documentation.
--]]
function p.element(frame)
	local args = getArgs(frame)
	return main(args, "element")
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects for Arrowverse-related location redirects.

Parameters: See character() for documentation.
--]]
function p.location(frame)
	local args = getArgs(frame)
	return main(args, "location")
end

--[[
Public function which is used to return a list of Arrowverse shows.
--]]
function p.getSeriesList()
	return tvSeriesNameList
end

--[[
Public function which is used to return a franchise name.
--]]
function p.getFranchiseName()
	return FRANCHISE
end

--[[
Public function which is used for the testcases.
--]]
function p.testSeriesName(frame)
	local args = getArgs(frame)
	local franchiseHandlerModule = require('Module:Fiction redirect category handler/Franchise')
	return franchiseHandlerModule.testSeriesName(args, FRANCHISE, tvSeriesNameList)
end

return p