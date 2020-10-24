-- This module requires the use of Module:ConvertNumeric.
local convertNumeric = require('Module:ConvertNumeric')

-- Unique suffix list.
local uniqueSuffix = {
	[1] = 'st',
	[2] = 'nd',
	[3] = 'rd'
}

-- Common suffix.
local commonSuffix = "th"

-- Test validation.
local test = false

-- Description list.
local descriptionList = {
	["NO_SERIES"] = "A television episode",
	["ONLY_SERIES_NAME"] = "An episode of ''%s''",
	["EPISODE_AND_SERIES_NAME"] = "An episode of the %s season of ''%s''",
	["ALL_VALUES"] = "%s episode%s of the %s season of ''%s''",
	["SINGLE_SEASON"] = "%s episode%s of ''%s''",
	["SPECIAL_EPISODE"] = "A %s episode of ''%s''"
}

-- Tracking category list.
local trackingCategoryList = {
	["NO_SERIES"] = '[[Category:Television episode articles with short description with no series name|%s]]',
	["NO_SEASON_NUMBER"] = '[[Category:Television episode articles with short description with no season number|%s]]',
	["NO_EPISODE_NUMBER"] = '[[Category:Television episode articles with short description with no episode number|%s]]',
	["SINGLE_EPISODE"] = '[[Category:Television episode articles with short description for single episodes|%s]]',
	["MULTI_EPISODE"] = '[[Category:Television episode articles with short description for multi-part episodes|%s]]',
	["DISAMBIGUATED_TITLE"] = '[[Category:Television episode articles with short description and disambiguated page names|%s]]'
}

local p = {}

--[[
Local function which is used to retrieve the ordinal indicator for an integer between 0 and 100.
--]]
local function getOrdinalIndicatorLessThan100(number)
	local suffix								-- Variable to save the ordinal indicator suffix.
	while (not suffix) do						-- Initiate a loop that goes on until a suffix has been found.
		if (number == 0) then					-- Check if the number equals 0; This should never be a valid entry.
			suffix = ""							-- Assign suffix as an empty string.
		elseif (number < 4) then				-- Check if the number is less than 4; Numbers "1", "2" and "3" have unique suffixes.
			suffix = uniqueSuffix[number]		-- It is; Get the unique suffix for that number and assign it.
		elseif (number < 20) then				-- Check if the number is more than 4 AND less than 20; These numbers all have the same common suffix.
			suffix = commonSuffix				-- It is; Assign suffix as the common suffix - "th".
		elseif (number % 10 == 0) then			-- Check if the remainder after division of the number by 10 equals 0.
			suffix = commonSuffix				-- It is; Assign suffix as the common suffix - "th".
		else									-- Anything else - numbers that are above 20 and which their remainder doesn't equal 0 (such as 45).
			number = number % 10				-- Save the new number to the remainder after division of the number by 100; So if the current number is 45, the new number be 5.
		end
	end
	return suffix								-- Return the suffix.
end

--[[
Local function which is used to retrieve the ordinal indicator for an integer between 0 and 1000.
--]]
local function getOrdinalIndicatorLessThan1000(number)
	if (number < 100) then												-- Check if the number is less than 100.
		return getOrdinalIndicatorLessThan100(number)					-- The number is less than 100; Call getOrdinalIndicatorLessThan100() to get the ordinal indicator and return it.
	elseif (number % 100 == 0) then										-- Check if the remainder after division of the number by 100 equals 0.
		return commonSuffix												-- It does; Return the common suffix - "th".
	else																-- Anything else - numbers that are above 100 and which their remainder doesn't equal 0 (such as 345).
		return getOrdinalIndicatorLessThan100(number % 100)				-- Call getOrdinalIndicatorLessThan100() to get the ordinal indicator and return it;
																		-- Pass the remainder after division of the number by 100 (So for 345, it would pass 45) as the parameter.
	end
end

--[[
Local function which is used to create an ordinal number.
--]]
local function getEpisodeOrdinalNumber(number)
	local ordinalIndicator = getOrdinalIndicatorLessThan1000(number)	-- Call getOrdinalIndicatorLessThan1000() to get the number's ordinal indicator.
	return number .. ordinalIndicator									-- Create an ordinal number and return it.
end

