-- This module implements {{Television critical response}}.

require('Module:No globals')
local yesno = require('Module:Yesno')

--------------------------------------------------------------------------------
-- CriticalResponse class
-- The main class.
--------------------------------------------------------------------------------

local CriticalResponse = {}

function CriticalResponse.cellspan(SeasonEntries, SeasonEntries_ordered, key, cell, multipart)
	local spanlength = 1
	
	for i = cell+1, #SeasonEntries_ordered do
		local entry = SeasonEntries[SeasonEntries_ordered[i]]
		-- Split season, then regular season
		if entry.startA then
			if not entry[key..'A'] then spanlength = spanlength + 1
			else break end
			if not entry[key..'B'] then spanlength = spanlength + 1
			else break end
		else
			if not entry[key] and (not entry.special and multipart) then
				spanlength = spanlength + 1
			else break end
		end
	end
	return spanlength
end

-- Sorting function
function CriticalResponse.series_sort(op1, op2)
	local n1,s1 = string.match(op1,"(%d+)(%a*)")
	local n2,s2 = string.match(op2,"(%d+)(%a*)")
	local n1N,n2N = tonumber(n1),tonumber(n2)

	if n1N == n2N then
		return s1 < s2
	else
		return n1N < n2N
	end
end

-- Function to add either text or {{N/a}} to cell
function CriticalResponse.season_cell(text, frame)
	local cell
	
	if string.find(text or '', 'table-na', 0, true) ~= nil then
		local findpipe = string.find(text, ' | ', 0, true)
		if findpipe ~= nil then
			cell = CriticalResponse.series_attributes( frame:expandTemplate{title='N/A',args={string.sub(text,findpipe+3)}} )
		else
			cell = CriticalResponse.series_attributes( frame:expandTemplate{title='N/A'} )
		end
	else
		cell = mw.html.create('td'):wikitext(text)
	end
	
	return cell
end

-- Allow usages of {{N/A}} cells
function CriticalResponse.series_attributes(infoParam)
	local entries = {}
	local infoCell = mw.html.create('td')
	local attrMatch = '([%a-]*)="([^"]*)"'
	
	while true do
		local a,b = string.match(infoParam,attrMatch)
		if a == nil or b == nil then break end
		infoCell:attr(a,b)
		infoParam = string.gsub(infoParam,attrMatch,'',1)
	end

	infoParam = string.gsub(infoParam,'%s*|%s*','',1)
	infoCell:wikitext(infoParam)
	
	return infoCell
end

