-- This module implements {{CFB schedule}}
local p = {}

local dagger = '<sup class="CFB-schedule-hcgame">[[File:Dagger-14-plain.png|alt=dagger|link=]]</sup>'

local haslocgamename = false
local hasoppgamename = false
local haslocrivalry = false
local hasopprivalry = false
local hasrank = false
local hasstrangescore = false
local hasnowrap = false

local function isnotempty(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function yesno(s, d)
	s = (s or ''):lower()
	if (s == 'no' or s == 'n') then
		return false
	elseif (s == 'yes' or s == 'y') then
		return true
	else
		return d
	end
end

local function ifexist(page)
	if not page then return false end
	if mw.title.new(page).exists then return true end
	return false
end

local function getdivision(y)
	if y >= 2006 then
		return 'NCAA Division I FBS'
	elseif y >= 1978 then
		return 'NCAA Division I-A'
	elseif y >= 1973 then
		return 'NCAA Division I'
	elseif y >= 1956 then
		return 'NCAA University Division'
	elseif y >= 1910 then
		return 'NCAA'
	elseif y >= 1906 then
		return 'Intercollegiate Athletic Association of the United States'
	else
		return 'college'
	end

	return ''
end

local function getpolltext(y, d, p)
	-- default poll is the Coaches poll
	if (p or '') == '' then
		p = 'Coaches\''
	end

	-- if p is linked then just return p
	if (p or ''):find('[%[%]]') then
		return p
	end

	-- else if y is a number
	if isnotempty(y) and tonumber(y) then
		if (d or '') == '' then
			d = getdivision(tonumber(y))
		end

		return '[[' .. y .. ' ' .. d .. ' football rankings'
					.. '#' .. p .. ' Poll|' .. p .. ' Poll]]'
					.. ' released prior to the game'
	end

	-- else if d is not empty
	if isnotempty(d) then
		d = d .. ' '

		if ifexist(d .. p .. ' Poll') then
			return '[[' .. d .. p .. ' Poll|' .. p .. ' Poll]]'
				.. ' released prior to the game'
		end
	end

	-- else if p Poll is an article
	if ifexist(p .. ' Poll') then
		return (d or '') .. '[[' .. p .. ' Poll]]'
			.. ' released prior to the game'
	end

	return (d or '') .. p .. ' poll released prior to the game'
end

local function getopp(s, atvs, movegn)
	s = mw.ustring.gsub(s, '<[%s/]*[Nn][Cc][Gg][%s/]*>', '<span class="CFB-schedule-ncgame">*</span>')
	s = mw.ustring.gsub(s, '<[%s/]*[Hh][Cc][%s/]*>', dagger)
	atvs = mw.ustring.gsub(atvs or '', '^%s*@%s*', 'at')
	atvs = mw.ustring.gsub(atvs or '', '^%s*[Vv][Ss]?[%.%s]*', 'vs.')
	s = mw.ustring.gsub(s, '^([A-Za-z%.%s]*)[Nn][Oo][%.%s]*([0-9])', '%1 No.&nbsp;%2' )
	s = mw.ustring.gsub(s, '^([A-Za-z%.%s]*)#([0-9])', '%1 No.&nbsp;%2')
	if mw.ustring.match(s, 'No%.&nbsp;%d') then hasrank=true end
	local gn, r = '', ''
	if mw.ustring.match(s, '[Nn][Oo][Ww][Rr][Aa][Pp]') then
		hasnowrap = true
	end
	if mw.ustring.match(s, '[Nn][Bb][Ss][Pp]') then
		hasnowrap = true
	end
	if mw.ustring.match(s, '^.*%s*%(%s*%[%[[^%[%]]*%]%]%s*%)%s*.*$') then
		if mw.ustring.match(s, '%(%[%[[^%[%]]*%|%s*[Rr]ivalry') then
			hasopprivalry = true
		else
			hasoppgamename = true
		end
		if movegn == true then
			s, gn, r = mw.ustring.match(s, '^(.*)%s*%(%s*(%[%[[^%[%]]*%]%])%s*%)(%s*.*)$')
		end
	end
	if atvs ~= '' then atvs = atvs .. ' ' end
	return atvs .. s .. r, gn
end

local function getrank(s)
	s = mw.ustring.gsub(s, '^%s*([%d][%d]*)', 'No.&nbsp;%1')
	return s
end

local function getsite(s, l, gn)
	if isnotempty(s) and isnotempty(l) then
		local r = mw.html.create('div')
		local u = r:addClass('hlist'):tag('ul')
		gn = mw.ustring.gsub(gn, '^%s*', '')
		if isnotempty(gn) then
			gn = ' (' .. gn .. ')'
		end
		u:tag('li'):wikitext(s)
		u:tag('li'):wikitext(l .. gn)
		if mw.ustring.match(l, '%s%(%[%[') then
			if mw.ustring.match(l, '%s%(%[%[[^%]]*%|%s*[Rr]ivalry') then
				haslocrivalry = true
			else
				haslocgamename = true
			end
		end
		return tostring(r)
	else
		gn = mw.ustring.gsub(gn, '^%s*', '')
		if isnotempty(gn) then
			gn = ' (' .. gn .. ')'
		end
		return s .. l .. gn
	end
end

local function setbg(WL,N)
	local BG = 'inherit'
	WL = mw.ustring.gsub(WL, '^%s*(.-)%s*$', '%1')
	WL = WL:upper()
	if WL == 'W' then
		BG = '#DDFFDD'
	elseif WL == 'L' then
		BG = '#FFDDDD'
	elseif WL == 'T' then
		BG = '#FFFFE6'
	elseif WL == 'V' then
		BG = '#F0E8E8'
		WL = 'W'
		N = N .. ' (vacated)'
	end
	return BG, WL, N
end

local function parse4(p, s)
	local t = {'', '', '', ''}
	for k = 1,4 do
		t[k] = mw.ustring.gsub(s, p, '%' .. k)
	end
	local wl, sc, n, bg = t[1], t[2] .. '–' .. t[3], t[4], 'inherit'
	bg, wl, n = setbg(wl, n)
	return '<span style="display:inline-block; font-weight:bold; width:1em">' .. wl .. '</span> ' .. sc .. n, bg
end
	
local function getresult(wl, s, n)
	local bg = 'inherit'

	local loopnum = 0
	while (mw.ustring.match(s, '&[Nn][Bb][Ss][Pp];') and loopnum < 5) do
		hasstrangescore = true
		s = mw.ustring.gsub(s, '&[Nn][Bb][Ss][Pp];', ' ')
		s = mw.ustring.gsub(s, '<%s*[Ss][Pp][Aa][Nn][^<>]*>%s*</[Ss][Pp][Aa][Nn]%s*>', ' ')
		loopnum = loopnum + 1
	end
	s = mw.ustring.gsub(s, '&[Nn][Bb][Ss][Pp];%s*(<[%s/]*[0-9]*OT[%s/]*>)', ' %1')
	s = mw.ustring.gsub(s, '%s*<([0-9]*)[Oo][Tt]>', ' <sup>%1OT</sup>')
	s = mw.ustring.gsub(s, '&[MmNn][Dd][Aa][Ss][Hh];', '–')
	s = mw.ustring.gsub(s, '<span class="url">(.-)</span>', '%1')
	s = mw.ustring.gsub(s, '^%s*(.-)%s*$', '%1')

	if wl ~= '' then
		s = mw.ustring.gsub(s, '^%s*([%d][%d]*)%s*[%‐‒–—―]%s*', '%1–')
		s = mw.ustring.gsub(s, '^%s*(%[%[%s*[^|]*|%s*[%d][%d]*)%s*[%‐‒–—―]%s*', '%1–')
		s = mw.ustring.gsub(s, '^%s*(%[[^|%[%]%s]*%s+[%d][%d]*)%s*[%‐‒–—―]%s*', '%1–')
		local r
		if mw.ustring.match(wl, '^%s*[%a]?%s*$') then
			bg, wl, n = setbg(wl, n)
			r = '<span style="display:inline-block; font-weight:bold; width:1em">' 
				.. wl .. '</span> ' .. s .. n
		else
			hasstrangescore = true
			r = wl .. s .. n
		end
		return r,bg
	end
	
	if s == 'Cancelled' or s == '' or s == '?' then
		return wl .. s .. n, 'inherit'
	end
	
	if mw.ustring.match(s, '^[%a]%s+[^%d].*$') then
		wl = mw.ustring.gsub(s, '^([%a])%s+(.-)$', '%1')
		s = mw.ustring.gsub(s, '^([%a])%s+(.-)$', '%2')
		bg, wl, n = setbg(wl, n)
		local r = '<span style="display:inline-block; font-weight:bold; width:1em">'
			.. wl .. '</span> ' .. s .. n
		return r,bg
	end
	
	if mw.ustring.match(s, '^[%a]$') then
		bg, wl, n = setbg(s, n)
		local r = '<span style="display:inline-block; font-weight:bold; width:1em">'
			.. wl .. '</span> ' .. n
		return r, bg
	end

	local pat
	pat = '^([%a])%s*([%d][%d]*)[%D]%s*([%d][%d]*)(.-)$'
	if mw.ustring.match(s, pat) then
		return parse4(pat, s)
	end

	pat = '^([%a])%s*(%[%[%s*[^|]*|%s*[%d][%d]*)[%D]%s*([%d][%d]*%]%])(.-)$'
	if mw.ustring.match(s, pat) then
		return parse4(pat, s)
	end
	
	pat = '^([%a])%s*(%[[^|%[%]%s]*%s+[%d][%d]*)[%D]%s*([%d][%d]*%s*%])(.-)$'
	if mw.ustring.match(s, pat) then
		return parse4(pat, s)
	end
	
	hasstrangescore = true

	return wl .. s .. n, 'inherit'
end

local function getfootnotes(ncg, hc, oe, rank, opprank, poll, tz, src)
	-- footnotes
	local fn = {}
	if ncg then
		table.insert(fn,'*Non-conference game')
	end
	if hc then
		table.insert(fn, dagger .. 'Homecoming')
	end
	if isnotempty(oe)  then
		table.insert(fn, oe)
	end
	if (rank == true) or (opprank == true) then
		table.insert(fn, 'Rankings from ' .. poll)
	end
	if isnotempty(tz) then
		table.insert(fn,'All times are in [[' .. tz .. ' Time Zone|' .. tz .. ' time]]')
	end
	if isnotempty(src) then
		table.insert(fn, 'Source: ' .. src)
	end

	if (#fn > 0) then
		local res = mw.html.create('div')
				:addClass('hlist')
				:tag('ul')
					:wikitext('<li>' .. table.concat(fn,'</li><li>') .. '</li>')
					:done()
		return tostring(res)
	else
		return nil
	end
end

local function make_outer_table(args)
	local showdate   = yesno(args['date'], false)
	local showtime   = yesno(args['time'], false)
	local showrank   = yesno(args['rank'], false)
	local showtv     = yesno(args['tv'], false)
	local showattend = yesno(args['attend'], false)
	local showsource = yesno(args['source'], false)
	local ncg, hc = false, false
	local row

	-- Step 1: Inspect the rows to determine which headers are active
	local k = 1
	while args[k] ~= nil do
		if showdate == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-date[^>]*>%s*[^%s<]') then
				showdate = true
			end
		end
		if showtime == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-time[^>]*>%s*[^%s<]') then
				showtime = true
			end
		end
		if showrank == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-rank[^>]*>%s*[^%s<]') then
				showrank = true
			end
		end
		if showtv == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-tv[^>]*>%s*[^%s<]') then
				showtv = true
			end
		end
		if showattend == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-attend[^>]*>%s*[^%s<]') then
				showattend = true
			end
		end
		if showsource == false then
			if args[k]:find('<td[^>]*CFB%-schedule%-source[^>]*>%s*[^%s<]') then
				showsource = true
			end
		end
		if ncg == false then
			if args[k]:find('<s[pu][ap][^>]*CFB%-schedule%-ncgame') then
				ncg = true
			end
		end
		if hc == false then
			if args[k]:find('<s[pu][ap][^>]*CFB%-schedule%-hcgame') then
				hc = true
			end
		end
		if hasrank == false then
			if showrank == true or args[k]:find('No%.&nbsp;%d') then
				hasrank = true
			end
		end
		k = k + 1
	end
	if k == 1 then
		return '[[Category:Pages using CFB schedule with no content]]'
	end
	
	-- Step 2: Build the table
	local root = mw.html.create('table')
	root:addClass('wikitable')
		:css('font-size', '95%')

	-- optional caption
	if args['caption'] then
		root:tag('caption'):wikitext(args['caption'])
	end
	
	-- add the headers
	local cols = 3
	row = root:tag('tr')
	if showdate then
		row:tag('th'):wikitext('Date')
		cols = cols + 1
	end
	if showtime then
		row:tag('th'):wikitext('Time')
		cols = cols + 1
	end
	row:tag('th'):wikitext('Opponent')
	if showrank then
		row:tag('th'):wikitext('Rank')
		cols = cols + 1
	end
	row:tag('th'):wikitext('Site')
	if showtv then
		row:tag('th'):wikitext('TV')
		cols = cols + 1
	end
	row:tag('th'):wikitext('Result')
	if showattend then
		row:tag('th'):wikitext('Attendance')
		cols = cols + 1
	end
	if showsource then
		row:tag('th'):wikitext('Source')
		cols = cols + 1
	end

	k = 1
	while args[k] ~= nil do
		row = args[k] or ''
		if showdate then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-date[^>]*>', '<td style="white-space:nowrap">')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-date[^>]*>%s*</td>%s*', '')
		end
		if showtime then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-time[^>]*>', '<td style="white-space:nowrap">')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-time[^>]*>%s*</td>%s*', '')
		end
		if showrank then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-rank[^>]*>', '<td style="white-space:nowrap">')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-rank[^>]*>%s*</td>%s*', '')
		end
		if showtv then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-tv[^>]*>', '<td>')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-tv[^>]*>%s*</td>%s*', '')
		end
		if showattend then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-attend[^>]*>', '<td style="text-align:center">')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-attend[^>]*>%s*</td>%s*', '')
		end
		if showsource then
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-source[^>]*>', '<td style="text-align:center">')
		else
			row = mw.ustring.gsub(row, '<td[^>]*CFB%-schedule%-source[^>]*>%s*</td>%s*', '')
		end
		root:wikitext(row)
		k = k + 1
	end

	-- footnotes
	local fnotes = getfootnotes(
		ncg,
		hc,
		args['other-event'] or args['other_event'] or args['otherevent'],
		showrank,
		yesno(args['opprank'], hasrank),
		getpolltext(
			args['rank_year'] or args['rankyear'],
			args['rank_division'] or args['rankdivision'],
			args['poll']
		),
		showtime and args['timezone'] or '',
		args['seasonsource']
	)

	if fnotes ~= nil then
		root:tag('tr')
				:tag('td')
				:attr('colspan',cols)
				:css('font-size', '85%')
				:wikitext(fnotes)
	end
	return tostring(root)