--[[
Local function which retrieves the correct category with a sort key.
--]]
local function getCategory(categoryKey, sortKey)
	local category = trackingCategoryList[categoryKey]
	return string.format(category, sortKey)	
end
	
--[[
Local function which "Module:Sort title" to retrieve a sortkey.
--]]
local function getSortKey()
	local sortkeyModule = require('Module:Sort title')
	return sortkeyModule._getSortKey()
end

--[[
Local function which is used to check if the article name is disambiguated.
This is usually in the format of "Episode name (<TV series name>)" or "Episode name (<TV series name> episode)".
--]]
local function isDisambiguated(articleTitle, tvSeriesName)
	local disambiguation = string.match(tostring(articleTitle), "%s%((.-)%)")	-- Get the text inside the disambiguation parentheses.

	if (disambiguation and tvSeriesName) then									-- Check if the article has parentheses and that the TV series name is not nil.
		if (string.find(disambiguation, tvSeriesName)) then 					-- Article has parentheses; Search for the TV series name in the article name disambiguation.
			return true															-- Article is disambiguated; Return true.
		else
			return false														-- Article is not disambiguated; Return false.
		end
	else
		return false															-- Article does not have parentheses; Return false.
	end
end

--[[
Local function which is used to return a relevant tracking category.
--]]
local function createTrackingCategory(tvSeriesName, categoryKey)
	local articleTitle = mw.title.getCurrentTitle()										-- Get the current page's title.
	local namespace = articleTitle.nsText												-- Get the invoking namespace.
	local sortKey = getSortKey()														-- Get sort key.
	
	if (namespace == '' or namespace == 'Draft' or test) then							-- Check if the invoking page is from the allowed namespace.
		if (isDisambiguated(articleTitle, tvSeriesName) == true) then					-- Invoking page is from the allowed namespace; Call isDisambiguated() to check if page is disambiguated.
			return getCategory(categoryKey, sortKey) .. getCategory("DISAMBIGUATED_TITLE", sortKey)		-- Article is disambiguated; Call getCategory() to retrieve the correct tracking categories and return them.
		else
			return getCategory(categoryKey, sortKey)									-- Article is not disambiguated; Retrieve the correct tracking category and return it.
		end
	else
		return ''																		-- Invoking page is not from the allowed namespace; Return empty string.
	end
end

--[[
Local function which is used to create a short description in the style of: "A television episode".
Adds article to the maintenance category: "Category:Television episode articles with short description with no series name".
--]]
local function getShortDescriptionNoValues()
	return descriptionList["NO_SERIES"], createTrackingCategory(nil, "NO_SERIES")
end

--[[
Local function which is used to create a short description in the style of: "An episode of ''Lost''".
Adds article to the maintenance category: "Category:Television episode articles with short description with no season number".
--]]
local function getShortDescriptionNoEpisodeNoSeasonsValues(tvSeriesName)
	return  string.format(descriptionList["ONLY_SERIES_NAME"], tvSeriesName), createTrackingCategory(tvSeriesName, "NO_SEASON_NUMBER")
end

--[[
Local function which is used to create a short description in the style of: "An episode of the first season of ''Lost''".
Adds article to the maintenance category: "Category:Television episode articles with short description with no episode number".
--]]
local function getShortDescriptionNoEpisodeValue(seasonOrdinalNumber, tvSeriesName)
	return string.format(descriptionList["EPISODE_AND_SERIES_NAME"], seasonOrdinalNumber, tvSeriesName), createTrackingCategory(tvSeriesName, "NO_EPISODE_NUMBER")
end

--[[
Local function which is used to create a short description for single season episodes in the style of: "1st episode of ''Lost''".
Adds article to the tracking category: "Category:Television episode articles with short description for single episodes".
--]]
local function getShortDescriptionSingleSeason(episodeOrdinalNumber, plural, tvSeriesName, category)
	return string.format(descriptionList["SINGLE_SEASON"], episodeOrdinalNumber, plural, tvSeriesName), createTrackingCategory(tvSeriesName, category)
end

