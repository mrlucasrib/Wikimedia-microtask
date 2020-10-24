local p = {}

-------------
-- Exports --
-------------

-- Used by [[Template:Drag Race contestant table]]
function p.contestant_table( frame )
	return p._contestant_table( frame )
end

-- Used by [[Template:Drag Race progress table]]
function p.progressTable( frame )
	return p._progressTable( frame )
end

-- Used by [[Template:Drag Race progress key]]
function p.key( frame )
	return p._key( frame )
end

-----------------------
-- Utility Functions --
-----------------------
function p._inTable( t, k )
	return (t[k] ~= nil)
end

function p._sortRows(a,b)
	return a[1] > b[1]	
end

function p._revSortRows(a,b)
	return a[1] < b[1]	
end

p.colorMap = { -- See [[Wikipedia:Manual of Style/Accessibility/Colors]]
	["red"] = "#FF7B7B",
	['orange'] = "#FFA7AF",
	["yellow"] = "#FAFA00",
	["chartreuse"] = "#A8FF4F",
	["green"] = "#7BFF7B",
	["spring"] = "#4FFFA8",
	["cyan"] = "#00FAFA",
	["dodger"] = "#4FA8FF",
	["blue"] = "#8888FF",
	["indigo"] = "#BB76FF",
	["magenta"] = "#FF29FF",
	["pink"] = "#FF52A9",
	["brown"] = "#E97500",
	["grey"] = "#808080",
	["gray"] = "#808080",
	["silver"] = "#F8F9FA" -- Actually just the usual background table color
}

