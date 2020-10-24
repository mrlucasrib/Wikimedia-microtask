require('Module:No globals')
local p = {}

local getArgs = require('Module:Arguments').getArgs

local tracking = ''

local function addflags(frame, names)
	for k,v in ipairs(names) do
		if v['nat'] then
			names[k]['nat'] = '<span data-sort-value="' .. v['nat'] .. '">'
				.. frame:expandTemplate{title = 'flagicon', args = {v['nat']}} .. '</span>'
		end
	end
	return names
end

local function linkschools(frame, names)
	for k,v in ipairs(names) do
		if v['college'] or v['school'] then
			names[k]['college'] = frame:expandTemplate{title = 'college', args = {v['college'] or v['school']}}
		end
	end
	return names
end

local function stylelinks(txt, css)
	if css and txt then
		local bg,fg = '',''
		css = string.lower(css)
		for k,v in ipairs(mw.text.split(css .. ';', ';')) do
			if v:match('^%s*background%s*:') then
				bg = v .. ';'
			elseif v:match('^s*background%-color%s*:') then
				bg = v .. ';'
			elseif v:match('^s*color%s*:') then
				fg = v .. ';'
			end
		end
		txt = mw.ustring.gsub(txt, '(%[%[)([^%[%]%|]*)(%]%])', '%1%2|%2%3')
		txt = mw.ustring.gsub(txt, '(%[%[[^%[%]%|]*%|)([^%[%]%|]*)(%]%])', 
			'%1<span style="' .. bg .. fg .. '">%2</span>%3')
	end
	return txt
end

local function getlastduplicates(names)
	local found = {}
	local res = {}
	local count = 0
	for k,v in ipairs(names) do
		if v['last'] then
			if found[v['last']] then
				res[v['last']] = 1
				count = count + 1
			else
				found[v['last']] = 1
			end
		end
	end
	if count < 1 then
		return nil
	end
	return res
end

local function linknames(names, fmt, reqinitials)
	for k,v in ipairs(names) do
		local link = v['link'] or v['name'] or ((v['first'] or '') .. ' ' .. (v['last']  or '') .. (v['dab'] and ' (' .. v['dab'] .. ')' or '')) or ''
		if v['nolink'] then
			link = ''
		end
		local text = v['last'] or v['alt'] or v['name'] or ((v['first'] or '') .. ' ' .. (v['last']  or '')) or link
		if fmt == 'lf' then
			text = v['alt'] or v['name'] or ((v['last']  or '') .. ', ' .. (v['first'] or '')) or ''
		elseif fmt == 'fl' or fmt == 'fil' or (reqinitials and reqinitials[v['last']]) then
			if (fmt == 'fil' or (reqinitials and reqinitials[v['last']])) and v['first'] then
				v['first'] = string.upper(string.sub(v['first'] .. ' ', 1, 1)) .. '.'
			end
			text = v['alt'] or v['name'] or ((v['first'] or '') .. ' ' .. (v['last']  or '')) or ''
		end
		
		if link:match('^[,%s]*$') then
			if text:match('^[,%s]*$') then
				text = ''
			end
		else
			if text:match('^[,%s]*$') then
				text = '[[' .. link .. ']]'
			elseif link == text then
				text = '[[' .. link .. ']]'
			else
				text = '[[' .. link .. '|' .. text .. ']]'
			end
		end
		names[k]['name'] = text
	end
	
	return names
end

local function parseEntry(s, keys)
	local res = {}
	for k,v in pairs(mw.text.split(s, '%s*<[Tt][Dd]%s*')) do
		v = mw.ustring.gsub(v, '%s*</[Tt][RrDd]>%s*', '')
		if v:find('^.-class%s*=%s*[\'"][^\'"]*sports%-roster%-([A-Za-z]+)%s*[\'"][^>]*>%s*([^%s].-)%s*$') then
			local kk =  mw.ustring.gsub(v, '^.-class%s*=%s*[\'"][^\'"]*sports%-roster%-([A-Za-z]+)%s*[\'"][^>]*>%s*([^%s].-)%s*$', '%1')
			res[kk] = mw.ustring.gsub(v, '^.-class%s*=%s*[\'"][^\'"]*sports%-roster%-([A-Za-z]+)%s*[\'"][^>]*>%s*([^%s].-)%s*$', '%2')
			keys[kk] = 1
		end
	end
	return keys, res
end

local function getEntries(args, role, res, keys)
	local i = 2
	local v
	res = res or {}
	keys = keys or {}
	while args[i] ~= nil do
		keys, v = parseEntry(args[i], keys)
		if role then
			v['role'] = role
		end
		table.insert(res, v)
		i = i + 1
	end
	return res, keys
end

function p.entry(frame)
	local args = getArgs(frame)
	local res = ''
	for k,v in pairs(args) do
		if type(k) == 'string' then
			res = res .. '<td class="sports-roster-' .. k .. '">' .. v .. '</td>'
		end
	end

	if res ~= '' then
		return '<tr>' .. res .. '</tr>'
	end

	return res
end

