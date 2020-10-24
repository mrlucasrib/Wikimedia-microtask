require('Module:No globals');
local yesno = require('Module:Yesno')

local p = {} 
local g = {}         -- for parameters with global scope in this module
g.goalscorers = {}   -- table where selected and sorted players will be place
g.args = {}
g.totalGoals = 0
local data = {}      -- module subpage data -- require('Module:Goalscorers/data/UEFA Euro 2016 qualifying'); 

p.errorString = ""
function p.error_msg()
	if p.errorString ~= "" then
		return '<span style="font-size:100%" class="error">'
	         -- '<code style="color:inherit;border:inherit;padding:inherit;">&#124;_template=</code>'
	         .. p.errorString .. '</span>';
	end
end
-- data for goals scored held in module subpages, e.g. "Module:Goalscorers/data/UEFA Euro 2016 qualifying"
      --[[ parameters containing data help in three tables
						data.rounds = {}   -- group, play-off
						data.goalscorers = {}    -- player, country, goals in each round)
						data.owngoalscorers = {} -- player, country, goals in each round)
						data.updated = {}        -- date of latest update (month, day, year)
					--]]

--[[ ############################ Parameter handing  ###############################
      this section is currently unused
      will be used to take check parameters set in template
]]

local function getArgs(frame)
	local parents = mw.getCurrentFrame():getParent()
		
	for k,v in pairs(parents.args) do
		--check content
		if v and v ~= "" then
			g.args[k]=mw.text.trim(v) --parents.args[k]
		end
	end
	for k,v in pairs(frame.args) do
		--check content
		if v and v ~= "" then
			g.args[k]= mw.text.trim(v)  --parents.args[k]
		end
	end
	-- allow empty caption to blank default
	--if parents.args['caption'] then templateArgs['caption'] = parents.args['caption'] end
end

--[[ ############################## Main function and other functions ######################

     main() - simple output of the data in the module in list form
]]
function p.main(frame)
    getArgs(frame)
    local dataTarget =  g.args[1] or  g.args['data']
    if dataTarget then
        data = require('Module:Goalscorers/data/'.. dataTarget) --or 'UEFA Euro 2016 qualifying' 
    	return p.useModuleData(frame)  -- data on goals taken from module subpage
    else
    	return p.useTemplateData(frame)  -- data on goals/assists taken from template
    end
    
end
function p.useModuleData(frame)

    --p.goalscorers = {} -- table where selected and sorted players will be place
    g.totalGoals = 0
    p.selectGoalscorers() -- selected goalscorers meeting round and group criteris
    
-- CHANGEe: append own goals to list  (data will now include goals and own goals (negative))  
    p.selectGoalscorers("OG")    
    
    
    p.sortGoalscorers() -- sort selected goalscorers by number of goal, then country
    
    
    local outputString = p.addIntroductorySentence() .. p.outputGoalscorers(frame) .. p.addFooterSentence()
--                      .. ""              --TODO add intermediate heading?
--                      .. p._owngoals(frame)  -- output list of goalscorers
    
    return p.error_msg() or outputString
