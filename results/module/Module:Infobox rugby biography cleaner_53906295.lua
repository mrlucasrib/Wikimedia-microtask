
local p = {}

local args = {}

local function isnotblank(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function argrename(n1, n2)
	if args[n1] or args[n2] then
		if( args[n1] and args[n1] ~= '' ) and ( args[n2] and args[n2] ~= '' ) then
			args[n2] = (args[n2] or '') .. '\n' .. (args[n1] or '')
		else
			args[n2] = (args[n2] or '') .. (args[n1] or '')
		end
		args[n1] = ''
	end
end

local function addparam(s, f)
	-- f = a, e, or nb
	local r = ''
	if f == 'a' then
		r = '\n| ' .. s .. ' = ' .. (args[s] or '')
	elseif f == 'e' then
		if args[s] then
			r = '\n| ' .. s .. ' = ' .. args[s]
		end
	else
		if isnotblank(args[s]) then
			r = '\n| ' .. s .. ' = ' .. args[s]
		end
	end
	args[s] = '<PROCESSED>'
	return r
end

local function addseries(s, n)
	local r = ''
	local yname = s .. 'years'
	local cname = s .. 'clubs'
	local aname = s .. 'apps'
	local pname = s .. 'points'
	local showapps = true
	local showpts = true
	
	argrename(s .. 'caps', aname)
	for k=1,n do
		argrename(s .. 'caps' .. k, aname .. k)
	end
	
	if (s == 'rl_youth') or (s == 'youth') then
		showapps = false
		showpts = false
	elseif (s == 'rl_club') then
		cname = 'rl_proclubs'
	elseif (s == 'city_vs_country_' or s == 'soo' or s == 'rl_national' 
		or s == 'amat' or s == 'rep') then
		cname = s .. 'team'
	elseif ( s == 'ru_sevensnational' ) then
		cname = s .. 'team'
		aname = s .. 'comp'
	elseif (s == 'rl_coach' or s == 'ru_coach') then
		cname = s .. 'teams'
		showapps = false
		showpts = false
	elseif (s == 'rl_referee' or s == 'ru_referee') then
		cname = s .. 'comps'
		showpts = false
	elseif (s == 'ru_province') or (s == 'super') then
		cname = s
	end
	if args[yname] and args[yname]:match('^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|.*}}[%s]*$') then
		args[yname] = mw.ustring.gsub(args[yname], '^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|(.*)}}[%s]*$', '%1')
	end
	if args[cname] and args[cname]:match('^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|.*}}[%s]*$') then
		args[cname] = mw.ustring.gsub(args[cname], '^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|(.*)}}[%s]*$', '%1')
	end
	if args[aname] and args[aname]:match('^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|.*}}[%s]*$') then
		args[aname] = mw.ustring.gsub(args[aname], '^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|(.*)}}[%s]*$', '%1')
	end
	if args[pname] and args[pname]:match('^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|.*}}[%s]*$') then
		args[pname] = mw.ustring.gsub(args[pname], '^[%s]*{{[Nn][Oo][Ww][Rr][Pp][^%s]*|(.*)}}[%s]*$', '%1')
	end
	if isnotblank(args[cname]) or isnotblank(args[yname]) then
		local ylist = mw.text.split(args[yname] or '', '[%s]*<[\/\t ]*[Bb][Rr][^<>]*>')
		local clist = mw.text.split(args[cname] or '', '[%s]*<[\/\t ]*[Bb][Rr][^<>]*>')
		local alist = {}
		local plist = {}
		if showapps then
			alist = mw.text.split(args[aname] or '', '[%s]*<[\/\t ]*[Bb][Rr][^<>]*>')
		end
		if showpts then
			plist = mw.text.split(args[pname] or '', '[%s]*<[\/\t ]*[Bb][Rr][^<>]*>')
		end
		if ((#clist) >= (#ylist)) and ((#clist) >= (#alist)) and ((#clist) >= (#plist)) then
			for k = 1,(#clist) do
				r = r .. '\n| ' .. yname .. k .. ' = ' .. (ylist[k] or '')
				r = r .. '\n| ' .. cname .. k .. ' = ' .. (clist[k] or '')
				if showapps then
					r = r .. '\n| ' .. aname .. k .. ' = ' .. (alist[k] or '')
				end
				if showpts then
					r = r .. '\n| ' .. pname .. k .. ' = ' .. (plist[k] or '')
				end
			end
			args[yname] = '<PROCESSED>'
			args[cname] = '<PROCESSED>'
			args[aname] = '<PROCESSED>'
			args[pname] = '<PROCESSED>'
		else
			r = r .. addparam(yname, 'e')
			r = r .. addparam(cname, 'e')
			r = r .. addparam(aname, 'e')
			r = r .. addparam(pname, 'e')
		end
	else
		r = r .. addparam(yname, 'e')
		r = r .. addparam(cname, 'e')
		r = r .. addparam(aname, 'e')
		r = r .. addparam(pname, 'e')
	end
	
	for k=1,n do
		r = r .. addparam(yname .. k, 'e')
		r = r .. addparam(cname ..  k, 'e')
		r = r .. addparam(aname ..  k, 'e')
		r = r .. addparam(pname ..  k, 'e')
	end
	return r
end

function p.main(frame)
	local res = ''
	local offset = 0
	for k,v in pairs(frame.args) do
		args[k] = v
	end
	
	-- preprocess
	argrename('rl_coachclubs', 'rl_coachteams')
	argrename('ru_coachclubs', 'coachteams')
	argrename('ru_coachyears', 'coachyears')
	argrename('ru_youthclubs', 'youthclubs')
	argrename('ru_youthyears', 'youthyears')
	argrename('ru_amateurclubs', 'amatteam')
	argrename('ru_amateuryears', 'amatyears')
	argrename('ru_amateurcaps', 'amatcaps')
	argrename('ru_amateurpoints', 'amatpoints')
	argrename('ru_amupdate', 'amatupdate')
	argrename('ru_proclubs', 'clubs')
	argrename('ru_clubyears', 'years')
	argrename('ru_clubcaps', 'caps')
	argrename('ru_clubpoints', 'points')
	argrename('ru_clubupdate', 'clubupdate')
	argrename('super14', 'super')
	argrename('super14years', 'superyears')
	argrename('super14caps', 'supercaps')
	argrename('super14points', 'superpoints')
	argrename('super14update', 'superupdate')
	argrename('ru_nationalteam', 'repteam')
	argrename('ru_nationalyears', 'repyears')
	argrename('ru_nationalcaps', 'repcaps')
	argrename('ru_nationalpoints', 'reppoints')
	argrename('ru_ntupdate', 'repupdate')
	for k=1,10 do
		argrename('amatcaps' .. k, 'amatapps' .. k)
	end
	
	
	res = res .. '{{Infobox rugby biography'
	res = res .. addparam('embed', 'nb')
	res = res .. addparam('name', 'e')
	res = res .. addparam('image', 'e')
	res = res .. addparam('image_size', 'e')
	res = res .. addparam('alt', 'e')
	res = res .. addparam('caption', 'e')
	res = res .. addparam('fullname', 'e')
	res = res .. addparam('birth_name', 'e')
	res = res .. addparam('nickname', 'e')
	res = res .. addparam('birth_date', 'e')
	res = res .. addparam('birth_place', 'e')
	res = res .. addparam('death_date', 'e')
	res = res .. addparam('death_place', 'e')
	res = res .. addparam('height', 'e')
	res = res .. addparam('height_cm', 'e')
	res = res .. addparam('height_ft', 'e')
	res = res .. addparam('height_in', 'e')
	res = res .. addparam('weight', 'e')
	res = res .. addparam('weight_kg', 'e')
	res = res .. addparam('weight_st', 'e')
	res = res .. addparam('weight_lb', 'e')
	res = res .. addparam('school', 'e')
	res = res .. addparam('university', 'e')
	res = res .. addparam('relatives', 'e')
	res = res .. addparam('spouse', 'e')
	res = res .. addparam('children', 'e')
	res = res .. addparam('occupation', 'e')
	res = res .. addparam('weight_update', 'e')
	
	res = res .. addparam('rl_position', 'e')
	res = res .. addparam('rl_currentposition', 'e')
	res = res .. addparam('rl_currentteam', 'e')

	res = res .. addseries('rl_youth', 5)

	res = res .. addseries('rl_amateur', 10)
	res = res .. addparam('rl_amupdate', 'e')

	res = res .. addseries('rl_club', 20)
	res = res .. addparam('rl_totalyears', 'e')
	res = res .. addparam('rl_totalapps', 'e')
	res = res .. addparam('rl_totalpoints', 'e')
	res = res .. addparam('rl_clubupdate', 'e')
	
	res = res .. addseries('city_vs_country_', 10)
	res = res .. addparam('city_vs_country_update', 'e')
	
	res = res .. addseries('soo', 10)
	res = res .. addparam('sooupdate', 'e')
	
	res = res .. addseries('rl_national', 10)
	res = res .. addparam('rl_ntupdate', 'e')
	
	res = res .. addseries('rl_coach', 20)
	res = res .. addparam('rl_coachupdate', 'e')
	
	res = res .. addseries('rl_referee', 20)
	res = res .. addparam('rl_refereeupdate', 'e')
	
	res = res .. addparam('ru_currentposition', 'e')
	res = res .. addparam('ru_position', 'e')
	res = res .. addparam('position', 'e')
	res = res .. addparam('ru_currentteam', 'e')
	res = res .. addparam('currentclub', 'e')
	res = res .. addparam('allblackid', 'e')
	res = res .. addparam('allblackno', 'e')

	res = res .. addseries('youth', 5)
	
	res = res .. addseries('amat', 10)
	res = res .. addparam('amatupdate', 'e')
	
	res = res .. addseries('', 20)
	res = res .. addparam('totalyears', 'e')
	res = res .. addparam('totalapps', 'e')
	res = res .. addparam('totalpoints', 'e')
	
	res = res .. addseries('ru_province', 10)
	res = res .. addparam('ru_provinceupdate', 'e')
	
	res = res .. addseries('super', 10)
	
	res = res .. addparam('ru_currentclub', 'e')
	res = res .. addparam('superupdate', 'e')
	
	res = res .. addseries('rep', 10)
	res = res .. addparam('repupdate', 'e')
	
	res = res .. addseries('ru_sevensnational', 10)
	res = res .. addparam('ru_sevensupdate', 'e')
	
	res = res .. addseries('coach', 20)
	res = res .. addparam('ru_coachupdate', 'e')
	
	res = res .. addseries('ru_referee', 20)
	res = res .. addparam('ru_refereeupdate', 'e')
	
	res = res .. addparam('website', 'e')
	res = res .. addparam('url', 'e')
	
	for k,v in pairs(args) do
		if v == '' or v == '<PROCESSED>' then
			-- skip
		else
			res = res .. '| <!-- UNKNOWN --> ' .. k .. ' = ' .. v
		end
	end

	res = res .. '\n}}'
	
	return res
	
end

return p