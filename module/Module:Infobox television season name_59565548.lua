local match = require("Module:String")._match

local p = {}

--[[
Local function which is used to create an pipped article link.
--]]
local function createArticleTitleWithPipedLink(article, pipedLink)
	if (pipedLink == nil or pipedLink == "") then
		return "[[" .. article .. "]]"
	else
		return "[[" .. article .. "|" .. pipedLink .. "]]"
	end
end

--[[
Local helper function which is used to get the current season number and modified show name
from the show name.
--]]
local function getModifiedShowNameAndCurrentSeasonNumberFromShowName(showName)
	local _, _, showNameModified, seasonNumber = string.find(showName, "(.*)%s+(%d+)")
	return showNameModified, seasonNumber
end

--[[
Local helper function which is used to get the current season number from the disambiguation.
--]]
local function getCurrentSeasonNumberFromDisambiguation(shortDisambiguation)
	return match(shortDisambiguation , "%d+", 1, -1, false, "")
end

--[[
Local helper function which is used to get the type of word used for "season"
in the disambiguation.

Returns one of three options: "season", "series" or "story arc".
--]]
local function getSeasonType(shortDisambiguation)
        if (string.find(shortDisambiguation, "story arc")) then
		return "story arc"
        end

	if (string.find(shortDisambiguation, "series")) then
		return "series"
        end

	return "season"
end

--[[
Local helper function which is used to get the short disambiguation,
without the "(year) TV series," part, which can cause issues later on.
--]]
local function getShortDisambiguation(disambiguation)
	return string.gsub(disambiguation, "%d+ TV series, ", "")
end

--[[
Local helper function which is used to get the disambiguation from the title.
--]]
local function getDisambiguation(title)
	local disambiguation = match(title, "%s%((.-)%)", 1, -1, false, "")
	if (disambiguation == "") then
		return nil
	else
		return disambiguation
	end
end

--[[
Local helper function which is used to get the show name from the title.
--]]
local function getShowName(title)
	return mw.ustring.gsub(title, "%s+%b()$", "")
end

--[[
Local function which is used to check if the given article exists.
The function returns "true" in the following cases:
	-- A season article exists.
	-- A redirect exists to a season section.

The function returns nil in the following cases:
	-- A season article or redirect do not exist.
	-- A redirect exists, but it is a general redirect and not for any specific season section.
]]--
local function checkArticle(articleTitle)
	local article = mw.title.new(articleTitle)
	if (article ~= nil and article.exists) then
		local redirectTarget = article.redirectTarget
		if (redirectTarget) then
			local fullLink = redirectTarget.fullText
			local isSection = fullLink:find("#")
			if (isSection) then
				return "true"								-- Article is a section redirect; Valid link.
			else
				return nil									-- Article is a general redirect; Not a valid link.
			end
		else
			return "true"									-- Article exists and is not a redirect; Valid link.
		end
	else
		return nil											-- Article or redirect do not exist; Not a valid link.
	end
end

--[[
Local function which returns a season article title and a piped link.

The following are the supported season naming styles:
	-- <showName> (<seasonType> <seasonNumber>)
		Example: Lost (season 2).
	-- <showName> (<country> <seasonType> <seasonNumber>)
		Example: The Office (American season 2).
		Example: X Factor (British series 2).
	-- <showName> (<country> <seasonType>)
		Example: Big Brother 2 (American season).
	-- <showName> (<year> TV series, <seasonType> <seasonNumber>)
		Example: Teenage Mutant Ninja Turtles (1987 TV series, season 2)
		-- <showName> (<country> TV series, <seasonType> <seasonNumber>)
		Example: Love Island (British TV series, series 2)
--]]
local function getArticleTitle(title, prevOrNextSeasonNumber)
	local showName = getShowName(title)
	local disambiguation = getDisambiguation(title)
	
	local shortDisambiguation
	local seasonType
	local seasonNumber = ""
	local pipedLink = ""
	if (disambiguation) then
		shortDisambiguation = getShortDisambiguation(disambiguation)
		seasonType = getSeasonType(shortDisambiguation)
		seasonNumber = getCurrentSeasonNumberFromDisambiguation(shortDisambiguation)
		pipedLink = seasonType:gsub("^%l", string.upper) .. " "
	end

	local showNameModified
	if (seasonNumber == "") then
		if (string.match(showName , "%s+(%d+)")) then
			showNameModified, seasonNumber = getModifiedShowNameAndCurrentSeasonNumberFromShowName(showName)
		else
			return "" -- Not a valid next/prev season link
		end
	end
	
	if (tonumber(seasonNumber) == nil) then
		return ""
	else
		seasonNumber = seasonNumber + prevOrNextSeasonNumber
		pipedLink = pipedLink .. seasonNumber
		-- Titles such as "Big Brother 1 (American season)""
		if (showNameModified and disambiguation) then
			return showNameModified .. " " .. seasonNumber .. " (" .. disambiguation  .. ")", pipedLink

		-- Titles such as "Big Brother Brasil 1"
		elseif (showNameModified) then
			return showNameModified .. " " .. seasonNumber, nil
			
		-- Standard titles such as "Lost (season 1)"
		else
			disambiguation = string.gsub(disambiguation, "%d+$", seasonNumber)
			return showName .. " (" .. disambiguation .. ")", pipedLink
		end
	end
end

