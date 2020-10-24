-- This module implements {{Series overview}}.

require('Module:No globals')
local yesno = require('Module:Yesno')
local HTMLcolor = mw.loadData( 'Module:Color contrast/colors' )

--------------------------------------------------------------------------------
-- SeriesOverview class
-- The main class.
--------------------------------------------------------------------------------

local SeriesOverview = {}

function SeriesOverview.cellspan(SeasonEntries, SeasonEntries_ordered, key, cell, multipart, setspan)
	if setspan ~= nil then return setspan end
	
	local spanlength = 1
	
	local firstEntry = SeasonEntries[SeasonEntries_ordered[cell]]
	if key == 'network' and firstEntry.networkA and not firstEntry.networkB then spanlength = 2 end
	
	for i = cell+1, #SeasonEntries_ordered do
		local entry = SeasonEntries[SeasonEntries_ordered[i]]
		-- Split season, then regular season
		if entry.startA then
			if not entry[key..'A'] then spanlength = spanlength + 1
			else break end
			if not entry[key..'B'] then spanlength = spanlength + 1
			else break end
		else
			if not entry[key] and (key == 'network' or ((string.sub(key,0,7) == 'postaux' or string.sub(key,0,3) == 'aux') and (not entry.special or entry.episodes)) or (string.sub(key,0,4) == 'info') and multipart) then
				spanlength = spanlength + 1
			else break end
		end
	end
	return spanlength
end

-- Sorting function
function SeriesOverview.series_sort(op1, op2)
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
function SeriesOverview.season_cell(text, frame)
	local cell
	
	if string.find(text or '', 'table-na', 0, true) ~= nil then
		local findpipe = string.find(text, ' | ', 0, true)
		if findpipe ~= nil then
			cell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={string.sub(text,findpipe+3)}} )
		else
			cell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A'} )
		end
	else
		cell = mw.html.create('td'):wikitext(text)
	end
	
	return cell
end

-- Allow usages of {{N/A}} cells
function SeriesOverview.series_attributes(infoParam)
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

