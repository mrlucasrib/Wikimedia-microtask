local p = {}

p.ConvertScoresway = function(frame)
	
	local parentArgs = mw.getCurrentFrame():getParent().args  -- get arguments from template

	local args = {}                     -- make local copy of args for modifying
	for k,v in pairs(parentArgs) do
		if v ~= "" then                 -- ignore empty parameters
			args[k] = v
		end
	end
	
	-- modify url to redirect to soccerway 
    local url = args.url
    if string.find( url, "scoresway", 1, true ) and string.find( url, "sport=soccer", 1, true ) then 
	    if  (string.find( url, "page=player", 1, true )or string.find( url, "page=person", 1, true )) then
	       local id =  string.match( url, "id=([%d]*)" )
	       if id  then 
	       	 -- https://www.soccerway.com/players/-/604379/
	         url = 	"https://www.soccerway.com/players/-/" .. id  
	       end
	       args['url'] = url
	    end
	    if  (string.find( url, "page=team", 1, true ) and string.find( url, "view=squad", 1, true )) then
	       local id =  string.match( url, "id=([%d]*)" )
	       if id  then 
	       	 -- https://www.soccerway.com/teams/-/-/8884/squad/
	         url = 	"https://www.soccerway.com/teams/-/-/" .. id .."/squad/" 
	       end
	       args['url'] = url
	    end
    end
    
    -- change other parameters

    args['publisher'] = "Soccerway"           -- change publisher (should be work/website) 
    
    local title = args['title']                   -- remove "scoresway" from title
    if string.find( title, "Scoresway", 1, true ) then
        title = string.gsub( title, "Scoresway", "Soccerway" )
        --title = string.gsub( title, "at Scoresway", "" )         -- remove "at Scoresway" ?
        args['title'] = title
    end

	
	return tostring(frame:expandTemplate{ title = 'Cite web',  args = args   } ) -- call cite web
    --return "hello"	
end
return p