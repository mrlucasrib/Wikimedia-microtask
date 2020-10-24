require('Module:No globals')
local fn = require('Module:Formatnum')
--local mm = require('Module:Math')
local Date = require('Module:Date')._Date
local p = {}

-- N/A but possible option: keep cyclone data in subpage data files
--local stormDatabase = require( "Module:Cyclone map/data" ) -- configuration module
                          
-- main function callable in Wikipedia via the #invoke command.
p.main = function(frame) 
	
	local str = p.getMapframeString()
	return frame:preprocess(str)   -- the mapframe needs to be preprocessed!!!!!
end  -- End the function.

--[[ function to construct mapframe string
       sets up the <mapframe> tags
       <mapframe width= height= latitude=  longitude= zoom= >
          MAPDATA in form of geojson constucted with function getGeoJSON()
       </mapframe>
--]]
p.getMapframeString = function(frame) 

    --get mapframe arguments from calling templates
    local parent = mw.getCurrentFrame():getParent() 
  
    -- get JSON data for features to display
    local mapData = p.getGeoJSON()
    
    local mapString = ""

    --mapString = '<mapframe text="London football stadia" width=800 height=650 align=left zoom=11 latitude=51.530 longitude=-0.16 >'
    if mapData ~= "" then

	    mapString = '<mapframe' 
	    if parent.args['frameless'] then  -- don't and text as this overrides frameless parameter
	    	mapString = mapString  .. ' frameless'
	    else
	    	mapString = mapString  .. ' text="' .. (parent.args['text'] or "") .. '"'
	    end
	    
	    -- set width and height using noth parameters, one parameter assuming 4:3 aspect ratio, or defaults
	    local aspect = 4/3                                                  
	    local width = parent.args['width']                                  --or "220"
	    local height = parent.args['height'] or (width or 220)/aspect     --or "165"
	    width = width or height*aspect                                   -- if width null, use height
	    
	    local align = parent.args['align'] or "right"

	    mapString = mapString  .. ' width='     .. math.floor(width)  .. ' height='    .. math.floor(height)  .. ' align='     .. align

	    local zoom      = parent.args['zoom'] --or "0"          -- no longer set defaults (mapframe does automatically)
		local latitude  = parent.args['latitude'] --or "0"
		local longitude = parent.args['longitude'] --or "0"
	    
	    --set if values, otherwise allow mapframe to set automatically (TODO check if longitude and latitude are independent)
	    if zoom      then  mapString = mapString .. ' zoom='      .. zoom      end
	    if latitude  then  mapString = mapString .. ' latitude='  .. latitude  end
	    if longitude then  mapString = mapString .. ' longitude=' .. longitude end
	    
	    mapString = mapString  .. ' >'  .. mapData   .. '</mapframe>'   -- add data and close tag
    else
    	mapString = "No data for map"
    end
    
    return mapString    

end  -- End the function.

