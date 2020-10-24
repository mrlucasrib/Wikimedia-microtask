local p = {}
local bool_to_number={ [true]=1, [false]=0 }
local getArgs = require('Module:Arguments').getArgs
local err = "-"

local function purif(str)
    if str == "" or str == nil then
        return nil
    elseif type(tonumber(str)) == "number" then
        return math.floor(tonumber(str))
    else
        return nil
    end
    -- need .5 -- ,5 number format converter?
end

local function inbord(val, down, up)
	if type(up) ~= "number" or type(down) ~= "number" or type(val) ~= "number" or up < down or val < down or val > up then
		return false
    else
        return true
    end
end

local function isdate ( chain )
	if (not type(chain) == "table")
	or (not inbord(chain.year,-9999,9999))
	or (not inbord(chain.month,1,12))
	or (not inbord(chain.day,1,31))
	then return false
	else return true end
--  more detailed check for 31.02.0000 needed
--  check for other calendars needed
end

local function numstr2date(datein)
	local nums = {}
    local dateout = {}
    for num in string.gmatch(datein,"(%d+)") do
        table.insert(nums,purif(num))
    end
    if #nums ~= 3 then error("Wrong format: 3 numbers expected")
    elseif not inbord(nums[2],1,12) then error("Wrong month")
    elseif not inbord(nums[3],1,31) then
        dateout = {["year"]=nums[3], ["month"]=nums[2], ["day"]=nums[1]}
    elseif not inbord(nums[1],1,31) then
        dateout = {["year"]=nums[1], ["month"]=nums[2], ["day"]=nums[3]}
    else
--		local lang = mw.getContentLanguage()
--		implement lang:formatDate(format,datein,true) here
        return error("Unable to recognize date")
    end
    return dateout
end

local function date2str(datein)
	if not isdate(datein) then return error("Wrong date") end
	local dateout = os.date("%Y-%m-%d", os.time(datein))
    return dateout
end

function gri2jd( datein )
	if not isdate(datein) then return error("Wrong date") end
    local year = datein.year
    local month = datein.month
    local day = datein.day
    -- jd calculation
    local a = math.floor((14 - month)/12)
    local y = year + 4800 - a
    local m = month + 12*a - 3
    local offset = math.floor(y/4) - math.floor(y/100) + math.floor(y/400) - 32045
    local jd = day + math.floor((153*m + 2)/5) + 365*y + offset
    -- jd validation
    local low, high = -1931076.5, 5373557.49999
    if not (low <= jd and jd <= high) then
        return error("Wrong date")
    end
	return jd
end

function jd2jul( jd )
	if type(jd) ~= "number" then return error("Wrong jd") end
    -- calendar date calculation
    local c = jd + 32082
    local d = math.floor((4*c + 3)/1461)
    local e = c - math.floor(1461*d/4)
    local m = math.floor((5*e + 2)/153)
    local year_out = d - 4800 + math.floor(m/10)
    local month_out = m + 3 - 12*math.floor(m/10)
    local day_out = e - math.floor((153*m + 2)/5) + 1
    -- output
    local dateout = {["year"]=year_out, ["month"]=month_out, ["day"]=day_out}
    return dateout
end

function jul2jd( datein )
	if not isdate(datein) then return error("Wrong date") end
    local year = datein.year
    local month = datein.month
    local day = datein.day
    -- jd calculation
    local a = math.floor((14 - month)/12)
    local y = year + 4800 - a
    local m = month + 12*a - 3
    local offset = math.floor(y/4) - 32083
    local jd = day + math.floor((153*m + 2)/5) + 365*y + offset
    -- jd validation
    local low, high = -1930999.5, 5373484.49999
    if not (low <= jd and jd <= high) then
        return error("Wrong date")
    end
	return jd
end

function jd2gri( jd )
    -- calendar date calculation
    local a = jd + 32044
    local b = math.floor((4*a + 3) / 146097)
    local c = a - math.floor(146097*b/4)
    local d = math.floor((4*c+3)/1461)
    local e = c - math.floor(1461*d/4)
    local m = math.floor((5*e+2)/153)
    local day_out =  e - math.floor((153*m+2)/5)+1
    local month_out = m + 3 - 12*math.floor(m/10)
    local year_out = 100*b + d - 4800 + math.floor(m/10)
    -- output
    local dateout = {["year"]=year_out, ["month"]=month_out, ["day"]=day_out}
    return dateout
end

-- =p.NthDay(mw.getCurrentFrame():newChild{title="1",args={"1","1","1","2020","%Y-%m-%d"}}) 

function p.NthDay( frame )
    local args = getArgs(frame, { frameOnly = true })
    local num, wday, mont, yea, format = 
    	purif(args[1]), purif(args[2]), purif(args[3]), purif(args[4]), args[5]
    if not format then format = "%Y-%m-%d" end
    if not inbord(num,-5,5) then 
    	return error("The number must be between -5 and 5")
    elseif num == 0 then 
    	return error("The number must not be zero") end
    if not inbord(wday,0,6) then 
    	return error("The day of the week must be between 0 and 6") end
    if not inbord(mont,1,12) then 
    	return error("The month must be between 1 and 12") end
    if not inbord(yea,0,9999) then 
    	return error("Wrong year number") end
    if inbord(num,1,5) then
        local m_start = os.time{year=yea, month=mont, day=1, hour=0}
        local m_wds = tonumber(os.date("%w", m_start)) 
        local start_shift = (
            (num - bool_to_number[wday >= m_wds]) * 7 
            - (m_wds - wday)
            ) * 24 * 60 * 60
        local tim = m_start + start_shift
        if tonumber(os.date("%m", tim)) == mont then
            return (os.date(format, tim))
        else
            return (err)
        end
    elseif inbord(num,-5,-1) then
        local m_end = os.time{year = yea, month = mont + 1, day = 1, hour = 0} - 24 * 60 * 60
        local m_wde = tonumber(os.date("%w", m_end))
        local end_shift = ((math.abs(num + 1) + bool_to_number[wday > m_wde]) * 7 
            + (m_wde - wday)) * 24 * 60 * 60
        local tim = m_end - end_shift
        if tonumber(os.date("%m", tim)) == mont then
            return (os.date(format, tim))
        else
            return (err)
        end
    end
end

-- =p.test(mw.getCurrentFrame():newChild{title="1",args={"1.1.2020"}}) 

function p.test(frame)
	local args = getArgs(frame, { frameOnly = true })
	local input = args[1]
	if not input then
		return ""
	else
		local datetest = numstr2date(input)
		if isdate(datetest) then
			strout = datetest.day .. "." .. datetest.month .. "." .. datetest.year .. " = " .. gri2jd(datetest)
			return strout
		else error("Not a date")
		end
	end
	error("You shouldn't read this too")
end

return p