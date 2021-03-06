-- Note: Originally written on English Wikipedia at https://en.wikipedia.org/wiki/Module:Mapframe

--[[----------------------------------------------------------------------------
 ##### Localisation (L10n) settings #####
 Replace values in quotes ("") with localised values
----------------------------------------------------------------------------]]--
local L10n = {}

-- Modue dependencies
local transcluder -- local copy of https://www.mediawiki.org/wiki/Module:Transcluder loaded lazily
-- "Module:No globals" should not be used, at least until all other modules which require this module are not using globals.

-- Template parameter names (unnumbered versions only)
--   Specify each as either a single string, or a table of strings (aliases)
--   Aliases are checked left-to-right, i.e. `{ "one", "two" }` is equivalent to using `{{{one| {{{two|}}} }}}` in a template
L10n.para = {
	display		= "display",
	type		= "type",
	id              = { "id", "ids" },
	from		= "from",
	raw		= "raw",
	title		= "title",
	description	= "description",
	strokeColor     = { "stroke-color", "stroke-colour" },
	strokeWidth	= "stroke-width",
	strokeOpacity = "stroke-opacity",
	fill        = "fill",
	fillOpacity     = "fill-opacity",
	coord		= "coord",
	marker		= "marker",
	markerColor	= { "marker-color", "marker-colour" },
	markerSize = "marker-size",
	radius      = { "radius", "radius_m" },
	radiusKm    = "radius_km",
	radiusFt    = "radius_ft",
	radiusMi    = "radius_mi",
	edges       = "edges",
	text		= "text",
	icon		= "icon",
	zoom		= "zoom",
	frame		= "frame",
	plain		= "plain",
	frameWidth	= "frame-width",
	frameHeight	= "frame-height",
	frameCoordinates = { "frame-coordinates", "frame-coord" }, 
	frameLatitude	= { "frame-lat", "frame-latitude" },
	frameLongitude	= { "frame-long", "frame-longitude" },
	frameAlign	= "frame-align",
	switch = "switch",
}

-- Names of other templates this module depends on
L10n.template = {
	Coord		= "coord" -- lowercase template name
}

-- Error messages
L10n.error = {
	badDisplayPara    = "Invalid display parameter",
	noCoords	      = "Coordinates must be specified on Wikidata or in |" .. ( type(L10n.para.coord)== 'table' and L10n.para.coord[1] or L10n.para.coord ) .. "=",
	wikidataCoords    = "Coordinates not found on Wikidata",
	noCircleCoords    = "Circle centre coordinates must be specified, or available via Wikidata",
	negativeRadius    = "Circle radius must be a positive number",
	noRadius          = "Circle radius must be specified",
	negativeEdges     = "Circle edges must be a positive number",
	noSwitchPara      = "Found only one switch value in |" .. ( type(L10n.para.switch)== 'table' and L10n.para.switch[1] or L10n.para.switch ) .. "=",
	oneSwitchLabel    = "Found only one label in |" .. ( type(L10n.para.switch)== 'table' and L10n.para.switch[1] or L10n.para.switch ) .. "=",
	noSwitchLists     = "At least one parameter must have a SWITCH: list",
	switchMismatches  = "All SWITCH: lists must have the same number of values",
	
	 -- "%s" and "%d" tokens will be replaced with strings and numbers when used
	oneSwitchValue    = "Found only one switch value in |%s=",
	fewerSwitchLabels = "Found %d switch values but only %d labels in |" .. ( type(L10n.para.switch)== 'table' and L10n.para.switch[1] or L10n.para.switch ) .. "=",
	noNamedCoords     = "No named coordinates found in %s"
}

-- Other strings
L10n.str = {
	-- valid values for display parameter, e.g. (|display=inline) or (|display=title) or (|display=inline,title) or (|display=title,inline)
	inline		= "inline",			
	title		= "title",	
	dsep		= ",",			-- separator between inline and title (comma in the example above)

	-- valid values for type paramter
	line		= "line",		-- geoline feature (e.g. a road)
	shape		= "shape",		-- geoshape feature (e.g. a state or province)
	shapeInverse	= "shape-inverse",	-- geomask feature (the inverse of a geoshape)
	data		= "data",		-- geoJSON data page on Commons
	point		= "point",		-- single point feature (coordinates)
	circle      = "circle",     -- circular area around a point
	named       = "named",      -- all named coordinates in an article or section
	
	-- Keyword to indicate a switch list. Must NOT use the special characters ^$()%.[]*+-?
	switch = "SWITCH",
	
	-- valid values for icon, frame, and plain parameters
	affirmedWords = ' '..table.concat({
		"add",
		"added",
		"affirm",
		"affirmed",
		"include",
		"included",
		"on",
		"true",
		"yes",
		"y"
	}, ' ')..' ',
	declinedWords = ' '..table.concat({
		"decline",
		"declined",
		"exclude",
		"excluded",
		"false",
		"none",
		"not",
		"no",
		"n",
		"off",
		"omit",
		"omitted",
		"remove",
		"removed"
	}, ' ')..' '
}

