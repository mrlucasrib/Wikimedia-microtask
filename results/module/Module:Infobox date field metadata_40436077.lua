local main = {};

local monthIndices = {
    ['january'] = 1,
    ['february'] = 2,
    ['march'] = 3,
    ['april'] = 4,
    ['may'] = 5,
    ['june'] = 6,
    ['july'] = 7,
    ['august'] = 8,
    ['september'] = 9,
    ['october'] = 10,
    ['november'] = 11,
    ['december'] = 12,
    ['jan'] = 1,
    ['feb'] = 2,
    ['mar'] = 3,
    ['apr'] = 4,
    --['may'] = 5, -- long one would have caught this already
    ['jun'] = 6,
    ['jul'] = 7,
    ['aug'] = 8,
    ['sep'] = 9,
    ['oct'] = 10,
    ['nov'] = 11,
    ['dec'] = 12
}

local monthDays = {
    [1] = 31,
    [2] = 29, -- will check below
    [3] = 31,
    [4] = 30,
    [5] = 31,
    [6] = 30,
    [7] = 31,
    [8] = 31,
    [9] = 30,
    [10] = 31,
    [11] = 30,
    [12] = 31
}

function checkIfDayValid(day, month, year)
    -- First check that the month can have at least this many days
    if (day > monthDays[month]) then return false end

    -- February leap year check
    if (month == 2) then
        -- On Feb 29, if we don't have a year (incomplete date), assume 29 can be valid once every 
        if (day == 29 and not year) then return true end
        -- On Feb 29, check for valid year - every 4 but not 100 but 400
        if (day == 29 and not ((year % 4 == 0) and (year % 100 ~= 0) or (year % 400 == 0))) then
             return false
        end
    end

    return true
end

function checkIfMonthValid(month)
    return month ~= 0 and month <= 12  -- <0 never happens with [0-9] pattern
end

function checkIfYearValid(year)
    return year >= 1583 -- up to 9999
end

function checkIfHourValid(hour)
    return hour < 24 -- <0 never happens with [0-9] pattern
end

function checkIfMinuteValid(minute)
    return minute < 60 -- <0 never happens with [0-9] pattern
end

function checkIfSecondValid(second)
    return second < 60 -- <0 never happens with [0-9] pattern
end

local PARSERESULT_OKAY = 1
local PARSERESULT_FAIL = 2 -- whatever we encountered isn't expected for any pattern
local PARSERESULT_UNCRECOGNIZED = 3 -- 14 May 12, 2014 (all elements okay, no pattern)
local PARSERESULT_INCOMPLETE = 4 -- May 3
local PARSERESULT_INCOMPLETERANGE = 5 -- 3 May 2012 - June 2013
local PARSERESULT_INVALID = 6 -- May 32
local PARSERESULT_INVALIDRANGE = 7 -- May 3 - May 2

-- This will first verify that we have a valid date and time and then output an ISO datetime string
function checkAndOutput(year, month, day, hour, minute, second, year2, month2, day2, hour2, minute2, second2)

    local s

    if (year and not checkIfYearValid(year)) then return PARSERESULT_INVALID; end
    if (month and not checkIfMonthValid(month)) then return PARSERESULT_INVALID; end
    if (day and not checkIfDayValid(day, month, year)) then return PARSERESULT_INVALID; end
    if (hour and not checkIfHourValid(hour)) then return PARSERESULT_INVALID; end
    if (minute and not checkIfMinuteValid(minute)) then return PARSERESULT_INVALID; end
    if (second and not checkIfSecondValid(second)) then return PARSERESULT_INVALID; end

    if (year2 and not checkIfYearValid(year2)) then return PARSERESULT_INVALID; end
    if (month2 and not checkIfMonthValid(month2)) then return PARSERESULT_INVALID; end
    if (day2 and not checkIfDayValid(day2, month2, year2)) then return PARSERESULT_INVALID; end
    if (hour2 and not checkIfHourValid(hour2)) then return PARSERESULT_INVALID; end
    if (minute2 and not checkIfMinuteValid(minute2)) then return PARSERESULT_INVALID; end
    if (second2 and not checkIfSecondValid(second2)) then return PARSERESULT_INVALID; end

    -- Check that end date is actually after start date
    if (year2 and year) then
        if (year2 < year) then return PARSERESULT_INVALIDRANGE end
        if (year2 == year) then
            if (month2 and month) then
                if (month2 < month) then return PARSERESULT_INVALIDRANGE end
                if (month2 == month) then
                    if (day2 and day) then
                        if (day2 < day) then return PARSERESULT_INVALIDRANGE end
                        -- TODO: compare time
                    end
                end
            end
        end
    end

    -- Check that the date is actually complete even if valid
    if (month and month2 and not year) then return PARSERESULT_INCOMPLETERANGE end -- any of 'd-dM', 'dM-dM', 'Md-d', 'Md-Md'
    if (month and not year) then return PARSERESULT_INCOMPLETE end -- 'May', 'May 15', '15 May'
    if (month2 and not year2) then return PARSERESULT_INCOMPLETE end -- same but other end
    -- While technically there are more cases, none should have been matched and been given to us
   
    local date1, time1, date2, time2

    -- time only
    if (second and not year) then time1 = string.format('%02d:%02d:%02d', hour, minute, second)
    elseif (minute and not year) then time1 = string.format('%02d:%02d', hour, minute)
    elseif (hour and not year) then time1 = string.format('%02d', hour)

    -- date and time
    elseif (second) then date1 = string.format('%d-%02d-%02d', year, month, day) time1 = string.format('%02d:%02d:%02d', hour, minute, second)
    elseif (minute) then date1 = string.format('%d-%02d-%02d', year, month, day) time1 = string.format('%02d:%02d', hour, minute)
    elseif (hour) then date1 = string.format('%d-%02d-%02d', year, month, day) time1 = string.format('%02d', hour)

    -- date only
    elseif (day) then date1 = string.format('%d-%02d-%02d', year, month, day)
    elseif (month) then date1 = string.format('%d-%02d', year, month)
    elseif (year) then date1 = string.format('%d', year)
    end

    -- time only
    if (second2 and not year2) then time2 = string.format('%02d:%02d:%02d', hour2, minute2, second2)
    elseif (minute2 and not year2) then time2 = string.format('%02d:%02d', hour2, minute2)
    elseif (hour2 and not year2) then time2 = string.format('%02d', hour2)

    -- date and time
    elseif (second2) then date2 = string.format('%d-%02d-%02d', year2, month2, day2) time2 = string.format('%02d:%02d:%02d', hour2, minute2, second2)
    elseif (minute2) then date2 = string.format('%d-%02d-%02d', year2, month2, day2) time2 = string.format('%02d:%02d', hour2, minute2)
    elseif (hour2) then date2 = string.format('%d-%02d-%02d', year2, month2, day2) time2 = string.format('%02d', hour2)

    -- date only
    elseif (day2) then date2 = string.format('%d-%02d-%02d', year2, month2, day2)
    elseif (month2) then date2 = string.format('%d-%02d', year2, month2)
    elseif (year2) then date2 = string.format('%d', year2)
    end

    return PARSERESULT_OKAY, date1, time1, date2, time2 -- this function wouldn't be called withotu matching pattern, so at least 1 value should have been filled

