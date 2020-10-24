require ('Module:No globals')
local yesno = require('Module:Yesno')
local getArgs = require ('Module:Arguments').getArgs

local tz = {};																	-- holds local copy of the specified timezone table from tz_data{}
local cfg = {};																	-- for internationalization 


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not.  A variable is set when it is not nil and not empty.

]]

local function is_set( var )
	return not (nil == var or '' == var);
end


--[[--------------------------< S U B S T I T U T E >----------------------------------------------------------

Populates numbered arguments in a message string using an argument table.

]]

local function substitute (msg, args)
	return args and mw.message.newRawMessage (msg, args):plain() or msg;
end


--[[--------------------------< E R R O R _ M S G >------------------------------------------------------------

create an error message

]]

local function error_msg (msg, arg)
	return substitute (cfg.err_msg, substitute (cfg.err_text[msg], arg))
end


--[[--------------------------< D E C O D E _ D S T _ E V E N T >----------------------------------------------

extract ordinal, day-name, and month from daylight saving start/end definition string as digits:
	Second Sunday in March
returns
	2 0 3

Casing doesn't matter but the form of the string does:
	<ordinal> <day> <any single word> <month> – all are separated by spaces

]]

local function decode_dst_event (dst_event_string)
	local ord, day, month;
	
	dst_event_string = dst_event_string:lower();								-- force the string to lower case because that is how the tables above are indexed
	ord, day, month = dst_event_string:match ('([%a%d]+)%s+(%a+)%s+%a+%s+(%a+)');
	
	if not (is_set (ord) and is_set (day) and is_set (month)) then				-- if one or more of these not set, then pattern didn't match
		return nil;
	end
	
	return cfg.ordinals[ord], cfg.days[day], cfg.months[month];
end


--[[--------------------------< G E T _ D A Y S _ I N _ M O N T H >--------------------------------------------

Returns the number of days in the month where month is a number 1–12 and year is four-digit Gregorian calendar.
Accounts for leap year.

]]

local function get_days_in_month (year, month)
	local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
	
	year = tonumber (year);														-- force these to be numbers just in case
	month = tonumber (month);

	if (2 == month) then														-- if February
		if (0 == (year%4) and (0 ~= (year%100) or 0 == (year%400))) then		-- is year a leap year?
			return 29;															-- if leap year then 29 days in February
		end
	end
	return days_in_month [month];
end


--[[--------------------------< G E T _ D S T _ M O N T H _ D A Y >--------------------------------------------

Return the date (month and day of the month) for the day that is the ordinal (nth) day-name in month (second
Friday in June) of the current year

timestamp is today's date-time number from os.time(); used to supply year
timezone is the timezone parameter value from the template call

Equations used in this function taken from Template:Weekday_in_month

]]

local function get_dst_month_day (timestamp, start)
	local ord, weekday_num, month;
	local first_day_of_dst_month_num;
	local last_day_of_dst_month_num;
	local days_in_month;
	local year;

	if true == start then
		ord, weekday_num, month = decode_dst_event (tz.dst_begins);				-- get start string and convert to digits
	else
		ord, weekday_num, month = decode_dst_event (tz.dst_ends);				-- get end string and convert to digits
	end
	
	if not (is_set (ord) and is_set (weekday_num) and is_set (month)) then
		return nil;																-- could not decode event string
	end
	
	year = os.date ('%Y', timestamp);

	if -1 == ord then		-- j = t + 7×(n + 1) - (wt - w) mod 7				-- if event occurs on the last day-name of the month ('last Sunday of October')
		days_in_month = get_days_in_month (year, month);
		last_day_of_dst_month_num = os.date ('%w', os.time ({['year']=year, ['month']=month, ['day']=days_in_month}));
		return month, days_in_month + 7*(ord + 1) - ((last_day_of_dst_month_num - weekday_num) % 7);
	else	-- j = 7×n - 6 + (w - w1) mod 7
		first_day_of_dst_month_num = os.date ('%w', os.time ({['year']=year, ['month']=month, ['day']=1}))
		return month, 7 * ord - 6 + (weekday_num - first_day_of_dst_month_num) % 7;		-- return month and calculated date
	end
end


--[[--------------------------< G E T _ U T C _ O F F S E T >--------------------------------------------------

Get utc offset in hours and minutes, convert to seconds.  If the offset can't be converted return nil.
TODO: return error message?
TODO: limit check this? +/-n hours?
]]

