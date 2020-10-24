require('Module:No globals');
local getArgs = require ('Module:Arguments').getArgs;
local lang = mw.language.getContentLanguage();									-- used for date formatting and validation
local namespace = mw.title.getCurrentTitle().namespace;							-- used for categorization

local master = mw.loadData("Module:IATA and ICAO code/data")
local IATA_airport = master.IATA
local ICAO_airport = master.ICAO
local wikilink_label = master.WikiName

local p = {}

function p.count(frame)
	local count = 0
		
	for i, v in ipairs(frame.args) do	
	count=count+1 end
	return count
end


--[[--------------------------< I S _ V A L I D _ D A T E >----------------------------------------------------

Dates must be real.  Returns true if date is a real date; false else.

Done this way because:
	mw.language.getContentLanguage():formatDate('Y-m-d', '2018-02-31') should return an error but instead returns
		2018-03-03

TODO: text for min/max years?

]]

local function is_valid_date (date)
local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};			-- number of days in each month
local month_length;
local year, month, day;

	year, month, day = date:match ('(%d%d%d%d)%-(%d%d)%-(%d%d)');				-- extract year, month, and day parts from date
	
	if (year < lang:formatDate ('Y', 'now')) or (year > lang:formatDate ('Y', 'now+2year')) then
		return false;
	end
	
	month = tonumber (month);
	if (1 > month) or (12 < month) then											-- check month
		return false;
	end
	
	if (2==month) then															-- if February
		month_length = 28;														-- then 28 days unless
		if (0==(year%4) and (0~=(year%100) or 0==(year%400))) then				-- a leap year
			month_length = 29;													-- in which case: 29 days in February
		end
	else
		month_length=days_in_month[month];										-- else month length from table
	end

	day = tonumber (day);
	if (1 > day) or ( month_length < day) then									-- check day
		return false;
	end
	return true;																-- good day
end