-- Default values for parameters
L10n.defaults = {
	display		= L10n.str.inline,
	text		= "Map",
	frameWidth	= "300",
	frameHeight	= "200",
	markerColor	= "5E74F3",
	markerSize	= nil,
	strokeColor	= "#ff0000",
	strokeWidth	= 6,
	edges = 32 -- number of edges used to approximate a circle
}

-- #### End of L10n settings ####

--[[----------------------------------------------------------------------------
 Utility methods
----------------------------------------------------------------------------]]--
local util = {}

--[[
Looks up a parameter value based on the id (a key from the L10n.para table) and
optionally a suffix, for parameters that can be suffixed (e.g. type2 is type
with suffix 2).
@param {table} args  key-value pairs of parameter names and their values 
@param {string} param_id  id for parameter name (key from the L10n.para table)
@param {string} [suffix]  suffix for parameter name
@returns {string|nil} parameter value if found, or nil if not found 
]]--
function util.getParameterValue(args, param_id, suffix)
	suffix = suffix or ''
	if type( L10n.para[param_id] ) ~= 'table' then
		return args[L10n.para[param_id]..suffix]
	end
	for _i, paramAlias in ipairs(L10n.para[param_id]) do
		if args[paramAlias..suffix] then
			return args[paramAlias..suffix]
		end
	end
	return nil
end	

--[[
Trim whitespace from args, and remove empty args. Also fix control characters.
@param {table} argsTable
@returns {table} trimmed args table
]]--
function util.trimArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				-- control characters inside json need to be escaped, but stripping them is simpler
				-- See also T214984
				-- However, *don't* strip control characters from wikitext or you'll break strip markers
				cleanArgs[key] = (not util.matchesParam('text', key)) and val:gsub('%c',' ') or val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

--[[
Check if a parameter name matches an unlocalized parameter key
@param {string} key - the unlocalized parameter name to search through
@param {string} name - the localized parameter name to check
@param {string|nil} - an optional suffix to apply to the value(s) from the localization key
@returns {boolean} true if the name matches the parameter, false otherwise
]]--
function util.matchesParam(key, name, suffix)
	local param = L10n.para[key]
	suffix = suffix or ''
	if type(param) == 'table' then
		for _, v in pairs(param) do
			if (v .. suffix) == name then return true end
		end
		return false
	end
	return ((param .. suffix) == name)
end

--[[
Check if a value is affirmed (one of the values in L10n.str.affirmedWords)
@param {string} val  Value to be checked
@returns {boolean} true if affirmed, false otherwise
]]--
function util.isAffirmed(val)
	if not(val) then return false end
	return string.find(L10n.str.affirmedWords, ' '..val..' ', 1, true ) and true or false
end

--[[
Check if a value is declined (one of the values in L10n.str.declinedWords)
@param {string} val  Value to be checked
@returns {boolean} true if declined, false otherwise
]]--
function util.isDeclined(val)
	if not(val) then return false end
	return string.find(L10n.str.declinedWords , ' '..val..' ', 1, true ) and true or false
end

--[[
Recursively extract coord templates which have a name parameter.
@param {string} wikitext
@returns {table} table sequence of coord templates
]]--
function util.extractCoordTemplates(wikitext)
	local output = {}
	local templates = mw.ustring.gmatch(wikitext, '{%b{}}')
	local subtemplates = {}
	for template in templates do
		local name = mw.ustring.match(template, '{{([^}|]+)') -- get the template name
		local nameParam = mw.ustring.match(template, "|%s*name%s*=%s*[^}|]+")
		if mw.ustring.lower(mw.text.trim(name)) == L10n.template.Coord then
			if nameParam then table.insert(output, template) end
		elseif mw.ustring.find(template, L10n.template.Coord) then
			local subOutput = util.extractCoordTemplates(mw.ustring.sub(template, 2))
			for _, t in pairs(subOutput) do
				table.insert(output, t)
			end
		end
	end
	-- ensure coords are not using title display
	for k, v in pairs(output) do
		output[k] = mw.ustring.gsub(v, "|%s*display%s*=[^|}]+", "|display=inline")
	end
	return output