end
function p.addIntroductorySentence()          -- add introductory text
	
	local totalGoalString = "A total of " .. g.totalGoals .. " goals were scored."
	--There were [has been|have been|was|were] #GOALS goal(s) scored in #MATCHES match(s), for an average of #GOALS/#MATCHES per match.
	
	local matches, dateUpdated = p.getNumberMatches()
	local mdyFormat = yesno(g.args['mdy'])
	
	local Date = require('Module:Date')._Date
	
	local pluralGoals = "s"
	local text1 = ""
	if g.totalGoals == 1 then
		pluralGoals = ""
		if dateUpdated == 'complete' then text1 = "was" else text1 = "has been" end
	else
		if dateUpdated == 'complete' then text1 = "were" else text1 = "have been" end
	end
	local text = string.format("There %s %s goal%s scored", text1, mw.getLanguage('en'):formatNum(g.totalGoals), pluralGoals)
	
	local pluralMatches = "es"
	if matches==1 then pluralMatches = "" end
	if matches then
		local average = g.totalGoals/tonumber(matches)
		local precision = 3                        -- display d.dd (three significant disgits)
		if average < 1 then precision = 2 end      -- display 0.dd (thwo significant disgits)
		average = tostring (average)

		local pluralAverage = "s"
		if  tonumber(string.format("%.2f",average))==1 then pluralAverage = "" end
	    text = text .. string.format(" in %d match%s, for an average of %."..precision.."g goal%s per match", matches, pluralMatches, average, pluralAverage)
	end
    
	if dateUpdated == 'complete' or dateUpdated == "" then
	    text = text .. "."
	else
		local dateFormat =  'dmy'                                                       -- default
		if data.params and data.params['date_format'] then dateFormat = data.params['date_format'] end  -- from data module
		if mdyFormat == true then dateFormat = "mdy" else
			if mdyFormat == false then dateFormat = "dmy" end   -- template param overrides
		end
	    text = text .. " (as of " .. Date(dateUpdated):text(dateFormat) .. ")."
	end
	text = p.addAdditionHeaderText(text, dateUpdated)  -- handles template parameters bold, further, extra

	return text --totalGoalString 
end
function p.addFooterSentence()                 -- add notes at bottom
    
    local footerSentence = g.args['footer'] or ""
    --footerSentence = "This is a footer sentence."               -- test footer
    if data.params then
    	local footer = data.params['footer'] or nil
	    if footer then
	    	local frame = mw.getCurrentFrame()
	    	local processed = frame:preprocess(footer)
	    	if g.notes then
	    		footerSentence  = footerSentence  .. processed
	    	end
	    end
    end
    
    if footerSentence ~= "" then
    	footerSentence = '<div style = "" >' .. footerSentence .. '</div>'
    end
    return footerSentence
end
function p.getNumberMatches()
   	local matches = g.args['matches']
   	local dateUpdated = data.updated['date'] or "1700-01-01" --'complete' -- assume completed if missing
  
    local round = g.args['round'] or "all"    -- round =  all(empty)|group|playoffs
    local group = g.args['group'] or "all"     -- group =  all(empty), A,B,C etc  
    
    local allGroupGames = 0
    local latestGroupDate = "1800-01-01" 
    if round == "all" or group == "all" then           -- count all the group games
    	for k,v in pairs(data.updated.group) do
    		allGroupGames = allGroupGames + v[1]
    		if v[2] ~= "complete" and v[2] > latestGroupDate then latestGroupDate = v[2] end -- update if later date
    	end
    	if latestGroupDate == "1800-01-01" then latestGroupDate = "complete"  end -- no dates so must be complete
    end

	if round == "all" then                                       -- all rounds and goals
        matches=0
        for k,v in pairs(data.updated) do 
            if k == "group" then
        		matches = matches + allGroupGames
    	     	if latestGroupDate ~= "complete" and latestGroupDate > dateUpdated then 
    	     		dateUpdated = latestGroupDate                -- update if later date
    	        end 
        	else
        		matches = matches + v[1]
    		    if v[2] ~= "complete" and v[2] > dateUpdated then dateUpdated = v[2] end -- update if later date
        	end
        	
        end 
	elseif round == "group" then                                  -- group round only
	    if group == "all" then                            
		   matches = allGroupGames
		   dateUpdated = latestGroupDate  
		else                                                      -- single group only
           matches     = data.updated.group[group][1]                 -- number matches
           dateUpdated = data.updated.group[group][2]                 -- update date or completed
		end
	else                                                          -- any other round
       matches     = data.updated[round][1]                           -- number matches
       dateUpdated = data.updated[round][2]                           -- update date or completed
    end 
    
    if dateUpdated == "1700-01-01" then dateUpdated = "complete"  end -- no dates so must be complete

   	return matches, dateUpdated
end

function p.owngoals(frame) -- need to check parameters if external call
    getArgs(frame)
    data = require('Module:Goalscorers/data/'.. g.args[1]) --or 'UEFA Euro 2016 qualifying' 

    local outputString = p._owngoals(frame)
    return  p.error_msg() or outputString
