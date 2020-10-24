require('Module:No globals');


local p = {} 

local error_msg = '<span style=\"font-size:100%\" class=\"error\"><code style=\"color:inherit; border:inherit; padding:inherit;\">&#124;_template=</code> missing or empty</span>';

-- data for various rankings held in module subpages, e.g. "Module:SportsRankings/data/FIFA World Rankings"
local data = {}      --[[ parameters containing data help in three tables
						data.source = {}     -- parameters for using in cite web (title, url, website)
						data.updated = {}    -- date of latest update (month, day, year)
						data.rankings = {}   -- the rankings list (country code, ranking, movement)
					    data.alias = {}      -- alias list (country code, country name [=key])
					    
					--]]

local  templateArgs = {} -- contains arguments from template involking module


local function getArgs(frame)
	local parents = mw.getCurrentFrame():getParent()
		
	for k,v in pairs(parents.args) do
		--check content
		if v and v ~= "" then
			templateArgs[k]=v --parents.args[k]
		end
	end
	for k,v in pairs(frame.args) do
		--check content
		if v and v ~= "" then
			templateArgs[k]=v --parents.args[k]
		end
	end
	-- allow empty caption to blank default
	if parents.args['caption'] then templateArgs['caption'] = parents.args['caption'] end
end

local function loadData(frame)
    
    local source = frame.args[1] -- source of rankings e.g. PDC Rankings
    data = require('Module:DartsRankings/data/'.. source);
    
end

local function getDate(option)
   
   local dateTable = data.updated         -- there must be date table (data.updated)
                                          -- TODO add a warning and/or category
   if option == "LAST" then 
   		local lastDateTable = data.previous 
   		if lastDateTable then             -- there might not be a previous data table (data.previous)
   			dateTable = lastDateTable
	   else 
	   		return "No previous date available (data.updated missing)"
       end
   end
   
   if templateArgs['mdy'] and templateArgs['mdy'] ~= "" then
   	   return dateTable['month'] .. " " .. dateTable['day'] .. ", " .. dateTable['year']
   else
   	   return dateTable['day'] .. " " .. dateTable['month'] .. " " .. dateTable['year']
   end
end

local function addCiteWeb(frame)  -- use cite web template
	
	return frame:expandTemplate{ title = 'cite web' , args = {
    		url = data.source['url'],            --"https://www.fifa.com/fifa-world-ranking/ranking-table/men/index.html", 
			title = data.source['title'],        -- "The FIFA/Coca-Cola World Ranking",
			website = data.source['website'],    --"FIFA",
			['date'] = getDate(),
			['access-date'] = getDate()
			}}
end
local function addReference(frame)
	
	local text = ""
	if data.source['text'] then text = data.source['text'] end
	
	return frame:expandTemplate{ title = 'refn' , args = {
		name=frame.args[1],                   --ranking used, e.g. "PDC Rankings",
	    text .. addCiteWeb(frame)
	}}

end

--[[ the main function returning ranking for one country
      - takes three-letter country code or name of country as parameters
      - displays as rank | movement |date
      
]]

function p.dates(frame)
	getArgs(frame) -- returns args table having checked for content
    loadData(frame)
       
--	if templateArgs[1]==1 then
		return getDate(templateArgs[2])
--	else
--		return getDate()
--	end
end

function p.main(frame)
	
    getArgs(frame) -- returns args table having checked for content
    loadData(frame)
    local outputString = ""
    local validCode = false
    local player = templateArgs[2] -- country name or county code passed as parameter
    local rank, move
    
	    for _,u in pairs(data.alias) do  -- run through alias list { 3-letter code, country name }
	    	if string.lower(u[1])==string.lower(player) then        -- if code = passed parameter
	       		validCode = true
	       		break
	       	end
	    end    
	    -- if no match of code to country name, set category

    for _,v in pairs(data.rankings) do
    	if string.lower(v[1])==string.lower(player) then 
       		rank = v[2]    -- get rank
       		break
       	end
    end
    
    if rank then -- no ranking found (do we want a tracking for no rank found?)

	    for _,v in pairs(data.rankingsold) do
	    	if string.lower(v[1])==string.lower(player) then 
	       		move = v[2] - rank    -- get move from last ranking
	       		break	
	       	else
	       		move = 0 - rank
	       	end
	    end
	else
    	rank = 'NR' 
    end

	if rank ~= 'NR' then
		outputString = outputString .. ' ' .. rank .. ' '
		if move < 0 and math.abs( move ) == math.abs( rank ) then -- new teams in ranking: move = -ranking
			outputString = outputString .. frame:expandTemplate{ title = 'new entry' } 
	    elseif move == 0 then                                    -- if no change in ranking
	    	outputString = outputString .. frame:expandTemplate{ title = 'steady' } 
	    elseif move < 0 then                                 --  if ranking down
	    	outputString = outputString .. frame:expandTemplate{ title = 'decrease' } .. ' ' .. math.abs(move)
	    elseif move > 0 then                                 -- if ranking up
	    	outputString = outputString .. frame:expandTemplate{ title = 'increase' } .. ' ' .. move
	    end	
    else
    	outputString = outputString .. frame:expandTemplate{ title = 'Abbr', args = { "NR", "Not ranked"}  }
    	--	{{Abbr|NR|Not ranked}} 
	end
	outputString = outputString .. ' <small>(' .. getDate() .. ')</small>'
	outputString = outputString .. addReference(frame)
    
    return outputString
	