local function get_utc_offset ()
	local sign;
	local hours;
	local minutes;
	
	sign, hours, minutes = mw.ustring.match (tz.utc_offset, '([%+%-±−]?)(%d%d):(%d%d)');

	if '-' == sign then sign = -1; else sign = 1; end
	if is_set (hours) and is_set (minutes) then
		return sign * ((hours * 3600) + (minutes * 60));
	else
		return nil;																-- we require that all timezone tables have what appears to be a valid offset
	end
end


--[[--------------------------< M A K E _ D S T _ T I M E S T A M P S >----------------------------------------

Return UTC timestamps for the date/time of daylight saving time events (beginning and ending).  These timestamps
will be compared to current UTC time.  A dst timestamp is the date/time in seconds UTC for the timezone at the
hour of the dst event.

For dst rules that specify local event times, the timestamp is the sum of:
	timestamp = current year + dst_month + dst_day + dst_time (all in seconds) local time
Adjust local time to UTC by subtracting utc_offset:
	timestamp = timestamp - utc_offset (in seconds)
For dst_end timestamp, subtract an hour for DST
	timestamp = timestamp - 3600 (in seconds)

For dst rules that specify utc event time the process is the same except that utc offset is not subtracted.

]]

local function make_dst_timestamps (timestamp)
	local dst_begin, dst_end;													-- dst begin and end time stamps 
	local year;																	-- current year
	local dst_b_month, dst_e_month, dst_day;									-- month and date of dst event
	local dst_hour, dst_minute;													-- hour and minute of dst event on year-dst_month-dst_day
	local invert = false;														-- flag to pass on when dst_begin month is numerically larger than dst_end month (southern hemisphere)
	local utc_offset;
	local utc_flag;

	year = os.date ('%Y', timestamp);											-- current year
	utc_offset = get_utc_offset ();												-- in seconds
	if not is_set (utc_offset) then												-- utc offset is a required timezone property
		return nil;
	end

	dst_b_month, dst_day = get_dst_month_day (timestamp, true);					-- month and day that dst begins
	if not is_set (dst_b_month) then
		return nil;
	end
	
	dst_hour, dst_minute = tz.dst_time:match ('(%d%d):(%d%d)');					-- get dst time
	utc_flag = tz.dst_time:find ('[Uu][Tt][Cc]%s*$');							-- set flag when dst events occur at a specified utc time

	dst_begin = os.time ({['year'] = year, ['month'] = dst_b_month, ['day'] = dst_day, ['hour'] = dst_hour, ['min'] = dst_minute});	-- form start timestamp
	if not is_set (utc_flag) then												-- if dst events are specified to occur at local time
		dst_begin = dst_begin - utc_offset;										-- adjust local time to utc by subtracting utc offset
	end

	dst_e_month, dst_day = get_dst_month_day (timestamp, false);				-- month and day that dst ends
	if not is_set (dst_e_month) then
		return nil;
	end
	
	if is_set (tz.dst_e_time) then
		dst_hour, dst_minute = tz.dst_e_time:match ('(%d%d):(%d%d)');			-- get ending dst time; this one for those locales that use different start and end times
		utc_flag = tz.dst_e_time:find ('[Uu][Tt][Cc]%s*$');						-- set flag if dst is pegged to utc time
	end	

	dst_end = os.time ({['year'] = year, ['month'] = dst_e_month, ['day'] = dst_day, ['hour'] = dst_hour, ['min'] = dst_minute});	-- form end timestamp
	if not is_set (utc_flag) then												-- if dst events are specified to occur at local time
		dst_end = dst_end - 3600;												-- assume that local end time is DST so adjust to local ST
		dst_end = dst_end - utc_offset;											-- adjust local time to utc by subtracting utc offset
	end


	if dst_b_month > dst_e_month then
		invert = true;															-- true for southern hemisphere eg: start September YYYY end April YYYY+1
	end

	return dst_begin, dst_end, invert;
end


--[[--------------------------< G E T _ T E S T _ T I M E >----------------------------------------------------

decode ISO formatted date/time into a table suitable for os.time().  Fallback to {{Timestamp}} format.
For testing, this time is UTC just as is returned by the os.time() function.

]]