function p.roster(frame)
	local args = getArgs(frame)
	local players, keys = getEntries(mw.text.split(args['players'] or '', '%s*<[Tt][Rr]>%s*'))

	local coaches, ckeys = {}, {}
	for k,v in ipairs({
		{'head_coach', 'Head coach'},
		{'asst_coach', 'Assistant coaches'}
		}) do
		coaches, ckeys = getEntries(mw.text.split(args[v[1]] or '', '%s*<[Tt][Rr]>%s*'), v[2], coaches, ckeys)
	end
	local staff, skeys = {}, {}
	for k,v in ipairs({
			{'player_development', 'Player development'}, 
			{'ath_train', 'Athletic trainer'},
			{'assistant_trainer', 'Assistant trainer'},
			{'str_cond', 'Strength and conditioning coach'},
		}) do
		staff, skeys = getEntries(mw.text.split(args[v[1]] or '', '%s*<[Tt][Rr]>%s*'), v[2], staff, skeys)
	end

	local p_style
	if args['style'] and mw.title.new('Module:Sports roster/' .. args['style']) then
		p_style = require('Module:Sports roster/' .. args['style'])
	else
		p_style = require('Module:Sports roster/default')
	end
	-- flags
	if keys['nat'] then
		players = addflags(frame, players)
	end
	if ckeys['nat'] then
		coaches = addflags(frame, coaches)
	end
	if skeys['nat'] then
		staff = addflags(frame, staff)
	end
	-- college links
	if keys['college'] or keys['school'] then
		players = linkschools(frame, players)
	end
	if ckeys['college'] or ckeys['school'] then
		coaches = linkschools(frame, coaches)
	end
	if skeys['college'] or ckeys['school'] then
		staff = linkschools(frame, staff)
	end
	-- link names
	players = linknames(players, 'lf')
	coaches = linknames(coaches, 'fl')
	staff = linknames(staff, 'fl')
	
	local res = mw.html.create('table')
	res:addClass('toccolours')
		:css('font-size', '85%')
		:css('margin', '1em auto')
		:css('width', '90%')
	local row = res:tag('tr')
	local above = p_style.above(args)
	local abovestyle = p_style.abovestyle(frame, args)
	local color = mw.ustring.match(';' .. string.lower(abovestyle or ''), ';%s*color%s*:([^;]*)')
	row:tag('th')
		:attr('colspan', 2)
		:cssText(abovestyle)
		:css('text-align', 'center')
		:wikitext(above and frame:expandTemplate{title='navbar-header', args={
			stylelinks(above,abovestyle),
			args['name'], fontcolor = color or ''}} or nil)
	row = res:tag('tr')
		:css('text-align', 'center')
	local headingstyle = p_style.headingstyle(frame, args)
	row:tag('th'):cssText(headingstyle):wikitext('Players')
	row:tag('th'):cssText(headingstyle):wikitext('Coaches')
	row = res:tag('tr')

	local innertable = row:tag('td'):css('vertical-align', 'top'):tag('table')
	innertable:addClass('sortable')
		:css('background', 'transparent')
		:css('margin', 0)
		:css('width', '100%')
	innertable:wikitext(p_style.headings(args, keys))
	innertable:wikitext(p_style.players_roster(args, players, keys))
	local cell = row:tag('td'):css('vertical-align', 'top')
	cell:wikitext(p_style.coaches_roster(coaches))
	cell:wikitext(p_style.staff_roster(staff))
	cell:wikitext(p_style.legend(args))
	local footer = p_style.footer(args, keys)
	if footer ~= '' then
		cell:attr('rowspan', 2)
		local footerstyle = p_style.footerstyle(frame, args)
		row = res:tag('tr')
		row:tag('td')
			:addClass('hlist')
			:css('text-align', 'center')
			:cssText(footerstyle)
			:wikitext(footer)
	end

	return tostring(res)

end

function p.navbox(frame)
	local args = getArgs(frame)
	local players, keys = getEntries(mw.text.split(args['players'] or '', '%s*<[Tt][Rr]>%s*'))
	local coaches, ckeys = {}, {}
	for k,v in ipairs({
		{'head_coach', 'Head coach'},
		{'asst_coach', 'Assistant coaches'}
		}) do
		coaches, ckeys = getEntries(mw.text.split(args[v[1]] or '', '%s*<[Tt][Rr]>%s*'), v[2], coaches, ckeys)
	end
	local p_style
	if args['style'] and mw.title.new('Module:Sports roster/' .. args['style']) then
		p_style = require('Module:Sports roster/' .. args['style'])
	else
		p_style = require('Module:Sports roster/default')
	end
	local needinitials = getlastduplicates(players)
	players = linknames(players, 'l', needinitials)
	coaches = linknames(coaches, 'fil')
	table.sort(players, function (a, b) 
			return (tonumber(a['num']) or 9999) < (tonumber(b['num']) or 9999)
				or ((tonumber(a['num']) or 9999) == (tonumber(b['num']) or 9999)
					and ((a['last'] or 'ZZZZ') < (b['last'] .. 'ZZZZ')))
				end
		)
	
	local Navbox = require('Module:Navbox')

	local targs = {}
	
	targs['name'] = args['name'] or mw.title.getCurrentTitle().text
	targs['titlestyle'] = p_style.titlestyle(frame, args)
	targs['title'] = stylelinks(p_style.title(args), targs['titlestyle'])
	targs['listclass'] = 'hlist'
	targs['state'] = args['state'] or 'autocollapse'
	targs['list1'] = p_style.players_list(args, players, keys) .. '\n' .. p_style.coaches_list(coaches)
	targs['belowclass'] = 'hlist'
	targs['belowstyle'] = p_style.belowstyle(frame, args)
	targs['below'] =  stylelinks(p_style.below(args, keys), targs['belowstyle'])

	return Navbox._navbox(targs) .. tracking
end

return p