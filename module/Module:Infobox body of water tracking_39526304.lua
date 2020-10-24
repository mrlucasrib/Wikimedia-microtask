local p = {}

function p.tracking(frame)
    local function isblank( val ) 
        return (val == nil) or val:match('^[%s]*$')
    end
    
    local function hasnoconvert( val )
    	local res = nil
    	val = mw.text.killMarkers(val)
    	if val:match('[0-9]') then
    		res = 1
    		if val:match('[%(][−0-9%.]') and val:match('[%)]') then
    			res = nil
    		end
		end
		return res
	end
    
    local cats = ''
    local maincats = ''
    local args = frame:getParent().args
    local AZ = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local warnmsg = {}
    
    if isblank(args['image']) then
    	maincats = maincats .. '[[Category:Articles using infobox body of water without image]]'
    elseif isblank(args['alt']) then
		maincats = maincats .. '[[Category:Articles using infobox body of water without alt]]'
    end
    
    if isblank(args['coords']) and isblank(args['coordinates']) then 
    	maincats = maincats .. '[[Category:Articles using infobox body of water without coordinates]]'
    end
    
    if (isblank(args['pushpin_map']) ) then
    	maincats = maincats .. '[[Category:Articles using infobox body of water without pushpin_map]]'
    elseif isblank(args['pushpin_map_alt']) then
		maincats = maincats .. '[[Category:Articles using infobox body of water without pushpin_map_alt]]'
    end
    
    if (isblank(args['image_bathymetry']) ) then
    	maincats = maincats .. '[[Category:Articles using infobox body of water without image_bathymetry]]'
    elseif isblank(args['alt_bathymetry']) then
		maincats = maincats .. '[[Category:Articles using infobox body of water without alt_bathymetry]]'
    end
 
    local duplicate_parameters = 0
	local duplicate_list = {
		{'child', 'embed'},
        {'name', 'lake_name'},
        {'image', 'image_lake'},
        {'alt', 'alt_lake'},
        {'caption', 'caption_lake'},
        {'coordinates', 'coords'},
        {'lake_type', 'type'},
        {'ocean_type', 'type'},
        {'lake_type', 'ocean_type'},
        {'part_of', 'parent'},
        {'basin_countries', 'countries'},
        {'catchment_km2', 'catchment'},
        {'length_km', 'length'},
        {'width_km', 'width'},
        {'area_km2', 'area'},
        {'depth_m', 'depth'},
        {'max-depth_m', 'max-depth'},
        {'volume_km3', 'volume'},
        {'shore_km', 'shore'},
        {'elevation_m', 'elevation'},
        {'settlements', 'cities'},
        {'extra', 'nrhp'},
        {'extra', 'embedded'},
        {'embedded', 'nrhp'}
    }
    for i, params in ipairs(duplicate_list) do
    	if args[params[1]] and args[params[2]] then
    		duplicate_parameters = duplicate_parameters + 1
    		table.insert(warnmsg, 'Cannot use <code>' .. params[1] .. '</code> and <code>' .. params[2] .. '</code> at the same time.')
    	end
    end
    if (duplicate_parameters > 0) then
        cats = cats .. '[[Category:Pages using infobox body of water with ' ..
        	'duplicate parameters|' .. 
        	string.sub(AZ, duplicate_parameters, duplicate_parameters+1) .. ']]'
    end
    
    local no_convert_parameters = 0
    local dim_list = {
    	'catchment', 'length', 'width', 'area', 'depth', 'max-depth', 'volume',
    	'shore', 'elevation', 'temperature_low', 'temperature_high'}
	for i, param in ipairs(dim_list) do
	   if hasnoconvert(args[param] or '') then
	     no_convert_parameters = no_convert_parameters + 1
	     table.insert(warnmsg, 'Unconverted dimensions in <code>' .. param .. '</code>')
		end
	end
    if (no_convert_parameters > 0) then
        maincats = maincats .. '[[Category:Pages using infobox body of water with a non-automatically converted dimension|' ..
        	string.sub(AZ,no_convert_parameters, no_convert_parameters+1) .. ']]'
    end
    
    if #warnmsg > 0 then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			cats = '<div class="hatnote" style="color:red"><strong>Infobox body of water warning:</strong> ' .. table.concat(warnmsg, '<br>') .. '</div>' .. cats
		end
    end

	if maincats ~= '' and mw.title.getCurrentTitle().namespace == 0 then
		cats = cats .. maincats
	end
	
    return cats
end
    
return p