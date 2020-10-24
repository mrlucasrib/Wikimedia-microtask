local mf = require('Module:Mapframe')
local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local infoboxImage = require('Module:InfoboxImage').InfoboxImage

-- Defaults
local DEFAULT_FRAME_WIDTH = "270"
local DEFAULT_FRAME_HEIGHT = "200"
local DEFAULT_ZOOM = 10
local DEFAULT_GEOMASK_STROKE_WIDTH = "1"
local DEFAULT_GEOMASK_STROKE_COLOR = "#777777"
local DEFAULT_GEOMASK_FILL = "#888888"
local DEFAULT_GEOMASK_FILL_OPACITY = "0.5"
local DEFAULT_SHAPE_STROKE_WIDTH = "3"
local DEFAULT_SHAPE_STROKE_COLOR = "#FF0000"
local DEFAULT_SHAPE_FILL = "#606060"
local DEFAULT_SHAPE_FILL_OPACITY = "0.5"
local DEFAULT_LINE_STROKE_WIDTH = "5"
local DEFAULT_LINE_STROKE_COLOR = "#FF0000"
local DEFAULT_MARKER_COLOR = "#5E74F3"


-- Trim whitespace from args, and remove empty args
function trimArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				cleanArgs[key] = val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

function getBestStatement(item_id, property_id)
	if not(item_id) or not(mw.wikibase.isValidEntityId(item_id)) or not(mw.wikibase.entityExists(item_id)) then
		return false
	end
	local statements = mw.wikibase.getBestStatements(item_id, property_id)
	if not statements or #statements == 0 then
		return false
	end
	local hasNoValue = ( statements[1].mainsnak and statements[1].mainsnak.snaktype == 'novalue' )
	if hasNoValue then
		return false
	end
	return statements[1]
end

function hasWikidataProperty(item_id, property_id)
	return getBestStatement(item_id, property_id) and true or false
end

function getStatementValue(statement)
	return statement and statement.mainsnak and statement.mainsnak.datavalue and statement.mainsnak.datavalue.value or nil
end

function relatedEntity(item_id, property_id)
	local value = getStatementValue( getBestStatement(item_id, property_id) )
	return value and value.id or false
end

function idType(id)
	if not id then 
		return nil
	elseif mw.ustring.match(id, "[Pp]%d+") then
		return "property"
	elseif mw.ustring.match(id, "[Qq]%d+") then
		return "item"
	else
		return nil
	end
end

function getZoom(value, unit)
	local length_km
	if unit == 'km' then
		length_km = tonumber(value)
	elseif unit == 'mi' then
		length_km = tonumber(value)*1.609344
	elseif unit == 'km2' then
		length_km = math.sqrt(tonumber(value))
	elseif unit == 'mi2' then
		length_km = math.sqrt(tonumber(value))*1.609344
	end
	-- max for zoom 2 is 6400km, for zoom 3 is 3200km, for zoom 4 is 1600km, etc
	local zoom = math.floor(8 - (math.log10(length_km) - 2)/(math.log10(2)))
	-- limit to values below 17
	zoom = math.min(17, zoom)
	-- take off 1 when calculated from area, to account for unusual shapes
	if unit == 'km2' or unit == 'mi2' then
		zoom = zoom - 1
	end
	-- minimum value is 1
	return math.max(1, zoom)
end

function shouldAutoRun(frame)
	-- Check if should be running
	local explicitlyOn = yesno(mw.text.trim(frame.getParent(frame).args.mapframe or "")) -- true of false or nil
	local onByDefault = (explicitlyOn == nil) and yesno(mw.text.trim(frame.args.onByDefault or ""), false) -- true or false
	return explicitlyOn or onByDefault
end

function argsFromAuto(frame)
	-- Get args from the frame (invoke call) and the parent (template call).
	-- Frame arguments are default values which are overridden by parent values
	-- when both are present
	local args = getArgs(frame, {parentFirst = true})
	
	-- Discard args not prefixed with "mapframe-", remove that prefix from those that remain
	local fixedArgs = {}
	for name, val in pairs(args) do
		local fixedName = string.match(name, "^mapframe%-(.+)$" )
		if fixedName then
			fixedArgs[fixedName] = val
		-- allow coord, coordinates, etc to be unprefixed
		elseif name == "coordinates" or name == "coord" or name == "coordinate" and not fixedArgs.coord then
			fixedArgs.coord = val
		-- allow id, qid to be unprefixed, map to id (if not already present)
		elseif name == "id" or name == "qid" and not fixedArgs.id then
			fixedArgs.id = val
		end
	end
	return fixedArgs
end

local p = {}

p.autocaption = function(frame)
	if not shouldAutoRun(frame) then return "" end
	local args = argsFromAuto(frame)
	if args.caption then
		return args.caption
	elseif args.switcher then 
		return ""
	end
	local maskItem
	local maskType = idType(args.geomask)
	if maskType == 'item' then
		maskItem = args.geomask
	elseif maskType == "property" then
		maskItem = relatedEntity(args.id or mw.wikibase.getEntityIdForCurrentPage(), args.geomask)
	end
	local maskItemLabel = maskItem and mw.wikibase.getLabel( maskItem )
	return maskItemLabel and "Location in "..maskItemLabel or ""
