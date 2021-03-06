
-- ATTENTION:	Please edit this code at https://de.wikipedia.org/wiki/Modul:Graph
--          	This way all wiki languages can stay in sync. Thank you!
--
--	BUGS:	X-Axis label format bug? (xAxisFormat =) https://en.wikipedia.org/wiki/Template_talk:Graph:Chart#X-Axis_label_format_bug?_(xAxisFormat_=)
--			linewidths - doesnt work for two values (eg 0, 1) but work if added third value of both are zeros? Same for marksStroke - probably bug in Graph extension
--			clamp - "clamp" used to avoid marks outside marks area, "clip" should be use instead but not working in Graph extension, see https://phabricator.wikimedia.org/T251709
--	TODO:  
--			marks:
--				- line strokeDash + serialization,
--				- symStroke serialization
--				- symbolsNoFill serialization
--				- arbitrary SVG path symbol shape as symbolsShape argument
--				- annotations
--					- vertical / horizontal line at specific values [DONE] 2020-09-01
--					- rectangle shape for x,y data range
--				- graph type serialization (deep rebuild reqired)
--	     - second axis (deep rebuild required - assignment of series to one of two axies) 

-- Version History (_PLEASE UPDATE when modifying anything_):
--   2020-09-01 Vertical and horizontal line annotations
--   2020-08-08 New logic for "nice" for x axis (problem with scale when xType = "date") and grid
--   2020-06-21 Serializes symbol size
--              transparent symbosls (from line colour) - buggy (incorrect opacity on overlap with line)
--              Linewidth serialized with "linewidths"
--              Variable symbol size and shape of symbols on line charts, default showSymbols = 2, default symbolsShape = circle, symbolsStroke = 0
--              p.chartDebuger(frame) for easy debug and JSON output 
--   2020-06-07 Allow lowercase variables for use with [[Template:Wikidata list]]
--   2020-05-27 Map: allow specification which feature to display and changing the map center
--   2020-04-08 Change default showValues.fontcolor from black to persistentGrey
--   2020-04-06 Logarithmic scale outputs wrong axis labels when "nice"=true
--   2020-03-11 Allow user-defined scale types, e.g. logarithmic scale
--   2019-11-08 Apply color-inversion-friendliness to legend title, labels, and xGrid
--   2019-01-24 Allow comma-separated lists to contain values with commas
--   2018-10-13 Fix browser color-inversion issues via #54595d per [[mw:Template:Graph:PageViews]]
--   2018-09-16 Allow disabling the legend for templates
--   2018-09-10 Allow grid lines
--   2018-08-26 Use user-defined order for stacked charts
--   2018-02-11 Force usage of explicitely provided x minimum and/or maximum values, rotation of x labels
--   2017-08-08 Added showSymbols param to show symbols on line charts
--   2016-05-16 Added encodeTitleForPath() to help all path-based APIs graphs like pageviews
--   2016-03-20 Allow omitted data for charts, labels for line charts with string (ordinal) scale at point location
--   2016-01-28 For maps, always use wikiraw:// protocol. https:// will be disabled soon.

local p = {}

--add debug text to this string with eg. 	debuglog = debuglog .. "" .. "\n\n"  .. "- " .. debug.traceback() .. "result type: ".. type(result) ..  " result: \n\n" .. mw.dumpObject(result) 
--invoke chartDebuger() to get graph JSON and this string
debuglog = "Debug " .. "\n\n" 

local baseMapDirectory = "Module:Graph/"
local persistentGrey = "#54595d"

local shapes = {}
shapes = { 
	circle = "circle", x= "M-.5,-.5L.5,.5M.5,-.5L-.5,.5" , square = "square", 
	cross = "cross", diamond = "diamond", triangle_up = "triangle-up", 
	triangle_down = "triangle-down", triangle_right = "triangle-right", 
	triangle_left = "triangle-left", 
	banana = "m -0.5281,0.2880 0.0020,0.0192 m 0,0 c 0.1253,0.0543 0.2118,0.0679 0.3268,0.0252 0.1569,-0.0582 0.3663,-0.1636 0.4607,-0.3407 0.0824,-0.1547 0.1202,-0.2850 0.0838,-0.4794 l 0.0111,-0.1498 -0.0457,-0.0015 c -0.0024,0.3045 -0.1205,0.5674 -0.3357,0.7414 -0.1409,0.1139 -0.3227,0.1693 -0.5031,0.1856 m 0,0 c 0.1804,-0.0163 0.3622,-0.0717 0.5031,-0.1856 0.2152,-0.1739 0.3329,-0.4291 0.3357,-0.7414 l -0.0422,0.0079 c 0,0 -0.0099,0.1111 -0.0227,0.1644 -0.0537,0.1937 -0.1918,0.3355 -0.3349,0.4481 -0.1393,0.1089 -0.2717,0.2072 -0.4326,0.2806 l -0.0062,0.0260" 
	   	}


local function numericArray(csv)
	if not csv then return end

	local list = mw.text.split(csv, "%s*,%s*")
	local result = {}
	local isInteger = true
	for i = 1, #list do
		if list[i] == "" then
			result[i] = nil
		else
			result[i] = tonumber(list[i])
			if not result[i] then return end
			if isInteger then
				local int, frac = math.modf(result[i])
				isInteger = frac == 0.0
			end
		end
	end

    return result, isInteger
end

local function stringArray(text)
	if not text then return end

	local list = mw.text.split(mw.ustring.gsub(tostring(text), "\\,", "<COMMA>"), ",", true)
	for i = 1, #list do
		list[i] = mw.ustring.gsub(mw.text.trim(list[i]), "<COMMA>", ",")
	end
	return list
end

local function isTable(t) return type(t) == "table" end

local function copy(x)
	if type(x) == "table" then
		local result = {}
		for key, value in pairs(x) do result[key] = copy(value) end
		return result
	else
		return x
	end
