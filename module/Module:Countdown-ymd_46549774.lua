-- This module powers {{countdown-ymd}}.
require('Module:No globals')

local p = {}
local static_text = {
	['eventtime'] = 'Time to event:',
	['begins'] = 'Event begins in',												-- when |duration= is set
	['ends'] = 'Event ends in',													-- when |duration= is set
	['ended'] = 'Event has ended.',												-- when |duration= is set
	['passed'] = 'Event time has passed.',
	['invalid'] = '<span style="font-size:100%" class="error">Error: invalid date and/or time</span>',
	}

local getArgs = require('Module:Arguments').getArgs

--[[--------------------------< F O R M A T _ U N I T >--------------------------------------------------------

Concatenates a singular or plural label to a time/date unit: unit label or unit labels.  If unit is 0 or less, returns nil

]]

local function format_unit (unit, label)
	if 1 > unit then															-- less than one so don't display
		return nil;																-- return nil so the result of this call isn't stuffed into results table by table.insert
	elseif 1 == unit then
		return unit .. ' ' .. label;											-- only one unit so return singular label
	else
		return unit .. ' ' .. label .. 's';										-- multiple units so return plural label
	end
end


--[[--------------------------< D U R A T I O N >--------------------------------------------------------------

Returns duration of event in seconds.  If the units are not defined, assumes seconds.  If the units are
defined but not one of day, days, hour, hours, minute, minutes, second, seconds then returns zero.

|duration=<number><space><unit>

TODO: Why are we even considering seconds and minutes?  Would it be better to specify and end time?

]]

local function duration (duration)
	local number, unit = duration:match ('(%d+)%s+(%a*)');
	
	if not number then
		return 0;																-- duration not properly specified
	elseif not unit then
		return number;															-- unit not defined, assume seconds
	end
	
	if unit:match ('days?') then
		return number * 86400;
	elseif unit:match ('hours?') then
		return number * 3600;
	elseif unit:match ('minutes?') then
		return number * 60;
	elseif unit:match ('seconds?') then
		return number;
	else
		return 0;																-- unknown unit
	end
end

--[[--------------------------< U T C _ O F F S E T >----------------------------------------------------------

Returns offset from UTC in seconds.  If 'utc offset' parameter is out of range or malformed, returns 0.

TODO: Return a success/fail flag so we can emit an error message?

]]

local function utc_offset (offset)
	local sign, utc_offset_hr, utc_offset_min;
	
	if offset:match('^[%+%-]%d%d:%d%d$') then									-- formal style: sign, hours colon minutes all required
		sign, utc_offset_hr, utc_offset_min = offset:match('^([%+%-])(%d%d):(%d%d)$');
	elseif offset:match('^[%+%-]?%d?%d:?%d%d$') then							-- informal: sign and colon optional, 1- or 2-digit hours, and minutes 
		sign, utc_offset_hr, utc_offset_min = offset:match('^([%+%-]?)(%d?%d):?(%d%d)$');
	elseif offset:match('^[%+%-]?%d?%d$') then									-- informal: sign optional, 1- or 2-digit hours only
		sign, utc_offset_hr = offset:match('^([%+%-]?)(%d?%d)$');
		utc_offset_min = 0;														-- because not included in parameter, set it to 0 minutes
	else
		return 0;																-- malformed so return 0 seconds
	end
	
	utc_offset_hr = tonumber (utc_offset_hr);
	utc_offset_min = tonumber (utc_offset_min);
	
	if 12 < utc_offset_hr or 59 < utc_offset_min then							-- hour and minute range checks
		return 0;
	end
	
	if '-' == sign then
		sign = -1;																-- negative west offset
	else
		sign = 1;																-- + or sign omitted east offset
	end
	utc_offset_hr = sign * (utc_offset_hr * 3600);								-- utc offset hours * seconds/hour
	utc_offset_min = sign * (utc_offset_min * 60);								-- utc offset minutes * seconds/minute
	return utc_offset_hr + utc_offset_min;										-- return the UTC offset adjustment in seconds
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

