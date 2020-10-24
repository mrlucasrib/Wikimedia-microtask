-- This module implements/replaces
-- [[Template:Lunar quadrangle]]
-- [[Template:Mars quadrangle]]
-- [[Template:Venus quadrangle]]
local p = {}

local function moonquad(lat, lon)
	local function LQ(n)
		if n < 10 then 
			return 'LQ0' .. n
		else 
			return 'LQ' .. n
		end
	end
	-- Note: requires positive longitude coordinates
	if lat > 65 then
		return LQ(1)
	elseif lat > 30 then
		if lon >= 180 then
			return LQ(2 + math.floor( (lon - 180) / 60 ) )
		else
			return LQ(5 + math.floor( lon / 60 ) )
		end
	elseif lat >= 0 then
		if lon >= 180 then
			return LQ(8 + math.floor( (lon - 180) / 45 ) )
		else
			return LQ(12 + math.floor( lon / 45 ) )
		end
	elseif lat >= -30 then
		if lon >= 180 then
			return LQ(16 + math.floor( (lon - 180) / 45 ) )
		else
			return LQ(20 + math.floor( lon / 45 ) )
		end
	elseif lat >= -65 then
		if lon >= 180 then
			return LQ(24 + math.floor( (lon - 180) / 60 ) )
		else
			return LQ(27 + math.floor( lon / 60 ) )
		end
	else
		return LQ(30)
	end

	return 'Error'
end

local function marsquad(lat, lon)
	-- Note: requires positive longitude coordinates
	if lat > 65 then 
		return 'Mare Boreum'
	elseif lat > 30 then 
		if lon < 60 then return 'Ismenius Lacus'
		elseif lon < 120 then return 'Casius'
		elseif lon < 180 then return 'Cebrenia'
		elseif lon < 240 then return 'Diacria'
		elseif lon < 300 then return 'Arcadia'
		else return 'Mare Acidalium' end
	elseif lat >= 0 then 
		if lon < 45 then return 'Arabia'
		elseif lon <  90 then return 'Syrtis Major'
		elseif lon < 135 then return 'Amenthes'
		elseif lon < 180 then return 'Elysium'
		elseif lon < 225 then return 'Amazonis'
		elseif lon < 270 then return 'Tharsis'
		elseif lon < 315 then return 'Lunae Palus'
		else return 'Oxia Palus' end
	elseif lat >= -30 then 
		if lon < 45 then return 'Sinus Sabaeus'
		elseif lon <  90 then return 'Iapygia'
		elseif lon < 135 then return 'Mare Tyrrhenum'
		elseif lon < 180 then return 'Aeolis'
		elseif lon < 225 then return 'Memnonia'
		elseif lon < 270 then return 'Phoenicis Lacus'
		elseif lon < 315 then return 'Coprates'
		else return 'Margaritifer Sinus' end
	elseif lat >= -65 then 
		if lon < 60 then return 'Noachis'
		elseif lon < 120 then return 'Hellas'
		elseif lon < 180 then return 'Eridania'
		elseif lon < 240 then return 'Phaethontis'
		elseif lon < 300 then return 'Thaumasia'
		else return 'Argyre' end
	else
		return 'Mare Australe'
	end
end

local function mercuryquad(lat, lon)
	-- Note: requires positive longitude coordinates
	if lat >= 66 then
		return 'Borealis'
	elseif lat >= 21 then
		if lon < 90 then return 'Hokusai'
		elseif lon < 180 then return 'Raditladi'
		elseif lon < 270 then return 'Shakespeare'
		else return 'Victoria' end
	elseif lat > -21 then
		if lon < 72 then return 'Derain'
		elseif lon < 144 then return 'Eminescu'
		elseif lon < 216 then return 'Tolstoj'
		elseif lon < 266 then return 'Beethoven'
		else return 'Kuiper' end
	elseif lat > -66 then
		if lon < 90 then return 'Debussy'
		elseif lon < 180 then return 'Neruda'
		elseif lon < 270 then return 'Michelangelo'
		else return 'Discovery' end
	else
		return 'Bach'
	end

	return 'Error'
end

local function venusquad(lat, lon)
	-- Note: requires positive longitude coordinates
	if lat > 57 then
		return 'Ishtar Terra'
	elseif lat >= 0 then
		if lon < 60 or lon >= 300 then return 'Sedna Planitia'
		elseif lon < 180 then return 'Niobe Planitia'
		else return 'Guinevere Planitia' end
	elseif lat >= -57 then
		if lon < 60  or lon >= 300 then return 'Lavinia Planitia'
		elseif lon < 180 then return 'Aphrodite Terra'
		else return 'Helen Planitia' end
	else
		return 'Lada Terra'
	end
end

local function quad_name(lat, lon, globe)
	-- lower case
	globe = globe:lower() or ''

	-- convert to numbers
	lat = tonumber(lat) or ''
	lon = tonumber(lon) or ''

	-- get the quad name
	if lat ~= '' and lon ~= '' and globe ~= '' then
		if lon < 0 then lon = lon + 360 end
		if lon < 0 or lon > 360 then
			return 'Error'
		end
		if globe == 'mars' then
			return marsquad(lat, lon)
		elseif globe == 'mercury' then
			return mercuryquad(lat, lon)
		elseif globe == 'moon' then
			return moonquad(lat, lon)
		elseif globe == 'venus' then
			return venusquad(lat, lon)
		end
	end

	return 'Error'
end

function p.category(frame)
	local args = frame.args
	local res = quad_name(args['lat'] or '', args['lon'] or '', args['globe'] or '')
	
	if res ~= 'Error' then
		if args['nameonly'] and args['nameonly'] ~= '' then
			return res
		else
			return '[[Category:' .. res .. ' quadrangle]]'
		end
	end

	return '<span class="error">Error</span>'
end

function p.name(frame)
	local args = frame.args
	local res = quad_name(args['lat'] or '', args['lon'] or '', args['globe'] or '')
	
	if res ~= 'Error' then
		return res
	end
	return '<span class="error">Error</span>'
end

return p