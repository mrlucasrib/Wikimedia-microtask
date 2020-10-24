require('Module:No globals')

local p = { isalias = false }
local yesno = require('Module:Yesno')
local constants = {	CODE_LEN = 3, SPACE = '&nbsp;', SHORT = 'short', INST = 'inst' }

local function makeInvokeFunc(funcName, league)
	return function (frame)
		local args = (frame.args[1] ~= nil) and frame.args or frame:getParent().args
		args['league'] = args['league'] or league or 'collegiate'
		return p[funcName](args)
	end
end

local function stripwhitespace(text) return text:match("^%s*(.-)%s*$") end

local function load_data(args)
	local data_module = 'Module:PHL sports team/' .. args['league']
	return mw.loadData(data_module)
end

local function get_key_by_code(code, data)
	if (data[code] ~= nil and type(data[code]) == 'string') then
		p.isalias = true
		return data[code]
	elseif (string.len(code) == constants.CODE_LEN) then
		for k,v in pairs(data) do
			if v[1]==code then return k end
		end
	end
	return code
end

local function get_icon(team, size, alt_team)
	local icon = '[[File:%s colors.svg|%s|border|%s school colors|link=]]'
	return string.format(icon, team, size or '11px', alt_team or team)
end

local function get_athlete_link(link, athl_name)
	if mw.title.new(link or athl_name, '').exists == true then return string.format('[[%s|%s]]', link or athl_name, athl_name) else return athl_name end
end

local function show_empty_param(param)
	return mw.html.create('span'):css('color', 'red'):cssText('style'):wikitext(string.format('Value for parameter \'%s\' not provided.', param))
end

local function get_link_by_evt(args, div, divLt, text, team)
	local evt = { bk = 'basketball', vb = 'volleyball', ft = 'football' }
	local mRdr = require('Module:Redirect')
	evt = evt[args[2]] or evt[args[3]] or evt[args['evt']]
	if evt == nil then
		if type(div) == 'number' and div < 3 then
			 return mRdr.getTarget(team)
		else return mRdr.getTarget(text) end
	end
	if (type(div) == 'string') then div = 3 end
	local evt_link = string.format('%s %s %s', text, divLt[div-2], evt)
	if (args['yr'] ~= nil) then return args['yr'] .. ' ' .. evt_link .. ' team' end
	return mRdr.getTarget(evt_link) or evt_link
end

local function get_name_by_year(team, year)
	if not year then return team[1] end
	for k, v in pairs(team) do
		if mw.ustring.find(k, "%d%d%d%dthru%d%d%d%d$") then
			local start_year, end_year = mw.ustring.match(k, "(%d%d%d%d)thru(%d%d%d%d)$")
			if (tonumber(start_year) <= tonumber(year)) and (tonumber(year) <= tonumber(end_year)) then
				return v
			end
		end
	end
	return team[1]
end

local function add_link(args, team, name, div, divLt, text)
	local evt_link = get_link_by_evt(args, div, divLt, team[div] or team[3], team[3])
	if (type(div) == 'number' and div >= 3 and div <= 6) then
		if ((args['inst'] or name) ~= nil or args[3] == constants.SHORT)
				then return string.format('[[%s|%s]]', evt_link or team[div], not p.isalias and team[args['inst']] or text)
			elseif (evt_link ~= nil) then return string.format('[[%s|%s]]', evt_link, text)
			else return string.format('[[%s]]', text) end
	end
	return string.format('[[%s|%s]]', evt_link or team[3], text)
end

local function add_link_generic(args, team, text)
	local mRdr = require('Module:Redirect')
	local tln = team.link or get_name_by_year(team, args['season'] or args['team'])
	local dab  = team.dab and (tln .. ' (' .. team.dab .. ')') or nil
	local fln = dab or tln
	
	if args['name']     then fln = team[args['name']] or dab or tln end
	if args['season']   then fln = args['season'] .. ' ' .. tln .. ' season'
	elseif args['team'] then fln = args['team'] .. ' ' .. tln .. ' team'
	else fln = mRdr.getTarget(fln) end
	return string.format('[[%s|%s]]', fln or dab or tln, text)
end