--[[
Local helper function which is used to get the title,
either from args (usually from /testcases) or from the page itself.
--]]
local function getTitle(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	local title = args.title
	if (not title) then
		title = mw.title.getCurrentTitle().text
	end

	return title
end

--[[
Local helper function which is called to create a TV season title for the next or previous season.
Passes the value "1" or -1" to increment or decrement the current season number.
--]]
local function createArticleTitleHelper(frame, number)
	local title = getTitle(frame)
	return getArticleTitle(title, number)
end

--[[
Local helper function which is used to check if a season article exists.
--]]
local function checkSeason(frame, number)
	local articleTitle = createArticleTitleHelper(frame, number)
	return checkArticle(articleTitle)
end

--[[
Local helper function which is used to create a season article link.
--]]
local function getSeasonArticleLink(frame, number)
	local articleTitle, pipedLink = createArticleTitleHelper(frame, number)
	return createArticleTitleWithPipedLink(articleTitle, pipedLink)
end

--[[
Public function which is used to check if the next season has
a valid created article or redirect.
--]]
function p.checkNextSeason(frame)
	return checkSeason(frame, 1)
end

--[[
Public function which is used to check if the previous season has
a valid article or redirect.
--]]
function p.checkPrevSeason(frame)
	return checkSeason(frame, -1)
end

--[[
Public function which is used to check if the next or previous season have
a valid article or redirect.

Parameters: 
--]]
function p.checkAll(frame)
	if (p.checkPrevSeason(frame) == "true") then
		return "true"
	else
		return p.checkNextSeason(frame)
	end
end

--[[
Public function which is used to get the next season article title.
--]]
function p.getNextSeasonArticle(frame)
	return getSeasonArticleLink(frame, 1)
end


--[[
Public function which is used to get the previous season article title.
--]]
function p.getPrevSeasonArticle(frame)
	return getSeasonArticleLink(frame, -1)
end

--[[
Public function which is used to get the type of season word used - "season" or "series".
--]]
function p.getSeasonWord(frame)
	local title = getTitle(frame)
	local disambiguation = getDisambiguation(title)
	if (disambiguation) then
		local shortDisambiguation = getShortDisambiguation(disambiguation)
		return getSeasonType(shortDisambiguation)
	else
		return ""
	end
end

--[[
Public function which is used to return the relevant text for the sub-header field.
The text is returned in the format of <code>Season #</code> or <code>Series #</code>,
depending on either what the article disambiguation uses, or on manually entered parameters of the infobox.
--]]
function p.getInfoboxSubHeader(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)

	local seasonType
	local seasonNumber
	if (args.season_number) then
		seasonType = "Season"
		seasonNumber = args.season_number
	elseif (args.series_number) then
		seasonType = "Series"
		seasonNumber = args.series_number
	end

	local title = getTitle(frame)
	local showName = getShowName(title)
	local disambiguation = getDisambiguation(title)
	if (not seasonNumber and disambiguation) then
		local shortDisambiguation = getShortDisambiguation(disambiguation)

		seasonType = getSeasonType(shortDisambiguation)
		seasonType = seasonType:sub(1, 1):upper() .. seasonType:sub(2)
		seasonNumber = getCurrentSeasonNumberFromDisambiguation(shortDisambiguation)
	end

	if (seasonNumber and seasonNumber ~= "") then
		return seasonType .. " " .. seasonNumber
	end
	
	return nil
end

--[[
Public function which is used to return the formatted link
to the list of episodes article in the style of:
[List of <series name> <disambiguation if present> episodes <seasons if present>|List of ''<series name>'' episodes <seasons if present>]

The link will only return if the page exists.
--]]
function p.getListOfEpisodes(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)

	local listRange = ""
	local title = getTitle(frame)
	local showName
	local disambiguation

	if (args.link) then
		-- Parameter should be unformatted.
		if (string.find(args.link, "%[")) then
			local delink = require('Module:Delink')._delink
			args.link = delink({args.link})
			mw.log(args.link)
		end

		-- Get the season or year range if present.
		listRange = args.link:match('episodes(.*)$') or ""

		-- Get the series name with disambiguation.
		local seriesNameWithDisambiguation = args.link:match('List of (.*) episodes')

		if (seriesNameWithDisambiguation) then
			showName = getShowName(seriesNameWithDisambiguation)
			disambiguation = getDisambiguation(seriesNameWithDisambiguation)
		end

	else
		showName = getShowName(title)
		disambiguation = getDisambiguation(title)
	end

	if (disambiguation) then
		-- Check if the disambiguation is extended
		-- and has 'TV series' and isn't just season #.
		if (string.find(disambiguation, "TV series")) then
			-- Only leave the TV series disambiguation, not including the season #.
			disambiguation = disambiguation:match('^(.*),') or disambiguation
			disambiguation = string.format(" (%s)", disambiguation)
		else
	    	disambiguation = ""
		end
	else
		disambiguation = ""
	end

	if (showName) then
		local episodeListArticle = "List of %s%s episodes%s"
		episodeListArticle = episodeListArticle:format(showName, disambiguation, listRange)
		local episodeListArticlePage = mw.title.new(episodeListArticle, 0)

		if (episodeListArticlePage.exists and episodeListArticlePage.redirectTarget ~= mw.title.getCurrentTitle()) then
			local episodeList = "[[%s|List of ''%s'' episodes%s]]"
			episodeList = episodeList:format(episodeListArticle, showName, listRange)
			return episodeList
		end
	end
end

return p