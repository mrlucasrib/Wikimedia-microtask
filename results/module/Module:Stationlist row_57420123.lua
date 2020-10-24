local p = { } -- Package to be exported
local getArgs = require('Module:Arguments').getArgs -- Import module function to work with passed arguments
local lang = mw.getContentLanguage() -- Retrieve built-in locale for date formatting

function dtsYearCore(date, circa)
	-- A limited replacement for {{dts}}. This is passed a date and derives a sort key from it. It returns a string with the hidden sort key, along with the year of the original date.
	if not date then return false end -- If the date is an empty string, stop and go back to whence it came.
	local year = lang:formatDate('Y', date) -- This invocation of lang:formatDate returns just the year.
	if year == date then -- If the provided date is just the year:
		date = date .. "-01-01" -- Tack on January 1 for the sort key to work right.
	end
	local month = lang:formatDate('m', date) -- Stores the month of the date.
	local day = lang:formatDate('d', date) -- Stores the day for this date.
	local dtsStr = string.format("%05d-%02d-%02d", year, month, day) -- Create and store the formatted hidden sort key. The year must be five digits, per convention.
	local spanParams = {style = "display:none; speak:none"} -- These CSS properties hide the sort key from normal view.
	local dtsSpan = mw.text.tag({name='span', content=dtsStr, attrs=spanParams}) -- This generates the HTML code necessary for the hidden sort key.
	if circa == 'yes' then -- If the date is tagged as circa,
		return dtsSpan .. "<abbr title=\"circa\">c.</abbr><span style=\"white-space:nowrap;\">&thinsp;" .. year .. "</span>" -- Add the circa abbreviation to the display. Derived from {{circa}}
	else -- Otherwise,
		return dtsSpan .. year -- Return the hidden sort key concatenated with the year for this date.
	end
end

function dtsYear(date, circa)
	local success, result = pcall(dtsYearCore, date, circa)
	if success then
		return result
	else
		return string.format('%s<span class="error">Error: Invalid date "%s".</span>', circa and '<abbr title="circa">c.</abbr>&thinsp;' or '', date)
	end
end

function dateCell(date, circa, ref)
	-- This function returns the proper value for a date cell.
	return '|align=center|' .. (dtsYear(date, circa) or "—") .. (ref or '')
end

function p._row(args)
	local concat = table.concat
	local insert = table.insert
	local stationCell = '|' .. args.station
	local locationCell = '|' .. args.location
	local linesCell
	if args.lines ~= 'none' then
		local lines = {}
		for _,v in ipairs(mw.text.split(args.lines, ';')) do
			insert(lines, v)
		end
		linesCell = '|' .. concat(lines, '<hr>')
	else
		linesCell = ''
	end
	local openedCell = dateCell(args.opened, args.circa_opened, args.opened_ref)
	local rebuiltCell = dateCell(args.rebuilt, args.circa_rebuilt, args.rebuilt_ref)
	local agencyClosedCell = dateCell(args.agency_closed, args.circa_agency_closed, args.agency_closed_ref)
	local closedCell = dateCell(args.closed, args.circa_closed, args.closed_ref)
	local notes = args.notes or ''
	local notesCell = notes == 'none' and '' or '|' .. notes
	local cells = {'|-', stationCell, locationCell, linesCell, openedCell, rebuiltCell, agencyClosedCell, closedCell, notesCell}
	return concat(cells, '\n')
end

function p.row(frame)
	local args = getArgs(frame)
	return p._row(args)
end

return p