end
function p._owngoals(frame) -- internal call for own goals

    --p.goalscorers = {} -- table where selected and sorted players will be place
    
    p.selectGoalscorers("OG") -- selected goalscorers meeting round and group criteris
    
    p.sortGoalscorers() -- sort selected goalscorers by number of goal, then country

    return p.outputGoalscorers(frame, "OG") -- output list of goalscorers
    
end


-- select players meeting round and goal criteria
function p.selectGoalscorers(og)

    --data = require('Module:Goalscorers/data/'.. g.args[1]) --or 'UEFA Euro 2016 qualifying' 
   
    local goalMinimum = tonumber(g.args['minimum']) or -5  -- assume 5 own goals is maximum
    
    -- select all players with goals totals for appropriate rounds
    local round = g.args['round'] or "all"    -- round =  all(empty)|group|playoffs
    local group = g.args['group'] or "all"     -- group =  all(empty), A,B,C etc  

    local goalsCol = p.getGoalsCol(round) -- 4          -- first column for goals
    --local groupCol =  3         -- default column for group
    if round then
    --	goalsCol = data.rounds[round] or data.rounds[1] or 4  -- get column containing goals for that round or first round listed if all
    end
    --groupCol = data.group[round] or 3    -- get column containing goals for that round
    
    -- select players who have scored in rounds/groups requested
    local goalscorerData = data.goalscorers
    if og == "OG" then goalscorerData = data.owngoalscorers end
    
    for k,v in pairs(goalscorerData) do
        local goals, comment = 0, ""                         -- goals > 0 is the flag to include the player
        local playerName, playerAlias = p.getPlayer(v[1])                -- player name
        local goalsByRound, commentByRound = 0, ""
		if round == "all" then                                                   -- all rounds and goals
		    --local i = 4
		    for i = goalsCol, #v, 1 do        --or while i <= #v do
		    	goalsByRound, commentByRound = p.getGoals( v[i] , playerName)
		    	goals = goals +   goalsByRound              --TODO use getGoals on round options
		    	if commentByRound ~= "" then
			    	if comment == "" then
			    		comment = commentByRound 
			    	else
			    		comment = comment .. "," .. commentByRound  --TODO decide on comma or semi-colon
		    		end
	       		end
		    	i = i+1
		    end
		elseif round == "group" then                                          -- group round only
		    --if group == v[groupCol] then                             -- single group only 
		    if group == p.getGroup(v[2], v[3]) then                         -- single group only 
				goals, comment = p.getGoals( v[goalsCol] , playerName)
			elseif group == "all" then                                 -- any group
				goals, comment = p.getGoals( v[goalsCol] , playerName)
			else   -- do nothing for other groups
			end
		--elseif round == "playoffs" then                                   -- playoff round (redunant?)
		--	   goals = v[goalsCol]
		else                                                              -- any other round
			   goals, comment = p.getGoals( v[goalsCol] , playerName)        -- should also handle playoffs
	    end 
	    if goals >= goalMinimum and goals ~= 0 then
	    	   if comment ~= "" then 
	    	   	  if og == "OG" then 
	    	   	  	comment = '<span> (' .. p.sortComment(comment) .. ')</span>' 
	    	   	  else
	    	   	  	comment = '<span>' .. comment .. '</span>'   -- no parenthesis when using notes
	    	      end
	    	   end
	    	   
	    	   if og == "OG" then goals = -goals end  -- make owngoals negative numbers
	    	   
			   g.goalscorers[#g.goalscorers+1] = { player=playerName, alias=playerAlias,
			   	                                   country=v[2], 
			   	                                   goals=goals, 
			   	                                   comment=p.parseComment(comment)}
			   --g.totalGoals = g.totalGoals + math.abs(goals)    -- increment total goal counter	                                  
	    end
	    g.totalGoals = g.totalGoals + math.abs(goals)    -- increment total goal counter
    end
    --return p.goalscorers -- it is available anyway
end
--[[ get column for round or first round listed if "all" 
      -allows group column to be omitted from player table when group table provided ]]
function p.getGoalsCol(round)
    
    if round == "all" then  -- if all need column of first round
       for k,v in pairs(data.rounds) do
       	  return v; -- return the first one
       end
    end
    return  data.rounds[round] or 4  -- get column containing goals for that round or first round listed if all