--[[ function getGeoJSON() - to construct JSON format data for markers on map.
     The information for each marker (coordinate, description and image for popup, etc) 
     can be set in several ways (in order of priority):
      (1) using arguments in the template (|imageN=, |descriptionN=)
      (2) from values in the data module (i.e. Module:Football map/data) [not function for cyclone map]
      (3) from Wikidata
]]
p.getGeoJSON = function(frame) 

    -- now we need to iterate through the stadiumN parameters and get data for the feature markers
    local maxNumber = 200 -- maximum number looked for
    local mapData = ""
    local cycloneName = nil
    local cycloneID = nil
    
    
     --get mapframe arguments from calling templates
    local parent = mw.getCurrentFrame():getParent() 
   
    --[[There are three ways of getting data about the stadium features
        	(1) from a list in the module subpages (n/a but possible alternative)
        	(2) from wikidata 
        	(3) from the parameters in the template (these always override other)
    	The parameters useWikiData, useModule restrict use of source
    --]]
    local useWikidata = true
    local useModule = false
    
    if parent.args['wikidata'] then useWikidata = true; useModule = false end -- use wikidata or template data (no module data)
    if parent.args['moduledata'] then useModule = true; useWikidata = false end -- use module of template data (no wikidata)
    if parent.args['templatedata'] then useModule = false; useWikidata = false end -- only use template data
    
    -- default parameters for marker color, size and symbol, etc (i.e. those without index suffix)
    local strokeColor = parent.args['stroke'] or "#000000"
    if strokeColor == "auto" then strokeColor = nil end  -- if using auto color
    
    -- the default properties are set by the unindexed parameters and affect all objects
    local defaultProperties = { 
    	                    ['marker-color']   = parent.args['marker-color'], -- default to nil --or  "#0050d0",
    	                    ['marker-size']    = parent.args['marker-size'] or "small",
    	                    ['marker-symbol']  = parent.args['marker-symbol'] or "circle", 
                            ['stroke']         = strokeColor,  --parent.args['stroke'] or "#000000",          -- nil default causes autocolor path; a value overrides autocolor
                            ['stroke-width']   = parent.args['stroke-width'] or 1,
                            ['stroke-opacity'] = parent.args['stroke-opacity'] or 1.0,
                            
                            -- these are for shapes drawn with polygon instead of the marker symbol
                            ['symbol-stroke']  = parent.args['symbol-stroke'],   -- nil default causes autocolor path; a value overrides autocolor
                            ['symbol-fill']    = parent.args['symbol-fill'],     -- nil default causes autocolor path; 
                            ['symbol-shape']    = parent.args['symbol-shape'] or "circle",
                            ['symbol-size']    = parent.args['symbol-size'] or 0.4,
                            ['symbol-stroke-width']   = parent.args['symbol-stroke-width'] or 0,
                            ['symbol-stroke-opacity'] = parent.args['symbol-stroke-opacity'] or 1.0,
                            ['symbol-fill-opacity']   = parent.args['symbol-fill-opacity'] or 1.0 
                          }

    local index=0
    while index < maxNumber do 
    	
    	index = index + 1
	    local cycloneID = ""
	  
	    -- (1) get cyclone name  
	    cycloneID   = parent.args['id'..tostring(index)] 
	    cycloneName = parent.args['name'..tostring(index)] 
	    
	    if cycloneName and not cycloneID  then 
	    	cycloneID = mw.wikibase.getEntityIdForTitle(cycloneName)
	    end  
	    if cycloneID and not cycloneName  then 
	    	cycloneName = mw.wikibase.getLabel( cycloneID )
	    	--TODO get associated Wikipedia page for linking
	    end
	    -- if we have a valid cyclone id (note:Lua has no continue statement)
	    if cycloneID then 
	    	
	    	local feature = {name="",alias="",latitude=0,longitude=0,description="",image="",valid=false, path={} }
	    	local validFeatureData = true -- assume now 
	    	
		    -- (2) get feature parameters from module (n/a) or wikidata or both
		    
	        --[[if useModule then	-- get feature parameters from module data stadium list
	           feature = p.getModuleData(frame, stadiumName)
	        end]]
	        
	        if useWikidata and cycloneID then --and  feature['name'] == "" then -- get feature parameters from wikidata
	            feature = p.getDataFromWikiData(cycloneName,cycloneID)
	            if not feature['valid'] then -- no valid coordinates
	            	validFeatureData =false
	            	mw.addWarning( "No valid coordinates found for " .. cycloneName .. " (" .. cycloneID .. ")" )
	        	end
	        end
	        
	        ----------------------------------------------------
	        -- (3) data from template parameters will override those obtainied from a module table or wikidata
	        local templateArgs = {
		    		    latitude    = parent.args['latitude'..tostring(index)], 
					    longitude   = parent.args['longitude'..tostring(index)], 
				     	description = parent.args['description'..tostring(index)], 
				        image       = parent.args['image'..tostring(index)] 
				        }
	
		    if templateArgs['latitude'] and templateArgs['longitude']  then -- if both explicitly set by template
		    	feature['latitude'] = templateArgs['latitude']
		    	feature['longitude']= templateArgs['longitude']
		    	feature['name'] = cycloneName -- as we have valid coordinates
		    	validFeatureData =true
		    end
         
		    -- use specified description and image if provided
	    	if templateArgs['description']  then 
	    		feature['description'] = templateArgs['description']
	        end
	    	if templateArgs['image']  then 
	    		feature['image'] =  templateArgs['image']   -- priority for image from template argument
	        end 
	    	if feature['image'] ~= "" then feature['image'] = '[[' .. feature['image'] .. ']]' end
	    	
	    	-- wikilink - use redirect if alias
	    	if feature['alias'] ~= '' then
	    		feature['name'] = '[[' .. feature['name'] .. '|'.. feature['alias'] .. ']]'
	    	else
            	feature['name'] = '[[' .. feature['name'] .. ']]'
            end
            

    		if feature['image'] ~= "" then 
    			feature['description'] = feature['image']  .. feature['description'] 
    	    end

		    --check if current feature marker has specified color, size or symbol
		    local strokeColor = parent.args['stroke'..tostring(index)] or defaultProperties['stroke']
            if strokeColor == "auto" then strokeColor = nil end  -- if using auto color

           -- the feature properties are set by the indexed parameters or defaults (see above)
	       local featureProperties = {
		    	['marker-color']   = parent.args['marker-color'..tostring(index)]   or defaultProperties['marker-color'],
		    	['marker-symbol']  = parent.args['marker-symbol'..tostring(index)]  or defaultProperties['marker-symbol'],
		    	['marker-size']    = parent.args['marker-size'..tostring(index)]    or defaultProperties['marker-size'],	
		    	['stroke']         = strokeColor, --parent.args['stroke'..tostring(index)]         or defaultProperties['stroke'],	
		    	['stroke-width']   = parent.args['stroke-width'..tostring(index)]   or defaultProperties['stroke-width'],
		    	['stroke-opacity'] = parent.args['stroke-opacity'..tostring(index)] or defaultProperties['stroke-opacity'],

                -- these are for shapes drawn with polygon instead of the marker symbol
                ['symbol-stroke']         = parent.args['symbol-stroke'..tostring(index)]         or defaultProperties['symbol-stroke'],          -- nil default causes autocolor path; a value overrides autocolor
                ['symbol-fill']           = parent.args['symbol-fill'..tostring(index)]           or defaultProperties['symbol-fill'],   
                ['symbol-shape']          = parent.args['symbol-shape'..tostring(index)]          or defaultProperties['symbol-shape'],   
                ['symbol-size']           = parent.args['symbol-size'..tostring(index)]           or defaultProperties['symbol-size'],   
                ['symbol-stroke-width']   = parent.args['symbol-stroke-width'..tostring(index)]   or defaultProperties['symbol-stroke-width'],
                ['symbol-stroke-opacity'] = parent.args['symbol-stroke-opacity'..tostring(index)] or defaultProperties['symbol-stroke-opacity'],
                ['symbol-fill-opacity']   = parent.args['symbol-fill-opacity'..tostring(index)]   or defaultProperties['symbol-fill-opacity'] 
		    	}
		    	
	        --(4) construct the json for the features (if we have a storm with valid coordinates)
            if validFeatureData then
            	
		        local featureData = ""

		        if feature.path[1] then                                                 -- add path if multiple coordinates
		        	featureData = p.addPathFeatureCollection(feature,featureProperties) 
                else                                                                    -- else show single marker
                	-- make sure a marker color is set (if not set by template or not autocoloring storm path)
                	-- note the default colour is left as nil for the auto coloring of paths by storm type
                	--    and that this can be overriden with a value, but might be nil here
                	local markerColor = featureProperties['marker-color'] or "#0050d0"
		    		
		    		featureData = '{ "type": "Feature", ' 
		    	            .. ' "geometry": { "type": "Point", "coordinates": ['
		    	                             .. feature['longitude'] .. ',' 
		    	                             .. feature['latitude'] 
		    	                             .. '] }, ' 
		    	            .. ' "properties": { "title": "'      .. feature['name']  .. '", ' 
		    	                          .. '"description": "'   .. feature['description'] ..'", ' 
		    	                          .. '"marker-symbol": "' .. featureProperties['marker-symbol'] .. '", '
		    	                          .. '"marker-size": "'   .. featureProperties['marker-size'] .. '", ' 
		    	                          .. '"marker-color": "'  .. markerColor .. '"  } ' 
		    	            .. ' } '
		    	            
		        end
         
		    	if index > 1 and mapData ~= "" then
		    	    mapData = mapData .. ',' .. featureData 
		    	else
		    		mapData = featureData 
		    	end
		    else
		    	--mapData = '{  "type": "Feature",  "geometry": { "type": "Point", "coordinates": [-0.066417, 51.60475] }, "properties": { "title": "White Hart Lane (default)",  "description": "Stadium of Tottenham Hotspur F.C.", "marker-symbol": "soccer", "marker-size": "large",  "marker-color": "0050d0"   }  } '
			    mw.addWarning( "No valid information found for " .. cycloneName .. " (" .. cycloneID .. ")" )
			end -- if valid parameters
	    
	    
	    end -- end if if cycloneID
	 end -- end while loop
	 
	 --[[ (5) check for external data (geoshape) 
	        TODO add more than index=1 and generalise for any json feature
	 --]]
	 local geoshape = parent.args['geoshape'..tostring(1)] or ""
	 if geoshape ~= "" then 
	 	mapData = mapData .. ',' .. geoshape -- assumes at least one stadium
	 end 
	 
	 -- add outer bracket to json if more than one element
	 if index > 1 then
	 	mapData = '[' .. mapData .. ']'
	 	--mapData = ' {"type": "FeatureCollection", "features": [' .. mapData .. ']}' -- is there an advantage using this?
	 end
     
     return mapData
     