end

function parseCustomWikitext(customWikitext)
	-- infoboxImage will format an image if given wikitext containing an
	-- image, or else pass through the wikitext unmodified
	return infoboxImage({
		args = {
			image = customWikitext
		}
	})
end

p.auto = function(frame)
	if not shouldAutoRun(frame) then return "" end
	local args = argsFromAuto(frame)
	if args.custom then
		return frame:preprocess(parseCustomWikitext(args.custom))
	end
	local mapframe = p._main(args)
	return frame:preprocess(mapframe)
end

p.main = function(frame)
	local parent = frame.getParent(frame)
	local parentArgs = parent.args
	local mapframe = p._main(parentArgs)
	return frame:preprocess(mapframe)
end

p._main = function(_config)
	-- `config` is the args passed to this module
	local config = trimArgs(_config)
	
	-- Require wikidata item, or specified coords
	local wikidataId = config.id or mw.wikibase.getEntityIdForCurrentPage()
	if not(wikidataId) and not(config.coord) then
		return ''
	end

	-- Require coords (specified or from wikidata), so that map will be centred somewhere
	-- (P625 = coordinate location)
	local hasCoordinates = hasWikidataProperty(wikidataId, 'P625') or config.coordinates or config.coord
	if not hasCoordinates then  
		return ''
	end

	-- `args` is the arguments which will be passed to the mapframe module
	local args = {}

	-- Some defaults/overrides for infobox presentation
	args.display = "inline"
	args.frame = "yes"
	args.plain = "yes"
	args["frame-width"]  = config["frame-width"] or config.width or DEFAULT_FRAME_WIDTH
	args["frame-height"] = config["frame-height"] or config.height or DEFAULT_FRAME_HEIGHT
	args["frame-align"]  = "center"

	args["frame-coord"] = config["frame-coordinates"] or config["frame-coord"] or ""
	-- Note: config["coordinates"] or config["coord"] should not be used for the alignment of the frame;
	-- see talk page ( https://en.wikipedia.org/wiki/Special:Diff/876492931 )

	-- deprecated lat and long parameters
	args["frame-lat"]    = config["frame-lat"] or config["frame-latitude"] or ""
	args["frame-long"]   = config["frame-long"] or config["frame-longitude"] or ""

	-- Calculate zoom from length or area (converted to km or km2)
	if config.length_km then
		args.zoom = getZoom(config.length_km, 'km')
	elseif config.length_mi then
		args.zoom = getZoom(config.length_mi, 'mi')
	elseif config.area_km2 then
		args.zoom = getZoom(config.area_km2, 'km2')
	elseif config.area_mi2 then
		args.zoom = getZoom(config.area_mi2, 'mi2')
	else
		args.zoom = config.zoom or DEFAULT_ZOOM
	end

	-- Conditionals: whether point, geomask should be shown
	local hasOsmRelationId = hasWikidataProperty(wikidataId, 'P402') -- P402 is OSM relation ID
	local shouldShowPointMarker;
	if config.point == "on" then
		shouldShowPointMarker = true 
	elseif config.point == "none" then
		shouldShowPointMarker = false
	else
		shouldShowPointMarker = not(hasOsmRelationId) or (config.marker and config.marker ~= 'none') or (config.coordinates or config.coord)
	end
	local shouldShowShape = config.shape ~= 'none'
	local shapeType = config.shape == 'inverse' and 'shape-inverse' or 'shape'
	local shouldShowLine = config.line ~= 'none'
	local maskItem
	local useWikidata = true -- Use shapes/lines based on wikidata id
	-- Do not use wikidata when coords are specified (and not turned off), unless explicitly set
	if config.coord and shouldShowPointMarker then
		useWikidata = config.wikidata and true or false
	end
	
	-- Switcher
	if config.switcher == "zooms" then
		-- switching between zoom levels
		local maxZoom = math.max(tonumber(args.zoom), 3) -- what zoom would have otherwise been (if 3 or more, otherwise 3)
		local minZoom = 1 -- completely zoomed out
		local midZoom = math.floor((maxZoom + minZoom)/2) -- midway between maxn and min
		args.switch = "zoomed in, zoomed midway, zoomed out"
		args.zoom = string.format("SWITCH:%d,%d,%d", maxZoom, midZoom, minZoom)
	elseif config.switcher == "auto" then
		-- switching between P276 and P131 areas with recursive lookup, e.g. item's city,
		-- that city's state, and that state's country
		args.zoom = nil -- let kartographer determine the zoom
		local maskLabels = {}
		local maskItems = {}
		local maskItemId = relatedEntity(wikidataId, "P276") or  relatedEntity(wikidataId, "P131") 
		local maskLabel = mw.wikibase.getLabel(maskItemId)
		while maskItemId and maskLabel and mw.text.trim(maskLabel) ~= "" do
			table.insert(maskLabels, maskLabel)
			table.insert(maskItems, maskItemId)
			maskItemId = maskItemId and relatedEntity(maskItemId, "P131")
			maskLabel = maskItemId and mw.wikibase.getLabel(maskItemId)
		end
		if #maskLabels > 1 then
			args.switch = table.concat(maskLabels, "###")
			maskItem = "SWITCH:" .. table.concat(maskItems, ",")
		elseif #maskLabels == 1 then
			maskItem = maskItemId[1]
		end
	elseif config.switcher == "geomasks" and config.geomask then
		-- switching between items in geomask parameter
		args.zoom = nil -- let kartographer determine the zoom
		local separator = (mw.ustring.find(config.geomask, "###", 0, true ) and "###") or
			(mw.ustring.find(config.geomask, ";", 0, true ) and ";") or ","
		local pattern = "%s*"..separator.."%s*"
		local maskItems = mw.text.split(mw.ustring.gsub(config.geomask, "SWITCH:", ""), pattern)
		local maskLabels = {}
		if #maskItems > 1 then
			for i, item in ipairs(maskItems) do
				table.insert(maskLabels, mw.wikibase.getLabel(item))
			end
			args.switch = table.concat(maskLabels, "###")
			maskItem = "SWITCH:" .. table.concat(maskItems, ",")
		end
	end
	
	-- resolve geomask item id (if not using geomask switcher)
	if not maskItem then --  
		local maskType = idType(config.geomask)
		if maskType == 'item' then
			maskItem = config.geomask
		elseif maskType == "property" then
			maskItem = relatedEntity(wikidataId, config.geomask)
		end
	end
	
	-- Keep track of arg numbering
	local argNumber = ''
	local function incrementArgNumber()
		if argNumber == '' then
			argNumber = 2
		else
			argNumber = argNumber + 1
		end
	end
	
	-- Geomask
	if maskItem then
		args["type"..argNumber] = "shape-inverse"
		args["id"..argNumber] = maskItem
		args["stroke-width"..argNumber] = config["geomask-stroke-width"] or DEFAULT_GEOMASK_STROKE_WIDTH
		args["stroke-color"..argNumber] = config["geomask-stroke-color"] or config["geomask-stroke-colour"] or DEFAULT_GEOMASK_STROKE_COLOR
		args["fill"..argNumber] = config["geomask-fill"] or DEFAULT_GEOMASK_FILL
		args["fill-opacity"..argNumber] = config["geomask-fill-opacity"] or DEFAULT_SHAPE_FILL_OPACITY
		-- Let kartographer determine zoom and position, unless it is explicitly set in config
		if not config.zoom and not config.switcher then
			args.zoom = nil
			args["frame-coord"] = nil
			args["frame-lat"] = nil
			args["frame-long"] = nil 	
			local maskArea = getStatementValue( getBestStatement(maskItem, 'P2046') )
		end
		incrementArgNumber()
		-- Hack to fix phab:T255932
		if not args.zoom then
			args["type"..argNumber] = "line"
			args["id"..argNumber] = maskItem
			args["stroke-width"..argNumber] = 0
			incrementArgNumber()
		end
	end
	
	-- Shape (or shape-inverse)
	if useWikidata and shouldShowShape then
		args["type"..argNumber] = shapeType
		if config.id then args["id"..argNumber] = config.id end
		args["stroke-width"..argNumber] = config["shape-stroke-width"] or config["stroke-width"] or DEFAULT_SHAPE_STROKE_WIDTH
		args["stroke-color"..argNumber] = config["shape-stroke-color"] or config["shape-stroke-colour"] or config["stroke-color"] or config["stroke-colour"] or DEFAULT_SHAPE_STROKE_COLOR
		args["fill"..argNumber] = config["shape-fill"] or DEFAULT_SHAPE_FILL
		args["fill-opacity"..argNumber] = config["shape-fill-opacity"] or DEFAULT_SHAPE_FILL_OPACITY
		incrementArgNumber()
	end
	
	-- Line
	if useWikidata and shouldShowLine then
		args["type"..argNumber] = "line"
		if config.id then args["id"..argNumber] = config.id end
		args["stroke-width"..argNumber] = config["line-stroke-width"] or config["stroke-width"] or DEFAULT_LINE_STROKE_WIDTH
		args["stroke-color"..argNumber] = config["line-stroke-color"] or config["line-stroke-colour"] or config["stroke-color"] or config["stroke-colour"] or DEFAULT_LINE_STROKE_COLOR
		incrementArgNumber()
	end

	-- Point
	if shouldShowPointMarker then
		args["type"..argNumber] = "point"
		if config.id then args["id"..argNumber] = config.id end
		if config.coord then args["coord"..argNumber] = config.coord end
		if config.marker then args["marker"..argNumber] = config.marker end
		args["marker-color"..argNumber] = config["marker-color"] or config["marker-colour"] or DEFAULT_MARKER_COLOR
		incrementArgNumber()
	end

	local mapframe = args.switch and mf.multi(args) or mf._main(args)
	local tracking = hasOsmRelationId and '' or '[[Category:Infobox mapframe without OSM relation ID on Wikidata]]'
	return mapframe .. tracking
end

return p