end
--[[ get group from group table or from player table     ]]
function p.getGroup(country, possibleGroup)             -- row contain player name, country code, group if given, goals
	if data.groups then
       for k,v in pairs(data.groups)  do  -- iterate through the groups
            --local = gotGroup = false
    		for j,u in pairs(v) do       -- for each group
    		   if u == country then
    		   	  return k
    		   end
    		end
    	end
        return "no group found"
    else 
    	return possibleGroup -- no group table, so assume column three contains the group
	end
	
end
--[[ get number of goals and any associated comment
      the goals can be a single number (the usual case)
        or as an option table (e.g. for own goals): { number of own goals, comma-delimited list of opponents }
    - if the entry is a table, we want the first entry (a number) and the second (comment string)
    - otherwise, if a number, we just want the number and an empty string
]]
function p.getGoals (u, player)
	if type(u) == 'table' and type(u[1]) == 'number' then
		return u[1], u[2]            -- return number of goals, comment
	elseif type(u) == 'number' then
		return u, ""                 -- return number of goals, empty string
	else
		p.errorString = p.errorString .. " Invalid goals entry for player " .. player
		return 0, ""
	end
end
function p.parseComment(comment)
	
	local frame = mw.getCurrentFrame()

	-- we have something like "{{efn-ua|name=goals}}"
	if string.find(comment, "efn" , 1 , true ) then       -- if we have a comment with a note
		g.notes = true                                    -- set flag
	end
	
	
	return frame:preprocess(comment)
end

function p.getPlayer(u)
	if type(u) == 'table'  then
		if type(u[1]) == 'string' and type(u[2]) == 'string' then
			--[[if #u[2] >1 then 
				p.errorString = p.errorString  .. "\n\nWe have u[1]=" .. u[1] .. " and u[2]=" .. u[2]
			end]]
			return u[1], u[2]            -- return player name, player sorting alias
		else
			p.errorString = p.errorString .. " Invalid name entry for player " .. u[1] .. ", " .. u[2] 
			return "", ""     --TODO errroer
		end
	elseif type(u) == 'string' then
		return u, ""                 -- return player name
	else
		p.errorString = p.errorString .. " Invalid name entry for player " .. u or u[1] or "unknown"
		return "", ""
	end
end
--[=[ function p.preprocessSortName()
      stripp off wikitext [[ and ]]
      force to lowercase
      change special characters to standard letters
]=]
function p.preprocessSortName (name)
	name = string.gsub(name, "%[%[", "")              -- strip off [[ and ]]
	name = string.gsub(name, "%]%]", "")
    --name =string.lower(name)                          -- force lower case and return
    name = mw.ustring.lower(name)                       -- use unicode function

	local specialChars = {                            -- list of special characters and replacement pairs
		                   { "ı", "i" } , { "İ", "i" } , { "ß", "ss" },
		                   { "ý", "y" } , { "ř", "r" } , { "ő", "o" },
		                   { "é", "e" } , { "è", "e" } , { "þ", "th" },
		                   { "ē", "e" } , { "ņ", "n" } , { "č", "c" },
		                   { "ū", "u" } , { "ž", "z" } , { "æ", "ae" },
		                   { "å", "a" } , { "ø", "o" } , { "ą", "a" },
		                   { "ń", "n" } , { "ł", "l" } , { "ã", "a" },
		                   { "ș", "s" } , { "š", "s" } , { "í", "i" },
		                   { "á", "a" } , { "ä", "a" } , { "ć", "c" },
		                   { "ç", "c" } , { "ğ", "g" } , { "ö", "o" },
		                   { "ë", "e" } , { "ú", "u" } , { "ó", "o" },
		                   { "ð", "d" } , { "ü", "u" } , { "ű", "u" },
		                   { "ā", "a" } , { "ī", "i" } , { "đ", "d" },
		                   { "ă", "a" } , { "â", "a" } , { "ż", "z" },
		                   { "ț", "t" } , { "ş", "s" } , { "ś", "s" },
		                   { "ǎ", "a" } , { "ě", "e" } , { "ů", "u" },
		                   { "ĕ", "e" } , { "ñ", "n" } , { "ď", "d" },
		                   { "ï", "i" } , { "ź", "z" } , { "ô", "o" },
		                   { "ė", "e" } , { "ľ", "l" } , { "ģ", "g" },
		                   { "ļ", "l" } , { "ę", "e" } , { "ň", "n" },
		                   { "ò", "o" }
                         }
    for k,v in pairs(specialChars) do                 -- replace special characters from supplied list
    	name = string.gsub(name, v[1], v[2])
    end

	return name                     