end -- End the function.

--[[ functions adding path to cyclone item 
		p.addPathFeatureCollection()    -- adds markers/symbols and lines for path of storm (cordinates from wikidata)
		p.addShapeFeature()             -- returns geoJson for the custom symbol
		p.getPolygonCoordinates()       -- returns coordinate set for the custom symbol (loop for diffent shapes)
		p.calculatePolygonCoordinates() -- calculates the coordinates for the specified shape
		p.getCycloneColor()             -- sets color of symbols/lines based on storm type (from wikidata)

--]]
p.addPathFeatureCollection=function(feature, featureProperties)
    
    if not feature.path[1] then return "" end  -- shouldn't be necessary now
 
    local mode  = mw.getCurrentFrame():getParent().args['mode']  or "default"


    
	local featureCollection = ""
	local sep = ""
	local i = 1
	table.sort (feature.path, function(a,b)
				                  if (a.timeStamp < b.timeStamp) then                --- primary sort on timeStamp
		                             return true
		                          else            
		                        	 return false
		                          end
		                      end)
	
	for i, v in pairs(feature.path) do 	
		
		local autoColor = p.getCycloneColor( feature.path[i]['cycloneType'], featureProperties )
		local markerColor = featureProperties['marker-color'] or autoColor
		local strokeColor = featureProperties['stroke'] or autoColor
		
		
		local longitude = feature.path[i]['longitude']
		local latitude = feature.path[i]['latitude'] 

		-- add a lines between the points (current point to the next point, if there is one)
		local lineFeature = ""
		if feature.path[i+1] then
			local longitude2 = feature.path[i+1]['longitude']
			local latitude2 = feature.path[i+1]['latitude'] 

			lineFeature  =   '{ "type": "Feature", ' 
		    	       .. ' "geometry": { "type": "LineString", "coordinates": ['
		    	                           .. '[' .. longitude .. ','  .. latitude .. '],'
		    	                           .. '[' .. longitude2 .. ','  .. latitude2 .. ']'
		    	                           .. '] }, ' 
		    	      .. ' "properties": {  "stroke": "' .. strokeColor .. '" , ' 
		    	                       .. ' "stroke-width": '  .. featureProperties['stroke-width'] .. ' , ' 
		    	                       .. ' "stroke-opacity": ' .. featureProperties['stroke-opacity'] 
		    	                          .. '  } ' 
		    	          .. ' } '		
			featureCollection = featureCollection .. sep .. lineFeature
			sep = ","
		end

		--[[ place mapframe markers and custom symbols on each object
		       mode="marker": use mapframe markers for mark storm objects
		       mode="test": use marker on first point of path and linePoint symbol
		       default: use custom polygons to mark storm objects
		 ]]
		if mode == "marker" or (mode == "test" and i==1) then 


			local pointFeature  =          '{ "type": "Feature", ' 
		    	            .. ' "geometry": { "type": "Point", "coordinates": [' .. longitude .. ','  .. latitude  .. '] }, ' 
		    	            .. ' "properties": { "title": "'  .. feature['name']  .. '", ' 
		    	                          .. '"description": "' .. feature['description'] .. '<br>Type: ' .. feature.path[i]['cycloneType']   .. '", ' 
		    	                          .. '"marker-symbol": "' .. featureProperties['marker-symbol'] .. '", '
		    	                          .. '"marker-size": "' .. featureProperties['marker-size'] .. '", ' 
		    	                          .. '"marker-color": "' .. markerColor .. '"  } ' 
		    	            .. ' } '		
			featureCollection = featureCollection .. sep .. pointFeature
			sep = ","

		elseif mode == "test"  then --  short lines (test) to mark with objects
			
			local dateString = " 2020-06"
			if feature.path[i]['timeStamp'] then 
				local formattedDate = Date(feature.path[i]['timeStamp']):text("dmy hm") 
				dateString = '<br/>date and time: ' .. formattedDate  --tostring( feature.path[i]['timeStamp'] )
			end
			local description = '<div>latitude: ' .. tostring(latitude)  
			               ..  '<br/>longitude: ' .. tostring(longitude) 
			               .. dateString
			               .. '</div>'
			
			local circleFeature  =  '{ "type": "Feature", ' 
		    	       .. ' "geometry": { "type": "LineString", "coordinates": ['
		    	                           .. '[' .. longitude .. ','  .. latitude .. '],'
		    	                           .. '[' .. (longitude) .. ','  .. (latitude) .. ']'
		    	                           .. '] }, ' 
		    	      .. ' "properties": {  "stroke": "' .. markerColor .. '" , ' 
		    	                       .. ' "stroke-width": 10, ' -- TODO change size based on marker size
		    	                       .. ' "description": "' .. description .. '"' 
		    	                          .. '  } ' 
		    	          .. ' } '		
			featureCollection = featureCollection .. sep .. circleFeature
			sep = ","
		
		else  -- use polygons (default if not marker)  to mark with objects

			featureCollection = featureCollection .. sep .. p.addShapeFeature(i, feature, featureProperties)
			sep = ","	
		end
		
		i=i+1    -- increment for next point in storm path
	end -- while/for in pairs
	
	if mw.getCurrentFrame():getParent().args['mode'] == "test3" then
		featureCollection = 
		 '{"type": "FeatureCollection", "features": [ {"type": "Feature","properties": {"marker-color": "#bbccff", "marker-symbol": "-number"}, "geometry": { "type": "Point", "coordinates": [80.298888888889,6.3316666666667]}}, {"type": "Feature","properties": {"marker-color": "#bbccff", "marker-symbol": "-number"}, "geometry": { "type": "Point", "coordinates": [80.263888888889,6.6644444444444]}}, {"type": "Feature","properties": {"marker-color": "#bbccff", "marker-symbol": "-number"}, "geometry": { "type": "Point", "coordinates": [80.434444444444,7.1883333333333]}}, {"type": "Feature","properties": {"marker-color": "#bbccff", "marker-symbol": "-number"}, "geometry": { "type": "Point", "coordinates": [80.656111111111,8.1086111111111]}}, {"type": "Feature","properties": {"marker-color": "#bbccff", "marker-symbol": "-number"}, "geometry": { "type": "Point", "coordinates": [80.9025,8.2961111111111]}}, {"type":"Feature", "properties": { "stroke":"#D3D3D3", "stroke-opacity":0.7, "stroke-width":50}, "geometry": {"type":"LineString", "coordinates": [[80.298888888889,6.3316666666667],[80.263888888889,6.6644444444444],[80.434444444444,7.1883333333333],[80.656111111111,8.1086111111111],[80.9025,8.2961111111111]]}} ]}'
	end
	--return  sep .. featureCollection
	return   featureCollection
