--require('Module:No globals')
-- All Lua modules on Wikipedia must begin by defining a variable that will hold their
-- externally accessible functions. They can have any name and may also hold data.
local p = {}

local stadiumDatabase = require( "Module:Football map/data" ) -- configuration module
                          
-- main function callable in Wikipedia via the #invoke command.
p.main = function(frame) 
	str = p.getMapframeString()
	return frame:preprocess(str)   -- the mapframe needs to be preprocessed!!!!!
end  -- End the function.

--[[ function to construct mapframe string
--]]
p.getMapframeString = function(frame) 

    --get mapframe arguments from calling templates
    local parent = mw.getCurrentFrame():getParent() 
  
    --[[local mapParams = { width     = parent.args['width'] or "400",
					    height    = parent.args['height'] or "300",
					    latitude  = parent.args['latitude'] or "51.5",
					    longitude = parent.args['longitude'] or "-0.15",
					    align     = parent.args['align'] or "right",
					    text      = parent.args['text'] or "",
					    zoom      = parent.args['zoom'] or "9" }--]]
    
    -- get JSON data for features to display
    local mapData = p.getStadiumJSON()
    
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
	    local width = parent.args['width']                                  --or "400"
	    local height = parent.args['height'] or (width or 300)/aspect     --or "300"
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
	    
	    mapString = mapString  .. ' >'  .. mapData  .. '</mapframe>'   -- add data and close tag
	    
	    --[[mapString = mapString  
	                      ..' width=' .. (parent.args['width'] or "400" )
	                      .. ' height=' .. (parent.args['height'] or "300")
	                      .. ' align=' .. (parent.args['align'] or "right") 
	                      .. ' zoom=' .. (parent.args['zoom'] or "9" )
	                      .. ' latitude=' .. (parent.args['latitude'] or "51.5")
	                      .. ' longitude=' .. (parent.args['longitude'] or "-0.15")
	                      .. ' >'
	                  .. mapData 
	               .. '</mapframe>'
	       ]]
    else
    	mapString = "No data for map"
    end
    
    return mapString    

end  -- End the function.

