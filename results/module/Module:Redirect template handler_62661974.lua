local p = {}

local currentFrame
local redirectTemplateList = {}
local debugTemplateUsedList = {}
local errorList = {
	["MULTI_SERIES"] = "|multi_series_name_table= can only be used in other modules"
}

--[[
Local function which validates parameter usage through Module:Check for unknown parameters.
If calling module has additional valid args that are not part of this module,
it should pass them as a seperate table - "additonalValidArgs".
--]]
local function getUnknownParametersErrors(args, additonalValidArgs)
	local templateName = currentFrame:getParent():getTitle() or "Module:Redirect template handler"
	local validArgs = {
		["unknown"] = "[[Category:Pages using Module:Redirect template handler with unknown parameters|_VALUE_]]",
		["preview"] = 'Page using [[' .. templateName .. ']] with unknown parameter "_VALUE_".',
		"series_name", "restricted", "birth_name", "alt_name", "former_name",
		"short_name", "long_name", "title_name", "alt_spelling", "to_diacritic",
		"incorrect_name", "capitalisation", "unneeded_dab", "draft_move", "anchor",
		"section", "list", "to_article", "primary", "merge", "history", "dab_exception"
	}
	
	-- Add optional series_name2-10 parameters.
	for i = 2, 10 do
		table.insert(validArgs, "series_name" .. i)
	end
	
	-- Safety check.
	if (additonalValidArgs) then
		for i = 1, #additonalValidArgs do
			table.insert(validArgs, additonalValidArgs[i])
		end
	end

	local checkForUnknownParameters = require("Module:Check for unknown parameters")
	return checkForUnknownParameters._check(validArgs, args)
end

--[[
Local function which handles the addition of redirect templates.
--]]
local function addRedirectTemplate(templateName, templateArgs)
	-- Args might already be a table.
	if (type(templateArgs) ~= "table") then
		templateArgs = {templateArgs}
	end

	-- Get the redirect template.
	local redirectTemplate = currentFrame:expandTemplate{title = templateName, args = templateArgs}
	-- Insert it to the redirect template list.
	table.insert(redirectTemplateList, redirectTemplate)
	-- Insert the name only to the debug list.
	table.insert(debugTemplateUsedList, templateName)
end

--[[ 
Local function which retrieves the redirect's correct disambiguation style.
This is needed to check if the current redirect title is using a correct disambiguation or not.
--]]
local function getCorrectDisambiguation(args)
	-- If a correct disambiguation was set, use it.
	if (args.correct_disambiguation) then
		return args.correct_disambiguation
	elseif (args.series_name) then
		-- If not, return the series name without disambiguation.
		local correctDisambiguation = string.gsub(args.series_name, "%(.*%)", "", 1)
		return mw.text.trim(correctDisambiguation)
	else
		-- If no series name was set, return an empty string.
		return ""
	end
end

--[[ 
Local function which retrieves the redirect's current disambiguation, if any.
--]]
local function getDisambiguation(args)
	local title
	if (args.test_title) then
		title = args.test_title
	else
		title = mw.title.getCurrentTitle().text
	end

	local stringMatch = require("Module:String")._match
	-- Return disambiguation.
	return stringMatch(title, "%s%((.-)%)", 1, -1, false, "")
end

--[[ 
Local function which checks if the current disambiguation used
is using a correct disambiguation style.

Returns true if one of the following is correct:
	-- Has no disambiguation.
	-- Disambiguation is equal to a correct disambiguation style.
	-- Disambiguation is equal to an extended correct disambiguation style,
		which includes the type of redirects.
	-- Disambiguation is tagged with an allowed exception.
--]]
local function isRedirectUsingCorrectDisambiguation(args, objectType)
	local disambiguation = getDisambiguation(args)
	local correctDisambiguation = getCorrectDisambiguation(args)
	objectType = objectType or ""

	if (args.dab_exception or 
		(not disambiguation) or 
		(disambiguation == "") or
		(disambiguation == correctDisambiguation) or 
		(disambiguation == correctDisambiguation .. " " .. objectType)
		) then
		return true
	else
		return false
	end
end

--[[ 
Local function which handles all the shared character, element and location redirect handling code.
--]]
local function getRedirectCategoryTemplates(args, objectType)
	local mainRedirect = true
	local printworthy = true

-----------------[[ Printworthy categories ]]-----------------

	-- See [[WP:NCHASHTAG]] for more details.
	-- This redirect can be a main redirect.
	if (args.restricted) then
		addRedirectTemplate("R restricted", args.restricted)
	end
	
	if (args.birth_name) then
		addRedirectTemplate("R from birth name")
		mainRedirect = false
	end

	if (args.alt_name) then
		addRedirectTemplate("R from alternative name")
		mainRedirect = false
	end

	if (args.former_name) then
		addRedirectTemplate("R from former name")
		mainRedirect = false
	end

	if (args.short_name) then
		addRedirectTemplate("R from short name")
		mainRedirect = false
	end

	if (args.long_name) then
		addRedirectTemplate("R from long name")
		mainRedirect = false
	end