end

function p.map(frame)
	-- map path data for geographic objects
	local basemap = frame.args.basemap or "Template:Graph:Map/Inner/Worldmap2c-json" -- WorldMap name and/or location may vary from wiki to wiki
	-- scaling factor
	local scale = tonumber(frame.args.scale) or 100
	-- map projection, see https://github.com/mbostock/d3/wiki/Geo-Projections
	local projection = frame.args.projection or "equirectangular"
	-- defaultValue for geographic objects without data
	local defaultValue = frame.args.defaultValue or frame.args.defaultvalue
	local scaleType = frame.args.scaleType or frame.args.scaletype or "linear"
	-- minimaler Wertebereich (nur für numerische Daten)
	local domainMin = tonumber(frame.args.domainMin or frame.args.domainmin)
	-- maximaler Wertebereich (nur für numerische Daten)
	local domainMax = tonumber(frame.args.domainMax or frame.args.domainmax)
	-- Farbwerte der Farbskala (nur für numerische Daten)
	local colorScale = frame.args.colorScale or frame.args.colorscale or "category10"
	-- show legend
	local legend = frame.args.legend
	-- the map feature to display
    local feature = frame.args.feature or "countries"
    -- map center
    local center = numericArray(frame.args.center)
	-- format JSON output
	local formatJson = frame.args.formatjson

	-- map data are key-value pairs: keys are non-lowercase strings (ideally ISO codes) which need to match the "id" values of the map path data
	local values = {}
	local isNumbers = nil
	for name, value in pairs(frame.args) do
		if mw.ustring.find(name, "^[^%l]+$") and value and value ~= "" then
			if isNumbers == nil then isNumbers = tonumber(value) end
			local data = { id = name, v = value }
			if isNumbers then data.v = tonumber(data.v) end
			table.insert(values, data)
		end
	end
	if not defaultValue then
		if isNumbers then defaultValue = 0 else defaultValue = "silver" end
	end

	-- create highlight scale
	local scales
	if isNumbers then
		if colorScale then colorScale = string.lower(colorScale) end
		if colorScale == "category10" or colorScale == "category20" then else colorScale = stringArray(colorScale) end
		scales =
		{
			{
				name = "color",
				type = scaleType,
				domain = { data = "highlights", field = "v" },
				range = colorScale,
				nice = true,
				zero = false
			}
		}
		if domainMin then scales[1].domainMin = domainMin end
		if domainMax then scales[1].domainMax = domainMax end

		local exponent = string.match(scaleType, "pow%s+(%d+%.?%d+)") -- check for exponent
		if exponent then
			scales[1].type = "pow"
			scales[1].exponent = exponent
		end
	end

	-- create legend
	if legend then
		legend =
		{
			{
				fill = "color",
				offset = 120,
				properties =
				{
					title = { fontSize = { value = 14 } },
					labels = { fontSize = { value = 12 } },
					legend =
					{
						stroke = { value = "silver" },
						strokeWidth = { value = 1.5 }
					}
				}
			}
		}
	end
 
	-- get map url
	local basemapUrl
	if (string.sub(basemap, 1, 10) == "wikiraw://") then
		basemapUrl = basemap
	else
		-- if not a (supported) url look for a colon as namespace separator. If none prepend default map directory name.
		if not string.find(basemap, ":") then basemap = baseMapDirectory .. basemap end
		basemapUrl = "wikiraw:///" .. mw.uri.encode(mw.title.new(basemap).prefixedText, "PATH")
	end

	local output =
	{
		version = 2,
		width = 1,  -- generic value as output size depends solely on map size and scaling factor
		height = 1, -- ditto
		data =
		{
			{
				-- data source for the highlights
				name = "highlights",
				values = values
			},
			{
				-- data source for map paths data
				name = feature,
				url = basemapUrl,
				format = { type = "topojson", feature = feature },
				transform =
				{
					{
						-- geographic transformation ("geopath") of map paths data
						type = "geopath",
						value = "data",			-- data source
						scale = scale,
                        translate = { 0, 0 },
                        center = center,
						projection = projection
					},
					{
						-- join ("zip") of mutiple data source: here map paths data and highlights
						type = "lookup",
						keys = { "id" },      -- key for map paths data
						on = "highlights",    -- name of highlight data source
						onKey = "id",         -- key for highlight data source
						as = { "zipped" },    -- name of resulting table
						default = { v = defaultValue } -- default value for geographic objects that could not be joined
					}
				}
			}
		},
		marks =
		{
			-- output markings (map paths and highlights)
			{
				type = "path",
				from = { data = feature },
				properties =
				{
					enter = { path = { field = "layout_path" } },
					update = { fill = { field = "zipped.v" } },
					hover = { fill = { value = "darkgrey" } }
				}
			}
		},
		legends = legend
	}
	if (scales) then
		output.scales = scales
		output.marks[1].properties.update.fill.scale = "color"
	end

	local flags
	if formatJson then flags = mw.text.JSON_PRETTY end
	return mw.text.jsonEncode(output, flags)
end

local function deserializeXData(serializedX, xType, xMin, xMax)
	local x

	if not xType or xType == "integer" or xType == "number" then
		local isInteger
		x, isInteger = numericArray(serializedX)
		if x then
			xMin = tonumber(xMin)
			xMax = tonumber(xMax)
			if not xType then
				if isInteger then xType = "integer" else xType = "number" end
			end
		else
			if xType then error("Numbers expected for parameter 'x'") end
		end
	end
	if not x then
		x = stringArray(serializedX)
		if not xType then xType = "string" end
	end
	return x, xType, xMin, xMax
end

