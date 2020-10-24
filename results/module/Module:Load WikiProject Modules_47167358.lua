local p = {}

function standardicon(modulename)
	index = {}
	-- Take modulename as input, returns corresponding icon filename
	-- Returns default icon if no icon is defined
	-- Grow the library! Add default icons as needed by adding this line below:
	-- index['MODULENAME'] = 'FILE NAME.ext'
	index['About'] = 'Information Noun 176431.svg'
	index['About us'] = 'Information Noun 176431.svg'
	index['Alerts'] = 'Bell icon.svg'
	index['Article alerts'] = 'Bell icon.svg'
	index['Article Alerts'] = 'Bell icon.svg'
	index['Partners'] = 'Handshake noun.svg'
	index['Partnerships'] = 'Handshake noun.svg'
	index['Discussions'] = 'Speechbubbles icon.svg'
	index['Events'] = 'Simpleicons Business calendar-with-a-clock-time-tools.svg' -- Is this PD-shapes?
	index['External Links'] = 'Link icon.svg'
	index['External links'] = 'Link icon.svg'
	index['Links'] = 'Link icon.svg'
	index['Maps'] = 'MapPin.svg'
	index['Metrics'] = 'ArticleCheck.svg'
	index['News'] = 'Calendar icon 2.svg'
	index['Offline App'] = 'Offline logo.svg'
	index['Press'] = 'Cite newspaper.svg'
	index['Recent changes'] = 'Clock icon.svg'
	index['Recent Changes'] = 'Clock icon.svg'
	index['Recognized content'] = 'RibbonPrize.svg'
	index['Recognized Content'] = 'RibbonPrize.svg'
	index['Related Projects'] = 'Contributions icon.svg' -- Not for use for the update bot, special use case, that expands the page	
	index['Related WikiProjects'] = 'Contributions icon.svg'
	index['Requests'] = 'Quotes icon.svg'
	index['Research'] = 'Microscope icon (black OCL).svg'
	index['Resources'] = 'Cite book.svg'
	index['Showcase'] = 'RibbonPrize.svg'
	index['Tasks'] = 'ListBullet.svg'
	index['Tools'] = 'Octicons-tools-minor.svg'
	index['Translations'] = 'Translation icon.svg'
	index['Watchlist'] = 'OpenEye icon.svg'
	index['Worklists'] = 'ListBullet.svg'
	for t, fn in pairs(index) do
		if t == modulename then
			return fn
		end
	end
	return 'Beta icon.svg' -- default if nothing matches
end

function editlinktest(modulename)
	no_edit_links = {'Discussions', 'Alerts', 'Showcase', 'Related WikiProjects'} -- no edit link for these standard modules
	
	for _, l in pairs(no_edit_links) do
		if l == modulename then
			return 'no'
		end
	end
	return 'yes'
end

