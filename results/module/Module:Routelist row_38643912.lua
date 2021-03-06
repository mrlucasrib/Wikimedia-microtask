local p = { } -- Package to be exported
local getArgs = require('Module:Arguments').getArgs -- Import module function to work with passed arguments
local lang = mw.getContentLanguage() -- Retrieve built-in locale for date formatting

local routeStates = { } -- Table with route statuses.
--[[ The following tables include the following entries:
row: The start of the row, for this particular type (color)
established: The string to be output in the "Formed" column. For future routes, "proposed" is displayed here. Otherwise, display the year passed in the established parameter.
removed: The string to be output in the "Removed" column. In the case of routeStates.former, the year that the route was decommissioned is output instead.
]]--
routeStates.current = {row = "|-", removed = "current"} -- Data for current routes
routeStates.future = {row = '|- style="background-color:#ffdead;" title="Future route"', established = "proposed", removed = "—"} -- Data for future routes
routeStates.former = {row = '|- style="background-color:#d3d3d3;" title="Former route"'} -- Data for former routes
routeStates.formeroverride = {row = '|- style="background-color:#d3d3d3;" title="Former route"', removed = "—"} -- Data for routes marked as former by override
routeStates.unknown = {row = "|-", removed = "—"} -- Data for route with unknown status

function getRouteState(established, decommissioned)
	--[[ This function is passed the dates given for the established and decommissioned fields to the template. 
	It then returns the entry in the routeStates table corresponding to the status of the route.
	]]--
	if decommissioned == 'yes' then --If the decommissioned property just says "yes", then mark it as a former route and display default data.
		return routeStates.formeroverride
	elseif decommissioned then -- If the route is decommissioned, then it must be a former route.
		return routeStates.former
	elseif not established then -- Without the establishment date, there is not enough information to determine the status of the route.
		return routeStates.unknown
	elseif established == 'proposed' then -- If the "established date" is the string 'proposed', then it must be a future route.
		return routeStates.future
	else -- If none of the first three conditions are true, then it must be a current route.
		return routeStates.current
	end
end

function getLength(args)
	-- This function is passed the length fields from the {{routelist row}} invocation, and calculates the missing length from the other.
	local math = require "Module:Math" -- This module contains functions needed later in this function.
	local precision = math._precision -- The math._precision function provides the precision of a given string representing a number.
	local round = math._precision_format -- This method rounds a given number to the given number of digits. In Lua, storing these functions locally results in more efficient execution.
	local length = {} -- This table will store the computed lengths.
	local km = args["length_km"] -- The kilometer length from the {{routelist row}} call.
	local mi = args["length_mi"] -- The length in miles as passed to {{routelist row}}.
	if not km then -- This signifies that a length in kilometers was not passed.
		local n = tonumber(mi) -- The first step is to convert the miles (passed as a string from the template) into a number.
		if n then -- If the passed mile value is an empty string, n will equal nil, which would make this statement false. Otherwise, the length in kilometers is computed and stored.
			local ten_mult = (n % 10 == 0) -- Rounding is handled differently if the input distance is a multiple of 10.
			local prec = precision(mi) -- Retrieve the precision of the passed mile value (as a string).
			if ten_mult and prec < 0 then -- If the distance is a multiple of 10 and a whole number...
				prec = prec + 1 -- Add a digit to the precision.
			end
			length.km = round(tostring(n * 1.609344), tostring(prec)) -- Compute and round the length in kilometers, and store it in the length table.
		else -- No mile value was passed
			length.km = '—'
		end
	else -- If the length in kilometers was passed, the computed lengths table will simply contain the passed length.
		local prec = precision(km)
		length.km = round(km, tostring(prec))
	end
	if not mi then -- The same as above, but this time converting kilometers to mile if necessary.
		local n = tonumber(km) -- Kilometers as a number
		if n then -- If a kilometer value was passed:
			local ten_mult = (n % 10 == 0) -- Rounding is handled differently if the input distance is a multiple of 10.
			local prec = precision(km) -- Precision of the passed length
			if ten_mult and prec < 0 then -- If the distance is a multiple of 10 and a whole number...
				prec = prec + 1 -- Add a digit to the precision
			end
			length.mi = round(tostring(n / 1.609344), tostring(prec)) -- Compute and store the conversion into miles.
		else -- If not:
			length.mi = '—' -- Store a dash.
		end
	else -- And if the length in miles was passed:
		local prec = precision(mi) -- Get the precision...
		length.mi = round(mi, tostring(prec)) -- and format it appropriately
	end
	return length -- Return the length table with the computed lengths.
