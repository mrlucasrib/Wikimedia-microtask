local p = {}
local getArgs = require("Module:Arguments").getArgs
local data = mw.loadData('Module:Jcon/data')
local miscTable = data.miscTable
local typeTable = data.typeTable
local divisionTable = data.divisionTable
local pictureTable = data.pictureTable

--[[ 
          R E T U R N P I C T U R E
          Return the picture of text 
]]--

local function returnPicture(frame,Type,args,division)
	if not pictureTable[division] then -- Return nothing if region doen't have pictures
		return ""
	end
	
	local export = pictureTable[division][1]..args[2]..pictureTable[division][2] or "" -- Set picture
	
	if args[2]:upper() == "407ETR" and division == "Highway" then -- Picture exceptions
		export = "Highway407crest.png"
	elseif args[2]:upper() == "QEW" and division == "Highway" then
		export = "Ontario QEW crown.svg"
	else
		routenumber = string.gsub(args[2],"%D","")
		if tonumber(routenumber) == nil then
			return "" -- Return nothing if there's no route number
		elseif tonumber(routenumber) >= 500 and division == "Highway" then -- If highway is secondary
			export = "Ontario Highway "..args[2]..".svg"
		end
	end
	if export == "" or nil then return "" end -- Return nothing if export is nothing
	if frame:callParserFunction('#ifexist', 'Media:' .. export, '1') ~= '' then -- Set picture sizes
		if args["size"] then                                                    
			return table.concat({"[[File:",export,"|alt=|link=|",args["size"],"]]"})
		elseif args[2]:upper() == "407ETR" then
			return table.concat({"[[File:",export,"|alt=|link=|24px]]"})
		elseif division == "Kawartha Lakes" then
			return table.concat({"[[File:",export,"|alt=|link=|21px]]"})	
		else
			return table.concat({"[[File:",export,"|alt=|link=|x20px]]"})
		end
	else
		return "" -- Retrun nothing if the picture doesn't exist
	end
end

--[[
          R E T U R N T E X T 
          Returns the text/link 
]]--

local function returnText(frame,Type,args,division,showred)
	local export; -- Link
	local display; -- Display (if different from link)
		if args[2]:upper() == "407ETR" then -- Exception
			export = "Ontario Highway".." ".."407"
			display = "407".." ".."ETR"
		elseif args[2]:upper() == "QEW" then -- Exception
			export = "Queen Elizabeth Way"
		elseif Type == "Highway" then -- Highways
			export = "Ontario Highway".." "..args[2]
			display = "Highway".." "..args[2]
		elseif division == "Kawartha Lakes" then 
			export ="Kawartha Lakes" .." ".."Road".." "..args[2]
			display = Type.." ".."Road".." "..args[2]
		elseif Type == "County Highway" or Type == "Regional Highway" or Type == "County Line" then
			export = division.." "..args[2]
			display = Type.." "..args[2]
		else
			export = division.." "..Type.." ".."Road".." "..args[2]
			display = Type.." ".."Road".." "..args[2]
		end
		if (frame:callParserFunction('#ifexist',export, '1') ~= '' or showred) and not args["nolink"] then 
			if display then
				export =  "[["..export.."|"..display.."]]" -- Show display
			else
				export = "[["..export.."]]" -- Show export
			end
			
			return export
		elseif display then
			return display
		else
			return export
		end
end

--[[
           R E T U R N P L A C E 
           Add name/link for a city/town
]]--

local function returnPlace(frame,export,place,after,showred)
	local preExport
	if frame:callParserFunction('#ifexist',place..", Ontario", '1') ~= '' or showred then
		preExport = "[["..place..", Ontario|"..place.."]]"
	else
		preExport = place
	end
	if after == true then
		return export..", "..preExport
	else
		return export.." – "..preExport
	end
end

--[[
           P . J C O N
           Return final picture(s)/text(s)
]]--

