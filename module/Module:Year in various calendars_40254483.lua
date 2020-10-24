-- Load dependencies.
local getArgs = require('Module:Arguments').getArgs
local numToRoman = require( 'Module:Roman' ).main
local getOlympiad = require( 'Module:Ancient Olympiads' )._main
local getDynasty = require( 'Module:Ancient Egypt era' )._main
local getPharaoh = require( 'Module:Ancient Egypt kings' )._main
local numToArmenian = require( 'Module:Armenian' ).main
local getRegnal = require( 'Module:British regnal year' ).main
local japaneseEra = require( 'Module:Japanese calendar' ).era()

-- Define constants.
local lang = mw.language.getContentLanguage()
local currentYear = tonumber( lang:formatDate( 'Y' ) )

--------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------

local function isInteger( num )
	-- Checks if a value is an integer. If so, returns the value converted to a number.
	-- If not, returns false.
	num = tonumber( num )
	if num and math.floor( num ) == num and num ~= math.huge then
		return num
	else
		return false
	end
end

local function BCToNum( s )
	-- Converts strings of the format "n BC" to their corresponding
	-- numerical values.
	if type( s ) ~= 'string' then
		return nil
	end
	s = mw.ustring.match( mw.ustring.upper( s ), '^([1-9]%d*)%s*BC$' )
	if not s then
		return nil
	end
	local num = tonumber( s )
	num = ( num - 1 ) * -1
	return num
end

local function numToBC( num )
	-- For BC years, returns a string with the year name appended with " BC".
	-- Otherwise returns nil.
	num = isInteger( num )
	if not num then return end
	if num <= 0 then
		return string.format( '%d BC', 1 - num )
	end
end

local function ADToNum( s )
	-- Converts strings of the format "AD n"
	-- to their corresponding numerical values.
	if type( s ) ~= 'string' then
		return nil
	end
	s = mw.ustring.match( mw.ustring.upper( s ), '^AD%s*([1-9]%d*)$' )
	if not s then
		return nil
	end
	local num = tonumber( s )
	return num
end

local function numToAD( num )
	-- For AD years up to 100, returns a string with the year name prepended with "AD ".
	-- Otherwise returns nil.
	num = isInteger( num )
	if not num then return end
	if (num <= 100) then
		return string.format( 'AD %d', num )
	end
end

local function formatNegative(s)
	-- Replaces hyphens in a string with minus signs if the hyphen comes before a number.
	s = mw.ustring.gsub( s, '%-(%d)', '−%1' )
	return s
end

--------------------------------------------------------------------
-- Calendar box class definition
--------------------------------------------------------------------

local calendarBox = {}
calendarBox.__index = calendarBox

function calendarBox:new( init )
	init = type( init ) == 'table' and init or {}
	local obj = {}
	local pagename = mw.title.getCurrentTitle().text

	-- Set the year. If the year is specified as an argument, use that.
	-- Otherwise, use the page name if it is valid. If the pagename isn't
	-- valid, use the current year.
	local yearNum = isInteger( init.year )
	local yearBC = BCToNum( init.year )
	local yearAD = ADToNum( init.year )
	local pageNum = isInteger( pagename )
	local pageBC = BCToNum( pagename )
	local pageAD = ADToNum( pagename )
	if yearNum then -- First, see if the year parameter is a number.
		self.year = yearNum
	elseif yearBC then -- Second, see if the year parameter is a "yyyy BC" string.
		self.year = yearBC
	elseif yearAD then -- Third, see if the year parameter is an AD/CE/year string.
		self.year = yearAD
	elseif pageNum then -- Fourth, see if the pagename is an integer.
		self.year = pageNum
	elseif pageBC then -- Fifth, see if the pagename is a "yyyy BC" string.
		self.year = pageBC
	elseif pageAD then -- Sixth, see if the pagename is an AD/CE/year string.
		self.year = pageAD
	else
		self.year = currentYear -- If none of the above apply, use the current year.
	end

	-- Set year text values.
	self.BCYearName = numToBC( self.year )
	self.ADYearName = numToAD( self.year )
	if self.BCYearName then
		self.yearText = self.BCYearName
	elseif self.ADYearName then
		self.yearText = self.ADYearName
	else
		self.yearText = tostring( self.year )
	end

	-- Set other fields.
	self.caption = self.yearText
	self.footnotes = init.footnotes

	return setmetatable( obj, {
			__index = self
		})
end

function calendarBox:setCaption( s )
	-- Sets the calendar box caption.
	if type( s ) ~= 'string' or s == '' then return end
	self.caption = s
end

function calendarBox:addCalendar( obj )
	-- Adds a calendar or a calendar group.
	if type( obj ) ~= 'table' and type( obj.new ) ~= 'function' then return end -- Exit if the object is invalid.
	self.calendars = self.calendars or {}
	table.insert( self.calendars, obj )