end

--[[  outputs a table of the rankings 
        called by list() or list2() 
        positional parameters - |ranking|first|last the ranking to use, fist and last in table
        other parameters: |style=               -- CSS styling
                          |headerN= footerN=    -- displays header and footer rows with additional information
                          |caption=             -- value of caption to display
                                                -- by default it generates a caption
                                                -- this can be suppressed with empty |caption=
]]
local function table(frame, ranking, first,last)

    local styleString = ""
    if templateArgs['style'] and templateArgs['style'] ~= "" then styleString = templateArgs['style'] end
    
    local lastRank = 0
    local selectCount = 0
    local selectData = nil
    local selectList = nil

    
    -- column header customisation
    local rankHeader = templateArgs['rank_header'] or "Rank"
    local selectionHeader = templateArgs['selection_header'] or selectList or "Rank"
    local teamHeader = templateArgs['team_header'] or "Player"
    local pointsHeader = templateArgs['points_header'] or "Earnings"
    local changeHeader = templateArgs['change_header'] or "Change"
    
    --start table
    local outputString = '{| class="wikitable" style="text-align:center;' .. styleString .. '"'
    
    local tabletitle = data.labels['title']
    -- add default or custom caption
    local caption = tabletitle .. ' as of ' .. getDate() .. '.'
    if templateArgs['caption'] and templateArgs['caption']  ~= "" then 
    	caption = templateArgs['caption'] 
    	caption = p.replaceKeywords(caption)
    end
	outputString = outputString ..	'\n|+' .. caption .. addReference(frame)
    
    -- add header rows (logo, date of update etc)
    local count = 0
    local header = {}
    local tableWidth = 4
    if selectList then tableWidth = 5 end
    while count < 5 do
    	count = count + 1
	    if templateArgs['header'..count] then
	    	header[count] = templateArgs['header'..count] 
	    	header[count] = p.replaceKeywords( header[count])
	    	outputString = outputString ..	'\n|-\n| colspan="'.. tableWidth .. '" |' .. header[count]
	    end
    end
    
    -- add the add part of the table
    local optionalColumn = ""
    if selectList then
    	optionalColumn = '\n!' .. selectionHeader 
    end
   	outputString = outputString .. '\n|-' .. optionalColumn
    	                        .. '\n!' .. rankHeader .. '\n!' .. changeHeader 
    	                        .. '\n!' .. teamHeader .. '\n!' .. pointsHeader
   
    local change,player,flag1,plink = '', '', '', ''
    --while i<last do 
    for k,v in pairs(data.rankings) do
	   --v[2] = tonumber(v[2])
	   if v[2] >= first and v[2] <= last then 

			--player=v[1]
	

				   for _,u in pairs(data.alias) do  -- get country code from name
				    	if string.lower(u[1])==string.lower(v[1]) then 
				       		player = u[1]
				       		if u[4] then player =u[4] end 
				       		--[[This allows us to define a different player display than the PDC keeps
								for example 'de Zwaan' vs 'De Zwaan' or 'Suljovic' vs 'Suljović']]
				       		flag1= u[2] -- Flag string from libarary
				       		if u[4] then 
				       			plink = '[[' .. u[3] .. '|' ..  u[4] .. ']]'
				       		elseif u[3] then
				       			plink = '[[' .. u[3] .. '|' ..  u[1] .. ']]'
				       		else
				       			plink = '[[' .. u[1] .. ']]'
				       		end
				       
				       		break
				       	end
				    end   
	   	   
	   	    local continue = true
		
			if continue ==true  then 
	   	   
			   local rowString = '\n|-'
			   if selectList then 
			   	    local selectRank = selectCount
			   	    if v[2]==lastRank then selectRank = selectCount -1 end -- only handles two at same rank
					rowString = rowString ..  '\n|' .. selectRank 
					selectCount = selectCount + 1
			   end
			   rowString = rowString .. '\n|' .. v[2]  -- rank
			   lastRank = v[2]
			   
			   --local move = v[3]
				local move = nil
				
				for _,w in pairs(data.rankingsold) do
			    	if string.lower(w[1])==string.lower(v[1]) then 
			       		move = w[2] - lastRank    -- get move from last ranking
			       		break	
			       	else
			       		move = 0 - lastRank
			       	end
				end
			    
			   if move < 0 and math.abs( move ) == math.abs( v[2] ) then -- new teams in ranking: move = -ranking
					change = frame:expandTemplate{ title = 'new entry' } 
			   elseif move == 0 then                                    -- if no change in ranking
			    	change = frame:expandTemplate{ title = 'steady' } 
			    elseif move < 0 then                                 --  if ranking down
			    	change = frame:expandTemplate{ title = 'decrease' } .. ' ' .. math.abs(move)
			    elseif move > 0 then                                 -- if ranking up
			    	change = frame:expandTemplate{ title = 'increase' } .. ' ' .. move
			    end	
			   rowString = rowString .. '||' .. change
			   
			   local countryIconString = frame:expandTemplate{title= 'flagicon', args = {flag1}} .. " " .. plink 

	 		   rowString = rowString .. '\n|style="text-align:left"|' .. countryIconString
			   
			   local points = ""
			   if v[3] then points = v[3] end
			   rowString = rowString ..  '||' .. points       -- country for now, later points
			   outputString = outputString .. rowString
			end
		end
	end
	
    -- add footer rows
    count = 0
    local footer = {}
    while count < 5 do
    	count = count + 1
	    if templateArgs['footer'..count] then
	    	footer[count] = templateArgs['footer'..count] 
	    	footer[count] = p.replaceKeywords(footer[count])
	    	outputString = outputString ..	'\n|-\n| colspan="'.. tableWidth .. '" |' .. footer[count]
	    end
    end


    outputString = outputString .. "\n|}"

    return outputString
	
