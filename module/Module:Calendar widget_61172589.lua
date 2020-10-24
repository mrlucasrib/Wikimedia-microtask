--[[
Module to create Calendar widget

--]]
require('Module:No globals');
local getArgs = require ('Module:Arguments').getArgs;

local lang_obj = mw.language.getContentLanguage();

local daysinmonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
local dayname = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'}
local dayabbr = {}
for i, v in ipairs(dayname) do
	dayabbr[i] = v:sub(1, 2)
end

local iso_dayname = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'}
local iso_dayabbr = {}
for i, v in ipairs(iso_dayname) do
	iso_dayabbr[i] = v:sub(1, 2)
end

local monthname = {}
local monthabbr = {}
if 0 == #monthname then
	for m = 1, 12 do
		monthname[m] = lang_obj:formatDate ("F", '2019-' .. m);					-- table of long month names
		monthabbr[m] = lang_obj:formatDate ("M", '2019-' .. m);					-- table of abbreviated month names
	end
end


--[[--------------------------< I S _ L E A P >----------------------------------------------------------------

returns true when <year> is a leapyear

]]

local function is_leap (year)
	return '1' == lang_obj:formatDate ('L', tostring(year));
end


--[[--------------------------< D A Y _ O F _ W E E K >--------------------------------------------------------

returns 1 to 7; 1 == Sunday; 1 == Monday when iso true

]]

local function day_of_week (year, month, day, iso)
	return
		iso and lang_obj:formatDate ('N', year .. '-' .. month .. '-' .. day) or	-- ISO: 1 = monday
		lang_obj:formatDate ('w', year .. '-' .. month .. '-' .. day) + 1;			-- 1 = sunday
end


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Returns true if argument is set; false otherwise. Argument is 'set' when it exists (not nil) or when it is not an empty string.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[=[-------------------------< M A K E _ W I K I L I N K >----------------------------------------------------

Makes a wikilink; when both link and display text is provided, returns a wikilink in the form [[L|D]]; if only
link is provided, returns a wikilink in the form [[L]]; if neither are provided or link is omitted, returns an
empty string.

]=]

local function make_wikilink (link, display)
	if is_set (link) then
		if is_set (display) then
			return table.concat ({'[[', link, '|', display, ']]'});
		else
			return table.concat ({'[[', link, ']]'});
		end
	else
		return '';
	end
end


--[[--------------------------< G E T _ D I S P L A Y _ Y E A R >----------------------------------------------

returns year from props with prefixed and suffixed wikilink if appropriate; this function used for both yearly
and stand-alone calendars

]]

local function get_display_year (props)
	local year_text = props.year;
	local lk_prefix = props.lk_pref_y or props.lk_pref;
	local lk_suffix = props.lk_suff_y or props.lk_suff;

	if props.lk_y then															-- if to be linked
		if lk_prefix or lk_suffix then											-- when prefix or suffix, [[prefix .. link .. suffix|label]]
			year_text = make_wikilink ((lk_prefix or '') .. year_text .. (lk_suffix or ''), year_text);
		else
			year_text = make_wikilink (year_text);								-- just year
		end
	end
	
	return year_text;
end


--[[--------------------------< G E T _ D I S P L A Y _ M O N T H >--------------------------------------------

returns month from argument or props with wikilink, prefix, suffix ...

argument mnum is nil when rendering stand-alone calendar

]]

local function get_display_month (mnum, props)
	local month_text = mnum or props.month_num;
	month_text = monthname[month_text];

	local lk_prefix = props.lk_pref_m or props.lk_pref;
	local lk_suffix = props.lk_suff_m or props.lk_suff;

	if props['lk_m&y'] then														-- stand-alone month calendars only
		month_text = month_text .. ' ' .. props.year;							-- composite month and year link
	end

	if props.lk_m or props['lk_m&y'] then
		if lk_prefix or lk_suffix then											-- when prefix or suffix, [[prefix .. link .. suffix|label]]
			month_text = make_wikilink ((lk_prefix or '') .. month_text .. (lk_suffix or ''), month_text);
		else
			month_text = make_wikilink (month_text);							-- just month name or composite month/year
		end
	end
	
	return month_text;
end


