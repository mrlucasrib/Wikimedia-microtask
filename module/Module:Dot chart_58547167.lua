local p = {}
local getArgs = require("Module:Arguments").getArgs
local yesno = require('Module:Yesno')

--------------------------------------------------------------------------------
---------- P . D O T S ---------------------------------------------------------
---------- Returns all the dots (with absolute postions) -----------------------
--------------------------------------------------------------------------------

function p.data(frame)                                                          -- Returns the data of the graph
	local args = getArgs(frame)
	-- Dot related
	local yTable = {}
	local xTable = {}
	local xCount = 0
	local yCount = 0
	local isx;
	local dotTable = {}
	local x;
	-- Color related
	local colorTable = {}
	local num;
	local colorTime;
	-- X label related
	local xLabels = {}
	local xLCount = 0
	-- Y label related
	local yLabels = {}
	local yLCount = 0

	if yesno(args["yx"]) == true then
		isx = false
	else
		isx = true
	end
	
	if args["x labels"] then                                                    -- Create xLabels
		for str in string.gmatch(args["x labels"], "([^,]+)") do
	        table.insert(xLabels,str)
	        xLCount = xLCount+1
	    end
	end
	
	if args["y labels"] then                                                    -- Create yLabels
		for str in string.gmatch(args["y labels"], "([^,]+)") do
			table.insert(yLabels,str)
			yLCount = yLCount+1
	    end
	end
	
	if args["dots"] then                                                        -- Creates xTable from dots
		local i = 0
		local j = 0
		
		for k,v in pairs(args) do
			if string.match(k,"%d+") 
			and not string.match(k,"color%-") then
				table.insert(yTable,v)
				yCount = yCount+1
			end
		end
		
		local cols = yCount / tonumber(args["dots"])
		
		if cols ~= math.floor(cols) then
			return table.concat({'<span style="font-size:100%" class="error">The amount of y parameters (',yCount,') ÷ parameter dots (',args["dots"],') is not a integer (',cols,')</span>'})
		end
		
		while(cols>i) do
			local xValue = ((100/cols*i)+(100/cols/10))*1.1
			i=i+1
			while(tonumber(args["dots"])>j) do
				j=j+1
				table.insert(xTable,xValue)
				xCount = xCount + 1
			end
			j=0
		end
	else                                                                        -- Divides args into the yTable and the xTable
		for k,v in pairs(args) do                                               
			if string.match(k,"%d+") 
			and not string.match(k,"color%-") then
				if isx == false then
					table.insert(yTable,v)
					yCount = yCount + 1
					isx = true
				elseif not args["dots"] then
					table.insert(xTable,v)
					xCount = xCount + 1
					isx = false
				end
			end
		end
	end
	
	if xCount < yCount then                            
		return table.concat({'<span style="font-size:100%" class="error">The amount of x values (',xCount,') is less then the number y values (',yCount,')</span>'})
	elseif xCount > yCount then
		return table.concat({'<span style="font-size:100%" class="error">The amount of x values (',xCount,') is more then the number y values (',yCount,')</span>'})
	end
	
	if args["color-even"] then                                                  -- Creates the colorTable if color-even is set
		colorTime = false
		for k,v in pairs(yTable) do
			if colorTime == true then
				colorTable[k] = args["color-even"]
				colorTime = false
			else
				colorTime = true
			end
		end
	end
	
	if args["color-odd"] then                                                   -- Creates the colorTable if color-odd is set
		colorTime = true
		for k,v in pairs(yTable) do
			if colorTime == true then
				colorTable[k] = args["color-odd"]
				colorTime = false
			else
				colorTime = true
			end
		end
	end
	
	for k,v in pairs(args) do                                                   -- Adds values to the colorTable if color-# is set
		if k == mw.ustring.match(k,"color%-%d+") then
			num = mw.ustring.gsub(k,"color%-","")
			num = tonumber(num)
			colorTable[num] = v
		end
	end
	
	for k,y in pairs(yTable) do                                                 -- Creates the dotTable
		local InnerDiv = mw.html.create('div')
		local div = mw.html.create('div')
		local size; 
		if args["size"] then
			size = tonumber(mw.ustring.match(args["size"],"(%d+)"))
		else
			size = 8
		end
		x = xTable[k]
		InnerDiv
			:css('position','absolute')
			:css('top',table.concat({'-',size/2,'px'}))
			:css('left',table.concat({'-',size/2,'px'}))
			:css('line-height','0')
			:wikitext('[[File:Location dot ',colorTable[k] or 'red','.svg|',size,'x',size,'px]]')
		div
			:css('position','absolute')
			:css('bottom',table.concat({y*0.85+15,'%'}))
			:css('left',table.concat({x*0.85+15,'%'}))
			:wikitext(tostring(InnerDiv))
		table.insert(dotTable,tostring(div))
	end
	
	for k,v in pairs(xLabels) do
		local div = mw.html.create('div')
		div
			:css('position','absolute')
			:css('bottom','0%')
			:css('left',table.concat({((100/xLCount*k-100/xLCount)*0.85+15)-4,'%'}))
			:wikitext(v)
		table.insert(dotTable,tostring(div))
	end
	
	for k,v in pairs(yLabels) do
		local div = mw.html.create('div')
		div
			:css('position','absolute')
			:css('bottom',table.concat({(((((100/yLCount*k-100/yLCount)-(100/yLCount/3))+5))+100/yLCount/2)*1.02,'%'}))
			:css('left','0%')
			:wikitext(v)
		table.insert(dotTable,tostring(div))
	end
	
	return table.concat(dotTable)