--[[--------------------------< D I F F _ T I M E >------------------------------------------------------------

calculates the difference between two times; returns a table of the differences in diff.hour, diff.min, and diff.sec

]]

local function diff_time (a, b)
	local diff = {}
	diff.sec = a.sec - b. sec;
	if diff.sec < 0 then
		diff.sec = diff.sec + 60;												-- borrow from minutes
		a.min = a.min - 1;
		if a.min < 0 then
			a.min = a.min + 60;													-- borrow from hours
			a.hour = a.hour - 1;
		end
	end
	diff.min = a.min - b.min;
	if diff.min < 0 then
		diff.min = diff.min + 60;												-- borrow from hours
		a.hour = a.hour - 1;
	end
	diff.hour = a.hour - b.hour;
	return diff;
end

--[[--------------------------< D I F F _ D A T E >------------------------------------------------------------

calculates the difference between two dates; returns a table of the difference in diff.year, diff.month, and diff.day

]]

local function diff_date (a, b)
	local diff = {}
	diff.day = a.day - b.day;
	if diff.day < 0 then
		a.month = a.month - 1;
		if a.month < 1 then	
			a.year = a.year - 1;												-- borrow a month from years
			a.month = a.month + 12;
		end
		diff.day = diff.day + get_days_in_month (a.year, a.month);				-- borrow all of the days from the *previous* month
	end

	diff.month = a.month - b.month;
	if diff.month < 0 then
		a.year = a.year - 1;													-- borrow a month from years
		diff.month = diff.month + 12;
	end
	diff.year = a.year - b.year;
	return diff;
end

--[[--------------------------< I S _ V A L I D _ D A T E _ T I M E >------------------------------------------

Validate date/time.  Also, determine if we have all of the necessary date/time componants.  Minimal required
date/time is |year=.

For dates, these are required (all other variations emit an error message):
	|year= or
	|year= |month= or
	|year= |month= |day=
	
If time is included, these are required (all other variations emit an error message):
	|hour= or
	|hour= |minute= or
	|hour= |minute= |second=

]]

local function is_valid_date_time (year, month, day, hour, minute, second)
	if not year or (not month and day) then										-- must have YMD, YM, or Y
		return false;
	end

	year = tonumber (year);
	if not year or 1582 > year or 9999 < year then return false; end			-- must be four digits in gregorian calander
	
	if month then
		month = tonumber (month);
		if not month or 1 > month or 12 < month then return false; end			-- 1 to 12
	end
	if day then
		day = tonumber (day);
		if not day or 1 > day or get_days_in_month (year, month) < day then		-- 1 to 28, 29, 30, or 31 depending on month
			return false;
		end
	end

	if ((minute or second) and not hour) or (not minute and second) then		-- must have H:M:S or H:M or H or none at all
			return false;
	end
	
	if hour then
		hour = tonumber (hour);
		if not hour or 0 > hour or 23 < hour then return false; end				-- 0 to 23
	end
	if minute then
		minute = tonumber (minute);
		if not minute or 0 > minute or 59 < minute then return false; end		-- 0 to 59
	end
	if second then
		second = tonumber (second);
		if not second or 0 > second or 59 < second then return false; end		-- 0 to 59
	end
	
	return true;

end

--[[--------------------------< M A I N >----------------------------------------------------------------------

Supported parameters:
	date and time parameters:
		|year= (required), |month=, |day=
		|hour=, |minute=, |second=
		|utc offset=
		|duration=

	presentation parameters:
		|color=
		
	wrapping-text parameters:
		|event lead= – text ahead of countdown text while event is in progress; countdown text is time to end of event; default is static_text.ends
		|event tail= – text that follows countdown text while event is in progress; default is empty string
		|expired= - display text when event is in the past; default is static_text.passed; when |duration= is set then default is static_text.ended
		|lead= – text ahead of countdown text; default is static_text.begins; overridden by |event lead= while event is in progress;
		|tail= – text that follows countdown text; default is empty string; overridden by |event tail= while event is in progress

]]