end
--[[ return the name for sorting 
       return supplied alias name for sorting
       otherwise
          checks for pipe (redirect) and uses name after pipe
          splits name into words
             returns first name if only name (e.g. Nani)
             otherwise returns name in format second_name [.. last name], firstname
]]
function p.getPlayerSortName (playerName, sortName, countryName)
	
			--dewikify all names before sorting, also forces lowercase
	playerName = p.preprocessSortName(playerName)
	sortName = p.preprocessSortName(sortName)
	
	if sortName ~= "" then                           -- if we have a sort name supplied
		return sortName                              --            then return it
	end
	
	-- players from certain countries will use name in order supplied
	local noSort = { "CAM", "CHN", "TPE", "MYA", "PRK", "KOR", "VIE" }
	for k,v in pairs(noSort) do 
		if v == countryName then
			return playerName
		end
	end
	
	
	-- else work it out from the supplied player name
		
    -- we don't want to test the name in a redirect, so get name after pipe if there is one
    if string.find (playerName, "|") then                 -- test for redirect
      	local names = mw.text.split( playerName, "|")    
       	playerName = names[2]                               -- get name after pipe
    end

    local names = mw.text.split( playerName, " ") -- we don't want to sort on first name
	
	if #names == 1 then
		return names[1]                             -- return name of single name player
	else
		-- we will assume the second name is the sort name e.g, Joe Bloggs, Jan van Bloggen
		local name = names[2]                   -- set name to second name e.g. Bloggs or van
		local i=3
		while i <= #names do                       -- any addition names e.g. Bloggen
			name= name .. names[i]
			i=i+1
		end
		name = name .. ", " .. names[1]           -- add first name e.g. Joe or Jan
		        
		return name                                -- sort on second name third name etc, first name	
	end
	
end

-- sort the list of countries alphabetically
function p.sortComment(comment)

	local items = mw.text.split( comment, ",")         -- split comma-delimited list

    for k,v in pairs(items) do 
    	items[k] = mw.text.trim(v)                          -- trim spaces and coe
    end
    
	table.sort(items, function(a,b) return a<b end)         -- sort the table alphbetically

	local list = "against "                    -- construct the alphabetical list string
	for i=1, #items do
		local sep =  ", "                              -- separator for comma-delimited list
		if i==1 then sep = ""                          -- first word doesn't need comma
		elseif i==#items then sep = " & "            -- use "and" before last word
		end
		list = list .. sep .. items[i]
	end	
	return list
	
end
function p.getCountryName(country)
	
	if string.len(country) == 3 then      -- if the country given as a three-letter code
		local codes = require('Module:Goalscorers/data/Country codes')
	    
	    for k,v in pairs(codes.alias) do 
    	   if v[1] == country then
    	   	   return v[2]
    	   end
        end
	else
	    return country                    -- return the country name as is
	end