end

---------- L E G E N D ---------------------------------------------------------
---------- Makes the legendTable -----------------------------------------------

local function legend(args)
	local color;
	local aValue;
	local Table = {}
	for k,v in pairs(args) do                                                   -- Adds values to the table
		if k == mw.ustring.match(k,"legend%-%a+") then
			color = mw.ustring.gsub(k,"legend%-","")
			v = table.concat({'<div>[[File:Location dot ',color or 'red','.svg|8x8px]] (',color,') = ',v,'</div>'})
			table.insert(Table,v)
			aValue = true
		end
	end
	if aValue == true then
		return table.concat(Table)
	else
		return ""
	end
end

--------------------------------------------------------------------------------
---------- P . G R A P H -------------------------------------------------------
---------- Returns all the dots in div tags-------------------------------------
--------------------------------------------------------------------------------

function p.graph(frame)         	                                        	-- Returns a graph with the dots on it
	if mw.ustring.match(p.data(frame),"<span") then                             -- Return error messages from p.data
		return p.data(frame) 
	end   
	local args = getArgs(frame)
	local picture = "Blank.png"
	local div = mw.html.create('div')
	local center = mw.html.create('div')
	local container = mw.html.create('div')
	local top = mw.html.create('div')
	local size; 
	if args["size"] then
		size = tonumber(mw.ustring.match(args["size"],"(%d+)"))
	else
		size = 8
	end
	
	if args["width"] then
		if args["width"] == mw.ustring.match(args["width"],"(%d+)") then
			args["width"] = table.concat({args["width"],'px'})
		end
	end

	if args["picture"] then                                                     -- Set local picture
		picture = args["picture"]
	elseif yesno(args["square"]) == true then
		picture = "Transparent.png"
	end
	
	picture = mw.ustring.gsub(picture,'|.+','')
	picture = mw.ustring.gsub(picture,'.-:','')
	
	if p.data(frame) == "" then                                                 -- Don't make box if empty
		return ""
	end
	 
	if args["top"] then
		top                                                                     -- Create top text
			:css('font-weight','bold')
			:css('text-decoration','underline')
			:css('text-align','center')
			:wikitext(args["top"])
	end
	
	container                                                                   -- Creates container
		:css('width',args["width"] or '240px')
		:css('float','right')
		:css('position','relative')
		:wikitext('[[File:',picture,'|',args["width"] or '240px',']]')
		:wikitext(p.data(frame))
	div                                                                         -- Creates box
		:css('width',args["width"] or '240px')
		:css('display','inline-block')
		:css('float',args["align"] or 'right')
		:css('margin',args["margin"] or '2px')
		:css('padding',args["padding"] or table.concat({size/2,'px'}))
		:css('background',args["color"] or 'none')
		:wikitext(tostring(top))
		:wikitext(tostring(container))
		:wikitext(legend(args))
		:wikitext(args["bottom"])
		
	if yesno(args['border']) ~= false then                                      -- Creates box border
		div
			:css('border-style','solid')
			:css('border-color','black')
			:css('border-width','3px')
	end
		
	if args['align'] == 'center' then                                           -- Centers output if needed
		center
			:addClass('center')
			:css('width','auto')
			:css('margin-left','auto')
			:css('margin-right','auto')
			:wikitext(tostring(div))
		return center                                                   
	else
		return div
	end
end

return p