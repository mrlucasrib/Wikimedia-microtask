-- This module implements [[Template:Infobox person/height]]

local p = {}

local function clean(s)

	s = mw.ustring.gsub(s, 'metre', 'm')
	s = mw.ustring.gsub(s, '([^a])meter', '%1m') -- prevents "parameter" from being changed to "param"
	s = mw.ustring.gsub(s, 'centi', 'c') -- changes "centim" to "cm"
	s = mw.ustring.gsub(s, 'ms', 'm')
 	s = mw.ustring.gsub(s, 'm[%.,]', 'm')

	s = mw.ustring.gsub(s, 'feet', 'ft')
	s = mw.ustring.gsub(s, 'foot', 'ft')
	s = mw.ustring.gsub(s, 'ft[%.,]', 'ft')

	s = mw.ustring.gsub(s, 'inches', 'in')
	s = mw.ustring.gsub(s, 'inch', 'in')
	s = mw.ustring.gsub(s, 'ins', 'in')
	s = mw.ustring.gsub(s, 'in[%.,]', 'in')

	s = mw.ustring.gsub(s, '%[%[[Mm]%]%]s', '[[Metre|m]]')
	s = mw.ustring.gsub(s, '%[%[[Cc]m%]%]s', '[[Centimetre|cm]]')
	s = mw.ustring.gsub(s, '%[%[[Cc]entim|cm%]%]', '[[Centimetre|cm]]')
	s = mw.ustring.gsub(s, '%[%[[Ii]n|in%]%]', '[[inch|in]]')

	return s
end

local function isnumber(s)
	if s then
		s = mw.ustring.gsub(s, '%+%s*%d+%s*/%s*%d+%s*$', '')
		return tonumber(s)
	end
	return nil
end

local function get_convert_args(s, prefer, enforce)
	local prefer_m = (prefer or '') == 'm'
	local force_m = (enforce or '') == 'm'
	local prefer_cm = (prefer or '') == 'cm'
	local force_cm = (enforce or '') == 'cm'
	
	unconverted = clean(s or '') -- basic unit cleaning
	
	s = mw.ustring.gsub(unconverted, '&[Nn][Bb][Ss][Pp];', ' ')
	
	local m = mw.ustring.find(s, 'm')
	local c = mw.ustring.find(s, 'cm')
	local f = mw.ustring.find(s, 'ft')
	local i = mw.ustring.find(s, 'in')
	
	if m == nil and f == nil and i == nil then
		return '', unconverted
	end
	
	if c ~= nil and f == nil and i == nil then
		local n = mw.ustring.sub(s, 1, c - 1)
		if isnumber(n) then
			return force_m
				and {n/100,'m','ftin',0,['abbr']='on'}
				or {n,'cm','ftin',0,['abbr']='on'}, mw.ustring.sub(s, c+2)
		end
		return '', unconverted
	end
	
	if m ~= nil and c == nil and f == nil and i == nil then
		local n = mw.ustring.sub(s, 1, m - 1)
		if isnumber(n) then
			return force_cm 
				and {n*100,'cm','ftin',0,['abbr']='on'}
				or {n,'m','ftin',0,['abbr']='on'}, mw.ustring.sub(s, m+1)
		end
		return '', unconverted
	end
	
	if f ~= nil and i ~=nil and m == nil then
		local n1 = mw.ustring.sub(s, 1, f - 1)
		local n2 = mw.ustring.sub(s, f+2, i - 1)
		if isnumber(n1) and isnumber(n2) then
			return (force_m or prefer_m)
				and {n1,'ft',n2,'in', 'm',2,['abbr']='on'}
				or {n1,'ft',n2,'in', 'cm',0,['abbr']='on'}, mw.ustring.sub(s, i+2)
		end
		return '', unconverted
	end
	
	if f ~= nil and i == nil and m == nil then
		local n = mw.ustring.sub(s, 1, f - 1)
		if isnumber(n) then
			return (force_m or prefer_m)
				and {n,'ft','m',2,['abbr']='on'}
				or {n,'ft','cm',0,['abbr']='on'}, mw.ustring.sub(s, f+2)
		end
		return '', unconverted
	end
	
	if i ~= nil and f == nil and m == nil then
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

function convert(frame, args)
	local targs, str = get_convert_args(args[1], args['prefer'] or '', args['enforce'] or '')

	if type(targs) == 'table' then
		return frame:expandTemplate{ title = 'convert', args = targs} .. str
	else
		return str
	end
end

function p.main(frame)
	return convert(frame, frame.args[1] and frame.args or frame:getParent().args)
end

return p