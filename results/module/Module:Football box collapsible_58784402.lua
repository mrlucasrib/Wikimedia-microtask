-- Implements [[Template:Football box collapsible]]
local p = {}

local labels = {
	['penalties'] = '[[Penalty shoot-out (association football)|Penalties]]',
	['shootout'] = '[[Penalty shoot-out (association football)#North American experiments|Shootout]]',
	['pen'] = '[[Penalty shoot-out (association football)|p]]',
	['so'] = '[[Penalty shoot-out (association football)|SO]]',
	['aet'] = '[[Overtime (sports)#Association football|a.e.t.]]',
	['agg'] = '[[Playoff format#Total points series (aggregate)|agg.]]',
	['stadium'] = 'Stadium:', 
	['attendance'] = 'Attendance:',
	['referee'] = 'Referee:',
	['assistantreferees'] = 'Assistant referees:',
	['assistantreferee2'] = '<span style="visibility:hidden">Assistant referees:</span>',
	['fourthofficial'] = 'Fourth official:',
	['fifthofficial'] = 'Fifth official:',
	['goallineassistants'] = 'Goal-line assistants:',
	['goallineassistant2'] = '<span style="visibility:hidden">Goal-line assistants:</span>',
	['motm'] = 'Man of the Match:',
	['potm'] = 'Player of the Match:',
	['mvp'] = 'MVP:',
	['note'] = 'Note:',
	['seealso'] = 'See also:'
}
local colors = {
	["W"] = "BBF3BB",
	["L"] = "FFBBBB",
	["T"] = "D" , ["D"] = "FFFFBB",
	["V"] = "P", ["P"] = "BBBBBB"
}

local tracking, preview

local function checkarg(k,v)
	if k and type(k) == 'string' then
		if k == 'id' or k == 'team1' or k == 'team2' or k == 'class' or 
			k == 'nobars' or k == 'size' or 
			k == 'result' or k == 'bg' or k == 'format' or k == 'date' or k == 'scorenote' or
			k == 'round' or k == 'score' or k == 'aet' or k == 'aggregatescore' or 
			k == 'penaltyscore' or k == 'location' or k == 'stadium' or 
			k == 'time' or k == 'goals1' or k == 'report' or k == 'goals2' or 
			k == 'attendance' or k == 'referee' or k == 'assistantreferees' or 
			k == 'assistantreferee2' or k == 'fourthofficial' or 
			k == 'fifthofficial' or k == 'goallineassistants' or 
			k == 'goallineassistant2' or k == 'potm' or k == 'motm' or 
			k == 'mvp' or k == 'penalties1' or k == 'penalties2' or k == 'note' or 
			k == 'shootoutscore' or k == 'shootout1' or k == 'shootout2' or
			k == 'seealso' or k == 'stack'  then
			-- valid and not tracked
		else
			-- invalid
			local vlen = mw.ustring.len(k)
			k = mw.ustring.sub(k, 1, (vlen < 25) and vlen or 25) 
			k = mw.ustring.gsub(k, '[^%w\-_ ]', '?')
			table.insert(tracking, '[[Category:Pages using football box collapsible with unknown parameters|' .. k .. ']]')
			table.insert(preview, '"' .. k .. '"')
		end
	end
end