end

-- Add an alias for adding calendar groups. The function is the same, but it might be confusing for users
-- to have to use the name "addCalendar" for a calendar group.
calendarBox.addCalendarGroup = calendarBox.addCalendar

function calendarBox:export()
	-- Outputs the calendar box wikitext.
	local root = mw.html.create( 'table' )
	-- Export the calendar box headers.
	root
	:addClass( 'infobox vevent' )
	:css( 'width', '22em' )
	:tag( 'caption' )
	:css( 'font-size', '125%' )
	:tag( 'span' )
	:addClass( 'summary dtstart' )
	:wikitext( self.caption )

	-- Export the calendars and calendar groups. "calendar:export()" works for both kinds
	-- of objects. Some export functions can return nil, so we need to check for that.
	if type( self.calendars ) == 'table' then
		for _, calendar in ipairs( self.calendars ) do
			local calendarText = calendar:export()
			if type( calendarText ) == 'string' then
				root:wikitext( calendarText )
			end
		end
	end

	-- Add footnotes.
	if type( self.footnotes ) == 'string' and self.footnotes ~= '' then
		root
		:tag( 'tr' )
		:tag( 'td' )
		:attr( 'colspan', '2' )
		:wikitext( string.format( '<small>%s</small>', self.footnotes ) )
	end

	return tostring( root )
end

--------------------------------------------------------------------
-- Calendar group class definition
--------------------------------------------------------------------

--  Calendar groups are used to group different calendars together. 
--  Previously, the template did this by including a table row with
--  no year value. By using objects we can do the same thing more
--  semantically.

local calendarGroup = {}
calendarGroup.__index = calendarGroup

function calendarGroup:new( init )
	init = type( init ) == 'table' and init or {}
	local obj = {}

	-- Get the heading and throw an error if it is invalid.
	obj.heading = init.heading
	if type( obj.heading ) ~= 'string' then
		error( 'calendarGroup: no heading detected' )
	end

	-- Set the metatable and return the object.
	self.__index = self
	return setmetatable( obj, {
			__index = self
		})
end

function calendarGroup:addCalendar( calendar )
	-- Adds a calendar object to the calendar group.
	self.calendars = self.calendars or {}
	if type( calendar ) == 'table' and type( calendar.getLink ) == 'function' then
		table.insert( self.calendars, calendar )
	end
end

function calendarGroup:export()
	-- Exports the calendar group's wikitext.
	-- Indent and italicise each calendar's link if it exists.
	for i, calendar in ipairs( self.calendars ) do
		local link = calendar:getLink()
		if type( link ) == 'string' then
			self.calendars[ i ]:setRawLink( string.format( "&nbsp;- ''%s''", link ) )
		end
	end
	-- Create the heading row html and export the calendar objects.
	local ret = mw.html.create()
	ret
	:tag( 'tr' )
	:tag( 'td' )
	:wikitext( self.heading )
	:done()
	:tag( 'td' ) -- Use a blank tag to make the html look nice.
	:allDone()
	for _, calendar in ipairs( self.calendars ) do
		ret:wikitext( calendar:export() )
	end
	return tostring( ret )
end

--------------------------------------------------------------------
-- Calendar class definition
--------------------------------------------------------------------

local calendar = {}
calendar.__index = calendar
calendar.type = 'calendar'

function calendar:new()
	local obj = {}
	return setmetatable( obj, {
			__index = self
		})
end

function calendar:setLink( link, display )
	-- Sets the calendar's wikilink, with optional display text and italics.
	if type( link ) ~= 'string' or link == '' then return end
	display = type( display ) == 'string' and display ~= '' and display
	if display then
		self.link = string.format( '[[%s|%s]]', link, display )
	else
		self.link = string.format( '[[%s]]', link )
	end
end

function calendar:setRawLink( s )
	-- Sets the calendar's wikilink as raw wikitext.
	if type( s ) ~= 'string' or s == '' then return end
	self.link = s
end

function calendar:getLink()
	-- Returns the calendar's link value.
	return self.link
end

function calendar:setYear( year )
	-- Sets a single year. Can be passed either a string or a number.
	-- If passed as a number, it is formatted with minus signs instead of hyphens.
	-- If passed as a string, no minus-sign formatting occurs; this should be done in the individual calendar definitions.
	if type( year ) == 'number' then
		year = tostring( year )
		self.year = formatNegative( year )
	elseif type( year ) == 'string' then
		self.year = year
	end
end

function calendar:setYearRange( year1, year2 )
	-- Sets a year range. Must be passed two numbers.
	if type( year1 ) == 'number' and type( year2 ) == 'number' then
		local year
		if year1 < 0 or year2 < 0 then -- Leave a gap for negative years to avoid having a minus sign and a dash right next to each other.
			year = string.format( '%d – %d', year1, year2 )
			year = formatNegative( year )
		else
			year = string.format( '%d–%d', year1, year2 )
		end
		self.year = year
	end
