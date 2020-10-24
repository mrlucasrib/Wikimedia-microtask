local p = {}
local yesno = require("Module:Yesno")

function get_portalicon(portalicon)
	if portalicon == nil then
		return ''
	end
	return '<span style="padding:0.3em; display:inline-block;margin-right:0.5em;">' .. portalicon .. '</span>'
end

function converttolinearrgb(c)
	c = tonumber(c, 16)
	c = c / 255.0
	if c <= 0.03928 then
		c = c/12.92
	else
		c = ((c+0.055)/1.055) ^ 2.4
	end
	
	return c
end

function p.render(frame)
	-- Default values
	portalname = 'Portal'
	tabs = {}
	subtabs = {}
	wrc = 0

	-- Default values (customizations)
	themecolor = '#54595d'
	headerstyle = ''
	tabsicons = {}
	wrcadditional = nil
	
	-- Populating variables
	for key, value in pairs(frame:getParent().args) do
		if key == 'portalname' then
			portalname = value
		elseif key == 'portalicon' then
			portalicon = value
		elseif key == 'active' then
			active = tonumber(value)
		elseif key == 'wrc' then
			wrc = value
		elseif key == 'themecolor' then
			themecolor = value
		elseif key == 'headerstyle' then
			headerstyle = value
		elseif key == 'hidenav' then
			hidenav = yesno(value)
		elseif key == 'hidesubnav' then
			hidesubnav = yesno(value)
		elseif key == 'wrcadditional' then
			wrcadditional = value
		elseif string.find(key, 'tab') ~= nil
		and string.find(key, 'subtab') == nil then  -- matches tab1, tab2, ...
    		id = string.gsub(key, 'tab', '')
    		id = tonumber(id)
    		tabs[id] = value
    	elseif string.find(key, 'icon') ~= nil then -- matches icon1, icon2, etc.
    		id = string.gsub(key, 'icon', '')
    		id = tonumber(id)
    		tabsicons[id] = value
    	elseif string.find(key, 'subtab') ~= nil then -- matches subtab1-1, etc.
    		id = string.gsub(key, 'subtab', '')
    		-- Subtab params take the form [prime tab]-[sub tab]
    		id = mw.text.split(id, '-')
    		primetab = tonumber(id[1])
    		subtab = tonumber(id[2])
    		if subtabs[primetab] == nil then
    			subtabs[primetab] = {}
    		end
    		subtabs[primetab][subtab] = value
    	end
	end
	
	-- Constructing header
	-- Relevant variables: portalname, wrc, themecolor, headerstyle
	
	-- The text color in the header is automatically chosen based on the best contrast
	-- https://stackoverflow.com/questions/3942878/how-to-decide-font-color-in-white-or-black-depending-on-background-color
	headertextcolor = '#fff'
	
	rgb = string.gsub(themecolor, '#', '')
	rgb = mw.text.split(rgb, '')
	if #rgb == 6 then
		r = rgb[1] .. rgb[2]
		g = rgb[3] .. rgb[4]
		b = rgb[5] .. rgb[6]
	elseif #rgb == 3 then
		r = rgb[1] .. rgb[1]
		g = rgb[2] .. rgb[2]
		b = rgb[3] .. rgb[3]
	end
	r = converttolinearrgb(r)
	g = converttolinearrgb(g)
	b = converttolinearrgb(b)
	
	luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
	
	if luminance > 0.179 then
		headertextcolor = '#000'
	end

	-- Applying customizations to headerstyle
	if headerstyle ~= '' then
		headerstyle = ' ' .. headerstyle
	end
	headerstyle = 'font-size:1.6875em; border-radius:2px; font-weight:bold;'
		.. 'background:' .. themecolor .. '; color:' .. headertextcolor
		.. '; padding:0.25em;'.. headerstyle
	
	header = '<div style="' .. headerstyle .. '">'
	header = header .. portalname .. get_portalicon(portalicon) .. '</div>'
	
	if wrc == '1' or wrc == 1 or wrc == 'true' or wrc == true or wrc == 'yes' then
		badgeargs = {}
		if wrcadditional ~= nil then
			badgeargs['additional'] = wrcadditional
		end

		header = frame:expandTemplate{
			title = 'Wikimedia Resource Center badge',
			args = badgeargs }
			.. '\n\n' .. header
	end
	
	-- Constructing the rest
	-- Relevant variables: themecolor tabs tabsicons active subtabs

	body = ''

	if hidenav ~= true then
		body = body .. '<div style="font-size:1.125em; margin-bottom:1.125em;>'
		
		for index, pagelink in ipairs(tabs) do
			-- Open TOC entry container
			containerstyle = 'display:inline-block; position:relative; vertical-align:top;'
			body = body .. '<div style="' .. containerstyle .. '">'
			
			-- Create the tab itself
			entrystyle = 'display:inline-block; margin:1em; padding-bottom:0.5em; font-weight:bold;'
			if index == active then
				if subtabs[index] == nil or hidesubnav == true then
					entrystyle = entrystyle .. ' border-bottom:0.3em solid ' .. themecolor .. ';'
				else
					entrystyle = entrystyle .. ' margin-bottom:0;'
				end
			else
				entrystyle = entrystyle .. '  border-bottom:0.3em solid #c8ccd1;'
			end
			
			icon = ''
			if tabsicons[index] ~= nil then
				icon = '<span style="margin-right:0.75em;">'
				icon = icon .. tabsicons[index] .. '</span>'
			end
			
			body = body
				.. '<span style="' .. entrystyle .. '">'
				.. icon .. pagelink
				.. '</span>'
			
			-- If the tab is active, show the subnav if there is any
			
			if index == active and subtabs[index] ~= nil and hidesubnav ~= true then
				body = body .. '<div style="font-size:95%; margin-left:1em; margin-right:1em; padding-top:1.125em; padding-bottom:1.125em; border-top:0.35em solid ' .. themecolor .. '; border-bottom:0.35em solid' .. themecolor .. ';">'
				
				for subindex, subpagelink in ipairs(subtabs[index]) do
					body = body .. subpagelink
					if subindex ~= #subtabs[index] then
						body = body .. '<br />'
					end
				end
				
				body = body .. '</div>'
			end
			
			-- Close TOC entry container
			body = body .. '</div>'
		end
	
		body = body .. '</div>'
	end

	return '<div>' .. header .. body .. '</div><div style="clear:both;"></div>'
end

return p