end

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

function removed(routeState, decommissioned, circa)
	-- This function returns the proper value for the removed column.
	return routeState.removed or dtsYear(decommissioned, circa) -- Returns the removed attribute of the provided routeState table or, if empty, the dtsYear-formatted decommissioned date.
end

function formed(routeState, established, circa)
	-- This function returns the proper value for the formed column.
	return routeState.established or dtsYear(established, circa) or "—" -- Returns 'proposed' if the route is proposed, the dtsYear-formatted established date if one was provided, or an em-dash.
end

function sortkey(args)
	-- This function return the sort key for the route (not to be confused with the previous function, which generates a sort key for the established and decommissioned dates.)
	local key = args.sortkey
	local type = args.type
	local route = args.route or ''
	if key then -- If a sort key already exists:
		return key -- Simply return it.
	else -- Otherwise:
		local routeKey
		local routeNum = tonumber(route)
		if routeNum then
			routeKey = string.format('%04d', route) -- This invocation is equivalent to the {{0000expr}} template. It zero-pads the given route number up to 4 digits.
		else
			local num, suffix = string.match(route, "(%d*)(.+)")
			routeKey = (tonumber(num) and string.format('%04d', num) or '') .. suffix
		end
		return type .. routeKey -- Return the sort key for this route, composed of the type and zero-padded route number.
	end
end

function termini(args)
	-- This function determines if this is a beltway or not, and displays the termini columns appropriately.
	local beltway = args["beltway"] -- Text in this parameter will span both termini columns.
	local terminus_a = args["terminus_a"] or '—' -- Southern or western terminus
	local terminus_b = args["terminus_b"] or '—' -- Northern or eastern terminus
	
	if beltway then
		return "|colspan=2 align=center|" .. beltway -- This text will, again, span both columns.
	else
		return '|' .. terminus_a .. '||' .. terminus_b -- Fill in the termini columns
	end
end

function dates(established, decommissioned, routeState, args)
	-- This function displays the date columns.
	local established_ref = args.established_ref or '' -- Reference for date established
	local decommissioned_ref = args.decommissioned_ref or '' -- Reference for date decommissioned
	return "|align=center|" .. formed(routeState, established, args.circa_established) ..
	       established_ref .. "||align=center|" .. removed(routeState, decommissioned, args.circa_decommissioned) ..
	       decommissioned_ref
end

function length(args)
	-- This function generate the length columns, with the appropriate conversions.
	local miles = args["length_mi"] -- Length in miles
	local kilometers = args["length_km"] -- Length in kilometers
	local lengths = {length_mi = miles, length_km = kilometers} -- This time, we compile the lengths into a table,
	local Lengths = getLength(lengths) -- which makes for an easy parameter. This function call will return the lengths in both miles and kilometers,
	
	local lengthRef = args["length_ref"] or ''
	local first, second
	if kilometers then
		first = Lengths.km
		second = Lengths.mi
	else
		first = Lengths.mi
		second = Lengths.km
	end
	
	return "|align=right|" .. first .. lengthRef .. "||align=right|" .. second -- which are then spliced in here and returned to the template.
end

function localname(args)
	-- This function generates a "Local names" cell if necessary
	local enabled = args[1] or ''
	local localName = args["local"] or ''
	if mw.text.trim(enabled) == "local" then
		return "|" .. localName
	else
		return ''
	end
end

function notes(notes)
	-- This function generates a "Notes" cell if necessary.
	if notes == 'none' then
		return '| ' --create empty cell
	elseif notes then
		return '|' .. notes --display notes in cell
	else
		return '' --create no cell
	end
end

