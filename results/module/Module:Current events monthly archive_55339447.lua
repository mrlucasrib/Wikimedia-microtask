-- This module generates the monthly archives [[Portal:Current events]].
-- See a sample archive at [[Portal:Current events/September 2011]].

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Return true if num is a positive integer; otherwise return false
local function isPositiveInteger(num)
	return num > 0 and num == math.floor(num)
end

-- Make an ordinal number from an integer.
local function makeOrdinalNumber(num)
	local suffix
	local rem100 = num % 100
	if rem100 == 11 or rem100 == 12 or rem100 == 13 then
		suffix = 'th'
	else
		local rem10 = num % 10
		if rem10 == 1 then
			suffix = 'st'
		elseif rem10 == 2 then
			suffix = 'nd'
		elseif rem10 == 3 then
			suffix = 'rd'
		else
			suffix = 'th'
		end
	end
	return tostring(num) .. suffix
end

-- Try to parse the year and month from the current title.
-- This template is usually used on pages with titles like
-- [[Portal:Current events/September 2011]], so our general approach will be to
-- pass the subpage name to lang:formatDate and see if we get something that's
-- not an error.
local function parseYearAndMonthFromCurrentTitle()
	local title = mw.title.getCurrentTitle()
	local lang = mw.language.getContentLanguage()
	-- Detect if we are on a sandbox page, and if so, use the base page.
	if title.subpageText:find('^[sS]andbox%d*$') then
		title = title.basePageTitle
	end
	-- Try to parse the date.
	local success, date = pcall(function ()
		-- lang:formatDate throws errors if it gets strange input,
		-- so use pcall to catch them, as random subpage names will
		-- usually not be well-formed dates.
		return lang:formatDate('Y-m', title.subpageText)
	end)
	if not success then
		-- We couldn't parse the date, so return nil.
		return nil, nil
	end
	-- Parse the year and month numbers from the date we got from
	-- lang:formatDate. If we can't parse them, then something has gone
	-- wrong with either lang:formatDate or our pattern.
	local year, month = date:match('^(%d%d%d%d)%-(%d%d)$')
	year = tonumber(year)
	month = tonumber(month)
	if not year or not month then
		error('Internal error in [[Module:Current events '
			.. 'monthly archive]]: couldn\'t match date '
			.. 'from lang:formatDate output'
		)
	end
	return year, month
end

--------------------------------------------------------------------------------
-- Date info
--------------------------------------------------------------------------------

