require('Module:No globals')

local p = {}

local getArgs = require('Module:Arguments').getArgs

local function round(n, decimals)
	local pow = 10^(decimals or 0)
	return math.floor(n * pow + 0.5) / pow
end

function p.getMapParams(map, frame)
	if not map then
		error('The name of the location map definition to use must be specified', 2)
	end
	local moduletitle = mw.title.new('Module:Location map/data/' .. map)
	if not moduletitle then
		error(string.format('%q is not a valid name for a location map definition', map), 2)
	elseif moduletitle.exists then
		local mapData = mw.loadData('Module:Location map/data/' .. map)
		return function(name, params)
			if name == nil then
				return 'Module:Location map/data/' .. map
			elseif mapData[name] == nil then
				return ''
			elseif params then
				return mw.message.newRawMessage(tostring(mapData[name]), unpack(params)):plain()
			else
				return mapData[name]
			end
		end
	else
		error('Unable to find the specified location map definition: "Module:Location map/data/' .. map .. '" does not exist', 2)
	end
end

function p.data(frame, args, map)
	if not args then
		args = getArgs(frame, {frameOnly = true})
	end
	if not map then
		map = p.getMapParams(args[1], frame)
	end
	local params = {}
	for k,v in ipairs(args) do
		if k > 2 then
			params[k-2] = v
		end
	end
	return map(args[2], #params ~= 0 and params)
end

local hemisphereMultipliers = {
	longitude = { W = -1, w = -1, E = 1, e = 1 },
	latitude = { S = -1, s = -1, N = 1, n = 1 }
}

local function decdeg(degrees, minutes, seconds, hemisphere, decimal, direction)
	if decimal then
		if degrees then
			error('Decimal and DMS degrees cannot both be provided for ' .. direction, 2)
		elseif minutes then
			error('Minutes can only be provided with DMS degrees for ' .. direction, 2)
		elseif seconds then
			error('Seconds can only be provided with DMS degrees for ' .. direction, 2)
		elseif hemisphere then
			error('A hemisphere can only be provided with DMS degrees for ' .. direction, 2)
		end
		local retval = tonumber(decimal)
		if retval then
			return retval
		end
		error('The value "' .. decimal .. '" provided for ' .. direction .. ' is not valid', 2)
	elseif seconds and not minutes then
		error('Seconds were provided for ' .. direction .. ' without minutes also being provided', 2)
	elseif not degrees then
		if minutes then
			error('Minutes were provided for ' .. direction .. ' without degrees also being provided', 2)
		elseif hemisphere then
			error('A hemisphere was provided for ' .. direction .. ' without degrees also being provided', 2)
		end
		return nil
	end
	decimal = tonumber(degrees)
	if not decimal then
		error('The degree value "' .. degrees .. '" provided for ' .. direction .. ' is not valid', 2)
	elseif minutes and not tonumber(minutes) then
		error('The minute value "' .. minutes .. '" provided for ' .. direction .. ' is not valid', 2)
	elseif seconds and not tonumber(seconds) then
		error('The second value "' .. seconds .. '" provided for ' .. direction .. ' is not valid', 2)
	end
	decimal = decimal + (minutes or 0)/60 + (seconds or 0)/3600
	if hemisphere then
		local multiplier = hemisphereMultipliers[direction][hemisphere]
		if not multiplier then
			error('The hemisphere "' .. hemisphere .. '" provided for ' .. direction .. ' is not valid', 2)
		end
		decimal = decimal * multiplier
	end
	return decimal
end

-- Finds a parameter in a transclusion of {{Coord}}.
local function coord2text(para,coord) -- this should be changed for languages which do not use Arabic numerals or the degree sign
	local result = mw.text.split(mw.ustring.match(coord,'%-?[%.%d]+°[NS] %-?[%.%d]+°[EW]') or '', '[ °]')
	if para == 'longitude' then result = {result[3], result[4]} end
	if not tonumber(result[1]) or not result[2] then return error('Malformed coordinates value', 2) end
	return tonumber(result[1]) * hemisphereMultipliers[para][result[2]]
end

-- effectively make removeBlanks false for caption and maplink, and true for everything else
-- if useWikidata is present but blank, convert it to false instead of nil
-- p.top, p.bottom, and their callers need to use this
function p.valueFunc(key, value)
	if value then
		value = mw.text.trim(value)
	end
	if value ~= '' or key == 'caption' or key == 'maplink' then
		return value
	elseif key == 'useWikidata' then
		return false
	end
end

local function getContainerImage(args, map)
	if args.AlternativeMap then
		return args.AlternativeMap
	elseif args.relief and map('image1') ~= '' then
		return map('image1')
	else
		return map('image')
	end
end

function p.top(frame, args, map)
	if not args then
		args = getArgs(frame, {frameOnly = true, valueFunc = p.valueFunc})
	end
	if not map then
		map = p.getMapParams(args[1], frame)
	end
	local width
	local default_as_number = tonumber(mw.ustring.match(tostring(args.default_width),"%d*"))
	if not args.width then
		width = round((default_as_number or 240) * (tonumber(map('defaultscale')) or 1))
	elseif mw.ustring.sub(args.width, -2) == 'px' then
		width = mw.ustring.sub(args.width, 1, -3)
	else
		width = args.width
	end
	local width_as_number = tonumber(mw.ustring.match(tostring(width),"%d*")) or 0;
    if width_as_number == 0 then
    	-- check to see if width is junk. If it is, then use default calculation
    	width = round((default_as_number or 240) * (tonumber(map('defaultscale')) or 1))
    	width_as_number = tonumber(mw.ustring.match(tostring(width),"%d*")) or 0;
    end	
    if args.max_width ~= "" and args.max_width ~= nil then
        -- check to see if width bigger than max_width
        local max_as_number = tonumber(mw.ustring.match(args.max_width,"%d*")) or 0;
        if width_as_number>max_as_number and max_as_number>0 then
            width = args.max_width;
        end
    end
	local retval = frame:extensionTag{name = 'templatestyles', args = {src = 'Template:Location map/styles.css'}}
	if args.float == 'center' then
		retval = retval .. '<div class="center">'
	end
	if args.caption and args.caption ~= '' and args.border ~= 'infobox' then
		retval = retval .. '<div class="locmap noviewer thumb '
		if args.float == '"left"' or args.float == 'left' then
			retval = retval .. 'tleft'
		elseif args.float == '"center"' or args.float == 'center' or args.float == '"none"' or args.float == 'none' then
			retval = retval .. 'tnone'
		else
			retval = retval .. 'tright'
		end
		retval = retval .. '"><div class="thumbinner" style="width:' .. (width + 2) .. 'px'
		if args.border == 'none' then
			retval = retval .. ';border:none'
		elseif args.border then
			retval = retval .. ';border-color:' .. args.border
		end
		retval = retval .. '"><div style="position:relative;width:' .. width .. 'px' .. (args.border ~= 'none' and ';border:1px solid lightgray">' or '">')
	else
		retval = retval .. '<div class="locmap" style="width:' .. width .. 'px;'
		if args.float == '"left"' or args.float == 'left' then
			retval = retval .. 'float:left;clear:left'
		elseif args.float == '"center"' or args.float == 'center' then
			retval = retval .. 'float:none;clear:both;margin-left:auto;margin-right:auto'
		elseif args.float == '"none"' or args.float == 'none' then
			retval = retval .. 'float:none;clear:none'
		else
			retval = retval .. 'float:right;clear:right'
		end
		retval = retval .. '"><div style="width:' .. width .. 'px;padding:0"><div style="position:relative;width:' .. width .. 'px">'
	end
	local image = getContainerImage(args, map)
	local currentTitle = mw.title.getCurrentTitle()
	retval = string.format(
		'%s[[File:%s|%spx|%s%s]]',
		retval,
		image,
		width,
		args.alt or ((args.label or currentTitle.text) .. ' is located in ' .. map('name')),
		args.maplink and ('|link=' .. args.maplink) or ''
	)
	if args.caption and args.caption ~= '' then
		if (currentTitle.namespace == 0) and mw.ustring.find(args.caption, '##') then
			retval = retval .. '[[Category:Pages using location map with a double number sign in the caption]]'
		end
	end
	if args.overlay_image then
		return retval .. '<div style="position:absolute;top:0;left:0">[[File:' .. args.overlay_image .. '|' .. width .. 'px]]</div>'
	else
		return retval
	end
end

function p.bottom(frame, args, map)
	if not args then
		args = getArgs(frame, {frameOnly = true, valueFunc = p.valueFunc})
	end
	if not map then
		map = p.getMapParams(args[1], frame)
	end
	local retval = '</div>'
	local currentTitle = mw.title.getCurrentTitle()
	if not args.caption or args.border == 'infobox' then
		if args.border then
			retval = retval .. '<div style="padding-top:0.2em">'
		else
			retval = retval .. '<div style="font-size:91%;padding-top:3px">'
		end
		retval = retval
		.. (args.caption or (args.label or currentTitle.text) .. ' (' .. map('name') .. ')')
		.. '</div>'
	elseif args.caption ~= ''  then
		-- This is not the pipe trick. We're creating a link with no text on purpose, so that CSS can give us a nice image
		retval = retval .. '<div class="thumbcaption"><div class="magnify">[[:File:' .. getContainerImage(args, map) .. '| ]]</div>' .. args.caption .. '</div>'
	end

	if args.switcherLabel then
		retval = retval .. '<span class="switcher-label" style="display:none">' .. args.switcherLabel .. '</span>'
	elseif args.autoSwitcherLabel then
		retval = retval .. '<span class="switcher-label" style="display:none">Show map of ' .. map('name') .. '</span>'
	end
	
	retval = retval .. '</div></div>'
	if args.caption_undefined then
		mw.log('Removed parameter caption_undefined used.')
		local parent = frame:getParent()
		if parent then
			mw.log('Parent is ' .. parent:getTitle())
		end
		mw.logObject(args, 'args')
		if currentTitle.namespace == 0 then
		    retval = retval .. '[[Category:Location maps with removed parameters|caption_undefined]]'
		end
	end
	if map('skew') ~= '' or map('lat_skew') ~= '' or map('crosses180') ~= '' or map('type') ~= '' then
		mw.log('Removed parameter used in map definition ' .. map())
		if currentTitle.namespace == 0 then
		    local key = (map('skew') ~= '' and 'skew' or '') ..
					(map('lat_skew') ~= '' and 'lat_skew' or '') ..
					(map('crosses180') ~= '' and 'crosses180' or '') ..
					(map('type') ~= '' and 'type' or '')
		    retval = retval .. '[[Category:Location maps with removed parameters|' .. key .. ' ]]'
		end
	end
	if string.find(map('name'), '|', 1, true) then
		mw.log('Pipe used in name of map definition ' .. map())
		if currentTitle.namespace == 0 then
		   retval = retval .. '[[Category:Location maps with a name containing a pipe]]'
		end
	end
	if args.float == 'center' then
		retval = retval .. '</div>'
	end
	return retval
end

local function markOuterDiv(x, y, imageDiv, labelDiv)
	return mw.html.create('div')
		:addClass('od')
		:cssText('top:' .. round(y, 3) .. '%;left:' .. round(x, 3) .. '%')
		:node(imageDiv)
		:node(labelDiv)
end

local function markImageDiv(mark, marksize, label, link, alt, title)
	local builder = mw.html.create('div')
		:addClass('id')
		:cssText('left:-' .. round(marksize / 2) .. 'px;top:-' .. round(marksize / 2) .. 'px')
		:attr('title', title)
	if marksize ~= 0 then
		builder:wikitext(string.format(
			'[[File:%s|%dx%dpx|%s|link=%s%s]]',
			mark,
			marksize,
			marksize,
			label,
			link,
			alt and ('|alt=' .. alt) or ''
		))
	end
	return builder
end

local function markLabelDiv(label, label_size, label_width, position, background, x, marksize)
	if tonumber(label_size) == 0 then
		return mw.html.create('div'):addClass('l0'):wikitext(label)
	end
	local builder = mw.html.create('div')
		:cssText('font-size:' .. label_size .. '%;width:' .. label_width .. 'em')
	local distance = round(marksize / 2 + 1)
	if position == 'top' then -- specified top
		builder:addClass('pv'):cssText('bottom:' .. distance .. 'px;left:' .. (-label_width / 2) .. 'em')
	elseif position == 'bottom' then -- specified bottom
		builder:addClass('pv'):cssText('top:' .. distance .. 'px;left:' .. (-label_width / 2) .. 'em')
	elseif position == 'left' or (tonumber(x) > 70 and position ~= 'right') then -- specified left or autodetected to left
		builder:addClass('pl'):cssText('right:' .. distance .. 'px')
	else -- specified right or autodetected to right
		builder:addClass('pr'):cssText('left:' .. distance .. 'px')
	end
	builder = builder:tag('div')
		:wikitext(label)
	if background then
		builder:cssText('background-color:' .. background)
	end
	return builder:done()
end

local function getX(longitude, left, right)
	local width = (right - left) % 360
	if width == 0 then
		width = 360
	end
	local distanceFromLeft = (longitude - left) % 360
	-- the distance needed past the map to the right equals distanceFromLeft - width. the distance needed past the map to the left equals 360 - distanceFromLeft. to minimize page stretching, go whichever way is shorter
	if distanceFromLeft - width / 2 >= 180 then
		distanceFromLeft = distanceFromLeft - 360
	end
	return 100 * distanceFromLeft / width
end

local function getY(latitude, top, bottom)
	return 100 * (top - latitude) / (top - bottom)
end

function p.mark(frame, args, map)
	if not args then
		args = getArgs(frame, {wrappers = 'Template:Location map~'})
	end
	local mapnames = {}
	if not map then
		if args[1] then
			map = {}
			for mapname in mw.text.gsplit(args[1], '#', true) do
				map[#map + 1] = p.getMapParams(mw.ustring.gsub(mapname, '^%s*(.-)%s*$', '%1'), frame)
				mapnames[#mapnames + 1] = mapname
			end
			if #map == 1 then map = map[1] end
		else
			map = p.getMapParams('World', frame)
			args[1] = 'World'
		end
	end
	if type(map) == 'table' then
		local outputs = {}
		local oldargs = args[1]
		for k,v in ipairs(map) do
			args[1] = mapnames[k]
			outputs[k] = tostring(p.mark(frame, args, v))
		end
		args[1] = oldargs
		return table.concat(outputs, '#PlaceList#') .. '#PlaceList#'
	end
	local x, y, longitude, latitude
	longitude = decdeg(args.lon_deg, args.lon_min, args.lon_sec, args.lon_dir, args.long, 'longitude')
	latitude = decdeg(args.lat_deg, args.lat_min, args.lat_sec, args.lat_dir, args.lat, 'latitude')
	if args.excludefrom then
		-- If this mark is to be excluded from certain maps entirely (useful in the context of multiple maps)
		for exclusionmap in mw.text.gsplit(args.excludefrom, '#', true) do
			-- Check if this map is excluded. If so, return an empty string.
			if args[1] == exclusionmap then
				return ''
			end
		end
			
	end
	local builder = mw.html.create()
	local currentTitle = mw.title.getCurrentTitle()
	if args.coordinates then
--		Temporarily removed to facilitate infobox conversion. See [[Wikipedia:Coordinates in infoboxes]]

--		if longitude or latitude then
--			error('Coordinates from [[Module:Coordinates]] and individual coordinates cannot both be provided')
--		end
		longitude = coord2text('longitude', args.coordinates)
		latitude = coord2text('latitude', args.coordinates)
	elseif not longitude and not latitude and args.useWikidata then
		-- If they didn't provide either coordinate, try Wikidata. If they provided one but not the other, don't.
		local entity = mw.wikibase.getEntity()
		if entity and entity.claims and entity.claims.P625 and entity.claims.P625[1].mainsnak.snaktype == 'value' then
			local value = entity.claims.P625[1].mainsnak.datavalue.value
			longitude, latitude = value.longitude, value.latitude
		end
		if args.link and (currentTitle.namespace == 0) then
			builder:wikitext('[[Category:Location maps with linked markers with coordinates from Wikidata]]')	
		end
	end
	if not longitude then
		error('No value was provided for longitude')
	elseif not latitude then
		error('No value was provided for latitude')
	end
	if currentTitle.namespace > 0 then
		if (not args.lon_deg) ~= (not args.lat_deg) then
			builder:wikitext('[[Category:Location maps with different longitude and latitude precisions|Degrees]]')
		elseif (not args.lon_min) ~= (not args.lat_min) then
			builder:wikitext('[[Category:Location maps with different longitude and latitude precisions|Minutes]]')
		elseif (not args.lon_sec) ~= (not args.lat_sec) then
			builder:wikitext('[[Category:Location maps with different longitude and latitude precisions|Seconds]]')
		elseif (not args.lon_dir) ~= (not args.lat_dir) then
			builder:wikitext('[[Category:Location maps with different longitude and latitude precisions|Hemisphere]]')
		elseif (not args.long) ~= (not args.lat) then
			builder:wikitext('[[Category:Location maps with different longitude and latitude precisions|Decimal]]')
		end
	end
	if args.skew or args.lon_shift or args.markhigh then
		mw.log('Removed parameter used in invocation.')
		local parent = frame:getParent()
		if parent then
			mw.log('Parent is ' .. parent:getTitle())
		end
		mw.logObject(args, 'args')
		if currentTitle.namespace == 0 then
			local key = (args.skew and 'skew' or '') ..
						(args.lon_shift and 'lon_shift' or '') ..
						(args.markhigh and 'markhigh' or '')
			builder:wikitext('[[Category:Location maps with removed parameters|' .. key ..' ]]')
		end
	end
	if map('x') ~= '' then
		x = tonumber(mw.ext.ParserFunctions.expr(map('x', { latitude, longitude })))
	else
		x = tonumber(getX(longitude, map('left'), map('right')))
	end
	if map('y') ~= '' then
		y = tonumber(mw.ext.ParserFunctions.expr(map('y', { latitude, longitude })))
	else
		y = tonumber(getY(latitude, map('top'), map('bottom')))
	end
	if (x < 0 or x > 100 or y < 0 or y > 100) and not args.outside then
		mw.log('Mark placed outside map boundaries without outside flag set. x = ' .. x .. ', y = ' .. y)
		local parent = frame:getParent()
		if parent then
			mw.log('Parent is ' .. parent:getTitle())
		end
		mw.logObject(args, 'args')
		if currentTitle.namespace == 0 then
			local key = currentTitle.prefixedText
			builder:wikitext('[[Category:Location maps with marks outside map and outside parameter not set|' .. key .. ' ]]')
		end
	end
	local mark = args.mark or map('mark')
	if mark == '' then
		mark = 'Red pog.svg'
	end
	local marksize = tonumber(args.marksize) or tonumber(map('marksize')) or 8
	local imageDiv = markImageDiv(mark, marksize, args.label or mw.title.getCurrentTitle().text, args.link or '', args.alt, args[2])
	local labelDiv
	if args.label and args.position ~= 'none' then
		labelDiv = markLabelDiv(args.label, args.label_size or 91, args.label_width or 6, args.position, args.background, x, marksize)
	end
	return builder:node(markOuterDiv(x, y, imageDiv, labelDiv))
end

local function switcherSeparate(s)
	if s == nil then return {} end
	local retval = {}
	for i in string.gmatch(s .. '#', '([^#]*)#') do
		i = mw.text.trim(i)
		retval[#retval + 1] = (i ~= '' and i)
	end
	return retval
end

function p.main(frame, args, map)
	local caption_list = {}
	if not args then
		args = getArgs(frame, {wrappers = 'Template:Location map', valueFunc = p.valueFunc})
	end
	if args.useWikidata == nil then
		args.useWikidata = true
	end
	if not map then
		if args[1] then
			map = {}
			for mapname in string.gmatch(args[1], '[^#]+') do
				map[#map + 1] = p.getMapParams(mw.ustring.gsub(mapname, '^%s*(.-)%s*$', '%1'), frame)
			end
			if args['caption'] then
				if args['caption'] == "" then
					while #caption_list < #map do
						caption_list[#caption_list + 1] = args['caption']
					end
				else
					for caption in mw.text.gsplit(args['caption'], '##', true) do
						caption_list[#caption_list + 1] = caption
					end
				end
			end
			if #map == 1 then map = map[1] end
		else
			map = p.getMapParams('World', frame)
		end
	end
	if type(map) == 'table' then
		local altmaps = switcherSeparate(args.AlternativeMap)
		if #altmaps > #map then
			error(string.format('%d AlternativeMaps were provided, but only %d maps were provided', #altmaps, #map))
		end
		local overlays = switcherSeparate(args.overlay_image)
		if #overlays > #map then
			error(string.format('%d overlay_images were provided, but only %d maps were provided', #overlays, #map))
		end
		if #caption_list > #map then
			error(string.format('%d captions were provided, but only %d maps were provided', #caption_list, #map))
		end
		local outputs = {}
		args.autoSwitcherLabel = true
		for k,v in ipairs(map) do
			args.AlternativeMap = altmaps[k]
			args.overlay_image = overlays[k]
			args.caption = caption_list[k]
			outputs[k] = p.main(frame, args, v)
		end
		return '<div class="switcher-container">' .. table.concat(outputs) .. '</div>'
	else
		return p.top(frame, args, map) .. tostring( p.mark(frame, args, map) ) .. p.bottom(frame, args, map)
	end
end

return p