function route(args)
	-- This function displays the shield and link.
	local format = mw.ustring.format	
	local parserModule = require "Module:Road data/parser"
	local parser = parserModule.parser
	
	local noshield = args.noshield
	local bannerFile = parser(args, 'banner')
	local banner
	if not noshield and bannerFile and bannerFile ~= '' then
		local widthCode = parser(args, 'width') or 'square'
		if widthCode == 'square' then
			banner = format("[[File:%s|25px|link=|alt=]]", bannerFile)
		elseif widthCode == 'expand' then
			local route = args.route
			if #route >= 3 then
				banner = format("[[File:No image.svg|3px|link=|alt=]][[File:%s|25px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile)
			else
				banner = format("[[File:%s|25px|link=|alt=]]", bannerFile)
			end
		elseif widthCode == 'wide' then
			banner = format("[[File:No image.svg|3px|link=|alt=]][[File:%s|25px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile)
		elseif widthCode == 'MOSupp' then
			local route = args.route
			if #route >= 2 then
				banner = format("[[File:No image.svg|3px|link=|alt=]][[File:%s|25px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile)
			else
				banner = format("[[File:%s|25px|link=|alt=]]", bannerFile)
			end
		elseif widthCode == 'US1926' then
			banner = format("[[File:%s|25px|link=|alt=]][[File:No image.svg|1px|link=|alt=]]", bannerFile)
		elseif args.state == 'CA' then
			local route = args.route
			local type = args.type
			if type == 'US-Bus' then
				if #route >= 3 then
					banner = format("[[File:No image.svg|2px|link=|alt=]][[File:%s|25px|link=|alt=]][[File:No image.svg|2px|link=|alt=]]", bannerFile)
				else
					banner = format("[[File:%s|25px|link=|alt=]]", bannerFile)
				end
			elseif type == 'CA-Bus' or type == 'SR-Bus' then
				if #route >= 3 then
					banner = format("[[File:No image.svg|1px|link=|alt=]][[File:%s|25px|link=|alt=]][[File:No image.svg|2px|link=|alt=]]", bannerFile)
				else
					banner = format("[[File:%s|24px|link=|alt=]]", bannerFile)
				end
			end
		end
		banner = banner .. '<br>'
	else
		banner = ''
	end

	local shield
	if not noshield then
		local shieldFile, second = parser(args, 'shield')
		if type(shieldFile) == 'table' then
			shieldFile, second = shieldFile[1], shieldFile[2]
		end
		if second and type(second) == 'string' then
			local shield1 = format("[[File:%s|x25px|alt=|link=]]", shieldFile)
			local shield2 = format("[[File:%s|x25px|alt=|link=]]", second)
			shield = shield1 .. shield2
		else
			shield = shieldFile and format("[[File:%s|x25px|alt=|link=]]", shieldFile) or ''
		end
	else
		shield = ''
	end
	
	local linkTarget = (not args.nolink) and parser(args, 'link')
	local abbr = parser(args, 'abbr')
	local link
	if linkTarget then
		link = format("[[%s|%s]]", linkTarget, abbr)
	else
		link = abbr
	end
	if not link then error("Type not in database: " .. args.type) end
	local sortkey = sortkey(args)
	local sortedLink = format("<span data-sort-value=\"%s&#32;!\">%s</span>", sortkey, link)
	local route = banner .. shield .. ' ' .. sortedLink
	return '!scope="row" class="nowrap"|' .. route
end

function p.row(frame)
	local args = getArgs(frame) -- Gather passed arguments into easy-to-use table
	
	local established = args.established
	local decommissioned = args.decommissioned
	local routeState = getRouteState(established, decommissioned)
	local anchor = args.anchor or sortkey(args)
	local rowdef = routeState.row .. string.format(' id="%s"', anchor)
	local route = route(args)
	local length = length(args)
	local termini = termini(args)
	local localname = localname(args)
	local dates = dates(established, decommissioned, routeState, args)
	local notesArg = args.notes
	local notes = notes(notesArg)
	
	local row = {rowdef, route, length, termini, localname, dates, notes}
	return table.concat(row, '\n')
end

return p