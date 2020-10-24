local libraryUtil = require('libraryUtil')

--=============================================================--
-- DisambiguationPattern class.
local function DisambiguationPattern(o)
	local DisambiguationPattern = o or {pattern = "", type = ""}
	local checkSelf = libraryUtil.makeCheckSelfFunction( 'Television infoboxes disambiguation check', 'DisambiguationPattern', DisambiguationPattern, 'Television infoboxes disambiguation check object' )

	return DisambiguationPattern
end

--=============================================================--

-- Constants.
local DAB_VALID = {
	[true] = "valid",
	[false] = "invalid"
}

local CATEGORY_INCORRECT = "[[Category:Television articles with incorrect naming style]]"

local validationTypeList = {
	["VALIDATION_TYPE_YEAR_COUNTRY"] = 1,
	["VALIDATION_TYPE_YEAR"] = 2,
	["VALIDATION_TYPE_COUNTRY"] = 3,
	["VALIDATION_TYPE_YEAR_SEASON_NUMBER"] = 4,
	["VALIDATION_TYPE_COUNTRY_SEASON_NUMBER"] = 5,
	["VALIDATION_TYPE_SEASON_NUMBER"] = 6,
	["VALIDATION_TYPE_COUNTRY_SEASON"] = 7,
	["VALIDATION_TYPE_YEAR_COUNTRY_SEASON_NUMBER"] = 8
}

local debugMessageList = {
	["DEBUG_EMPTY_TITLE"] = "Debug: Error: Empty title.",
	["DEBUG_NO_DAB"] = "Debug: No disambiguation.",
	["DEBUG_TITLE_ON_EXCEPTION"] = "Debug: Title on exception list.",
	["DEBUG_VALID_FORMAT"] = "Debug: Using a valid format.",
	["DEBUG_NOT_VALID_FORMAT"] = "Debug: Not a valid format.",
	["DEBUG_YEAR_COUNTRY"] = "Debug: Using a valid format with an extended Year and Country - {}.",
	["DEBUG_YEAR"] = "Debug: Using a valid format with an extended Year - {}.",
	["DEBUG_COUNTRY"] = "Debug: Using a valid format with an extended Country - {}.",
	["DEBUG_INCORRECT_STYLE"] = "Debug: Using a valid format but using an incorrect extended style.",
	["DEBUG_INCORRECT_INFOBOX"] = "Debug: Using incorrect infobox - {}.",
	["DEBUG_YEAR_SEASON_NUMBER"] = "Debug: Using a valid format with an extended Year and Season number - {}.",	
	["DEBUG_COUNTRY_SEASON_NUMBER"] = "Debug: Using a valid format with an extended Country and Season number - {}.",	
	["DEBUG_SEASON_NUMBER"] = "Debug: Using a valid format with a Season number - {}.",
	["DEBUG_COUNTRY_SEASON"] = "Debug: Using a valid format with a Country and the word Season - {}.",
	["DEBUG_YEAR_COUNTRY_SEASON_NUMBER"] = "Debug: Using a valid format with an extended Year, Country and Season number - {}."
}

-- Local function which checks if both booleans are true or not.
local function validateTwoParameters(isValid1, isValid2)
	if (isValid1 and isValid2) then
		return true
	else
		return false
	end
end

-- Validate that the season number entered is a valid number -
-- that it does not start with a leading zero (0).
local function validateSeasonNumber(seasonNumber)
	if (tonumber(string.sub(seasonNumber, 1, 1)) == 0) then
		return false
	else
		return true
	end
end

-- Validate that the year entered is a valid year.
local function validateYear(year)
	if (string.len(year) == 4) then
		return true
	else
		return false
	end
end

-- Validate that the text entered is a supported country adjective.
local function validateCountryAdjective(adjective)
	local data = mw.loadData('Module:Country adjective')

	-- Search for a country corresponding to the given text.
	if (data.getCountryFromAdj[adjective]) then
		return true
	else
		return false
	end
end