end

function periodHourAdd(period)
    if (period == 'pm' or period == 'p.m' or period == 'pm.' or period == 'p.m.') then -- random '.' is pattern match artifact
        return 12
    else
        return 0
    end
end

local seekString -- this is our local seek string, so we don't have to pass it as parameter every time

local currentPosition -- this keeps track of where we are in seeking our current string

-- These are the element type "constants" for readability mostly
local ELEMENT_INVALID = 1
local ELEMENT_ONETWODIGITS = 2 -- '1' '12' '01'
local ELEMENT_FOURDIGITS = 3 -- '1234'
local ELEMENT_WHITESPACE = 4 -- ' ' '    '
local ELEMENT_MONTHWORD = 5 -- 'May' 'February' 'Aug'
local ELEMENT_COMMA = 6 -- ',' ', '
local ELEMENT_DASH = 7 -- '-' ' - ' ' — ' '- ' ' -'
local ELEMENT_DATESEPARATOR = 8 -- '-'
local ELEMENT_TIMESEPARATOR = 9 -- ':'
local ELEMENT_TIMEPERIOD = 10 -- 'am' 'p.m.'
local ELEMENT_PERIODWHITESPACE = 11 -- '.' or '.   '
local ELEMENT_ONETWODIGITSWITHORDINAL = 12 -- '12th' '3rd'