end
--[[ sort goalscorers by goals, country and name
        the sort first sorts by number of goals
        when these are equal, it sorts by country
        when these are equal, it sorts by name
        Note: the name sort is on the first name
               - a split of the name and sort on the last name is possible
               - however, this would be complicated by Dutch (e.g. Stefan de Vrij) and Spanish names
               - would sort on second name be better
]]
function p.sortGoalscorers()
    
    local sort_function = function( a,b )
		    if (a.goals > b.goals) then                -- primary sort on 'goals' -> a before b
		        return true
		    elseif (a.goals < b.goals) then            -- primary sort on 'goals' -> b before a
		        return false
		    else -- a.goals == b.goals 		           -- primary sort tied, 
		        
		        --return a.country < b.country         -- resolve with secondary sort on 'country'
			    local country_a = p.getCountryName(a.country)  -- sort on name of country, not the code
			    local country_b = p.getCountryName(b.country)
			    
			    if (country_a < country_b) then        -- secondary sort on 'country'
			        return true
			    elseif (country_a > country_b) then    -- secondary sort on 'country'
			        return false
			    else -- a.country == b.country 		   -- secondary sort tied, 

			        --return a.player < b.player         --resolve with tertiary sort on 'player' name
                    
                    local player_a = p.getPlayerSortName(a.player, a.alias, a.country) -- get player name for sorting
                    local player_b = p.getPlayerSortName(b.player, b.alias, b.country)
                    
                    return player_a < player_b      -- 
--[[]
                     --local test_a, test_b = a.player, b.player

                   -- we don't want to test the name in a redirect, so get name after pipe if there is one
                    if string.find (a.player, "|") then                 -- test for redirect
                    	local names = mw.text.split( a.player, "|")    
                    	test_a = names[2]                               -- get name after pipe
                    end
                    if string.find (b.player, "|") then
                    	local names = mw.text.split( b.player, "|")
                    	test_b = names[2]
                    end
                    
			        local names_a = mw.text.split( test_a, " ") -- we don't want to sort on first name
			        local names_b = mw.text.split( test_b, " ") --     so split names 
			        
			        if not names_a[2] then names_a[2] = test_a end -- for players with one name
			        if not names_b[2] then names_b[2] = test_b end
			        
			        return names_a[2] < names_b[2]      -- sort on second name
]]			        
			    end		        
		    end
		end
		
    table.sort(g.goalscorers, sort_function)


end

function   p.outputGoalscorers(frame, og) -- output list of goalscorers
    local outputString = ""	
    if og == "OG" then   end

    -- ==============output the lists of goalscorers by goal======================
    local goalNumber = 1000
    --local goalMinimum = tonumber(templateArgs['minimum']) or 0
    
    local listOpen = false -- flag for list started by template {{Div Col}} 
    
    for j,u in pairs(g.goalscorers) do    -- run through sorted list of selected goalscorers
    	
    	--if u['goals'] < goalMinimum then break end -- limit list to goals over a threshold (now handled in select goalscorers)
    		
    	if u['goals'] < goalNumber then         -- start new list of new number of goals
    		if listOpen then                    -- if an open list, close last list
    			outputString = outputString .. p.closeList(frame) 
    			listOpen = false -- redundant as will be set true again
    		end
    		goalNumber = u['goals']
    		
    		local goalString = " goal"
    		--if og == "OG" then 	
    		if goalNumber < 0 then
    			goalString = " own" .. goalString 
    		end
    		if  math.abs(u['goals']) ~= 1 then goalString = goalString .. "s" end

    		outputString = outputString .. "\n'''" .. math.abs(u['goals']) .. goalString .. "'''"   -- list caption
    		
    		outputString = outputString .. p.openList(frame,og) --start new list
    		listOpen = true
    		--goalNumber = u['goals']
    	end
    	-- is the player active still?
    	local playerActive = false
    	if data.active_countries then
    		for k,v in pairs(data.active_countries) do
    		  if v == u['country'] then
    		  	playerActive = true
    		  	break;
    		  end
    		end
    	end
    	local _,roundStatus = p.getNumberMatches()
    	if roundStatus == "complete" then playerActive = false end  -- overrides active_countries
    	
    	-- wikitext for bullet list    
       	local goalscorerString = '\n*<span>' .. p.addLinkedIcon(frame, u['country'])    -- linked flag icon    
    	if playerActive and g.args['bold']~='no' then
    		goalscorerString = goalscorerString  .. " <b>" .. u['player'] .. "</b>"    -- bolded name
    	else
   		    goalscorerString = goalscorerString  .. " " .. u['player']                  -- name
    	end
    	goalscorerString = goalscorerString  .. u['comment']   .. '</span>'             -- comment for o.g.
    	                              
    	outputString = outputString .. goalscorerString   --  .. " " .. tostring(u['goals'])

    end -- reached end of list of goalscorers

	if outputString ~= "" then
	    outputString = outputString .. p.closeList(frame)

		return outputString
	else
		return ("No goals matching requested criteria.")
	end