end
function p.replaceKeywords(keyword)
      keyword =  string.gsub( keyword, "INSERT_UPDATE_DATE", getDate())
      keyword =  string.gsub( keyword, "INSERT_LAST_DATE", getDate("LAST"))
      keyword =  string.gsub( keyword, "INSERT_REFERENCE", addReference(mw.getCurrentFrame()))
      return keyword
end

--[[ create a table of rankings
       parameters:  |ranking=        -- ranking to display (e.g. FIFA World Rankings)
                    |first= |last=   -- first and last ranking to display (defaults 1-10)
]]
function p.list(frame)

    getArgs(frame) -- returns args table having checked for content
    loadData(frame)	
    local ranking = frame.args[1]
    local first, last = 1,10
    first = tonumber(frame.args['2'])
    last = tonumber(frame.args['3'])
    
    return table(frame, ranking, first, last)
end

local function navlist(frame, ranking, first,last)


    local lastRank = 0
    local selectCount = 0
    local selectData = nil
    local selectList = nil
    
    --start list
    local outputString = '<ol start="' .. first .. '">'
   
   
    local change,player,flag1,plink = '', '', '', ''
    --while i<last do 
    for k,v in pairs(data.rankings) do
	   --v[2] = tonumber(v[2])
	   if v[2] >= first and v[2] <= last then 

				   for _,u in pairs(data.alias) do  -- get country code from name
				    	if string.lower(u[1])==string.lower(v[1]) then 
				       		player = u[1]
				       		if u[4] then player =u[4] end 
				       		--[[This allows us to define a different player display than the PDC keeps
								for example 'de Zwaan' vs 'De Zwaan' or 'Suljovic' vs 'Suljović']]
				       		flag1= u[2]
				       		if u[4] then 
				       			plink = '[[' .. u[3] .. '|' ..  u[4] .. ']]'
				       		elseif u[3] then
				       			plink = '[[' .. u[3] .. '|' ..  u[1] .. ']]'
				       		else
				       			plink = '[[' .. u[1] .. ']]'
				       		end				   
				       	break
				       	end
				    end   
	   	   


		

	   	   
			
			   local rowString = '<li>'  -- rank
			   lastRank = v[2]
			   

			   
	   
			   local countryIconString = frame:expandTemplate{title= 'flagicon', args = {flag1}} .. " " .. plink 
			   
	 		   rowString = rowString .. countryIconString
			   

				local move = nil
				for _,w in pairs(data.rankingsold) do
			    	if string.lower(w[1])==string.lower(v[1]) then 
			       		move = w[2] - lastRank    -- get move from last ranking
			       		break	
			       	else
			       		move = 0 - lastRank
			       	end
				end
				
				if move < 0 and math.abs( move ) == math.abs( v[2] ) then -- new teams in ranking: move = -ranking
					change = frame:expandTemplate{ title = 'new entry' } 
			   elseif move == 0 then                                    -- if no change in ranking
			    	change = frame:expandTemplate{ title = 'steady' } 
			    elseif move < 0 then                                 --  if ranking down
			    	change = frame:expandTemplate{ title = 'decrease' }
			    elseif move > 0 then                                 -- if ranking up
			    	change = frame:expandTemplate{ title = 'increase' }
			    end	
			   rowString = rowString .. ' ' .. change .. '</li>'
			   
			   outputString = outputString .. '\n'.. rowString
		end
	end
	outputString = outputString .. '</ol>'
	
    return outputString
	
end

---
--- Returns text list for players first,last for PDC top 20 navbox
function p.nav(frame)

    getArgs(frame) -- returns args table having checked for content
    loadData(frame)	
    local ranking = frame.args[1]
    local first, last = 1,10
    first = tonumber(frame.args['2'])
    last = tonumber(frame.args['3'])
    
    return navlist(frame, ranking, first, last)
end


return p