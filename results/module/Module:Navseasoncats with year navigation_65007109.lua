local p = {}
local nsc = require('Module:Navseasoncats')

local errorList = {
	["FIND_VAR"] = "Function find_var can't recognize the decade for category %s.",
	["NO_YEAR"] = "{{Navseasoncats with centuries below decade}} can't recognize the year for category %s.",
	["NO_DECADE"] = "{{Navseasoncats with centuries below decade}} can't recognize the decade for category %s."
}

local function create_category(firstPart, lastPart, dateValue, dateWord)
	local category = mw.text.trim(firstPart .. ' ' .. nsc.addord(dateValue) .. dateWord .. lastPart)

	if (mw.title.new(category, 'Category').exists) then
		return category
	else
		return nil
	end
end

local function getCentury(decade)
	decade = tonumber(decade)
	local century = math.floor(((decade - 1) / 100) + 1) --from {{CENTURY}}
	if (string.match(decade, '00$')) then
		century = century + 1
	end --'2000' is technically in the 20th, but the rest of the 2000s is in the 21st
	
	return century
end

local function getDecade(year)
	year = tonumber(year)
	local decade = year / 10
	decade = math.floor(decade)
	return decade .. "0s"
end

local function getNestTierDateCategory(dateArgs, dateValue, firstPart, lastPart, decade)
	local nextTierDateCategory = ""
	if (dateArgs.dateType == "year") then
		local decade = getDecade(dateValue)
		nextTierDateCategory = create_category(firstPart, lastPart, decade, " ")
		if (not nextTierDateCategory) then --check for "the YYYY"
			nextTierDateCategory = create_category(firstPart, lastPart, "the " .. decade, " ")
		end
	elseif (dateArgs.dateType == "decade") then
		local century = getCentury(dateValue)
		nextTierDateCategory = create_category(firstPart, lastPart, century, " century ")
		if (not nextTierDateCategory) then --check for hyphenated century
			nextTierDateCategory = create_category(firstPart, lastPart, century, "-century ")
		end
	end

	return nextTierDateCategory
end

local function isCategoryValid(dateValue, dateType, dateArgs)
	if ((dateValue) and (dateType == dateArgs.dateType)) then
		return true
	else
		return false
	end
end

local function getError(pageName, avoidSelf, testcases, errorMessage)
	local errorOut = ''
	if (avoidSelf) then
		local errors = nsc.errorclass(string.format(errorMessage, pageName))
		errorOut = nsc.failedcat(errors, 'P')
		if (testcases) then
			string.gsub(errorOut, '(%[%[)(Category)', '%1:%2')
		end
	end
	return errorOut
end

local function getAvoidSelf(currentTitle, testcases)
	local avoidSelf = (currentTitle.text ~= 'Navseasoncats with year navigation' and
		currentTitle.text ~= 'Navseasoncats with year navigation/doc' and
		currentTitle.text ~= 'Navseasoncats with year navigation/sandbox' and
		(currentTitle.nsText ~= 'Template' or testcases)) --avoid nested transclusion errors
	return avoidSelf
end

local function main(frame, dateArgs)
	local currentTitle = mw.title.getCurrentTitle()
	local testcases = (currentTitle.subpageText == 'testcases')
	local avoidSelf = getAvoidSelf(currentTitle, testcases)

	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	
	local testcase = args[1]

	if ((testcase == nil) and (avoidself == false)) then
		return ''
	end

	local pageName = testcase or currentTitle.baseText
	
	local findVar = nsc.find_var(pageName) --picks up decades/seasons/etc.
	if (findVar[1] == 'error') then
		return getError(pageName, avoidSelf, testcases, errorList["FIND_VAR"])
	end

	local dateValue = tonumber(string.match(findVar[2], dateArgs.pattern))
	if (not isCategoryValid(dateValue, findVar[1], dateArgs)) then
		return getError(pageName, avoidSelf, testcases, dateArgs.errorMessage)
	end

	local nav1 = ''
	if (testcase) then
		nav1 = frame:expandTemplate{title = 'Navseasoncats', args = {testcase = testcase}} --not sure how else to pass frame & args together
	else
		nav1 = nsc.navseasoncats(frame)
	end

	local firstPart, lastPart = string.match(pageName, '^(.*)' .. findVar[2] .. '(.*)$')
	firstPart = mw.text.trim(firstPart or '')
	lastPart  = mw.text.trim(lastPart or '')

	local nextTierDateCategory = getNestTierDateCategory(dateArgs, dateValue, firstPart, lastPart, decade)

	if (nextTierDateCategory) then
		local nav2 = frame:expandTemplate{title = 'Navseasoncats', args = {[dateArgs.argName] = nextTierDateCategory}} --not sure how else to pass frame & args together
		return '<div style="display:block !important; max-width: calc(100% - 25em);">' .."\n" .. nav1 .. nav2 .."\n" .. '</div>'
	else
		return nav1
	end
end

function p.centuriesBelowDecade(frame)
	local dateArgs = {dateType = "decade", pattern = '^(%d+)s', argName = "century-below-decade", errorMessage = errorList["NO_DECADE"]}
	return main(frame, dateArgs)
end

function p.decadesBelowYear(frame)
	local dateArgs = {dateType = "year", pattern = '^(%d+)', argName = "decade-below-year", errorMessage = errorList["NO_YEAR"]}
	return main(frame, dateArgs)
end

return p