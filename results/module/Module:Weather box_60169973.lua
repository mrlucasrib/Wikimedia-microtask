-- Implement [[Template:Weather box]].

local precision = require('Module:Math')._precision

local function stripToNil(text)
	-- If text is a non-empty string, return its trimmed content.
	-- Otherwise, return nothing (text is an empty string or is not a string).
	if type(text) == 'string' then
		return text:match('(%S.-)%s*$')
	end
end

local function isAny(args, suffix)
	local months = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
	for _, month in ipairs(months) do
		if stripToNil(args[month .. suffix]) then
			return true
		end
	end
end

local function makeLabel(args, is_first, base, what)
	local first
	if isAny(args, ' ' .. what .. ' cm') then
		first = 'cm'
	else
		if isAny(args, ' ' .. what .. ' mm') then
			first = 'mm'
		else
			first = (what == 'snow' or
				precision(args['Jan ' .. what .. ' inch'] or '0') < 1)
					and 'cm'
					or 'mm'
		end
	end
	local second = 'inches'
	if not stripToNil(args['metric first']) then
		first, second = second, first
	end
	if is_first then
		if stripToNil(args['single line']) then
			first = first .. ' (' .. second .. ')'
		end
	else
		first = second
	end
	return base .. ' ' .. first
end

local function makeSources(frame, args)
	local source1 = stripToNil(args.source) or stripToNil(args['source 1'])
	local source2 = stripToNil(args['source 2']) or stripToNil(args['source2'])
	local result = '|-\n|colspan="14" style="text-align:center;font-size:95%;"|'
	local text
	if source1 or source2 then
		if source1 and source2 then
			text = 'Source 1: ' .. source1 .. '\n' .. result .. 'Source 2: ' .. source2
		else
			text = 'Source: ' .. (source1 and source1 or source2)
		end
	else
		text = frame:expandTemplate({ title = 'citation needed', args = {date = stripToNil(args.date)} })
	end
	return result .. text .. '\n|}'
end