end
--[[ function p.addShapeFeature(i, feature, featureProperties)
		
		function adding shape features using polygon type: square, triangle, stars, etc 
]]
p.addShapeFeature =function(i, feature, featureProperties)
	
	local size =  featureProperties['symbol-size']
	local shape = featureProperties['symbol-shape']                      -- symbol for tropical cyclone
    if feature.path[i]['cycloneType2'] == 'extratropical cyclone' then   
    	shape = 'triangle'                                               -- symbol for extratropical cyclone (Q1063457) 
    elseif feature.path[i]['cycloneType2'] == 'subtropical cyclone' then  
    	shape = 'square'                                                 -- symbol for subtropical cyclone (Q2331851)
    end
    local autoColor = p.getCycloneColor( feature.path[i]['cycloneType'], featureProperties )
	--local markerColor = featureProperties['symbol-color'] or autoColor
	local strokeColor = featureProperties['symbol-stroke'] or autoColor
	local fillColor = featureProperties['symbol-fill'] or autoColor
	
	local longitude = feature.path[i]['longitude']
	local latitude = feature.path[i]['latitude'] 

	local description = '<div style=\\"text-align:left;\\"> '  
			        
			   --     .. '<br/>date: ' .. mw.language.getContentLanguage():formatDate('d F Y', feature.path[i]['timeStamp'])  
			        .. '<br/>date: ' .. Date(feature.path[i]['timeStamp']):text("dmy")    -- :text("dmy hm") 
			        .. '<br/>type: ' .. tostring(feature.path[i]['cycloneType'])
			        .. '<br/>longitude: ' .. fn.formatNum(longitude,"en",6) 
			        .. '<br/>latitude: '  .. fn.formatNum(latitude,"en",6)  
			        .. '</div>'
	
	local shapeFeature =""
	--shape="circle"
	shapeFeature  = ' { "type": "Feature", ' 
	    	       .. ' "geometry":  {  "type": "Polygon", '
	    	                       .. ' "coordinates": [ ' .. p.getPolygonCoordinates(shape, size, latitude, longitude) ..' ] '
	    	                       .. ' }, ' 
	    	       .. ' "properties": { "stroke": "' .. strokeColor .. '" , ' 
	    	                       .. ' "fill": "' .. fillColor .. '" ,' 
	    	                       .. ' "fill-opacity": 1, ' 
	    	                       .. ' "stroke-width": ' .. featureProperties['symbol-stroke-width'] .. ','
	    	                       .. ' "description": "' .. description .. '"' 
	    	                       .. '  } ' 
	    	          .. ' } '		
    -- if shape==cyclone, a circle shape will have been drawn; now add the tails
	if shape=="cyclone"  then		 -- superimpose a second shape
		local shape2="cyclone_tails"
		shapeFeature  = shapeFeature  .. ', '
		           .. '{ "type": "Feature", ' 
	    	       .. ' "geometry":  {  "type": "Polygon", '
	    	                       .. ' "coordinates": [ ' .. p.getPolygonCoordinates(shape2, size, latitude, longitude) ..' ] '
	    	                       .. ' }, ' 
	    	      .. ' "properties": {  "stroke": "' .. strokeColor .. '" , ' 
	    	                       .. ' "fill": "' .. fillColor .. '" ,' 
	    	                       .. ' "fill-opacity": 1, ' 
	    	                       .. ' "stroke-width": ' .. 0 .. ','
	    	                       .. ' "description": "' .. description .. '"' 
	    	                       .. '  } ' 
	    	          .. ' } '		
			
	end
	
	return shapeFeature