function p.main(frame)
	local args = getArgs(frame)

	if false == is_valid_date_time (args.year, args.month, args.day, args.hour, args.minute, args.second) then	-- validate our inputs; minimal requirement is |year=
		return  static_text.invalid;
	end
																				-- convert event time parameters to seconds; use default January 1 @ 0h for defaults if not provided
	local event = os.time({year=args.year, month=args.month or 1, day=args.day or 1, hour=args.hour or 0, min=args.minute, sec=args.second});	-- convert to seconds
	if args['utc offset'] then
		event = event - utc_offset(args['utc offset']);							-- adjust event time to UTC from local time
	end
	
	if 'none' == args.expired then
		args.expired = '';
	end
	
	if event < os.time () then													-- if event time is in the past
		if not args.duration then
			return args.expired or static_text.passed;							-- if the event start time has passed, we're done
		else
			event = event + duration (args.duration);							-- calculate event ending time
			if event < os.time () then
				return args.expired or static_text.ended;						-- if the event start time + duration has passed, we're done
			end
		end
	else																		-- here when event has not yet started or occured
		if not args.lead then
			if args.duration then
				args.lead = static_text.begins;									-- default lead text when |duration= set but |lead= not set
			else
				args.lead = static_text.eventtime;								-- default lead text when |duration= and |lead= not set
			end
		end
		args.duration = nil;													-- event not yet started; unset so that we render text around the countdown correctly
	end
	
	local today = os.date ('*t');												--fetch table of current date time parameters from the server
	local event_time = os.date ('*t', event);									--fetch table of event date time parameters from the server
	local hms_til_start = diff_time (event_time, today)							-- table of time difference (future time - current time)
	if hms_til_start.hour < 0 then												-- will be negative if we need to borrow hours from day
		hms_til_start.hour = hms_til_start.hour + 24;							-- borrow a day's worth of hours from event start date
		event_time.day = event_time.day - 1;
	end

	local ymd_til_start = diff_date (event_time, today)							-- table of date difference (future date - current date)

	local result = {}															-- results table with some formatting; values less than one are not added to the table 
	table.insert (result, format_unit (ymd_til_start.year, 'year'));			-- add date parameters
	table.insert (result, format_unit (ymd_til_start.month, 'month'));
	table.insert (result, format_unit (ymd_til_start.day, 'day'));
	
	local count = #result;														-- zero if less than 24 hours to event; when less than 24 hours display all non-zero time units
	table.insert (result, format_unit (hms_til_start.hour, 'hour'));			-- always include hours if it is not zero
	if args.hour or 0 == count then												-- if event start hour provided in template, show non-zero minutes
		table.insert (result, format_unit (hms_til_start.min, 'minute'));
	end
	if (args.minute and args.hour) or 0 == count then							-- if event start hour and minute provided in template, show non-zero seconds
		table.insert (result, format_unit (hms_til_start.sec, 'second'));
	end
	
	result = table.concat (result, ', ');
	result = mw.ustring.gsub(result, '(%d+)', '<span style="color: ' .. (args.color or 'blue') .. '; font-weight: bold;">%1</span>')
	local refreshLink = mw.title.getCurrentTitle():fullUrl{action = 'purge'}
	refreshLink = mw.ustring.format(' <sup>[<span class="plainlinks">[%s refresh]</span>]</sup>', refreshLink)

	if not args.duration then													-- will be nil if event hasn't started yet or |duration= not specified
		args.lead = args.lead or static_text.eventtime;							-- use default begins text
	else
		args.lead = args['event lead'] or static_text.ends;						-- event has started use |event lead= text or default ends text
		args.tail = args['event tail'];											-- and use |event tail= text
	end

	if 'none' == args.lead then													-- here, if either arg.lead and args['event lead'] were set to keyword'none'
		args.lead = '';															-- set lead text to empty string
	elseif args.lead then
		args.lead = args.lead .. ' ';											-- add a space
	end

	if args.tail then
		args.tail = ' ' .. args.tail;											-- add a space
	else
		args.tail = '';															-- empty string for concatenation
	end
	
	return args.lead .. result .. args.tail .. refreshLink;
end

return p