function p.build(frame)
	title = ''
	intro = ''
	image = ''
	color = '#6af' -- default value
	displaymode = 'normal' -- default value
	modules = {}
	for key, value in pairs(frame:getParent().args) do  -- iterate through arguments, pick out values
		if key == 'title' then
			title = value
		elseif key == 'intro' then
			intro = value
		elseif key == 'image' then
			image = value
		elseif key == 'color' then
			color = value
		elseif key == 'displaymode' then
			displaymode = value
    	elseif string.find(key, 'module') ~= nil then  -- matches module1, module2, etc.
    		id = string.gsub(key, 'module', '')
    		id = tonumber(id)
    		modules[id] = value
		end
	end

	-- Rendering table of contents and body
	toc_args = {width = 80, height = 55} -- passed into Image Array module
	toc_args['font-size'] = '100%'
	toc_args['margin'] = 0
	body = ""
	
	-- Load a Table of Contents entry, transclude module, for each named module
	counter = 0
	for _, module in pairs(modules) do
		counter = counter + 1
		toc_args['image' .. counter] = standardicon(module)
		toc_args['alt' .. counter] = module
		if displaymode == "womeninred" then
			if module == "Metrics" or module == "Showcase" or module == "About us" or module == "Press" or module == "Research" or module == "External links" then
				toc_args['link' .. counter] = "Wikipedia:WikiProject Women in Red/" .. module
			else
				toc_args['link' .. counter] = "#" .. module
			end
		else
			toc_args['link' .. counter] = "#" .. module
		end
		toc_args['caption' .. counter] = "[[" .. toc_args['link' .. counter] .. "|" .. module .. "]]"
		if module == "Related WikiProjects" then
			-- Load the appropriate subpage of [[Wikipedia:Related WikiProjects]]
			moduletitle = 'Related WikiProjects' .. '/' .. title
			moduletitle_encoded = string.gsub('Wikipedia:' .. moduletitle, ' ', '_')
			body = body .. "\n" .. frame:expandTemplate{ title = 'WPX header', args = { module, color = color, modulename = moduletitle_encoded, editlink = editlinktest(module) } }
			body = body .. "\n" .. frame:expandTemplate{ title = "Wikipedia:Related WikiProjects/" .. title, args = {color} }
		else
			if displaymode == "normal" or ( displaymode == "womeninred" and module ~= "Metrics" and module ~= "Showcase" and module ~= "About us" and module ~= "Press" and module ~= "Research" and module ~= "External links" ) then
				moduletitle = title .. '/' .. module
				moduletitle_encoded = string.gsub('Wikipedia:' .. moduletitle, ' ', '_')
				body = body .. "\n" .. frame:expandTemplate{ title = 'WPX header', args = { module, color = color, modulename = moduletitle_encoded, editlink = editlinktest(module) } }
				if mw.title.makeTitle('Wikipedia', moduletitle).exists == true then
					body = body .. "\n" .. frame:expandTemplate{ title = 'Wikipedia:' .. moduletitle, args = {color} } .. "\n<div style='clear:both;'></div>"
				else
					-- Is module in question a Standard Module? If so, load the template with corresponding editintro
					if mw.title.makeTitle('Template', 'WPX module/' .. module).exists == true then
						preload = '&preload=Template:WPX_module/' .. string.gsub(module, ' ', '_')
						editintro = '&editintro=Template:WPX_editintro/' .. string.gsub(module, ' ', '_')
					else
						preload = '' -- no preload
						editintro = '&editintro=Template:WPX_editintro/Generic' -- generic editintro
					end
					-- Create notice
					create_url = '//en.wikipedia.org/wiki/Wikipedia:' .. string.gsub(moduletitle, ' ', '_') .. '?action=edit' .. preload .. editintro
					create_button = frame:expandTemplate{ title = 'Template:Clickable button 2', args = {'Create Module', url = create_url, class = 'mw-ui-progressive' } }
					body = body .. '[[Wikipedia:' .. moduletitle .. ']] does not exist. ' .. create_button
				end
			end
		end
		
	end
	
	toc_args['perrow'] = counter -- sets length of image array to the number of icons
	toc = "<div style='margin-bottom:4em;'>" .. frame:expandTemplate{ title='Image_array', args = toc_args } .. "</div><div style='clear:both;'></div>"

	-- Adding header
	header = "__NOTOC__\n<div style='display: flex; display: -webkit-flex; flex-flow: row wrap; -webkit-flex-flow: row wrap;'>" -- top container
	if displaymode == "womeninred" then
		header = header .. "<div style='flex: 1 0; -webkit-flex: 1 0; border-top: solid .7em " .. color .. ";'>" -- intro
	else
		header = header .. "<div style='flex: 1 0; -webkit-flex: 1 0; padding-bottom: 3em; border-top: solid .7em " .. color .. ";'>" -- intro
	end
	-- Adding project icon
	header = header .. "<div class='nomobile' style='float:left; margin-top: 1em; margin-right: 2em; margin-bottom: 1em; text-align: center;'>"
	header = header .. image .. "</div>"
	-- Adding project title
	header = header .. "<div style='font-size: 120%; padding: 0;'>" -- header
    header = header .. "<h1 style='font-weight: bold; border-bottom: none; margin:0; padding-top:0.5em;'>" .. title .. "</h1></div>"
    if displaymode == "womeninred" then
    	header = header .. toc
    end
	-- Adding intro blurb
	header = header .. "<div style='margin-top: 1em; font-size: 110%;'>"
	header = header .. intro .. "</div>"
	-- Adding announcement section
	if mw.title.makeTitle('Wikipedia', title .. "/" .. "Announcements").exists == true then
		header = header .. frame:expandTemplate{ title = 'Wikipedia:' .. title .. "/" .. "Announcements", args = { } }
	end
	header = header .. "</div>"
	-- Adding member box
	header = header .. "<div style='flex: 0 1; -webkit-flex: 0 20em;'>"
	header = header .. frame:expandTemplate{ title = 'WPX member box', args = { } }
	header = header .. "</div>"
	-- Closing off header
	header = header .. "</div></div>"

	-- Assembling parts
	if displaymode == "womeninred" then
		contents = header .. body
	else
		contents = header .. toc .. body
	end
	return contents
end

return p