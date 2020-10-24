local p = {}

local addManualCategory = false
local currentFrame

local categoryList = {
	["SEASON_EPISODE_CATEGORY"] = "Category:%s (%s %s) episodes"
}

local TEMP_TRACKING_CATEGORY = "[[Category:Television episode redirect handler parameter usage tracking|%s]]"

--[[
Helper function which creates a season category, checks if it exists
and returns it if it does or an empty string if it doesn't.
--]]
local function getSeasonCategory(seriesName, seasonType, seasonNumber)
	local seasonCategory = string.format(categoryList["SEASON_EPISODE_CATEGORY"], seriesName, seasonType, seasonNumber)
	if (mw.title.new(seasonCategory).exists) then
		return "[[" .. seasonCategory .. "]]"
	else
		return ""
	end	
end

--[[
Local function which sets adds the primary episode redirect to a season category, if it exists.
--]]
local function getSeasonCategory(args)
	local seasonNumber
	local seasonType
	
	if (args.season_num) then
		seasonNumber = args.season_num
		seasonType = "season"
	elseif (args.season_num_uk) then
		seasonNumber = args.season_num_uk
		seasonType = "series"
	end
	
	local seasonCategory = ""
	if (args.series_name and seasonNumber) then
		seasonCategory = getSeasonCategory(args.series_name, seasonType, seasonNumber)
		if (seasonCategory == "") then
			local seriesNameNoDab = mw.ustring.gsub(args.series_name, "%s+%b()$", "")
			seasonCategory = getSeasonCategory(seriesNameNoDab, seasonType, seasonNumber)
		end
	end
	
	return seasonCategory
end

--[[
Local function which "Module:Sort title" to retrieve a sortkey and set it as the default sortkey.
--]]
local function getDefaultSortKey()
	local sortkeyModule = require('Module:Sort title')
	local sortkey = sortkeyModule._getSortKey()
	
	return currentFrame:preprocess{text = "{{DEFAULTSORT:" .. sortkey .. "}}"}
end

--[[
Local function which calls "Module:Television episode short description" to add a short description.
--]]
local function getShortDescription(args)
	local shortDescription = require('Module:Television episode short description')._getShortDescription
	return shortDescription(currentFrame, args)
end

--[[
Public function which is used to create a Redirect category shell
with relevant redirects, and a short description for a television episode.
A sort key is also added to the article.

Parameters: See module documentation for details.
--]]
function p.main(frame)
	currentFrame = frame
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(currentFrame)
	local redirectTemplateHandler = require('Module:Redirect template handler')
	
	local validArgs = {"season_num", "season_num_uk", "episode_num", "multi_episodes", "not_dab", "parent_series"}
	local redirectCategoryShell, mainRedirect, unknownParametersErrors = redirectTemplateHandler.setEpisodeRedirect(args, validArgs)

	-- Used for testcases testing.
	if (args.test) then
		-- This is not the shell, but just the redirect template names that were used.
		return redirectCategoryShell
	end
	
	-- Only add a short description to the main redirect,
	-- and not to a crossover episode, as the short description isn't set up to handle it.
	local shortDescription = ""
	if (mainRedirect and not args.series_name2) then
		shortDescription = getShortDescription(args)
	end
	
	local defaultSortKey = getDefaultSortKey()

	local seasonCategory = getSeasonCategory(args)
	
	if (unknownParametersErrors) then
		return redirectCategoryShell .. "\n" .. shortDescription .. "\n" .. defaultSortKey .. "\n" .. seasonCategory .. unknownParametersErrors
	else
		return redirectCategoryShell .. "\n" .. shortDescription .. "\n" .. defaultSortKey .. "\n" .. seasonCategory
	end
end

return p