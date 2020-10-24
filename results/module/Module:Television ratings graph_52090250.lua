-- This module implements {{Television ratings graph}}.

local contrast_ratio = require('Module:Color contrast')._ratio

--------------------------------------------------------------------------------
-- TVRG class
-- The main class.
--------------------------------------------------------------------------------

local TVRG = {}

-- Allow usages of {{N/A}} cells
function TVRG.NACell(frame,text)
	local cell = mw.html.create('td')
	local attrMatch = '([%a-]*)="([^"]*)"'
	
	infoParam = frame:expandTemplate{title='N/A',args={text}}
	
	-- Gather styles of {{N/A}} and assign to node variable
	while true do
		local a,b = string.match(infoParam,attrMatch)
		if a == nil or b == nil then break end
		cell:attr(a,b)
		infoParam = string.gsub(infoParam,attrMatch,'',1)
	end

	infoParam = string.gsub(infoParam,'%s*|%s*','',1)
	cell:wikitext(infoParam)
	
	return cell
end

-- Create the graph and table
function TVRG.new(frame,args)
	args = args or {}
	
	-- Variables
	local timeline = {}
	local longestseason = -1
	local average = args.average and 1 or 0
	local season_title = args.season_title or 'Season'
	local root = mw.html.create('div')
		:attr('align', 'center')
	
	-- Create the timeline
	
	-- Number of actual viewer numbers
	local numberargs = 0
	for k,v in pairs(args) do 
		if (string.lower(v) == 'n/a') or (not string.match(k,'[^%d]+') and not string.match(v,'[^%d\.]+')) then numberargs = numberargs + 1 end
	end

	-- Determine number of seasons
	local num_seasons = -1
	for k,v in pairs(args) do
		local thisseason = tonumber(string.sub(k,6))
		if string.sub(k,1,5) == 'color' and thisseason > num_seasons then
			num_seasons = thisseason
		end
	end
	if num_seasons < 1 then
		num_seasons = 1
	end

	-- Determine number of episodes and subtract averages if included (they should be equal to the number of seasons)
	local num_episodes
	if average == 1 then
		num_episodes = numberargs-num_seasons
	else
		num_episodes = numberargs
	end

	-- Bar and graph width
	local barwidth
	if num_episodes >= 80 then barwidth = 9
	elseif num_episodes >= 50 then barwidth = 10
	elseif num_episodes >= 20 then barwidth = 11
	else barwidth = 12
	end

	local graphwidth = num_episodes*barwidth
	
	-- Determine maximum viewer figure
	local maxviewers = -1
	local multiple = 'millions'
	for k,v in pairs(args) do
		local num = tonumber(v)
		if tonumber(k) ~= nil and num ~= nil and num > maxviewers then
			maxviewers = num
		end
	end
	if maxviewers <= 1.5 then
		multiple = 'thousands'
		maxviewers = maxviewers*1000
		for k, v in pairs(args) do
			local num = tonumber(v)
			if tonumber(k) ~= nil and num ~= nil then args[k] = tostring(num*1000) end
		end
	end

	-- Basis parameters
	timeline['type'] = 'stackedrect'
	timeline['width'] = (args.width or graphwidth)
	timeline['height'] = (args.height or 300)
	timeline['legend'] = season_title
	timeline['colors'] = ''
	
	timeline['x'] = ''
	timeline['xType'] = 'string'
	timeline['xAxisAngle'] = '-90'
	timeline['xAxisTitle'] = 'Episode'
	
	timeline['yGrid'] = 'y'
	
	-- Color and legend variables
	for season = 1,num_seasons do 
		args["color" .. season] = args["color" .. season] or '#CCCCFF';
		if num_seasons > 1 then
			timeline['y'..season..'Title'] = (args["legend" .. season] or season) .. " " -- The space after this is not a regular space, it is a copy-pasted non-breaking space so the graph registers season names that are numbers (such as 1984 for American Horror Story) as a string, not a number; if it registers as a number, it will register as the first season. Do not remove/change it.
		elseif timeline['legend'] then
			timeline['legend'] = nil
		end
		timeline['colors'] = timeline['colors'] .. args["color" .. season] .. ','
	end
	
	-- Axis labels
	local countryDisplayUS, countryDisplayUK, countryDisplayOther
	if args.country ~= nil and args.country ~= '' then
		if args.country == "U.S." or args.country == "US" or args.country == "United States" then countryDisplayUS = 'U.S.'
		elseif args.country == "U.K." or args.country == "UK" or args.country == "United Kingdom" then countryDisplayUK = 'UK'
		else countryDisplayOther = args.country
		end
	end
	timeline['yAxisTitle'] = ((countryDisplayUS or countryDisplayUK or countryDisplayOther) or "") .. ((countryDisplayUS or countryDisplayUK or countryDisplayOther) and " v" or "V") .. "iewers (" .. multiple .. ")\n"

	-- Add bars to timeline, one per viewer figure
	local bar = 1
	local season = 0
	local thisseason = 0
	local counted_episodes = 0
	
	for k,v in pairs(args) do
		if string.lower(v) == 'n/a' then v = '' end
		if tonumber(k) ~= nil then
			if v == '-' then
				-- Hyphen means new season
				season = season + 1
				timeline['y'..season] = ''
				for ep = 1,counted_episodes do 
					timeline['y'..season] = timeline['y'..season] .. ','
				end
				
				-- Determine highest number of counted_episodes in a season
				if thisseason > longestseason then
					longestseason = thisseason
				end
				thisseason = 0
			elseif average == 0 or (average == 1 and args[k+1] ~= '-' and args[k+1] ~= nil) then
				-- Include bar for viewer figure, do not include if averages are included and the next parameter is a new season marker
				timeline['y'..season] = timeline['y'..season] .. (timeline['y'..season] and ',' or '') .. (v ~= '' and v or 0)
				
				-- Increment tracking variables
				counted_episodes = counted_episodes + 1
				thisseason = thisseason + 1
				bar = bar + 1
			end
		end
	end
	-- Determine highest number of episodes in a season after final season's bars
	if thisseason > longestseason then
		longestseason = thisseason
	end
	
	-- X axis variables
	for ep = 1,num_episodes do 
		timeline['x'] = timeline['x'] .. (timeline['x'] and ',' or '') .. ep
	end
	
	-- If there's a title, add it with the viewers caption, else just display the viewers caption by itself
	if args.title ~= nil and args.title ~= '' then
		root:wikitext("'''''" .. args.title .. "''" .. "&#8202;" .. ": " .. ((countryDisplayUS or countryDisplayUK or countryDisplayOther) or "") .. ((countryDisplayUS or countryDisplayUK or countryDisplayOther) and " v" or "V") .. "iewers per episode (" .. multiple .. ")'''"):css('margin-top', '1em')
	else
		root:wikitext("'''Viewers per episode (" .. multiple .. ")'''"):css('margin-top', '1em')
	end
	root:tag('div'):css('clear','both')

	-- Add timeline to div
	if args.no_graph == nil then
		root:node(frame:expandTemplate{title='Graph:Chart', args=timeline})
		root:tag('div'):css('clear','both')
	end
	
	-- Create ratings table
	if args.no_table == nil then
		local rtable = mw.html.create('table')
		   	:addClass('wikitable')
			:css('text-align', 'center')
		
			-- Create headers rows
			local row = rtable:tag('tr')
			row:tag('th'):wikitext(season_title)
				:attr('colspan','2')
				:attr('rowspan','2')
				:css('padding-left', '.8em')
				:css('padding-right', '.8em')
				
			row:tag('th')
				:attr('colspan',longestseason)
				:wikitext("Episode number")
				:css('padding-left', '.8em')
				:css('padding-right', '.8em')
				
			-- Average column
			if average == 1 then
				row:tag('th')
				   :attr('scope','col')
				   :attr('rowspan','2')
				   :wikitext("Average")
				   :css('padding-left', '.8em')
				   :css('padding-right', '.8em')
			end

			local row = rtable:tag('tr')
			
			for i = 1,longestseason do
				row:tag('th')
				   :attr('scope','col')
				   :wikitext(i)
			end
		
		local season = 1
		local thisseason = 0
		
		-- Create table rows and cells
		for k,v in pairs(args) do
			if tonumber(k) ~= nil then
				-- New season marker, or final episode rating
				if v == '-'  or (average == 1 and args[k+1] == nil) then
					if season > 1 then
						-- Spanning empty cells with {{N/A}}
						if thisseason < longestseason then
							row:node(TVRG.NACell(frame,"N/A"):attr('colspan',longestseason-thisseason))
						end
						
						if average == 1 then
							-- If averages included, then set the averages cell with value or TBD
							if v ~= '' then
								row:tag('td'):wikitext(args[k+1] ~= nil and args[k-1] or v)
							else
								row:node(TVRG.NACell(frame,"TBD"))
							end
							thisseason = thisseason + 1
						end
					end
					
					-- New season marker
					if v == '-' then
						-- New row with default or preset caption
						row = rtable:tag('tr')
						row:tag('th')
							:css('background-color', args['color' .. season])
							:css('width','10px')
						
						row:tag('th')
						   :attr('scope','row')
						   :wikitext(args["legend" .. season] and args["legend" .. season] or season)
						
						thisseason = 0
						season = season + 1
					end
				elseif average == 0 or (average == 1 and args[k+1] ~= '-' and args[k+1] ~= nil) then
					-- Viewer figures, either as a number or TBD
					if string.lower(v) == 'n/a' then
						row:node(TVRG.NACell(frame,"N/A"))
					elseif v ~= '' then
						row:tag('td'):wikitext(v)
						   :css('width', '35px')
					else
						row:node(TVRG.NACell(frame,"TBD"))
					end
					thisseason = thisseason + 1
				end
			end
		end
		
		-- Finish by checking if final row needs {{N/A}} cells
		if average == 0 and thisseason < longestseason then
			row:node(TVRG.NACell(frame,"N/A"):attr('colspan',longestseason-thisseason))
		end
			
		-- Add table to div root and return
		root:node(rtable)
		root:tag('div'):css('clear','both')
	end
	
	local current_monthyear = os.date("%B %Y")
	local span = mw.html.create('span'):wikitext(frame:expandTemplate{title='Citation needed', args={date=current_monthyear}})
	     
	if countryDisplayUS then
		root:wikitext("<small>Audience measurement performed by [[Nielsen Media Research]].</small>" .. (args.refs ~= '' and args.refs or tostring(span)))
	elseif countryDisplayUK then
		root:wikitext("<small>Audience measurement performed by [[Broadcasters' Audience Research Board]].</small>" .. (args.refs ~= '' and args.refs or tostring(span)))
	else
		root:wikitext("<small>Source: </small>" .. (args.refs ~= '' and args.refs or tostring(span)))
	end
	
	return tostring(root)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		removeBlanks = false,
		wrappers = 'Template:Television ratings graph'
	})
	return TVRG.new(frame,args)
end

return p