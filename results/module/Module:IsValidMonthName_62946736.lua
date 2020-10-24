--[[
    A simple module to check whether a supplied string is a valid name of a month
    in the Julian or Gregorian calendars.
--]]

local IsValidMonthName = {}

local FullMonthNames = {
    ["January"] = true,
    ["February"] = true,
    ["March"] = true,
    ["April"] = true,
    ["May"] = true,
    ["June"] = true,
    ["July"] = true,
    ["August"] = true,
    ["September"] = true,
    ["October"] = true,
    ["November"] = true,
    ["December"] = true
}

local FullMonthNamesLowerCase = {
    ["january"] = true,
    ["february"] = true,
    ["march"] = true,
    ["april"] = true,
    ["may"] = true,
    ["june"] = true,
    ["july"] = true,
    ["august"] = true,
    ["september"] = true,
    ["october"] = true,
    ["november"] = true,
    ["december"] = true
}

local ShortMonthNames = {
    ["Jan"] = true,
    ["Feb"] = true,
    ["Mar"] = true,
    ["Apr"] = true,
    ["May"] = true,
    ["Jun"] = true,
    ["Jul"] = true,
    ["Aug"] = true,
    ["Sep"] = true,
    ["Oct"] = true,
    ["Nov"] = true,
    ["Dec"] = true
}

local ShortMonthNamesLowerCase = {
    ["jan"] = true,
    ["feb"] = true,
    ["mar"] = true,
    ["apr"] = true,
    ["may"] = true,
    ["jun"] = true,
    ["jul"] = true,
    ["aug"] = true,
    ["sep"] = true,
    ["oct"] = true,
    ["nov"] = true,
    ["dec"] = true
}



-- ############### Publicly accessible functions #######################

-- if the parameter is a valid FULL name of a month, return "%validmonthname%"
-- Otherwise just return an empty string
function IsValidMonthName.isFullMonthName(frame)
	return doNameCheck(frame.args[1], frame.args[2], true, false)
end


-- if the parameter is a valid SHORT name of a month, return "%validmonthname%"
-- Otherwise just return an empty string
function IsValidMonthName.isShortMonthName(frame)
	return doNameCheck(frame.args[1], frame.args[2], false, true)
end


-- if the parameter is a valid FULL OR SHORT name of a month, return "%validmonthname%"
-- Otherwise just return an empty string
function IsValidMonthName.isMonthName(frame)
	return doNameCheck(frame.args[1], frame.args[2], true, true)
end

-- ############### Private functions #######################


function doNameCheck(s, caseArg, checkFull, checkShort)
	local ignoreCase = false

	-- check for missing parameter
	if (s == nil) then
		return ""
	end
	
	-- check for empty parameter
	s = mw.text.trim(s)
	if (s == "") then
		return ""
	end
		
	if (caseArg ~= nil) then
		if (string.lower(caseArg) == "ignorecase") then
			ignoreCase = true
		end
	end
	
	if checkFull then
		if ((FullMonthNames[s] == true) and (not ignoreCase))
			or
		((FullMonthNamesLowerCase[string.lower(s)] == true) and (ignoreCase))
		then
			return s
		end
	end
	if checkShort then
		if ((ShortMonthNames[s] == true) and (not ignoreCase))
			or
		((ShortMonthNamesLowerCase[string.lower(s)] == true) and (ignoreCase))
		then
			return s
		end
	end
	
	return ""
end

return IsValidMonthName