-- implements [[template:IceHockeybox]]
local p = {}

local errorcats = ''

local function isnotempty(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function mysplit(s)
	-- Change <br> tags to slashes
	s = mw.ustring.gsub(s or '', '<[\/%s]*[Bb][Rr][^<>]*>', ' / ')
	s = mw.ustring.gsub(s or '', '[%s]* /[%s]*', ' / ')
	s = mw.ustring.gsub(s or '', '[%s]*/ [%s]*', ' / ')
	-- Split into a table
	s = mw.text.split(s .. ' / ', ' / ')
	-- Remove empty rows
	local t = {}
	for k=1,#s do
		if isnotempty(s[k]) then
			table.insert(t, s[k])
		end
	end
	return t
end

local function scoringtable(g1, g2, p)
	local root = ''
	-- If there is no progression then do a very simple format
	if (not isnotempty(p)) and (isnotempty(g1) or isnotempty(g2)) then
		root = mw.html.create('table')
			root
				:attr('cellspacing', '0')
				:css('width', '100%')
		local row = root:tag('tr'):css('text-align','top')
		row:tag('td')
			:css('text-align','right')
			:css('width', '39%')
			:wikitext(g1 or '')
		row:tag('td')
			:css('text-align','center')
			:css('width', '22%')
			:tag('i'):wikitext('Goals')
		row:tag('td')
			:css('text-align','left')
			:css('width', '39%')
			:wikitext(g2 or '')
		return tostring(root)
	end
	
	-- Split into tables
	local gt1 = mysplit(g1)
	local gt2 = mysplit(g2)
	local pt  = mysplit(p)
	-- Align goals with scores in progression
	local score1, score2 = 0, 0
	for k = 1,#pt do
		local s1 = tonumber(mw.ustring.gsub(pt[k] or '', '^[%s]*([0-9][0-9]*)[^0-9][^0-9]*([0-9][0-9]*)[%s]*$', '%1') or '-1') or -1
		local s2 = tonumber(mw.ustring.gsub(pt[k] or '', '^[%s]*([0-9][0-9]*)[^0-9][^0-9]*([0-9][0-9]*)[%s]*$', '%2') or '-1') or -1
		if s1 == (score1 + 1) and s2 == score2 then
			score1 = s1
			table.insert(gt2, k, '')
		elseif s2 == (score2 + 1) and s1 == score1 then
			score2 = s2
			table.insert(gt1, k, '')
		else
			errorcats = errorcats .. '[[Category:Pages using icehockeybox with improperly formatted progression or goals]]'
			errorcats = errorcats .. 'Error: Goals/Progression mismatch: S1 = ' .. s1 .. ' S2 = ' .. s2 .. ' GT1 = ' .. (gt1[k] or '') .. ' GT2 = ' .. (gt2[k] or '') .. '<br>'
		end
	end
	if not (#gt1 == #pt) or not(#gt2 == #pt) then
		errorcats = errorcats .. '[[Category:Pages using icehockeybox with improperly formatted progression or goals]]'
		errorcats = errorcats .. 'Error: Goals/Progression mismatch: N1 = ' .. #gt1 .. ' N2 = ' .. #gt2 .. ' PN = ' .. #pt .. '<br>'
	end
	-- Now build the score table
	for k=1,#pt do
		if k == 1 then
			root = mw.html.create('table')
			root
				:attr('cellspacing', '0')
				:css('width', '100%')
		end
		local row = root:tag('tr'):css('text-align','top')
		row:tag('td')
			:css('text-align','right')
			:css('width', '39%')
			:wikitext(gt1[k] or '')
		row:tag('td')
			:css('text-align','center')
			:css('width', '22%')
			:wikitext(pt[k] or '')
		row:tag('td')
			:css('text-align','left')
			:css('width', '39%')
			:wikitext(gt2[k] or '')
	end
	
	return tostring(root)
end

function p.box( frame )
	local args = frame:getParent().args
	local res = ''
	local id = args['id'] or ''
	
	id = mw.ustring.gsub(id,'^"(.-)"$', '%1')
	
	local root = mw.html.create('table')
	root
		:attr('cellspacing', '0')
		:attr('id', id )
		:css('width', '100%')
		:css('background-color', args['bg'] or '#eeeeee')
		:addClass('vevent')
	local row = root:tag('tr'):addClass('summary')
	-- Date and time
	local cell = row:tag('td')
		:css('width', '15%')
		:css('text-align', 'center')
		:css('font-size', '85%')
	cell:wikitext(args['date'] or '')
	cell:wikitext(isnotempty(args['time']) and '<br>' .. args['time'] or '')
	-- Team 1
	cell = row:tag('td')
		:css('width', '25%')
		:css('text-align', 'right')
		:addClass('vcard attendee')
	cell:tag('span'):addClass('fn org'):wikitext(args['team1'] or '')
	-- Score
	cell = row:tag('td')
		:css('width', '15%')
		:css('text-align', 'center')
	if isnotempty(args['score']) then
		cell:tag('b'):wikitext(args['score'])
	else
		cell:tag('abbr'):attr('title', 'versus'):css('text-decoration', 'none'):wikitext('v')	
	end
	if isnotempty(args['periods']) then
		cell:wikitext('<br>')
		cell:tag('small'):wikitext(args['periods'])
	end
	-- Team 2
	cell = row:tag('td')
		:css('width', '25%')
		:css('text-align', 'left')
		:addClass('vcard attendee')
	cell:tag('span'):addClass('fn org'):wikitext(args['team2'] or '')
	-- Stadium and attendance
	cell = row:tag('td')
		:css('font-size', '85%')
	if isnotempty(args['stadium']) then
		cell:tag('span'):addClass('location'):wikitext(args['stadium'])
	end
	if isnotempty(args['attendance']) then
		cell:wikitext('<br>')
		cell:tag('i'):wikitext('Attendance:')
		cell:wikitext(' ' .. args['attendance'])
	end
	res = res .. tostring(root)

	if isnotempty(args['score']) then
		root = mw.html.create('table')
		root
			:addClass('collapsible collapsed')
			:attr('cellspacing', '0')
			:css('width', '100%')
			:css('background-color', args['bg'] or '#eeeeee')
		cell = root:tag('tr'):tag('th')
		cell:attr('colspan', '5')
			:css('style', 'text-align', 'center')
			:css('font-size', '85%')
		if isnotempty(args['reference']) then
			cell:tag('b'):wikitext('[' .. args['reference'] .. ' Game reference]')
		end
		-- Empty spacing
		row = root:tag('tr'):css('font-size', '85%')
		cell = row:tag('td')
			:attr('rowspan', '7')
			:css('width', '15%')
			:css('vertical-align', 'top')

		-- Goalies
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'right')
			:wikitext(args['goalie1'] or '')
		cell = row:tag('td')
			:css('width', '15%')
			:css('vertical-align', 'top')
			:css('text-align', 'center')
		if isnotempty(args['goalie1']) or isnotempty(args['goalie2']) then
			cell:tag('i'):wikitext('Goalies')
		end
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'left')
			:wikitext(args['goalie2'] or '')

		-- Officials and linesmen
		cell = row:tag('td')
			:attr('rowspan', '7')
			:css('vertical-align', 'top')
		if isnotempty(args['official']) then
			if isnotempty(args['official2']) then
				cell:tag('i'):wikitext('Referees:')
				cell:wikitext('<br>' .. args['official'] .. '<br>' .. args['official2'])
			else
				cell:tag('i'):wikitext('Referee:')
				cell:wikitext('<br>' .. args['official'])
			end
		end
		if isnotempty(args['linesman']) then
			cell:wikitext('<br>')
			if isnotempty(args['linesman2']) then
				cell:tag('i'):wikitext('Linesmen:')
				cell:wikitext('<br>' .. args['linesman'] .. '<br>' .. args['linesman2'])
			else
				cell:tag('i'):wikitext('Linesman:')
				cell:wikitext('<br>' .. args['linesman'])
			end
		end
		-- Goals and progression
		row = root:tag('tr'):css('font-size', '85%')
		cell = row:tag('td')
			:attr('colspan', '3')
			:css('width', '65%')
			:wikitext(
				scoringtable(args['goals1'] or '', 
							args['goals2'] or '',
							args['progression'] or '')
					)
		if isnotempty(args['pnote']) then
			row = root:tag('tr'):css('font-size', '85%')
			row:tag('td')
				:attr('colspan', '3')
				:css('text-align','center')
				:css('width', '65%')
				:wikitext(args['pnote'])
		end
		-- Shoot out
		if isnotempty(args['soshots1']) or isnotempty(args['soshots2']) then
			soshots1 = table.concat(mysplit(args['soshots1'] or ''), '<br>')
			soshots2 = table.concat(mysplit(args['soshots2'] or ''), '<br>')
			row = root:tag('tr'):css('font-size', '85%')
			row:tag('td')
				:css('width', '25%')
				:css('vertical-align', 'top')
				:css('text-align', 'right')
				:wikitext(soshots1 or '')
			row:tag('td')
				:css('width', '15%')
				:css('vertical-align', 'top')
				:css('text-align', 'center')
				:tag('i'):wikitext('[[Overtime (ice hockey)#Shootout|Shootout]]')
			row:tag('td')
				:css('width', '25%')
				:css('vertical-align', 'top')
				:css('text-align', 'left')
				:wikitext(soshots2 or '')
		end
		if isnotempty(args['sonote']) then
			row = root:tag('tr'):css('font-size', '85%')
			row:tag('td')
				:attr('colspan', '3')
				:css('text-align', 'center')
				:css('width', '65%')
				:wikitext(args['sonote'])
		end
		-- Second leg overtime
		if isnotempty(args['otgoals1']) or isnotempty(args['otgoals2']) 
						or isnotempty(args['otprogression']) then
			row = root:tag('tr'):css('font-size', '85%')
			cell = row:tag('td')
				:attr('colspan', '3')
				:css('width', '65%')
				:wikitext(
					scoringtable(args['otgoals1'] or '', 
							args['otgoals2'] or '',
							args['otprogression'] or '')
					)
		end
		if isnotempty(args['otnote']) then
			row = root:tag('tr'):css('font-size', '85%')
			row:tag('td')
				:attr('colspan', '3')
				:css('text-align','center')
				:css('width', '65%')
				:wikitext(args['otnote'])
		end
		-- Penalties
		row = root:tag('tr'):css('font-size', '85%')
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'right')
		if isnotempty(args['penalties1']) then
			cell:tag('i'):wikitext(args['penalties1'] .. ' min')
		end
		cell = row:tag('td')
			:css('width', '15%')
			:css('vertical-align', 'top')
			:css('text-align', 'center')
		if isnotempty(args['penalties1']) or isnotempty(args['penalties2']) then
			cell:tag('i'):wikitext('Penalties')
		end
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'left')
		if isnotempty(args['penalties2']) then
			cell:tag('i'):wikitext(args['penalties2'] .. ' min')
		end
		-- Shots
		row = root:tag('tr'):css('font-size', '85%')
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'right')
		if isnotempty(args['shots1']) then
			cell:tag('i'):wikitext(args['shots1'])
		end
		cell = row:tag('td')
			:css('width', '15%')
			:css('vertical-align', 'top')
			:css('text-align', 'center')
		if isnotempty(args['shots1']) or isnotempty(args['shots2']) then
			cell:tag('i'):wikitext('Shots')
		end
		cell = row:tag('td')
			:css('width', '25%')
			:css('vertical-align', 'top')
			:css('text-align', 'left')
		if isnotempty(args['shots2']) then
			cell:tag('i'):wikitext(args['shots2'])
		end
		res = res .. tostring(root)
	end
	if isnotempty(args['note']) then
		root = mw.html.create('table')
		root
			:attr('cellspacing', '0')
			:css('width', '100%')
			:css('background-color', args['bg'] or '#eeeeee')
		cell = root:tag('tr'):tag('td')
		cell
			:css('text-align', 'left')
			:css('font-size', '100%')
			:tag('i'):wikitext(args['note'])
		res = res .. tostring(root) .. '[[Category:Pages using icehockeybox with the note parameter]]'
	end
	-- tracking
	if (args['sogoals1'] or args['sogoals2']) then
		errorcats = errorcats .. '[[Category:Pages using icehockeybox with improperly formatted progression or goals| ]]'
	end
	-- make errors visible in preview mode
	if errorcats ~= '' then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			errorcats = '<span class="error">' .. errorcats .. '</span>'
		else
			errorcats = '<span style="display:none">' .. errorcats .. '</span>'
		end
	end
	return errorcats .. res
end

return p