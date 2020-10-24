local getArgs = require('Module:Arguments').getArgs
 
local p = {}
 
local function makeInvokeFunction(funcName)
	-- makes a function that can be returned from #invoke, using
	-- [[Module:Arguments]].
	return function (frame)
		local args = getArgs(frame, {parentOnly = true})
		return p[funcName](args)
	end
end
 
local function colorboxLinked(color,text,link)
	return '[['..link..'|<span role="img" aria-label="'..text..'" style="border:1px solid darkgray;-ms-user-select:none;-webkit-user-select:none;user-select:none;background-color:'..color..'" title="'..text..'">&nbsp;&nbsp;&nbsp;&nbsp;</span>]]&nbsp;'
end
 
local function colorboxUnlinked(color)
	return '<span style="border:1px solid darkgray;-ms-user-select:none;-webkit-user-select:none;user-select:none;background-color:'..color..'">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;'
end

local t1 = {
	['A Line'] = { 'blue line', 'blue', 'a line', 'line a', 'a', icon='img_circle', dab=true, },
	['B Line'] = { 'red line', 'red', 'b line', 'line b', 'b', icon='img_circle', dab=true, },
	['C Line'] = { 'green line', 'green', 'c line', 'line c', 'c',  icon='img_circle', dab=true, },	
	['D Line'] = { 'purple line', 'purple', 'd line', 'line d', 'd', icon='img_circle', dab=true, },
	['E Line'] = { 'expo line', 'expo', 'e line', 'line e', 'e', icon='img_circle', dab=true, },	
	['G Line'] = { 'orange line', 'orange', 'g line', 'line g', 'g', icon='img_square', dab=true, },	
	['J Line'] = { 'silver line', 'silver',  'j line', 'line j', 'j', icon='img_square', dab=true, },	
	['Crenshaw/LAX Line'] = { 'crenshaw/lax line', 'crenshaw/lax', 'crenshaw line', 'crenshaw', 'k line', 'line k', 'k', icon='crenshaw', },
	['L Line'] = { 'gold line', 'gold', 'l line', 'line l', 'l', icon='img_circle', dab=true, },	
	['Harbor Transitway'] = { 'harbor transitway', 'harbor', color='#B8860B', icon='colorbox', },
	['El Monte Busway'] = { 'el monte busway', 'el monte', color='#B8AD93', icon='colorbox', },
	['Regional Connector Transit Corridor'] = { 'regional connector transit corridor', 'regional connector', 'regional', color='#604020', icon='colorbox', },
}
 
p.icon = makeInvokeFunction('_icon')
 
function p._icon(args)
	local link
	local code = args[1] or ''
	local text = args[2]
	if text then text = '('..text..')' else text = '' end
	local showtext = args.showtext
	local alt
	for k, v in pairs(t1) do
		for _, name in ipairs(v) do
			if mw.ustring.lower(code) == name then
				if v.dab == true then
					if showtext then
						link = ''
						alt = 'alt='
						showtext = '[['..k..' (Los Angeles Metro)|'..k..']]'
					else
						link = k..' (Los Angeles Metro)'
						alt = k
						showtext = ''
					end
				else
					if showtext then
						link = ''
						alt = 'alt='
						showtext = '[['..k..']]&nbsp;'
					else
						link = k
						alt = k
						showtext = ''
					end
				end
				if v.icon == 'colorbox' then
					if showtext then
						return colorboxUnlinked(v.color)..showtext..text
					else
						return colorboxLinked(v.color,k,k)..text
					end
				elseif v.icon == 'crenshaw' then
					return '[[File:LACMTA_Circle_K_Line.svg|'..(args.size or 17)..'px|link='..link..'|'..alt..']]&nbsp;'..showtext..text
				elseif v.icon == 'img_circle' then
					return '[[File:LACMTA Circle '..k..'.svg|'..(args.size or 17)..'px|link='..link..'|'..alt..']]&nbsp;'..showtext..text
				elseif v.icon == 'img_square' then
					return '[[File:LACMTA Square '..k..'.svg|'..(args.size or 17)..'px|link='..link..'|'..alt..']]&nbsp;'..showtext..text
				end
			end
		end
	end
	return colorboxLinked('#fff',code..' Line',code..' Line (Los Angeles Metro)')..text
end
 
return p