--[[
Local function which is used to create a short description in the style of: "5th episode of the fourth season of ''Lost''".
Adds article to the tracking category: "Category:Television episode articles with short description for single episodes".
--]]
local function getShortDescriptionSingleEpisode(episodeOrdinalNumber, seasonOrdinalNumber, tvSeriesName, singleSeason)
	if (singleSeason) then
		return getShortDescriptionSingleSeason(episodeOrdinalNumber, "", tvSeriesName, "SINGLE_EPISODE")
	else
		return string.format(descriptionList["ALL_VALUES"], episodeOrdinalNumber, "", seasonOrdinalNumber, tvSeriesName), createTrackingCategory(tvSeriesName, "SINGLE_EPISODE")
	end
end

--[[
Local function which is used to create a short description for a multi-part episode in the style of: "23rd and 24th episodes of the third season of ''Lost''".
Adds article to the tracking category: "Category:Television episode articles with short description for multi-part episodes".
--]]
local function getShortDescriptionMultiEpisode(episodeOrdinalNumber, episodeNumber, seasonOrdinalNumber, tvSeriesName, multiEpisodes, singleSeason)
	local episodeOrdinalList = {episodeOrdinalNumber}
	-- Check if the |multi_episodes value was a number or a "yes" string.
	if (tonumber(multiEpisodes)) then
		multiEpisodes = tonumber(multiEpisodes)
		-- If the value was entered as 1, this isn't a multi-episode.
		if (multiEpisodes == 1) then
			return getShortDescriptionSingleEpisode(episodeOrdinalNumber, seasonOrdinalNumber, tvSeriesName)
		end
		
		-- Go over the amount entered minus 1 (as the first episode ordinal is already known).
		for i = 1, multiEpisodes - 1 do
			table.insert(episodeOrdinalList, getEpisodeOrdinalNumber(episodeNumber + i))
		end
	else
		-- The value entered was "yes", use as default 2 episodes.
		table.insert(episodeOrdinalList, getEpisodeOrdinalNumber(episodeNumber + 1))
	end
			
	local episodeText = mw.text.listToText(episodeOrdinalList)
		
	if (singleSeason) then
		return getShortDescriptionSingleSeason(episodeText, "s", tvSeriesName, "MULTI_EPISODE")
	else
		return string.format(descriptionList["ALL_VALUES"], episodeText, "s", seasonOrdinalNumber, tvSeriesName), createTrackingCategory(tvSeriesName, "MULTI_EPISODE")
	end
end

--[[
Local function which is used to create a short description for a special episode in the style of: "A special episode of ''Lost''" or "A <value used for |special=> episode of ''Lost''"
Adds article to the tracking category: "Category:Television episode articles with short description for single episodes".
--]]
local function getShortDescriptionSpecialEpisode(special, tvSeriesName)
	if (special == "yes" or special == "y") then
		special = "special"
	end
	return string.format(descriptionList["SPECIAL_EPISODE"], special, tvSeriesName), createTrackingCategory(tvSeriesName, "SINGLE_EPISODE")
end

--[[
Local function which is used to validate if data was entered into a parameter of type number.
--]]
local function validateNumberParam(number)
	if (tonumber(number)) then			-- Convert the string into a number and check if the value equals nil (conversion failed).
		return true						-- Param is a number; Return true.
	else
		return false					-- Param is either empty or not a number; Return false.
	end
end

--[[
Local function which is used to return a clean version of the number.
This is done to make sure that no malformed episode or season values
have been entered. The function will remove all text which is not part
of the first number in the string.

The function converts entries such as:
	-- "1.2" -> "1"
	-- "12.2" -> "12"
	-- "1<ref name="number" />" -> "1"
--]]
local function getCleanNumber(number)
	if (number) then							-- Check if the number is not nil (some kind of value was entered).
		return string.match(number, '%d+')		-- The value is not null; Clean the number, if needed.
	else
		return nil								-- The number is nil; Return nil.
	end
end