--[[ function to construct JSON format data for markers on map.
     The information for each marker (coordinate, description and image for popup, etc) 
     can be set in several ways (in order of priority):
      (1) using arguments in the template (|imageN=, |descriptionN=)
      (2) from values in the data module (i.e. Module:Football map/data)
      (3) from Wikidata
]]
p.getStadiumJSON = function(frame) 

    -- now we need to iterate through the stadiumN parameters and get data for the feature markers
    local maxNumber = 200 -- maximum number looked for
    local mapData = ""
    local stadiumName = ""
    local clubName = ""
    
     --get mapframe arguments from calling templates
    local parent = mw.getCurrentFrame():getParent() 
   
    --[[There are three ways of getting data about the stadium features
        (1) from a list in the module subpages
        (2) from wikidata 
        (3) from the parameters in the template (these always override other)
        By default 
        The parameters useWikiData, useModule restrict use of source
    --]]
    local useWikidata = true
    local useModule = true
    
    if parent.args['wikidata'] then useWikidata = true; useModule = false end -- use wikidata or template data (no module data)
    if parent.args['moduledata'] then useModule = true; useWikidata = false end -- use module of template data (no wikidata)
    if parent.args['templatedata'] then useModule = false; useWikidata = false end -- only use template data
    
    -- default parameters for marker color, size and symbol (i.e. those without index suffix)
    local defaultMarker ={  color = parent.args['color'] or  "0050d0",
    	                    size  = parent.args['size'] or "medium",
    	                    symbol = parent.args['symbol'] or "soccer"  }
    local index=0
    while index < maxNumber do 
    	
    	index = index + 1
	    local stadiumID = ""
	  
	    -- (1) get stadium name  
	    stadiumName = parent.args['stadium'..tostring(index)] --or ""
	    
	    if not stadiumName  then -- name from |stadiumN parameter,
	    	clubName = parent.args['club'..tostring(index)] or ""
	    	if clubName ~= "" then
	    		stadiumName, stadiumID = p.getStadiumFromClubName(clubName)
	    	end
	    end    
	    
	    -- if we have a valid stadium name (note:Lua has no continue statement)
	    if stadiumName then 
	    	
	    	local feature = {name="",alias="",latitude=0,longitude=0,description="",image="",valid=false}
	    	local validFeatureData =true -- assume now and
	    	
		    -- (2) get feature parameters from module or wikidata or both
		    
	        if useModule then	-- get feature parameters from module data stadium list
	           feature = p.getModuleData(frame, stadiumName)
	        end
	        
	        if useWikidata and  feature['name'] == "" then -- get feature parameters from wikidata
	            feature = p.getDataFromWikiData(stadiumName,stadiumID)
	            if not feature['valid'] then validFeatureData =false end -- no valid coordinates
	        end
	        
	        ----------------------------------------------------
	        -- (3) data from template parameters will override those obtainied from a module table or wikidata
	        local templateArgs = {
		    		    latitude = parent.args['latitude'..tostring(index)], --or 0,
					    longitude= parent.args['longitude'..tostring(index)], --or 0,
				     	description = parent.args['description'..tostring(index)], --or "",
				        image = parent.args['image'..tostring(index)] --or "" 
				        }
	
		    if templateArgs['latitude'] and templateArgs['longitude']  then -- if both explicitly set 
		    	feature['latitude'] = templateArgs['latitude']
		    	feature['longitude']= templateArgs['longitude']
		    	feature['name'] = stadiumName -- as we have valid coordinates
		    	validFeatureData =true
		    end
         
		    -- use specified description and image if provided
	    	if templateArgs['description']  then 
	    		feature['description'] = templateArgs['description']
	        end
	    	if templateArgs['image']  then 
	    		feature['image'] =  templateArgs['image']   -- priority for image from template argument
	        end 
	    	if feature['image'] ~= "" then feature['image'] = '[[' .. mw.text.encode(feature['image']) .. ']]' end
	    	
	    	-- wikilink - use redirect if alias
	    	if feature['alias'] ~= '' then
	    		feature['name'] = '[[' .. feature['name'] .. '|'.. feature['alias'] .. ']]'
	    	else
            	feature['name'] = '[[' .. feature['name'] .. ']]'
            end
            
            if clubName ~= "" then 
            	--feature['name'] = '[[' .. clubName .. ']] (' .. feature['name'] ..')'
            	if stadiumName ~= "" then
            		feature['description'] = '[[' .. stadiumName .. ']]. ' .. feature['description'] 
            	end
            	feature['name'] = '[[' .. clubName .. ']]' 
            end
    		if feature['image'] ~= "" then 
    			feature['description'] = feature['image']  .. feature['description'] 
    	    end

		    --check if current feature marker has specified color, size or symbol
	       local featureMarker ={
		    	color = parent.args['color'..tostring(index)] or defaultMarker['color'],
		    	symbol = parent.args['symbol'..tostring(index)] or defaultMarker['symbol'],
		    	size = parent.args['size'..tostring(index)] or defaultMarker['size']	}
		    	
	        --  if we have a stadium with valid coordinates
            if validFeatureData then
	
		    	--(4) construct the json for the features
		    	
		    	--mapData = mapStadium1
		    	featureData = '{ "type": "Feature", ' 
		    	            .. ' "geometry": { "type": "Point", "coordinates": ['
		    	                             .. feature['longitude'] .. ',' 
		    	                             .. feature['latitude'] 
		    	                             .. '] }, ' 
		    	            .. ' "properties": { "title": "'  .. feature['name']  .. '", ' 
		    	                          .. '"description": "' .. feature['description'] ..'", ' 
		    	                          .. '"marker-symbol": "' .. featureMarker['symbol'] .. '", '
		    	                          .. '"marker-size": "' .. featureMarker['size'] .. '", ' 
		    	                          .. '"marker-color": "' .. featureMarker['color'] .. '"  } ' 
		    	            .. ' } '
		    	
		    	if index > 1 and mapData ~= "" then
		    	    mapData = mapData .. ',' .. featureData
		    	else
		    		mapData = featureData 
		    	end
		    else
		    	--mapData = '{  "type": "Feature",  "geometry": { "type": "Point", "coordinates": [-0.066417, 51.60475] }, "properties": { "title": "White Hart Lane (default)",  "description": "Stadium of Tottenham Hotspur F.C.", "marker-symbol": "soccer", "marker-size": "large",  "marker-color": "0050d0"   }  } '
			end -- if valid parameters
	    end -- end if stadiumName
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
	 end
     
     return mapData
     
