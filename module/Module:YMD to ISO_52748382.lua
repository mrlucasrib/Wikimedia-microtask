local p = {}

local function month_number(month_name)
    local months_full = {january=1, february=2, march=3, april=4, may=5, june=6, july=7, august=8, september=9, october=10, november=11, december=12}
    local months_abbr = {jan=1, feb=2, mar=3, apr=4, may=5, jun=6, jul=7, aug=8, sep=9, oct=10, nov=11, dec=12}
    local month_lc, _ = string.gsub(string.lower(month_name),'%.','',1)
    local month_num = months_full[month_lc] or months_abbr[month_lc] or 0
    if month_lc == 'sept' then
        month_num = 9
    end
    return month_num
end

local function days_in_month(month_num,year)
    -- modified from code in Module:Citation/CS1/Date_validation
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local month_length
    if month_num == 2 then         -- February: 28 days, unless leap year
        month_length = 28
        if year <= 1582 then       -- Julian calendar before Oct 1582
            if (year%4) == 0 then
                month_length = 29  -- if leap year, then 29 days
            end
        else                       -- Gregorian calendar since Oct 1582
            if ( (year%4)==0 and ((year%100)~=0 or (year%400)==0) ) then  
                month_length = 29  -- if leap year, then 29 days   
            end
        end
    else                           -- not February, get number of days for month
        month_length = days[month_num]
    end
    return month_length
end

local function zero_pad(string)
    if string.len(string) == 1 then
        return '0' .. string
    else
        return string
    end
end

function p.main(frame)
    if frame.args[1] == nil then
        return ''     -- first argument is missing
    end
    local arg1, _ = string.gsub(mw.text.trim(frame.args[1]),'_',' ')
    return p._main(arg1)
end
function p._main(arg1)
    if arg1 == '' then
        return ''     -- first argument is empty
    end
    if not arg1:match('^%d%d%d%d %a%a%a%a?%.?%a?%a?%a?%a?%a?%a? *%d%d?$') then
        return arg1   -- invalid date pattern
    end
    local year, month_name, day = string.match(arg1, '^(%d%d%d%d) *(%a%a%a%a?%.?%a?%a?%a?%a?%a?%a?) *(%d%d?)$')
    if month_number(month_name) == 0 then
        return arg1   -- invalid month name or abbreviation
    end
    if tonumber(day) < 1 or tonumber(day) > days_in_month(month_number(month_name),tonumber(year)) then
        return arg1   -- invalid day number for given month
    end
    return year .. '-' .. zero_pad(tostring(month_number(month_name))) .. '-' .. zero_pad(day)
end

return p