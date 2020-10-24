require('Module:No globals')

local p = {
	TIE_REGEX = '^T([%d]+)%s*$'
}

local div = {
	senior = { 'M', 'W', 'C'},
	junior = { 'B', 'G', 'C'}
}

local evt = { 
	{'BSKB', 'Basketball' },
	{'3X3B', '3x3 basketball' },
	{'INVB', 'Volleyball (indoor)' },
	{'BCVB', 'Volleyball (beach)' },
	{'SWMM', 'Swimming' },
	{'CHSS', 'Chess' },
	{'TNNS', 'Tennis' },
	{'SFTN', 'Soft tennis' },
	{'TBTN', 'Table tennis' },
	{'BDMT', 'Badminton' },
	{'TKWD', 'Taekwondo' },
	{'JUDO', 'Judo' },
	{'BSBL', 'Baseball' },
	{'SFBL', 'Softball' },
	{'FTBL', 'Football' },
	{'ATHL', 'Athletics' },
	{'FENC', 'Fencing' },
	{'ESPT', 'Electronic sports' }
}

local colors = {
			 { 'gold',	  'Champion'},
			 { 'silver',  'Runner-up' },
			 { '#CC9966', 'Third place' },
	['WD'] = { '#FFBBBB', 'Withdrew' },
	['NT'] = { nil, 	  'No team' }
}

local function isnotempty(s)
	return s and s:match('^%s*(.-)%s*$') ~= ''
end

local function stripwhitespace(text)
	return text:match("^%s*(.-)%s*$")
end

local function findchamp(teams, t, r)
	local found = (teams[t].res[r].rank == 1 or teams[t].res[r].raw == 'T1')
	if found or (t == 1) then return found else return findchamp(teams, t - 1, r) end
end

local function countties(teams, r)
	local tie = {}
	for kt, vt in pairs(teams) do
		local raw = vt.res[r].raw or ''
		if (raw):match(p.TIE_REGEX) then
			tie[raw] = (tie[raw] or 0) + 1
		end
	end
	return tie
end

