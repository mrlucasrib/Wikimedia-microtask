local p = {}  -- exposed functions
local l = {}  -- local functions

local botanicalAuthorites = require( "Module:Taxon_authority/data" ).botanicalAuthorites -- get list from submodule
local names = {
	["L."]      = "Carl Linnaeus",
	["Schldl."] = "Diederich Franz Leonhard von Schlechtendal",
    ["Cham."]   = "Adelbert von Chamisso",
}
--[[-------------------------------------------------------------------------------------
    main entry point
]]
p.main = function(frame)
	local option = mw.getCurrentFrame():getParent().args['option']
	if option == "wikidata" then
		return p.misc(frame)
	else
		return p.linkBotanicalAuthorites(frame:getParent().args[1])
	end
	
end

--[[ -------------------------------------------------------------------------------------
		function to adds wikilinks for valid botanical authorities
    	this version uses the keyed table at the top of this module
    	the name in the key needs to be escaped for the lua expression wildcard "."
	]]  
p.linkBotanicalAuthorites = function(name)
	if names[name] then
		name = l.wikilinkName(names[name], name) -- if the passed authority matches a single authority name
	else
	    for k, v in pairs( names  ) do
	    	                                          -- if the passed authority contains the authority name
	    	if string.find( name, k, 1, false) then      -- plain=true as  don't want to treat . as wildcard

	    		name = string.gsub( name, l.escape(k), l.wikilinkName(v,k) )  -- is the wildcard . a potential problem?
		    end
	 	end
	 end
 	return '<small>' .. name .. '</small>'
end
--[[ ----------------------------------------------------------------------------------------------
		function to adds wikilinks for valid botanical authorities
    	- this version uses simple unkeyed table in the data submodule (Module:Taxon authority/data)
        - note: for some reason, the wild card "." doesn't need to be escaped
  ]]
p.linkBotanicalAuthorites2 = function(frame)
	local name = mw.getCurrentFrame():getParent().args[1]
    for k, v in pairs( botanicalAuthorites  ) do
    	
    	if name == v[1] then                     -- if the passed authority matches a single authority name
    		name = l.wikilinkName(v[2],v[1])
    	else                                     -- if the passed authority contains the authority name
	    	if string.find( name, v[1], 1, true) then   -- don't want to treat . as wildcard
	    		name = string.gsub( name, v[1], l.wikilinkName(v[2],v[1]) ) 
		    end
	    end
 	end	
 	return '<small>' .. name .. '</small>'
end
--[[------------------------------------------------------------------------------------
		function to add wikilink to formal authority names
]]
l.wikilinkName = function(targetPage, displayedName)
	return '[[' .. targetPage .. '|' .. displayedName .. ']]'
end
--[[ ------------------------------------------------------------------------------------------
		function to escape the lua expression wildcardd "." in the authority names (e.g. "L.")
  ]]
l.escape = function(str)
	if string.find( str, ".", 1, false) then -- need to esc the .
	   local s = mw.text.split( str, "%.", plain ) 
	   return  s[1] .. "%." .. s[2]                -- escaped version of string
	end
	return str -- unaltered str
end

--[[---------------------------------------------------------------------------------
           general purpose function to experiment with wikidata etc
  ]]
p.misc = function (frame)
	
	local output = ""
	--get  arguments from calling templates
    local parent = mw.getCurrentFrame():getParent() 
	local name = parent.args[1]
	
	-- first check  the module list
	--p.linkBotanicalAuthorites2(frame)

	-- if name not found so try wikidata
	if output == "" then
	
		local wdName, err = l.getBotanicalAuthorityFromWikiData(name)
	    if not err then  
	    	--output = wdName 
	    	output = '[[' .. name .. '|' .. wdName .. ']]'
	    else
			output = l.errmsg("wikidata item not found")        -- return error message
			output = name                                       -- return unlinked name 
		end	
	end	
	return '<small>' .. output .. '</small>'  
end

l.errmsg = function(text)
	return '<span style="color:red;">' .. text .. '</span>'
end
l.getBotanicalAuthorityFromWikiData=function(name)
	if (2==1) then return "" end

	
	local WikidataId = mw.wikibase.getEntityIdForTitle(name)

    if not (WikidataId and mw.wikibase.isValidEntityId( WikidataId )) then
    	local titleObj = mw.title.new( name ).redirectTarget
		if  titleObj and titleObj.text ~= nil then name = titleObj.text end
		WikidataId = mw.wikibase.getEntityIdForTitle(name)
    end

	if WikidataId and mw.wikibase.isValidEntityId( WikidataId ) then -- valid wikidata id
    	local value = "authority not found"
    	local item = mw.wikibase.getEntity(WikidataId)
    	local statements = item:getBestStatements('P428')[1] --botany authority
        if statements ~= nil then -- 
	    	value = statements.mainsnak.datavalue.value
        end
    	return value
    end 
    --return l.errmsg("wikidata item not found for " .. name), true  -- return error message
    return  name, true                                        -- return unlinked name, true to indicate error
end

return p