end

local function convert_table(args)
	local function splitresult(s)
		local wl = ''
		s = mw.ustring.gsub(s or '', '&[MmNn][Dd][Aa][Ss][Hh];', '–')
		s = mw.ustring.gsub(s, '^%s*(.-)%s*$', '%1')
		local r = ''
		if mw.ustring.match(s, '^[%a]%s*[%d][%d]*[%D]%s*[%d][%d]*%s*.*$') then
			local t = {'', '', '', ''}
			for k = 1,4 do
				t[k] = mw.ustring.gsub(s,'^([%a])%s*([%d][%d]*)[%D]%s*([%d][%d]*)%s*(.*)$', '%' .. k)
			end
			local wl, s1, s2, n = t[1], t[2], t[3], t[4]
			wl = wl:lower()
			return wl, s1 .. '–' .. s2 .. n
		end
		return '', s
	end
	local res = '{{CFB schedule\n'
	res = res .. (yesno(args['opprank'], false) == false and '' or '| opprank = y\n')
	res = res .. (isnotempty(args['other-event'])
			and '| other-event = ' .. args['other-event'] .. '\n' or '')
	res = res .. (isnotempty(args['rankyear'])
			and '| rankyear = ' .. args['rankyear'] .. '\n' or '')
	res = res .. (isnotempty(args['rankdivision'])
			and '| rankdivision = ' .. args['rankdivision'] .. '\n' or '')
	res = res .. (isnotempty(args['poll'])
		and '| poll = ' .. args['poll'] .. '\n' or '')
	res = res .. (isnotempty(args['timezone'])
		and '| timezone = ' .. args['timezone'] .. '\n' or '')

	-- switch headers on and off
	local headers = {'Date', 'Time', 'At/Vs', 'Opponent', 'Rank', 'Site', 'Location', 'TV', 'Result', 'Attendance', 'Source'}
	local resultoffset = 8

	for k = #headers,1,-1 do
		if headers[k] == 'Time' and (yesno(args['time'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'At/Vs' and (yesno(args['atvs'], true) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'Rank' and (yesno(args['rank'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'TV' and (yesno(args['tv'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'Attendance' and (yesno(args['attend'], false) == false) then
			table.remove(headers,k)
		elseif headers[k] == 'Source' and (yesno(args['source'], false) == false) then
			table.remove(headers,k)
		end
	end

	-- parse the table
	local k = 1
	local stopflag = (args[k] == nil) and true or false
	while stopflag == false do
		res = res .. '|{{CFB schedule entry\n'
		for j = 1,#headers do
			if headers[j] == 'Date' then
				res = res .. '| date = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			elseif headers[j] == 'Time' then
				res = res .. '| time = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			elseif headers[j] == 'At/Vs' then
				local atvs = mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1')
				atvs = mw.ustring.gsub(atvs, '^@', 'at')
				atvs = mw.ustring.gsub(atvs, '^[Vv][Ss]?[%.%s]*', 'vs.')
				if mw.ustring.find(atvs, '^at') then
					res = res .. '| away = y\n'
				elseif mw.ustring.find(atvs, '^vs') then
					res = res .. '| neutral = y\n'
				elseif atvs ~= '' then
					res = res .. '| atvs = ~' .. atvs .. '~\n'
				end
			elseif headers[j] == 'Opponent' then
				local opp = mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1')
				if mw.ustring.find(opp, '%s*<[%s/]*[Nn][Cc][Gg][%s/]*>%s*') then
					opp = mw.ustring.gsub(opp, '%s*<[%s/]*[Nn][Cc][Gg][%s/]*>%s*', ' ')
					res = res .. '| nonconf = y\n'
				end
				if mw.ustring.find(opp, '%s*<[%s/]*[Hh][Cc][%s/]*>%s*') then
					opp = mw.ustring.gsub(opp, '%s*<[%s/]*[Hh][Cc][%s/]*>%s*', ' ')
					res = res .. '| homecoming = y\n'
				end
				opp = mw.ustring.gsub(opp, '^%s*(.-)%s*$', '%1')
				opp = mw.ustring.gsub(opp, '^[Nn][Oo][%.%s]*([0-9])', '#%1' )
				if mw.ustring.find(opp, '^#([0-9]+)%s*') then
					local orank = mw.ustring.gsub(opp, '^#([0-9]+)%s*(.-)$', '%1' )
					opp = mw.ustring.gsub(opp, '^#([0-9]+)%s*(.-)$', '%2' )
					res = res .. '| opprank = ' .. orank .. '\n'
				end
				if mw.ustring.find(opp, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$') then
					local rgame = mw.ustring.gsub(opp, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$', '%2')
					opp = mw.ustring.gsub(opp, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$', '%1')
					res = res .. '| gamename = ' .. rgame .. '\n'
				end
				res = res .. '| opponent = ' .. opp .. '\n'
			elseif headers[j] == 'Rank' then
				local mrank = mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1')
				mrank = mw.ustring.gsub(mrank, '^[Nn][Oo][%.%s]*([0-9])', '%1' )
				mrank = mw.ustring.gsub(mrank, '^#[%.%s]*([0-9])', '%1' )
				res = res .. '| rank = ' .. mrank .. '\n'
			elseif headers[j] == 'Site' then
				res = res .. '| stadium = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			elseif headers[j] == 'Location' then
				local loc = mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1')
				local rname = ''
				if mw.ustring.find(loc, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$') then
					rgame = mw.ustring.gsub(loc, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$', '%2')
					rname = rname .. '| gamename = ' .. rgame .. '\n'
					loc = mw.ustring.gsub(loc, '^(.-)%s*%((%[%[[^%[%]]*%]%])%)%s*$', '%1')
				end
				res = res .. '| cityst = ' .. loc .. '\n'
				res = res .. rname
			elseif headers[j] == 'TV' then
				res = res .. '| tv = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			elseif headers[j] == 'Result' then
				local wl, score = splitresult(args[k] or '')
				res = res .. '| w/l = ' .. wl .. '\n'
				res = res .. '| score = ' .. score .. '\n'
			elseif headers[j] == 'Attendance' then
				res = res .. '| attend = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			elseif headers[j] == 'Source' then
				res = res .. '| source = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			else
				res = res .. '| ?? = ' .. mw.ustring.gsub(args[k] or '', '^%s*(.-)%s*$', '%1') .. '\n'
			end
			k = k + 1
			stopflag = (args[k] == nil) and true or false
		end
		res = res .. '}}\n'
	end
	res = res .. '}}'

	return res
end

local function make_table(args)
	local hasgamename = true

	-- switch headers on and off
	local headers = {'Date', 'Time', 'At/Vs', 'Opponent', 'Rank', 'Site', 'Location', 'Game name', 'TV', 'Result', 'Attendance', 'Source'}
	local resultoffset = 9

	local ncg, hc = false, false

	for k = #headers,1,-1 do
		if headers[k] == 'Time' and (yesno(args['time'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'At/Vs' and (yesno(args['atvs'], true) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'Rank' and (yesno(args['rank'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'Game name' and (yesno(args['gamename'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
			hasgamename = false
		elseif headers[k] == 'TV' and (yesno(args['tv'], false) == false) then
			table.remove(headers,k)
			resultoffset = resultoffset - 1
		elseif headers[k] == 'Attendance' and (yesno(args['attend'], false) == false) then
			table.remove(headers,k)
		elseif headers[k] == 'Source' and (yesno(args['source'], false) == false) then
			table.remove(headers,k)
		end
	end

	-- create the root table
	local root = mw.html.create('table')
	root:addClass('wikitable')
		:css('font-size', '95%')
	
	-- optional caption
	if args['caption'] then
		root:tag('caption'):wikitext(args['caption'])
	end

	-- add the headers
	local row = root:tag('tr')
	for k=1,#headers do
		if headers[k] == 'Rank' then
			local cell = row:tag('th')
			cell:wikitext('Rank')
		elseif headers[k] == 'Location' then
		elseif headers[k] == 'At/Vs' then
		elseif headers[k] == 'Opponent' then
			local cell = row:tag('th')
			cell:wikitext('Opponent')
		else
			local cell = row:tag('th')
			cell:wikitext(headers[k])
		end
	end

	-- build the table
	local k = 1
	local stopflag = (args[k] == nil) and true or false
	if stopflag then return '[[Category:Pages using CFB schedule with no content]]' end
	while stopflag == false do
		local res, bg = getresult('', args[k+resultoffset] or '', '')
		row = root:tag('tr'):css('background-color', bg)
		local op, gn = '', ''
		for j = 1,#headers do
			if headers[j] == 'Result' then
				row:tag('td'):css('white-space', 'nowrap'):wikitext(res)
			elseif headers[j] == 'At/Vs' then
			elseif headers[j] == 'Opponent' then
				if mw.ustring.find(args[k] or '', '<[%s/]*[Nn][Cc][Gg][%s/]*>') then
					ncg = true
				end
				if mw.ustring.find(args[k] or '', '<[%s/]*[Hh][Cc][%s/]*>') then
					hc = true
				end
				op, gn = getopp(args[k], (yesno(args['atvs'], true) == true) and (args[k-1] or '') or '', true)
				row:tag('td'):wikitext(op)
			elseif headers[j] == 'Rank' then
				row:tag('td'):wikitext(getrank(args[k]))
			elseif headers[j] == 'Site' then
				row:tag('td'):wikitext(getsite(args[k] or '', args[k+1] or '',
					(hasgamename and (args[k+2] or '') or '') .. (' ' .. gn)))
			elseif headers[j] == 'Location' then
			elseif headers[j] == 'Game name' then
			elseif headers[j] == 'Attendance' then
				row:tag('td'):css('text-align', 'center'):wikitext(args[k])
			else
				row:tag('td'):wikitext(args[k])
			end
			k = k + 1
			stopflag = (args[k] == nil) and true or false
		end
	end

	-- footnotes
	local fnotes = getfootnotes(
		ncg,
		hc,
		args['other-event'] or args['other_event'] or args['otherevent'],
		yesno(args['rank'], false),
		yesno(args['opprank'], hasrank),
		getpolltext(
			args['rank_year'] or args['rankyear'],
			args['rank_division'] or args['rankdivision'],
			args['poll']
		),
		(yesno(args['time'], false) == false) and '' or args['timezone'],
		args['seasonsource']
	)

	if fnotes ~= nil then
		row = root:tag('tr')
		row:tag('td')
			:attr('colspan',#headers)
			:css('font-size', '85%')
			:wikitext(fnotes)
	end

	-- return the root table
	return tostring(root) ..
		(haslocgamename and '[[Category:Pages using CFB schedule with gamename after location]]' or '') ..
		(hasoppgamename and '[[Category:Pages using CFB schedule with gamename after opponent]]' or '') ..
		(haslocrivalry and '[[Category:Pages using CFB schedule with rivalry after location]]' or '') ..
		(hasopprivalry and '[[Category:Pages using CFB schedule with rivalry after opponent]]' or '') ..
		(hasstrangescore and '[[Category:Pages using CFB schedule with an unusual score]]' or '') ..
		(hasnowrap and '[[Category:Pages using CFB schedule with nowrap or nbsp opponent]]' or '')
end

function p.entry(frame)
	local args = (frame.args.opponent ~= nil) and frame.args or frame:getParent().args
	local cell

	if args['overtime'] then
		args['overtime'] = ' <sup>' .. args['overtime'] .. '</sup>'
	end

	local res, bg = getresult(
		(args['w/l'] or '') .. ' ', 
		args['score'] or '', 
		args['overtime'] or ''
		)

	local root = mw.html.create('tr')
		:addClass('CFB-schedule-row')
		:css('background-color', bg)

	-- Date
	cell = root:tag('td'):addClass('CFB-schedule-date')
	if args.date and (args.date):lower() ~= 'no' then
		cell
			:css('white-space','nowrap')
			:wikitext(args.date or '')
	else
		cell:css('display','none')
	end

	-- Time
	cell = root:tag('td'):addClass('CFB-schedule-time')
	if args.time and (args.time):lower() ~= 'no' then
		cell
			:css('white-space','nowrap')
			:wikitext(args.time or '')
	else
		cell:css('display','none')
	end

	-- Opponent
	local op, gn = getopp(
		(isnotempty(args.opprank) and 'No.&nbsp;' .. args.opprank .. ' ' or '') ..
		(args.opponent or '') ..
		((yesno(args.nonconf,false) == true) and '<ncg>' or '') ..
		((yesno(args.homecoming,false) == true) and '<hc>' or '') ..
		(args.ref or ''),
		(isnotempty(args.away) and 'at' or '') ..
		(isnotempty(args.neutral) and 'vs.' or ''),
		false
		)
	root:tag('td')
		:css('white-space', 'nowrap')
		:wikitext(op)

	-- Rank
	cell = root:tag('td'):addClass('CFB-schedule-rank')
	if args.rank and (args.rank):lower() ~= 'no' then
		local rank = args.rank or ''
		if rank ~= '' then
			rank = 'No. ' .. rank
		end
		cell
			:css('text-align','center')
			:css('white-space','nowrap')
			:wikitext(rank)
	else
		cell:css('display','none')
	end

	-- Gamename
	local gamename = args.gamename or ''

	-- Site
	root:tag('td')
		:wikitext(getsite(args.stadium or args.site_stadium or '', (args.cityst or args.site_cityst or ''), gamename))

	-- TV
	cell = root:tag('td'):addClass('CFB-schedule-tv')
	if args.tv and (args.tv):lower() ~= 'no' then
		cell
			:wikitext(args.tv or '')
	else
		cell:css('display','none')
	end

	-- Result
	root:tag('td')
		:css('white-space','nowrap')
		:wikitext(res)

	-- Attendance
	cell = root:tag('td'):addClass('CFB-schedule-attend')
	if args.attend and (args.attend):lower() ~= 'no' then
		cell
			:css('text-align','center')
			:wikitext(args.attend or '')
	else
		cell:css('display','none')
	end

	-- Source
	cell = root:tag('td'):addClass('CFB-schedule-source')
	if args.source and (args.source):lower() ~= 'no' then
		cell
			:css('text-align','center')
			:wikitext(args.source or '')
	else
		cell:css('display','none')
	end

	return tostring(root)
end

function p.subst(frame)
	local args = frame.args[1] and frame.args or frame:getParent().args
	if (args[1] or ''):find('<tr[^>]*CFB%-schedule%-row') then
		return make_outer_table(args)
	else
		return convert_table(args)
	end
end

function p.table(frame)
	local args = frame.args[1] and frame.args or frame:getParent().args
	if (args[1] or ''):find('<tr[^>]*CFB%-schedule%-row') then
		return make_outer_table(args) .. '[[Category:Pages using CFB schedule with named parameters]]'
	else
		return make_table(args) .. '[[Category:Pages using CFB schedule with unnamed parameters]]'
	end
end

return p