-----------------[[ Unprintworthy categories ]]-----------------

	if (args.title_name) then
		addRedirectTemplate("R from name with title")
		printworthy = false
		mainRedirect = false
	end

	if (args.alt_spelling) then
		addRedirectTemplate("R from alternative spelling", args.alt_spelling)
		printworthy = false
		mainRedirect = false
	end

	if (args.to_diacritic) then
		addRedirectTemplate("R to diacritic")
		mainRedirect = false
		printworthy = false
	end

	if (args.incorrect_name) then
		addRedirectTemplate("R from incorrect name", args.primary or args.incorrect_name)
		mainRedirect = false
		printworthy = false
	end

	if (args.capitalisation) then
		addRedirectTemplate("R from miscapitalisation", args.primary or args.capitalisation)
		mainRedirect = false
		printworthy = false
	end

	if (args.unneeded_dab) then
		addRedirectTemplate("R from unnecessary disambiguation")
		mainRedirect = false
		printworthy = false
	end

	if (not isRedirectUsingCorrectDisambiguation(args, objectType)) then
		addRedirectTemplate("R from incorrect disambiguation")
		mainRedirect = false
		printworthy = false
	end

	if (args.draft_move) then
		addRedirectTemplate("R from move")
		addRedirectTemplate("R from drafts")
		mainRedirect = false
		printworthy = false
	end

-----------------[[ Technical categories ]]-----------------

	--[[
	Redirect target can be:
	-- a link to an anchor in a list.
	-- a link to a list, where the redirect is an entry.
	-- an article, for which the redirect is an alt title of. These are not currently categorized.
	-- a section of an article.
	]]--
	if (args.anchor) then
		addRedirectTemplate("R to anchor")
	elseif (args.list) then
		addRedirectTemplate("R to list entry")
	elseif (args.to_article) then
		-- Currently do nothing.
	else
		addRedirectTemplate("R to section")	
	end

	if (args.primary) then
		addRedirectTemplate("R avoided double redirect", args.primary)
		mainRedirect = false
	end

	if (args.merge) then
		addRedirectTemplate("R from merge")
	end
	
	if (args.history) then
		addRedirectTemplate("R with history")
	end

	if (mainRedirect) then
		addRedirectTemplate("R with possibilities")
	end

	if (printworthy) then
		addRedirectTemplate("R printworthy")
	else
		addRedirectTemplate("R unprintworthy")
	end

	return table.concat(redirectTemplateList), mainRedirect
end

--[[ 
Local function which handles the main process.
--]]
local function main(args, objectType, validArgs)
	local redirectCategoryTemplates, mainRedirect = getRedirectCategoryTemplates(args, objectType)
	local redirectCateogryShell = currentFrame:expandTemplate{title = "Redirect category shell", args = {redirectCategoryTemplates}}
	
	local unknownParametersErrors = getUnknownParametersErrors(args, validArgs)
	-- Used for /testcases testing.
	if (args.test) then
		return table.concat(debugTemplateUsedList, ", "), mainRedirect
	else
		return redirectCateogryShell, mainRedirect, unknownParametersErrors
	end
end

--[[ 
Local function which is used when redirects are tagged with more than one series name.
It retrieves the complete lists of series used.
Series entered should be in the style of "series_name#", as in series_name4.
--]]
local function getMultipleSeriesNames(args)
	local seriesArgs = {}
	table.insert(seriesArgs, args.series_name)
	for i = 2, 10 do
		local tvSeries = args["series_name" .. i]
		if (tvSeries) then
			table.insert(seriesArgs, tvSeries)
		end
	end
	table.insert(debugTemplateUsedList, table.concat(seriesArgs, ", "))
	seriesArgs["multi"] = "yes"
	return seriesArgs
end

--[[ 
Entry point for episode redirects.
--]]
function p.setEpisodeRedirect(args, validArgs)
	currentFrame = mw.getCurrentFrame()
	
	-- For scenarios where the redirect is a crossover episode redirect
	-- and it should appear in more than one series category.
	if (args.series_name2) then
		local seriesArgs = getMultipleSeriesNames(args)
		addRedirectTemplate("R from television episode", seriesArgs)
	else
		
		-- For scenarios where a series has a short web-based series ("minisodes"),
		-- and the redirects should be placed in the parent series category.
		-- Creating a seriesName variable here. This is needed since changing
		-- arg.series_name directly affects code in invoking module.
		local seriesName = args.series_name
		if (args.parent_series) then
			seriesName = args.parent_series
		end
		
		addRedirectTemplate("R from television episode", seriesName)
	end
	
	if (not (args.list or args.to_article or args.section)) then
		args.anchor = true
	end
	
	return main(args, "episode", validArgs)
end

--[[ 
Entry point for fictional object redirects.
This includes character, element and location redirects.
--]]
function p.setFictionalObjectRedirect(args, objectType, validArgs)
	currentFrame = mw.getCurrentFrame()

	if (args.multi_series_name_table) then
		-- For scenarios where the redirect is a character that appears in several different series
		-- and it should appear in more than one series category.
		-- This parameter is used by franchise modules which handle multiple series fields.
		if (type(args.multi_series_name_table) == "table") then
			table.insert(debugTemplateUsedList, table.concat(args.multi_series_name_table, ", "))
			addRedirectTemplate("R from fictional " .. objectType, args.multi_series_name_table)
		else
			error(errorList[MULTI_SERIES], 0)
		end
	elseif (args.series_name2) then
		-- For scenarios where the redirect is a character that appears in several different series
		-- and it should appear in more than one series category.
		local seriesArgs = getMultipleSeriesNames(args)
		addRedirectTemplate("R from fictional " .. objectType, seriesArgs)
	else
		addRedirectTemplate("R from fictional " .. objectType, args.series_name)
	end
	
	return main(args, objectType, validArgs)
end

return p