local function get_test_time (iso_date)
	local year, month, day, hour, minute, second;

	year, month, day, hour, minute, second = iso_date:match ('(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)');
	if not year then
		year, month, day, hour, minute, second = iso_date:match ('^(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)$');
		if not year then
			return nil;															-- test time did not match the specified patterns
		end
	end
	return {['year'] = year, ['month'] = month, ['day'] = day, ['hour'] = hour, ['min'] = minute, ['sec'] = second};
end

--[[----------------------< G E T _ F U L L _ U T C _ O F F S E T >-----------------------------------------------

Creates a standard UTC offset from numerical inputs, for function time to convert to a table.  Expected inputs shall have the form:
	<sign><hour><separator><portion>
where:
	<sign> – optional; one of the characters: '+', '-' (hyphen), '±', '−' (minus); defaults to '+'
	<hour> - one or two digits
	<separator> - one of the characters '.' or ':'; required when <portion> is included; ignored else
	<portion> - optional; one or two digits when <separator> is '.'; two digits else

returns correct utc offset string when input has a correct form; else returns the unmodified input

]]

local function get_full_utc_offset (utc_offset)
	local h, m, sep, sign;
	
	local patterns = {
		'^([%+%-±−]?)(%d%d?)(%.)(%d%d?)$',										-- one or two fractional hour digits
		'^([%+%-±−]?)(%d%d?)(:)(%d%d)$',										-- two minute digits
		'^([%+%-±−]?)(%d%d?)[%.:]?$',											-- hours only; ignore trailing separator
		}
	
	for _, pattern in ipairs(patterns) do										-- loop through the patterns
		sign, h, sep, m = mw.ustring.match (utc_offset, pattern);
		if h then
			break;																-- if h is set then pattern matched
		end
	end

	if not h then
		return utc_offset;														-- did not match a pattern
	end
	
	sign = ('' == sign) and '+' or sign;										-- sign character is required; set to '+' if not specified

	m = ('.' == sep) and ((sep .. m) * 60) or m or 0;							-- fractional h to m

	return string.format ('utc%s%02d:%02d', sign, h, m);
end


--[[--------------------------< T A B L E _ L E N >------------------------------------------------------------

return number of elements in table

]]

local function table_len (tbl)
	local count = 0;
	for _ in pairs (tbl) do
		count = count + 1;
	end
	return count;
end


--[[--------------------------< F I R S T _ S E T >------------------------------------------------------------

scans through a list of parameter names that are aliases of each other and returns the value assigned to the
first args[alias] that has a set value; nil else. scan direction is right-to-left (top-to-bottom)

]]

local function first_set (list, args)
	local i = 1;
	local count = table_len (list);												-- get count of items in list
	
	while i <= count do															-- loop through all items in list
		if is_set( args[list[i]] ) then											-- if parameter name in list is set in args
			return args[list[i]];												-- return the value assigned to the args parameter
		end
		i = i + 1;																-- point to next
	end
end