end

-- output icon linked to national team page
function p.addLinkedIcon(frame, country)
	local icon = data.templates['flag_icon_linked']         -- fbicon etc set in data module
	local level = data.templates['youth_level']  or ""           -- parameter for youth level, ie under-21
    -- equivalent to  {{fbicon|country}}     
    local flagVariant = ""
    if data.templates.flagvar and data.templates.flagvar[country] then
    	flagVariant = data.templates.flagvar[country] 
    end
    if level ~= "" then 
    	return frame:expandTemplate{ title = icon , args = { level, country, flagVariant } }   
    else
    	return frame:expandTemplate{ title = icon , args = { country, flagVariant } }     -- flag icon
    end
end
-- formatting of list under each number of goals
function p.openList(frame,og)

	return '<div class="div-col columns column-count column-count-3" style="' 
	         .. frame:expandTemplate{ title = 'column-count', args = {3} }  .. '">'
end
function p.closeList(frame)
   return '</div>'
end
function p.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

-- handles parameters bold, further, extra
function p.addAdditionHeaderText(text, dateUpdated)
    if g.args['inlineref'] then
    	text = text .. g.args['inlineref']
    end
    if g.args['bold'] and g.args['bold']~='no' then
    	text = text .. " Players highlighted in '''bold''' are still active in the competition."
    end
    if g.args['further'] then
    	if text ~= "" then text = text .. " " end
    	text = text .. g.args['further']
    end
    if g.args['extra'] then
    	text = text .. "\n\n" .. g.args['extra']
    end
    return text
end
-- count number of goals for data in template
function p.countGoals(list, number, totalGoals)

    local split = mw.text.split( list, "\n", true )  -- split the list for number of goals scorers with N goals
    local count = #split  * math.abs(number)         -- calculate number of goals (including own goals)
    totalGoals = totalGoals + count
   
    --mw.addWarning( "Entry: " .. list  .. "[" .. count .. "]")

	return totalGoals 
end

--[[ use data supplied by template 
]]