local function deserializeYData(serializedYs, yType, yMin, yMax)
	local y = {}
	local areAllInteger = true

	for yNum, value in pairs(serializedYs) do
		local yValues
		if not yType or yType == "integer" or yType == "number" then
			local isInteger
			yValues, isInteger = numericArray(value)
			if yValues then
				areAllInteger = areAllInteger and isInteger
			else
				if yType then
					error("Numbers expected for parameter '" .. name .. "'")
				else
					return deserializeYData(serializedYs, "string", yMin, yMax)
				end
			end
		end
		if not yValues then yValues = stringArray(value) end

		y[yNum] = yValues
	end
	if not yType then
		if areAllInteger then yType = "integer" else yType = "number" end
	end
	if yType == "integer" or yType == "number" then
		yMin = tonumber(yMin)
		yMax = tonumber(yMax)
	end

	return y, yType, yMin, yMax
end

local function convertXYToManySeries(x, y, xType, yType, seriesTitles)
	local data =
	{
		name = "chart",
		format =
		{
			type = "json",
			parse = { x = xType, y = yType }
		},
		values = {}
	}
	for i = 1, #y do
		local yLen = table.maxn(y[i])
		for j = 1, #x do
			if j <= yLen and y[i][j] then table.insert(data.values, { series = seriesTitles[i], x = x[j], y = y[i][j] }) end
		end
	end
	return data
end

local function convertXYToSingleSeries(x, y, xType, yType, yNames)
	local data = { name = "chart", format = { type = "json", parse = { x = xType } }, values = {} }

	for j = 1, #y do data.format.parse[yNames[j]] = yType end

	for i = 1, #x do
		local item = { x = x[i] }
		for j = 1, #y do item[yNames[j]] = y[j][i] end

		table.insert(data.values, item)
	end
	return data
end

local function getXScale(chartType, stacked, xMin, xMax, xType, xScaleType)
	if chartType == "pie" then return end

	local xscale =
	{
		name = "x",
		range = "width",
		zero = false, -- do not include zero value
		domain = { data = "chart", field = "x" }
	}
	if xScaleType then xscale.type = xScaleType else xscale.type = "linear" end
	if xMin then xscale.domainMin = xMin end
	if xMax then xscale.domainMax = xMax end
	if xMin or xMax then
		xscale.clamp = true
		xscale.nice = false
	end
	if chartType == "rect" then
		xscale.type = "ordinal"
		if not stacked then xscale.padding = 0.2 end -- pad each bar group
	else 
		if xType == "date" then 
			xscale.type = "time"
		elseif xType == "string" then
			xscale.type = "ordinal"
			xscale.points = true
		end
	end
	if xType and xType ~= "date" and xScaleType ~= "log" then xscale.nice = true end -- force round numbers for x scale, but "log" and "date" scale outputs a wrong "nice" scale
	return xscale
end

local function getYScale(chartType, stacked, yMin, yMax, yType, yScaleType)
	if chartType == "pie" then return end

	local yscale =
	{
		name = "y",
		 --type = yScaleType or "linear",
		range = "height",
		-- area charts have the lower boundary of their filling at y=0 (see marks.properties.enter.y2), therefore these need to start at zero
		zero = chartType ~= "line",
		nice = yScaleType ~= "log" -- force round numbers for y scale, but log scale outputs a wrong "nice" scale
	}
	if yScaleType then yscale.type = yScaleType else yscale.type = "linear" end
	if yMin then yscale.domainMin = yMin end
	if yMax then yscale.domainMax = yMax end
	if yMin or yMax then yscale.clamp = true end
	if yType == "date" then yscale.type = "time"
	elseif yType == "string" then yscale.type = "ordinal" end
	if stacked then
		yscale.domain = { data = "stats", field = "sum_y" }
	else
		yscale.domain = { data = "chart", field = "y" }
	end

	return yscale
end

local function getColorScale(colors, chartType, xCount, yCount)
	if not colors then
		if (chartType == "pie" and xCount > 10) or yCount > 10 then colors = "category20" else colors = "category10" end
	end

	local colorScale =
	{
		name = "color",
		type = "ordinal",
		range = colors,
		domain = { data = "chart", field = "series" }
	}
	if chartType == "pie" then colorScale.domain.field = "x" end
	return colorScale
end

local function getAlphaColorScale(colors, y)
	local alphaScale
	-- if there is at least one color in the format "#aarrggbb", create a transparency (alpha) scale
	if isTable(colors) then
		local alphas = {}
		local hasAlpha = false
		for i = 1, #colors do
			local a, rgb = string.match(colors[i], "#(%x%x)(%x%x%x%x%x%x)")
			if a then
				hasAlpha = true
				alphas[i] = tostring(tonumber(a, 16) / 255.0)
				colors[i] = "#" .. rgb
			else
				alphas[i] = "1"
			end
		end
		for i = #colors + 1, #y do alphas[i] = "1" end
		if hasAlpha then alphaScale = { name = "transparency", type = "ordinal", range = alphas } end
	end
	return alphaScale
end

local function getLineScale(linewidths, chartType)
	local lineScale = {}
 
	lineScale =
    	{
        name = "line",
        type = "ordinal",
        range = linewidths,
        domain = { data = "chart", field = "series" }
    	}

	return lineScale
end

local function getSymSizeScale(symSize)
	local SymSizeScale = {}
	SymSizeScale =
       	{
        name = "symSize",
        type = "ordinal",
        range = symSize,
        domain = { data = "chart", field = "series" }
        }

	return SymSizeScale
end

local function getSymShapeScale(symShape)
	local SymShapeScale = {}
	SymShapeScale =
       	{
        name = "symShape",
        type = "ordinal",
        range = symShape,
        domain = { data = "chart", field = "series" }
        }

	return SymShapeScale
end

local function getValueScale(fieldName, min, max, type)
	local valueScale =
	{
		name = fieldName,
		type = type or "linear",
		domain = { data = "chart", field = fieldName },
		range = { min, max }
	}
	return valueScale
end

