-- This module implements [[Template:Infobox person/length]]

local p = {}

local function clean_length(s)
	s = mw.ustring.gsub(s, 'centimetre', 'cm')
	s = mw.ustring.gsub(s, 'centimeter', 'cm')
	s = mw.ustring.gsub(s, 'cms', 'cm')
	s = mw.ustring.gsub(s, 'cm%.', 'cm')
	s = mw.ustring.gsub(s, 'metre', 'm')
	s = mw.ustring.gsub(s, 'meter', 'm')
	s = mw.ustring.gsub(s, 'ms', 'm')
	s = mw.ustring.gsub(s, 'm%.', 'm')
	s = mw.ustring.gsub(s, 'inches', 'in')
	s = mw.ustring.gsub(s, 'inch', 'in')
	s = mw.ustring.gsub(s, 'ins', 'in')
	s = mw.ustring.gsub(s, 'in%.', 'in')
	s = mw.ustring.gsub(s, '%[%[[Cc]entim|cm%]%]', '[[Centimetre|cm]]')
	s = mw.ustring.gsub(s, '%[%[cm%]%]s', '[[Centimetre|cm]]')
	s = mw.ustring.gsub(s, '%[%[m%]%]s', '[[Metre|m]]')
	s = mw.ustring.gsub(s, '%[%[in|in%]%]', '[[inch|in]]')
	
	return s
end

local function isnumber(s)
	if s then
		s = mw.ustring.gsub(s, '%+%s*%d+%s*/%s*%d+%s*$', '')
		return tonumber(s)
	end
	return nil
end

local function get_convert_length_args(s, prefer, enforce)
	local prefer_m = (prefer or '') == 'm'
	local force_m = (enforce or '') == 'm'
	local prefer_cm = (prefer or '') == 'cm'
	local force_cm = (enforce or '') == 'cm'
	
	unconverted = clean_length(s or '') -- basic unit cleaning
	
	s = mw.ustring.gsub(unconverted, '&[Nn][Bb][Ss][Pp];', ' ')
	
	local m = mw.ustring.find(s, 'm')
	local c = mw.ustring.find(s, 'cm')
	local i = mw.ustring.find(s, 'in')
	
	if m == nil and i == nil then
		return '', unconverted
	end
	
	if c ~= nil and i == nil then
		local n = mw.ustring.sub(s, 1, c - 1)
		if isnumber(n) then
			return force_m
				and {n/100,'m','in',0,['abbr']='on'}
				or {n,'cm','in',0,['abbr']='on'}, mw.ustring.sub(s, c+2)
		end
		return '', unconverted
	end
	
	if m ~= nil and c == nil and i == nil then
		local n = mw.ustring.sub(s, 1, m - 1)
		if isnumber(n) then
			return force_cm 
				and {n*100,'cm','in',0,['abbr']='on'}
				or {n,'m','in',0,['abbr']='on'}, mw.ustring.sub(s, m+1)
		end
		return '', unconverted
	end
	
	if i ~= nil and m == nil then
		local n = mw.ustring.sub(s, 1, i - 1)
		if isnumber(n) then
			return (force_m or prefer_m)
				and {n,'in','m',2,['abbr']='on'}
				or {n,'in','cm',0,['abbr']='on'}, mw.ustring.sub(s, i+2)
		end
		return '', unconverted
	end
	
	return '', unconverted
end

function convert_length(frame, args)
	local targs, str = get_convert_length_args(args[1], args['prefer'] or '', args['enforce'] or '')

	if type(targs) == 'table' then
		return frame:expandTemplate{ title = 'convert', args = targs} .. str
	else
		return str
	end
end

function p.length(frame)
	return convert_length(frame, frame.args[1] and frame.args or frame:getParent().args)
end

return p