--[[-------------------------< M A K E _ D A T E _ T Y P E _ S T R I N G >------------------------------------

decodes begin, resume, end service date type and date stamps and returns human readable text.  Format is:
	<type><date> where:
		<type> is one of the three-character keywords:
			beg - new service begins
			res - service resumes after an interruption
			end - service ends
		<date> is a singe date or date-range similar in format to ISO 8601:
			YYYY-MM-DD - a single YMD date may be begin, resume, or end date
			YYYY-MM-DD/YYYY-MM-DD - a date range where the first date (left) is a start or resume date and the second (right) is an end date
	
returns nil and an error message if:
	type keyword is not recognized
	either date is invalid - dates must be real
	begin or resume date falls on or after end date - events must begin/resume before they end
	
event dates that have already occurred (today's date follows a begin/resume/end date) are quitely muted.  When this occurs
the function returns only an end date (if a date range and that event is still in the future).  The function will add a hidden category
to articles with muted begin/resume/end dates.

]]

local function make_date_type_string (date_type, date, date2, ref, df)
local result = {};
local cat = '';
local today = lang:formatDate ('Y-m-d', 'today');								-- system date in ymd format as a text string

	if not date_type or ('' == date_type) then									-- if not set then this code isn't dated
		return '', nil, '';														-- return empty string, no error message, empty string for category
	end

	if not is_valid_date (date) then											-- dates must be valid
		return nil, table.concat ({'invalid date: ', date});					-- return nil, an error message, category is nil but we don't care
	end

	if date2 then																-- if date is a range
		if 'end' == date_type then
			return nil, 'date range not allowed for keyword \'end\'';			-- :endYYYY-MM-DD/YYYY-MM-DD is nonsensical
		end
		
		if not is_valid_date (date2) then										-- dates must be valid
			return nil, table.concat ({'invalid date: ', date2});				-- return nil, an error message, category is nil but we don't care
		end

		if date >= date2 then													-- start/resume dates must precede end dates
			return nil, table.concat ({'invalid date order: ', date, '/', date2});	-- return nil, an error message, category is nil but we don't care
		end
	end

	if date < today then														-- if date has passed
		date = nil;																-- quietly hide expired dates
		cat = '[[Category:Expired airport code]]';								-- (but categorize)
	end

	if date2 then																-- if date is a range
		if date2 < today then													-- if date has passed
			date2 = nil;														-- quietly hide expired dates
			cat = '[[Category:Expired airport code]]';							-- (but categorize)
		end
	end

	date_type = date_type:lower();												-- make it case insensitive
	
	if 'beg' == date_type then
		if date then															-- date may be nil here because it has already passed
			table.insert (result, ' (begins ');									-- begin date is today or in the future
		elseif date2 then														-- here when date has passed and date timestamp was a range
			date = date2;														-- begin date is in the past so event has already happened; convert date2 to end
			date2 = nil;														-- unset
			table.insert (result, ' (ends ');									-- range end date is today or in the future
		end
	elseif 'res' == date_type then
		if date then
			table.insert (result, ' (resumes ');								-- resume date is today or in the future
		elseif date2 then
			date = date2;														-- resume date is in the past so event has already happened; convert date2 to end
			date2 = nil;														-- unset
			table.insert (result, ' (ends ');									-- range end date is today or in the future
		end
	elseif 'end' == date_type then
		if date then
			table.insert (result, ' (ends ');									-- end date is today or in the future
		else
			return nil;															-- date has expired for an end date type; return nil as flag to hide this destination
		end
	else
		return nil, table.concat ({'unexpected date type: ', date_type});		-- return nil, an error message, category is nil but we don't care
	end

	if date then																-- define formatting strings for lang:formatDate()
		if 'dmy' == df then
			df = 'j F Y';
		elseif 'mdy' == df then
			df = 'F j, Y';
		else
			df = 'Y-m-d';														-- yeah, sort of pointless, but simple
		end
		
		table.insert (result, lang:formatDate (df, date));						-- reformat ymd to selected format according to |df=
		
		if date2 then
			table.insert (result, '; ends ');									-- date2 always an end event
			table.insert (result, lang:formatDate (df, date2));					-- reformat ymd to selected format according to |df=
		end
	end

	if 0 ~= namespace then
		cat = ''																-- categorize articles in mainspace only
	end

	if 0 ~= #result then														-- when there is date text, 
		table.insert (result, ref);												-- reference goes just before we ...
		table.insert (result, ')');												-- ... close the date text
		return table.concat (result), nil, cat;									-- return formatted date string, no error message, and category (if mainspace)
	else
		return '', nil, cat;													-- return empty string for concatenation, no error message, and category (if mainspace)
	end
	
end


--[=[-------------------------< C O M P >---------------------------------------------------------------------

Comparison funtion for table.sort() compares wikilink labels

	[[wikilink target|wikilink label]]

]=]

local function comp (a, b)
local a_label = a:match ('^[^|]+|([^%]]+)%]%]'):lower();						-- extract the label from a
local b_label = b:match ('^[^|]+|([^%]]+)%]%]'):lower();						-- extract the label from b
	return a_label < b_label;
end


--[=[--------------------------< M A I N >--------------------------------------------------------------------

returns a wikilink to the en.wiki article that matches the IATA or ICAO code provided in the call
example of data:
	{'North America','USA','ABE','KABE','Lehigh Valley International Airport','Allentown/Bethlehem'},
	
{{#invoke:IATA and ICAO code|main|ABE}} returns
	[[Lehigh Valley International Airport|Allentown/Bethlehem]]
	or an error message

When there are multiple codes, returns comma separated, alpha ascending list of wikilinks or an error message.

]=]

function p.main(frame)
local args = getArgs(frame);
local results = {};
local code;
local date_type;
local date, date2;
local message;
local ref = '';
local cat = '';

	for _, value in ipairs (args) do
		value = mw.text.trim (value);
		if value:match ('^(%a%a%a%a?) *: *(%a%a%a) *(%d%d%d%d%-%d%d%-%d%d) */ *(%d%d%d%d%-%d%d%-%d%d) *(.*)') then
			code, date_type, date, date2, ref = value:match ('^(%a%a%a%a?) *: *(%a%a%a) *(%d%d%d%d%-%d%d%-%d%d) */ *(%d%d%d%d%-%d%d%-%d%d) *(.*)');
		elseif value:match ('^(%a%a%a%a?) *: *(%a%a%a) *(%d%d%d%d%-%d%d%-%d%d) *(.*)') then
			code, date_type, date, ref = value:match ('^(%a%a%a%a?) *: *(%a%a%a) *(%d%d%d%d%-%d%d%-%d%d) *(.*)');
		elseif value:match ('^%a%a%a%a?$') then
			code = value:match ('^%a%a%a%a?$');
		else
			return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: malformed parameter value: ', value, '</span>'});
		end

		ref = mw.text.trim (ref);												-- remove extraneous white space; if ref is only white space, makes empty string
		if '' ~= ref then
			if not ref:match ('^\127[^\127]*UNIQ%-%-ref%-%x+%-QINU[^\127]*\127') then
				return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: extraneous reference text: ', ref, '</span>'});
			end
		end

		date_type, message, cat = make_date_type_string (date_type, date, date2, ref, args.df);
		
		if message then															-- if an error message, abandon
			return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: ', message, '</span>'});
		end
		
		if date_type then														-- nil when end date type has expired
			code = code:upper();													-- force code to uppercase
	
			if IATA_airport[code] then
				table.insert (results, table.concat ({'[[', IATA_airport[code], '|', wikilink_label[code], ']]', date_type, cat}))	-- make wikilink from iata code
			elseif ICAO_airport[code] then
				table.insert (results, table.concat ({'[[', ICAO_airport[code], '|', wikilink_label[code], ']]', date_type, cat}))	-- make wikilink from icao code
			else
				return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: data missing for code: ', code, '</span>'});
			end
		end		
		date_type = nil;														-- clear so we can reuse these
		date = nil;
		date2 = nil;
		ref = '';
	end
	
	table.sort (results, comp);													-- sort in ascending alpha order
	
	local i = 1;
	while i<#results do															-- check for and remove duplicates
		if results[i] == results[i+1] then										-- compare
			table.remove (results, i);											-- remove the duplicate at results[i]; do not bump i
		else
			i = i + 1;															-- not the same so bump i
		end
	end
	
	return table.concat (results, ', ');										-- make a comma separated list
end


--[[--------------------------< D U P L I C A T E _ C H E C K >------------------------------------------------

This function looks at IATA and ICAO code in Module:IATA and ICAO code/data.  It attempts to locate invalid (by
length) codes and attempts to detect duplicate codes.

  1               2     3     4
{'North America','USA','ABE','KABE','Lehigh Valley International Airport','Allentown/Bethlehem'},

]]

function p.duplicate_check ()
	local iata_count_table = {};
	local icao_count_table = {};

	local _master = master._master

	local iata = {}
	local icao = {}

	for i, v in ipairs(_master) do												-- create tables from master
		if '' ~= v[3] then														-- iata codes TODO: length checking
			if not iata[v[3]] then
				iata[v[3]] = 1;													-- state that this is the first time we've seen this code
			else
				iata[v[3]] = iata[v[3]] + 1;									-- bump the count for this code
			end
		end
		if '' ~= v[4] then														-- iaco codes TODO: length checking
			if not icao[v[4]] then
				icao[v[4]] = 1;													-- state that this is the first time we've seen this code
			else
				icao[v[4]] = icao[v[4]] + 1;									-- bump the count for this code
			end
		end
	end
	
	for k, v in pairs (iata) do
		if 1 < v then
			table.insert (iata_count_table, table.concat ({k, ' (', v, '×)'}))
		end
	end

	for k, v in pairs (icao) do
		if 1 < v then
			table.insert (icao_count_table, table.concat ({k, ' (', v, '×)'}))
		end
	end
	
	local iata_msg = '';														-- error messages go here
	local icao_msg = '';

	if 0 ~= #iata_count_table then
		iata_msg = table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: more than one IATA code:<br />	', table.concat (iata_count_table, ', '), '</span>'})
	end
	if 0 ~= #icao_count_table then
		icao_msg = table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: more than one ICAO code:<br />	', table.concat (icao_count_table, ', '), '</span>'})
	end
	
	if (0 ~= #iata_count_table) or (0 ~= #icao_count_table) then				-- TODO find a better way of doing this
		return table.concat ({iata_msg, '<br /><br />', icao_msg})
	end
	return 'ok';
end

return p