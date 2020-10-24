require('Module:No globals')
local getArgs = require('Module:Arguments').getArgs

local p = {}

local function deflag(s)
	s = mw.ustring.gsub(s or '', '%[%[[Fe][Ii][Ll][Ee]:[^%[%]]*%]%]', '')
	s = mw.ustring.gsub(s, '%[%[[Ii][Mm][Aa][Gg][Ee]:[^%[%]]*%]%]', '')
	s = mw.ustring.gsub(s, '<[^<>]*>', '')
	s = mw.ustring.gsub(s, '%s*%([A-Z][A-Z][A-Z]%)%s*$', '')
	while s:match('^%s*&[Nn][Bb][Ss][Pp];%s*') do
		s = mw.ustring.gsub(s, '^%s*&[Nn][Bb][Ss][Pp];%s*', '')
	end
	s = mw.ustring.gsub(s, '%s*&[Nn][Bb][Ss][Pp];%s*$', '')
	s = mw.ustring.gsub(s, '%s%s+', ' ')
	s = mw.ustring.gsub(s, '^%s*(.-?)%s*$', '%1')
	return s
end

function p.createTable(frame, args)
	if not args then
		args = getArgs(frame)
	end

    local team = args['team'] or 'Nation'
	local root = mw.html.create()
	local host = args['host'] or ''
	local hostColor = '#ccccff'
	local defaultRowColor = '#f8f9fa'
	local flagTemplate = args['flag_template'] or 'flagteam'
	local event = args['event']
	local legendpos = (args['legend_position'] or 't'):lower()
	local header, footer = '', ''
	local totalGold = 0
	local totalSilver = 0
	local totalBronze = 0
	
	local remainingGold = 0
	local remainingSilver = 0
	local remainingBronze = 0
	local remainingStart = 0
	local remainingEnd = 0
	local limitReached = false
	local showLimit = tonumber(args['show_limit'])

	-- build the legend
	if host ~= '' then
		if args['name_' .. host] then
			host = args['name_' .. host]
			host = 'Host nation (' .. deflag(host) .. ')'
		elseif host:match('^([A-Z][A-Z][A-Z])') then
			host = frame:expandTemplate{title = flagTemplate, args = {host, event} }
			host = 'Host nation (' .. deflag(host) .. ')'
		end
		host = host .. (args['host_note'] or '')
		host = frame:expandTemplate{title = 'color box', args = {hostColor, '&nbsp;*&nbsp;', 'border=darkgray'}} ..'&nbsp;'.. host
	end
	
	local leading = ''
	if args['leading'] then
		leading = frame:expandTemplate{title = 'legend', args = {'#E9D66B', "'''Leading in that sport'''"}}
	end
	
	if legendpos == 't' then
		header = header .. host .. leading
	else
		footer = footer .. host .. leading
	end
	
	root = root
		:tag('table')
		:addClass('wikitable')
		:addClass('sortable')
		:addClass('plainrowheaders')
		:addClass('jquery-tablesorter')
		:css('text-align', 'center')
	
	root:tag('caption')
		:wikitext(args['caption'])
	-- add the header row
	local row = root:tag('tr')
	
	if args['hide_rank'] then else
		row:tag('th')
			:attr('scope', 'col')
			:wikitext('Rank')
	end
	row
		:tag('th')
			:attr('scope', 'col')
			:wikitext(team)
		:tag('th')
			:attr('scope', 'col')
			:addClass('headerSort')
			:css('width', '4em')
			:css('background-color', 'gold')
			:wikitext('Gold')
		:tag('th')
			:attr('scope', 'col')
			:addClass('headerSort')
			:css('width', '4em')
			:css('background-color', 'silver')
			:wikitext('Silver')
		:tag('th')
			:attr('scope', 'col')
			:addClass('headerSort')
			:css('width', '4em')
			:css('background-color', '#c96')
			:wikitext('Bronze')
		:tag('th')
			:attr('scope', 'col')
			:css('width', '4em')
			:wikitext('Total')
	
	-- enumerate the rows
	local rowNums = {}
	local IOCs = {}
	for k,v in pairs(args) do
		k = ''..k
		local IOC = k:match('^gold_([A-Z][A-Z][A-Z])$') or k:match('^gold_(%d+)$')
			or k:match('^silver_([A-Z][A-Z][A-Z])$') or k:match('^silver_(%d+)$')
			or k:match('^bronze_([A-Z][A-Z][A-Z])$') or k:match('^bronze_(%d+)$')
		if IOC and IOCs[IOC] == nil then
			IOCs[IOC] = 1
			local gold   = (tonumber(args['gold_' .. IOC]) or 0)
			local silver = (tonumber(args['silver_' .. IOC]) or 0)
			local bronze = (tonumber(args['bronze_' .. IOC]) or 0)
			local noskip = args['skip_' .. IOC] and 0 or 1
			local nation = args['name_' .. IOC] or 
				frame:expandTemplate{title = flagTemplate, args = {IOC, event} }
			nation = deflag(nation)
			if nation:match('%[%[[^%[%]%|]*%|([^%[%]]*)%]%]') then
				nation = nation:match('%[%[[^%[%]%|]*%|([^%[%]]*)%]%]')
			end
			if nation:match('%[%[([^%[%]%|]*)%]%]') then
				nation = nation:match('%[%[([^%[%]%|]*)%]%]')
			end
			table.insert(rowNums, {gold, silver, bronze, noskip, nation, IOC}) 
		end
	end
	if args['team'] == 'Games' then
		table.sort(rowNums, function (a,b)
			return  a[5] < b[5]
			end
		)
	else
		table.sort(rowNums, function (a, b) 
			return a[1] > b[1] or (a[1] == b[1] and a[2] > b[2]) 
				or (a[1] == b[1] and a[2] == b[2] and a[3] > b[3]) 
				or (a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] > b[4])
				or (a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4] and a[5] < b[5])
				end
		)
	end
	
	local lastGold, lastSilver, lastBronze = -1
	local rank = 0
	local lastspan, lastrankcell = 1, nil
	for i, anum in ipairs(rowNums) do
		local IOC = anum[6]
		if args['skip_' .. IOC] then 
			lastGold, lastSilver, lastBronze, lastspan = -1, -1, -1, 1
		else 
			rank = rank + 1 
		end
		local nation = args['name_' .. IOC] or 
			frame:expandTemplate{title = flagTemplate, args = {IOC, event} }
		local gold   = tonumber(args['gold_' .. IOC]) or 0
		local silver = tonumber(args['silver_' .. IOC]) or 0
		local bronze = tonumber(args['bronze_' .. IOC]) or 0
		local isHost = args['host_' .. IOC]
		-- this is mainly for the parameter names example so you can override it.
		local total  = args['total_' .. IOC] or gold + silver + bronze
		local color = isHost and hostColor or defaultRowColor

		if args['grand_total'] then else
				totalGold = totalGold + gold
				totalSilver = totalSilver + silver
				totalBronze = totalBronze + bronze
		end

		if args['host_' .. IOC] then
			nation = nation .. '*'
		end

		if args['note_' .. IOC] then
			nation = nation .. args['note_' .. IOC]
		end

		if showLimit and (rank>showLimit) then 
			if remainingStart == 0 then remainingStart = rank end
			limitReached = true
			remainingGold = remainingGold + gold
			remainingSilver = remainingSilver + silver
			remainingBronze = remainingBronze + bronze
		else
			local row
			if args['leading_' .. IOC] then
				row = root:tag('tr'):css('background-color', '#E9D66B')
				color = '#E9D66B'
			else
				row = root:tag('tr')
			end
				
			--Don't put the color on the row because of ranks spanning multiple rows. 
			--:css('background-color', color)
			
			if args['hide_rank'] then else
				if (gold == lastGold) and (silver == lastSilver) and (bronze == lastBronze) then
					lastspan = lastspan + 1
					lastrankcell:attr('rowspan',lastspan)
				else
					lastspan = 1
					if args['skip_' .. IOC] then
						lastrankcell = row:tag('td'):wikitext(frame:expandTemplate{title = 'sort', args = {'999', '–'}})
					else
						lastrankcell = row:tag('td'):wikitext(rank)
						lastGold   = gold
						lastSilver = silver
						lastBronze = bronze
					end
				end
			end
			row:tag('th')
					:attr('scope', 'row')
					:css('background-color', color)
					:css('text-align','left')
					:wikitext(nation)
				:tag('td')
					:wikitext(gold)
				:tag('td')
					:wikitext(silver)
				:tag('td')
					:wikitext(bronze)
				:tag('td')
					:wikitext(total)
		end
		remainingEnd = rank
	end
	
	if limitReached then
		root:tag('tr')
				:tag('td')
					:wikitext(remainingStart..'–'..remainingEnd)
				:tag('td')
					:css('font-style', 'italic')
					:css('text-align','left')
					:wikitext(args['remaining_link'] or args['remaining_text'] or 'Remaining')
				:tag('td')
					:wikitext(remainingGold)
				:tag('td')
					:wikitext(remainingSilver)
				:tag('td')
					:wikitext(remainingBronze)
				:tag('td')
					:wikitext(remainingGold+remainingSilver+remainingBronze)
	end

	if team:match('^[A-Z][A-Z][A-Z]$') or team:match('>[A-Z][A-Z][A-Z]<') then else team = team:lower() end
	if team:match('^games$') then team = 'game' end
	
	local colspan 
	if args['hide_rank'] then 
		colspan = 1 
	else 
		colspan = 2	
	end
	if args['hide_totals'] then else
		root:tag('tr')
			:css('background-color', '#eaebef')
			:addClass('sortbottom')
			:tag('th')
				:wikitext('Totals ('..remainingEnd..' '..team..'s)')
				:attr('scope', 'row')
				:css('background-color', '#eaebef')
				:css('font-weight', 'bold')
				:attr('colspan', colspan)
			:tag('td')
				:wikitext(args['total_gold'] or totalGold)
				:css('font-weight', 'bold')
			:tag('td')
				:wikitext(args['total_silver'] or totalSilver)
				:css('font-weight', 'bold')
			:tag('td')
				:wikitext(args['total_bronze'] or totalBronze)
				:css('font-weight', 'bold')
			:tag('td')
				:wikitext(args['grand_total'] or totalGold+totalSilver+totalBronze)
				:css('font-weight', 'bold')
	end

	-- Build the rest of the footer
	if args['source'] or args['notes'] then
		if footer ~= '' then
			footer = footer .. '<br>'
		end
		footer = frame:expandTemplate{ title = 'refbegin' } .. footer
		
		if args['source'] then 
			footer = footer .. 'Source: ' .. args['source']
		end
		if args['notes'] then
			if args['source'] then
				footer = footer .. '<br>'
			end
			footer = footer .. 'Notes: ' .. args['notes']
		end
		footer = footer .. frame:expandTemplate{ title = 'refend' }
	end

	return header .. tostring(root) .. footer
end

return p