local p = {}

function p.wikirequests(frame)
	 -- Goal: given template parameters input, return a wikipedia page of specific page title
	 
	 pagetitle = 'Wikipedia Requests' -- Template namespace
	 header = "'''Requests for "
	 searchtype = ''
	 searchterm = ''
	 
	 for key, value in pairs(frame:getParent().args) do  -- iterate through arguments, pick out values
	 	searchtype = key
	 	searchterm = value
	 	if key == 'category' then
	 		pagetitle = pagetitle .. '/Category/' .. value
	 		header = header .. '[[:Category:' .. value
	 	elseif key == 'wikiproject' then
	 		pagetitle = pagetitle .. '/WikiProject/' .. value
	 		header = header .. '[[Wikipedia:' .. value
	 	elseif key == 'article' then
	 		pagetitle = pagetitle .. '/Article/' .. value
	 		header = header .. '[[' .. value
	 	end
 	end
 	
 	header = header .. "]] via [[Wikipedia:Wikipedia Requests|Wikipedia Requests]]:'''\n\n"
 
 	if pagetitle == 'Wikipedia Requests' then -- You end up with this when there are no parameters
 		body = 'You need to specify parameters.'
 	else
	 	if mw.title.makeTitle('Template', pagetitle).exists == true then
			body = frame:expandTemplate{ title = 'Template:' .. pagetitle, args = {} }
		else
	 		body = "''The list will be copied to Wikipedia soon''"
	 	end
 	end
 
 	footer = '\n\n' .. frame:expandTemplate{ title = 'Template:Clickable button 2', args = { url = 'https://wpx.wmflabs.org/requests/en/search?searchtype=' .. searchtype .. '&searchterm=' .. string.gsub(searchterm, ' ', '+') .. '&language=en', '… View full list', class='mw-ui-progressive mw-ui-quiet', style='color:#2962CB' } }
 	footer = footer .. frame:expandTemplate{ title = 'Template:Clickable button 2', args = { url = 'https://wpx.wmflabs.org/requests/en/add', '+ Add request', class='mw-ui-progressive mw-ui-quiet', style='color:#2962CB' } }
 	
 	content = header .. body .. footer
 	return content
 end
 
 return p