-- Checks pages using by validating the disambiguation patterns.
local function validatePatterns(disambiguation, disambiguationPatternList)
	local year = ""
	local adjective = ""
	local seasonNumber = ""
	local isYearValid
	local isAdjectiveValid
	local isSeasonNumberValid

	for i, v in ipairs(disambiguationPatternList) do
		local currentDisambiguationPattern = disambiguationPatternList[i]
		if (disambiguation:match(currentDisambiguationPattern.pattern)) then
			
			-- Year and Country styles: "1999 American TV series"
			if (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_YEAR_COUNTRY"]) then
				year, adjective = disambiguation:match(currentDisambiguationPattern.pattern)
				isYearValid = validateYear(year)
				isAdjectiveValid = validateCountryAdjective(adjective)

				local isValid = validateTwoParameters(isYearValid, isAdjectiveValid)
				return isValid, debugMessageList["DEBUG_YEAR_COUNTRY"]:gsub("{}", DAB_VALID[isValid])

			-- Year styles: "1999 TV series"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_YEAR"]) then
				year = disambiguation
				isYearValid = validateYear(year)
				return isYearValid, debugMessageList["DEBUG_YEAR"]:gsub("{}", DAB_VALID[isYearValid])

			-- Country styles: "American TV series"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_COUNTRY"]) then
				adjective = disambiguation
				isAdjectiveValid = validateCountryAdjective(adjective)
				return isAdjectiveValid, debugMessageList["DEBUG_COUNTRY"]:gsub("{}", DAB_VALID[isAdjectiveValid])

			-- Year and Season number styles: "1999 TV series, season 1"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_YEAR_SEASON_NUMBER"]) then
				year, seasonNumber = disambiguation:match(currentDisambiguationPattern.pattern)
				isYearValid = validateYear(year)
				isSeasonNumberValid = validateSeasonNumber(seasonNumber)

				local isValid = validateTwoParameters(isYearValid, isSeasonNumberValid)
				return isValid, debugMessageList["DEBUG_YEAR_SEASON_NUMBER"]:gsub("{}", DAB_VALID[isValid])

			-- Country and Season number styles: "American season 1" and "American TV series, season 1"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_COUNTRY_SEASON_NUMBER"]) then
				adjective, seasonNumber = disambiguation:match(currentDisambiguationPattern.pattern)
				isAdjectiveValid = validateCountryAdjective(mw.text.trim(adjective))
				isSeasonNumberValid = validateSeasonNumber(seasonNumber)
				
				local isValid = validateTwoParameters(isAdjectiveValid, isSeasonNumberValid)
				return isValid, debugMessageList["DEBUG_COUNTRY_SEASON_NUMBER"]:gsub("{}", DAB_VALID[isValid])

			-- Country and the word season: "American season"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_COUNTRY_SEASON"]) then
				adjective = disambiguation:match(currentDisambiguationPattern.pattern)
				isAdjectiveValid = validateCountryAdjective(mw.text.trim(adjective))
				return isAdjectiveValid, debugMessageList["DEBUG_COUNTRY_SEASON"]:gsub("{}", DAB_VALID[isAdjectiveValid])

			--Season number styles: "season 1"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_SEASON_NUMBER"]) then
				seasonNumber = disambiguation:match(currentDisambiguationPattern.pattern)
				isSeasonNumberValid = validateSeasonNumber(seasonNumber)
				return isSeasonNumberValid, debugMessageList["DEBUG_SEASON_NUMBER"]:gsub("{}", DAB_VALID[isSeasonNumberValid])

			-- Year, Country and Season number styles: "Gladiators (2008 British TV series, series 2)"
			elseif (currentDisambiguationPattern.type == validationTypeList["VALIDATION_TYPE_YEAR_COUNTRY_SEASON_NUMBER"]) then
				year, adjective, seasonNumber = disambiguation:match(currentDisambiguationPattern.pattern)
				isYearValid = validateYear(year)
				isAdjectiveValid = validateCountryAdjective(mw.text.trim(adjective))
				isSeasonNumberValid = validateSeasonNumber(seasonNumber)
				
				local isValid = validateTwoParameters(isYearValid, isAdjectiveValid)
				isValid = validateTwoParameters(isValid, isSeasonNumberValid)
				return isValid, debugMessageList["DEBUG_YEAR_COUNTRY_SEASON_NUMBER"]:gsub("{}", DAB_VALID[isValid])
				
			-- Not a valid supported style.
			else
				-- Do nothing.
			end
		else
			-- Do nothing.
		end
	end
	return false, debugMessageList["DEBUG_INCORRECT_STYLE"]
end

-- Validate that the disambiguation type is one of the supported types.
local function validateDisambiguationType(disambiguation, validDisambiguationTypeList)
	local extendedDisambiguation
	local count = 0
	
	for i, v in ipairs(validDisambiguationTypeList) do
		extendedDisambiguation, count = disambiguation:gsub(v, '')
		extendedDisambiguation = mw.text.trim(extendedDisambiguation)
		if (count ~= 0) then
			-- Disambiguation was a valid type; Exit loop.
			break
		end
	end
	
	count = count ~= 0 
	return count, extendedDisambiguation

end

-- Validate that the complete disambiguation is using a supported style.
local function validateDisambiguation(invoker, disambiguation, validDisambiguationTypeList, validDisambiguationPatternList)
	-- Check if the list is empty.
	if (table.getn(validDisambiguationTypeList) ~= 0) then
		local isDisambiguationValid, extendedDisambiguation = validateDisambiguationType(disambiguation, validDisambiguationTypeList)
	
		-- Exit module if the disambiguation type is not a supported style.
		if (not isDisambiguationValid) then
			return false, debugMessageList["DEBUG_NOT_VALID_FORMAT"]
		end
 
 		-- Check if there is no extended disambiguation.
		if (extendedDisambiguation == '') then
			return true, debugMessageList["DEBUG_VALID_FORMAT"]
		end
		
		-- A bit of hack so I won't need to refactor a ton of code.
		if (invoker ~= "infobox television season") then
			disambiguation = extendedDisambiguation
		end
	end
	
	return validatePatterns(disambiguation, validDisambiguationPatternList)
end

-- Check if the page is using disambiguation style that belongs to a different infobox.
local function isPageUsingIncorrectInfobox(disambiguation, otherInfoboxList)
	for k, v in pairs(otherInfoboxList) do
		if (string.match(disambiguation, k)) then
			return true, v, debugMessageList["DEBUG_INCORRECT_INFOBOX"]:gsub("{}", k)
		end
	end
	return false
end

-- Validate that the title has brackets that are part of the title and not part of disambiguation.
local function isOnExceptionList(title, exceptionList)
	for _, v in ipairs(exceptionList) do
		if (v == title) then
			return true
		elseif (string.match(title, v)) then
			return true
		end
	end
	return false
end

-- Get the disambiguation text and make sure that if the title has more than 1 pair of brackets, it returns the last one.
local function getDisambiguation(title)
	local match = require("Module:String")._match
	return match(title, "%s%((.-)%)", 1, -1, false, "")
--	return (string.match (title, '%s*%b()$') or ''):gsub('[%(%)]', '')
end

-- Validate that arg is not nill and not empty.
local function isEmpty(arg)
	if (not arg or arg == "") then
		return true
	else
		return false
	end
end

-- Returns two objects:
--- The first is either an empty string or a tracking category which will appear when using the live version.
--- The second is a debug string which will appear when using /testcases.
local function main(title, invoker, validDisambiguationTypeList, validDisambiguationPatternList, exceptionList, otherInfoboxList, invalidTitleStyleList)
	-- Exit module if the parameter has no value.
	if (isEmpty(title)) then
		return "", debugMessageList["DEBUG_EMPTY_TITLE"]
	end

	-- Exit module if the title has brackets that are part of the title (not disambiguation).
	if (isOnExceptionList(title, exceptionList)) then
		return "", debugMessageList["DEBUG_TITLE_ON_EXCEPTION"]
	end
	
	if (invoker == "infobox television season") then
		if (#invalidTitleStyleList ~= 0) then
			for i = 1, #invalidTitleStyleList do
				if (string.find(title, invalidTitleStyleList[i])) then
					return CATEGORY_INCORRECT, debugMessageList["DEBUG_NOT_VALID_FORMAT"]
				end
			end
		end
	end
		
				
	-- Get the disambiguation.
	local disambiguation = getDisambiguation(title)

	-- Exit module if the title has no disambiguation.
	if (isEmpty(disambiguation)) then
		return "", debugMessageList["DEBUG_NO_DAB"]
	end

	-- Exit module if the disambiguation belongs to a different infobox.
	local isValid, category, debugString = isPageUsingIncorrectInfobox(disambiguation, otherInfoboxList)
	if (isValid) then
		return category, debugString
	end
	
	-- Check if the disambiguation is valid.
	isValid, debugString = validateDisambiguation(invoker, disambiguation, validDisambiguationTypeList, validDisambiguationPatternList)
	
	-- Check if the disambiguation is not valid and add category.
	if (not isValid) then
		category = CATEGORY_INCORRECT
	end

	return category, debugString
end

return {
	main = main,
	DisambiguationPattern = DisambiguationPattern
	}