end
p.getPolygonCoordinates = function(shape, size, latitude, longitude)
	
    -- shape = "circle"
    -- shape ="spiral"
	
	local coordinates = "" 
	if shape == "square"  then 
		coordinates = '	[ '
	    	                           .. '[' .. (longitude+size) .. ','  .. (latitude+size) .. '],'
	    	                           .. '[' .. (longitude+size) .. ','  .. (latitude-size) .. '],'
	    	                           .. '[' .. (longitude-size) .. ','  .. (latitude-size) .. '],'
	    	                           .. '[' .. (longitude-size) .. ','  .. (latitude+size) .. '],'
	    	                           .. '[' .. (longitude+size) .. ','  .. (latitude+size) .. ']'
	    	                           .. '] '
	elseif shape == "triangle2"  then 
		coordinates = '	[ '
	    	                           .. '[' .. (longitude) .. ','  .. (latitude+size) .. '],'
	    	                           .. '[' .. (longitude+size) .. ','  .. (latitude-size) .. '],'
	    	                           .. '[' .. (longitude-size) .. ','  .. (latitude-size) .. '],'
	    	                           .. '[' .. (longitude) .. ','  .. (latitude+size) .. ']'
	    	                           .. '] '
	elseif shape == "inverse-triangle"  then 
		coordinates = '	[ '
	    	                           .. '[' .. (longitude) .. ','  .. (latitude-size) .. '],'
	    	                           .. '[' .. (longitude+size) .. ','  .. (latitude+size) .. '],'
	    	                           .. '[' .. (longitude-size) .. ','  .. (latitude+size) .. '],'
	    	                           .. '[' .. (longitude) .. ','  .. (latitude-size) .. ']'
	    	                           .. '] '
	elseif shape == "star2"  then 
		--size = size * 5
		coordinates = ' [ '
                       .. '[' .. longitude            .. ','  .. latitude+(size*1.2) .. '],'     -- top point
                       .. '[' .. longitude+(size*0.2) .. ','  .. latitude+(size*0.2) .. '],'
                       .. '[' .. longitude+(size*1.2) .. ','  .. latitude+(size*0.4) .. '],'     -- 2pm point
                       .. '[' .. longitude+(size*0.3) .. ','  .. latitude-(size*0.1) .. '],'
                       .. '[' .. longitude+(size)     .. ','  .. latitude-(size)     .. '],'     -- 5pm point
                       .. '[' .. longitude            .. ','  .. latitude-(size*0.3) .. '],'     -- 6pm (innner)
                       .. '[' .. longitude-(size)     .. ','  .. latitude-(size)     .. '],'     -- 7pm point
                       .. '[' .. longitude-(size*0.3) .. ','  .. latitude-(size*0.1) .. '],'
                       .. '[' .. longitude-(size*1.2) .. ','  .. latitude+(size*0.4) .. '],'     -- 10pm point
                       .. '[' .. longitude-(size*0.2) .. ','  .. latitude+(size*0.2) .. '],'
                       .. '[' .. longitude            .. ','  .. latitude+(size*1.2) .. ']'      -- top point (close)
                    .. '] '

	elseif shape == "circle2"  then 
		
		local  radius = size
		coordinates = coordinates   .. ' [ '
		for angle = 0, 360, 3 do
        	if angle > 0 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude +(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude  +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 
        
	elseif shape == "cyclone_tails"  then 

		local  radius = size*2
		-- add tail at 3 o'clock
		coordinates = coordinates   .. ' [ '
		for angle = 0, 60, 3 do
        	if angle > 0 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude-size+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 

		-- add tail at 9 o'clock
		coordinates = coordinates   .. ', [ '
		for angle = 180, 240, 3 do
        	if angle > 180 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude+size+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 
        
		-- add tail at 6 o'clock
		coordinates = coordinates   .. ', [ '
		for angle = 270, 330, 3 do
        	if angle > 270 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude+size +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 

		-- add tail at 6 o'clock
		coordinates = coordinates   .. ', [ '
		for angle = 90, 150, 3 do
        	if angle > 90 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude-size +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 
        
        --[[ for adding circle
        local  radius = size
		coordinates = coordinates   .. ', [ '
		for angle = 0, 360, 3 do
        	if angle > 0 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        end
        coordinates = coordinates   .. '] ' 
        --]]
	elseif shape == "spiral"  then 

		coordinates = ' [ '
		local radius = size*0.01
		for angle = 0, 360*4, 4 do
			radius = radius + size*0.01
        	if angle > 0 then coordinates = coordinates .. ',' end
        	coordinates = coordinates  .. '[' .. longitude+(radius*math.cos(math.rad(angle)))    .. ','  
        	                                  .. latitude +(radius*math.sin(math.rad(angle))) 
        	                                  .. ']'     
        	                                  
        end
        coordinates = coordinates   .. '] ' 
	elseif shape == "circle" or shape == "cyclone" then                          -- circle as 120 sided polygon
        return p.calculatePolygonCoordinates(120, 1, size, latitude, longitude) 
    elseif shape == "triangle"  then
        return p.calculatePolygonCoordinates(3, 1, size, latitude, longitude)
    elseif shape == "diamond"  then
        return p.calculatePolygonCoordinates(4, 1, size, latitude, longitude)
    elseif shape == "hexagon"  then
        return p.calculatePolygonCoordinates(6, 1, size, latitude, longitude)
    elseif shape == "octagon"  then
        return p.calculatePolygonCoordinates(8, 1, size, latitude, longitude)
    elseif shape == "star4"  then
        return p.calculatePolygonCoordinates(8, 3, size, latitude, longitude)
    elseif shape == "star5"  then
        return p.calculatePolygonCoordinates(10, 3, size, latitude, longitude)
    elseif shape == "star8"  then
        return p.calculatePolygonCoordinates(16, 3, size, latitude, longitude)
    elseif shape == "star12"  then
        return p.calculatePolygonCoordinates(24, 3, size, latitude, longitude)
    elseif shape == "star"  then
        return p.calculatePolygonCoordinates(10, 2, size, latitude, longitude)
    end
    
    return coordinates
end
--[[   p.calculatePolygonCoordinates(sides, ratio, size, latitude, longitude)   
 
            calculates coordinates for polygons or stars
            a star is a polygon with alternate points with different radii (determined by ratio)
            
            sides: number of sides on polygon
                   for a star this is twice the number of points of the star
            ratio: ratio of inner and outer radii for a star (a higher number makes a more pointy star)
                   use 1 for a simple polygon 
            size:  the outer radius of the a circle surrounding the polygon
            latitude and longitude: self explanatory
]]
p.calculatePolygonCoordinates = function(sides, ratio, size, latitude, longitude)
	
		local coordinates = ' [ '

		local outer = true
		local radius = size
		for angle = 0, 360, 360/sides do
        	if angle > 0 then coordinates = coordinates .. ',' end   -- important for geojson structure (unlike Lua)
        	
         	if radius ~= 1 then                                               -- if a star
        		if outer then radius = size else radius = size/ratio end      -- alternate inner and outer radius
        		outer = not outer
        	end
        	
        	coordinates = coordinates  .. '[' .. longitude+(radius*math.sin(math.rad(angle)))    .. ','  
        	                                  .. latitude +(radius*math.cos(math.rad(angle))) 
        	                                  .. ']'     
        end
        return  coordinates   .. '] ' 	
        
end
--[[     p.getCycloneColor=function(cycloneType, featureProperties)
    
    sets color of symbols/lines based on storm type (from wikidata)
]]
p.getCycloneColor=function(cycloneType, featureProperties)
	
	--[[ codors from "Tropical cyclone scales" article
          	#80ccff		Depression, Zone of Disturbed Weather, Tropical Disturbance (?) 	
          	#5ebaff		Tropical Depression, Deep Depression 
          	            Tropical Disturbance (?), Tropical Depression, Tropical Low
          	#00faf4 	tropical storm, moderate tropical storm, cyclonic storm, Category 1 Tropical Cyclone
          	#ccffff 	severe cyclonic storm, severe tropical storm, Category 1 Hurricane 
          	#ffffcc		Very Severe Cyclonic Storm 	Tropical Cyclone 
	        #fdaf9a		Typhoon
	        #ffc140		Very Strong Typhoon, Extremely Severe Cyclonic Storm, Intense Tropical Cyclone 	Category 4
			#ff6060 	Violent Typhoon, Category 5 Severe Tropical Cyclone, Super Typhoon, 
						Super Cyclonic Storm, Very Intense Tropical Cyclone, Category 5 Major Hurricane 
	
	]]
	local color = "#000000"
	cycloneType = string.lower(cycloneType)
	if cycloneType == "depression"  or cycloneType == "zone of disturbed weather" or cycloneType == "Tropical disturbance"
	    	then color = "#80ccff"
	    	elseif cycloneType == "tropical depression" or cycloneType == "deep depression"  or cycloneType == "tropical Depression" 
														or cycloneType == "tropical low"
			then color = "#5ebaff"
	elseif cycloneType == "cyclonic storm" or cycloneType == "tropical storm" or cycloneType == "moderate tropical storm" 
	                                                    or cycloneType == "category 1 tropical cyclone"
			then color = "#00faf4"  
	elseif cycloneType == "severe cyclonic storm" or cycloneType == "severe tropical storm" or cycloneType == "category 1 hurricane"
			then color = "#ccffff"
	elseif cycloneType == "very severe cyclonic storm" or cycloneType == "tropical cyclone"
	        then color = "#ffffcc"  
    elseif cycloneType == "typhoon"
	        then color = "#fdaf9a"  
	elseif cycloneType == "very strong typhoon" or cycloneType == "extremely severe cyclonic storm" or cycloneType == "intense tropical cyclone" 
	                                            or cycloneType == "category 4 severe tropical storm"
	        then color = "#ffc140"  
	elseif cycloneType == "violent typhoon"     or cycloneType == "category 5 severe tropical cyclone" or cycloneType == "super typhoon" 
						                        or cycloneType == "super cyclonic storm" or cycloneType == "very intense tropical cyclone" 
						                        or cycloneType == "category 5 major hurricane"
	        then color = "#ff6060"  
          			 
	        
	        
			 	
	
	end
	return color
end



--[[-------------------------------Retrieve information from wikidata-------------------------
 
	statements of interest (datavalue element)
		item = mw.wikibase.getEntity(WikidataId), 
		statements = item:getBestStatements('P625')[1]
    	"claims":
			P625 coordinate location (value.longitude/latitude)
			   "P625":[{ "mainsnake": { ... "datavalue": { "value": {"latitude": 51.4, "longitude": -0.19] ...
			   statements.mainsnak.datavalue.value.latitude
			P18 image on commons (value, "File:value")
		   	   "P18":[{ "mainsnake": { ... "datavalue": { "value": "Stamford Bridge Clear Skies.JPG"
			P1566 GeoNames ID (value, "geonames.org/value")
			P31 (instance of) Q483110 (stadium)
			   "P18":[{ "mainsnake": { ... "datavalue": { "value": { "id": "Q483110"
			   however also sports venue, olympic stadium, association football stadium
			P159 headquarters location (for football club) 
			   e..g. London
			   qualifier property: coordinates(P625)
    page title on enwiki
    	mw.wikibase.getSitelink( itemId ) - gets local version
    	"sitelink": { "enwiki": { "title": "Hurricane Katrina" }
    other properties of possible interest:
    	P276 location
		P17 country
		P580 start time
		P582 end time
		P1120 number of deaths
		P2630 cost of damage
		P2532 lowest atmospheric pressure
		P2895 maximum sustained winds

--]]
p.getDataFromWikiData=function(cycloneName,cycloneID)
    
    local wd={name="",latitude="",longitude="",description="",image="",alias="",type="",valid=false, path = {} }
    
	-- 	get wikidata id corresponding to wikipedia stadium page
	--local WikidataId = mw.wikibase.getEntityIdForTitle(cycloneName)
	local WikidataId = cycloneID
	if not cycloneName then cycloneName = "unnamed" end --TODO get the name
  
	if WikidataId and mw.wikibase.isValidEntityId( WikidataId ) then -- valid id
    	
    	local item = mw.wikibase.getEntity(WikidataId)
        if not item then return wd end -- will test for wiki

    	local enwikiTitle =	mw.wikibase.getSitelink( WikidataId ) -- name of local Wikipedia page
    	local wikidataTitle = mw.wikibase.getLabel( WikidataId  ) -- name of Wikidata page
    	if enwikiTitle and wikidataTitle and enwikiTitle ~= wikidataTitle then
    	    wd['alias'] = wikidataTitle
    		wd['name'] =cycloneName 
	    else
    		wd['name'] =cycloneName 
    	end
    	
    	-- get storm type P31 instance of 
    	local statements = item:getBestStatements('P31') --coordinate location 
        if statements  and statements[2] then -- check cordinates available
	    	local type = statements[2].mainsnak.datavalue.value.id or ""
	    	wd['type'] = mw.wikibase.getLabel( type )
    	end
    	
        -- get coordinates
    	local statements = item:getBestStatements('P625')[1] --coordinate location 
        if statements ~= nil then -- check cordinates available
	    	local coord = statements.mainsnak.datavalue.value
	    	if type(coord.latitude) == 'number' and type(coord.longitude) == 'number' then 
        	    -- add coordinate data from wikidata for unindexed stadium
	        	wd['latitude'] = coord.latitude
	        	wd['longitude'] = coord.longitude
	            wd['valid'] = true
                
                -- if we have a path of coordinates
                if item:getBestStatements('P625')[2] then  -- TODO make sure ordinal number
			        local i = 1
			        
			        while  item:getBestStatements('P625')[i]  do
			        -- get coordinates
				    	local statements = item:getBestStatements('P625')[i] --coordinate location 
				        if statements ~= nil then -- check cordinates available
					    	local coord = statements.mainsnak.datavalue.value
					    	if type(coord.latitude) == 'number' and type(coord.longitude) == 'number' then 
				        	    -- add coordinate data from wikidata for path
				        	    wd.path[i] = {}
					        	wd.path[i].latitude = coord.latitude
					        	wd.path[i].longitude = coord.longitude
					        	
					        	-- get series ordinal as index (now removed so set to i)
					        	-- TODO sort based on point in time, i.e. wd.path(i).timeStamp 
					            wd.path[i].index = i -- statements.qualifiers['P1545'][1]['datavalue']['value']    -- P1545 = series ordinal {a number]
					            
					            -- get storm type using instance of (P31)
					            local cycloneType =  statements.qualifiers['P31'][1]['datavalue']['value']['id'] -- P31 = instance of [cyclone type]
					            if cycloneType then wd.path[i].cycloneType =  mw.wikibase.getLabel( cycloneType ) end
					            -- get storm type using instance of (P31)
					            if statements.qualifiers['P31'][2] then
					            	cycloneType =  statements.qualifiers['P31'][2]['datavalue']['value']['id'] -- P31 = instance of [cyclone type]
					            	if cycloneType then wd.path[i].cycloneType2 =  mw.wikibase.getLabel( cycloneType ) end
					            end
					            
					            --get point in time (P585) qualifier
					            local timeStamp = statements.qualifiers['P585'][1]['datavalue']['value']['time']
					            if timeStamp then wd.path[i].timeStamp = timeStamp end
					            
				        	end
				        end
				        i=i+1
			        end -- end while loop
			    end
        	
        	
        	end
        end -- end if coordinate statements
	
    	
    	--get image
    	statements = item:getBestStatements('P18')[1] --image
    	if statements ~= nil then 
           wd['image'] = 'File:' .. statements.mainsnak.datavalue.value
    	end

        
    end

    return wd

end
	

--[[------------------------------------------------------------------------------
	This function gets data from a module subpage (not implemented)
--------------------------------------------------------------------------------]]
p.getModuleData = function (frame, stormName)
	
     	local feature = {}
     	feature['name'] =  ""
	    --feature['data'] = ""
	    feature['alias'] = ""
	    feature['description'] =  ""
	    feature['image'] = ""
	    
		    -- check the module storm list for name match
		    --  set feature parameters from the module data
		    for _, params in pairs( stormDatabase.storm ) do
		    	if stormName == params[1] then -- if we have a match from the list
		    		feature['name'] = params[1]
		    		feature['latitude'] = params[2]
		    		feature['longitude'] = params[3]
		    		feature['alias'] = params[4]
		    		feature['description'] = params[5]
		    		feature['image'] =  params[6] 
		    		break
		        end
		    end
    return feature
end

-- All modules end by returning the variable containing its functions to Wikipedia.
return p