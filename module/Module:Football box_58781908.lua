-- Implements [[Template:Football box]]
local p = {}
local lang = nil
local delink = require('Module:Delink')._delink
local eventschema = "http://schema.org/SportsEvent"
local teamschema = "http://schema.org/SportsTeam"
local placeschema = "http://schema.org/Place"
local penalties = '[[Penalty shoot-out (association football)|Penalties]]'
local aet = '[[Overtime (sports)#Association football|a.e.t.]]'
local asdet = '[[Sudden death (sport)#Association football|a.s.d.e.t.]]'
local agget = '[[Overtime (sports)#Association football|a.e.t.]]/[[Golden goal#Association football|g.g.]]'
local asget = '[[Overtime (sports)#Association football|a.e.t.]]/[[Golden goal#Silver goal|s.g.]]'
local attendance = 'Attendance:'
local referee = 'Referee:'
local templatestyles = 'Football box/styles.css'

local tracking, preview

local function checkarg(k,v)
	if k and type(k) == 'string' then
		if  k == 'assistantreferees2' then
			table.insert(tracking, '[[Category:Pages using football box with assistantreferees|2]]')
		elseif k == 'aggregatescore' or k == 'assistantreferees' or 
				k == 'fourthofficial' or k == 'game' or k == 'motm' or 
				k == 'nobars' or k == 'note' or k == 'result' then
			-- valid and tracked
			table.insert(tracking, '[[Category:Pages using football box with ' .. k .. ']]')
		elseif k == 'size' or k == 'bg' or k == 'id' or k == 'event' or 
			k == 'date' or k == 'time' or k == 'round' or k == 'team1' or 
			k == 'team2' or k == 'score1' or k == 'score2' or k == 'score' or k == 'scorenote' or
			k == 'aet' or k == 'asdet' or k == 'agget' or k == 'asget' or k == 'goals1' or k == 'report' or k == 'goals2' or 
			k == 'penaltyscore' or k == 'penalties1' or k == 'penalties2' or 
			k == 'stadium' or k == 'location' or k == 'attendance' or 
			k == 'referee' or k == 'stack'  then
			-- valid and not tracked
		else
			-- invalid
			local vlen = mw.ustring.len(k)
			k = mw.ustring.sub(k, 1, (vlen < 25) and vlen or 25) 
			k = mw.ustring.gsub(k, '[^%w\-_ ]', '?')
			table.insert(tracking, '[[Category:Pages using football box with unknown parameters|' .. k .. ']]')
			table.insert(preview, '"' .. k .. '"')
		end
	end
end

local function timestamp(d, t)
	if d then
		lang = lang or mw.language.getContentLanguage() -- lazy initialize
		local success, timestamp = pcall(lang.formatDate, lang, 'c', delink({d .. ' ' .. (t or '')}))
		if success then
			return timestamp
		else
			return nil
		end
	end
	return nil
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

local function trim(s)
	return s:match('^[\'"%s]*(.-)[\'"%s]*$')
end