end

--[[
Gets all named coordiates from a page or a section of a page.
@param {string|nil} page  Page name, or name#section, to get named coordinates
  from. If the name is omitted, i.e. #section or nil or empty string, then
  the current page will be used.
@returns {table} sequence of {coord, name, description} tables where coord is
  the coordinates in a format suitable for #util.parseCoords, name is a string,
  and description is a string (coordinates in a format suitable for displaying
  to the reader). If for some reason the name can't be found, the description
  is nil and the name contains display-format coordinates.
@throws {L10n.error.noNamedCoords} if no named coordinates are found.
]]--
function util.getNamedCoords(page)
	if transcluder == nil then
		-- load [[Module:Transcluder]] lazily so it is only transcluded on pages that
		-- actually use named coordinates
		transcluder = require("Module:Transcluder")
	end
	local parts = mw.text.split(page or "", "#", true)
	local name = parts[1] == "" and mw.title.getCurrentTitle().prefixedText or parts[1]
	local section = parts[2]
	local pageWikitext = transcluder.get(section and name.."#"..section or name)
	local coordTemplates = util.extractCoordTemplates(pageWikitext)
	if #coordTemplates == 0 then error(string.format(L10n.error.noNamedCoords, page or name), 0) end
	local frame = mw.getCurrentFrame()
	local sep = "________"
	local expandedContent = frame:preprocess(table.concat(coordTemplates, sep))
	local expandedTemplates = mw.text.split(expandedContent, sep)
	local namedCoords = {}
	for _, expandedTemplate in pairs(expandedTemplates) do
		local coord = mw.ustring.match(expandedTemplate, "<span class=\"geo%-dec\".->(.-)</span>")
		if coord then
			local name = mw.ustring.match(expandedTemplate, "<span class=\"fn org\">(.-)</span>") or coord
			local description = name ~= coord and coord
			local coord = mw.ustring.gsub(coord, "[° ]", "_")
			table.insert(namedCoords, {coord=coord, name=name, description=description})
		end
	end
	if #namedCoords == 0 then error(string.format(L10n.error.noNamedCoords, page or name), 0) end
	return namedCoords
end