--[[
Local function which is used to create a short description
by validating if a "multi_episodes" value was entered.
--]]
local function createDescriptionValidateEpisodeValue(args, tvSeriesName, seasonOrdinalNumber)
	local episodeNumber = getCleanNumber(args['episode_num'])																				-- Call getCleanNumber() to return a cleaned version of the number.
	episodeNumber = tonumber(episodeNumber)																									-- Convert the value into a number.

	if (validateNumberParam(episodeNumber)) then																							-- Call validateNumberParam() to check if an episode number was entered.
		local episodeOrdinalNumber = getEpisodeOrdinalNumber(episodeNumber)																	-- A number was entered; Call getEpisodeOrdinalNumber() to get the episode ordinal number.
		local multiEpisodes = args['multi_episodes']
		local singleSeason = false
		if (seasonOrdinalNumber == -1) then
			singleSeason = true
		end
		if (multiEpisodes) then																												-- Check if a |multi_episodes= value was entered.
			return getShortDescriptionMultiEpisode(episodeOrdinalNumber, episodeNumber, seasonOrdinalNumber, tvSeriesName, multiEpisodes, singleSeason)	-- A |multi_episodes= value was entered; Call getShortDescriptionMultiEpisode().
		else
			return getShortDescriptionSingleEpisode(episodeOrdinalNumber, seasonOrdinalNumber, tvSeriesName, singleSeason)					-- A |multi_episodes= value was not entered; Call getShortDescriptionSingleEpisode().
		end
	else
		return getShortDescriptionNoEpisodeValue(seasonOrdinalNumber, tvSeriesName)															-- A an episode number was not entered; Call getShortDescriptionNoEpisodeValue().
	end
end

--[[
Local function which is used to retrieve the season number, since it can be entered in
either the "season" or "series_no" params.
--]]
local function getSeasonNumber(seasonNumber, seasonNumberUK)
	seasonNumber = getCleanNumber(seasonNumber)					-- Call getCleanNumber() to return a cleaned version of the number.
	seasonNumberUK = getCleanNumber(seasonNumberUK)				-- Call getCleanNumber() to return a cleaned version of the number.
	if (validateNumberParam(seasonNumber)) then					-- Call validateNumberParam() to check if the value in the "|season_num" ("season") param is a number.
		return seasonNumber										-- It is; Return value.
	elseif (validateNumberParam(seasonNumberUK)) then			-- Call validateNumberParam() to check if the value in the "|season_num_uk" ("series_no") param is a number.
		return seasonNumberUK									-- It is; Return value.
	else
		return ""												-- Anything else - value not entered. Return empty string.
	end
end

--[[
Local function which is used to create a short description by validating if a season number was entered.
--]]
local function createDescriptionValidateSeasonValue(args, tvSeriesName)
	local seasonNumber = getSeasonNumber(args['season_num'], args['season_num_uk'])							-- Call getSeasonNumber() to get the season number, as it can be in one of two fields.
	if (validateNumberParam(seasonNumber)) then																-- Call validateNumberParam() to check if a season number was entered.
		local seasonOrdinalNumber = convertNumeric.spell_number2({num = seasonNumber, ordinal = true})		-- A season number was entered; Call spell_number2() from Module:ConvertNumeric to get the season ordinal number.
		return createDescriptionValidateEpisodeValue(args, tvSeriesName, seasonOrdinalNumber)				-- Call createDescriptionValidateEpisodeValue() to continue validation process.
	elseif (args['single_season']) then																		-- A season number was not entered; Check if a |single_season= value was entered.
		return createDescriptionValidateEpisodeValue(args, tvSeriesName, -1)								-- |single_season= was entered; Call createDescriptionValidateEpisodeValue().
	elseif (args['special']) then																			-- Check if a |special= value was entered.
		return getShortDescriptionSpecialEpisode(args['special'], tvSeriesName)								-- Call getShortDescriptionSpecialEpisode().
	else
		return getShortDescriptionNoEpisodeNoSeasonsValues(tvSeriesName)									-- A special value was not entered; Call getShortDescriptionNoEpisodeNoSeasonsValues().
	end
end

--[[
Local function which is used to create a short description.
This creates a description by a process of validating which values have values.
These are the following options:
	-- If no |series_name= was entered, it calls getShortDescriptionNoValues().
	-- If only |series_name= and |season_num= or |season_num_uk= were entered, it calls getShortDescriptionNoEpisodeValue().
	-- If all information was entered and |multi_episodes= was not entered, it calls getShortDescriptionSingleEpisode().
	-- If all information and |multi_episodes= was entered, it calls getShortDescriptionDoubleEpisode().
	-- If |series_name= and |special= was entered, it calls getShortDescriptionSpecialEpisode().
	-- If |series_name=, |episode_num= and |no_season= were entered, it calls getShortDescriptionNoSeason().
--]]
local function getDescription(args)
	local tvSeriesName = args['series_name']
	if (tvSeriesName) then															-- Check if a TV series name was entered.
		if (not args['not_dab']) then												-- A TV series name was entered; Check if a not_dab value was entered.
			tvSeriesName = string.gsub(tvSeriesName, "%s+%b()$", "", 1, false)		-- A |not_dab= value was not entered; Get the article title without the disambiguation.
		end
		return createDescriptionValidateSeasonValue(args, tvSeriesName)				-- Call createDescriptionValidateSeasonValue() to continue validation process.
	else
		return getShortDescriptionNoValues()										-- A TV series name was not entered; Call getShortDescriptionNoValues().
	end