--function p.list(frame)
function p.useTemplateData(frame)
    --getArgs(frame)
    
    --[[ {{{#if:{{{assists|}}}||There 
                  {{#if:{{{ongoing|}}}|{{#ifexpr:{{{goals}}}=1|has|have}} been
                  |{{#ifexpr:{{{goals}}}=1|was|were}}}} {{{goals}}} 
                  {{#ifexpr:{{{goals}}}=1|goal|goals}} scored{{#if:{{{players|}}}|&nbsp;by {{{players}}} 
                  {{#ifexpr:{{{players}}}=1|player|different players}}
                  {{#if:{{{own goals|}}}|&nbsp;(with {{{own goals}}} of them credited as {{#ifexpr:{{{own goals}}}=1|an own goal|own goals}})|}}|}} in {{{matches}}} 
                  {{#ifexpr:{{{matches}}}=1|match|matches}}, for an average of {{#expr:{{{goals}}}/{{{matches}}} round 2}} 
                  {{#ifexpr:({{{goals}}}/{{{matches}}} round 2)=1|goal|goals}} per match
                  {{#if:{{{updated|}}}|&nbsp;(as of {{{updated}}})}}.}}{{#if:{{{bold|}}}|{{#if:{{{assists|}}}||&nbsp;}}
                  Players highlighted in '''bold''' are still active in the competition.
                  |}}{{#if:{{{further|}}}|{{#if:{{{assists|}}}||&nbsp;}}{{{further}}}|}}
                  {{#if:{{{extra|}}}|{{{extra}}}{{clear}}|}}
    --]]
    local statNumber = g.args['goals'] or g.args['assists'] or 0
    local matches = g.args['matches']
    local statType = "goal"
    if g.args['assists'] then statType = "assist" end
    if g.args['clean sheets'] then statType = "clean sheet" end
    local ongoing = g.args['ongoing']
    local text1 = "There"
    if g.args['lc'] then text1 = "there" end  
    local text2 = "were"
    if ongoing then text2 = "have been" end  
    local updateString = ""
    local averageString = ""
    local text3 = ""
    if g.args['goals'] and tonumber(g.args['goals']) > 1 then text3 = "es" end
    
    -- auto version: string.format(" in %d match%s, for an average of %."..precision.."g goal%s per match", matches, pluralMatches, average, pluralAverage)
    if g.args['goals'] and g.args['matches'] then
    	averageString = string.format(" in %d match%s, for an average of %.3g goals per match", g.args['matches'], text3,g.args['goals']/g.args['matches'])
    end    
    if g.args['updated'] and g.args['updated'] ~= "complete" then
    	updateString = "&nbsp;(as of " ..g.args['updated'] .. ")"
    end
    local sep = "."
    if g.args['sep'] then sep = g.args['sep'] end
    local text = ""
    if g.args['goals'] then
    	text = string.format("%s %s %d %ss scored%s", 
    	                     text1, text2, statNumber, statType, averageString..updateString..sep)
    end
    text = p.addAdditionHeaderText(text)  -- handles template parameters bold, further, extra
    
    --[[   {{#if:{{{30 goals|{{{30 assists|}}}}}}|'''30 {{#if:{{{assists|}}}|assists|goals}}'''
                 <div class="div-col columns column-count column-count-3" style="{{column-count|3}}">
                 {{#if:{{{assists|}}}|{{{30 assists}}}|{{{30 goals}}}}}</div>|}}]]
    local output = "\n"
    local number = 30
   
    local totalGoals = 0
    
    while number > -4 do                   -- for the each goals/assists
    	
       local entry = g.args[number .. ' goals'] or g.args[number .. ' goal']
                       or g.args[number .. ' assists'] or g.args[number .. ' assist']
                       or g.args[number .. ' clean sheets'] or g.args[number .. ' clean sheet']
                     
       if number < 0 then  
       	  entry = g.args[math.abs(number) .. ' own goals'] or g.args[math.abs(number) .. ' own goal']
       	  statType = "own goal"
       end
       local plural = "s"
       if number == 1 or number == -1 then plural = "" end
			
       if entry then                                    -- do we have goals/assists for this number

    	 output = output .. "\n'''" .. tostring(math.abs(number)) .. " " .. statType .. plural .. "'''\n" 
    	                 .. '<div class="div-col columns column-count column-count-3" style="' .. frame:expandTemplate{ title = "column-count", args = {3} }  .. '">'
    	                 .. "\n" .. entry .. '</div>'
    	 totalGoals = p.countGoals(entry, number, totalGoals)
       end
       
       number = number -1
    end
    
    if statType == "goal" or statType == "own goal" then
    	if g.args['goals'] and totalGoals ~= tonumber(g.args['goals']) then 
    	    mw.addWarning("WARNING. Mismatch between number of goals listed (" .. totalGoals .. ") and goals parameter (" .. g.args['goals']  .. ").")
    	end
    end
    
    --{{#if:{{{bottom|}}}|{{small|{{{bottom_text}}}}} <div class="div-col columns column-count column-count-3" style="{{column-count|3}}"> {{{bottom}}}</div>|}}{{#if:{{{source|}}}|{{smaller|Source: {{{source}}}}}|}}
    local footerText = g.args['footer-text']  or g.args['bottom'] or ""
    local footerHeading = g.args['footer-heading'] or  g.args['bottom-text'] or ""
    local footer = ""
    if footerText ~= "" then
    	local heading = ""
    	if footerHeading ~= "" then
    		heading = '<p>' .. footerHeading .. '</p>'
    	end
    	footer =  '\n' ..  heading 
    	          .. '<div class="div-col columns column-count column-count-3" style="' .. frame:expandTemplate{ title = "column-count", args = {3} }  .. '">'
                  .. '\n' .. footerText .. '</div>'
    end
    
    
    --{{#if:{{{source|}}}|{{small|Source: {{{source}}}}}|}}
    local source = g.args['source'] or ""
    if source ~= "" then source = "<small>Source: " .. source .. "</small>" end
    
    return text .. output .. footer .. source
end
return p