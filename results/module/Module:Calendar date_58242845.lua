--[[ 

Display Gregorian date of a holiday that moves year to year. Date data can be obtained from multiple sources as configured in Module:Calendar date/events

  "localfile" = local data file (eg. https://en.wikipedia.org/wiki/Module:Calendar_date/localfiles/Hanukkah)
  "calculator" = user-supplied date calculator 
  "wikidata" = <tbd> for holidays with their own date entity page such as https://www.wikidata.org/wiki/Q51224536
               
 ]]

require('Module:No globals')

local p = {}
local cfg						-- Data structure from ~/events
local eventdata					-- Data structure from ~/localfiles/<holiday name>
local track = {}				-- Tracking category container

--[[--------------------------< inlineError >-----------------------

     Critical error. Render output completely in red. Add to tracking category.

 ]]

local function inlineError(arg, msg, tname)

	track["Category:Calendar date template errors"] = 1
	return '<span style="font-size:100%" class="error citation-comment">Error in {{' .. tname .. '}} - Check <code style="color:inherit; border:inherit; padding:inherit;">&#124;' .. arg .. '=</code>  ' .. msg .. '</span>'

end

--[[--------------------------< trimArg >-----------------------

	 trimArg returns nil if arg is "" while trimArg2 returns 'true' if arg is "" 
	 trimArg2 is for args that might accept an empty value, as an on/off switch like nolink=

 ]]

local function trimArg(arg)
	if arg == "" or arg == nil then
		return nil
	else
		return mw.text.trim(arg)
	end
end
local function trimArg2(arg)
	if arg == nil then
		return nil
	else
		return mw.text.trim(arg)
	end
end

--[[--------------------------< tableLength >-----------------------

	Given a 1-D table, return number of elements

  ]]

local function tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--[[-------------------------< make_wikilink >----------------------------------------------------

	Makes a wikilink; when both link and display text is provided, returns a wikilink in the form [ [L|D] ]; if only
	link is provided, returns a wikilink in the form [ [L] ]; if neither are provided or link is omitted, returns an
	empty string.

  ]]

local function make_wikilink (link, display, no_link)
	if nil == no_link then
		if link and ('' ~= link) then
			if display and ('' ~= display) then
				return table.concat ({'[[', link, '|', display, ']]'});
			else
				return table.concat ({'[[', link, ']]'});
			end
		end
	else																		-- no_link
		if display and ('' ~= display) then										-- if there is display text
			return display;														-- return that
		else
			return link or '';													-- return the target article name or empty string
		end
	end
end

--[[--------------------------< createTracking >-----------------------

	Return data in track[] ie. tracking categories

  ]]

local function createTracking()

	local out = {};
	if tableLength(track) > 0 then
		for key, _ in pairs(track) do											-- loop through table
			table.insert (out, make_wikilink (key))								-- and convert category names to links
		end
	end
	return table.concat (out)													-- concat into one big string; empty string if table is empty
end

--[[--------------------------< isValidDate >----------------------------------------------------

	Returns true if date is after 31 December 1899 , not after 2100, and represents a valid date 
	(29 February 2017 is not a valid date).  Applies Gregorian leapyear rules. All arguments are required.

]]

local function isValidDate (year, month, day)

	local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	local month_length
	local y, m, d
	local today = os.date ('*')										-- fetch a table of current date parts

	if not year or year == '' or not month or month == '' or not day or day == '' then
		return false												-- something missing
	end

	y = tonumber (year)
	m = tonumber (month)
	d = tonumber (day)

	if 1900 > y or 2100 < y or 1 > m or 12 < m then					-- year and month are within bounds
		return false
	end

	if (2==m) then													-- if February
		month_length = 28											-- then 28 days unless
		if (0==(y%4) and (0~=(y%100) or 0==(y%400))) then			-- is a leap year?
			month_length = 29										-- if leap year then 29 days in February
		end
	else
		month_length=days_in_month[m];
	end

	if 1 > d or month_length < d then								-- day is within bounds
		return false
	end
	
	return true
end

--[[--------------------------< makeDate >-----------------------

	Given a zero-padded 4-digit year, 2-digit month and 2-digit day, return a full date in df format
	df = mdy, dmy, iso, ymd

 ]]

local function makeDate(year, month, day, df, format)
	local formatFull = {
		['dmy'] = 'j F Y',
		['mdy'] = 'F j, Y',
		['ymd'] = 'Y F j',
		['iso'] = 'Y-m-d'
	}
	local formatInfobox = {
		['dmy'] = 'j F',
		['mdy'] = 'F j',
		['ymd'] = 'F j',
		['iso'] = 'Y-m-d'
	}

	if not year or year == "" or not month or month == "" or not day or day == "" and format[df] then
		return nil
	end

	local date = table.concat ({year, month, day})               -- assemble iso format date
	if format ~= "infobox" then
		return mw.getContentLanguage():formatDate (formatFull[df], date)
	else
		return mw.getContentLanguage():formatDate (formatInfobox[df], date)
	end
end

--[[--------------------------< dateOffset >-----------------------

	Given a 'origdate' in ISO format, return the date offset by number of days in 'offset' 
		eg. given "2018-02-01" and "-1" it will return "2018-01-30"
	On error, return origdate

  ]]

local function dateOffset(origdate, offset)

	local year, month, day = origdate:match ('(%d%d%d%d)-(%d%d)-(%d%d)')
	local now = os.time{year = year, month = month, day = day}
	local newdate = os.date("%Y-%m-%d", now + (tonumber(offset) * 24 * 3600))
	return newdate and newdate or origdate

  end

--[[--------------------------< renderHoli >-----------------------

	Render the data

  ]]
  
local function renderHoli(cfg,eventdata,calcdate,date,df,format,tname,cite)

	local hits = 0
	local matchdate = "^" .. date
	local startdate,enddate,outoffset,endoutoffset = nil
	local starttitle,endtitle = ""  

	-- user-supplied date calculator 
	if cfg.datatype == "calculator" then
		if cfg.datasource then
			startdate = calcdate
			enddate = dateOffset(startdate, cfg.days - 1)
		else
			return inlineError("holiday", 'invalid calculator result', tname )
		end

	-- read dates from localfile -- it assumes dates are in chrono order, need a more flexible method
	elseif cfg.datatype == "localfile" then                                              
		local numRecords = tableLength(eventdata) -- Get first and last date of holiday
		for i = 1, numRecords do
			if mw.ustring.find( eventdata[i].date, matchdate ) then
				if hits == 0 then
					startdate = eventdata[i].date
					hits = 1
				end
				if hits >= tonumber(cfg.days) then
					enddate = eventdata[i].date
					break
				end
				hits = hits + 1
			end
		end
	end
     
	-- Verify data and special conditions
	if startdate == nil or enddate == nil then 
		if cfg.name == "Hanukkah" and startdate and not enddate then  -- Hanukkah bug, template doesn't support cross-year boundary
			enddate = dateOffset(startdate, 8)
		elseif cfg.datatype == "localfile" and cfg.days > "1" and startdate then
			enddate = dateOffset(startdate, cfg.days - 1)
		elseif startdate and not enddate then
			return inlineError("year", 'cannot find enddate', tname) .. createTracking()
		else
			return inlineError("holiday", 'cannot find startdate and enddate', tname) .. createTracking()
		end
	end
     
	-- Generate start-date offset (ie. holiday starts the evening before the given date)
	if cfg.startoffset then
		startdate = dateOffset(startdate, cfg.startoffset)
		if startdate ~= enddate then
			enddate = dateOffset(enddate, cfg.startoffset)
		else
			cfg.days = (cfg.days == "1") and "2"
		end
	end
 
	-- Generate end-date outside-Irael offset (ie. outside Israel the holiday ends +1 day later)
	endoutoffset = cfg.endoutoffset and dateOffset(enddate, cfg.endoutoffset)

	-- Format dates into df format 
	local year, month, day = startdate:match ('(%d%d%d%d)-(%d%d)-(%d%d)')
	startdate = makeDate(year, month, day, df, format)
	year, month, day = enddate:match ('(%d%d%d%d)-(%d%d)-(%d%d)')
	enddate = makeDate(year, month, day, df, format)
	if startdate == nil or enddate == nil then return nil end

	-- Add "outside of Israel" notices
	if endoutoffset then
		year, month, day = endoutoffset:match ('(%d%d%d%d)-(%d%d)-(%d%d)')
		local leader = ((format == "infobox") and "<br>") or " "
		endoutoffset = leader .. "(" .. makeDate(year, month, day, df, "infobox") .. " outside of Israel)"
	end
	if not endoutoffset then
		endoutoffset = ""
	end

	--- Determine format string
	format = ((format == "infobox") and " –<br>") or " – "

	--- Determine pre-pended text string eg. "sunset, <date>"
	local prepend1 = (cfg.prepend1 and (cfg.prepend1 .. ", ")) or ""
	local prepend2 = (cfg.prepend2 and (cfg.prepend2 .. ", ")) or ""

	-- return output
	if startdate == enddate or cfg.days == "1" then            -- single date
		return prepend1 .. startdate .. endoutoffset .. cite
	else
		return prepend1 .. startdate .. format .. prepend2 .. enddate .. endoutoffset .. cite
	end
end

--[[--------------------------< calendardate >-----------------------

     Main function

  ]]

function p.calendardate(frame)

	local pframe = frame:getParent()
	local args = pframe.args

	local tname = "Calendar date"					-- name of calling template. Change if template rename.
	local holiday = nil								-- name of holiday
	local date = nil								-- date of holiday (year) 
	local df = nil									-- date format (mdy, dmy, iso - default: iso)
	local format = nil								-- template display format options
	local cite = nil								-- leave a citation at end 
	local calcdate = ""             

	--- Determine holiday
	holiday = trimArg(args.holiday)					-- required
	if not holiday then
		holiday = trimArg(args.event)				-- event alias
		if not holiday then
			return inlineError("holiday", 'missing holiday argument', tname) .. createTracking()
		end
	end

	--- Determine date
	date = trimArg(args.year)						-- required
	if not date then
		return inlineError("year", 'missing year argument', tname) .. createTracking()
	elseif not isValidDate(date, "01", "01") then
		return inlineError("year", 'invalid year', tname) .. createTracking()
	end

	--- Determine format type
	format = trimArg(args.format)
	if not format then
		format = "none"
	elseif format ~= "infobox" then
		format = "none"
	end 

	-- Load configuration file
	local eventsfile = mw.loadData ('Module:Calendar date/events')
	if eventsfile.hebrew_calendar[mw.ustring.upper(holiday)] then
		cfg = eventsfile.hebrew_calendar[mw.ustring.upper(holiday)]
	elseif eventsfile.christian_events[mw.ustring.upper(holiday)] then
		cfg = eventsfile.christian_events[mw.ustring.upper(holiday)]
	elseif eventsfile.carnivals[mw.ustring.upper(holiday)] then
		cfg = eventsfile.carnivals[mw.ustring.upper(holiday)]
	elseif eventsfile.chinese_events[mw.ustring.upper(holiday)] then
		cfg = eventsfile.chinese_events[mw.ustring.upper(holiday)]
	elseif eventsfile.misc_events[mw.ustring.upper(holiday)] then
		cfg = eventsfile.misc_events[mw.ustring.upper(holiday)]
	else
		return inlineError("holiday", 'unknown holiday ' .. holiday, tname) .. createTracking()
	end

	-- If datatype = localfile 
	if cfg.datatype == "localfile" then
		local eventfile = nil
		eventfile = mw.loadData(cfg.datasource)
		if eventfile.event then
			eventdata = eventfile.event
		else
			return inlineError("holiday", 'unknown holiday file ' .. cfg.datasource .. '</span>', tname) .. createTracking()
		end

	-- If datatype = calculator
	elseif cfg.datatype == "calculator" then
		calcdate = frame:preprocess(cfg.datasource:gsub("YYYY", date))
		local year, month, day = calcdate:match ('(%d%d%d%d)-(%d%d)-(%d%d)')
		if not isValidDate(year, month, day) then
			return inlineError("holiday", 'invalid calculated date ' .. calcdate, tname) .. createTracking()
		end
	else
		return inlineError("holiday", 'unknown "datatype" in configuration', tname) .. createTracking()
	end

	--- Determine df - priority to |df in template, otherwise df in datafile, otherwise default to dmy
	df = trimArg(args.df)
	if not df then
		df = (cfg.df and cfg.df) or "dmy"
	end
	if df ~= "mdy" and df ~= "dmy" and df ~= "iso" then
		df = "dmy"
	end

	-- Determine citation
	cite = trimArg2(args.cite)
	if cite then
		if (cite ~= "no") then
			cite = ""
			if cfg.citeurl and cfg.accessdate and cfg.source and cfg.name then
				local citetitle = cfg.citetitle
				if citetitle == nil then
					citetitle = 'Dates for ' .. cfg.name
				end
				cite = frame:preprocess('<ref name="' .. holiday .. ' dates">{{cite web |url=' .. cfg.citeurl .. ' |title=' .. citetitle .. ' |publisher=' .. cfg.source .. '|accessdate=' .. cfg.accessdate .. '}}</ref>')
			elseif cfg.source then
				cite = frame:preprocess('<ref name="' .. holiday .. ' dates">' .. cfg.source:gsub("YYYY", date) .. '</ref>')
			else
				cite = ""
			end
		else
			cite = ""
		end
	else
		cite = ""
	end

	-- Render 
	local rend = renderHoli( cfg,eventdata,calcdate,date,df,format,tname,cite)
	if not rend then
		rend = '<span style="font-size:100%" class="error citation-comment">Error in [[:Template:' .. tname .. ']]: Unknown problem. Please report on template talk page.</span>'
		track["Category:Webarchive template errors"] = 1 
	end

	return rend .. createTracking()

end

return p