--[[--------------------------< G E T _ D I S P L A Y _ D A Y >------------------------------------------------

returns day with wikilink (month and day), link prefix, link suffix ... (text doesn't get prefix / suffix)

]]

local function get_display_day (day_text, mnum, props)
	local lk_prefix = props.lk_pref_d or props.lk_pref;
	local lk_suffix = props.lk_suff_d or props.lk_suff;

	if props.lk_d then
		local link_text = (lk_prefix or '') .. monthname[mnum] .. ' ' .. day_text .. (lk_suffix or '');
		day_text = make_wikilink (link_text, day_text);
	end
	
	return day_text;
end


--[[--------------------------< R E P E A T _ T A G S >--------------------------------------------------------

create <tag> ... </tag>... string to be included into another tag as :wikitext(...)

items is a table of items, each of which will be wrapped in <tag>...</tag>
options is a table of optional class, css, and attribute settings for these tags
	options.attr is a table of attribute / value pairs: {['attribute'] = 'value', ...}
	options.css is a table of attribute / value pairs: {['attribute'] = 'value', ...}

]]

local function repeat_tags (tag, items, options)
	local tags = {};															-- table of <tag>...</tag> tag strings
	local opt_attr = options.attr or {};										-- if options not supplied, use empty table
	local css_opts = options.css or {};
	
	for i, item in ipairs (items) do
		local repeat_tag = mw.html.create (tag);								-- new td object
		repeat_tag
			:addClass (options.class)
			:attr (opt_attr)
			:css (css_opts)
			:wikitext (item)													-- the item to be wrapped in <tag>...</tag>
			:done()																-- close <td>
		table.insert (tags, tostring (repeat_tag));								-- make a string of this object
	end

	return table.concat (tags);													-- concatenate them all together
end


--[[--------------------------< G E T _ R O W _ D A T E S >----------------------------------------------------

gets a week (row) of calendar dates each in its own <td>...</td>; inserts iso week number <td> tag ahead of column 1
when props.iso_wk true.

]]

local function get_row_dates (firstday, mnum, row, props)
	local options = {['class']='mcal'};											-- table of otions for these td tags
	local td_items = {};														-- table of <td>...</td> tag strings
	local result = {};
	local hilite;
	
	for col = 1, 7 do
		local dom = 7 * (row-1) + col + 1 - firstday							-- calculate day of month for row/col position
		local day;
		
		if props.iso_wk and 1 == col then										-- when column 1, insert iso week number <td> ahead of first 'dom'
			local iso_wk = lang_obj:formatDate ('W', props.year .. '-' .. mnum .. '-' .. ((1 > dom) and 1 or dom));
			local css_opts = props.wknum_color and {['background'] = props.wknum_color} or {};
			
			table.insert (result, repeat_tags ('td', {iso_wk}, {['class']='mcal_iso', ['css'] = css_opts}));
		end
		
		if dom < 1 or dom > daysinmonth[mnum] then
			day = "&nbsp;"														-- before or after month, blank cell
		else
			day = get_display_day (dom, mnum, props);							-- make wikilinks from month and day if required
		end

		if props.today then														-- highlight today's date when displayed
			if (props.year == props.this_ynum) and (mnum == props.this_mnum) and  (dom == props.this_dnum) then
				hilite = col;
			end
		end
		
		table.insert (td_items, day);
	end

	for i, td_item in ipairs (td_items) do
		if i == hilite then
			table.insert (result, repeat_tags ('td', {td_item}, {['class']='mcal', ['css'] = {['background-color'] = props.today_color or '#cfc'}}));
		else
			table.insert (result, repeat_tags ('td', {td_item}, options));
		end
	end

	return table.concat (result);
end


--[[--------------------------< G E T _ W E E K _ D A Y _ H D R >----------------------------------------------

create header row of day-of-week abbreviations with title attributes

]]

local function get_week_day_hdr (props)
	local headers = {};
	local css_opts = props.week_color and {['background'] = props.week_color} or {}

	if props.iso_wk then
		table.insert (headers, repeat_tags ('th', {'Wk'}, {['class']='mcal', ['attr']={['title'] = 'ISO week number'}, ['css'] = css_opts}));			-- iso week header
		for i, abbr in ipairs (iso_dayabbr) do
			table.insert (headers, repeat_tags ('th', {iso_dayabbr[i]}, {['class']='mcal', ['attr']={['title'] = iso_dayname[i]}, ['css'] = css_opts}));
		end
	else
		for i, abbr in ipairs (dayabbr) do
			table.insert (headers, repeat_tags ('th', {dayabbr[i]}, {['class']='mcal', ['attr']={['title'] = dayname[i]}, ['css'] = css_opts}));
		end
	end

	return table.concat (headers);
end


--[[--------------------------< G E T _ M O N T H _ H D R >----------------------------------------------------

create main header row for month calendars, with or without year and with or without previous / next links

]]

local function get_month_hdr (mnum, props)
	local result = {};
	local prev = '';
	local next = '';
	local hdr_year = '';
	local col_span = (props.iso_wk and 8) or 7;									-- assume no prev/next

	if not props.hide_year and props.month_num then								-- props.month_num has value only for stand-alone month calendars
		hdr_year = get_display_year (props);									-- if to be shown, add wikilink, etc when required
	end

	if props.prevnext then
		prev = monthname[(0 < mnum-1) and mnum-1 or 12];
		next = monthname[(13 > mnum+1) and mnum+1 or 1];

		if is_set (hdr_year) then
			prev = prev .. ' ' .. ((0 < mnum-1) and hdr_year or hdr_year-1);	-- january-1 = december previous year
			next = next .. ' ' .. ((13 > mnum+1) and hdr_year or hdr_year+1);	-- december+1 = january next year
		end
		
		local link_text = (props.lk_pref_mprev or '') .. prev .. (props.lk_suff_mprev or '')
		prev = make_wikilink (link_text, '<<');
		
		link_text = (props.lk_pref_mnext or '') .. next .. (props.lk_suff_mnext or '')
		next = make_wikilink (link_text, '>>');

		table.insert (result, repeat_tags ('td', {prev}, {['css']={['text-align']='center'}}));	-- insert prev now, insert next later
		col_span = col_span - 2;												-- narrow the month year <th>
	end

	if props['lk_m&y'] then														-- for composite links
		table.insert (result, repeat_tags ('th', {get_display_month (mnum, props)}, {['class']='mcal', ['attr']={['colspan']=col_span}}));
	else
		table.insert (result, repeat_tags ('th', {get_display_month (mnum, props) .. ' ' .. hdr_year}, {['class']='mcal', ['attr']={['colspan']=col_span}}));
	end

	if props.prevnext then
		table.insert (result, repeat_tags ('td', {next}, {['css']={['text-align']='center'}}));
	end

	return table.concat (result);
end


--[[--------------------------< D I S P L A Y M O N T H >------------------------------------------------------

generate the html to display a month calendar

]]

local function display_month (mnum, props)
	if props.leap then daysinmonth[2] = 29 end
	local firstday = day_of_week (props.year, mnum, 1, props.iso);				-- get first day number of the first day of the month; 1 == Sunday

	local table_css = {};
	if props.m_center then
		table_css = {															-- TODO: make a separate class in styles.css?
			['clear'] = 'both',
			['margin-left'] = 'auto',
			['margin-right'] = 'auto',
			}
	end
	
	if props.month_num then														-- month_num only set when doing stand-alone month calendars
		table_css.border = '1px solid grey';									-- put this is styles.css as a separate class?
	end
	
	local month_cal = mw.html.create ('table');
	month_cal
		:addClass ('mcal' .. (props.m_float_r and ' floatright' or ''))			-- float table right; leading space required to separate classes
		:css (table_css)
		:tag ('tr')																-- for month name header
			:addClass ('mcalhdr')
			:css (props.title_color and {['background'] = props.title_color} or {})
			:wikitext (get_month_hdr (mnum, props))
			:done()																-- close <tr>
		:tag ('tr')																-- for weekday header
			:addClass ('mcalhdr')
			:wikitext (get_week_day_hdr (props))
			:done()																-- close <tr>

	local numrows = math.ceil ((firstday + daysinmonth[mnum] - 1) / 7);			-- calculate number of rows needed for this calendar
	for row = 1, numrows do
		month_cal
			:tag ('tr')															-- for this week
			:addClass ('mcal')
			:wikitext (get_row_dates (firstday, mnum, row, props));				-- get dates for this week
	end
	month_cal:done()															-- close <table>
--mw.log (tostring (month_cal))
	return tostring (month_cal)
end


--[[--------------------------< G E T _ R O W _ C A L E N D A R S >--------------------------------------------

create <td> ... </td>... string to be included into <tr>...</tr> as :wikitext(...)

]]

local function get_row_calendars (cols, row_num, props)
	local mnum;																	-- month number
	local options = {['class']='ycal'};											-- table of otions for these td tags
	local td_items = {};														-- table of <td>...</td> tag strings
	
	for col_num = 1, cols do
		mnum = cols * (row_num - 1) + col_num									-- calculate month number from row and column values
		if mnum < 13 then														-- some sort of error return if ever 13+?
			table.insert (td_items, display_month (mnum, props));				-- get a calendar for month number mnum
		end
	end

	return repeat_tags ('td', td_items, options)
end


--[[--------------------------< G E T _ Y E A R _ H E A D E R >------------------------------------------------

create html header for yearly calendar;

]]

local function get_year_header (props)
	local css_opts = {};
	
	if props.hide_year then														-- for accesibility, when |hide_year=yes
		css_opts['display'] = 'none';											-- use css to hide the year header (but not when |title= has a value)
	end
	
	local header = mw.html.create('tr');
		header
			:addClass ('ycalhdr')
			:tag ('th')
				:addClass ('ycal')
				:css(css_opts)
				:attr ('colspan', props.cols)
				:wikitext (props.title or get_display_year (props));				-- 
	return tostring (header)
end


--[[--------------------------< D I S P L A Y _ Y E A R >------------------------------------------------------

create a twelve-month calendar; default is 4 columns × 3 rows

]]

local function display_year(props)
	local year = props.year
	local cols = props.cols
	local rows = math.ceil (12 / cols);
	local mnum;
	
	local year_cal = mw.html.create('table');
	year_cal
		:addClass ('ycal' .. (props.y_float_r and ' floatright' or ''))			-- float table right; leading space required to separate classes
		:css (props.y_center and {['clear'] = 'both', ['margin-left'] = 'auto', ['margin-right'] = 'auto'} or {})	-- centers table; TODO: add to styles.css?
		:wikitext (get_year_header(props));										-- get year header if not hidden

	for row_num = 1, rows do
		year_cal
			:tag('tr')
			:addClass ('ycal')
			:wikitext(get_row_calendars (cols, row_num, props))					-- get calendars for this row each wrapped in <td>...</td> tags as wikitext for this <tr>...</tr>
	end
	year_cal:done()																-- close <table>
--mw.log (tostring (year_cal))
	return tostring (year_cal)
end


--[[--------------------------< _ C A L E N D A R >------------------------------------------------------------

module entry point.  args is the parent frame args table

]]

local function _calendar (args)
	local props = {};															-- separate calendar properties table to preserve arguments as originally provided
	local this_year_num = tonumber (lang_obj:formatDate ('Y'));
	local this_month_num = tonumber (lang_obj:formatDate ('n'));

	props.this_ynum = this_year_num;											-- for highlighting 'today' in a calendar display
	props.this_mnum = this_month_num;
	props.this_dnum = tonumber (lang_obj:formatDate ('j'));

	props.year = args.year and tonumber(args.year) or this_year_num;
	if (1583 > props.year) or (1582 == props.year and 10 > props.month_num) then	-- gregorian calendar only (1583 for yearly calendar because gregorian started in October of 1582)
		props.year = this_year_num;												-- so use this year
	end

	props.leap = is_leap (props.year)
	
	props.title = args.title;													-- year calendar title

	props.cols = tonumber(args.cols or 4);										-- yearly calendar number of columns
	if 1 > props.cols or 12 < props.cols then
		props.cols = 4;
	end
	
	if args.month then
		local mnum = tonumber(args.month)
		if not mnum then														-- month provided as some sort of text string
			if args.month == "current" then
				props.month_num = this_month_num
				props.year = this_year_num
			elseif args.month == "last" then
				mnum = this_month_num - 1
				if mnum == 0 then
					props.month_num = 12										-- december last year
					props.year = this_year_num - 1								-- last year
				else
					props.month_num = mnum;										-- previous month
				end
			elseif args.month == "next" then
				mnum = this_month_num + 1
				if mnum == 13 then
					props.month_num = 1											-- january next year
					props.year = this_year_num + 1								-- next year
				else
					props.month_num = mnum;										-- next month
				end
			else
				local good
				good, props.month_num = pcall (lang_obj.formatDate, lang_obj, 'n', args.month);
				
				if not good then
					props.month_num = this_month_num
				else
					props.month_num = tonumber (props.month_num)
				end
			end
		else
			props.month_num =  (13 > mnum and 0 < mnum) and mnum or this_month_num;	-- month provided as a number
		end

		props.prevnext = 'yes' == (args.prevnext and args.prevnext:lower());	-- show previous / next links in month header only in single month calendars

		if args.lk_pref_mprev or args.lk_suff_mprev then
			props.lk_pref_mprev = args.lk_pref_mprev;
			props.lk_suff_mprev = args.lk_suff_mprev;
			props.prevnext = true;
		end

		if args.lk_pref_mnext or args.lk_suff_mnext then
			props.lk_pref_mnext = args.lk_pref_mnext;
			props.lk_suff_mnext = args.lk_suff_mnext;
			props.prevnext = true;
		end

		props.m_center = 'center' == (args.float and args.float:lower());		-- month calendar positions; default is left
		props.m_float_r = 'right' == (args.float and args.float:lower());
	end
	
	props.iso_wk = 'yes' == (args.iso_wk and args.iso_wk:lower());				-- show iso format with week numbers when true
	props.iso = 'yes' == (args.iso and args.iso:lower()) or props.iso_wk;		-- iso format without week number unless props.iso_wk true; always true when props.iso_wk true
	
	args.lk = args.lk and args.lk:lower();
	if args.lk and ({['yes']=1, ['m&y']=1, ['dm&y']=1, ['dm']=1, ['my']=1, ['dy']=1, ['d']=1, ['m']=1, ['y']=1})[args.lk] then	-- if valid keywords
		if 'yes' == args.lk then												-- all date components are individually linked
			props.lk_d = true;
			props.lk_m = true;
			props.lk_y = true;
		elseif 'm&y' == args.lk and props.month_num then						-- stand-alone month calendars only; month and year as a single composite link
			props['lk_m&y'] = true;
		elseif 'dm&y' == args.lk and props.month_num then						-- stand-alone month calendars only; month and year as a single composite link
			props['lk_m&y'] = true;
			props.lk_d = true;
		else
			props.lk_d = 'd' == args.lk:match ('d');							-- decode the keywords to know which components are to be linked
			props.lk_m = 'm' == args.lk:match ('m');
			props.lk_y = 'y' == args.lk:match ('y');
		end
	end

	if not (props.title or props.lk_y or props['lk_m&y']) then
		props.hide_year = ('yes' == args.hide_year) or ('off' == args.show_year);	-- year normally displayed; this hides year display but not when linked or replaced with title
	end

	props.lk_pref = args.lk_pref;												-- prefix for all links except previous and next
	props.lk_suff = args.lk_suff;												-- suffix for all links except previous and next

	for _, v in ipairs ({'y', 'm', 'd'}) do										-- loop through calendar parts for link prefix and suffix parameters
		props['lk_pref_' .. v] = args['lk_pref_' .. v] or args.lk_pref;			-- set prefix values
		props['lk_suff_' .. v] = args['lk_suff_' .. v] or args.lk_suff;			-- set suffix values
		if props['lk_pref_' .. v] or props['lk_suff_' .. v] then				-- set the calendar link flags as necessary
			props['lk_' .. v] = true;
		end
	end
	
	if not (props.m_center or props.m_float_r) then								-- these may aleady be set for stand-alone month calendar
		props.y_center = 'center' == (args.float and args.float:lower());
		props.y_float_r = 'right' == (args.float and args.float:lower());
	end

	props.today = 'yes' == (args.show_today and args.show_today:lower());		-- highlight today's date in calendars where it is displayed
	props.today_color = args.today_color or args.today_colour;
	
	props.title_color = args.title_color or args.title_colour or args.color or args.colour;
	props.week_color = args.week_color or args.week_colour or args.color or args.colour;
	props.wknum_color = args.wknum_color or args.wknum_colour;
	
-- TODO: add all other args{} from template or invoke to props{} modified as appropriate

	if props.month_num then														-- set only when rendering stand-alone month calendar
		return display_month (props.month_num, props);
	else
		return display_year (props);
	end
end


--[[--------------------------< C A L E N D A R >--------------------------------------------------------------

template entry point.  All parameters are template parameters; there are no special invoke parameters

]]

local function calendar (frame)
	local args=getArgs (frame);
	return _calendar (args);
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	calendar = calendar,
	}