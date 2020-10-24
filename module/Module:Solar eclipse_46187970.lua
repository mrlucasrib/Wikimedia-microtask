local eclipse = {}
local args = {}

local data_module_prefix = "Module:Solar eclipse/db/"

local function ifnotempty(s,a,b)
	if (s and s ~= '') then
		return a
	else
		return bs
	end
end

local function ifexist(page)
    if not page then return false end
    if mw.title.new(page).exists then return true end
    return false
end

local function parsedate(y,m,d)
	local lang = mw.language.getContentLanguage()
	d = (tonumber(d) < 10) and ('0' .. tonumber(d)) or (d)
	m = (tonumber(m) < 10) and ('0' .. tonumber(m)) or (m)
	local success, result = pcall(lang.formatDate, lang, 'F j, Y', y .. '-' .. m .. '-' .. d)
	return success and result or nil
end

local function parsecoord(frame, s)
	local lat = s:match('^%s*([%d][%d.]*)%s*[NS]%s*[%d][%d.]*[EW]%s*$')
	local  NS = s:match('^%s*[%d][%d.]*%s*([NS])%s*[%d][%d.]*[EW]%s*$')
	local lon = s:match('^%s*[%d][%d.]*%s*[NS]%s*([%d][%d.]*)[EW]%s*$')
	local  EW = s:match('^%s*[%d][%d.]*%s*[NS]%s*[%d][%d.]*([EW])%s*$')
	if( lat and NS and lon and EW ) then
		return frame:expandTemplate{ title = 'coord', args = {lat, NS, lon, EW, 'type:landmark'} }
	else
		return s
	end
end

local function parsekm(frame, s)
	if(s and s:match('^%s*[%d][%d.]*%s*$')) then
		return frame:expandTemplate{ title = 'convert', args = {s, 'km', 'mi', abbr = 'on'} }
	else
		if(s and s ~= '') then
			return s .. ' km'
		else
			return nil
		end
	end
end

local function parsetime(s)
	if(s and s ~= '') then
		local min = s:match('^%s*([%d][%d]*)m%s*[%d][%d]*s%s*$')
		local sec = s:match('^%s*[%d][%d]*m%s*([%d][%d]*)s%s*$')
		if( min and sec ) then
			return tostring(tonumber(min)*60 + tonumber(sec)) .. '&nbsp;sec' ..
				' (' .. min .. '&nbsp;m ' .. sec .. '&nbsp;s)'
		end
	end
	return s
end

local function cataloglink(c, y, m, d)
	y, m, d = tonumber(y), tonumber(m), tonumber(d)
	if tonumber(c) and y and m and d then
		d = (d < 10) and ('0' .. d) or d
		m = (m < 10) and ('0' .. m) or m
		return '[https://eclipse.gsfc.nasa.gov/SEsearch/SEdata.php?Ecl=+' .. y .. m .. d .. ' ' .. c .. ']'
	else
		return c
	end
end

local function loadsolardb(frame, s)
	local yearstr = s:match('^%s*([%d][%d][%d][%d])[A-Z][a-z][a-z][%d][%d]%s*$') or ''
	local function setarg(k, v)
		if(v and v ~= '') then args[k] = v end
	end
	if( yearstr ~= '' ) then
		local dbsubpage = math.floor( (tonumber(yearstr) - 1) / 50 ) * 5
		local dbpage  = data_module_prefix .. tostring( dbsubpage )
		if (ifexist(dbpage)) then
			local data = mw.loadData(dbpage)
			local dargs = data[s]
			setarg('date', parsedate(dargs['y'], dargs['m'] or dargs['m3'] or dargs['m2'], dargs['d'] or dargs['d2']))
			setarg('image', (dargs['Ph'] and dargs['Ph'] ~= '') and '[[File:' .. dargs['Ph']  .. '|320px]]' or nil)
			setarg('caption', dargs['PhCap'])
			setarg('map', (dargs['Map'] and dargs['Map'] ~= '') and '[[File:' .. dargs['Map']  .. '|320px]]' or nil)
			setarg('map_caption', 'Map')
			setarg('type_ref', '')
			setarg('cat', cataloglink(dargs['Cat'], dargs['y'], dargs['m'] or dargs['m3'] or dargs['m2'], dargs['d'] or dargs['d2']) )
			setarg('nature', dargs['Ty'])
			setarg('gamma', dargs['Gam'])
			setarg('magnitude', dargs['Mag'])
			setarg('saros', dargs['Saros'] and '[[Solar Saros ' .. dargs['Saros'] .. '|'  .. dargs['Saros'] .. ']]')
			setarg('saros_sequence', dargs['Mem'])
			setarg('saros_total', dargs['Max'])
			setarg('max_eclipse_ref', '')
			setarg('duration', parsetime(dargs['Dur']))
			setarg('location', '')
			setarg('coords', parsecoord(frame,dargs['Loc']))
			setarg('max_width', parsekm(frame,dargs['Wid']))
			setarg('times_ref', '')
			setarg('start_partial', dargs['TiPB'])
			setarg('start_total', dargs['TiTB'])
			setarg('start_central', '')
			setarg('greatest_eclipse', dargs['TiG'])
			setarg('end_central', '')
			setarg('end_total', dargs['TiTE'])
			setarg('end_partial', dargs['TiPE'])
		end
	end