local function isnotempty(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function trim(s)
	if isnotempty(s) then
		s = s:match('^[\'"%s]*(.-)[\'"%s]*$')
		return isnotempty(s) and s or nil
	end
	return nil
end

local function bold(s)
	if isnotempty(s) then
		return "'''" .. s .. "'''"
	end
	return ""
end

local function italic(s)
	if isnotempty(s) then
		return "''" .. s .. "''"
	end
	return ""
end

local function small(s)
	if isnotempty(s) then
		return '<small>' .. s .. '</small>'
	end
	return ''
end

local function nowrap(s)
	if isnotempty(s) then
		return '<span style="white-space:nowrap">' .. s .. '</span>'
	end
	return ''
end

local function background(frame, c, r, bg)
	local data = colors
	local res = data[r:upper()]
	if res then
		res = '#' .. (data[res] or res)
	elseif isnotempty(bg) then
		res = '#' .. bg
	else
		res = 'transparent'
	end
	return res
end

local function teamname(team)
    local prefix, suffix, b = "", "", "'''";

    if mw.ustring.sub(team,1,3) ~= b and mw.ustring.sub(team,-3) ~= b then
        prefix = b .. '<span class="fn org">';
        suffix = "</span>" .. b;
    else
        if mw.ustring.sub(team,1,3) == b then
            prefix = '<span class="fn org">';
            team = mw.ustring.sub(team,4);
        else
            prefix = '<span class="fn org">' .. b;
        end

        if mw.ustring.sub(team,-3) == b then
            suffix = "</span>";
            team = mw.ustring.sub(team,1,mw.ustring.len(team)-3);
        else
            suffix = b .. "</span>";
        end
    end
        
    return prefix .. team .. suffix;
end

local function score(s, a, ag, p, so)
	s = nowrap(bold(s ~= '' and s or 'v'))
	if a ~= '' then
		s = s .. small(' (' .. labels['aet'] .. ')')
	end
	if ag ~= '' then
		s = s .. '<br>' .. small(' (' .. bold(ag) .. ' ' .. labels['agg'] .. ')')
	end
	if p ~= '' then
		s = s .. '<br>' .. small(' (' .. bold(p) .. ' ' .. labels['pen'] .. ')')
	elseif so ~= '' then
		s = s .. '<br>' .. small(' (' .. bold(so) .. ' ' .. labels['so'] .. ')')
	end
	return s
end
 
local function fmtlist(s)
	s = mw.ustring.gsub(s or '', '%[%[ *([%?-]) *%]%]', '%1')
	s = mw.ustring.gsub(s, '%[%[ *[%?-] *| *(.-) *%]%]', '%1')
	if mw.ustring.sub(s, 1, 1) == '*' then
		return tostring(mw.html.create('div'):addClass('plainlist'):newline():wikitext(s))
	end
	return s
end

local function makelink(s,t)
	if s:match('^http') then
		return '[' .. s .. ' ' .. t .. ']'
	end
	return s
end

function p.main(frame)
	local args = (frame.args['team1'] or frame.args['team2']) and frame.args or frame:getParent().args
	local id = trim(args['id'])
	local bars = (args['nobars'] == nil) or (args['bars'] == '')
	local class = trim(args['class'] or 'mw-collapsible mw-collapsed') or ''
	local width1 = {['1'] = '28%', ['1.1'] = '22%', ['1.2'] = '28%', ['default'] = '19%'}
	local width2 = {['1'] = '19%', ['1.1'] = '25%', ['1.2'] = '19%', ['default'] = '23%'}
	local width3 = {['1'] =  '8%', ['1.1'] =  '8%', ['1.2'] =  '8%', ['default'] = '12%'}
	local width4 = {['1'] = '19%', ['1.1'] = '19%', ['1.2'] = '26%', ['default'] = '23%'}
	local width5 = {['1'] = '26%', ['1.1'] = '26%', ['1.2'] = '19%', ['default'] = '23%'}
	local location = nil
	local extra = {}
	local notes = {}
	
	tracking, preview = {}, {}
    for k, v in pairs(args) do
    	if v ~= '' then
    		checkarg(k,v)
    	end
	end
	
	if args['class'] then
		if args['class'] == 'collapsible' or args['class'] == 'mw-collapsible' or args['class'] == 'uncollapsed' then 
			--valid
		elseif args['class'] == '' then
			table.insert(tracking,'[[Category:Pages using football box collapsible with blank class parameter]]')
		else
			table.insert(tracking,'[[Category:Pages using football box collapsible with class parameter]]')
		end
	end
	
	if isnotempty(args['stack']) then
		table.insert(tracking, '[[Category:Pages using football box collapsible with unsupported stack parameter]]')
	end
	
	-- required parameters
	for i, k in ipairs({'team1', 'team2'}) do
		if args[k] == nil then args[k] = '{{{' .. k .. '}}}' end
	end
	-- vcard for stadium
	if isnotempty(args['stadium']) then
		args['stadium'] = tostring(mw.html.create('span'):addClass('location'):wikitext(args['stadium']))
	end

	-- placement of stadium and location information
	if isnotempty(args['location']) then
		location = args['location']
		if isnotempty(args['stadium']) then
			table.insert(extra, labels['stadium'] .. ' ' .. args['stadium'])
		end
	elseif isnotempty(args['stadium']) then
		location = args['stadium']
	end

	-- remaining extra information
	for i, k in ipairs({'attendance', 'referee', 'assistantreferees', 
		'assistantreferee2', 'fourthofficial', 'fifthofficial', 
		'goallineassistants', 'goallineassistant2', 'potm', 'motm', 'mvp'}) do
		if isnotempty(args[k]) then
			table.insert(extra, labels[k] .. ' ' .. args[k])
		end
	end
	
	-- score
	local scorestr = ''
	if args['score1'] or args['score2'] then
		scorestr = (args['score1'] or '0') .. '&ndash;' .. (args['score2'] or '0')
	elseif args['score'] then
		scorestr = args['score']
	end
	if args['scorenote'] then
		scorestr = scorestr .. '<br>' .. args['scorenote']
	end
	
	-- notes
	if isnotempty(args['note']) then
		table.insert(notes, "''" .. labels['note'] .. " " .. args['note'] .. "''")
	end
	if isnotempty(args['seealso']) then
		table.insert(notes, "''" .. labels['seealso'] .. " " .. args['seealso'] .. "''")
	end

	-- check if this is a one row table
	if class == '' or class == 'uncollapsed' then
		class = ''
	elseif #extra > 0 or #notes > 0 or isnotempty(args['time']) or isnotempty(args['report']) or 
		isnotempty(args['goals1']) or isnotempty(args['goals2']) or
		isnotempty(args['penalties1']) or isnotempty(args['penalties2']) or
		isnotempty(args['shootout1']) or isnotempty(args['shootout2']) then
	elseif class == 'collapsible collapsed' or class == 'mw-collapsible mw-collapsed' then
		class = ''
	end
	
	-- Start box
	local root = 
		mw.html.create('div')
			:addClass('vevent')
			:attr('id', id)
	root:tag('span')
		:addClass('summary')
		:css('display', 'none')
		:wikitext(args['team1'] .. ' v ' .. args['team2'])
	root:newline()
	
	-- Start table
	local rtable = root:tag('table')
		:attr('cellspacing', 0)
		:addClass(class ~= '' and class or nil)
		:addClass('vevent')
		:css('border-top', bars and '1px solid #999' or nil)
		:css('border-bottom', bars and '1px solid #999' or nil)
		:css('margin-bottom', bars and '-1px' or nil)
		:css('width', args['size'] or '100%')
		:css('background', background(frame, 'default', args['result'] or '', args['bg'] or ''))

	local row = rtable:tag('tr'):css('vertical-align', 'top')
	-- date and round
	local cell = row:tag('td')
		:css('width', width1[args['format'] or 'default'] or width1['default'])
	if isnotempty(args['date']) then
		cell:tag('span')
			:css('white-space', 'nowrap')
			:css('float', 'right')
			:css('margin-left', '0.5em')
			:wikitext(args['date'])
		cell:wikitext(' ')
	end
	if isnotempty(args['round']) then
		cell:wikitext(small(args['round']))
	end
	-- team1
	row:tag('td')
		:css('width', width2[args['format'] or 'default'] or width2['default'])
		:css('text-align', 'right')
		:addClass('vcard attendee')
		:wikitext(teamname(args['team1']))
	-- score
	row:tag('td')
		:css('width', width3[args['format'] or 'default'] or width3['default'])
		:css('text-align', 'center')
		:wikitext(score(scorestr, args['aet'] or '', args['aggregatescore'] or '', args['penaltyscore'] or '', args['shootoutscore'] or ''))
	-- team2
	row:tag('td')
		:css('width', width4[args['format'] or 'default'] or width4['default'])
		:addClass('vcard attendee')
		:wikitext(teamname(args['team2']))
	-- location, stadium
	row:tag('td')
		:css('width', location and (width5[args['format'] or 'default'] or width5['default']) or nil)
		:css('font-size', '85%')
		:wikitext(location)

	if #extra > 0 or isnotempty(args['time']) or isnotempty(args['report']) or 
		isnotempty(args['goals1']) or isnotempty(args['goals2']) then
		local row = rtable:tag('tr'):css('vertical-align','top'):css('font-size','85%')
		-- time
		row:tag('td')
			:css('text-align', isnotempty(args['time']) and 'right' or nil)
			:wikitext(args['time'])
		row:newline()	
		-- goals1
		row:tag('td')
			:css('text-align', isnotempty(args['goals1']) and 'right' or nil)
			:wikitext(fmtlist(args['goals1']))	
		row:newline()
		-- report
		row:tag('td')
			:css('text-align', isnotempty(args['report']) and 'center' or nil)
			:wikitext(makelink(args['report'] or '', 'Report'))
		row:newline()
		-- goals2
		row:tag('td')
			:wikitext(fmtlist(args['goals2']))
		row:newline()
		-- location, stadium
		row:tag('td')
			:wikitext(table.concat(extra, '<br>'))
	end

	if isnotempty(args['penalties1']) or isnotempty(args['penalties2']) then
		row = rtable:tag('tr')
		row:tag('td'):attr('rowspan', 2)
		row:tag('td'):attr('colspan', 3):css('text-align', 'center'):wikitext(bold(labels['penalties']))
		row:tag('td'):attr('rowspan', 2)
		row = rtable:tag('tr'):css('vertical-align','top'):css('font-size','85%')
		row:newline()
		row:tag('td')
			:css('text-align', isnotempty(args['penalties1']) and 'right' or nil)
			:wikitext(fmtlist(args['penalties1']))
		row:newline()
		row:tag('td')
		row:newline()
		row:tag('td')
			:wikitext(fmtlist(args['penalties2']))
		row:newline()
	elseif isnotempty(args['shootout1']) or isnotempty(args['shootout2']) then
		row = rtable:tag('tr')
		row:tag('td'):attr('rowspan', 2)
		row:tag('td'):attr('colspan', 3):css('text-align', 'center'):wikitext(bold(labels['shootout']))
		row:tag('td'):attr('rowspan', 2)
		row = rtable:tag('tr'):css('vertical-align','top'):css('font-size','85%')
		row:newline()
		row:tag('td')
			:css('text-align', isnotempty(args['shootout1']) and 'right' or nil)
			:wikitext(fmtlist(args['shootout1']))
		row:newline()
		row:tag('td')
		row:newline()
		row:tag('td')
			:wikitext(fmtlist(args['shootout2']))
		row:newline()
	end
	
	if #notes > 0 then
		row = rtable:tag('tr'):css('font-size', '85%')
		row:tag('td')
			:attr('colspan', 5)
			:wikitext(table.concat(notes, '<br>'))
		row:newline()
	end
	
	local trackstr = (#tracking > 0) and table.concat(tracking, '') or ''
	if #preview > 0 and frame:preprocess( "{{REVISIONID}}" ) == "" then
		trackstr = tostring(mw.html.create('div')
			:addClass('hatnote')
			:css('color','red')
			:tag('strong'):wikitext('Warning:'):done()
			:wikitext('Unknown parameters: ' .. table.concat(preview, '; ')))
	end
	
	return tostring(root) .. trackstr
end

return p