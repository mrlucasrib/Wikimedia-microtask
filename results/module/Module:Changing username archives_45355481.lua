-- This module produces automatically updated archive lists for the request
-- pages related to [[Wikipedia:Changing username]].

local findHighestArchiveNumber = require('Module:Highest archive number')._main
local lang -- lazily load a mw.language object

local p = {}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function makeWikilink(page, display)
	return string.format('[[%s|%s]]', page, display)
end

local function message(msg, ...)
	return mw.message.newRawMessage(msg, ...):plain()
end

local function formatDate(format, date)
	lang = lang or mw.language.getContentLanguage()
	local success, newDate = pcall(lang.formatDate, lang, format, date)
	if success then
		return newDate
	else
		error(string.format(
			"invalid date '%s' passed to getDate",
			tostring(date)
		))
	end
end

local function getYearNumber(date)
	return tonumber(formatDate('Y', date))
end

local function getMonthNumber(date)
	return tonumber(formatDate('n', date))
end

--------------------------------------------------------------------------------
-- NumberArchive class
--------------------------------------------------------------------------------

local NumberArchive = {}
NumberArchive.__index = NumberArchive

-- Create a new NumberArchive object.
-- Parameters:
-- pageFormat - a message string to create the page name with. The archive
--     number is available as parameter $1.
--     e.g. "Talk:Example/Archive $1"
-- number - the archive number, as an integer
-- display - a custom display value
function NumberArchive.new(pageFormat, number, display)
	local obj = setmetatable({}, NumberArchive)
	obj.pageFormat = pageFormat
	obj.number = number
	obj.display = display
	return obj
end

-- Get the archive page name.
function NumberArchive:getPage()
	return message(self.pageFormat, self.number)
end

-- Render the archive link.
function NumberArchive:__tostring()
	return makeWikilink(self:getPage(), self.display or tostring(self.number))
end

--------------------------------------------------------------------------------
-- DateArchive class
--------------------------------------------------------------------------------

local DateArchive = {}
DateArchive.__index = DateArchive

DateArchive.params = {
	'pageFormat',
	'year',
	'month',
	'yearFormat',
	'monthFormat',
	'displayFormat'
}

-- Make a new DateArchive object. This is a named function, with the following
-- parameters:
-- pageFormat - a message string to create the page name with. The year is
--     available as parameter $1, and the month is available as parameter $2.
--     e.g. "Talk:Example/Archives/$1/$2"
-- year - the year, as a 4-digit integer
-- month - the month, as an integer from 1 to 12
-- yearFormat - year format, as a format string for lang:formatDate
-- monthFormat - month format, as a format string for lang:formatDate
-- displayFormat - a custom display format, as a format string for
--     lang:formatDate
function DateArchive.new(t)
	local obj = setmetatable({}, DateArchive)
	for i, param in ipairs(DateArchive.params) do
		obj[param] = t[param]
	end
	return obj
end

function DateArchive:getFormattedMonth(format)
	format = format or self.monthFormat or 'F'
	return formatDate(format, string.format('2000-%02d-01', self.month))
end

function DateArchive:getFormattedYear(format)
	format = format or self.monthFormat or 'Y'
	return formatDate(format, string.format('%04d-01-01', self.year))
end

function DateArchive:getDisplay()
	local format = self.displayFormat or 'M'
	return formatDate(
		format,
		string.format('%04d-%02d-01', self.year, self.month)
	)
end

function DateArchive:getPage()
	return message(
		self.pageFormat,
		self:getFormattedYear(),
		self:getFormattedMonth()
	)
end

function DateArchive:__tostring()
	return makeWikilink(self:getPage(), self:getDisplay())
end

--------------------------------------------------------------------------------
-- ArchiveList class
--------------------------------------------------------------------------------

local ArchiveList = {}
ArchiveList.__index = ArchiveList

function ArchiveList.newNumberedList(t)
	-- For archives in the format Archive1, Archive2, Archive3 ...
	local obj = setmetatable({}, ArchiveList)

	-- Make archive objects
	local archives = {}
	local prefix = t.prefix
	for i = 1, findHighestArchiveNumber(prefix) do
		local archiveObj = Archive.new(i, prefix)
		table.insert(archives, archiveObj)
	end
	obj.archives = archives

	-- Set start of line function
	function obj.isStartOfLine(archiveObj)
		local period = t.period or 25
		return (archiveObj.number - 1) % period == 0
	end

	return obj
end

function ArchiveList.newDatedList(t)
	-- For archives in the format January, February, March...
	local obj = setmetatable({}, ArchiveList)
	local startYear = getYearNumber(t.startDate)
	local startMonth = getMonthNumber(t.startDate)
	local endYear = getYearNumber(t.endDate) -- Defaults to current year
	local endMonth = getMonthNumber(t.endDate) -- Defaults to current month

	-- Set start of line function
	function obj.isStartOfLine(archiveObj)
		local startMonth = t.lineStartMonth or 1
		return archiveObj.month == startMonth
	end

	return obj
end

return p