end

local function infobox(frame)
	local abovestr = ifnotempty(args['date'], 
		"Solar eclipse of " .. (args['date'] or ''),
		"For instructions on use, see [[Template:Infobox Solar eclipse]]")
	local bgcolor = args['background'] or args['bgcolour'] or ''
	local mapstr = ifnotempty(args['map'],
		"<div style='padding-bottom:0.5em;'>" .. 
		(args['map'] or '') .. ifnotempty(args['map_caption'], 
			"<div style='line-height:1.2em; padding-top:0.1em;'>" ..
			(args['map_caption'] or '') .. "</div>", '') .. '</div>')

	return frame:expandTemplate{ title = 'infobox', args = {
		["bodyclass"] = "vevent",
		["bodystyle"] = "width:25em; text-align:left; font-size:90%;",
		["above"] = abovestr,
		["aboveclass"] = "summary",
		["abovestyle"] = "padding-bottom:0.25em; background:" .. bgcolor .. "; line-height:1.2em; text-align:center; font-size:115%;",
------------------ Images and maps ------------------
		["image"] = args['image'] or '',
		["imagestyle"] = "padding-bottom:0.5em;",
		["caption"] = args['caption'] or '',
		["headerstyle"] = "background:#eee; font-size:105%;",
		["data1"] = mapstr,
------------- Type of eclipse and saros -------------
		["header2"] = "Type of eclipse" .. (args['type_ref'] or ''),
		["label3"]  = "Nature",
		["data3"]   = args['nature'] or '',
		["label4"]  = "[[Gamma (eclipse)|Gamma]]",
		["data4"]   = args['gamma'] or '',
		["label5"]  = "[[Magnitude of eclipse|Magnitude]]",
		["data5"]   = args['magnitude'] or '',
------------------ Maximum eclipse ------------------
		["header7"] = "Maximum eclipse" .. (args['max_eclipse_ref'] or ''),
		["label8"] = "Duration",
		["data8"] = args['duration'] or '',
		["label9"] = "Location",
		["data9"] = args['location'] or '',
		["class9"] = "location",
		["label10"] = "Coordinates",
		["data10"] = args['coords'] or '',
		["label11"] = "Max.&nbsp;width of&nbsp;band",
		["data11"] = args['max_width'] or '',
----------------------- Times -----------------------
		["header12"] = "Times ([[UTC]])" .. (args['times_ref'] or ''),
		["label13"] = "(P1) Partial begin",
		["data13"] = args['start_partial'] or '',
		["label14"] = "(U1) Total begin",
		["data14"] = args['start_total'] or '',
		["label15"] = "(U2) Central begin",
		["data15"] = args['start_central'] or '',
		["label16"] = "Greatest eclipse",
		["data16"] = args['greatest_eclipse'] or '',
		["label17"] = "(U3) Central end",
		["data17"] = args['end_central'] or '',
		["label18"] = "(U4) Total end",
		["data18"] = args['end_total'] or '',
		["label19"] = "(P4) Partial end",
		["data19"] = args['end_partial'] or '',
------------------------ Event references -------------------------
		["header20"] = "References",
		["label21"] = "[[Saros (astronomy)|Saros]]",
		["data21"] = (args['saros'] or '') 
			.. " (" .. (args['saros_sequence'] or '') .. " of " .. (args['saros_total'] or '') .. ")",
		["label22"] = "Catalog # (SE5000)",
		["data22"] = args['cat'] or '',
		} }
	
end

function eclipse.box(frame)
	args = require('Module:Arguments').getArgs(frame, {
			wrappers = 'Template:Infobox solar eclipse'
		})

	if( args['2'] and args['2'] ~= '') then
		loadsolardb(frame,args['2'])
	elseif( args['1'] and args['1'] ~= '') then
		loadsolardb(frame,args['1'])
	end
	
	return infobox(frame)
end

return eclipse