--[[
Parse coordinate values from the params passed in a GeoHack url (such as
//tools.wmflabs.org/geohack/geohack.php?pagename=Example&params=1_2_N_3_4_W_ or
//tools.wmflabs.org/geohack/geohack.php?pagename=Example&params=1.23_S_4.56_E_ )
@param {string} coords
@returns {number, number} latitude, longitude
]]--
function util.parseCoords(coords)
	local parts = mw.text.split((mw.ustring.match(coords,'[_%.%d]+[NS][_%.%d]+[EW]') or ''), '_')

	local lat_d = tonumber(parts[1])
	local lat_m = tonumber(parts[2]) -- nil if coords are in decimal format
	local lat_s = lat_m and tonumber(parts[3]) -- nil if coords are either in decimal format or degrees and minutes only
	local lat = lat_d + (lat_m or 0)/60 + (lat_s or 0)/3600
	if parts[#parts/2] == 'S' then
		lat = lat * -1
	end

	local long_d = tonumber(parts[1+#parts/2])
	local long_m = tonumber(parts[2+#parts/2]) -- nil if coords are in decimal format
	local long_s = long_m and tonumber(parts[3+#parts/2]) -- nil if coords are either in decimal format or degrees and minutes only
	local long = long_d + (long_m or 0)/60 + (long_s or 0)/3600
	if parts[#parts] == 'W' then
		long = long * -1
	end

	return lat, long
end

--[[
Get coordinates from a Wikidata item
@param {string} item_id  Wikidata item id (Q number)
@returns {number, number} latitude, longitude
@throws {L10n.error.noCoords} if item_id is invalid or the item does not exist
@throws {L10n.error.wikidataCoords} if the the item does not have a P625
  statement (coordinates), or it is set to "no value"
]]--
function util.wikidataCoords(item_id)
	if not(mw.wikibase.isValidEntityId(item_id)) or not(mw.wikibase.entityExists(item_id)) then
		error(L10n.error.noCoords, 0)
	end
	local coordStatements = mw.wikibase.getBestStatements(item_id, 'P625')
	if not coordStatements or #coordStatements == 0 then
		error(L10n.error.wikidataCoords, 0)
	end
	local hasNoValue = ( coordStatements[1].mainsnak and coordStatements[1].mainsnak.snaktype == 'novalue' )
	if hasNoValue then
		error(L10n.error.wikidataCoords, 0)
	end
	local wdCoords = coordStatements[1]['mainsnak']['datavalue']['value']
	return tonumber(wdCoords['latitude']), tonumber(wdCoords['longitude'])
end

--[[
Creates a polygon that approximates a circle
@param {number} lat  Latitude
@param {number} long  Longitude
@param {number} radius  Radius in metres
@param {number} n  Number of edges for the polygon
@returns {table} sequence of {latitude, longitude} table sequences, where
  latitude and longitude are both numbers
]]--
function util.circleToPolygon(lat, long, radius, n) -- n is number of edges
	-- Based on https://github.com/gabzim/circle-to-polygon, ISC licence
	
	local function offset(cLat, cLon, distance, bearing)
		local lat1 = math.rad(cLat)
		local lon1 = math.rad(cLon)
		local dByR = distance / 6378137 -- distance divided by 6378137 (radius of the earth) wgs84
		local lat = math.asin(
			math.sin(lat1) * math.cos(dByR) +
			math.cos(lat1) * math.sin(dByR) * math.cos(bearing)
		)
		local lon = lon1 + math.atan2(
			math.sin(bearing) * math.sin(dByR) * math.cos(lat1),
			math.cos(dByR) - math.sin(lat1) * math.sin(lat)
		)
		return {math.deg(lon), math.deg(lat)}
	end
	
	local coordinates = {};
	local i = 0;
	while i < n do
		table.insert(coordinates,
			offset(lat, long, radius, (2*math.pi*i*-1)/n)
		)
		i = i + 1
	end
	table.insert(coordinates, offset(lat, long, radius, 0))
	return coordinates
end


--[[
Get the number of key-value pairs in a table, which might not be a sequence.
@param {table} t
@returns {number} count of key-value pairs
]]--
function util.tableCount(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

--[[
For a table where the values are all tables, returns either the util.tableCount
of the subtables if they are all the same, or nil if they are not all the same.
@param {table} t
@returns {number|nil} count of key-value pairs of subtable, or nil if subtables
  have different counts
]]--
function util.subTablesCount(t)
	local count = nil
	for k, v in pairs(t) do
		if count == nil then
			count = util.tableCount(v)
		elseif count ~= util.tableCount(v) then
			return nil
		end
	end
	return count
end

--[[
Splits a list into a table sequence. The items in the list may be separated by
commas, or by semicolons (if items may contain commas), or by "###" (if items
may contain semicolons).
@param {string} listString
@returns {table} sequence of list items
]]--
function util.tableFromList(listString)
	if type(listString) ~= "string" or listString == "" then return nil end
	local separator = (mw.ustring.find(listString, "###", 0, true ) and "###") or
		(mw.ustring.find(listString, ";", 0, true ) and ";") or ","
	local pattern = "%s*"..separator.."%s*"
	return mw.text.split(listString, pattern)
end

-- Boolean in outer scope indicating if Kartographer should be able to
-- automatically calculate coordinates (see phab:T227402)
local coordsDerivedFromFeatures = false;

--[[----------------------------------------------------------------------------
 Make methods: These take in a table of arguments, and return either a string
 or a table to be used in the eventual output.
----------------------------------------------------------------------------]]--
local make = {}

--[[
Makes content to go inside the maplink or mapframe tag.

@param {table} args
@returns {string} tag content
]]--
function make.content(args)
	if util.getParameterValue(args, 'raw') then
		coordsDerivedFromFeatures = true -- Kartographer should be able to automatically calculate coords from raw geoJSON
		return util.getParameterValue(args, 'raw')
	end

	local content = {}

    local argsExpanded = {}
    for k, v in pairs(args) do
    	local index = string.match( k, '^[^0-9]+([0-9]*)$' )
    	if index ~= nil then
    		local indexNumber = ''
    		if index ~= '' then
    			indexNumber = tonumber(index)
    		else
    			indexNumber = 1
    		end
    		
    		if argsExpanded[indexNumber] == nil then
    			argsExpanded[indexNumber] = {}
    		end
    		argsExpanded[indexNumber][ string.gsub(k, index, '') ] = v
    	end
    end
	
	for contentIndex, contentArgs in pairs(argsExpanded) do
		local argType = util.getParameterValue(contentArgs, "type")
		-- Kartographer automatically calculates coords if geolines/shapes are used (T227402)
		if not coordsDerivedFromFeatures then
			coordsDerivedFromFeatures = ( argType == L10n.str.line or argType == L10n.str.shape ) and true or false
		end
		if argType == L10n.str.named then
			local namedCoords = util.getNamedCoords(util.getParameterValue(contentArgs, "from"))
			local typeKey = type(L10n.para.type) == "table" and L10n.para.type[1] or L10n.para.type
			local coordKey = type(L10n.para.coord) == "table" and L10n.para.coord[1] or L10n.para.coord
			local titleKey = type(L10n.para.title) == "table" and L10n.para.title[1] or L10n.para.title
			local descKey = type(L10n.para.description) == "table" and L10n.para.description[1] or L10n.para.description
			for _, namedCoord in pairs(namedCoords) do
				contentArgs[typeKey] = "point"
				contentArgs[coordKey]  = namedCoord.coord
				contentArgs[titleKey]  = namedCoord.name
				contentArgs[descKey]  = namedCoord.description
				content[#content+1] = make.contentJson(contentArgs)
			end
		else
			content[#content + 1] = make.contentJson(contentArgs)
		end
	end
	
	--Single item, no array needed
	if #content==1 then return content[1] end

	--Multiple items get placed in a FeatureCollection
	local contentArray = '[\n' .. table.concat( content, ',\n') .. '\n]'
	return contentArray
end

--[[
Make coordinates from the coord arg, or the id arg, or the current page's
Wikidata item.
@param {table} args
@param {boolean} [plainOutput]
@returns {Mixed} Either:
  {number, number} latitude, longitude  if plainOutput is true; or
  {table} table sequence of longitude, then latitude (gives the required format
   for GeoJSON when encoded)
]]--
function make.coords(args, plainOutput) 
	local coords, lat, long
	local frame = mw.getCurrentFrame()
	if util.getParameterValue(args, 'coord') then
		coords = frame:preprocess( util.getParameterValue(args, 'coord') )
		lat, long = util.parseCoords(coords)
	else
		lat, long = util.wikidataCoords(util.getParameterValue(args, 'id') or mw.wikibase.getEntityIdForCurrentPage())
	end
	if plainOutput then
		return lat, long
	end
	return {[0] = long, [1] = lat}
end

--[[
Makes a table of coordinates that approximate a circle.
@param {table} args
@returns {table} sequence of {latitude, longitude} table sequences, where
  latitude and longitude are both numbers
@throws {L10n.error.noCircleCoords} if centre coordinates are not specified
@throws {L10n.error.noRadius} if radius is not specified
@throws {L10n.error.negativeRadius} if radius is negative or zero
@throws {L10n.error.negativeEdges} if edges is negative or zero
]]--
function make.circleCoords(args)
	local lat, long = make.coords(args, true)
	local radius = util.getParameterValue(args, 'radius')
	if not radius then
		radius = util.getParameterValue(args, 'radiusKm') and tonumber(util.getParameterValue(args, 'radiusKm'))*1000
		if not radius then
			radius = util.getParameterValue(args, 'radiusMi') and tonumber(util.getParameterValue(args, 'radiusMi'))*1609.344
			if not radius then
				radius = util.getParameterValue(args, 'radiusFt') and tonumber(util.getParameterValue(args, 'radiusFt'))*0.3048
			end
		end
	end
	local edges = util.getParameterValue(args, 'edges') or L10n.defaults.edges
	if not lat or not long then
		error(L10n.error.noCircleCoords, 0)
	elseif not radius then
		error(L10n.error.noRadius, 0)
	elseif tonumber(radius) <= 0 then
		error(L10n.error.negativeRadius, 0)
	elseif tonumber(edges) <= 0 then
		error(L10n.error.negativeEdges, 0)
	end
	return util.circleToPolygon(lat, long, radius, tonumber(edges))
end

--[[
Makes JSON data for a feature
@param contentArgs  args for this feature. Keys must be the non-suffixed version
  of the parameter names, i.e. use type, stroke, fill,... rather than type3,
  stroke3, fill3,...
@returns {string} JSON encoded data
]]--
function make.contentJson(contentArgs)
	local data = {}

	if util.getParameterValue(contentArgs, 'type') == L10n.str.point or util.getParameterValue(contentArgs, 'type') == L10n.str.circle then
		local isCircle = util.getParameterValue(contentArgs, 'type') == L10n.str.circle
		data.type = "Feature"
		data.geometry = {
			type = isCircle and "LineString" or "Point",
			coordinates = isCircle and make.circleCoords(contentArgs) or make.coords(contentArgs)
		}
		data.properties = {
			title = util.getParameterValue(contentArgs, 'title') or mw.getCurrentFrame():getParent():getTitle()
		}
		if isCircle then
			-- TODO: This is very similar to below, should be extracted into a function
			data.properties.stroke = util.getParameterValue(contentArgs, 'strokeColor') or L10n.defaults.strokeColor
			data.properties["stroke-width"] = tonumber(util.getParameterValue(contentArgs, 'strokeWidth')) or L10n.defaults.strokeWidth
			local strokeOpacity = util.getParameterValue(contentArgs, 'strokeOpacity')
			if strokeOpacity then
				data.properties['stroke-opacity'] = tonumber(strokeOpacity)
			end
			local fill = util.getParameterValue(contentArgs, 'fill')
			if fill then
				data.properties.fill = fill
				local fillOpacity = util.getParameterValue(contentArgs, 'fillOpacity')
				data.properties['fill-opacity'] = fillOpacity and tonumber(fillOpacity) or 0.6
			end
		else -- is a point
			data.properties["marker-symbol"] = util.getParameterValue(contentArgs, 'marker') or  L10n.defaults.marker
			data.properties["marker-color"] = util.getParameterValue(contentArgs, 'markerColor') or L10n.defaults.markerColor
			data.properties["marker-size"] = util.getParameterValue(contentArgs, 'markerSize') or L10n.defaults.markerSize
		end
	else
		data.type = "ExternalData"

		if util.getParameterValue(contentArgs, 'type') == L10n.str.data or util.getParameterValue(contentArgs, 'from') then
			data.service = "page"
		elseif util.getParameterValue(contentArgs, 'type') == L10n.str.line then
			data.service = "geoline"
		elseif util.getParameterValue(contentArgs, 'type') == L10n.str.shape then
			data.service = "geoshape"
		elseif util.getParameterValue(contentArgs, 'type') == L10n.str.shapeInverse then
			data.service = "geomask"
		end

		if util.getParameterValue(contentArgs, 'id') or (not (util.getParameterValue(contentArgs, 'from')) and mw.wikibase.getEntityIdForCurrentPage()) then
			data.ids = util.getParameterValue(contentArgs, 'id') or mw.wikibase.getEntityIdForCurrentPage()
		else 
			data.title = util.getParameterValue(contentArgs, 'from')
		end

		data.properties = {
			stroke = util.getParameterValue(contentArgs, 'strokeColor') or L10n.defaults.strokeColor,
			["stroke-width"] = tonumber(util.getParameterValue(contentArgs, 'strokeWidth')) or L10n.defaults.strokeWidth
		}
		local strokeOpacity = util.getParameterValue(contentArgs, 'strokeOpacity')
		if strokeOpacity then
			data.properties['stroke-opacity'] = tonumber(strokeOpacity)
		end
		local fill = util.getParameterValue(contentArgs, 'fill')
		if fill and (data.service == "geoshape" or data.service == "geomask") then
			data.properties.fill = fill
			local fillOpacity = util.getParameterValue(contentArgs, 'fillOpacity')
			if fillOpacity then
				data.properties['fill-opacity'] = tonumber(fillOpacity)
			end
		end
	end

	data.properties.title = util.getParameterValue(contentArgs, 'title') or mw.title.getCurrentTitle().text
	if util.getParameterValue(contentArgs, 'description') then
		data.properties.description = util.getParameterValue(contentArgs, 'description')
	end

	return mw.text.jsonEncode(data)
end

--[[
Makes attributes for the maplink or mapframe tag.
@param {table} args
@param {boolean} [isTitle]  Tag is to be displayed in the title of page rather
  than inline
@returns {table<string,string>} key-value pairs of attribute names and values 
]]--
function make.tagAttribs(args, isTitle)
	local attribs = {}
	if util.getParameterValue(args, 'zoom') then
		attribs.zoom = util.getParameterValue(args, 'zoom')
	end
	if util.isDeclined(util.getParameterValue(args, 'icon')) then
		attribs.class = "no-icon"
	end
	if util.getParameterValue(args, 'type') == L10n.str.point and not coordsDerivedFromFeatures then
		local lat, long = make.coords(args, 'plainOutput')
		attribs.latitude = tostring(lat)
		attribs.longitude = tostring(long)
	end
	if util.isAffirmed(util.getParameterValue(args, 'frame')) and not(isTitle) then
		attribs.width = util.getParameterValue(args, 'frameWidth') or L10n.defaults.frameWidth
		attribs.height = util.getParameterValue(args, 'frameHeight') or L10n.defaults.frameHeight
		if util.getParameterValue(args, 'frameCoordinates') then
			local frameLat, frameLong = util.parseCoords(util.getParameterValue(args, 'frameCoordinates'))
			attribs.latitude = frameLat
			attribs.longitude = frameLong
		else
			if util.getParameterValue(args, 'frameLatitude') then
				attribs.latitude = util.getParameterValue(args, 'frameLatitude')
			end
			if util.getParameterValue(args, 'frameLongitude') then
				attribs.longitude = util.getParameterValue(args, 'frameLongitude')
			end
		end
		if not attribs.latitude and not attribs.longitude and not coordsDerivedFromFeatures then
			local success, lat, long = pcall(util.wikidataCoords, util.getParameterValue(args, 'id') or mw.wikibase.getEntityIdForCurrentPage())
			if success then
				attribs.latitude = tostring(lat)
				attribs.longitude = tostring(long)
			end
		end
		if util.getParameterValue(args, 'frameAlign') then
			attribs.align = util.getParameterValue(args, 'frameAlign')
		end
		if util.isAffirmed(util.getParameterValue(args, 'plain')) then
			attribs.frameless = "1"
		else
			attribs.text = util.getParameterValue(args, 'text') or L10n.defaults.text
		end
	else
		attribs.text = util.getParameterValue(args, 'text') or L10n.defaults.text
	end
	return attribs
end

--[[
Makes maplink wikitext that will be located in the top-right of the title of the
page (the same place where coords with |display=title are positioned).
@param {table} args
@param {string} tagContent  Content for the maplink tag
@returns {string}
]]--
function make.titleOutput(args, tagContent)
 	local titleTag = mw.text.tag('maplink', make.tagAttribs(args, true), tagContent)
	local spanAttribs = {
		style = "font-size: small;",
		id = "coordinates"
	}
	return mw.text.tag('span', spanAttribs, titleTag)
end

--[[
Makes maplink or mapframe wikitext that will be located inline.
@param {table} args
@param {string} tagContent  Content for the maplink tag
@returns {string}
]]--
function make.inlineOutput(args, tagContent)
	local tagName = 'maplink'
	if util.getParameterValue(args, 'frame') then
		tagName = 'mapframe'
	end

	return mw.text.tag(tagName, make.tagAttribs(args), tagContent)
end


--[[
Makes the HTML required for the swicther to work, including the templatestyles
tag.
@param {table} params  table sequence of {map, label} tables
  @param {string} params{}.map  Wikitext for mapframe map
  @param {string} params{}.label  Label text for swicther option
@param {table} options
  @param {string} options.alignment  "left" or "center" or "right"
  @param {boolean} options.isThumbnail  Display in a thumbnail
  @param {string} options.width  Width of frame, e.g. "200"
  @param {string} [options.caption]  Caption wikitext for thumnail
@retruns {string} swicther HTML
]]--
function make.switcherHtml(params, options)
	if not options then option = {} end
	local frame = mw.getCurrentFrame()
	local styles = frame:extensionTag{
		name = "templatestyles",
		args = {src = "Template:Maplink/styles-multi.css"}
	}
	local container = mw.html.create("div")
		:addClass("switcher-container")
		:addClass("mapframe-multi-container")
	if options.alignment == "left" or options.alignment == "right" then
		container:addClass("float"..options.alignment)
	else -- alignment is "center"
		container:addClass("center")
	end
	for i = 1, #params do
		container
			:tag("div")
				:wikitext(params[i].map)
				:tag("span")
					:addClass("switcher-label")
					:css("display", "none")
					:wikitext(mw.text.trim(params[i].label))
	end
	if not options.isThumbnail then
		return styles .. tostring(container)
	end
	local classlist = container:getAttr("class")
	classlist = mw.ustring.gsub(classlist, "%a*"..options.alignment, "")
	container:attr("class", classlist)
	local outerCountainer = mw.html.create("div")
		:addClass("mapframe-multi-outer-container")
		:addClass("mw-kartographer-container")
		:addClass("thumb")
	if options.alignment == "left" or options.alignment == "right" then
		outerCountainer:addClass("t"..options.alignment)
	else -- alignment is "center"
		outerCountainer
			:addClass("tnone")
			:addClass("center")
	end
	outerCountainer
		:tag("div")
			:addClass("thumbinner")
			:css("width", options.width.."px")
			:node(container)
			:node(options.caption and mw.html.create("div")
				:addClass("thumbcaption")
				:wikitext(options.caption)
			)
	return styles .. tostring(outerCountainer)
end

--[[----------------------------------------------------------------------------
 Package to be exported, i.e. methods which will available to templates and
 other modules.
----------------------------------------------------------------------------]]--
local p = {}

-- Entry point for templates
function p.main(frame)
	local parent = frame.getParent(frame)
	local switch = util.getParameterValue(parent.args, 'switch')
	local isMulti = switch and mw.text.trim(switch) ~= ""
	local output = isMulti and p.multi(parent.args) or p._main(parent.args)
	return frame:preprocess(output)
end

-- Entry points for modules
function p._main(_args)
	local args = util.trimArgs(_args)
 
	local tagContent = make.content(args)

	local display = mw.text.split(util.getParameterValue(args, 'display') or L10n.defaults.display, '%s*' .. L10n.str.dsep .. '%s*')
	local displayInTitle = display[1] ==  L10n.str.title or display[2] ==  L10n.str.title
	local displayInline = display[1] ==  L10n.str.inline or display[2] ==  L10n.str.inline

	local output
	if displayInTitle and displayInline then
		output = make.titleOutput(args, tagContent) .. make.inlineOutput(args, tagContent)
	elseif displayInTitle then
		output = make.titleOutput(args, tagContent)
	elseif displayInline then
		output = make.inlineOutput(args, tagContent)
	else
		error(L10n.error.badDisplayPara)
	end

	return output
end

function p.multi(_args)
	local args = util.trimArgs(_args)
	if not args[L10n.para.switch] then error(L10n.error.noSwitchPara, 0) end
	local switchParamValue = util.getParameterValue(args, 'switch')
	local switchLabels = util.tableFromList(switchParamValue)
	if #switchLabels == 1 then error(L10n.error.oneSwitchLabel, 0) end
	
	local mapframeArgs = {}
	local switchParams = {}
	for name, val in pairs(args) do
		-- Copy to mapframeArgs, if not the switch labels or a switch parameter
		if val ~= switchParamValue and not string.match(val, "^"..L10n.str.switch..":") then
			mapframeArgs[name] = val
		end
		-- Check if this is a param to switch. If so, store the name and switch
		-- values in switchParams table.
		local switchList = string.match(val, "^"..L10n.str.switch..":(.+)")
		if switchList ~= nil then
			local values = util.tableFromList(switchList)
			if #values == 1 then
				error(string.format(L10n.error.oneSwitchValue, name), 0)
			end
			switchParams[name] = values
		end
	end
	if util.tableCount(switchParams) == 0 then
		error(L10n.error.noSwitchLists, 0)
	end
	local switchCount = util.subTablesCount(switchParams)
	if not switchCount then 
		error(L10n.error.switchMismatches, 0)
	elseif switchCount > #switchLabels then
		error(string.format(L10n.error.fewerSwitchLabels, switchCount, #switchLabels), 0)
	end
	
	-- Ensure a plain frame will be used (thumbnail will be built by the
	-- make.switcherHtml function if required, so that switcher options are
	-- inside the thumnail)
	mapframeArgs.plain = "yes"
	
	local switcher = {}
	for i = 1, switchCount do
		local label = switchLabels[i]
		for name, values in pairs(switchParams) do
			mapframeArgs[name] = values[i]
		end
		table.insert(switcher, {
			map = p._main(mapframeArgs),
			label = "Show "..label
		})
	end
	return make.switcherHtml(switcher, {
		alignment = args["frame-align"] or "right",
		isThumbnail = (args.frame and not args.plain) and true or false,
		width = args["frame-width"] or L10n.defaults.frameWidth,
		caption = args.text
	})
end

return p