local function addInteractionToChartVisualisation(plotMarks, colorField, dataField)
	-- initial setup
	if not plotMarks.properties.enter then plotMarks.properties.enter = {} end
	plotMarks.properties.enter[colorField] = { scale = "color", field = dataField }

	-- action when cursor is over plot mark: highlight
	if not plotMarks.properties.hover then plotMarks.properties.hover = {} end
	plotMarks.properties.hover[colorField] = { value = "red" }

	-- action when cursor leaves plot mark: reset to initial setup
	if not plotMarks.properties.update then plotMarks.properties.update = {} end
	plotMarks.properties.update[colorField] = { scale = "color", field = dataField }
end

local function getPieChartVisualisation(yCount, innerRadius, outerRadius, linewidth, radiusScale)
	local chartvis =
	{
		type = "arc",
		from = { data = "chart", transform = { { field = "y", type = "pie" } } },

		properties =
		{
			enter = {
				innerRadius = { value = innerRadius },
				outerRadius = { },
				startAngle = { field = "layout_start" },
				endAngle = { field = "layout_end" },
				stroke = { value = "white" },
				strokeWidth = { value = linewidth or 1 }
			}
		}
	}

	if radiusScale then
		chartvis.properties.enter.outerRadius.scale = radiusScale.name
		chartvis.properties.enter.outerRadius.field = radiusScale.domain.field
	else
		chartvis.properties.enter.outerRadius.value = outerRadius
	end

	addInteractionToChartVisualisation(chartvis, "fill", "x")

	return chartvis
end

local function getChartVisualisation(chartType, stacked, colorField, yCount, innerRadius, outerRadius, linewidth, alphaScale, radiusScale, lineScale, interpolate)
	if chartType == "pie" then return getPieChartVisualisation(yCount, innerRadius, outerRadius, linewidth, radiusScale) end

	local chartvis =
	{
		type = chartType,
		properties =
		{
			-- chart creation event handler
			enter =
			{
				x = { scale = "x", field = "x" },
				y = { scale = "y", field = "y" }
			}
		}
	}
	addInteractionToChartVisualisation(chartvis, colorField, "series")
	if colorField == "stroke" then
		chartvis.properties.enter.strokeWidth = { value = linewidth or 2.5 }
		if type(lineScale) =="table"  then 
			chartvis.properties.enter.strokeWidth.value = nil
			chartvis.properties.enter.strokeWidth = 
			{
				scale = "line",
				field= "series"
			} 
		end
	end

	if interpolate then chartvis.properties.enter.interpolate = { value = interpolate } end

	if alphaScale then chartvis.properties.update[colorField .. "Opacity"] = { scale = "transparency" } end
	-- for bars and area charts set the lower bound of their areas
	if chartType == "rect" or chartType == "area" then
		if stacked then
			-- for stacked charts this lower bound is the end of the last stacking element
			chartvis.properties.enter.y2 = { scale = "y", field = "layout_end" }
		else
			--[[
			for non-stacking charts the lower bound is y=0
			TODO: "yscale.zero" is currently set to "true" for this case, but "false" for all other cases.
			For the similar behavior "y2" should actually be set to where y axis crosses the x axis,
			if there are only positive or negative values in the data ]]
			chartvis.properties.enter.y2 = { scale = "y", value = 0 }
		end
	end
	-- for bar charts ...
	if chartType == "rect" then
		-- set 1 pixel width between the bars
		chartvis.properties.enter.width = { scale = "x", band = true, offset = -1 }
		-- for multiple series the bar marking needs to use the "inner" series scale, whereas the "outer" x scale is used by the grouping
		if not stacked and yCount > 1 then
			chartvis.properties.enter.x.scale = "series"
			chartvis.properties.enter.x.field = "series"
			chartvis.properties.enter.width.scale = "series"
		end
	end
	-- stacked charts have their own (stacked) y values
	if stacked then chartvis.properties.enter.y.field = "layout_start" end

	-- if there are multiple series group these together
	if yCount == 1 then
		chartvis.from = { data = "chart" }
	else
		-- if there are multiple series, connect colors to series
		chartvis.properties.update[colorField].field = "series"
		if alphaScale then chartvis.properties.update[colorField .. "Opacity"].field = "series" end
		
	    -- if there are multiple series, connect linewidths to series
		if chartype == "line" then
			chartvis.properties.update["strokeWidth"].field = "series"
		end

		
		-- apply a grouping (facetting) transformation
		chartvis =
		{
			type = "group",
			marks = { chartvis },
			from =
			{
				data = "chart",
				transform =
				{
					{
						type = "facet",
						groupby = { "series" }
					}
				}
			}
		}
		-- for stacked charts apply a stacking transformation
		if stacked then
			table.insert(chartvis.from.transform, 1, { type = "stack", groupby = { "x" }, sortby = { "-_id" }, field = "y" } )
		else
			-- for bar charts the series are side-by-side grouped by x
			if chartType == "rect" then
				-- for bar charts with multiple series: each serie is grouped by the x value, therefore the series need their own scale within each x group
				local groupScale =
				{
					name = "series",
					type = "ordinal",
					range = "width",
					domain = { field = "series" }
				}

				chartvis.from.transform[1].groupby = "x"
				chartvis.scales = { groupScale }
				chartvis.properties = { enter = { x = { field = "key", scale = "x" }, width = { scale = "x", band = true } } }
			end
		end
	end

	return chartvis
end