----------------------
-- Contestant table --
----------------------
function p._contestant_table( frame )
	local templateFrame = frame:getParent()
	local contestantData = p._getContestantData( templateFrame )
	ret = [=[
	{| class="wikitable sortable" border="2" style="text-align:center;"
	|+ Contestants of ''All Stars 5'' and their backgrounds
	! scope="col"| Contestant
	! scope="col"| Age
	! scope="col"| Hometown
	! scope="col"| Original season(s)
	! scope="col"| Original placement(s)
	! scope="col"| Outcome
	]=]
	for k, v in pairs( contestantData ) do
		ret = ret .. p._bio_makeRow(contestantData[k])
	end
	return ret .. "|}"
end

function p._bio_makeRow( contestant )
	local rowTemplate = [=[
	|-
	! scope="row" rowspan="${NROWS}"|[[${NAME}]]
	|rowspan="${NROWS}"|${AGE}
	|rowspan="${NROWS}"|${HOMETOWN}
	]=]
	if string.find(contestant['season'], 'All Stars') ~= nil then
		rowTemplate = rowTemplate .. "|[[RuPaul's Drag Race All Stars (season ${SEASON-NUM})|''All Stars'' ${SEASON-NUM}]]\n"
		contestant['season-num'] = string.match(contestant['season'], 'All Stars (%d+)')
		contestant['season'] = nil
	else
		rowTemplate = rowTemplate .. "|[[RuPaul's Drag Race (season ${SEASON})|Season ${SEASON}]]\n"
	end
	rowTemplate = rowTemplate .. [=[
	|<span data-sort-value="${PLACE-SORT}">${PLACE}</span>
	]=]
	if contestant['outcome'] ~= nil then
		rowTemplate = rowTemplate .. '|rowspan="${NROWS}"|${OUTCOME}\n'
		if #tostring(contestant['outcome']) < 3 then
			contestant['outcome'] = p._makePlace(contestant['outcome'])
		end
	else
		rowTemplate = rowTemplate .. '|rowspan="${NROWS}" style="background: #DDF; color: #2C2C2C; vertical-align: middle; text-align: center;" class="no table-no2"|TBA\n'
	end

	if tonumber(contestant['nrows']) > 1 then
		rowTemplate = rowTemplate .. "|-\n"
		if string.find(contestant['season2'], 'All Stars') ~= nil then
			rowTemplate = rowTemplate .. "|[[RuPaul's Drag Race All Stars (season ${SEASON2-NUM})|''All Stars'' ${SEASON2-NUM}]]\n"
			contestant['season2-num'] = tostring(string.match(contestant['season2'], '%d+'))
			contestant['season2'] = nil
		else
			rowTemplate = rowTemplate .. "|[[RuPaul's Drag Race (season ${SEASON2})|Season ${SEASON2}]]\n"
		end
		rowTemplate = rowTemplate .. '|<span data-sort-value="${PLACE2-SORT}">${PLACE2}</span>\n'
		if contestant['place2-sort'] == nil then
			contestant['place2-sort'] = p._makePlaceSort(contestant['place2'])
		end
		local place
		if #tostring(contestant['place2']) > 2 then 
		  	place = string.match(contestant['place2'],'(%d+)%D%D')
		else
		   	place = contestant['place2']
		end
		contestant['place2'] = p._makePlace(place)
	end
	for k, v in pairs( contestant ) do
		mw.log(k:upper())
		rowTemplate = string.gsub(rowTemplate,"${"..k:upper():gsub('%-','%%-').."}",contestant[k])
	end
	return rowTemplate	
end

function p._getContestant( k )
	return string.match( k, "contestant%-(%d+)" )
end

function p._getField( k )
	return string.match( k, "contestant%-%d+%-(.*)")
end

function p._getContestantData( frame )
    local contestantData = {}
    for k, v in pairs( frame.args ) do
    	-- Read inputs and organize them by contestant
   		if not p._inTable(contestantData, p._getContestant(k)) then
   			contestantData[p._getContestant(k)] = {}
   		end
   		if p._getField(k) ~= nil then
    		contestantData[p._getContestant(k)][p._getField(k)] = v
    	else
    		contestantData[p._getContestant(k)]["name"] = v
    	end
    end
    for k, v in pairs( contestantData ) do
    	-- Final cleanup of the input before rendering table
	    if not p._inTable(contestantData[k],"nrows") then
	    	contestantData[k]["nrows"] = 1
	    end
	    if not p._inTable(contestantData[k],"place-sort") then
		    if #tostring(contestantData[k]['place']) > 2 then 
		    	place = string.match(contestantData[k]['place'],'(%d+)%D%D')
		    else
		    	place = contestantData[k]['place']
		    end
	    	contestantData[k]["place-sort"] = p._makePlaceSort(place)
	    end
	    if #tostring(contestantData[k]['place']) < 3 then 
	    	contestantData[k]['place'] = p._makePlace(contestantData[k]['place'])
		end
    end
    return contestantData
end

function p._makePlaceSort( place )
	if #tostring(place) < 2 then
		return '0'..place
	else
		return place
	end
end

function p._makePlace( place )
	place = tonumber(place)
	if place == 1 then
		return '1st Place'
	elseif place == 2 then
		return '2nd Place'
	elseif place == 3 then
		return'3rd Place'
	else
		return place .. 'th Place'
	end
end

-------------------------------
-- Contestant progress table --
-------------------------------
function p._progressTable( frame )
	local templateFrame = frame:getParent()
	local contestantData = {}
	ret = ""
	for i=1,50 do
		arg = templateFrame.args[i]
		if arg == nil then
			break
		elseif i % 3 == 1 then -- First in triplet is contestant name
			contestantData[arg] = {{}}
		elseif i % 3 == 2 then -- Second in triple is color codes
			contestantData[templateFrame.args[i-1]][1] = arg
		else -- Third in triplet is text
			contestantData[templateFrame.args[i-2]][2] = arg
		end
	end
	contestantData, width = p._parseRanks( contestantData )
	ret = ret .. [=[{| class="wikitable" style="text-align:center;"
	|+Progress of contests including rank/position in each episode
	! scope="col"| Contestant
	]=]
	for i=1,width do
		ret = ret .. "! scope='col'| " .. i .."\n"	
	end
	rowList = {}
	for k,v in pairs(contestantData) do
		table.insert(rowList,p._prog_makeRow(k,v,width))
	end
	table.sort(rowList,p._sortRows)
	for i=1,20 do
		if rowList[i] == nil then
			break
		end
		ret = ret .. rowList[i][2]
	end
	return ret .. "|}"
end

function p._parseRanks( contestantData )
	local data = {}
	local high = 0
	for k,v in pairs(contestantData) do
		data[k] = {}
		data[k][1] = mw.text.split(contestantData[k][1],',%s*')
		data[k][2] = mw.text.split(contestantData[k][2],',%s*')
		if #data[k][1] > high then
			high = #data[k][1]
		end
	end
	return data, high
end
	
function p._prog_makeRow( contestant, tableData, width )
	row = "|-\n! scope='row'| " .. contestant .. "\n"
	colors = tableData[1]
	labels = tableData[2]
	final = 0
	for i=1,20 do
		-- If we've reached the end of the list...
		if colors[i] == nil then
			final = i
			-- ...and the entries span the entire width of the table, then finish
			if i > width then
				break
			end
			-- ...otherwise, fill the rest of the columns with darkgray
			row = row .. "| colspan='" .. width + 1 - i .. "' bgcolor='darkgray' |\n"
			break
		end
		text = labels[i]
		color = p.colorMap[colors[i]:gsub("%s+","")]
		row = row .. "| style='background:" .. color .. ";' |" .. text .. "\n"
	end
	retRow = {
		final,
		row
	}
	return retRow
end

-------------------------
-- Make key for colors --
-------------------------
function p._key( frame )
	local templateFrame = frame:getParent()
	local args = templateFrame.args
	local ret = ''
	local order = mw.text.split(args.order,',%s*')
	args.order = nil
	local reverseIndex = {}
	for i,v in ipairs(order) do
		reverseIndex[v] = i
	end
	local rowTable = {}
	for k,v in pairs(args) do
		if k ~= 'order' then
			box = p._makeColorBox( k )
			text = v .. "\n"
			row = { reverseIndex[k], box .. text }
			table.insert(rowTable,row)
		end
	end
	table.sort(rowTable,p._revSortRows)
	for i=1,20 do
		if rowTable[i] == nil then
			break
		end
		ret = ret .. rowTable[i][2]
	end
	return ret
end

function p._makeColorBox( key )
	local template = ':<span style="background-color:HEXCODE; border:1px solid #000000;">&nbsp;&nbsp;&nbsp;&nbsp;</span> '
	color = p.colorMap[key]
	return string.gsub(template, 'HEXCODE', color)
end

return p