local function getid(s)
	s = trim(s or '')
	if s and s ~= '' then
		return s
	end
	return nil
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame)
	local id = getid(args['id'])
	local d = timestamp(args['date'], args['time'])
	local block
	
	tracking, preview = {}, {}
    for k, v in pairs(args) do
    	if v ~= '' then
    		checkarg(k,v)
    	end
	end

	local score = 'v'
	if args['score1'] or args['score2'] then
		score = (args['score1'] or '0') .. '&ndash;' .. (args['score2'] or '0')
	elseif args['score'] and args['score'] ~= '' then
		score = args['score']
	end
	if args['aet'] then
		score = score .. ' (' .. aet .. ')'
	elseif args['asdet'] then
		score = score .. ' (' .. asdet .. ')'
	elseif args['agget'] then
		score = score .. ' (' .. agget .. ')'
	elseif args['asget'] then
		score = score .. ' (' .. asget .. ')'
	end
	if args['scorenote'] then
		score = score .. '<br>' .. args['scorenote']
	end
	
	-- Start box
	local root = 
		mw.html.create('div')
			:attr('itemscope', '')
			:attr('itemtype', eventschema)
			:addClass('footballbox')
			:css('width', args['size'])
			:css('background-color', args['bg'])
			:attr('id', id)
	root:newline()
	
	if args['event'] then
		root:tag('div')
			:addClass('ftitle')
			:wikitext(args['event'])
	end
	
	-- Start left block
	block = root:tag('div')
		:addClass('mobile-float-reset')
		:addClass('fleft')
	
	local timetag = block:tag('time')
		:attr('itemprop', d and 'startDate' or nil)
		:attr('datetime', d)
		
	timetag:tag('div')
		:addClass('mobile-float-reset')
		:addClass('fdate')
		:wikitext(args['date'])
	
	if args['time'] then
		timetag:tag('div')
			:addClass('mobile-float-reset')
			:addClass('ftime')
			:wikitext(args['time'])
	end
	
	if args['round'] then
		block:tag('div')
			:addClass('mobile-float-reset')
			:addClass('frnd')
			:wikitext(args['round'])
	end
	-- End block
	
	-- Start table
	local rtable = root:tag('table')
		:addClass('fevent')
	local row = rtable:tag('tr')
		:attr('itemprop', 'name')
	row:newline()
	row:tag('th')
		:addClass('fhome')
		:attr('itemprop', 'homeTeam')
		:attr('itemscope', '')
		:attr('itemtype', teamschema)
		:tag('span')
			:attr('itemprop', 'name')
			:wikitext(args['team1'])
	row:tag('th')
		:addClass('fscore')
		:wikitext(score)
	row:tag('th')
		:addClass('faway')
		:attr('itemprop', 'awayTeam')
		:attr('itemscope', '')
		:attr('itemtype', teamschema)
		:tag('span')
			:attr('itemprop', 'name')
			:wikitext(args['team2'])

	row = rtable:tag('tr')
		:addClass('fgoals')
		:newline()
	row:tag('td')
		:addClass('fhgoal')
		:wikitext(fmtlist(args['goals1']))
	row:newline()
	row:tag('td')
		:wikitext(makelink(args['report'] or '', 'Report'))
	row:newline()
	row:tag('td')
		:addClass('fagoal')
		:wikitext(fmtlist(args['goals2']))
	row:newline()	
	
	if args['penaltyscore'] then
		rtable
			:tag('tr')
				:tag('th')
					:attr('colspan', 3)
					:wikitext(penalties)
		row = rtable:tag('tr')
			:addClass('fgoals')
		row:newline()
		row:tag('td')
			:addClass('fhgoal')
			:wikitext(fmtlist(args['penalties1']))
		row:newline()
		row:tag('th')
			:wikitext(args['penaltyscore'])
		row:newline()
		row:tag('td')
			:addClass('fagoal')
			:wikitext(fmtlist(args['penalties2']))
		row:newline()
	end
	-- End table
	
	-- Start right block
	block = root:tag('div')
		:addClass('mobile-float-reset')
		:addClass('fright')
	
	if args['stadium'] then
		local sdiv = block:tag('div')
			:attr('itemprop', 'location')
			:attr('itemscope', '')
			:attr('itemtype', placeschema)
		if args['location'] then
			sdiv:tag('span')
				:attr('itemprop', 'name')
				:wikitext(args['stadium'])
			sdiv:wikitext(', ')
			sdiv:tag('span')
				:attr('itemprop', 'address')
				:wikitext(args['location'])
		else
			sdiv:tag('span')
				:attr('itemprop', 'name address')
				:wikitext(args['stadium'])
		end
	end
	
	if args['attendance'] then
		block:tag('div'):wikitext(attendance ..' ' .. args['attendance'])
	end
	if args['referee'] then
		block:tag('div'):wikitext(referee .. ' ' .. args['referee'])
	end

	local trackstr = (#tracking > 0) and table.concat(tracking, '') or ''
	if #preview > 0 and frame:preprocess( "{{REVISIONID}}" ) == "" then
		trackstr = tostring(mw.html.create('div')
			:addClass('hatnote')
			:css('color','red')
			:tag('strong'):wikitext('Warning:'):done()
			:wikitext('Unknown parameters: ' .. table.concat(preview, '; ')))
	end
	
	return frame:extensionTag{ name = 'templatestyles', args = { src = templatestyles} } .. tostring(root) .. trackstr
end

return p