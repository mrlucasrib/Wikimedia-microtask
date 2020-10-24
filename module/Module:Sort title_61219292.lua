local match = require("Module:String")._match

local p = {}

--[[
Local function which is used to return a number without commas.
For example: 4,722 will become 4722.
--]]
local function cleanNumberFromCommas(title)
	return string.gsub(title, "(%d+)(,+)", "%1")
end

--[[
Local function which is used to check if the word is an article.
Returns true if it is, false if it isn't.
--]]
local function isFirstWordAnArticle(word)
	word = string.lower(word)
	if (word == "a" or word == "an" or word == "the") then
		return true
	else
		return false
	end
end

--[[
Local function which is used to return the title without its disambiguation.
--]]
local function getTitleWithoutDisambiguation(title, disambiguation)
	local newTitle = string.gsub(title, "%(".. disambiguation .. "%)", "")
	return mw.text.trim(newTitle)
end

--[[
Local function which is used to return a title without its first word.
--]]
local function getTitleWithoutFirstWord(title)
	return mw.ustring.gsub(title, "^[^%s]*%s*", "")
end

--[[
Local function which is used to return the first word from a title.
--]]
local function getFirstWord(title)
	return match(title, "^[^%s]*", 1, 1, false, "")
end

--[[
Local function which is used to return a sort key for a specific part.
--]]
local function getSortKey(title, firstWord)
	local sortKey = title
	if (isFirstWordAnArticle(firstWord) and firstWord ~= title) then
		title = getTitleWithoutFirstWord(title)
		sortKey = title .. ", " .. firstWord
	end
	
	return sortKey
end

--[[
Local function which is used to return the disambiguation sort key.
--]]
local function getDisambiguationSortKey(disambiguation)
	if (disambiguation == "") then
		return ""
	end
	
	local firstWord = getFirstWord(disambiguation)
	local disambiguationSortKey = getSortKey(disambiguation, firstWord)
	return "(" .. disambiguationSortKey .. ")"
end

--[[
Local function which is used to return the disambiguation from a title.
--]]
local function getDisambiguation(title)
	local disambiguation = match(title, "%s%((.-)%)", 1, -1, false, "")
	if (disambiguation == "") then
		return ""
	else
		return disambiguation
	end
end

--[[
The main function.
--]]
local function _main(title)
	if (not title) then
		title = mw.title.getCurrentTitle().text
	end

	local firstWord = getFirstWord(title)
	local disambiguation = getDisambiguation(title)
	local disambiguationSortKey = getDisambiguationSortKey(disambiguation)
	
	title = getTitleWithoutDisambiguation(title, disambiguation)
	title = cleanNumberFromCommas(title)
	title = getSortKey(title, firstWord)
	
	local sortKey = title .. " " .. disambiguationSortKey
	return mw.text.trim(sortKey)
end

--[[
Public function which allows modules to retrieve a sort key.
--]]
function p._getSortKey()
	return _main(nil)
end

--[[
Public function which allows templates to retrieve a sort key.
--]]
function p.getSortKey(frame)
	return _main(nil) 
end

--[[
Public function which allows templates to retrieve the sort key inside a DEFAULTSORT.
--]]
function p.getDefaultSort(frame)
	local sortKey = _main(nil)
	return frame:preprocess{text = "{{DEFAULTSORT:" .. sortKey .. "}}"} 
end

--[[
Public function which is used for testing various names and not the current page name.
--]]
function p.testcases(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	return _main(args[1])
end

return p