-- Get a table of information about the date for the monthly archive.
local function getDateInfo(year, month)
	local lang = mw.language.getContentLanguage()
	local dateFuncs = {}
	local dateInfo = setmetatable({}, {
		__index = function (t, key)
			-- Memoize values so we only have to calculate them once.
			if dateFuncs[key] then
				local val = dateFuncs[key]()
				t[key] = val
				return val
			end
		end
	})

	function dateFuncs.currentYear()
		-- The current year (number)
		return tonumber(os.date('%Y'))
	end

	function dateFuncs.currentMonthNumber()
		-- The current month (number)
		return tonumber(os.date('%m'))
	end

	function dateFuncs.year()
		-- The year (number)
		return tonumber(year) or dateInfo.currentYear
	end

	function dateFuncs.monthNumber()
		-- The month (number)
		return tonumber(month) or dateInfo.currentMonthNumber
	end

	function dateFuncs.monthNumberZeroPadded()
		-- The month, zero-padded to two digits (string)
		return string.format('%02d', dateInfo.monthNumber)
	end

	function dateFuncs.date()
		-- The date in YYYY-MM-DD format (string)
		return string.format(
			'%04d-%02d-01',
			dateInfo.year, dateInfo.monthNumber
		)
	end

	function dateFuncs.monthName()
		-- The month name, e.g. "September" (string)
		return lang:formatDate('F', dateInfo.date)
	end

	function dateFuncs.monthOrdinal()
		-- The ordinal month as an English word (string)
		local ordinals = {
			"first",   "second",   "third",
			"fourth",  "fifth",    "sixth",
			"seventh", "eighth",   "ninth",
			"tenth",   "eleventh", "twelfth and final",
		}
		return ordinals[dateInfo.monthNumber]
	end

	function dateFuncs.beVerb()
		-- If the month is the current month or a month in the future, then this
		-- is the string "is"; otherwise, "was" (string)
		if dateInfo.year > dateInfo.currentYear
			or (
				dateInfo.year == dateInfo.currentYear
				and dateInfo.monthNumber >= dateInfo.currentMonthNumber
			)
		then
			return 'is'
		else
			return 'was'
		end
	end

	function dateFuncs.leapDesc()
		-- The year's leap year status; either "common", "leap" or
		-- "century leap" (string)
		local isLeapYear = tonumber(lang:formatDate('L', dateInfo.date)) == 1
		if isLeapYear and dateInfo.year % 400 == 0 then
			return 'century leap'
		elseif isLeapYear then
			return 'leap'
		else
			return 'common'
		end
	end

	function dateFuncs.decadeNote()
		-- If the month is the first or last of a decade, century, or
		-- millennium, a note to that effect; otherwise the empty string
		-- (string)
		local function getMillennium(year)
			return math.floor((year - 1) / 1000) + 1 -- Fenceposts
		end

		local function getCentury(year)
			return math.floor((year - 1) / 100) + 1 -- Fenceposts
		end

		local year = dateInfo.year
		local month = dateInfo.monthNumber
		local firstOrLast = month == 12 and "last" or "first"

		if year % 1000 == 0 and month == 12
			or year % 1000 == 1 and month == 1
		then
			local millennium = makeOrdinalNumber(getMillennium(year))
			local century = makeOrdinalNumber(getCentury(year))
			return string.format(
				--Millenniums always overlap centuries.
				"It %s the %s month of the [[%s millennium]] and the [[%s century]].",
				dateInfo.beVerb, firstOrLast, millennium, century
			)
		elseif year % 100 == 0 and month == 12
			or year % 100 == 1 and month == 1
		then
			local century = makeOrdinalNumber(getCentury(year))
			return string.format(
				"It %s the %s month of the [[%s century]].",
				dateInfo.beVerb, firstOrLast, century
			)
		elseif year % 10 == 9 and month == 12
			or year % 10 == 0 and month == 1
		then
			local decadeNumber = math.floor(dateInfo.year / 10) * 10
			return string.format(
				"It %s the %s month of the [[%ds]] decade.",
				dateInfo.beVerb, firstOrLast, decadeNumber
			)
		end

		return ''
	end

	function dateFuncs.moonNote()
		-- If the month had no full moon, a note to that effect; otherwise the
		-- empty string (string)
		if dateInfo.monthNumber == 2 then
			-- https://www.quora.com/When-was-the-last-time-the-entire-month-of-February-passed-without-a-Full-Moon/answer/Alan-Marble
			local year = dateInfo.year
			if year == 1961
				or year == 1999
				or year == 2018
				or year == 2037
				or year == 2067
				or year == 2094
			then
				return 'This month had no full moon.'
			end
		end

		return ''
	end

	function dateFuncs.firstDayOfMonth()
		-- Weekday of the first day of the month, e.g. "Tuesday" (string)
		return lang:formatDate('l', dateInfo.date)
	end

	function dateFuncs.lastDayOfMonth()
		-- Weekday of the last day of the month, e.g. "Thursday" (string)
		return lang:formatDate('l', dateInfo.date .. ' +1 month -1 day')
	end

	function dateFuncs.daysInMonth()
		-- Number of days in the month (number)
		return tonumber(lang:formatDate(
			'j',
			dateInfo.date .. ' +1 month -1 day')
		)
	end

	function dateFuncs.mainContent()
		-- The rendered content of all the current events portal pages for the
		-- month (string)
		local ret = {}
		local frame = mw.getCurrentFrame()
		local year = dateInfo.year
		local monthName = dateInfo.monthName
		for date = 1, 31 do
			local portalTitle = mw.title.new(string.format(
				'Portal:Current events/%d %s %d',
				year, monthName, date
			))
			if portalTitle.exists then
				table.insert(
					ret,
					frame:expandTemplate{title = portalTitle.prefixedText}
				)
			end
		end
		return table.concat(ret, '\n')
	end

	return dateInfo
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p.main(frame)
	-- Get the arguments
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Current events monthly archive',
	})
	local year = tonumber(args.year)
	local month = tonumber(args.month)

	-- Validate the arguments
	if year and not isPositiveInteger(year) then
		error('invalid year argument (must be a positive integer)', 2)
	end
	if month then
		if not isPositiveInteger(month) then
			error('invalid month argument (must be a positive integer)', 2)
		elseif month > 12 then
			error('invalid month argument (must be 12 or less)', 2)
		end
	end

	-- If we weren't passed a month or a year, try to get them from the
	-- page title.
	if not year and not month then
		year, month = parseYearAndMonthFromCurrentTitle()
	end

	-- Convert the dateInfo table values into arguments to pass to the current
	-- events monthly archive display template
	local dateInfo = getDateInfo(year, month)
	local displayArgs = {}
	displayArgs['year']                     = dateInfo.year
	displayArgs['month-name']               = dateInfo.monthName
	displayArgs['month-number']             = dateInfo.monthNumber
	displayArgs['month-number-zero-padded'] = dateInfo.monthNumberZeroPadded
	displayArgs['be-verb']                  = dateInfo.beVerb
	displayArgs['month-ordinal']            = dateInfo.monthOrdinal
	displayArgs['leap-desc']                = dateInfo.leapDesc
	displayArgs['moon-note']                = dateInfo.moonNote
	displayArgs['decade-note']              = dateInfo.decadeNote
	displayArgs['first-day-of-month']       = dateInfo.firstDayOfMonth
	displayArgs['last-day-of-month']        = dateInfo.lastDayOfMonth
	displayArgs['days-in-month']            = dateInfo.daysInMonth
	displayArgs['main-content']             = dateInfo.mainContent

	-- Expand the display template with the arguments from dateInfo, and return
	-- it
	return frame:expandTemplate{
		title = 'Current events monthly archive/display',
		args = displayArgs,
	}
end

-- Export getDateInfo so that we can use it in unit tests.
p.getDateInfo = getDateInfo

return p