function p.jcon (frame)
	local args = getArgs(frame)
	args[1] = args[1] or "" -- Unnil args[1]
	local Remove = {"regional","region","county","country",
		"municipality of","city of","^ "," $"} -- Stuff to remove from lowercase input
	for _,v in ipairs(Remove) do
		args[1] = mw.ustring.gsub(args[1]:lower(),v,'')
	end
	args[2] = args[2] or ""
	local division = divisionTable[args[1]:lower()] or args[1]
	local Type = typeTable[division]
	local export = ""
	if miscTable[args[1]:lower()] or miscTable[args[2]:lower()] then
		return miscTable[args[1]:lower()] or miscTable[args[2]:lower()]
	end
	if not typeTable[division] then -- Region not in typeTable
		return "&#8203;"
	end
	if args[2] == "" then -- Need args[2] after this point
		return "&#8203;"
	end
	if args["ot"] then -- If output should only be text
		args["nosh"] = "yes"
		args["nolink"] = "yes"
	end
	args["2A"] = args[2] -- road1 is args[2]
	if args["con"] then args["2B"] = args["con"] end -- road 2 is args["con"]
	if args["con2"] then args["2C"] = args["con2"] end -- road 3 is args["con2"]
	-- [[ G E T   P I C T U R E ]] --
	if not args["nosh"] then -- If allowed to add shield
			args[2] = args["2A"] -- Set args[2] to road 1
			picture = returnPicture(frame,Type,args,division) -- Return picture of road 1
		if args["con"] then
			args[2] = args["2B"] -- Set args[2] to road 2
			picture = picture.."&nbsp;"..returnPicture(frame,Type,args,division) -- Return picture of road 2
		end
		if args["con2"] then
			args[2] = args["2C"] -- Set args[2] to road 3
			picture = picture.."&nbsp;"..returnPicture(frame,Type,args,division) -- Return picture of road 3
		end
		if picture ~= "" and not args["pic aft"] then -- If a picture was returned and picture goes first
			picture = picture.."&nbsp;" -- Add a space
		end
	end
	-- [[ A D D   P I C T U R E ]] (If it goes before) --
	if not args["pic aft"] and picture then -- If picure goes first
		export = picture
	end
	-- [[ A D D   T E X T ]] --
	if not args["notext"] then -- If allowed to show text
		args[2] = args["2A"]
		export = export..returnText(frame,Type,args,division,args['showred']) 
		if args["con"] then
			args[2] = args["2B"]
			export = export.."&nbsp;".."/".." "..returnText(frame,Type,args,division,args['showred'])
		end
		if args["con2"] then
			args[2] = args["2C"]
			export = export.."&nbsp;".."/".." "..returnText(frame,Type,args,division,args['showred'])
		end
	end
	if args["dir"] then -- Direction
		export = export.." "..args["dir"]
		if args["condir"] then
			export=export.."/"..args["condir"]
		end
	end
	if args[3] then -- Name (argument 3)
		export = export.." ("..args[3]..")"
	end
	if args["city"] then -- City 1
		export = returnPlace(frame,export,args["city"],false,args['showred'])
	elseif args["town"] then -- Or town 1
		export = returnPlace(frame,export,args["town"],false,args['showred'])
	end
	if args["city2"] then -- City 1
		export = returnPlace(frame,export,args["city2"],true,args['showred'])
	elseif args["town2"] then -- Or town 1
		export = returnPlace(frame,export,args["town2"],true,args['showred'])
	end
	-- [[ A D D   P I C T U R E ]] (If it goes after) --
	if args["pic aft"] and picture then
		export = export.."&nbsp;"..picture
	end
	return export
end

--[[
           P . S U P P O R T E D 
           Return all supported "regions" in a list format
]]--

function p.supported (frame)
	local export = "'''Note: All inputs are converted to lowercase'''<br /><u>'''Supported 'Regions':'''</u>" -- Add header
	local supportedTable = {} -- Used to store all regional tables
	local index = {} -- Used to sort alphabetically
	for correct,_ in pairs(typeTable) do -- Create tables for each region
		supportedTable[correct] = {correct}
	end 
	for improper,proper in pairs(divisionTable) do -- Add improper to regional tables
		if supportedTable[proper] then
			table.insert(supportedTable[proper],improper)
		else
			mw.log(proper.." doesn't have a type specified") -- Log regions that do not have a type
			supportedTable[proper] = {proper,improper} -- Create table
		end
	end
    for correct,_ in pairs(supportedTable) do  -- Add keys to sortable index
    	table.insert(index,correct) 
    end
    table.sort(index) -- Sort index
    for _,correct in ipairs(index) do -- Go over each proper region
    	for _,name in ipairs(supportedTable[correct]) do -- Go over each region name
    		table.sort(supportedTable[correct])
    		if name == correct then -- Add to list if proper name
    			export = export.."<br />• "..name
    		else -- Add to list if improper name
    			export = export.."<br />".."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".."• "..name
    		end
    	end
    end
    export = export.."<br /><u>'''Supported MTO signs:'''</u>" -- Add MTO header
    for k,v in pairs(miscTable) do -- Add MTO signs
		export = export.."<br />• "..k
	end
	return export -- Return list
end

--[[
           Return Output
           End of module
]]--

return p;