local function getDefinitions(frame, args)
	-- Return a list of tables or strings that define each row.
	local navbar = require('Module:Navbar')._navbar
	local function _if(parm, a, b)
		return stripToNil(args[parm]) and a or b or ''
	end
	local function _ifset(parm, a)
		return stripToNil(args[parm]) and args[parm] or a
	end
	local function _ifany(suffix)
		return isAny(args, suffix)
	end
	return {

----------- HEADER ----------
'{| class="wikitable ' .. _if('open', '', 'collapsible' .. _if('collapsed', ' collapsed')) ..
'" style="width:' .. _ifset('width', '100%') ..
'; text-align:center; line-height: 1.2em; margin:' ..
_ifset('margin', 'auto') .. ';"' ..
_if('open',
	-- Following intentionally shows "{{{location}}}" if parameter is blank to alert editor.
	'\n|+Climate data for ' .. _if('location', args.location, '{{{location}}}'),
	'\n|-' ..
	'\n!colspan="14" | ' ..
	_if('name',
		navbar({'Climate data for ' .. _if('location', args.location, '{{{location}}}'), args.name, collapsible=1}),
		'Climate data for ' .. _if('location', args.location, '{{{location}}}')
	)
) ..
[=[

|-
!scope="row" |Month
!scope="col" |Jan
!scope="col" |Feb
!scope="col" |Mar
!scope="col" |Apr
!scope="col" |May
!scope="col" |Jun
!scope="col" |Jul
!scope="col" |Aug
!scope="col" |Sep
!scope="col" |Oct
!scope="col" |Nov
!scope="col" |Dec
!scope="col" style="border-left-width:medium" |Year
]=],

{---------- FIRST LINE MAXIMUM HUMIDEX ----------
	WANTROW = _ifany(' maximum humidex') and (_ifset('metric first') or _ifset('single line')),
	mode = 'basic',
	group_name = 'maximum humidex',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record high [[humidex]]',
	annual_mode = 'max',
},
{---------- FIRST LINE RECORD HIGH TEMPERATURES ----------
	WANTROW = _ifany(' record high C') or _ifany(' record high F'),
	mode = 'temperature',
	group_name = 'record high',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record high °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'max',
},
{---------- FIRST-SECOND LINE AVG MONTHLY MAXIMUM TEMPERATURES ----------
	WANTROW = _ifany(' avg record high C') or _ifany(' avg record high F'),
	mode = 'temperature',
	group_name = 'avg record high',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Mean maximum °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'max',
},
{---------- FIRST LINE AVERAGE HIGH TEMPERATURES ----------
	WANTROW = _ifany(' high C') or _ifany(' high F'),
	mode = 'temperature',
	group_name = 'high',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average high °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'avg',
},
{---------- FIRST LINE DAILY MEAN TEMPERATURES ----------
	WANTROW = _ifany(' mean C') or _ifany(' mean F'),
	mode = 'temperature',
	group_name = 'mean',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Daily mean °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'avg',
},
{---------- FIRST LINE AVERAGE LOW TEMPERATURES ----------
	WANTROW = _ifany(' low C') or _ifany(' low F'),
	mode = 'temperature',
	group_name = 'low',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average low °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'avg',
},
{---------- FIRST-SECOND LINE AVG MONTHLY MINIMUM TEMPERATURES ----------
	WANTROW = _ifany(' avg record low C') or _ifany(' avg record low F'),
	mode = 'temperature',
	group_name = 'avg record low',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Mean minimum °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'min',
},
{---------- FIRST LINE RECORD LOW TEMPERATURES ----------
	WANTROW = _ifany(' record low C') or _ifany(' record low F'),
	mode = 'temperature',
	group_name = 'record low',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record low °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'min',
},
{---------- FIRST LINE MINIMUM WIND CHILL ----------
	WANTROW = _ifany(' chill') and (_ifset('metric first') or _ifset('single line')),
	mode = 'basic',
	group_name = 'chill',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record low [[wind chill]]',
	annual_mode = 'min',
},
{---------- FIRST LINE TOTAL PRECIPITATION ----------
	WANTROW = _ifany(' precipitation cm') or _ifany(' precipitation mm') or _ifany(' precipitation inch'),
	mode = 'precipitation',
	group_name = 'precipitation',
	color_scheme = _ifset('precipitation colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	prefer_cm = precision(_ifset('Jan precipitation inch', '0')) < 1,
	label = makeLabel(args, true, 'Average [[precipitation]]', 'precipitation'),
	annual_mode = 'sum',
},
{---------- FIRST LINE RAINFALL ----------
	WANTROW = _ifany(' rain cm') or _ifany(' rain mm') or _ifany(' rain inch'),
	mode = 'precipitation',
	group_name = 'rain',
	color_scheme = _ifset('rain colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	prefer_cm = precision(_ifset('Jan rain inch', '0')) < 1,
	label = makeLabel(args, true, 'Average rainfall', 'rain'),
	annual_mode = 'sum',
},
{---------- FIRST LINE SNOWFALL ----------
	WANTROW = _ifany(' snow cm') or _ifany(' snow mm') or _ifany(' snow inch'),
	mode = 'precipitation',
	group_name = 'snow',
	prefer_cm = true,
	color_scheme = _ifset('snow colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	label = makeLabel(args, true, 'Average snowfall', 'snow'),
	annual_mode = 'sum',
},
{---------- SECOND LINE MAXIMUM HUMIDEX ----------
	WANTROW = not _ifset('single line') and _ifany(' maximum humidex'),
	mode = 'basic',
	group_name = 'maximum humidex',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = '[[Humidex]]',
	annual_mode = 'max',
	second_line = true,
},
{---------- SECOND LINE RECORD HIGH TEMPERATURES ----------
	WANTROW = not _ifset('single line') and (_ifany(' record high C') or _ifany(' record high F')),
	mode = 'temperature',
	group_name = 'record high',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record high °' .. _if('metric first', 'F', 'C'),
	annual_mode = 'max',
},
{---------- SECOND LINE AVERAGE HIGH TEMPERATURES ----------
	WANTROW = not _ifset('single line') and (_ifany(' high C') or _ifany(' high F')),
	mode = 'temperature',
	group_name = 'high',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average high °' .. _if('metric first', 'F', 'C'),
	annual_mode = 'avg',
},
{---------- SECOND LINE DAILY MEAN TEMPERATURES ----------
	WANTROW = not _ifset('single line') and (_ifany(' mean C') or _ifany(' mean F')),
	mode = 'temperature',
	group_name = 'mean',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Daily mean °' .. _if('metric first', 'F', 'C'),
	show = _if('metric first', '2', '1'),
	annual_mode = 'avg',
},
{---------- SECOND LINE AVERAGE LOW TEMPERATURES ----------
	WANTROW = not _ifset('single line') and (_ifany(' low C') or _ifany(' low F')),
	mode = 'temperature',
	group_name = 'low',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average low °' .. _if('metric first', 'F', 'C'),
	show = _if('metric first', '2', '1'),
	annual_mode = 'avg',
},
{---------- SECOND LINE RECORD LOW TEMPERATURES ----------
	WANTROW = not _ifset('single line') and (_ifany(' record low C') or _ifany(' record low F')),
	mode = 'temperature',
	group_name = 'record low',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Record low °' .. _if('metric first', 'F', 'C'),
	show = _if('metric first', '2', '1'),
	annual_mode = 'min',
},
{---------- SECOND LINE MINIMUM WIND CHILL ----------
	WANTROW = not _ifset('single line') and (_ifany(' chill') and _if('metric first')),
	mode = 'basic',
	group_name = 'chill',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = '[[Wind chill]]',
	annual_mode = 'min',
},
{---------- SECOND LINE TOTAL PRECIPITATION ----------
	WANTROW = not _ifset('single line') and (_ifany(' precipitation cm') or _ifany(' precipitation mm') or _ifany(' precipitation inch')),
	mode = 'precipitation',
	group_name = 'precipitation',
	second_line = true,
	color_scheme = _ifset('precipitation colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	prefer_cm = precision(_ifset('Jan precipitation inch', '0')) < 1,
	label = makeLabel(args, false, 'Average [[precipitation]]', 'precipitation'),
	annual_mode = 'sum',
},
{---------- SECOND LINE RAINFALL ----------
	WANTROW = not _ifset('single line') and (_ifany(' rain cm') or _ifany(' rain mm') or _ifany(' rain inch')),
	mode = 'precipitation',
	group_name = 'rain',
	second_line = true,
	color_scheme = _ifset('rain colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	prefer_cm = precision(_ifset('Jan rain inch', '0')) < 1,
	label = makeLabel(args, false, 'Average rainfall', 'rain'),
	annual_mode = 'sum',
},
{---------- SECOND LINE SNOWFALL ----------
	WANTROW = not _ifset('single line') and (_ifany(' snow cm') or _ifany(' snow mm') or _ifany(' snow inch')),
	mode = 'precipitation',
	group_name = 'snow',
	second_line = true,
	prefer_cm = true,
	color_scheme = _ifset('snow colour', 'p'),
	date_mode = true,
	scale_factor = '1',
	label = makeLabel(args, false, 'Average snowfall', 'snow'),
	annual_mode = 'sum',
},
{---------- PRECIPITATION DAYS ----------
	WANTROW = _ifany(' precipitation days'),
	mode = 'basic',
	group_name = 'precipitation days',
	color_scheme = _ifset('precip days colour', 'd'),
	date_mode = true,
	scale_factor = '1',
	label = 'Average precipitation days' .. _if('unit precipitation days', ' <span style="font-size:90%;" class="nowrap">(≥ ' .. _ifset('unit precipitation days', '') .. ')</span>'),
	annual_mode = 'sum',
},
{---------- RAINY DAYS ----------
	WANTROW = _ifany(' rain days'),
	mode = 'basic',
	group_name = 'rain days',
	color_scheme = _ifset('precip days colour', 'd'),
	date_mode = true,
	scale_factor = '1',
	label = 'Average rainy days' .. _if('unit rain days', ' <span style="font-size:90%;" class="nowrap">(≥ ' .. _ifset('unit rain days', '') .. ')</span>'),
	annual_mode = 'sum',
},
{---------- SNOWY DAYS ----------
	WANTROW = _ifany(' snow days'),
	mode = 'basic',
	group_name = 'snow days',
	color_scheme = _ifset('precip days colour', 'd'),
	date_mode = true,
	scale_factor = '1',
	label = 'Average snowy days' .. _if('unit snow days', ' <span style="font-size:90%;" class="nowrap">(≥ ' .. _ifset('unit snow days', '') .. ')</span>'),
	annual_mode = 'sum',
},
{---------- PERCENT RELATIVE HUMIDITY ----------
	WANTROW = _ifany(' humidity'),
	mode = 'basic',
	group_name = 'humidity',
	color_scheme = _ifset('humidity colour', 'h'),
	scale_factor = '1',
	label = 'Average [[relative humidity]] (%)' ..
		_if('time day', ' <span style="font-size:90%;" class="nowrap">(at ' .. _ifset('time day', '') .. ')</span>') ..
		_if('daily', ' <span style="font-size:90%;" class="nowrap">(daily average)</span>'),
	annual_mode = 'avg',
},
{---------- AFTERNOON PERCENT RELATIVE HUMIDITY ----------
	WANTROW = _ifany(' afthumidity'),
	mode = 'basic',
	group_name = 'afthumidity',
	color_scheme = _ifset('humidity colour', 'h'),
	scale_factor = '1',
	label = 'Average afternoon [[relative humidity]] (%)' ..
		_if('time day', ' <span style="font-size:90%;" class="nowrap">(at ' .. _ifset('time day', '') .. ')</span>') ..
		_if('daily', ' <span style="font-size:90%;" class="nowrap">(daily average)</span>'),
	annual_mode = 'avg',
},
{---------- FIRST LINE AVERAGE DEW POINT ----------
	WANTROW = _ifany(' dew point C') or _ifany(' dew point F'),
	mode = 'temperature',
	group_name = 'dew point',
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average [[dew point]] °' .. _if('metric first', 'C', 'F') .. _if('single line', ' (°' .. _if('metric first', 'F', 'C') .. ')'),
	annual_mode = 'avg',
},
{---------- SECOND LINE AVERAGE DEW POINT----------
	WANTROW = not _ifset('single line') and (_ifany(' dew point C') or _ifany(' dew point F')),
	mode = 'temperature',
	group_name = 'dew point',
	second_line = true,
	color_scheme = _ifset('temperature colour', 't'),
	scale_factor = '1',
	label = 'Average [[dew point]] °' .. _if('metric first', 'F', 'C'),
	show = _if('metric first', '2', '1'),
	annual_mode = 'avg',
},
{---------- MONTHLY SUNSHINE HOURS ----------
	WANTROW = _ifany(' sun'),
	mode = 'basic',
	group_name = 'sun',
	color_scheme = _ifset('sun colour', 's'),
	date_mode = true,
	scale_factor = '1',
	label = 'Mean monthly [[Sunshine duration|sunshine hours]]',
	annual_mode = 'sum',
},
{---------- DAILY SUNSHINE HOURS ----------
	WANTROW = _ifany('d sun'),
	mode = 'basic',
	group_name = 'd sun',
	color_scheme = _ifset('sun colour', 's'),
	include_space = false,
	scale_factor = '30.44',
	label = 'Mean daily [[Sunshine duration|sunshine hours]]',
	annual_mode = 'avg',
},
{---------- DAILY DAYLIGHT HOURS ----------
	WANTROW = _ifany(' light'),
	mode = 'basic',
	group_name = ' light',
	color_scheme = _ifset('sun colour', 's'),
	include_space = false,
	scale_factor = '30.44',
	label = 'Mean daily [[Daytime|daylight hours]]',
	annual_mode = 'avg',
},
{---------- PERCENT SUNSHINE ----------
	WANTROW = _ifany(' percentsun'),
	mode = 'basic',
	group_name = 'percentsun',
	color_scheme = _ifset('sun colour', 's'),
	scale_factor = '7.2',
	label = 'Percent [[Sunshine duration|possible sunshine]]',
	annual_mode = 'avg',
},
{---------- ULTRAVIOLET INDEX ----------
	WANTROW = _ifany(' uv'),
	mode = 'basic',
	group_name = 'uv',
	color_scheme = _ifset('uv colour', 'u'),
	scale_factor = '1',
	label = 'Average [[ultraviolet index]]',
	annual_mode = 'avg',
},
----------- SOURCES ----------
makeSources(frame, args),
}
end

local function makeFrame(self_args, parent_args)
	-- Kludge to pass arguments for a single row to buildRow.
	-- Later: Refactor buildRow so this is not needed.
	return {
		args = self_args,
		getParent = function (self) return makeFrame(parent_args, nil) end,
	}
end

local function main(frame)
	local buildRow = require('Module:Weather box/row').buildRow
	local args = frame:getParent().args
	local results = {}
	for i, def in ipairs(getDefinitions(frame, args)) do
		local row
		if type(def) == 'string' then
			row = def
		elseif def.WANTROW then
			row = buildRow(makeFrame(def, args))
		else
			row = ''
		end
		results[i] = row
	end
	return '<div>\n'..table.concat(results)..'\n</div>'  -- prevent Scribunto from inserting a blank line before the table
end

return {
	main = main,
}