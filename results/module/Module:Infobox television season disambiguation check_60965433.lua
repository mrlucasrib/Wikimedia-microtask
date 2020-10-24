-- This module requires the use of the following modules.
local getArgs = require('Module:Arguments').getArgs
local validateDisambiguation = require('Module:Television infoboxes disambiguation check')

local p = {}

local validDisambiguationTypeList = {
	"TV series, season",
	"TV series, series",
	"season",
	"series"
}

local validDisambiguationPatternList = {
	validateDisambiguation.DisambiguationPattern{pattern = "^(%d+) ([%D]+) TV series, season (%d+)$", type = 8},	-- "VALIDATION_TYPE_YEAR_COUNTRY_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^(%d+) ([%D]+) TV series, series (%d+)$", type = 8},	-- "VALIDATION_TYPE_YEAR_COUNTRY_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^(%d+) TV series, season (%d+)$", type = 4},			-- "VALIDATION_TYPE_YEAR_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^(%d+) TV series, series (%d+)$", type = 4},
	validateDisambiguation.DisambiguationPattern{pattern = "^([%D]+) TV series, season (%d+)$", type = 5},			-- "VALIDATION_TYPE_COUNTRY_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^([%D]+) TV series, series (%d+)$", type = 5},
	validateDisambiguation.DisambiguationPattern{pattern = "^([%D]+) season (%d+)$", type = 5},						-- "VALIDATION_TYPE_COUNTRY_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^([%D]+) series (%d+)$", type = 5},
	validateDisambiguation.DisambiguationPattern{pattern = "^([%D]+) season$", type = 7},							-- "VALIDATION_TYPE_COUNTRY_SEASON"
	validateDisambiguation.DisambiguationPattern{pattern = "^season (%d+)$", type = 6},								-- "VALIDATION_TYPE_SEASON_NUMBER"
	validateDisambiguation.DisambiguationPattern{pattern = "^series (%d+)$", type = 6}
}

local exceptionList = {
	"^Bigg Boss %(Hindi season %d+%)$",
	"^Bigg Boss %(Malayalam season %d+%)$",
	"^Bigg Boss %(Telugu season %d+%)$"
}

local otherInfoboxList = {
	["^[^,]*TV series$"] = "[[Category:Television articles using incorrect infobox|T]]"
}

local invalidTitleStyleList = {
	"List of"
}

local function getOtherInfoboxListMerged()
	local infoboxTelevisionDisambiguation = require('Module:Infobox television disambiguation check')
	local list = infoboxTelevisionDisambiguation.getDisambiguationTypeList()

	for i = 1, #list do
		otherInfoboxList[list[i]] = "[[Category:Television articles using incorrect infobox|T]]"
	end
	
	return otherInfoboxList
end

local function _main(args)
	local title = args[1]
	local otherInfoboxListMerged = getOtherInfoboxListMerged()
	return validateDisambiguation.main(title, "infobox television season", validDisambiguationTypeList, validDisambiguationPatternList, exceptionList, otherInfoboxListMerged, invalidTitleStyleList)
end

function p.main(frame)
	local args = getArgs(frame)
	local category, debugString = _main(args)
	return category
end

function p.test(frame)
	local args = getArgs(frame)
	local category, debugString = _main(args)
	return debugString
end

return p