end

--[[
Local function which is used to clean the values from unwanted characters.
--]]
local function getCleanValues(args)
	for _, v in ipairs({'episode_num', 'season_num', 'season_num_uk', 'series_name'}) do
		if (args[v]) then
			args[v] = args[v]:gsub('\127[^\127]*UNIQ%-%-(%a+)%-%x+%-QINU[^\127]*\127', '')	-- Remove all strip-markers.
			args[v] = args[v]:gsub('</? *br */?>', ' ')										-- Replace <br /> (and variants) with space character.
			args[v] = args[v]:gsub('%b<>[^<]+%b<>', '')										-- Remove html markup.
			args[v] = args[v]:gsub('%b<>', '')												-- Remove self-closed html tags.
			args[v] = args[v]:gsub('%[%[[^|]+|([^%]]+)%]%]', '%1')							-- Remove wiki-link retain label.
			args[v] = args[v]:gsub('%[%[([^%]]+)%]%]', '%1')								-- Remove wiki-link retain article.
			args[v] = args[v]:gsub('%[%S+ +([^%]]-)%]', '%1')								-- Remove URLs retain label.
			args[v] = args[v]:gsub('%[[^%]]-%]', '')										-- Remove all remaining URLs.

			if (args[v] == '') then															-- Check if the value is an empty string.
				args[v] = nil																-- The value is an empty string; Set it to nil.
			end
		end
	end
	return args																				-- Return args.
end

--[[
Public function which does the actual main process.
--]]
function p._getShortDescription(frame, args)
	args = getCleanValues(args)																				-- Call getCleanValues() to remove all unwanted characters.
	local shortDescription, trackingCat = getDescription(args)												-- Call getDescription() and return two values: the episode's short description and tracking category.

	-- Check if the invoking page is from /testcases or /doc pages.
	if (args['test']) then
		return shortDescription, trackingCat
	elseif (args['doc']) then
		return shortDescription	
	else
		local tableData = {shortDescription, 'noreplace'}													-- Invoking page isn't a test or doc; Create a table for the short description parameter.
		return frame:expandTemplate({title = 'short description', args = tableData}) .. trackingCat			-- Return expanded short description with tracking category.
	end
end

--[[
Public function which is used to create a television episode's short description
from the data available in [Template:Infobox television episode].
A suitable description will be generated depending on the values
of the various parameters. See documentation for examples.

Parameters:
	-- |episode_num=		— optional; The episode's number.
	-- |season_num=			— optional; The season's number.
	-- |season_num_uk=		— optional; The season's number if using the British "series" term.
	-- |series_name=		— optional; The TV series name.
	-- |multi_episodes=		— optional; Setting "yes" will default to a two-part episode.
								If there are more than 2 parts, set the value to the number of parts.
	-- |not_dab=			— optional; Set if the TV series name has parentheses as part of its name.
	-- |special=			— optional; Setting to "yes" will set the description as a "special episode".
								Any other value will replace the word "special" with the one entered. For example "special=recap" will create "recap episode".
	-- |single_season=		— optional; Set if the series is a single season series, such as miniseries or limited series and does not need "1st season" as part of the description.
--]]
function p.getShortDescription(frame)
	local getArgs = require('Module:Arguments').getArgs		-- Use Module:Arguments to access module arguments.
	local args = getArgs(frame)								-- Get the arguments sent via the template.

	return p._getShortDescription(frame, args)				-- Call _getShortDescription() to perform the actual process.
end

--[[
Public function which is used for testing only.
--]]
function p.test(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	
	test = args['test']															-- This param should only be used by tests runned through /testcases.
	local shortDescription, categories = p._getShortDescription(frame, args)
	
	if (test == "cat") then
		return categories
	else
		return shortDescription
	end
end

return p