local function getTextMarks(chartvis, chartType, outerRadius, scales, radiusScale, yType, showValues)
	local properties
	if chartType == "rect" then
		properties =
		{
			x = { scale = chartvis.properties.enter.x.scale, field = chartvis.properties.enter.x.field },
			y = { scale = chartvis.properties.enter.y.scale, field = chartvis.properties.enter.y.field, offset = -(tonumber(showValues.offset) or -4) },
			--dx = { scale = chartvis.properties.enter.x.scale, band = true, mult = 0.5 }, -- for horizontal text
			dy = { scale = chartvis.properties.enter.x.scale, band = true, mult = 0.5 }, -- for vertical text
			align = { },
			baseline = { value = "middle" },
			fill = { },
			angle = { value = -90 },
			fontSize = { value = tonumber(showValues.fontsize) or 11 }
		}
		if properties.y.offset >= 0 then
			properties.align.value = "right"
			properties.fill.value = showValues.fontcolor or "white"
		else
			properties.align.value = "left"
			properties.fill.value = showValues.fontcolor or persistentGrey
		end
	elseif chartType == "pie" then
		properties =
		{
			x = { group = "width", mult = 0.5 },
			y = { group = "height", mult = 0.5 },
			radius = { offset = tonumber(showValues.offset) or -4 },
			theta = { field = "layout_mid" },
			fill = { value = showValues.fontcolor or persistentGrey },
			baseline = { },
			angle = { },
			fontSize = { value = tonumber(showValues.fontsize) or math.ceil(outerRadius / 10) }
		}
		if (showValues.angle or "midangle") == "midangle" then
			properties.align = { value = "center" }
			properties.angle = { field = "layout_mid", mult = 180.0 / math.pi }

			if properties.radius.offset >= 0 then
				properties.baseline.value = "bottom"
			else
				if not showValues.fontcolor then properties.fill.value = "white" end
				properties.baseline.value = "top"
			end
		elseif tonumber(showValues.angle) then
			-- qunatize scale for aligning text left on right half-circle and right on left half-circle
			local alignScale = { name = "align", type = "quantize", domainMin = 0.0, domainMax = math.pi * 2, range = { "left", "right" } }
			table.insert(scales, alignScale)

			properties.align = { scale = alignScale.name, field = "layout_mid" }
			properties.angle = { value = tonumber(showValues.angle) }
			properties.baseline.value = "middle"
			if not tonumber(showValues.offset) then properties.radius.offset = 4 end
		end

		if radiusScale then
			properties.radius.scale = radiusScale.name
			properties.radius.field = radiusScale.domain.field
		else
			properties.radius.value = outerRadius
		end
	end

	if properties then
		if showValues.format then
			local template = "datum.y"
			if yType == "integer" or yType == "number" then template = template .. "|number:'" .. showValues.format .. "'"
			elseif yType == "date" then template = template .. "|time:" .. showValues.format .. "'"
			end
			properties.text = { template = "{{" .. template .. "}}" }
		else
			properties.text = { field = "y" }
		end

		local textmarks =
		{
			type = "text",
			properties =
			{
				enter = properties
			}
		}
		if chartvis.from then textmarks.from = copy(chartvis.from) end

		return textmarks
	end
end

local function getSymbolMarks(chartvis, symSize, symShape, symStroke, noFill, alphaScale)

	local symbolmarks 
	symbolmarks =
	{
		type = "symbol",
		properties =
		{
			enter = 
			{
				x = { scale = "x", field = "x" },
				y = { scale = "y", field = "y" },
				strokeWidth = { value = symStroke },
				stroke = { scale = "color", field = "series" },
				fill = { scale = "color", field = "series" },
			}
		}
	}
	if type(symShape) == "string" then 
		symbolmarks.properties.enter.shape = { value = symShape }
	end
	if type(symShape) == "table" then 
		symbolmarks.properties.enter.shape = { scale = "symShape", field = "series" }
	end
	if type(symSize) == "number" then 
		symbolmarks.properties.enter.size = { value = symSize }
	end
	if type(symSize) == "table" then 
		symbolmarks.properties.enter.size = { scale = "symSize", field = "series" }
	end
	if noFill then 
		symbolmarks.properties.enter.fill = nil
	end
	if alphaScale then 
		symbolmarks.properties.enter.fillOpacity = 
		{ scale = "transparency", field = "series" } 
		symbolmarks.properties.enter.strokeOpacity = 
		{ scale = "transparency", field = "series" } 
	end
	if chartvis.from then symbolmarks.from = copy(chartvis.from) end
    
	return symbolmarks
end

local function getAnnoMarks(chartvis, stroke, fill, opacity)

	local vannolines, hannolines, vannoLabels, vannoLabels 
	vannolines =
	{
		type = "rule",
		from = { data = "v_anno" },
		properties =
		{
			update = 
			{
				x = { scale = "x", field = "x" },
				y = { value = 0 },
				y2 = {  field = { group = "height" } },
				strokeWidth = { value = stroke },
				stroke = { value = persistentGrey },
				opacity = { value = opacity }
			}
		}
	}
	vannolabels =
	{
		type = "text",
		from = { data = "v_anno" },
		properties =
		{
			update = 
			{
				x = { scale = "x", field = "x", offset = 3 },
				y = {  field = { group = "height" }, offset = -3 },
				text = { field = "label" },
				baseline = { value = "top" },
		        angle = { value = -90 },
		        fill = { value = persistentGrey },
		        opacity = { value = opacity }
			}
		}
	}	
	hannolines =
	{
		type = "rule",
		from = { data = "h_anno" },
		properties =
		{
			update = 
			{
				y = { scale = "y", field = "y" },
				x = { value = 0 },
				x2 = {  field = { group = "width" } },
				strokeWidth = { value = stroke },
				stroke = { value = persistentGrey },
				opacity = { value = opacity }
			}
		}
	}
	hannolabels =
	{
		type = "text",
		from = { data = "h_anno" },
		properties =
		{
			update = 
			{
				y = { scale = "y", field = "y", offset = 3 },
				x = {  value = 0 , offset = 3 },
				text = { field = "label" },
				baseline = { value = "top" },
		        angle = { value = 0 },
		        fill = { value = persistentGrey },
		        opacity = { value = opacity }
			}
		}
	}
	return vannolines, vannolabels, hannolines, hannolabels
end

