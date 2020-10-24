-- This module implements [[Template:Infobox person/weight]]

local p = {}

local function clean_weight(s)

	s = mw.ustring.gsub(s, 'kilogram', 'kg')
	s = mw.ustring.gsub(s, 'kgs', 'kg')
	s = mw.ustring.gsub(s, 'kg[%.,]', 'kg')

	s = mw.ustring.gsub(s, 'pound', 'lb')
	s = mw.ustring.gsub(s, 'lbs', 'lb')
	s = mw.ustring.gsub(s, 'lb[%.,]', 'lb')

	s = mw.ustring.gsub(s, 'stone', 'st')
	s = mw.ustring.gsub(s, 'sts', 'st')
	s = mw.ustring.gsub(s, 'st[%.,]', 'st')

	s = mw.ustring.gsub(s, '%[%[kg%]%]s', '[[Kilogram|kg]]')

	return s
end

local function isnumber(s)
	if s then
		s = mw.ustring.gsub(s, '%+%s*%d+%s*/%s*%d+%s*$', '')
		s = mw.ustring.gsub(s, '%s*[–%-]%s*', '')
		return tonumber(s)
	end
	return nil
end

local function get_convert_weight_args(s, kg_stlb, lb_stlb)
	local prefer_m = (prefer or '') == 'm'
	local force_m = (enforce or '') == 'm'
	local prefer_cm = (prefer or '') == 'cm'
	local force_cm = (enforce or '') == 'cm'
	
	unconverted = clean_weight(s or '') -- basic unit cleaning
	
	s = mw.ustring.gsub(unconverted, '&[Nn][Bb][Ss][Pp];', ' ')
	
	local kg = mw.ustring.find(s, 'kg')
	local st = mw.ustring.find(s, 'st')
	local lb = mw.ustring.find(s, 'lb')
	
	if kg == nil and st == nil and lb == nil then
		return '', unconverted
	end
	
	if kg ~= nil and st == nil and lb == nil then
		local n = mw.ustring.sub(s, 1, kg - 1)
		if isnumber(n) then
			return {n,'kg',kg_stlb and 'lb stlb' or 'lb',0,['abbr']='on'}, mw.ustring.sub(s, kg+2)
		end
		return '', unconverted
	end
	
	if lb ~= nil and kg == nil and st == nil then
		local n = mw.ustring.sub(s, 1, lb - 1)
		if isnumber(n) then
			return {n,'lb',lb_stlb and 'kg stlb' or 'kg',0,['abbr']='on'}, mw.ustring.sub(s, lb+2)
		end
		return '', unconverted
	end
	
	if st ~= nil and kg == nil and lb == nil then
		local n = mw.ustring.sub(s, 1, st - 1)
		if isnumber(n) then
			return {n,'st','lb kg',0,['abbr']='on'}, mw.ustring.sub(s, st+2)
		end
		return '', unconverted
	end

	if lb ~= nil and st ~=nil and kg == nil then
		local n1 = mw.ustring.sub(s, 1, st - 1)
		local n2 = mw.ustring.sub(s, st+2, lb - 1)
		if isnumber(n1) and isnumber(n2) then
			return {n1,'st',n2,'lb', 'lb kg',0,['abbr']='on'}, mw.ustring.sub(s, lb+2)
		end
		return '', unconverted
	end
	
	return '', unconverted
end

function convert_weight(frame, args)
	local targs, str = get_convert_weight_args(args[1], (args['kg-stlb'] or '') ~= '', (args['lb-stlb'] or '') ~= '')

	if type(targs) == 'table' then
		return frame:expandTemplate{ title = 'convert', args = targs} .. str
	else
		return str
	end
end

function p.weight(frame)
	return convert_weight(frame, frame.args[1] and frame.args or frame:getParent().args)
end

return p