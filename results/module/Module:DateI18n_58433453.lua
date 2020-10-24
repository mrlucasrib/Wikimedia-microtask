--[[  
  __  __           _       _        ____        _       ___ _  ___        
 |  \/  | ___   __| |_   _| | ___ _|  _ \  __ _| |_ ___|_ _/ |( _ ) _ __  
 | |\/| |/ _ \ / _` | | | | |/ _ (_) | | |/ _` | __/ _ \| || |/ _ \| '_ \ 
 | |  | | (_) | (_| | |_| | |  __/_| |_| | (_| | ||  __/| || | (_) | | | |
 |_|  |_|\___/ \__,_|\__,_|_|\___(_)____/ \__,_|\__\___|___|_|\___/|_| |_|
  
This module is intended for processing of date strings.

Please do not modify this code without applying the changes first at Module:Date/sandbox and testing 
at Module:Date/sandbox/testcases and Module talk:Date/sandbox/testcases.

Authors and maintainers:
* User:Parent5446 - original version of the function mimicking template:ISOdate
* User:Jarekt - original version of the functions mimicking template:Date 
]]
require('Module:No globals')

-- ==================================================
-- === Internal functions ===========================
-- ==================================================

-- Function allowing for consistent treatment of boolean-like wikitext input.
-- It works similarly to Module:Yesno
local function yesno(val, default)
	if type(val) == 'boolean' then
		return val
	elseif type(val) == 'number' then
		if val==1 then 
			return true
		elseif val==0 then
			return false
		end
	elseif type(val) == 'string' then
	    val = mw.ustring.lower(val)  -- put in lower case
	    if val == 'no'  or val == 'n' or val == 'false' or tonumber(val) == 0 then
	        return false
	    elseif val == 'yes' or val == 'y' or val == 'true'  or tonumber(val) == 1 then
	        return true
	    end
    end
    return default
end

---------------------------------------------------------------------------------------
-- String replacement that ignores part of the string in "..."
local function strReplace(String, old, new)
	if String:find('"') then
		local T={}
		for i, str in ipairs(mw.text.split( String, '"', true )) do
			if i%2==1 then
				str = str:gsub(old, new)
			end
			table.insert(T, str)
		end
		return table.concat(T,'"')
	else
		return String:gsub(old, new)
	end
end

---------------------------------------------------------------------------------------
-- process datevec
-- INPUT:
--  * datevec - Array of {year,month,day,hour,minute,second, tzhour, tzmin} containing broken 
--    down date-time component strings or numbers
-- OUTPUT:
--  * datecode - a code specifying content of the array where Y' is year, 'M' is month, 
--     'D' is day, 'H' is hour, 'M' minute, 'S' is second. output has to be one of YMDHMS, YMDHM, YMD, YM, MD, Y
--  * datenum - same array but holding only numbers or nuls
local function parserDatevec(datevec)
	-- if month is not a number than check if it is a month name in project's language
	local month = datevec[2]
	if month and month~='' and not tonumber(month) then
		datevec[2] = mw.getContentLanguage():formatDate( "n", month)
	end

	-- create datecode based on which variables are provided and check for out-of-bound values
	local maxval = {nil, 12, 31, 23, 59, 59,  23, 59} -- max values for year, month, ...
	local minval = {nil,  1,  1,  0,  0,  0, -23,  0} -- min values for year, month, ...
	local c = {'Y', 'M', 'D', 'H', 'M', 'S', '', ''}
	local datecode = '' -- a string signifying which combination of variables was provided
	local datenum = {}  -- date-time encoded as a vector = [year, month, ... , second]
	for i = 1,8 do
		datenum[i] = tonumber(datevec[i])
		if datenum[i] and (i==1 or (datenum[i]>=minval[i] and datenum[i]<=maxval[i])) then
			datecode = datecode .. c[i]
		end
	end
	return datecode, datenum
end
	
---------------------------------------------------------------------------------------
-- process datevec
-- INPUT:
--  * datecode - a code specifying content of the array where Y' is year, 'M' is month, 
--     'D' is day, 'H' is hour, 'M' minute, 'S' is second. output has to be one of YMDHMS, YMDHM, YMD, YM, MD, Y
--  * datenum - Array of {year,month,day,hour,minute,second, tzhour, tzmin} as numbers or nuls
-- OUTPUT:
--  * timeStamp - date string in the format taken by mw.language:formatDate lua function and {{#time}} perser function
--       https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual#mw.language:formatDate
--       https://www.mediawiki.org/wiki/Help:Extension:ParserFunctions#.23time
--  * datecode - with possible corrections
local function getTimestamp(datecode, datenum)
	-- create time stamp string (for example 2000-02-20 02:20:20) based on which variables were provided
	local timeStamp
	if datecode == 'YMDHMS' then
		timeStamp = string.format('%04i-%02i-%02i %02i:%02i:%02i', datenum[1], datenum[2], datenum[3], datenum[4], datenum[5], datenum[6] )
	elseif datecode == 'YMDHM' then
		timeStamp = string.format('%04i-%02i-%02i %02i:%02i', datenum[1], datenum[2], datenum[3], datenum[4], datenum[5] )
	elseif datecode:sub(1,3)=='YMD' then
		timeStamp = string.format('%04i-%02i-%02i', datenum[1], datenum[2], datenum[3] )
		datecode = 'YMD' -- 'YMD', 'YMDHMS' and 'YMDHM' are the only supported format starting with 'YMD'. All others will be converted to 'YMD'
	elseif datecode == 'YM' then
		timeStamp = string.format('%04i-%02i', datenum[1], datenum[2] )
	elseif datecode:sub(1,1)=='Y' then
		timeStamp = string.format('%04i', datenum[1] )
		datecode = 'Y' 
	elseif datecode == 'M' then
		timeStamp = string.format('%04i-%02i-%02i', 2000, datenum[2], 1 )
	elseif datecode == 'MD' then
		timeStamp = string.format('%04i-%02i-%02i', 2000, datenum[2], datenum[3] )
	else
		timeStamp = nil -- format not supported
	end
	return timeStamp, datecode
end

---------------------------------------------------------------------------------------
-- trim leading zeros in years prior to year 1000
-- INPUT:
--  * datestr   - translated date string 
--  * lang      - language of translation
-- OUTPUT:
--  * datestr - updated date string 

local function trimYear(datestr, year, lang)
	local yearStr0, yearStr1, yearStr2, zeroStr
	yearStr0 = string.format('%04i', year ) -- 4 digit year in standard form "0123"
	yearStr1 = mw.language.new(lang):formatDate( 'Y', yearStr0) -- same as calling {{#time}} parser function
	--yearStr1 = mw.getCurrentFrame():callParserFunction( "#time", { 'Y', yearStr0, lang } ) -- translate to a language 
	if yearStr0==yearStr1 then -- most of languages use standard form of year 
		yearStr2 = tostring(year)
	else -- some languages use different characters for numbers
		yearStr2 = yearStr1
		zeroStr = mw.ustring.sub(yearStr1,1,1) -- get "0" in whatever language
		for i=1,3 do -- trim leading zeros
			if mw.ustring.sub(yearStr2,1,1)==zeroStr then
				yearStr2 = mw.ustring.sub(yearStr2, 2, 5-i)
			else
				break
			end
		end
	end
	return string.gsub(datestr, yearStr1, yearStr2 ) -- in datestr replace long year with trimmed one
end

---------------------------------------------------------------------------------------
-- Look up proper format string to be passed to {{#time}} parser function
-- INPUTS:
--  * datecode: YMDHMS, YMDHM, YMD, YM, MD, Y, or M
--  * day     : Number between 1 and 31 (not needed for most languages)
--  * lang    : language
-- OUTPUT:
--  * dFormat : input to {{#time}} function
local function getDateFormat(datecode, day, lang)
	local function parseFormat(dFormat, day)
		if dFormat:find('default') and #dFormat>10 then
			-- special (and messy) case of dFormat code depending on a day number
			-- then json contains a string with more json containing "default" field and 2 digit day keys
			-- if desired day is not in that json than use "default" case
			dFormat = dFormat:gsub('”','"') -- change fancy double quote to a straight one, used for json marking
			local D = mw.text.jsonDecode( dFormat )		--com = mw.dumpObject(D)
			day = string.format('d%02i',day) -- create day key
			dFormat = D[day] or D.default
			dFormat = dFormat:gsub("'", '"') -- change single quote to a double quote, used for {{#time}} marking
		end
		return dFormat
	end
	
	local T = {}
	local tab = mw.ext.data.get('DateI18n.tab', lang)
	for _, row in pairs(tab.data) do -- convert the output into a dictionary table
		local id, _, msg = unpack(row)
		T[id] = msg
	end
	local dFormat = T[datecode]
	if dFormat=='default' and (datecode=='YMDHMS' or datecode=='YMDHM')  then 
		-- for most languages adding hour:minute:second is done by adding ", HH:MM:SS to the 
		-- day precission date, those languages are skipped in DateI18n.tab and default to 
		-- English which stores word "default"
		dFormat = parseFormat(T['YMD'], day).. ', H:i'
		if datecode=='YMDHMS' then
			dFormat = dFormat .. ':s'
		end
	else
		dFormat = parseFormat(dFormat, day)
	end
	return dFormat
end

---------------------------------------------------------------------------------------
-- Look up proper format string to be passed to {{#time}} parser function
-- INPUTS:
--  * month : month number
--  * case  : gramatic case abbriviation, like "ins", "loc"
--  * lang  : language
-- OUTPUT:
--  * dFormat : input to {{#time}} function
local function MonthCase(month, case, lang)
	local T = {{},{},{},{},{},{},{},{},{},{},{},{}}
	local tab = mw.ext.data.get('I18n/MonthCases.tab', lang)
	for _, row in pairs(tab.data) do
		local mth, cs, msg = unpack(row)
		T[mth][cs] = msg
	end
	return T[month][case]
end

-- ==================================================
-- === External functions ===========================
-- ==================================================
local p = {}

--[[ ========================================================================================
Date
 
This function is the core part of the ISOdate template. 
 
Usage:
  local Date = require('Module:DateI18n')._Date
  local dateStr = Date({2020, 12, 30, 12, 20, 11}, lang)
 
Parameters:
  * {year,month,day,hour,minute,second, tzhour, tzmin}: broken down date-time component strings or numbers
		tzhour, tzmin are timezone offsets from UTC, hours and minutes
  * lang: The language to display it in
  * case: Language format (genitive, etc.) for some languages
  * class: CSS class for the <time> node, use "" for no metadata at all
]]
function p._Date(datevec, lang, case, class, trim_year)	
	-- make sure inputs are in the right format
	if not lang or not mw.language.isValidCode( lang ) then
		lang = mw.getCurrentFrame():callParserFunction( "int", "lang" ) -- get user's chosen language
	end
	if lang == 'be-tarsk' then
		lang = 'be-x-old'
	end
	
	-- process datevec and extract timeStamp and datecode strings as well as numeric datenum array
	local datecode,  datenum  = parserDatevec(datevec)
	local year, month, day = datenum[1], datenum[2], datenum[3]
	local timeStamp, datecode = getTimestamp(datecode, datenum)
	if not timeStamp then -- something went wrong in parserDatevec
		return ''
	end
	-- Commons [[Data:DateI18n.tab]] page stores prefered formats for diferent 
	-- languages and datecodes (specifying year-month-day or just year of month-day, etc)
	-- Look up country specific format input to {{#time}} function
	local dFormat = getDateFormat(datecode, day, lang)

	-- By default the gramatical case is not specified (case=='') allowing the format to be specified 
	-- in [[Data:DateI18n.tab]]. You can overwrite the default grammatical case of the month by 
	-- specifying "case" variable. This is needed mostly by Slavic languages to create more complex 
	-- phrases as it is done in [[c:Module:Complex date]]
	case = case or ''
	if (lang=='qu' or lang=='qug') and (case=='nom') then
		-- Special case related to Quechua and Kichwa languages. The form in the I18n is
		--  Genitive case with suffix "pi" added to month names provided by {#time}}
		-- in Nominative case that "pi" should be removed
		-- see https://commons.wikimedia.org/wiki/Template_talk:Date#Quechua from 2014
		dFormat = dFormat:gsub('F"pi"', 'F')
	elseif (case=='gen') then
		dFormat = strReplace(dFormat, "F", "xg")
	elseif (case=='nom') then
		dFormat = strReplace(dFormat, "xg", "F")
	elseif (case ~= '') then
		-- see is page [[Data:I18n/MonthCases.tab]] on Commons have name of the month 
		-- in specific gramatic case in desired language. If we have it than replace 
		-- "F" and xg" in dFormat
		local monthMsg = MonthCase(month, case, lang)
		if  monthMsg and monthMsg ~= '' then -- make sure it exists
			dFormat = strReplace(dFormat, 'F',  '"'..monthMsg..'"') -- replace default month with month name we already looked up
			dFormat = strReplace(dFormat, 'xg', '"'..monthMsg..'"')
		end
	end

    -- Translate the date using specified format
	-- See https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual#mw.language:formatDate and 
	-- https://www.mediawiki.org/wiki/Help:Extension:ParserFunctions##time for explanation of the format
	local datestr = mw.language.new(lang):formatDate( dFormat, timeStamp) -- same as using {{#time}} parser function
	
	-- Special case related to Thai solar calendar: prior to 1940 new-year was at different 
	-- time of year, so just year (datecode=='Y') is ambiguous and is replaced by "YYYY or YYYY" phrase
	if lang=='th' and datecode=='Y' and year<=1940 then
		datestr = string.format('%04i หรือ %04i', year+542, year+543 ) 
	end
	
	-- If year<1000 than either keep the date padded to the length of 4 digits or trim it
	-- decide if the year will stay padded with zeros (for years in 0-999 range)
	if year and year<1000 then
		if type(trim_year)=='nil' then 
			trim_year = '100-999'
		end
		local trim = yesno(trim_year,nil) -- convert to boolean
		if trim==nil and type(trim_year)=='string' then
			-- if "trim_year" not a simple True/False than it is range of dates
			-- for example '100-999' means to pad one and 2 digit years to be 4 digit long, while keeping 3 digit years as is
			local YMin, YMax = trim_year:match( '(%d+)-(%d+)' )
			trim = (YMin~=nil and year>=tonumber(YMin) and year<=tonumber(YMax)) 
		end
		if trim==true then
			datestr = trimYear(datestr, year, lang) -- in datestr replace long year with trimmed one
		end
	end

	-- append timezone if present
	if datenum[7] and (datecode == 'YMDHMS' or datecode == 'YMDHM') then
		-- use {{#time}} parser function to create timezone string, so that we use correct character set
		local sign = (datenum[7]<0) and '−' or '+'
		timeStamp = string.format("2000-01-01 %02i:%02i:00", math.abs(datenum[7]), datenum[8] or 0)
		local timezone = mw.language.new(lang):formatDate( 'H:i', timeStamp) -- same as using {{#time}} parser function
		datestr = string.format("%s %s%s", datestr, sign, timezone )
	end

	-- html formating and tagging of date string
	if class and class ~= '' and datecode~='M' and datecode~='MD'then
		local DateHtmlTags = '<span style="white-space:nowrap"><time class="%s" datetime="%s">%s</time></span>'
		datestr = DateHtmlTags:format(class, timeStamp, datestr)
	end
	return datestr
end

--[[ ========================================================================================
Date
 
This function is the core part of the ISOdate template. 
 
Usage:
{{#invoke:DateI18n|Date|year=|month=|day=|hour=|minute=|second=|tzhour=|tzmin=|lang=en}}
 
Parameters:
  * year, month, day, hour, minute, second: broken down date-time component strings
  * tzhour, tzmin: timezone offset from UTC, hours and minutes
  * lang: The language to display it in
  * case: Language format (genitive, etc.) for some languages
  * class: CSS class for the <time> node, use "" for no metadata at all
]]
function p.Date(frame)
	local args = {}
	for name, value in pairs( frame.args ) do 
		name = string.gsub( string.lower(name), ' ', '_')
		args[name] = value
	end
	return p._Date(	
		{ args.year, args.month, args.day, args.hour, args.minute, args.second, args.tzhour, args.tzmin },
		args.lang,                  -- language
		args.case,                  -- allows to specify grammatical case for the month for languages that use them
		args.class or 'dtstart',    -- allows to set the html class of the time node where the date is included. This is useful for microformats.
		args.trim_year or '100-999' -- by default pad one and 2 digit years to be 4 digit long, while keeping 3 digit years as is
	)	
end

return p