end -- End the function.



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
			P466 occupant (value.id) (use )
			P1083 capacity (value.amount)
			   "P1083":[{ "mainsnake": { ... "datavalue": { "value": { "amount" : "+41875" ...
			P571 inception (value), P576 demolished (value)
			P1566 GeoNames ID (value, "geonames.org/value")
			P84 architect
			P137 operator, P127 owned by
			P31 (instance of) Q483110 (stadium)
			   "P18":[{ "mainsnake": { ... "datavalue": { "value": { "id": "Q483110"
			   however also sports venue, olympic stadium, association football stadium
			P159 headquarters location (for football club) 
			   e..g. London
			   qualifier property: coordinates(P625)
    page title on enwiki
    	mw.wikibase.getSitelink( itemId ) - gets local version
    	"sitelink": { "enwiki": { "title": "Stamford Bridge (stadium)" 
    	    
    ERROR NOTE there was an error is caused when a supposed stadium redirected to page with no coordinates
      e.g  Fortress Stadium, Bromley was redirecting to Bromley F.C., 
      this had a valid Wiki ID and item but no coordinates
    	  1. it is handled by setting wd['valid'] when there are valid coordinates
    	  2. an alternative would We could check it is a stadium
    	       if P31 (instance of ) Q483110 (stadium)
--]]
p.getDataFromWikiData=function(stadiumName,stadiumID)
    
    local wd={name="",latitude="",longitude="",description="",image="",alias="",valid=false }
    
	-- 	get wikidata id corresponding to wikipedia stadium page
	local WikidataId = mw.wikibase.getEntityIdForTitle(stadiumName)

	if WikidataId and mw.wikibase.isValidEntityId( WikidataId ) then -- valid id
    	
    	local item = mw.wikibase.getEntity(WikidataId)
        if not item then return wd end -- will test for wiki

    	local enwikiTitle =	mw.wikibase.getSitelink( WikidataId ) -- name of local Wikipedia page
    	local wikidataTitle = mw.wikibase.getLabel( WikidataId  ) -- name of Wikidata page
    	if enwikiTitle and wikidataTitle and enwikiTitle ~= wikidataTitle then
    	    wd['alias'] = wikidataTitle
    		wd['name'] =stadiumName 
	    else
    		wd['name'] =stadiumName 
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
        	end
    	end
    	
    	--get image
    	statements = item:getBestStatements('P18')[1] --image
    	if statements ~= nil then 
           wd['image'] = 'File:' .. statements.mainsnak.datavalue.value
    	end
    	-- get occupants  --TODO check for multi-occupancy
        statements = item:getBestStatements('P466')[1] --occupant (i.e football club)
    	if statements ~= nil then 
    		local clubID = statements.mainsnak.datavalue.value.id
            if clubID then
            	local clubName = mw.wikibase.getLabel( clubID  )
            	wd['description'] = '<small>Home ground of ' .. clubName .. '</small>'
            end
        end
        
        -- get capacity
        statements = item:getBestStatements('P1083')[1] --mcapacity
    	if statements ~= nil then 
    		local capacity = tonumber(statements.mainsnak.datavalue.value.amount)
    		if capacity then 
    			wd['description'] = wd['description'] .. '<small> (capacity: ' .. capacity .. ')</small>' 
    		end
        end
    end

    return wd

end
	
----------------------------------------------
p.getStadiumFromClubName = function(clubName)
	    	
	-- let us assume the club name has a wikipedia page with the extact same name

	local wdId = mw.wikibase.getEntityIdForTitle(clubName)
	
	if wdId and mw.wikibase.isValidEntityId( wdId ) then -- if valid id
    	local item = mw.wikibase.getEntity(wdId)
    	mw.logObject( mw.wikibase.getBestStatements( 'Q18721', 'P115' ) )
    	--local statements = mw.wikibase.getBestStatements( 'Q18721', 'P115' )[1] 
    	local statements = item:getBestStatements('P115')[1] --home venue
        if statements ~= nil then -- check cordinates available
	    	
			local stadiumID = statements.mainsnak.datavalue.value.id
            -- P115 doesn't seem to have the stadium name (P115 is type "Item") 
            --- other properties (e.g. stadium name) would need to be got from the ID
            local stadiumName = mw.wikibase.getLabel( stadiumID  )
            --stadiumName = clubName -- if the marker is to be labelled with club name
            
            local enwikiTitle =	mw.wikibase.getSitelink( stadiumID )
            
            return enwikiTitle, stadiumID
            --return stadiumName, stadiumID
    	end
    end	  	
    return ""
end
--------------------------------------------------------------------------------
p.getModuleData = function (frame, stadiumName)
	
     	local feature = {}
     	feature['name'] =  ""
	    --feature['data'] = ""
	    feature['alias'] = ""
	    feature['description'] =  ""
	    feature['image'] = ""
	    
		    -- check the module stadium list for name match
		    --  set feature parameters from the module data
		    for _, params in pairs( stadiumDatabase.stadia ) do
		    	if stadiumName == params[1] then -- if we have a match from the list
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

-- function to construct JSON string for WHL in London map
p.getTestJSONstring = function(frame) 
   
    return '{  "type": "Feature",  "geometry": { "type": "Point", "coordinates": [-0.066417, 51.60475] }, "properties": { "title": "White Hart Lane",  "description": "Stadium of Tottenham Hotspur F.C.", "marker-symbol": "soccer", "marker-size": "large",  "marker-color": "0050d0"   }  } '

end  -- End the function.

-- function to construct JSON string
p.getJSONstring = function(frame) 

    local stadiumName = mw.getCurrentFrame():getParent().args['stadium1'] or "default name"

    local str=stadiumName
    local jsonString = '{   "type": "Feature", '
    jsonString = jsonString .. ' "geometry": { "type": "Point", "coordinates": [-0.065833, 51.603333] }, '
    jsonString = jsonString .. ' "properties": {     "title": "[[White Hart Lane]]", '
    jsonString = jsonString .. ' "description": "[[File:White Hart Lane Aerial.jpg|150px]]Tottenham Hotspur Football Club (1899-2017)", '
    jsonString = jsonString .. ' "marker-symbol": "-number", "marker-size": "small", "marker-color": "dd50d0"  } } '
    
    --mapString = mapString ..  '</mapframe>'
   jsonString = '{  "type": "Feature",  "geometry": { "type": "Point", "coordinates": [-0.066417, 51.60475] }, "properties": { "title": "[[Northumberland Development Project]]",  "description": "[[File:NDProject2015.jpg|100px]]", "marker-symbol": "soccer", "marker-size": "large",  "marker-color": "0050d0"   }  } '
   
   jsonString = '{  "type": "Feature",  "geometry": { "type": "Point", "coordinates": [-0.066417, 51.60475] }, "properties": { "title": "title",  "description": "description", "marker-symbol": "soccer", "marker-size": "large",  "marker-color": "0050d0"   }  } '
    
    str = '<nowiki>' .. jsonString .. '</nowiki>'
    --str =  jsonString 

    return str    


end   -- End the function.

-- All modules end by returning the variable containing its functions to Wikipedia.
return p

-- We can now use this module by calling {{#invoke: HelloWorld | hello }}.
-- The #invoke command begins with the module's name, in this case "HelloWorld",
-- then takes the name of one of its functions as an argument, in this case "hello".