function p._main(args)
	local data = load_data(args)
	local in_team = stripwhitespace(args[1] or '')
	if (in_team:match('^{{{.*}}}$') ~= nil) then return show_empty_param(in_team) elseif (in_team == '' or nil) then return '—' end
	
	local in_div = stripwhitespace(args[2] or '')
	local in_name = args['name']
	local key = get_key_by_code(in_team, data)
	local team = data[key]
	if (team == nil) then return error(string.format('Invalid team: %s', in_team)) end
	
	local out
	local divLt = { "men's", "women's", "boys'", "girls'" }
	
	if (in_div ~= constants.SHORT) then
		local div = { inst = 2, men = 3, women = 4, junior = 5, boys = 5, girls = 6 }
		in_div = div[in_div] or tonumber(in_div:match('[2-6]') or '3')
		if (args[3] == constants.INST or args['inst'] ~= nil or in_div == 2) then out = p.isalias and team[in_team] or team[div['inst']]
			elseif (args[3] == constants.SHORT) then out = team[7] or key or in_team
			else out = in_name or team[in_div] end
		if (out == nil) then return error('No ' .. divLt[in_div-2] .. ' team') end
	else
		out = team[7] or key or in_team
	end
	
	out = out:gsub("-", "&ndash;")
	
	if yesno(args['add_link'] or 'y') then
		out = add_link(args, team, in_name, in_div, divLt, out)
	end

	if yesno(args['icon'] or 'y') then
		local icon = get_icon(key or in_team, args['iconsize'])
		out = yesno(args['rt'] or 'n') and out .. constants.SPACE .. icon or icon .. constants.SPACE .. out
	end
	
	return out
end

function p._rt(args)
	args['rt'] = 'y'
	return p._main(args)
end

function p._name(args)
	args['icon'] = 'n'
	return p._main(args)
end

function p._color(args)
	local data = load_data(args)
	local in_team = stripwhitespace(args[1] or '')
	local no_img = string.format('[[File:No image.svg|%s|link=]]', args['size'] or '11px')
	local note = ''
	if in_team and in_team:match('[%*]$') then
		note = mw.ustring.gsub(in_team, '^(.-)([%*]*)$', '%2')
		in_team = mw.ustring.gsub(in_team, '^(.-)([%*]*)$', '%1')
	end
	if (in_team:match('^{{{.*}}}$') ~= nil) then
		return show_empty_param(in_team) .. note
	elseif (in_team == '' or nil) then return no_img .. note end
		
	local key = get_key_by_code(in_team, data)
	if ((data[in_team] or data[key]) == nil) then
		return no_img .. note
	end
	return get_icon(key or in_team, args['size'], args[2]) .. note
end

function p._generic(args)
	local data = load_data(args)
	local code, name, out = stripwhitespace(args[1] or ''), args['name']
	local team = data[code]
	
	if (code:match('^{{{.*}}}$') ~= nil) then return show_empty_param(code) elseif (code == '' or nil) then return '—' end

	if type(team) == 'string' then
		local alias = mw.text.split(team, '%s*|%s*')
		team = data[alias[1]]
		name = name or alias[2]
	end
	
	if not team then return error(string.format('Invalid team: %s', code)) end
	if args[2] == constants.SHORT then out = team[2] or code
		elseif name then out = team[name] or name
		else out = get_name_by_year(team, args['season'] or args['team'] or args['yr'])
	end
	return add_link_generic(args, team, out)
end

function p._athlete(args)
	local athl_1 = args['athl']
	local athl_2 = args['athl2']
	
	if athl_1 == nil then return error('Invalid athlete: no value') end
	local link = get_athlete_link(args['link'], athl_1)
	
	if (athl_2 ~= nil) then link = link .. ' and ' .. get_athlete_link(args['link2'], athl_2) end
	
	local showicon = yesno(args['icon'])
	local sport = args['sp']
	
	if (showicon) then args[3] = constants.SHORT end
	args['add_link'] = 'n'
	local lbl = p._name(args)
	if (sport ~= nil) then
		lbl = string.format('%s&nbsp;<span style="font-size:90%%;">(%s,&nbsp;%s)</span>', link, lbl, string.lower(sport))
	else lbl = string.format('%s&nbsp;<span style="font-size:90%%;">(%s)</span>', link, lbl)
	end
	
	if (showicon) then
		args[2] = args[1]
		return p._color(args) .. constants.SPACE .. lbl
	else return lbl
	end
end

function p._athlete_bc(args)
	if (args['athl'] == nil) then
	    -- reassign arguments for backward compatibility --
	    args['athl'] = args[2]
		args[2] = args[3] or ''
		args[3] = args[4] or ''
	end
	return p._athlete(args)
end

p.main = makeInvokeFunc('_main')
p.rt = makeInvokeFunc('_rt')
p.name = makeInvokeFunc('_name')
p.color = makeInvokeFunc('_color')
p.pba = makeInvokeFunc('_generic', 'PBA')
p.athlete = makeInvokeFunc('_athlete_bc')

return p