--[=[-------------------------< T I M E >----------------------------------------------------------------------

This template takes several parameters (some positonal, some not); none are required:
	1. the time zone abbreviation/UTC offset (positional, always the first unnamed parameter)
	2. a date format flag; second positional parameter or |df=; can have one of several values
	3. |dst= when set to 'no' disables dst calculations for locations that do not observe dst – Arizona in MST
	4. |timeonly= when set to 'yes' only display the time
	5. |dateonly= when set to 'yes' only display the date
	6. |hide-refresh = when set to 'yes' removes the refresh link
	7. |hide-tz = when set to 'yes' removes the timezone name
	8. |unlink-tz = when set to 'yes' unlinks the timzone name
	9. |_TEST_TIME_= a specific utc time in ISO date time format used for testing this code
	
TODO: convert _TEST_TIME_ to |time=?

Timezone abbreviations can be found here: [[List_of_time_zone_abbreviations]]

For custom date format parameters |df-cust=,  |df-cust-a=,  |df-cust-p= use codes 
described here: [[:mw:Help:Extension:ParserFunctions##time]]

]=]

local function time (frame)
	local args = getArgs (frame);
	local utc_timestamp, timestamp;												-- current or _TEST_TIME_ timestamps; timestamp is local ST or DST time used in output
	local dst_begin_ts, dst_end_ts;												-- DST begin and end timestamps in UTC
	local tz_abbr;																-- select ST or DST timezone abbreviaion used in output 
	local time_string;															-- holds output time/date in |df= format
	local utc_offset;
	local invert;																-- true when southern hemisphere
	local DF;																	-- date format flag; the |df= parameter
	local is_dst_tz;

	local data = table.concat ({'Module:Time/data', frame:getTitle():find('sandbox', 1, true) and '/sandbox' or ''}); -- make a data module name; sandbox or live
	data = mw.loadData (data);													-- load the data module
	cfg = data.cfg;																-- get the configuration table
	local tz_aliases = data.tz_aliases;											-- get the aliases table
	local tz_data = data.tz_data;												-- get the tz data table

	local Timeonly = yesno(first_set (cfg.aliases['timeonly'], args));			-- boolean
	local Dateonly = yesno(first_set (cfg.aliases['dateonly'], args));			-- boolean
	if Timeonly and Dateonly then												-- invalid condition when both are set
		Timeonly, Dateonly = false;
	end
	
	local Hide_refresh = yesno(first_set (cfg.aliases['hide-refresh'], args));	-- boolean
	local Hide_tz = yesno(first_set (cfg.aliases['hide-tz'], args));			-- boolean
	local Unlink_tz = yesno(first_set (cfg.aliases['unlink-tz'], args));		-- boolean
	local DST = first_set (cfg.aliases['dst'], args) or true;					-- string 'always' or boolean
	
	local Lang = first_set (cfg.aliases['lang'], args);							-- to render in a language other than the local wiki's language
	
	local DF_cust = first_set (cfg.aliases['df-cust'], args);					-- custom date/time formats
	
	local DF_cust_a = first_set (cfg.aliases['df-cust-a'], args);				-- for am/pm sensitive formats
	local DF_cust_p = first_set (cfg.aliases['df-cust-p'], args);

	if not ((DF_cust_a and DF_cust_p) or										-- DF_cust_a xor DF_cust_p
			(not DF_cust_a and not DF_cust_p))then
		return error_msg ('bad_df_pair');										-- both are required
	end

	if args[1] then
		args[1] = get_full_utc_offset (args[1]):lower();						-- make lower case because tz table member indexes are lower case
	else
		args[1] = 'utc';														-- default to utc
	end

	if mw.ustring.match (args[1], 'utc[%+%-±−]%d%d:%d%d') then					-- if rendering time for a UTC offset timezone
		tz.abbr = args[1]:upper():gsub('%-', '−');								-- set the link label to upper case and replace hyphen with a minus character (U+2212)
		tz.article = tz.abbr;													-- article title same as abbreviation
		tz.utc_offset = mw.ustring.match (args[1], 'utc([%+%-±−]?%d%d:%d%d)'):gsub('−', '%-');	-- extract the offset value; replace minus character with hyphen
		local s, t = mw.ustring.match (tz.utc_offset, '(±)(%d%d:%d%d)');		-- ± only valid for offset 00:00
		if s and '00:00' ~= t then
			return error_msg ('bad_sign');
		end
		tz.df = 'iso';
		args[1] = 'utc_offsets';												-- spoof to show that we recognize this timezone
	else
		tz = tz_aliases[args[1]] and tz_data[tz_aliases[args[1]]] or tz_data[args[1]];	-- make a local copy of the timezone table from tz_data{}
		if not tz then
			return error_msg ('unknown_tz', args[1]);							-- if the timezone given isn't in module:time/data(/sandbox)
		end
	end

	DF = first_set (cfg.aliases['df'], args) or args[2] or tz.df or cfg.default_df;	-- template |df= overrides typical df from tz properties
	DF = DF:lower();															-- normalize to lower case
	if not cfg.df_vals[DF] then
		return error_msg ('bad_format', DF);
	end

	if is_set (args._TEST_TIME_) then											-- typically used to test the code at a specific utc time
		local test_time = get_test_time (args._TEST_TIME_);
		if not test_time then
			return error_msg ('test_time');
		end

		utc_timestamp = os.time(test_time);
	else
		utc_timestamp = os.time ();												-- get current server time (UTC)
	end
	utc_offset = get_utc_offset ();												-- utc offset for specified timezone in seconds
	timestamp = utc_timestamp + utc_offset;										-- make local time timestamp

	if 'always' == DST then														-- if needed to always display dst time
		timestamp = timestamp + 3600;											-- add a hour for dst
		tz_abbr = tz.dst_abbr;													-- dst abbreviation
	elseif not yesno(DST) then													-- for timezones that DO observe dst but for this location ...
		tz_abbr = tz.abbr;														-- ... dst is not observed (|dst=no) show time as standard time
	else
		if is_set (tz.dst_begins) and is_set (tz.dst_ends) and is_set (tz.dst_time) then	-- make sure we have all of the parts
			dst_begin_ts, dst_end_ts, invert = make_dst_timestamps (timestamp);	-- get begin and end dst timestamps and invert flag

			if nil == dst_begin_ts or nil == dst_end_ts then
				return error_msg ('bad_dst');
			end
	
			if invert then														-- southern hemisphere; use beginning and ending of standard time in the comparison
				if utc_timestamp >= dst_end_ts and utc_timestamp < dst_begin_ts then	-- is current date time standard time?
					tz_abbr = tz.abbr;											-- standard time abbreviation
				else		
					timestamp = timestamp + 3600;								-- add an hour
					tz_abbr = tz.dst_abbr;										-- dst abbreviation
				end
			else																-- northern hemisphere
				if utc_timestamp >= dst_begin_ts and utc_timestamp < dst_end_ts then	-- all timestamps are UTC
					timestamp = timestamp + 3600;								-- add an hour 
					tz_abbr = tz.dst_abbr;
				else
					tz_abbr = tz.abbr;
				end
			end
		elseif is_set (tz.dst_begins) or is_set (tz.dst_ends) or is_set (tz.dst_time) then	-- if some but not all not all parts then emit error message
			return error_msg ('bad_def', args[1]:upper());
		else
			tz_abbr = tz.abbr;													-- dst not observed for this timezone
		end
	end
	
	if Dateonly then
		if 'iso' == DF then														-- |df=iso
			DF = 'iso_date';
		elseif DF:find ('^dmy') or 'y' == DF then								-- |df=dmy, |df=dmy12, |df=dmy24, |df=y
			DF = 'dmy_date';
		else
			DF = 'mdy_date';													-- default
		end

	elseif Timeonly or DF:match ('^%d+$') then									-- time only of |df= is just digits
		DF = table.concat ({'t', DF:match ('%l*(12)') or '24'});				-- |df=12, |df=24, |df=dmy12, |df=dmy24, |df=mdy12, |df=mdy24; default to t24
		
	elseif 'y' == DF or 'dmy24' == DF then
		DF = 'dmy';

	elseif 'mdy24' == DF then
		DF = 'mdy';
	end
	
	local dformat;
	if is_set (DF_cust) then
		dformat=DF_cust;
	elseif is_set (DF_cust_a) then												-- custom format is am/pm sensitive?
		if 'am' == os.date ('%P', timestamp) then								-- if current time is am
			dformat = DF_cust_a;												-- use custom am format
		else
			dformat = DF_cust_p;												-- use custom pm format
		end
	else
		dformat = cfg.format[DF];												-- use format from tables or from |df=
	end

	time_string = frame:callParserFunction ({name='#time', args={dformat, '@'..timestamp, Lang}});
	if Lang then
		time_string = table.concat ({											-- bidirectional isolation of non-local language; yeah, rather brute force but simple
			'<bdi lang="',														-- start of opening bdi tag
			Lang,																-- insert rendered language code
			'">',																-- end of opening tag
			time_string,														-- insert the time string
			'</bdi>'															-- and close the tag
			});
	end

	if not is_set (tz.article) then												-- if some but not all not all parts then emit error message
		return error_msg ('bad_def', args[1]:upper());
	end
	
	local refresh_link = (Hide_refresh and '') or
		table.concat ({
			' <span class="plainlinks" style="font-size:85%;">[[',				-- open span
			mw.title.getCurrentTitle():fullUrl({action = 'purge'}),				-- add the a refresh link url
			' ',
			cfg['refresh-label'],												-- add the label
			']]</span>',														-- close the span
			});

	local tz_tag = (Hide_tz and '') or
		((Unlink_tz and table.concat ({' ', tz_abbr})) or						-- unlinked
			table.concat ({' [[', tz.article, '|', tz_abbr, ']]'}));			-- linked
	
	return table.concat ({time_string, tz_tag, refresh_link});

end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {time = time}