function seekNextElement()
    
    -- Profiler says mw.ustring.find is the bottleneck, probably because it's unicode; not sure how to improve though besides writing my own pattern matcher

    -- Digits with letters
    local foundPositionStart, foundPositionEnd, foundMatch, foundMatch2 = mw.ustring.find(seekString, '^([0-9]+)([a-z]+)%.?', currentPosition)
	if (foundPositionStart) then
		--currentPosition = foundPositionEnd + 1 -- this is our new start location -- only if we return
		
        -- Additionally check how many digits we actually have, as arbitrary number isn't valid
        if (#foundMatch <= 2) then -- most likely a day number
        	if (foundMatch2 == 'st' or foundMatch2 == 'nd' or foundMatch2 == 'rd' or foundMatch2 == 'th') then -- won't bother checking against a number, no false positives that I saw in 120k cases
        		currentPosition = foundPositionEnd + 1 -- this is our new start location (forced to do this here, since we don't always return)
            	return ELEMENT_ONETWODIGITSWITHORDINAL, tonumber(foundMatch), (currentPosition > mw.ustring.len(seekString))
        	--else -- let it capture digits again, this time '10am' '8p.m.' will be separate
        	--	return ELEMENT_INVALID -- not a valid ordinal indicator
    		end
        --else -- let it capture digits again, this time '10am' '8p.m.' will be separate
        --    return ELEMENT_INVALID -- just the invalid, the number of digits (3+) won't match any patterns
        end
    end
    
    -- Digits
    local foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^([0-9]+)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location

        -- Additionally check how many digits we actually have, as arbitrary number isn't valid
        if (#foundMatch <= 2) then -- most likely a day number or time number
            return ELEMENT_ONETWODIGITS, tonumber(foundMatch), (currentPosition > mw.ustring.len(seekString))
        elseif (#foundMatch == 4) then -- most likely a year
            return ELEMENT_FOURDIGITS, tonumber(foundMatch), (currentPosition > mw.ustring.len(seekString))
        else
            return ELEMENT_INVALID -- just the invalid, the number of digits (3 or 5+) won't match any patterns
        end
    end

    -- Time period - a.m./p.m. (before letters)
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^%s*([ap]%.?m%.?)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_TIMEPERIOD, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end

    -- Word
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^([A-Za-z]+)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location

        if (#foundMatch >= 3) then

            -- Find the possible month name index
            monthIndex = monthIndices[mw.ustring.lower(foundMatch)]

            if (monthIndex) then
                return ELEMENT_MONTHWORD, monthIndex, (currentPosition > mw.ustring.len(seekString))
            else
                return ELEMENT_INVALID -- just the invalid, the word didn't match a valid month name
            end
        else
            -- TODO LETTERS
            return ELEMENT_INVALID -- just the invalid, the word was too short to be valid month name
        end
    end

    -- Time separator (colon without whitespace)
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(:)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_TIMESEPARATOR, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end

    -- Comma and any following whitespace
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(,%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_COMMA, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    
    -- Period and any following whitespace ('Feb. 2010' or '29. June')
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(%.%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_PERIODWHITESPACE, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    
    -- Dash with possible whitespace or Date separator (dash without whitespace)
    -- Both non-breaking spaces - '&nbsp;-&nbsp;'
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(&nbsp;[%-–—]&nbsp;)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    -- Non-breaking space - '&nbsp;- '
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(&nbsp;[%-–—]%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    -- Dash entity code and both non-breaking spaces - '&nbsp;&ndash;&nbsp;'
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(&nbsp;&[nm]dash;&nbsp;)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    -- Dash entity code and non-breaking space - '&nbsp;&ndash; '
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(&nbsp;&[nm]dash;%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end  
    -- Dash entity code - ' &ndash; '
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(%s*&[nm]dash;%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end 
    -- Regular whitespace
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(%s*[%-–—]%s*)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        
        if (foundMatch == '-') then -- nothing else is date separator, no hyphens no stuff like that
            return ELEMENT_DATESEPARATOR, foundMatch, (currentPosition > mw.ustring.len(seekString))
        else
            return ELEMENT_DASH, foundMatch, (currentPosition > mw.ustring.len(seekString)) -- we will actually need to check for DATESEPARATOR as well, as that one stole the '-' case
        end
    end

    -- Whitespace (after all others that capture whitespace)
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^(%s+)', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_WHITESPACE, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end
    -- Whitespace -- same as above but using &nbsp; (other that for dashes)
    foundPositionStart, foundPositionEnd, foundMatch = mw.ustring.find(seekString, '^&nbsp;', currentPosition)
    if (foundPositionStart) then
        currentPosition = foundPositionEnd + 1 -- this is our new start location
        return ELEMENT_WHITESPACE, foundMatch, (currentPosition > mw.ustring.len(seekString))
    end

    return ELEMENT_INVALID -- just the invalid, we won't be parsing this further

end

function parseDateString(input)

    -- Reset our seek string and position
    seekString = input
    currentPosition = 1

    local elements = {}
    local values = {}

    -- Seek the entire string now
    local numberOfElements = 0
    repeat

        foundElement, foundValue, eos = seekNextElement()

        -- If we found something we can't process, return as unparsable
        if (foundElement == ELEMENT_INVALID) then return nil end

        numberOfElements = numberOfElements + 1
        elements[numberOfElements] = foundElement
        values[numberOfElements] = foundValue

    until eos

    --[[
    local s = input .. ' -> ' .. numberOfElements .. ' elements: '

    for currentElementIndex = 1, numberOfElements do
        s = s .. ' #' .. elements[currentElementIndex] .. '=' .. values[currentElementIndex]
    end

    do return s end  
    ]]

    -- Now comes an uber-deep if-then-else tree
    -- This is roughly the most efficient step-by-step parsing, something like log(N)
    -- Doing each combination via pattern/"Regex" is way slower
    -- Having each combination a clean function/preset means checking every element, so way slower
    -- Only immediate big improvement is to only seekNextElement() when actually checking that deep, though this will make a (even bigger) mess

    if (elements[1] == ELEMENT_ONETWODIGITS or elements[1] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- '3' or '10' or '12th'
        if (elements[2] == ELEMENT_WHITESPACE or elements[2] == ELEMENT_PERIODWHITESPACE) then -- '3 ' or '3. '
            if (elements[3] == ELEMENT_MONTHWORD) then -- '3 May'
                if (numberOfElements == 3) then return checkAndOutput(nil, values[3], values[1], nil, nil, nil) end
                if (elements[4] == ELEMENT_WHITESPACE or elements[4] == ELEMENT_PERIODWHITESPACE or elements[4] == ELEMENT_COMMA) then -- '3 May ' or '3 Feb. ' or '3 May, '
                    if (elements[5] == ELEMENT_FOURDIGITS) then -- '3 May 2013'
                        if (numberOfElements == 5) then return checkAndOutput(values[5], values[3], values[1], nil, nil, nil) end
                        if (elements[6] == ELEMENT_WHITESPACE or elements[6] == ELEMENT_COMMA) then -- '3 May 2013, '
                            if (elements[7] == ELEMENT_ONETWODIGITS) then -- '3 May 2013, 10'
                                if (elements[8] == ELEMENT_TIMEPERIOD) then -- '3 May 2013, 10 am'
                                    if (numberOfElements == 8) then return checkAndOutput(values[5], values[3], values[1], values[7] + periodHourAdd(values[8]), nil, nil) end
                                elseif (elements[8] == ELEMENT_TIMESEPARATOR) then -- '3 May 2013, 10:'
                                    if (elements[9] == ELEMENT_ONETWODIGITS) then -- '3 May 2013, 10:38'
                                        if (numberOfElements == 9) then return checkAndOutput(values[5], values[3], values[1], values[7], values[9], nil) end
                                        if (elements[10] == ELEMENT_TIMEPERIOD) then -- '3 May 2013, 10:38 am'
                                            if (numberOfElements == 10) then return checkAndOutput(values[5], values[3], values[1], values[7] + periodHourAdd(values[10]), values[9], nil) end
                                        elseif (elements[10] == ELEMENT_TIMESEPARATOR) then -- '3 May 2013, 10:38:'
                                            if (elements[11] == ELEMENT_ONETWODIGITS) then -- '3 May 2013, 10:38:27'
                                                if (numberOfElements == 11) then return checkAndOutput(values[5], values[3], values[1], values[7], values[9], values[11]) end
                                                if (elements[12] == ELEMENT_TIMEPERIOD) then -- '3 May 2013, 10:38:27 am'
                                                    if (numberOfElements == 12) then return checkAndOutput(values[5], values[3], values[1], values[7] + periodHourAdd(values[12]), values[9], values[11]) end
                                                end
                                            end                                            
                                        end                                        
                                    end                                    
                                end                                
                            end
                        elseif (elements[6] == ELEMENT_DASH or elements[6] == ELEMENT_DATESEPARATOR) then -- '3 May 2013 - '
                            if (elements[7] == ELEMENT_ONETWODIGITS or elements[7] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- '3 May 2013 - 12' or '3rd May 2013 - 12th'
                                if (elements[8] == ELEMENT_WHITESPACE) then -- '3 May 2013 - 12 '
                                    if (elements[9] == ELEMENT_MONTHWORD) then -- '3 May 2013 - 12 February'
                                        if (elements[10] == ELEMENT_WHITESPACE) then -- '3 May 2013 - 12 February '
                                            if (elements[11] == ELEMENT_FOURDIGITS) then -- '3 May 2013 - 12 February 2014'
                                                if (numberOfElements == 11) then return checkAndOutput(values[5], values[3], values[1], nil, nil, nil, values[11], values[9], values[7], nil, nil, nil) end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end                
                elseif (elements[4] == ELEMENT_DASH or elements[4] == ELEMENT_DATESEPARATOR) then -- '3 May - '
                    if (elements[5] == ELEMENT_ONETWODIGITS or elements[5] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- '3 May - 12' or '3rd May - 12th'
                        if (elements[6] == ELEMENT_WHITESPACE) then -- '3 May - 12 '
                            if (elements[7] == ELEMENT_MONTHWORD) then -- '3 May - 12 October'
                                if (numberOfElements == 7) then return checkAndOutput(nil, values[3], values[1], nil, nil, nil, nil, values[7], values[5], nil, nil, nil) end
                                if (elements[8] == ELEMENT_COMMA or elements[8] == ELEMENT_WHITESPACE) then -- '3 May - 12 October '
                                    if (elements[9] == ELEMENT_FOURDIGITS) then -- '3 May - 12 October 2013'
                                        if (numberOfElements == 9) then return checkAndOutput(values[9], values[3], values[1], nil, nil, nil, values[9], values[7], values[5], nil, nil, nil) end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif (elements[2] == ELEMENT_DASH or elements[2] == ELEMENT_DATESEPARATOR) then -- '3 - '
            if (elements[3] == ELEMENT_ONETWODIGITS or elements[3] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- '3 - 12' or '3rd - 12th'
                if (elements[4] == ELEMENT_WHITESPACE) then -- '3 - 12 '
                    if (elements[5] == ELEMENT_MONTHWORD) then -- '3 - 12 May'
                        if (numberOfElements == 5) then return checkAndOutput(nil, values[5], values[1], nil, nil, nil, nil, values[5], values[3], nil, nil, nil) end
                        if (elements[6] == ELEMENT_COMMA or elements[6] == ELEMENT_WHITESPACE) then -- '3 - 12 May '
                            if (elements[7] == ELEMENT_FOURDIGITS) then -- '3 - 12 May 2013'
                                if (numberOfElements == 7) then return checkAndOutput(values[7], values[5], values[1], nil, nil, nil, values[7], values[5], values[3], nil, nil, nil) end
                            end
                        end
                    end
                end
            end
        end

        -- Here's a case where we want to optimize or rather add readability and trim redundancy
        -- Basically, any time '10am', '10:28', '10:28am', '10:28:27', '10:28:27am' can be followed by a date, which means 5 copies of 30+ lines (urgh)
        -- Instead we will only check once, but using a different element index offset if needed, so date might start at element 4 or 5 or 6 etc.
        -- Currently we only have '10', but if it turns out to be a time we will be checking if it's followed by a date

        local wasTime = false -- by default we didn't find a valid time syntax, we have '10' and that's not a time by itself without 'am/pm' or further precision
        local possibleHour, possibleMinute, possibleSecond -- temporary values that we will fill as far as we can when parsing time and use for time+date combo if one is found
        local i = 0 -- this is our offset from the closest possible location for date seeking

        if (elements[2] == ELEMENT_TIMESEPARATOR and elements[1] ~= ELEMENT_ONETWODIGITSWITHORDINAL) then -- '10:' but not '10th:'
            possibleHour = values[1] -- only once we see ':' (or 'am' below) it is likely a time
            if (elements[3] == ELEMENT_ONETWODIGITS) then -- '10:28'
                if (numberOfElements == 3) then return checkAndOutput(nil, nil, nil, values[1], values[3], nil) end
                possibleMinute = values[3]
                wasTime = true -- this is a valid final time, so we can check date appended to this
                i = 1 -- '10', ':' and '28' are three elements, so we start 1 further from 3
                if (elements[4] == ELEMENT_TIMESEPARATOR) then -- '10:28:'
                    wasTime = false -- a time can't end with separator, so if this is last match, we aren't appending any dates
                    if (elements[5] == ELEMENT_ONETWODIGITS) then -- '10:28:27'
                        if (numberOfElements == 5) then return checkAndOutput(nil, nil, nil, values[1], values[3], values[5]) end
                        possibleSecond = values[5]
                        wasTime = true -- this is a valid final time, so we can check date appended to this
                        i = 3 -- '10', ':', '28', ':' and '27' are five elements, so we start 3 further from 3
                        if (elements[6] == ELEMENT_TIMEPERIOD) then -- '10:28:27 am'
                            if (numberOfElements == 6) then return checkAndOutput(nil, nil, nil, values[1] + periodHourAdd(values[6]), values[3], values[5]) end
                            possibleHour = values[1] + periodHourAdd(values[6]) -- hour now needs possible adjusting since we saw a time period
                            -- wasTime = true -- already set
                            i = 4 -- '10', ':', '28', ':', '27' and 'am' are six elements, so we start 4 further from 3
                        end
                    end
                elseif (elements[4] == ELEMENT_TIMEPERIOD) then -- '10:28 am'
                    if (numberOfElements == 4) then return checkAndOutput(nil, nil, nil, values[1] + periodHourAdd(values[4]), values[3], nil) end
                    wasTime = true -- this is a valid final time, so we can check date appended to this
                    possibleHour = values[1] + periodHourAdd(values[4]) -- hour now needs possible adjusting since we saw a time period
                    i = 2 -- '10', ':', '28' and 'am' are four elements, so we start 2 further from 3
                end
            end
        elseif (elements[2] == ELEMENT_TIMEPERIOD) then -- '10 am'
            if (numberOfElements == 2) then return checkAndOutput(nil, nil, nil, values[1] + periodHourAdd(values[2]), nil, nil) end
            possibleHour = values[1] + periodHourAdd(values[2]) -- only once we see 'am' (or ':' above) it is likely a time
            wasTime = true -- this is a valid final time, so we can check date appended to this
            i = 0 -- '10' and 'am' are two elements, so we start at 3 - default
        end

        if (wasTime) then -- '10am', '10:28', '10:28am', '10:28:27', '10:28:27am' (using just '10:28:27...' below)
            -- Now we will try to append a date to the time
            if (elements[3+i] == ELEMENT_WHITESPACE or elements[3+i] == ELEMENT_COMMA) then -- '10:28:27, '
                if (elements[4+i] == ELEMENT_ONETWODIGITS) then -- '10:28:27, 3'
                    if (elements[5+i] == ELEMENT_WHITESPACE) then -- '10:28:27, 3 '
                        if (elements[6+i] == ELEMENT_MONTHWORD) then -- '10:28:27, 3 May'
                            if (elements[7+i] == ELEMENT_WHITESPACE) then -- '10:28:27, 3 May '
                                if (elements[8+i] == ELEMENT_FOURDIGITS) then -- '10:28:27, 3 May 2013'
                                    if (numberOfElements == 8+i) then return checkAndOutput(values[8+i], values[6+i], values[4+i], possibleHour, possibleMinute, possibleSecond) end
                                end
                            end
                        end
                    end
                elseif (elements[4+i] == ELEMENT_MONTHWORD) then -- '10:28:27, May'
                    if (elements[5+i] == ELEMENT_WHITESPACE) then -- '10:28:27, May '
                        if (elements[6+i] == ELEMENT_ONETWODIGITS) then -- '10:28:27, May 3'
                            if (elements[7+i] == ELEMENT_COMMA or elements[7+i] == ELEMENT_WHITESPACE) then -- '10:28:27, May 3, '
                                if (elements[8+i] == ELEMENT_FOURDIGITS) then -- '10:28:27, May 3, 2013'
                                    if (numberOfElements == 8+i) then return checkAndOutput(values[8+i], values[4+i], values[6+i], possibleHour, possibleMinute, possibleSecond) end
                                end
                            end
                        end
                    end
                elseif (elements[4+i] == ELEMENT_FOURDIGITS) then -- '10:28:27, 2013'
                    if (elements[5+i] == ELEMENT_DATESEPARATOR) then -- '10:28:27, 2013-'
                        if (elements[6+i] == ELEMENT_ONETWODIGITS) then -- '10:28:27, 2013-05'
                            if (elements[7+i] == ELEMENT_DATESEPARATOR) then -- '10:28:27, 2013-05-'
                                if (elements[8+i] == ELEMENT_ONETWODIGITS) then -- '10:28:27, 2013-05-03'
                                    if (numberOfElements == 8+i) then return checkAndOutput(values[4+i], values[6+i], values[8+i], possibleHour, possibleMinute, possibleSecond) end
                                end
                            end
                        end
                    end
                end
            end
        end

    elseif (elements[1] == ELEMENT_FOURDIGITS) then -- '2013'
        if (numberOfElements == 1) then return checkAndOutput(values[1], nil, nil, nil, nil, nil) end
        if (elements[2] == ELEMENT_DATESEPARATOR) then -- '2013-'
            if (elements[3] == ELEMENT_ONETWODIGITS) then -- '2013-05'
                --if (numberOfElements == 3) then return checkAndOutput(values[1], values[3], nil, nil, nil, nil) end
                -- This is actually ambiguous -- 2008-12 can be years 2008 to 2012 or it could be Decemeber 2008; few cases, so just ignoring
                if (elements[4] == ELEMENT_DATESEPARATOR) then -- '2013-05-'
                    if (elements[5] == ELEMENT_ONETWODIGITS) then -- '2013-05-03'
                        if (numberOfElements == 5) then return checkAndOutput(values[1], values[3], values[5], nil, nil, nil) end
                        if (elements[6] == ELEMENT_WHITESPACE or elements[6] == ELEMENT_COMMA) then -- '2013-05-03, '
                            if (elements[7] == ELEMENT_ONETWODIGITS) then -- '2013-05-03, 10'
                                if (elements[8] == ELEMENT_TIMEPERIOD) then -- '2013-05-03, 10 am'
                                    if (numberOfElements == 8) then return checkAndOutput(values[1], values[3], values[5], values[7] + periodHourAdd(values[8]), nil, nil) end
                                elseif (elements[8] == ELEMENT_TIMESEPARATOR) then -- '2013-05-03, 10:'
                                    if (elements[9] == ELEMENT_ONETWODIGITS) then -- '2013-05-03, 10:38'
                                        if (numberOfElements == 9) then return checkAndOutput(values[1], values[3], values[5], values[7], values[9], nil) end
                                        if (elements[10] == ELEMENT_TIMEPERIOD) then -- '2013-05-03, 10:38 am'
                                            if (numberOfElements == 10) then return checkAndOutput(values[1], values[3], values[5], values[7] + periodHourAdd(values[10]), values[9], nil) end
                                        elseif (elements[10] == ELEMENT_TIMESEPARATOR) then -- '2013-05-03, 10:38:'
                                            if (elements[11] == ELEMENT_ONETWODIGITS) then -- '2013-05-03, 10:38:27'
                                                if (numberOfElements == 11) then return checkAndOutput(values[1], values[3], values[5], values[7], values[9], values[11]) end
                                                if (elements[12] == ELEMENT_TIMEPERIOD) then -- '2013-05-03, 10:38:27 am'
                                                    if (numberOfElements == 12) then return checkAndOutput(values[1], values[3], values[5], values[7] + periodHourAdd(values[12]), values[9], values[11]) end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end -- can't elseif, because we have ELEMENT_DATESEPARATOR, which repeats above
        if (elements[2] == ELEMENT_DASH or elements[2] == ELEMENT_DATESEPARATOR) then -- '2013 - '
            if (elements[3] == ELEMENT_FOURDIGITS) then -- '2013 - 2014'
                if (numberOfElements == 3) then return checkAndOutput(values[1], nil, nil, nil, nil, nil, values[3], nil, nil, nil, nil, nil) end
            end
        elseif (elements[2] == ELEMENT_WHITESPACE or elements[2] == ELEMENT_COMMA) then -- '2013 ' or '2013, '
            if (elements[3] == ELEMENT_MONTHWORD) then -- '2013 May'
                if (numberOfElements == 3) then return checkAndOutput(values[1], values[3], nil, nil, nil, nil) end
                -- 2013 May - 2013 April (let's see first if this is ever used real-world)
                if (elements[4] == ELEMENT_WHITESPACE) then -- '2013 May '
            		if (elements[5] == ELEMENT_ONETWODIGITS) then -- '2013 May 15'
            			if (numberOfElements == 5) then return checkAndOutput(values[1], values[3], values[5], nil, nil, nil) end
        			end
    			end
            elseif (elements[3] == ELEMENT_ONETWODIGITS) then -- '2013 15' or '2013, 15'
                if (elements[4] == ELEMENT_WHITESPACE) then -- '2013 15 '
            		if (elements[5] == ELEMENT_MONTHWORD) then -- '2013 15 May'
            			if (numberOfElements == 5) then return checkAndOutput(values[1], values[5], values[3], nil, nil, nil) end
        			end
    			end
            end
        end

    elseif (elements[1] == ELEMENT_MONTHWORD) then -- 'May'
        if (numberOfElements == 1) then return checkAndOutput(nil, values[1], nil, nil, nil, nil) end
        if (elements[2] == ELEMENT_WHITESPACE or elements[2] == ELEMENT_PERIODWHITESPACE) then -- 'May ' or 'Feb. '
            if (elements[3] == ELEMENT_ONETWODIGITS or elements[3] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- 'May 3' or 'May 3rd'
                if (numberOfElements == 3) then return checkAndOutput(nil, values[1], values[3], nil, nil, nil) end
                if (elements[4] == ELEMENT_COMMA or elements[4] == ELEMENT_WHITESPACE) then -- 'May 3, '
                    if (elements[5] == ELEMENT_FOURDIGITS) then -- 'May 3, 2013'
                        if (numberOfElements == 5) then return checkAndOutput(values[5], values[1], values[3], nil, nil, nil) end
                        if (elements[6] == ELEMENT_WHITESPACE or elements[6] == ELEMENT_COMMA) then -- ''May 3, 2013, '
                            if (elements[7] == ELEMENT_ONETWODIGITS) then -- ''May 3, 2013, 10'
                                if (elements[8] == ELEMENT_TIMEPERIOD) then -- ''May 3, 2013, 10 am'
                                    if (numberOfElements == 8) then return checkAndOutput(values[5], values[1], values[3], values[7] + periodHourAdd(values[8]), nil, nil) end
                                elseif (elements[8] == ELEMENT_TIMESEPARATOR) then -- ''May 3, 2013, 10:'
                                    if (elements[9] == ELEMENT_ONETWODIGITS) then -- ''May 3, 2013, 10:38'
                                        if (numberOfElements == 9) then return checkAndOutput(values[5], values[1], values[3], values[7], values[9], nil) end
                                        if (elements[10] == ELEMENT_TIMEPERIOD) then -- ''May 3, 2013, 10:38 am'
                                            if (numberOfElements == 10) then return checkAndOutput(values[5], values[1], values[3], values[7] + periodHourAdd(values[10]), values[9], nil) end
                                        elseif (elements[10] == ELEMENT_TIMESEPARATOR) then -- ''May 3, 2013, 10:38:'
                                            if (elements[11] == ELEMENT_ONETWODIGITS) then -- ''May 3, 2013, 10:38:27'
                                                if (numberOfElements == 11) then return checkAndOutput(values[5], values[1], values[3], values[7], values[9], values[11]) end
                                                if (elements[12] == ELEMENT_TIMEPERIOD) then -- ''May 3, 2013, 10:38:27 am'
                                                    if (numberOfElements == 12) then return checkAndOutput(values[5], values[1], values[3], values[7] + periodHourAdd(values[12]), values[9], values[11]) end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        elseif (elements[6] == ELEMENT_DASH or elements[6] == ELEMENT_DATESEPARATOR) then -- 'May 3, 2013 - '
                            if (elements[7] == ELEMENT_MONTHWORD) then -- 'May 3, 2013 - February'
                                if (elements[8] == ELEMENT_WHITESPACE) then -- 'May 3, 2013 - February '
                                    if (elements[9] == ELEMENT_ONETWODIGITS or elements[3] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- 'May 3, 2013 - February 12' or 'May 3rd, 2013 - February 12th'
                                        if (elements[10] == ELEMENT_COMMA or elements[10] == ELEMENT_WHITESPACE) then -- 'May 3, 2013 - February 12, '
                                            if (elements[11] == ELEMENT_FOURDIGITS) then -- 'May 3, 2013 - February 12, 2014'
                                                if (numberOfElements == 11) then return checkAndOutput(values[5], values[1], values[3], nil, nil, nil, values[11], values[7], values[9], nil, nil, nil) end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif (elements[4] == ELEMENT_DASH or elements[4] == ELEMENT_DATESEPARATOR) then -- 'May 3 - '
                    if (elements[5] == ELEMENT_MONTHWORD) then -- 'May 3 - June'
                        if (elements[6] == ELEMENT_WHITESPACE) then -- 'May 3 - June '
                            if (elements[7] == ELEMENT_ONETWODIGITS or elements[3] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- 'May 3 - June 12' or 'May 3rd - June 12th'
                                if (numberOfElements == 7) then return checkAndOutput(nil, values[1], values[3], nil, nil, nil, nil, values[5], values[7], nil, nil, nil) end
                                if (elements[8] == ELEMENT_COMMA or elements[8] == ELEMENT_WHITESPACE) then -- 'May 3 - June 12, '
                                    if (elements[9] == ELEMENT_FOURDIGITS) then -- 'May 3 - June 12, 2014'
                                        if (numberOfElements == 9) then return checkAndOutput(values[9], values[1], values[3], nil, nil, nil, values[9], values[5], values[7], nil, nil, nil) end
                                    end
                                end
                            end
                        end
                    elseif (elements[5] == ELEMENT_ONETWODIGITS or elements[3] == ELEMENT_ONETWODIGITSWITHORDINAL) then -- 'May 3 - 12' or 'May 3rd - 12th'
                        if (numberOfElements == 5) then return checkAndOutput(nil, values[1], values[3], nil, nil, nil, nil, values[1], values[5], nil, nil, nil) end
                        if (elements[6] == ELEMENT_COMMA or elements[6] == ELEMENT_WHITESPACE) then -- 'May 3 - 12, '
                            if (elements[7] == ELEMENT_FOURDIGITS) then -- 'May 3 - 12, 2013'
                                if (numberOfElements == 7) then return checkAndOutput(values[7], values[1], values[3], nil, nil, nil, values[7], values[1], values[5], nil, nil, nil) end
                            end
                        end
                    end
                end
            elseif (elements[3] == ELEMENT_FOURDIGITS) then -- 'May 2013'
                if (numberOfElements == 3) then return checkAndOutput(values[3], values[1], nil, nil, nil, nil) end
                if (elements[4] == ELEMENT_DASH or elements[4] == ELEMENT_DATESEPARATOR) then -- 'May 2013 -'
                    if (elements[5] == ELEMENT_MONTHWORD) then -- 'May 2013 - June'
                        if (elements[6] == ELEMENT_WHITESPACE) then -- 'May 2013 - June '
                            if (elements[7] == ELEMENT_FOURDIGITS) then -- 'May 2013 - June 2013'
                                if (numberOfElements == 7) then return checkAndOutput(values[3], values[1], nil, nil, nil, nil, values[7], values[5], nil, nil, nil, nil) end
                            end
                        end
                    end
                end
            end
        elseif (elements[2] == ELEMENT_DASH or elements[2] == ELEMENT_DATESEPARATOR) then -- 'May - '
            if (elements[3] == ELEMENT_MONTHWORD) then -- 'May - June'
                if (elements[4] == ELEMENT_WHITESPACE) then -- 'May - June '
                    if (elements[5] == ELEMENT_FOURDIGITS) then -- 'May - June 2013'
                        if (numberOfElements == 5) then return checkAndOutput(values[5], values[1], nil, nil, nil, nil, values[5], values[3], nil, nil, nil, nil) end
                    end
                end
            end
        elseif (elements[2] == ELEMENT_COMMA) then -- 'May, '
            if (elements[3] == ELEMENT_FOURDIGITS) then -- 'May, 2012'
                if (numberOfElements == 3) then return checkAndOutput(values[3], values[1], nil, nil, nil, nil) end
            end
        end

    else
        return PARSERESULT_UNRECOGNIZED -- the combination of elements was not a recognized one
    end

end

function hasMetadataTemplates(input)
	
	-- This is a basic list of the template names for metadata emiting tempaltes, there are inr eality more templates and more redirects
	if (string.match(input, '%{%{[Ss]tart[ %-]?date')) then return true end
	if (string.match(input, '%{%{[Ee]nd[ %-]?date')) then return true end
	if (string.match(input, '%{%{[Bb]irth[ %-]?date')) then return true end
	if (string.match(input, '%{%{[Dd]eath[ %-]?date')) then return true end
	if (string.match(input, '%{%{[Bb]irth[ %-]?year')) then return true end
	if (string.match(input, '%{%{[Dd]eath[ %-]?year')) then return true end
	if (string.match(input, '%{%{[Ff]ilm ?date')) then return true end
	if (string.match(input, '%{%{[ISO[ %-]date')) then return true end

	return false

end

-- This function will return a raw string for generic checks and unit test, including defined parse errors
function main.parseDateOutputRaw(frame)

    local input = frame.args[1]
    
    -- If desired (default), unstrip and decode to have the raw markup
    if (not frame.args.noUnstrip or frame.args.noUnstrip ~= 'yes') then
        input = mw.text.decode(mw.text.unstrip(input))
    end
        
    -- If desired (not default), strip the field extra stuff
    if (frame.args.stripExtras and frame.args.stripExtras == 'yes') then
        input = stripFieldExtras(input)
    end

    -- If there is nothing but whitespace, don't bother
    if (mw.ustring.match(input, '^%s*$')) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{gray|Empty input}}\'\'') else return 'Empty input' end end

    local result, startDate, startTime, endDate, endTime = parseDateString(input)

    if (result == PARSERESULT_FAIL) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{gray|Failed parse}}\'\'') else return 'Failed parse' end end
    if (result == PARSERESULT_UNRECOGNIZED) then 
    	local s
    	if (hasMetadataTemplates(input)) then s = 'Has metadata template' else s = 'Unrecognized pattern' end
    	if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{gray|'..s..'}}\'\'') else return s end 
	end
    if (result == PARSERESULT_INVALID) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{maroon|Invalid date/time}}\'\'') else return 'Invalid date/time' end end
    if (result == PARSERESULT_INVALIDRANGE) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{maroon|Invalid date range}}\'\'') else return 'Invalid date range' end end
    if (result == PARSERESULT_INCOMPLETE) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{cyan|Incomplete date}}\'\'') else return 'Incomplete date' end end
    if (result == PARSERESULT_INCOMPLETERANGE) then if (frame.args[2] == 'pretty') then return frame:preprocess('\'\'{{cyan|Incomplete date range}}\'\'') else return 'Incomplete date range' end end

    local s
    
    if (startDate) then s = startDate end
    if (startTime) then if (startDate) then s = s .. ' ' .. startTime else s = startTime end end
    if (endDate) then s = s .. '; ' .. endDate end -- currently end date implies start date
    -- currently no end time

    return s

end

-- Strips whitespace from an input
function trim(value)
	local strip, count = string.gsub(value, '^%s*(.-)%s*$', '%1')
	return strip
end	

function stripFieldExtras(value)
        
    -- todo: do progressive scan like with that seek string just for ref tags and such
    -- note that we can't just replace matches with whitespace and catch them all, because it could be like '3 August<!---->20<ref/>12'
        
    local matchStrip = value:match('^([^<]-)<ref[^>]*>[^<]*</ref><ref[^>]*>[^<]*</ref><ref[^>]*>[^<]*</ref>$') -- basic refs (quite common)
    if (matchStrip) then return trim(matchStrip) end

    matchStrip = value:match('^([^<]-)<ref[^>]*>[^<]*</ref><ref[^>]*>[^<]*</ref>$') -- basic refs (quite common)
    if (matchStrip) then return trim(matchStrip) end

    matchStrip = value:match('^([^<]-)<ref[^>]*>[^<]*</ref>$') -- basic refs (quite common)
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^([^<]-)<ref[^>]*/><ref[^>]*/><ref[^>]*/>$') -- basic named ref (quite common)
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^([^<]-)<ref[^>]*/><ref[^>]*/>$') -- basic named ref (quite common)
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^([^<]-)<ref[^>]*/>$') -- basic named ref (quite common)
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^<!--.--->([^<]+)$') -- comment before (sometimes used for notes to editors [not yet seen metadata-related comment])
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^([^<]-)<!--.--->$') -- comment after  (sometimes used for notes to editors)
    if (matchStrip) then return trim(matchStrip) end
    
    matchStrip = value:match('^{{[Ff]lag ?icon[^}]+}}%s*{{[Ff]lag ?icon[^}]+}}([^<]+)$') -- 2 flag icons (also more common than one would think)
    if (matchStrip) then return trim(matchStrip) end

	matchStrip = value:match('^{{[Ff]lag ?icon[^}]+}}([^<]+)$') -- flag icon (quite common, although against MOS:ICON)
    if (matchStrip) then return trim(matchStrip) end    
   
    matchStrip = value:match('^([^<]-){{[Ff]lag ?icon[^}]+}}%s*{{[Ff]lag ?icon[^}]+}}$') -- after as well
    if (matchStrip) then return trim(matchStrip) end

	matchStrip = value:match('^([^<]-){{[Ff]lag ?icon[^}]+}}$')
    if (matchStrip) then return trim(matchStrip) end    
   
    return value -- if we didn't match anything, abort now
    
end

function main.emitMetadata(frame)
    
    local input = frame.args[1]
    
    -- If desired (default), unstrip and decode to have the raw markup
    if (not frame.args.noUnstrip or frame.args.noUnstrip ~= 'yes') then
        input = mw.text.decode(mw.text.unstrip(input))
    end

    input = stripFieldExtras(trim(input))

    -- If there is nothing but whitespace, don't bother
    if (mw.ustring.match(input, '^%s*$')) then return nil end

    -- Then parse the date and see if we get a valid output date
    local result, startDate, startTime, endDate, endTime = parseDateString(input)
    
    if (not frame.args.noErrorCats or frame.args.noErrorCats ~= 'yes') then
        if (result == PARSERESULT_FAIL and not hasMetadataTemplates(input)) then return frame:preprocess('<includeonly>[[Category:Articles that could not be parsed for automatic date metadata]]</includeonly>') end
        if (result == PARSERESULT_UNRECOGNIZED and not hasMetadataTemplates(input)) then return frame:preprocess('<includeonly>[[Category:Articles that could not be parsed for automatic date metadata]]</includeonly>') end
        --if (result == PARSERESULT_INVALID) then return frame:preprocess('<includeonly>[[Category:]]</includeonly>') end
        --if (result == PARSERESULT_INVALIDRANGE) then return frame:preprocess('<includeonly>[[Category:]]</includeonly>') end
        if (result == PARSERESULT_INCOMPLETE) then return frame:preprocess('<includeonly>[[Category:Articles with incomplete dates for automatic metadata]]</includeonly>') end
        if (result == PARSERESULT_INCOMPLETERANGE) then return frame:preprocess('<includeonly>[[Category:Articles with incomplete date ranges for automatic metadata]]</includeonly>') end
        -- we need to use frame:preprocess() for <includeonly> or it just gets displayed
    end

    -- We are only doing the rest for a valid date
    if (result ~= PARSERESULT_OKAY) then return nil end

    local dtstartSpan, dtendSpan
    
    -- If we have a start value and we're told to output it
    if ((startDate or startTime) and frame.args.dtstart and frame.args.dtstart == 'yes') then 
        if (startDate and startTime) then dtstartSpan = '<span class="dtstart">' .. startDate .. 'T' .. startTime .. '</span>'
        elseif (startDate) then dtstartSpan = '<span class="dtstart">' .. startDate .. '</span>'
        else dtstartSpan = '<span class="dtstart">' .. startTime .. '</span>' end
    end

    -- If we have an end value and we're told to output it
    if ((endDate or endTime) and frame.args.dtend and frame.args.dtend == 'yes') then -- end values only happen when start values happen
        if (endDate and endTime) then dtendSpan = '<span class="dtend">' .. endDate .. 'T' .. endTime .. '</span>'
        elseif (endDate) then dtendSpan = '<span class="dtend">' .. endDate .. '</span>'
        else dtendSpan = '<span class="dtend">' .. endTime .. '</span>' end
    end

    local trackingCat = ''
    if (frame.args.trackingCat and frame.args.trackingCat == 'yes') then
        trackingCat = '[[Category:Articles with automatically detected infobox date metadata]]'
    end

    if (dtstartSpan and dtendSpan) then return '<span style="display:none">&#160;(' .. dtstartSpan .. ' - ' .. dtendSpan .. ')</span>' .. trackingCat
    elseif (dtstartSpan) then return '<span style="display:none">&#160;(' .. dtstartSpan .. ')</span>' .. trackingCat
    elseif (dtendSpan) then return '<span style="display:none">&#160;(' .. dtendSpan .. ')</span>' .. trackingCat
    else return nil end

end

function main.outputRawStripped(frame)
    return stripFieldExtras(trim(mw.text.decode(mw.text.unstrip(frame.args[1]))))
end


function main.reoutputme(frame)
    if (frame.args.preprocess and frame.args.preprocess == 'yes') then
        return frame:preprocess(mw.text.decode(mw.text.unstrip(frame.args[1]))) .. '[[Category:Dummy]]'
    else
        return mw.text.decode(mw.text.unstrip(frame.args[1])) .. '[[Category:Dummy]]'
    end    
    
    --[[local input = mw.text.decode(mw.text.unstrip(frame.args[1]))
    
    s = 'Len=' .. #input .. ' '
    for i = 1, string.len(input) do
        s = s .. string.sub(input, i, i) .. ' '
    end
    return s]]
end

return main