function SeriesOverview.new(frame, args)
	args = args or {}
	
	local initialArticle = args['1'] or ''
	local categories = ''
	local title = mw.title.getCurrentTitle()
	local allReleased = yesno(args.allreleased)

	-- Create series overview table
	local root = mw.html.create((args.multiseries or not args.series) and 'table' or '')
	local cellPadding = '0 8px'
	local basePadding = '0.2em 0.4em'

	root
		:addClass('wikitable')
		:addClass('plainrowheaders')
		:css('text-align', 'center')
	
	-- Sortable
	if args.sortable then
		root:addClass('sortable');
	end
	
	-- Width
	if args.width then
		root:css('width', args.width)
	end

	-- Caption
	if args.caption then
		root:tag('caption'):wikitext(frame:expandTemplate{title='sronly',args={args.caption}})
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
	table.sort(SeasonEntries_ordered,SeriesOverview.series_sort)
	
	local firstRow = args.multiseries and {} or SeasonEntries[SeasonEntries_ordered[1]]
	
	-- Colspan calculation for information cells (0 = no info set)
	local numAuxCells = 0
	local numInfoCells = 0
	for i = string.byte('A'), string.byte('Z') do
		local param = 'info' .. string.char(i)
		if args[param] then numInfoCells = numInfoCells + 1 end
	end
	
	-- Top info cell
	-- @ = string.char(64), A = string.char(65)
	local topInfoCell = numInfoCells > 0 and string.char(numInfoCells + (string.byte('A') - 1)) or '@'
	
	-- Networks are included if the very first entry sets the first network
	local setNetwork = (args.multiseries and args.network) or firstRow.network or firstRow.networkA
	local networkTransclude = args.network_transclude
	if (networkTransclude == 'onlyinclude' and title.fullText == initialArticle) or (networkTransclude == 'noinclude' and title.fullText ~= initialArticle) then
		setNetwork = false
	end

	-- Headers
	do
		if args.multiseries or not args.series then
			local headerRow = root:tag('tr')
			headerRow
				:css('text-align', 'center')
			
			local releasedBlurb = args.released and 'released' or 'aired'
			
			-- Base series/season content on the format of the first date; Series = D M Y, Season = M D, Y
			local matchDMY = false
			local thisStart = firstRow.start or firstRow.startA
			if thisStart then
				if string.match(thisStart:gsub("&nbsp;"," "), '(%d+)%s(%a+)%s(%d+)') then
					matchDMY = true
				end
			end
			
			-- Multiple series header
			if args.multiseries then
				headerRow:tag('th')
					:attr('scope', 'col')
					:css('padding', cellPadding)
					:attr('rowspan', allReleased and 1 or 2)
					:wikitext('Series')
			end
			
			-- Season header
			headerRow:tag('th')
				:attr('scope', 'col')
				:attr('rowspan', allReleased and 1 or 2)
				:attr('colspan', 2)
				:css('min-width', '50px')
				:css('padding', cellPadding)
				:wikitext(args.seriesT or args.seasonT or (matchDMY and 'Series') or 'Season')
			
			for _a = 1, 3 do
				if _a == 1 or _a == 3 then
					-- Aux headers
					local auxtype = (_a == 3 and 'post' or '') .. 'aux'
					for i = string.byte('A'), string.byte('Z') do
						local param = auxtype .. string.char(i)
						if args[param] then
							numAuxCells = numAuxCells + 1
							headerRow:tag('th')
								:attr('scope', 'col')
								:css('padding', cellPadding)
								:attr('rowspan', allReleased and 1 or 2)
								:wikitext(args[param])
						end
					end
				end
				
				if _a == 2 then
					-- Episodes header
					headerRow:tag('th')
						:attr('scope', 'col')
						:attr('rowspan', allReleased and 1 or 2)
						:attr('colspan', 2)
						:css('padding', cellPadding)
						:wikitext('Episodes')
				end
			end

			-- Originally aired header
			local OriginallyColspan = (not allReleased and setNetwork) and 3 or 2
			local countryBlurb = ''
			if args.country then
				countryBlurb = ' (' .. args.country .. ')'
			end
			headerRow:tag('th')
				:attr('scope', 'col')
				:attr('colspan', OriginallyColspan)
				:wikitext('Originally ' .. releasedBlurb .. countryBlurb)
			
			-- Network subheader for released series
			if setNetwork and allReleased then
				headerRow:tag('th')
					:attr('scope', 'col')
					:attr('rowspan', allReleased and 1 or 2)
					:css('padding', cellPadding)
					:wikitext('Network')
			end
			
			-- Information headers
			if topInfoCell ~= '@' then
				for i = string.byte('A'), string.byte(topInfoCell) do
					local param = 'info' .. string.char(i)
					local infoTransclude = args[param .. '_transclude']
					if (infoTransclude == 'onlyinclude' and title.fullText == initialArticle) or (infoTransclude == 'noinclude' and title.fullText ~= initialArticle) then else
						headerRow:tag('th')
							:attr('scope', 'col')
							:attr('rowspan', allReleased and 1 or 2)
							:css('padding', cellPadding)
							:wikitext(args[param])
					end
				end
			end
			
			-- Subheader row
			local subheaderRow = mw.html.create('tr')

			if not allReleased then
				-- First aired subheader
				subheaderRow:tag('th')
					:attr('scope', 'col')
					:wikitext('First ' .. releasedBlurb)

				-- Last aired subheader
				subheaderRow:tag('th')
					:attr('scope', 'col')
					:wikitext('Last ' .. releasedBlurb)
				
				-- Network subheader for aired series
				if setNetwork then
					subheaderRow:tag('th')
						:attr('scope', 'col')
						:css('padding', cellPadding)
						:wikitext('Network')
				end
			end
		
			-- Check for scenarios with an empty subheaderRow
			if not allReleased or numInfoCells > 0 then
				root:node(subheaderRow)
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
			if title.namespace == 0 and #SeasonEntries == 1 then
				categories = categories .. '[[Category:Articles using Template:Series overview with only one row]]'
			end
		
			-- Determine number of rows in the whole overview
			local SeasonEntriesRows = 0
			for X = 1, #SeasonEntries_ordered do
				local season, entry = SeasonEntries_ordered[X], SeasonEntries[SeasonEntries_ordered[X]]
				local splits = 0
				for i = string.byte('A'), string.byte('Z') do
					local param = 'start' .. string.char(i)
					if entry[param] then splits = splits + 1 end
				end
				if splits == 0 then splits = 1 end
				SeasonEntriesRows = SeasonEntriesRows + splits
			end
			
			for X = 1, #SeasonEntries_ordered do
				local season, entry = SeasonEntries_ordered[X], SeasonEntries[SeasonEntries_ordered[X]]
				
				-- Determine number of splits in a season
				local splits = 0
				for i = string.byte('A'), string.byte('Z') do
					local param = 'start' .. string.char(i)
					if entry[param] then splits = splits + 1 end
				end
				local splitSeason = (splits > 1)
				
				-- Season rows for each season
				for k0 = string.byte('A')-1, string.byte('Z') do
					local k = string.char(k0)
					if k0 == string.byte('A')-1 then k = '' end
					
					-- New season row
					-- local seasonRow = (entry['color' .. k] or entry['episodes' .. k] or entry['start' .. k] or entry['end' .. k]) and root:tag('tr') or mw.html.create('tr')
					local seasonRow = entry['start' .. k] and root:tag('tr') or mw.html.create('tr')
					
					-- Series name for group overviews
					if X == 1 and (k == '' or k == 'A') and args.series then
						seasonRow:tag('th')
							:attr('scope', 'row')
							:attr('rowspan', SeasonEntriesRows)
							:wikitext(args.series)
					end
					
					-- Coloured cell
					if entry['color' .. k] ~= nil and HTMLcolor[entry['color' .. k]] == nil then 
						entry['color' .. k] = '#'..(mw.ustring.match(entry['color' .. k], '^[%s#]*([a-fA-F0-9]*)[%s]*$') or '')
					end
					if splitSeason and entry.color then
						if k == 'A' then
							seasonRow:tag('td')
								:attr('rowspan', entry.color and splits or 1)
								:css('background', entry.color)
								:css('width','10px')
						end
					else
						seasonRow:tag('td')
							:css('background',entry['color' .. k])
							:css('width','10px')
					end
					
					-- Season number link, included only in the first row
					if k == '' or k == 'A' then
						seasonRow:tag(args.series and 'td' or 'th')
							:attr('scope', 'row')
							:attr('rowspan', splitSeason and splits or nil)
							:attr('colspan', entry.special and not entry.episodes and 3+numAuxCells or 1)
							:css('text-align', 'center')
							:wikitext((entry.link and '[[' .. entry.link .. '|' .. (entry.linkT or season) .. ']]' or (entry.linkT or season)) .. (entry.linkR or ''))
					end
					
					for _a = 1, 3 do
						if _a == 1 or _a == 3 then
							-- Aux headers
							local auxtype = (_a == 3 and 'post' or '') .. 'aux'
							-- Aux cells
							for i = string.byte('A'), string.byte('Z') do
								local param = auxtype .. string.char(i)
								if entry[param .. k] then
									local thisCell = SeriesOverview.season_cell(entry[param .. k], frame)
										:attr('scope', 'col')
										:attr('rowspan', SeriesOverview.cellspan(SeasonEntries, SeasonEntries_ordered, param, X, (args.series and true or false), entry[param .. k .. 'span'] or nil))
										:css('padding', cellPadding)
									seasonRow:node(thisCell)
								end
							end
						end
						
						if _a == 2 then
							-- Episodes counts
							if ((splitSeason and k == 'A' and entry.episodes ~= 'hide') or not splitSeason) then
								if entry.episodes then
									local thisCell = SeriesOverview.season_cell(entry.episodes, frame)
										:attr('colspan', splitSeason and 1 or 2)
										:attr('rowspan', splitSeason and splits or nil)
									seasonRow:node(thisCell)
								elseif not entry.special then
									local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
									infoCell
										:attr('colspan', splitSeason and 1 or 2)
										:attr('rowspan', splitSeason and splits or nil)
									seasonRow:node(infoCell)
								end
							end
							if splitSeason then
								if entry['episodes' .. k] then
									local thisCell = SeriesOverview.season_cell(entry['episodes' .. k], frame)
										:attr('colspan', (entry.episodes ~= 'hide') and 1 or 2)
									seasonRow:node(thisCell)
								else
									local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
										:attr('colspan', (entry.episodes ~= 'hide') and 1 or 2)
									seasonRow:node(infoCell)
								end
							end
						end
					end
				
					-- Start date
					if entry['start' .. k] then
						local thisCell = SeriesOverview.season_cell(entry['start' .. k], frame)
							:attr('colspan',((not entry.special and entry['end' .. k] == 'start') or (entry.special and not entry['end' .. k]) or allReleased) and 2 or 1)
							:css('padding',basePadding)
						seasonRow:node(thisCell)
					else
						local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
						infoCell:css('padding',basePadding)
						seasonRow:node(infoCell)
					end
					
					-- End date
					if not allReleased and entry['end' .. k] ~= 'start' and ((entry.special and entry['end' .. k]) or not entry.special) then
						if entry['end' .. k] then
							local thisCell = SeriesOverview.season_cell(entry['end' .. k], frame)
								:css('padding',cellPadding)
							seasonRow:node(thisCell)
						else
							local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
							infoCell:css('padding',cellPadding)
							seasonRow:node(infoCell)
						end
					end
					
					-- Network
					if entry['network' .. k] and setNetwork then
						local thisCell = SeriesOverview.season_cell(entry['network' .. k], frame)
							:attr('rowspan', SeriesOverview.cellspan(SeasonEntries, SeasonEntries_ordered, 'network', X, (args.series and true or false), entry['network' .. k .. 'span'] or nil))
						seasonRow:node(thisCell)
					end
					
					-- Information
					for i = string.byte('A'), string.byte(topInfoCell) do
						local param0 = 'info' .. string.char(i)
						local param = 'info' .. string.char(i) .. k
						
						local infoTransclude = args[param .. '_transclude']
						if (infoTransclude == 'onlyinclude' and title.fullText == initialArticle) or (infoTransclude == 'noinclude' and title.fullText ~= initialArticle) then else
							local infoParam = entry[param]
							
							if infoParam and splitSeason and k == '' and not entry[param .. 'A'] then
								entry[param .. 'A'] = entry[param]
								entry[param .. 'spanning'] = 'y'
							end
							
							local rowspan = (entry[param0 .. 'spanning'] and splits) or
											(args.series and SeriesOverview.cellspan(SeasonEntries, SeasonEntries_ordered, param0, X, (args.series and true or false), entry[param0 .. 'span'] or nil))
											or nil
							
							if k == 'A' or (k ~= 'A' and not entry[param0 .. 'spanning']) then
								-- Cells with {{N/A|...}} already expanded
								if infoParam then
									if string.sub(infoParam,1,5) == 'style' then
										local infoCell = SeriesOverview.series_attributes(infoParam)
										infoCell:attr('rowspan', rowspan)
										seasonRow:node(infoCell)
									else
										-- Unstyled content info cell
										local thisCell = SeriesOverview.season_cell(infoParam, frame)
											:attr('rowspan', rowspan)
										seasonRow:node(thisCell)
									end
								else
									if not args.series then
										local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
										infoCell:attr('rowspan', rowspan)
										seasonRow:node(infoCell)
									end
								end
							elseif not entry[param0 .. 'spanning'] then
								if not args.series then
									local infoCell = SeriesOverview.series_attributes( frame:expandTemplate{title='N/A',args={'TBA'}} )
									infoCell:attr('rowspan', rowspan)
									seasonRow:node(infoCell)
								end
							end
						end
					end
				
				end -- End k0 string.byte
			end -- End 'for' SeasonEntries_ordered
		end -- End 'if' multiseries
	end -- End 'do' season rows

	return (args.dontclose and mw.ustring.gsub(tostring(root), "</table>", "") or tostring(root)) .. categories
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Series overview'
	})
	return SeriesOverview.new(frame, args)
end

return p