local function getAxes(xTitle, xAxisFormat, xAxisAngle, xType, xGrid, yTitle, yAxisFormat, yType, yGrid, chartType)
	local xAxis, yAxis
	if chartType ~= "pie" then
		if xType == "integer" and not xAxisFormat then xAxisFormat = "d" end
		xAxis =
		{
			type = "x",
			scale = "x",
			title = xTitle,
			format = xAxisFormat,
			grid = xGrid
		}
		if xAxisAngle then
			local xAxisAlign
			if xAxisAngle < 0 then xAxisAlign = "right" else xAxisAlign = "left" end
			xAxis.properties =
			{
				title =
				{
					fill = { value = persistentGrey }
				},
				labels =
				{
					angle = { value = xAxisAngle },
					align = { value = xAxisAlign },
					fill = { value = persistentGrey }
				},
				ticks =
				{
					stroke = { value = persistentGrey }
				},
				axis =
				{
					stroke = { value = persistentGrey },
					strokeWidth = { value = 2 }
				},
				grid =
				{
					stroke = { value = persistentGrey }
				}
			}
		else
			xAxis.properties =
			{
				title =
				{
					fill = { value = persistentGrey }
				},
				labels =
				{
					fill = { value = persistentGrey }
				},
				ticks =
				{
					stroke = { value = persistentGrey }
				},
				axis =
				{
					stroke = { value = persistentGrey },
					strokeWidth = { value = 2 }
				},
				grid =
				{
					stroke = { value = persistentGrey }
				}
			}
		end

		if yType == "integer" and not yAxisFormat then yAxisFormat = "d" end
		yAxis =
		{
			type = "y",
			scale = "y",
			title = yTitle,
			format = yAxisFormat,
			grid = yGrid
		}
		yAxis.properties =
		{
			title =
			{
				fill = { value = persistentGrey }
			},
			labels =
			{
				fill = { value = persistentGrey }
			},
			ticks =
			{
				stroke = { value = persistentGrey }
			},
			axis =
			{
				stroke = { value = persistentGrey },
				strokeWidth = { value = 2 }
			},
			grid =
			{
				stroke = { value = persistentGrey }
			}
		}
	
	end

	return xAxis, yAxis
end

local function getLegend(legendTitle, chartType, outerRadius)
	local legend =
	{
		fill = "color",
		stroke = "color",
		title = legendTitle,
	}
	legend.properties = {
		title = {
			fill = { value = persistentGrey },
		},
		labels = {
			fill = { value = persistentGrey },
		},
	}
	if chartType == "pie" then
		legend.properties = {
			-- move legend from center position to top
			legend = {
				y = { value = -outerRadius },
			},
			title = {
				fill = { value = persistentGrey }
			},
			labels = {
				fill = { value = persistentGrey },
			},
		}
	end
	return legend
end

function p.chart(frame)
	-- chart width and height
	local graphwidth = tonumber(frame.args.width) or 200
	local graphheight = tonumber(frame.args.height) or 200
	-- chart type
	local chartType = frame.args.type or "line"
	-- interpolation mode for line and area charts: linear, step-before, step-after, basis, basis-open, basis-closed (type=line only), bundle (type=line only), cardinal, cardinal-open, cardinal-closed (type=line only), monotone
	local interpolate = frame.args.interpolate
	-- mark colors (if no colors are given, the default 10 color palette is used)
	local colorString = frame.args.colors
	if colorString then colorString = string.lower(colorString) end
	local colors = stringArray(colorString)
	-- for line charts, the thickness of the line; for pie charts the gap between each slice
	local linewidth = tonumber(frame.args.linewidth)
	local linewidthsString = frame.args.linewidths
	local linewidths
	if linewidthsString and linewidthsString ~= "" then linewidths = numericArray(linewidthsString) or false end
	-- x and y axis caption
	local xTitle = frame.args.xAxisTitle  or frame.args.xaxistitle
	local yTitle = frame.args.yAxisTitle  or frame.args.yaxistitle
	-- x and y value types
	local xType = frame.args.xType or frame.args.xtype
	local yType = frame.args.yType or frame.args.ytype
	-- override x and y axis minimum and maximum
	local xMin = frame.args.xAxisMin or frame.args.xaxismin
	local xMax = frame.args.xAxisMax or frame.args.xaxismax
	local yMin = frame.args.yAxisMin or frame.args.yaxismin
	local yMax = frame.args.yAxisMax or frame.args.yaxismax
	-- override x and y axis label formatting
	local xAxisFormat = frame.args.xAxisFormat or frame.args.xaxisformat
	local yAxisFormat = frame.args.yAxisFormat or frame.args.yaxisformat
	local xAxisAngle = tonumber(frame.args.xAxisAngle) or tonumber(frame.args.xaxisangle)
	-- x and y scale types
	local xScaleType = frame.args.xScaleType or frame.args.xscaletype 
	local yScaleType = frame.args.yScaleType or frame.args.yscaletype  
