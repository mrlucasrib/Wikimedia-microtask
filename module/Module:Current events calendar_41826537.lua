-- This module renders the calendar seen on [[Portal:Current events]].

--[[
	Incoming expected variables:
		frame.args.year = Integer value for year
		frame.args.month = Integer value for month, 1 based.
--]]

local p = {}

local function makeWikilink(link, display)
	if display then
		return string.format('[[%s|%s]]', link, display)
	else
		return string.format('[[%s]]', link)
	end
end

function p.main(frame)
	local argsDate = nil
	if (frame and frame.args and frame.args.year and frame.args.month) then
		-- If a date is passed in, assume that the display page is an Archive page.
		-- If no date passed in, assume that the display page is the current Current Events page
		argsDate = frame.args.year .. "-" .. frame.args.month .. "-01" -- Construct a date, YYY-M-DD format.
	end
	local dateStuff = p.getDateStuff(argsDate)
	local dayStrings = p.makeDayStrings(dateStuff)
	return p.export(dayStrings, dateStuff)
end

function p.getDateStuff(argsDate)

--[[
	Note: This function takes advantage of the formatDate's second argument to
	create data for the archival calendars. If the second arg (argsDate) is nil,
	then formatDate assumes the current date/time.
--]]

	-- Gets date data.
	local dateStuff = {}
	local lang = mw.language.getContentLanguage()
	dateStuff.argsDate = argsDate
	--Year
	local year = lang:formatDate('Y', argsDate)
	year = tonumber(year)
	dateStuff.year = year
	-- Month
	local month = lang:formatDate('F', argsDate)
	dateStuff.month = month
	-- Month and year
	local monthAndYear = lang:formatDate('F Y', argsDate)
	local firstOfMonth = lang:formatDate('01-m-Y', argsDate)
	dateStuff.monthAndYear = monthAndYear
	-- Previous month and year
	dateStuff.previousMonthAndYear = lang:formatDate('F Y', firstOfMonth .. ' -1 month')
	-- Next month and year
	dateStuff.nextMonthAndYear = lang:formatDate('F Y', firstOfMonth .. ' +1 month')
	-- Day
	local day = lang:formatDate('j', argsDate)
	day = tonumber(day)
	dateStuff.day = day
	-- Days in month
	local daysInMonth = lang:formatDate('j', firstOfMonth .. ' +1 month -1 day')
	daysInMonth = tonumber(daysInMonth)
	dateStuff.daysInMonth = daysInMonth
	-- Weekday of the first day of the month
	local firstWeekday = lang:formatDate('w', firstOfMonth) -- Sunday = 0, Saturday = 6
	firstWeekday = tonumber(firstWeekday)
	firstWeekday = firstWeekday + 1 -- Make compatible with Lua tables. Sunday = 1, Saturday = 7.
	dateStuff.firstWeekday = firstWeekday
	return dateStuff
end

function p.makeDayStrings(dateStuff)
	local calStrings = {}
	local currentDay = dateStuff.day
	local isLinkworthy = p.isLinkworthy
	local currentMonth = dateStuff.month
	local currentYear = dateStuff.year
	local makeDayLink = p.makeDayLink
	for day = 1, dateStuff.daysInMonth do
		if dateStuff.argsDate or isLinkworthy(day, currentDay) then
			calStrings[#calStrings + 1] = makeDayLink(day, currentMonth, currentYear)
		else
			calStrings[#calStrings + 1] = tostring(day)
		end
	end
	return calStrings
end

function p.isLinkworthy(day, currentDay)
	-- Returns true if the calendar day should be linked, and false if not.
	-- Days should be linked if they are the current day or if they are within the six
	-- preceding days, as that is the number of items on the current events page.
	if currentDay - 6 <= day and day <= currentDay then
		return true
	else
		return false
	end
end

function p.makeDayLink(day, month, year)
	return string.format("'''[[#%d %s %d|&nbsp;&nbsp;%d&nbsp;&nbsp;]]'''", year, month, day, day)
end

function p.export(dayStrings, dateStuff)
	-- Generates the calendar HTML.
	local monthAndYear = dateStuff.monthAndYear
	local root = mw.html.create('table')
	-- The next two lines help to make the table-layout-based Archive pages look good. When the 
	-- Archives have been converted to a grid-based layout, this logic can be removed, and the
	-- corressponding CSS margin attribute can be simplified.
	local temporaryMarginAdjustment = "auto !important"
	if dateStuff.argsDate then temporaryMarginAdjustment = "8px 0 0 8px" end
	root
		:addClass('infobox')
		:css{
			display = 'table',
			width = '100%',
			float = 'initial', 
			['max-width'] = '350px',
			margin = temporaryMarginAdjustment,
			['text-align'] = 'center',
			['background-color'] = '#f5faff',
			border = '1px solid #cedff2'
		}
		-- Headings
		:tag('tr')
			:css('background-color', '#cedff2')
			:tag('th')
				:css{['text-align'] = 'center'}
				:tag('span')
					:addClass('noprint')
					:wikitext(makeWikilink('Portal:Current events/' .. dateStuff.previousMonthAndYear, '◀'))
					:done()
				:done()
			:tag('th')
				:attr('colspan', '5')
				:css{['text-align'] = 'center'}
				:wikitext(makeWikilink('Portal:Current events/' .. monthAndYear, monthAndYear))
				:done()
			:tag('th')
				:css{['text-align'] = 'center'}
				:tag('span')
					:addClass('noprint')
					:wikitext(makeWikilink('Portal:Current events/' .. dateStuff.nextMonthAndYear, '▶'))

	-- Day of week headings
	local dayHeadingRow = root:tag('tr')
	local weekdays = {'S', 'M', 'T', 'W', 'T', 'F', 'S'}
	for i, weekday in ipairs(weekdays) do
		dayHeadingRow:tag('th')
			:css{['width'] = '14%', ['text-align'] = 'center'}
			:wikitext(weekday)
	end

	-- Days
	local cellCount = 1 - dateStuff.firstWeekday -- Tracks the number of day cells. Negative values used for initial blank cells.
	while cellCount < #dayStrings do -- Weekly rows
		local weeklyRow = root:tag('tr')
		for i = 1, 7 do -- Always make 7 cells.
			cellCount = cellCount + 1
			local dayString = dayStrings[cellCount] or "&nbsp;" -- Use a blank cell if there is no corresponding dateString
			weeklyRow:tag('td')
				:css{['text-align'] = 'center'}
				:wikitext(dayString)
		end
	end

	-- Footer
	if not dateStuff.argsDate then -- No footer necessary on Archive pages.
		root:tag('tr')
		    :addClass('noprint')
			:tag('td')
				:attr('colspan', '7')
				:css{['padding-top'] = '3px', ['padding-bottom'] = '5px', ['font-size'] = '78%', ['text-align'] = 'right'}
				:wikitext(makeWikilink('Portal:Current events/' .. monthAndYear, 'More ' .. monthAndYear .. ' events...&nbsp;&nbsp;&nbsp;'))
	end
	
	return tostring(root)
end

return p