end

function calendar:setYearCouple( year1, year2 )
	-- Same as setYearRange, only with a slash (/) in the middle. Must be passed two numbers. 
	-- Additional text possible, must be defined as follows: addtext = string.format( 'additional text or link')
	-- See example in Seleucid era calendar
	if type( year1 ) == 'number' and type( year2 ) == 'number' then
		local year
		if year1 < 0 or year2 < 0 then -- Leave no gap for negative years.
			year = string.format( '%d/%d %s', year1, year2, addtext )
			year = formatNegative( year )
		else
			year = string.format( '%d/%d %s', year1, year2, addtext )
		end
		self.year = year
	end
end

function calendar:export()
	-- Outputs the calendar wikitext.
	-- Exit if no link has been specified.
	local link = self.link
	if type( link ) ~= 'string' or link == '' then return end

	-- If no year has been specified, set the year value to N/A.
	local year = self.year
	if type( year ) ~= 'string' or year == '' then
		year = "''N/A''"
	end

	-- Build the table row.
	local ret = mw.html.create()
	ret
	:tag( 'tr' )
	:tag( 'td' )
	:wikitext( link )
	:done()
	:tag( 'td' )
	:wikitext( year )
	:allDone()
	return tostring( ret )
end

--------------------------------------------------------------------
-- Build the box
--------------------------------------------------------------------