local function getevtdisp(teams, division)
	local r = 1
	local evt_disp = {}
	for ke, ve in pairs(evt) do
		for kd, vd in pairs(div[division]) do
			local showevt = findchamp(teams, #teams, r)
			local ties = countties(teams, r)
			table.insert(evt_disp, { show = showevt, ties = ties })
			r = r + 1
		end
	end
	return evt_disp
end

local function getevtindex(value)
	for k, v in pairs(evt) do
		if v[1] == value then return tonumber(k) end
	end
	return tonumber(99)
end

local function getvte(frame, args)
	local baselink = frame:getParent():getTitle()
	if mw.title.getCurrentTitle().text == baselink then	baselink = '' end
	local vtetemplate = args['tname'] or (baselink ~= '' and (':' .. baselink)) or ''

	if vtetemplate ~= '' then
		return frame:expandTemplate{ title = 'navbar', args = { mini=1, style='float:left', brackets=1, vtetemplate} }
	end
	return nil
end

local function getbg(rank, raw)
	rank = tonumber(tostring(raw):match(p.TIE_REGEX) or rank) or 0
	if rank > 0 and rank <= 3 then return colors[rank][1]
	elseif raw == 'WD' then return colors.WD[1]
	else return nil
	end
end

local function comptiepts(ptsbyrank, trank, teamsize, ctie)
	local count = ctie['T'..trank]
	if count == 0 then return ptsbyrank[trank] end
	local limit, total = trank + count - 1, 0
	if limit > teamsize then error('Invalid number of teams tied on #'..trank) end
	for i=trank, limit do
		total = ptsbyrank[i] + total
	end
	return total / count
end

local function getpts(rank, raw, ptsbyrank, tsize, ctie)
	local  trank = tonumber(tostring(raw):match(p.TIE_REGEX)) or 0
	if	   trank > 0 then return comptiepts(ptsbyrank,trank,tsize,ctie) or ptsbyrank.NT
	elseif string.match(raw,'([?|WD])') then return raw
	else   return ptsbyrank[rank] or ptsbyrank.NT
	end
end

local function prefillvalues(args,teams,division,ptsbyrank,ovptsonly)
	local tally = {}
	for kt, vt in pairs(teams) do
		local res, subtotal, overall, gold, silver, bronze = {}, {}, 0, 0, 0, 0
		
		local evt_disp = getevtdisp(teams,division,ptsbyrank)
		for kr, vr in pairs(vt.res) do
			local evtprop = evt_disp[kr]
			if evtprop.show then
				local rank = tonumber(tostring(vr.raw):match(p.TIE_REGEX)) or vr.rank
					vr.pts = tonumber(getpts(rank,vr.raw,ptsbyrank,#teams,evtprop.ties)) or 0
				subtotal[vr.div] = (tonumber(subtotal[vr.div]) or 0) + vr.pts
				if	   rank == 1 then gold = gold + 1
				elseif rank == 2 then silver = silver + 1
				elseif rank == 3 then bronze = bronze + 1 end
				table.insert(res, vr)
			end
		end
		for kd, vd in pairs(div[division]) do overall = overall + tonumber(subtotal[vd] or 0) end

		if ovptsonly then
			overall = tonumber(args['pts_'..vt.code]) or overall
		end
		table.insert(tally, { rank = vt.rank, code = vt.code, team = vt.name, res = res, subtotal = subtotal, overall = overall, medals = { gold, silver, bronze } })
	end
	table.sort(tally, function (a, b) return a.overall > b.overall or (a.overall == b.overall and a.rank < b.rank) end)
	return tally
end

local function medaltable(frame,args,tally,division,isfinal)
	local mMedals = require('Module:Medals table')
	local legendL = 'Leads the '..(args['overall'] or 'general')..' championship tally'
	args['team'] = 'Team'
	args['event'] = 'inst'
	args['legend_position'] = 'b'
	args['flag_template'] = args['team_template'] or 'UAAPteam'
	args['host_note'] = string.format(';&nbsp;%s&nbsp;%s', frame:expandTemplate{title = 'color box', args = {'#E9D66B'}}, legendL)
	args['notes'] = isfinal and 'Results are final.' or 'Season in progress. Results are not yet final.'
	
	for kt, vt in pairs(tally) do
		local name = args['name_'..vt.code]
		if kt == 1 and vt.overall ~= 0 then
			args['leading_'..vt.code] = 'yes'
		end
		if division == 'junior' and isnotempty(args['j_short_'..vt.code]) then
			args['name_'..vt.code] = frame:expandTemplate{title = args['flag_template'], args = { vt.code, division, inst = args['j_short_'..vt.code] } }
		elseif division == 'senior' and isnotempty(args['short_'..vt.code]) then
			args['name_'..vt.code] = frame:expandTemplate{title = args['flag_template'], args = { vt.code, division, inst = args['short_'..vt.code] } }
		elseif not isnotempty(name) or name == nil then
			args['name_'..vt.code] = vt.name
		end
		if stripwhitespace(args['status_'..vt.code] or '') == 'H' then
			args['host_'..vt.code] = 'yes'
			args['host'] = 'Season host'
		end
		args['gold_'..vt.code] = vt.medals[1]
		args['silver_'..vt.code] = vt.medals[2]
		args['bronze_'..vt.code] = vt.medals[3]
	end
	return mMedals.createTable(frame, args)
end

local function buildtable(frame,args,teams,division,ptsbyrank,showmedals,ovptsonly,sumsonly,isfinal)
	local tally = prefillvalues(args,teams,division,ptsbyrank,ovptsonly)
	
	if showmedals then
		return medaltable(frame,args,tally,division,isfinal)
	end
	
	local root = mw.html.create()
	local footer = mw.html.create()
	local abbr = mw.html.create('abbr')
	root = root:tag('table')
		:addClass('wikitable')
		:addClass('plainrowheaders')
		:css('font-size', (ovptsonly or sumsonly) and '100%' or '95%')
		:css('text-align', 'center')
	
	-- header row (1)
	local evts = tally[1].res
	local divs = div[division]
	local row = root:tag('tr')
	local celltype = not ovptsonly and 'th' or 'td'
	local showwg, showc, showhost, hidedivs = false, false, false, true
	
	if not ovptsonly then
		row:tag('th')
			:attr('scope', 'col')
			:attr('colspan', '2')
			:wikitext(getvte(frame,args))
		
		abbr:attr('title', 'Mixed or co-ed'):wikitext(divs[3])
		
		-- column spanning by event
		local prevspan, prevcell, prevevt = 0, nil, nil
		for ke, ve in pairs(evts) do
			local evtname = evt[getevtindex(ve.evt)][2]
			if	   ve.div == divs[2] then showwg = true
			elseif ve.div == divs[3] then showc  = true end
			if not sumsonly then
				if (prevevt == ve.evt) then
					prevspan = prevspan + 1
					prevcell
						:attr('colspan', prevspan)
				else
					prevspan = 1
					prevcell = row:tag('th')
						:attr('scope', 'col')
						:wikitext(string.format('[[File:%s pictogram.svg|20px|link=|%s]]', evtname, evtname))
					prevevt = ve.evt
				end
			end
		end
		
		hidedivs = not showwg and not showc
		row:tag('th')
			:attr('scope', 'col')
			:attr('colspan', hidedivs and 1 or (((not showwg and showc) or (showwg and not showc)) and 3 or 4))
			:css('border-left-width', '3px')
			:wikitext('Total')
	end
	
	-- header row (2)
	row = root:tag('tr')
	row:tag('th')
			:attr('scope', 'col')
			:attr('width', '50px')
			:wikitext('Rank')
		:tag('th')
			:attr('scope', 'col')
			:attr('width', '90px')
			:wikitext('Team')
	
	if not (ovptsonly or sumsonly) then
		for ke, ve in pairs(evts) do
			row:tag('th')
				:attr('scope', 'col')
				:attr('width', '22px')
				:wikitext(ve.div == divs[3] and tostring(abbr) or ve.div)
		end
	end
	
	if not ovptsonly then
		for kd, vd in pairs(divs) do
			if  (hidedivs or
				(not showwg and vd == divs[2]) or
				(not showc and vd == divs[3])) then break
			else
				row:tag('th')
					:attr('scope', 'col')
					:attr('width', '22px')
					:css('border-left-width', (kd == 1) and '3px' or nil)
					:wikitext(vd == divs[3] and tostring(abbr) or vd)
			end
		end
	end
	
	row:tag('th')
		:attr('scope', 'col')
		:css('border-left-width', hidedivs and '3px' or nil)
		:wikitext(ovptsonly and 'Points' or 'Overall')
	
	-- row spanning by points
	local prevpts, prevspan, prevrankcell, prevtotalcell = -1, 0, nil, nil
	
	-- team row
	for ka, va in pairs(tally) do
		local teamtext = va.team

		if stripwhitespace(args['status_'..va.code] or '') == 'H' then
			showhost = true
			teamtext = va.team..'&nbsp;<b>(H)</b>'
		end
		
		row = root:tag('tr')
		
		if (prevpts == va.overall) then
			prevspan = prevspan + 1
			prevrankcell
				:attr('rowspan', prevspan)
		else
			prevspan = 1
			prevrankcell = row:tag(celltype)
					:attr('scope', 'row')
					:css('text-align', 'center')
					:wikitext(ka)
		end
		
		row:tag('td')
			:attr('scope', 'row')
			:css('white-space', 'nowrap')
			:css('text-align', 'left')
			:wikitext(teamtext)
					
		if not ovptsonly then
			if not sumsonly then
				for kr, vr in pairs(va.res) do
					row:tag('td')
						:css('background-color', getbg(vr.rank,vr.raw))
						:wikitext(vr.pts ~= 0 and vr.pts or ptsbyrank.NT)
				end
			end
			
			for kd, vd in pairs(divs) do
				if (hidedivs or
					(not showwg and vd == divs[2]) or
					(not showc and vd == divs[3])) then break
				else row:tag('td')
					:css('border-left-width', (kd == 1) and '3px' or nil)
					:wikitext(va.subtotal[vd] or 0)
				end
			end
		end
		
		if (prevpts == va.overall) then
			prevtotalcell
				:attr('rowspan', prevspan)
		else
			prevspan = 1
			prevtotalcell = row:tag(celltype)
				:attr('scope', 'row')
				:css('font-weight', 'bold')
				:css('text-align', 'center')
				:css('border-left-width', hidedivs and '3px' or nil)
				:wikitext(va.overall)
			prevpts = va.overall
		end
	end
	
	local source, legend = args['source'], footer:tag('div'):attr('class', 'reflist')
	
	if source then
		legend:tag(''):wikitext('Source: '.. source ..'<br>')
	end
	if showhost then
		legend:tag('span')
			:css('font-weight', 'bold')
			:wikitext('(H)')
			:done()
		:wikitext('&nbsp;Season host')
		if ovptsonly or sumsonly then legend:wikitext('.') end
	end
	if not (ovptsonly or sumsonly) then
		local firsttag = not showhost
		for kp, vp in pairs(ptsbyrank) do
			if not string.match(kp,p.TIE_REGEX) and (tonumber(kp) or 0) < 4 then
				if firsttag == false then legend:wikitext('; ') end
				legend:tag('span')
					:css('margin', '0')
					:css('white-space', 'nowrap')
					:tag('span')
						:addClass('legend-text')
						:css('border', 'none')
						:css('padding', '1px .3em')
						:css('background-color', getbg(kp))
						:css('font-size', '95%')
						:css('border', '1px solid #BBB')
						:css('line-height', '1.25')
						:css('text-align', 'center')
						:wikitext(type(vp) == 'number' and '&nbsp;' or vp)
						:done()
					:wikitext(' = ' .. (colors[kp] or colors.NT)[2])
				firsttag = false
			end
		end
		legend:wikitext('.')
	end
	
	legend:wikitext('<br>Notes: ' .. (isfinal and 'Results are final.' or 'Season in progress. Results are not yet final.'))

	return tostring(root)..tostring(footer)
end

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame, { parentFirst = true })
	
	local yesno = require('Module:Yesno')
	local showmedals = yesno(args['show_medals'] or 'n')
	local ovptsonly = yesno(args['overall_pts_only'] or 'n')
	local sumsonly = yesno(args['subtotals_only'] or 'n')
	local isfinal = yesno(args['final'] or 'y')
	local division = (args['division'] or 'senior'):lower()
	local template = args['team_template'] or 'UAAPteam'
	local team_list, defaultpts = {}, { 15, 12, 10, 8, 6, 4, 2, 1, NT = '&mdash;' }
	local ptsbyrank = { NT = defaultpts.NT }
	
	for ka, va in pairs(args) do
		-- Process team args
		local i = tostring(ka):match('^team([%d]+)%s*$') or '0'
		if (tonumber(i) > 0 and isnotempty(va)) then
			local res, t = {}, args['team' .. i]
			local sname = args['short_' .. t]
			if division == 'junior' and isnotempty(args['j_short_' .. t]) then sname = args['j_short_' .. t] end
			local tname = args['name_' .. t] or
				(isnotempty(sname) and
					frame:expandTemplate{title = template, args = { t, division, name = sname } } or 
					frame:expandTemplate{title = template, args = { t, division, 'short' } }
				)
			for ke, ve in pairs(evt) do
				for kd, vd in pairs(div[division]) do
					local cvd = vd
					if (kd == 3) then cvd = division:sub(1,1) end
					local evt_rank = stripwhitespace(args[cvd:lower()..'_'..ve[1]..'_'..t] or '')
					table.insert(res, { div = vd, evt = ve[1], raw = stripwhitespace(evt_rank), rank = tonumber(evt_rank) or 0 })
				end
			end
			table.insert(team_list, {rank = i, code = t, name = tname, res = res})
		end
	end
	
	if #team_list == 0 then error ('At least one team required') end
	for r=1,#team_list do
		ptsbyrank[r] = tonumber(stripwhitespace(args['pts_'..require('Module:Ordinal')._ordinal(r)] or '')) or defaultpts[r] or 0
	end
	return buildtable(frame,args,team_list,division,ptsbyrank,showmedals,ovptsonly,sumsonly,isfinal)
end

return p