function CriticalResponse.new(frame, args)
	args = args or {}
	
	local initialArticle = args['1'] or ''
	local categories = ''
	local title = mw.title.getCurrentTitle()
	local hide_rotten_tomatoes = yesno(args.hide_rotten_tomatoes)
	local hide_metacritic = yesno(args.hide_metacritic)
	local series_name = tostring(title):gsub("%s%((.-)%)","")

	-- Create critical response table
	local root = mw.html.create((args.multiseries or not args.series) and 'table' or '')
	local cellPadding = '0 8px'
	local basePadding = '0.2em 0.4em'
	
	root
		:addClass('wikitable')
		:addClass('plainrowheaders')
		:css('text-align', 'center')
		
	-- Remove float if multiple series
	if not args.multiseries then
		root:css('float', 'right')
		root:css('margin', '10px')
	end
	
	-- Sortable
	if args.sortable or args.multiseries then
		root:addClass('sortable');
	end
	
	-- Width
	if args.width then
		root:css('width', args.width)
	end

	-- Caption
	if not args.series then
		if args.title and args.multiseries then
			root:tag('caption'):wikitext(frame:expandTemplate{title='sronly',args={'Critical response of ' .. args.title}})
		elseif args.title then
			root:tag('caption'):wikitext(frame:expandTemplate{title='sronly',args={'Critical response of <i>' .. args.title .. '</i>'}})
		else
			root:tag('caption'):wikitext(frame:expandTemplate{title='sronly',args={'Critical response of <i>' .. series_name .. '</i>'}})
		end
	end

	-- Extract seasons info and place into a 3D array
	local SeasonEntries = {}
	for k,v in pairs(args) do
		local str, num, str2 = string.match(k, '([^%d]*)(%d*)(%a*)')
		if num ~= '' then
			-- Special
			local special = false
			if string.sub(str2,1,1) == 'S' then
				special = true
				num = num .. str2
				str2 = ''
			end
			-- Add to entries, create if necessary
			if not SeasonEntries[num] then
				SeasonEntries[num] = {}
			end
			SeasonEntries[num][str .. str2] = v
			if special then
				SeasonEntries[num]['special'] = 'y'
			end
		end
	end

	-- Order table by season number
	local SeasonEntries_ordered = {}
	for k in pairs(SeasonEntries) do
		table.insert(SeasonEntries_ordered, k)
	end
	table.sort(SeasonEntries_ordered,CriticalResponse.series_sort)
	
	local firstRow = args.multiseries and {} or SeasonEntries[SeasonEntries_ordered[1]]

	-- Headers
	do
		if args.multiseries or not args.series then
			local headerRow = root:tag('tr')
			headerRow
				:css('text-align', 'center')
			
			-- Multiple series header
			if args.multiseries then
				headerRow:tag('th')
					:attr('scope', 'col')
					:css('padding', cellPadding)
					:wikitext('Series')
			end
			
			-- Season header
			headerRow:tag('th')
				:attr('scope', 'col')
				:css('min-width', '50px')
				:css('padding', cellPadding)
				:addClass('unsortable')
				:wikitext(args.seriesT or args.seasonT or 'Season')

			-- Rotten Tomatoes header
			if not hide_rotten_tomatoes then
				headerRow:tag('th')
					:attr('scope', 'col')
					:wikitext('[[Rotten Tomatoes]]')
			end

			-- Metacritic header
			if not hide_metacritic then
				headerRow:tag('th')
					:attr('scope', 'col')
					:wikitext('[[Metacritic]]')
			end
		end
	end

	-- Season rows
	do
		if args.multiseries then
			-- Multi series individual entries
			if args.multiseries ~= "y" then
				root:node(args.multiseries)
			end
		else
			-- One row entries, only categorized in the mainspace
			if #SeasonEntries == 1 then
				categories = categories .. '[[Category:Articles using Template:Television critical response with only one row]]'
			end
		
			-- Determine number of rows in the whole table
			local SeasonEntriesRows = 0
			for X = 1, #SeasonEntries_ordered do
				local season, entry = SeasonEntries_ordered[X], SeasonEntries[SeasonEntries_ordered[X]]
				SeasonEntriesRows = SeasonEntriesRows + 1
			end
			
			for X = 1, #SeasonEntries_ordered do
				local season, entry = SeasonEntries_ordered[X], SeasonEntries[SeasonEntries_ordered[X]]
				
				-- Season rows for each season
				for k0 = string.byte('A')-1, string.byte('Z') do
					local k = string.char(k0)
					if k0 == string.byte('A')-1 then k = '' end
					
					-- New season row
					local seasonRow = (entry['rotten_tomatoes' .. k] or entry['metacritic' .. k]) and root:tag('tr') or mw.html.create('tr')
					
					-- Series name for group overviews
					if X == 1 and (k == '' or k == 'A') and args.series then
						seasonRow:tag('th')
							:attr('scope', 'row')
							:attr('rowspan', SeasonEntriesRows)
							:wikitext(args.series)
					end
					
					-- Season number link, included only in the first row
					if k == '' or k == 'A' then
						seasonRow:tag(args.series and 'td' or 'th')
							:attr('scope', 'row')
							:attr('colspan', entry.special or 1)
							:css('text-align', 'center')
							:wikitext((entry.link and '[[' .. entry.link .. '|' .. (entry.linkT or season) .. ']]' or (entry.linkT or season)) .. (entry.linkR or ''))
					end
				
					-- Rotten Tomatoes
					if not hide_rotten_tomatoes and entry['rotten_tomatoes' .. k] ~= 'metacritic' then
						if entry['rotten_tomatoes' .. k] then
							local thisCell = CriticalResponse.season_cell(entry['rotten_tomatoes' .. k], frame)
								:css('padding',basePadding)
							seasonRow:node(thisCell)
						else
							local infoCell = CriticalResponse.series_attributes( frame:expandTemplate{title='N/A'} )
							infoCell:css('padding',basePadding)
							seasonRow:node(infoCell)
						end
					end
					
					-- Metacritic
					if not hide_metacritic and entry['metacritic' .. k] ~= 'rotten_tomatoes' then
						if entry['metacritic' .. k] then
							local thisCell = CriticalResponse.season_cell(entry['metacritic' .. k], frame)
								:css('padding',cellPadding)
							seasonRow:node(thisCell)
						else
							local infoCell = CriticalResponse.series_attributes( frame:expandTemplate{title='N/A'} )
							infoCell:css('padding',cellPadding)
							seasonRow:node(infoCell)
						end
					end
				
				end -- End k0 string.byte
			end -- End 'for' SeasonEntries_ordered
		end -- End 'if' multiseries
	end -- End 'do' season rows

	return tostring(root) .. categories
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Television critical response'
	})
	return CriticalResponse.new(frame, args)
end

return p