local function makeCalendarBox( args )
	-- Initiate the box and get the year values.
	local init = args
	local box = calendarBox:new( init )
	local year = box.year
	local yearText = box.yearText

	-- Set the caption.
	box:setCaption( box.caption .. ' in various [[Calendar era|calendars]]' )

	----------------------------------------------------------------------
	-- Gregorian calendar
	----------------------------------------------------------------------

	local gregorian = calendar:new()
	gregorian:setLink( 'Gregorian calendar' )
	-- Get the year link.
	local gregcal = args.gregcal
	if type( gregcal ) == 'string' and gregcal ~= '' then
		gregorian.yearLink = string.format( '[[%s|%s]]', gregcal, yearText )
	else
		gregorian.yearLink = yearText
	end
	-- Set the year.
	gregorian.romanYear = numToRoman{ math.abs(year) } .. (year < 0 and ' BC' or '')
	if gregorian.romanYear then
		gregorian:setYear( string.format(
				[[%s<br /><span style="font-family: serif;">''%s''</span>]],
				gregorian.yearLink, gregorian.romanYear
				) )
	else
		gregorian:setYear( gregorian.yearLink )
	end
	box:addCalendar( gregorian ) 
	
	----------------------------------------------------------------------
	-- French Republican calendar
	-- displays only in years 1793 - 1805 and 1871
	-- This calendar was in use and had defined years only for the short period on display.
	-- Its importance during these few years is also the reason why it should stay out of the alphabetic order.
	-- See discussion on talk page.
	----------------------------------------------------------------------
	
	if year >= 1793 and year < 1806 or year == 1871 then
		local republican = calendar:new()
		republican:setLink('French Republican calendar')
		if year <= 1870 then
			republican:setYearRange( year - 1792, year - 1791 )
		elseif year == 1871 then
			republican:setYear( year - 1792 ) -- Paris Commune, May
		end
		box:addCalendar( republican )
	end
	
	----------------------------------------------------------------------
	-- Ab urbe condita
	-- Varro's correlation, from 1 AUC
	----------------------------------------------------------------------
	if year >= -752 then
		local abUrbe = calendar:new()
		abUrbe:setLink( 'Ab urbe condita' )
		abUrbe:setYear( year + 753 )
		box:addCalendar( abUrbe )
	end
	
	----------------------------------------------------------------------
	-- Ancient Egypt era 
	-- Displays dynasty between 1549 BC and 30 BC
	-- Displays pharaoh or king between 752 BC and 30 BC
	----------------------------------------------------------------------
	if year > -1549 and year <= -29 then
	local ancEgypt = calendar:new()
	ancEgypt:setLink(
			'Egyptian chronology',
			'Ancient Egypt era'
		)
	ancEgypt:setYear( getDynasty( year ) )
	box:addCalendar( ancEgypt )
	end
	if year > - 752 and year <= -29 then
	local ancPharaoh = calendar:new()
	ancPharaoh:setLink(
			'List of pharaohs',
			'<i>- Pharaoh</i>'
		)
	ancPharaoh:setYear( getPharaoh( year ) )
	box:addCalendar( ancPharaoh )
	end

	----------------------------------------------------------------------
	-- Ancient Olympiads 
	-- Currently only the first 194 Olympiads
	-- May be expanded until 394 AD when data available
	----------------------------------------------------------------------
	if year >= -1300 and year < 1 then
	local ancOlympiads = calendar:new()
	ancOlympiads:setLink(
			'Ancient Greek calendar',
			'Ancient Greek era'
		)
	ancOlympiads:setYear( getOlympiad( year ) )
	box:addCalendar( ancOlympiads )
	end

	----------------------------------------------------------------------
	-- Armenian calendar
	----------------------------------------------------------------------

	if year > 551 then
	local armenian = calendar:new()
	armenian:setLink( 'Armenian calendar' )
		local armenianYear = year - 551
		armenian:setYear( string.format( '%s<br />ԹՎ %s', armenianYear, numToArmenian( armenianYear ) ) )
	box:addCalendar( armenian )
	end

	----------------------------------------------------------------------
	-- Assyrian calendar
	----------------------------------------------------------------------

	local assyrian = calendar:new()
	assyrian:setLink( 'Assyrian calendar' )
	assyrian:setYear( year + 4750 )
	box:addCalendar( assyrian )

	----------------------------------------------------------------------
	-- Bahá'í calendar
	-- displays only after 1843
	----------------------------------------------------------------------
	
	if year >= 1844 then
		local bahai = calendar:new()
		bahai:setLink( "Bahá'í calendar" )
		bahai:setYearRange( year - 1844, year - 1843 )
		box:addCalendar( bahai )
	end
	
    ----------------------------------------------------------------------
    -- Balinese saka calendar
    ---------------------------------------------------------------------- 
    local balinese = calendar:new()
    balinese:setLink( 'Balinese saka calendar' )
    if year - 76 > 0 then
    	balinese:setYearRange( year - 79, year - 78 )
    end
    box:addCalendar( balinese )

	----------------------------------------------------------------------
	-- Bengali calendar
	----------------------------------------------------------------------

	local bengali = calendar:new()
	bengali:setLink( 'Bengali calendar' )
	bengali:setYear( year - 593 )
	box:addCalendar( bengali )

	----------------------------------------------------------------------
	-- Berber calendar
	----------------------------------------------------------------------

	local berber = calendar:new()
	berber:setLink( 'Berber calendar' )
	berber:setYear( year + 950 )
	box:addCalendar( berber )

	----------------------------------------------------------------------
	-- Regnal year
	----------------------------------------------------------------------

	if year >= 1000 then
		local regnal = calendar:new()
		local regnalName
		if year > 1706 then
			regnalName = 'British'
		else
			regnalName = 'English'
		end
		regnal:setLink( 'Regnal years of English monarchs', regnalName .. ' Regnal year' )
		regnal:setYear( getRegnal( year ) )
		box:addCalendar( regnal )
	end

	----------------------------------------------------------------------
	-- Buddhist calendar
	----------------------------------------------------------------------

	local buddhist = calendar:new()
	buddhist:setLink( 'Buddhist calendar' )
	buddhist:setYear( year + 544 )
	box:addCalendar( buddhist )

	----------------------------------------------------------------------
	-- Burmese calendar
	----------------------------------------------------------------------

	local burmese = calendar:new()
	burmese:setLink( 'Burmese calendar' )
	burmese:setYear( year - 638 )
	box:addCalendar( burmese )

	----------------------------------------------------------------------
	-- Byzantine calendar
	----------------------------------------------------------------------

	local byzantine = calendar:new()
	byzantine:setLink( 'Byzantine calendar' )
	byzantine:setYearRange( year + 5508, year + 5509 )
	box:addCalendar( byzantine )

	----------------------------------------------------------------------
	-- Chinese calendar
	----------------------------------------------------------------------

	local chinese = calendar:new()
	chinese:setLink( 'Chinese calendar' )

	-- Define the information for the "heavenly stems" and "earthly branches" year cycles.
	-- See [[Chinese calendar#Cycle of years]] for information.

	local heavenlyStems = {
		{ '甲', 'Wood' },   -- 1
		{ '乙', 'Wood' },   -- 2
		{ '丙', 'Fire' },   -- 3
		{ '丁', 'Fire' },   -- 4
		{ '戊', 'Earth' },  -- 5
		{ '己', 'Earth' },  -- 6
		{ '庚', 'Metal' },  -- 7
		{ '辛', 'Metal' },  -- 8
		{ '壬', 'Water' },  -- 9
		{ '癸', 'Water' }   -- 10
	}

	local earthlyBranches = {
		{ '子', '[[Rat (zodiac)|Rat]]' },           -- 1
		{ '丑', '[[Ox (zodiac)|Ox]]' },             -- 2
		{ '寅', '[[Tiger (zodiac)|Tiger]]' },       -- 3
		{ '卯', '[[Rabbit (zodiac)|Rabbit]]' },     -- 4
		{ '辰', '[[Dragon (zodiac)|Dragon]]' },     -- 5
		{ '巳', '[[Snake (zodiac)|Snake]]' },       -- 6
		{ '午', '[[Horse (zodiac)|Horse]]' },       -- 7
		{ '未', '[[Goat (zodiac)|Goat]]' },         -- 8
		{ '申', '[[Monkey (zodiac)|Monkey]]' },     -- 9
		{ '酉', '[[Rooster (zodiac)|Rooster]]' },   -- 10
		{ '戌', '[[Dog (zodiac)|Dog]]' },           -- 11
		{ '亥', '[[Pig (zodiac)|Pig]]' }            -- 12
	}

	-- Calculate the cycle numbers from the year. The first sexagenary year corresponds to the ''previous'' year's entry
	-- in [[Chinese calendar correspondence table]], as the Chinese New Year doesn't happen until Jan/Feb in
	-- Gregorian years.
	local sexagenaryYear1 = ( year - 4 ) % 60
	local sexagenaryYear2 = ( year - 3 ) % 60
	local heavenlyNum1 = (sexagenaryYear1 - 1) % 10 + 1 -- amod, since lua arrays are 1-indexed
	local heavenlyNum2 = (sexagenaryYear2 - 1) % 10 + 1
	local earthlyNum1 = (sexagenaryYear1 - 1) % 12 + 1
	local earthlyNum2 = (sexagenaryYear2 - 1) % 12 + 1

	-- Get the data tables for each permutation.
	local heavenlyTable1 = heavenlyStems[ heavenlyNum1 ]
	local heavenlyTable2 = heavenlyStems[ heavenlyNum2 ]
	local earthlyTable1 = earthlyBranches[ earthlyNum1 ]
	local earthlyTable2 = earthlyBranches[ earthlyNum2 ]

	-- Work out the continously-numbered year. (See [[Chinese calendar#Continuously numbered years]].)
	local year1 = year + 2696
	local year2 = year + 2697
	local year1Alt = year1 - 60
	local year2Alt = year2 - 60

	-- Format any negative numbers.
	year1 = formatNegative( tostring( year1 ) )
	year2 = formatNegative( tostring( year2 ) )
	year1Alt = formatNegative( tostring( year1Alt ) )
	year2Alt = formatNegative( tostring( year2Alt ) )

	-- Return all of that data in a (hopefully) reader-friendly format.
	chinese:setYear( string.format(
			[=[[[Chinese sexagenary cycle|%s%s]]年 <small>(%s&nbsp;%s)</small><br />%s or %s<br />&nbsp;&nbsp;&nbsp;&nbsp;''—&nbsp;to&nbsp;—''<br />%s%s年 <small>(%s&nbsp;%s)</small><br />%s or %s]=],
			heavenlyTable1[ 1 ],
			earthlyTable1[ 1 ],
			heavenlyTable1[ 2 ],
			earthlyTable1[ 2 ],
			year1,
			year1Alt,
			heavenlyTable2[ 1 ],
			earthlyTable2[ 1 ],
			heavenlyTable2[ 2 ],
			earthlyTable2[ 2 ],
			year2,
			year2Alt
			) )

	box:addCalendar( chinese )

	----------------------------------------------------------------------
	-- Coptic calendar
	----------------------------------------------------------------------

	local coptic = calendar:new()
	coptic:setLink( 'Coptic calendar' )
	coptic:setYearRange( year - 284, year - 283 )
	box:addCalendar( coptic )

	----------------------------------------------------------------------
	-- Discordian calendar
	----------------------------------------------------------------------

	local discordian = calendar:new()
	discordian:setLink( 'Discordian calendar' )
	discordian:setYear( year + 1166 )
	box:addCalendar( discordian )

	----------------------------------------------------------------------
	-- Ethiopian calendar
	----------------------------------------------------------------------

	local ethiopian = calendar:new()
	ethiopian:setLink( 'Ethiopian calendar' )
	ethiopian:setYearRange( year - 8, year - 7 )
	box:addCalendar( ethiopian )

	----------------------------------------------------------------------
	-- Hebrew calendar
	----------------------------------------------------------------------

	local hebrew = calendar:new()
	hebrew:setLink( 'Hebrew calendar' )
	hebrew:setYearRange( year + 3760, year + 3761 )
	box:addCalendar( hebrew )

	----------------------------------------------------------------------
	-- Hindu calendars
	----------------------------------------------------------------------

	local hindu = calendarGroup:new{ heading = '[[Hindu calendar]]s' }

	-- Vikram Samvat

	local vikramSamvat = calendar:new()
	vikramSamvat:setLink( 'Vikram Samvat' )
	vikramSamvat:setYearRange( year + 56, year + 57 )
	hindu:addCalendar( vikramSamvat )

	-- Shaka Samvat

	local shakaSamvat = calendar:new()
	shakaSamvat:setLink( 'Indian national calendar', 'Shaka Samvat' )
	if year >= 78 then
		shakaSamvat:setYearRange( year - 79, year - 78 )
	end
	hindu:addCalendar( shakaSamvat )

	-- Kali Yuga

	local kaliYuga = calendar:new()
	kaliYuga:setLink( 'Kali Yuga' ) -- use italics
	kaliYuga:setYearRange( year + 3100, year + 3101 )
	hindu:addCalendar( kaliYuga )

	box:addCalendarGroup( hindu )

	----------------------------------------------------------------------
	-- Holocene calendar
	----------------------------------------------------------------------

	local holocene = calendar:new()
	holocene:setLink( 'Holocene calendar' )
	holocene:setYear( year + 10000 )
	box:addCalendar( holocene )

	----------------------------------------------------------------------
	-- Igbo calendar
	----------------------------------------------------------------------

	-- In the old template this was a calendar group with just one calendar; intentionally adding this as a single
	-- calendar here, as the previous behaviour looked like a mistake.
	if year >= 1000 then
		local igbo = calendar:new()
		igbo:setLink( 'Igbo calendar' )
		igbo:setYearRange( year - 1000, year - 999 )
		box:addCalendar( igbo )
	end

	----------------------------------------------------------------------
	-- Iranian calendar
	----------------------------------------------------------------------

	local iranian = calendar:new()
	iranian:setLink( 'Iranian calendars', 'Iranian calendar' )
	if year - 621 > 0 then
		iranian:setYearRange( year - 622, year - 621 )
	else
		iranian:setYear( string.format( '%d BP&nbsp;– %d BP', 622 - year, 621 - year ) )
	end
	box:addCalendar( iranian )

	----------------------------------------------------------------------
	-- Islamic calendar
	----------------------------------------------------------------------

	local islamic = calendar:new()
	islamic:setLink( 'Islamic calendar' )
	local islamicMult = 1.030684 -- the factor to multiply by
	local islamicSub = 621.5643 -- the factor to subtract by
	if year - 621 > 0 then
		local year1 = math.floor( islamicMult * ( year - islamicSub ) )
		local year2 = math.floor( islamicMult * ( year - islamicSub + 1 ) )
		islamic:setYearRange( year1, year2 )
	else
		local year1 = math.ceil( -islamicMult * ( year - islamicSub ) )
		local year2 = math.ceil( -islamicMult * ( year - islamicSub + 1 ) )
		islamic:setYear( string.format( '%d BH&nbsp;– %d BH', year1, year2 ) )
	end
	box:addCalendar( islamic )

	----------------------------------------------------------------------
	-- Japanese calendar
	-- starting 600
	----------------------------------------------------------------------
	
	if year >= 600 then
	local japanese = calendar:new()
	japanese:setLink( 'Japanese calendar' )

	japanese.thisEra = japaneseEra:new{ year = year }
	if japanese.thisEra then
		local japaneseYearText = {}
		japanese.oldEra = japanese.thisEra:getOldEra()
		if japanese.oldEra and japanese.oldEra.eraYear and japanese.thisEra.article ~= japanese.oldEra.article then
			japanese.oldText = string.format( '%s %d', japanese.oldEra.link, japanese.oldEra.eraYear )
			table.insert( japaneseYearText, japanese.oldText )
			table.insert( japaneseYearText, ' / ' )
		end
		if japanese.thisEra.eraYear then
			table.insert( japaneseYearText, string.format( '%s %d', japanese.thisEra.link, japanese.thisEra.eraYear ) )
		end
		table.insert( japaneseYearText, string.format( '<br /><small>(%s%s年)</small>', japanese.thisEra.kanji, japanese.thisEra.eraYearKanji ) )
		japanese:setYear( table.concat( japaneseYearText ) )
	end

	box:addCalendar( japanese )
	end

	----------------------------------------------------------------------
	-- Javanese calendar
	----------------------------------------------------------------------

	local javanese = calendar:new()
	javanese:setLink( 'Javanese calendar' )
	local javaneseMult = 1.030684 -- the factor to multiply by
	local javaneseSub = 124.9 -- the factor to subtract by
	if year - 124 > 0 then
		local year1 = math.floor( javaneseMult * ( year - javaneseSub ) )
		local year2 = math.floor( javaneseMult * ( year - javaneseSub + 1 ) )
		javanese:setYearRange( year1, year2 )
	else
		local year1 = math.ceil( -javaneseMult * ( year - javaneseSub ) )
		local year2 = math.ceil( -javaneseMult * ( year - javaneseSub + 1 ) )
	end
	box:addCalendar( javanese )
	
	----------------------------------------------------------------------
	-- Juche calendar
	-- displays only after 1910
	----------------------------------------------------------------------

	if year >= 1910 then
		local juche = calendar:new()
		juche:setLink( 'North Korean calendar', 'Juche calendar' )
		if year > 1911 then
			juche:setYear( year - 1911 )
		end
		box:addCalendar( juche )
	end

	----------------------------------------------------------------------
	-- Julian calendar
	----------------------------------------------------------------------

	local julian = calendar:new()
	julian:setLink( 'Julian calendar' )

	if year >= -45 and year < 1582 then
		julian:setYear(gregorian.year)
	elseif year >= 1582 then
		local diff = math.floor(year/100-2) - math.floor(year/400)
		if year % 100 == 0 and year % 400 ~= 0 then
			julian:setYear('Gregorian minus ' .. diff-1 .. ' or ' .. diff .. ' days')
		else
			julian:setYear('Gregorian minus ' .. diff .. ' days')
		end
	end

	box:addCalendar( julian )

	----------------------------------------------------------------------
	-- Korean calendar
	----------------------------------------------------------------------

	local korean = calendar:new()
	korean:setLink( 'Korean calendar' )
	korean:setYear( year + 2333 )
	box:addCalendar( korean )

	----------------------------------------------------------------------
	-- Minguo calendar
	----------------------------------------------------------------------

	local minguo = calendar:new()
	minguo:setLink( 'Minguo calendar' )
	if year > 1949 then
		local minguoYear = year - 1911
		minguo:setYear( string.format( '[[Taiwan|ROC]] %d<br /><small>民國%d年</small>', minguoYear, minguoYear ) )
	elseif year > 1911 then
		local minguoYear = year - 1911
		minguo:setYear( string.format( '[[Republic of China (1912–1949)|ROC]] %d<br /><small>民國%d年</small>', minguoYear, minguoYear ) )
	else
		local minguoYear = 1911 - year + 1
		minguo:setYear( string.format( '%d before [[Republic of China (1912–1949)|ROC]]<br /><small>民前%d年</small>', minguoYear, minguoYear ) )
	end
	box:addCalendar( minguo )
	
	----------------------------------------------------------------------
	-- Nanakshahi calendar
	----------------------------------------------------------------------

	local nanakshahi = calendar:new()
	nanakshahi:setLink( 'Nanakshahi calendar' )
	nanakshahi:setYear( year - 1468 )
	box:addCalendar( nanakshahi )
	
	----------------------------------------------------------------------
	-- Seleucid era
	-- displays from 312 BC until 1200 AD
	----------------------------------------------------------------------
	
	if year >= -311 and year < 1200 then
		local seleucid = calendar:new()
			seleucid:setLink( 'Seleucid era' )
			addtext = string.format( '[[Anno Graecorum|AG]]')
		seleucid:setYearCouple( year + 311, year + 312, addtext )
		box:addCalendar( seleucid )
	end

	----------------------------------------------------------------------
	-- Thai solar calendar
	----------------------------------------------------------------------

	local thai = calendar:new()
	thai:setLink( 'Thai solar calendar' )
	if year >= 1941 then
		thai:setYear( year + 543 )
	else -- if year >= 1912 or year <= 1887 -- year started in March/April
		thai:setYearRange( year + 542, year + 543 )
	-- else -- Rattanakosin Era, 1888?-1912
	--			thai:setYear( string.format( '%d &nbsp;– %d <small>([[Rattanakosin Kingdom|Rattanakosin Era]])</small>', year - 1782 , year - 1781 ) )
	end
	box:addCalendar( thai )

	----------------------------------------------------------------------
	-- Tibetan calendar
	----------------------------------------------------------------------

	local tibetan = calendar:new()
	tibetan:setLink( 'Tibetan calendar' )

	-- Define the information for the "heavenly stems" and "earthly branches" year cycles.
	-- See [[Tibetan calendar#Years]] for information.

	local heavenlyStems = {
		{ '阳木', 'male Wood' },   -- 1
		{ '阴木', 'female Wood' },   -- 2
		{ '阳火', 'male Fire' },   -- 3
		{ '阴火', 'female Fire' },   -- 4
		{ '阳土', 'male Earth' },  -- 5
		{ '阴土', 'female Earth' },  -- 6
		{ '阳金', 'male Iron' },  -- 7
		{ '阴金', 'female Iron' },  -- 8
		{ '阳水', 'male Water' },  -- 9
		{ '阴水', 'female Water' }   -- 10
	}

	local earthlyBranches = {
		{ '鼠', '[[Rat (zodiac)|Rat]]' },           -- 1
		{ '牛', '[[Ox (zodiac)|Ox]]' },             -- 2
		{ '虎', '[[Tiger (zodiac)|Tiger]]' },       -- 3
		{ '兔', '[[Rabbit (zodiac)|Rabbit]]' },     -- 4
		{ '龙', '[[Dragon (zodiac)|Dragon]]' },     -- 5
		{ '蛇', '[[Snake (zodiac)|Snake]]' },       -- 6
		{ '马', '[[Horse (zodiac)|Horse]]' },       -- 7
		{ '羊', '[[Goat (zodiac)|Goat]]' },         -- 8
		{ '猴', '[[Monkey (zodiac)|Monkey]]' },     -- 9
		{ '鸡', '[[Rooster (zodiac)|Rooster]]' },   -- 10
		{ '狗', '[[Dog (zodiac)|Dog]]' },           -- 11
		{ '猪', '[[Pig (zodiac)|Pig]]' }            -- 12
	}

	-- Calculate the cycle numbers from the year. The first sexagenary year corresponds to the ''previous'' year's entry
	-- in [[Tibetan calendar correspondence table]], as the Tibetan New Year doesn't happen until Feb/Mar in
	-- Gregorian years.
	local sexagenaryYear1 = ( year - 4 ) % 60
	local sexagenaryYear2 = ( year - 3 ) % 60
	local heavenlyNum1 = (sexagenaryYear1 - 1) % 10 + 1 -- amod, since lua arrays are 1-indexed
	local heavenlyNum2 = (sexagenaryYear2 - 1) % 10 + 1
	local earthlyNum1 = (sexagenaryYear1 - 1) % 12 + 1
	local earthlyNum2 = (sexagenaryYear2 - 1) % 12 + 1

	-- Get the data tables for each permutation.
	local heavenlyTable1 = heavenlyStems[ heavenlyNum1 ]
	local heavenlyTable2 = heavenlyStems[ heavenlyNum2 ]
	local earthlyTable1 = earthlyBranches[ earthlyNum1 ]
	local earthlyTable2 = earthlyBranches[ earthlyNum2 ]

	-- Work out the continously-numbered year. (See [[Tibetan calendar#Years with cardinal numbers]].)
	local year1 = year + 126
	local year2 = year + 127
	local year1Alt1 = year1 - 381
	local year1Alt2 = year1 - 1153
	local year2Alt1 = year2 - 381
	local year2Alt2 = year2 - 1153

	-- Format any negative numbers.
	year1 = formatNegative( tostring( year1 ) )
	year2 = formatNegative( tostring( year2 ) )
	year1Alt1 = formatNegative( tostring( year1Alt1 ) )
	year1Alt2 = formatNegative( tostring( year1Alt2 ) )
	year2Alt1 = formatNegative( tostring( year2Alt1 ) )
	year2Alt2 = formatNegative( tostring( year2Alt2 ) )

	-- Return all of that data in a (hopefully) reader-friendly format.
	tibetan:setYear( string.format(
			[=[%s%s年<br /><small>(%s-%s)</small><br />%s or %s or %s<br />&nbsp;&nbsp;&nbsp;&nbsp;''—&nbsp;to&nbsp;—''<br />%s%s年<br /><small>(%s-%s)</small><br />%s or %s or %s]=],
			heavenlyTable1[ 1 ],
			earthlyTable1[ 1 ],
			heavenlyTable1[ 2 ],
			earthlyTable1[ 2 ],
			year1,
			year1Alt1,
			year1Alt2,
			heavenlyTable2[ 1 ],
			earthlyTable2[ 1 ],
			heavenlyTable2[ 2 ],
			earthlyTable2[ 2 ],
			year2,
			year2Alt1,
			year2Alt2
			) )

	box:addCalendar( tibetan )

	----------------------------------------------------------------------
	-- Unix time
	----------------------------------------------------------------------

	local unix = calendar:new()

	local function getUnixTime( year )
		if year < 1970 then return end
		local noError, unixTime = pcall( lang.formatDate, lang, 'U', '1 Jan ' .. tostring( year ) )
		if not noError or noError and not unixTime then return end
		unixTime = tonumber( unixTime )
		if unixTime and unixTime >= 0 then
			return unixTime - 1
		end
	end
	unix.thisYear = getUnixTime( year )
	unix.nextYear = getUnixTime( year + 1 )
	if unix.thisYear and unix.nextYear then
		unix:setLink( 'Unix time' )
		unix:setYear( (unix.thisYear + 1) .. " – " .. unix.nextYear )
	end

	box:addCalendar( unix )

	return box:export()
end

--------------------------------------------------------------------
-- Process arguments from #invoke
--------------------------------------------------------------------

local p = {}

function p.main( frame )
	-- Process the arguments and pass them to the box-building function.
	local args = getArgs( frame )
	-- Pass year argument with 'year' parameter or without any name but first argument
	args.year = args.year or args[1]
	return makeCalendarBox( args )
end

return p