-- log scale require minimum > 0, for now it's no possible to plot negative values on log - TODO see: https://www.mathworks.com/matlabcentral/answers/1792-log-scale-graphic-with-negative-value
--	if xScaleType == "log" then
--		if (not xMin or tonumber(xMin) <= 0) then xMin = 0.1 end
--		if not xType then xType = "number" end
--	end
--	if yScaleType == "log" then
--		if (not yMin or tonumber(yMin) <= 0) then yMin = 0.1 end
--		if not yType then yType = "number" end
--	end

	-- show grid
	local xGrid = frame.args.xGrid or frame.args.xgrid or false
	local yGrid = frame.args.yGrid or frame.args.ygrid or false
	-- for line chart, show a symbol at each data point
	local showSymbols = frame.args.showSymbols or frame.args.showsymbols
	local symbolsShape = frame.args.symbolsShape or frame.args.symbolsshape
	local symbolsNoFill = frame.args.symbolsNoFill or frame.args.symbolsnofill 
	local symbolsStroke = tonumber(frame.args.symbolsStroke or frame.args.symbolsstroke)
	-- show legend with given title
	local legendTitle = frame.args.legend
	-- show values as text
	local showValues = frame.args.showValues or frame.args.showvalues 
	-- show v- and h-line annotations
	local v_annoLineString = frame.args.vAnnotatonsLine or frame.args.vannotatonsline
	local h_annoLineString = frame.args.hAnnotatonsLine or frame.args.hannotatonsline
	local v_annoLabelString = frame.args.vAnnotatonsLabel or frame.args.vannotatonslabel
	local h_annoLabelString = frame.args.hAnnotatonsLabel or frame.args.hannotatonslabel





	-- decode annotations cvs
	local v_annoLine, v_annoLabel, h_annoLine, h_annoLabel
	if v_annoLineString and v_annoLineString ~= "" then

		if xType == "number" or xType == "integer" then 
		v_annoLine = numericArray(v_annoLineString)

		else 
			v_annoLine = stringArray(v_annoLineString)

		end
		v_annoLabel = stringArray(v_annoLabelString)
	end
	if h_annoLineString and h_annoLineString ~= "" then

		if yType == "number" or yType == "integer" then 
			h_annoLine = numericArray(h_annoLineString)

		else 
			h_annoLine = stringArray(h_annoLineString)

		end
		h_annoLabel = stringArray(h_annoLabelString)
	end





	-- pie chart radiuses
	local innerRadius = tonumber(frame.args.innerRadius) or tonumber(frame.args.innerradius) or 0
	local outerRadius = math.min(graphwidth, graphheight)
	-- format JSON output
	local formatJson = frame.args.formatjson

	-- get x values
	local x
	x, xType, xMin, xMax = deserializeXData(frame.args.x, xType, xMin, xMax)

	-- get y values (series)
	local yValues = {}
	local seriesTitles = {}
	for name, value in pairs(frame.args) do
		local yNum
		if name == "y" then yNum = 1 else yNum = tonumber(string.match(name, "^y(%d+)$")) end
		if yNum then
			yValues[yNum] = value
			-- name the series: default is "y<number>". Can be overwritten using the "y<number>Title" parameters.
			seriesTitles[yNum] = frame.args["y" .. yNum .. "Title"] or frame.args["y" .. yNum .. "title"] or name
		end
	end
	local y
	y, yType, yMin, yMax = deserializeYData(yValues, yType, yMin, yMax)

	-- create data tuples, consisting of series index, x value, y value
	local data
	if chartType == "pie" then
		-- for pie charts the second second series is merged into the first series as radius values
		data = convertXYToSingleSeries(x, y, xType, yType, { "y", "r" })
	else
		data = convertXYToManySeries(x, y, xType, yType, seriesTitles)
	end

	-- configure stacked charts
	local stacked = false
	local stats
	if string.sub(chartType, 1, 7) == "stacked" then
		chartType = string.sub(chartType, 8)
		if #y > 1 then -- ignore stacked charts if there is only one series
		stacked = true
		-- aggregate data by cumulative y values
		stats =
		{
			name = "stats", source = "chart", transform =
		{
			{
				type = "aggregate",
				groupby = { "x" },
				summarize = { y = "sum" }
			}
		}
		}
		end
	end
	
	-- add annotations to data
	local vannoData, hannoData
	
	if v_annoLine then
		vannoData = { name = "v_anno", format = { type = "json", parse = { x = xType } }, values = {} }
		for i = 1, #v_annoLine do
			local item = { x = v_annoLine[i], label = v_annoLabel[i] }
			table.insert(vannoData.values, item)
		end
	end	
	if h_annoLine then
		hannoData = { name = "h_anno", format = { type = "json", parse = { y = yType } }, values = {} }
		for i = 1, #h_annoLine do
			local item = { y = h_annoLine[i], label = h_annoLabel[i] }
			table.insert(hannoData.values, item)
		end
	end	


	-- create scales
	local scales = {}

	local xscale = getXScale(chartType, stacked, xMin, xMax, xType, xScaleType)
	table.insert(scales, xscale)
	local yscale = getYScale(chartType, stacked, yMin, yMax, yType, yScaleType)
	table.insert(scales, yscale)

	local colorScale = getColorScale(colors, chartType, #x, #y)
	table.insert(scales, colorScale)

	local alphaScale = getAlphaColorScale(colors, y)
	table.insert(scales, alphaScale)

	local lineScale
	if (linewidths) and (chartType == "line") then
		lineScale = getLineScale(linewidths, chartType)
		table.insert(scales, lineScale)
	end

	local radiusScale
	if chartType == "pie" and #y > 1 then
		radiusScale = getValueScale("r", 0, outerRadius)
		table.insert(scales, radiusScale)
	end

	-- decide if lines (strokes) or areas (fills) should be drawn
	local colorField
	if chartType == "line" then colorField = "stroke" else colorField = "fill" end



	-- create chart markings
	local chartvis = getChartVisualisation(chartType, stacked, colorField, #y, innerRadius, outerRadius, linewidth, alphaScale, radiusScale, lineScale, interpolate)
	local marks = { chartvis }
	
	-- text marks
	if showValues then
		if type(showValues) == "string" then -- deserialize as table
			local keyValues = mw.text.split(showValues, "%s*,%s*")
			showValues = {}
			for _, kv in ipairs(keyValues) do
				local key, value = mw.ustring.match(kv, "^%s*(.-)%s*:%s*(.-)%s*$")
				if key then showValues[key] = value end
			end
		end

		local chartmarks = chartvis
		if chartmarks.marks then chartmarks = chartmarks.marks[1] end
		local textmarks = getTextMarks(chartmarks, chartType, outerRadius, scales, radiusScale, yType, showValues)
		if chartmarks ~= chartvis then
			table.insert(chartvis.marks, textmarks)
		else
			table.insert(marks, textmarks)
		end
	end
	
    -- grids
    if xGrid then 
    	if xGrid == "0" then xGrid = false
    	elseif xGrid == 0 then xGrid = false 
    	elseif xGrid == "false" then xGrid = false 
    	elseif xGrid == "n" then xGrid = false 
    	else xGrid = true 
    	end
    end
    if yGrid then 
    	if yGrid == "0" then yGrid = false
    	elseif yGrid == 0 then yGrid = false 
    	elseif yGrid == "false" then yGrid = false 
    	elseif yGrid == "n" then yGrid = false 
    	else yGrid = true 
    	end
    end
    
	-- symbol marks
	if showSymbols and chartType ~= "rect" then
		local chartmarks = chartvis
		if chartmarks.marks then chartmarks = chartmarks.marks[1] end

		if type(showSymbols) == "string" then
			if showSymbols == "" then showSymbols = true
			else showSymbols = numericArray(showSymbols)
			end
		else
			showSymbols = tonumber(showSymbols)
		end

		-- custom size
		local symSize
		if type(showSymbols) == "number" then 
			symSize = tonumber(showSymbols*showSymbols*8.5)
	 	elseif type(showSymbols) == "table" then 
	 		symSize = {}
	 		for k, v in pairs(showSymbols) do
                symSize[k]=v*v*8.5 -- "size" acc to Vega syntax is area of symbol
            end
        else
	 		symSize = 50
	 	end
		-- symSizeScale 
	 	local symSizeScale = {}
		if type(symSize) == "table" then
			symSizeScale = getSymSizeScale(symSize)
			table.insert(scales, symSizeScale)
		end
 	

    	-- custom shape
    	if  stringArray(symbolsShape) and #stringArray(symbolsShape) > 1 then symbolsShape = stringArray(symbolsShape) end
    	
    	local symShape = " "
		
		if type(symbolsShape) == "string" and shapes[symbolsShape] then
			symShape = shapes[symbolsShape]
	 	elseif type(symbolsShape) == "table" then 
	 		symShape = {}
	 		for k, v in pairs(symbolsShape) do
                if symbolsShape[k] and shapes[symbolsShape[k]] then 
                	symShape[k]=shapes[symbolsShape[k]]
                else
                	symShape[k] = "circle"
                end
            end
       	else
			symShape = "circle"
		end
		-- symShapeScale 
	 	local symShapeScale = {}
		if type(symShape) == "table" then
			symShapeScale = getSymShapeScale(symShape)
			table.insert(scales, symShapeScale)
		end 
 
		-- custom stroke
		local symStroke
		if (type(symbolsStroke) == "number") then 
			symStroke = tonumber(symbolsStroke)
-- TODO symStroke serialization
--		elseif type(symbolsStroke) == "table" then 
--	 		symStroke = {}
--	 		for k, v in pairs(symbolsStroke) do
--                symStroke[k]=symbolsStroke[k]
--                		--always draw x with stroke
--				if symbolsShape[k] == "x" then symStroke[k] = 2.5 end
				--always draw x with stroke
--				if symbolsNoFill[k] then symStroke[k] = 2.5 end
--            end
		else 
			symStroke = 0
		--always draw x with stroke
			if symbolsShape == "x" then symStroke = 2.5 end
		--always draw x with stroke
			if symbolsNoFill then symStroke = 2.5 end
	 	end 		


--	TODO	-- symStrokeScale 
--	 	local symStrokeScale = {}
--		if type(symStroke) == "table" then
--			symStrokeScale = getSymStrokeScale(symStroke)
--			table.insert(scales, symStrokeScale)
--		end


		
		local symbolmarks = getSymbolMarks(chartmarks, symSize, symShape, symStroke, symbolsNoFill, alphaScale)
		if chartmarks ~= chartvis then
			table.insert(chartvis.marks, symbolmarks)
		else
			table.insert(marks, symbolmarks)
		end
	end


	local vannolines, vannolabels, hannolines, hannolabels = getAnnoMarks(chartmarks, persistentGrey, persistentGrey, 0.75)
	if vannoData then
		table.insert(marks, vannolines)
		table.insert(marks, vannolabels)
	end
	if hannoData then
		table.insert(marks, hannolines)
		table.insert(marks, hannolabels)
	end

	-- axes
	local xAxis, yAxis = getAxes(xTitle, xAxisFormat, xAxisAngle, xType, xGrid, yTitle, yAxisFormat, yType, yGrid, chartType)
	
	-- legend
	local legend
	if legendTitle and tonumber(legendTitle) ~= 0 then legend = getLegend(legendTitle, chartType, outerRadius) end
	-- construct final output object
	local output =
	{
		version = 2,
		width = graphwidth,
		height = graphheight,
		data = { data },
		scales = scales,
		axes = { xAxis, yAxis },
		marks = marks,
		legends = { legend }
	}
	if vannoData then table.insert(output.data, vannoData) end
	if hannoData then table.insert(output.data, hannoData) end
	if stats then table.insert(output.data, stats) end

	local flags
	if formatJson then flags = mw.text.JSON_PRETTY end
	return mw.text.jsonEncode(output, flags)
end

function p.mapWrapper(frame)
	return p.map(frame:getParent())
end

function p.chartWrapper(frame)
	return p.chart(frame:getParent())
end

function p.chartDebuger(frame)
	return   "\n\nchart JSON\n ".. p.chart(frame) .. " \n\n" .. debuglog 
end


-- Given an HTML-encoded title as first argument, e.g. one produced with {{ARTICLEPAGENAME}},
-- convert it into a properly URL path-encoded string
-- This function is critical for any graph that uses path-based APIs, e.g. PageViews graph
function p.encodeTitleForPath(frame)
	return mw.uri.encode(mw.text.decode(mw.text.trim(frame.args[1])), 'PATH')
end

return p