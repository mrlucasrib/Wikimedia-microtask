local function buildquery(frame, target)
	local textToDisplay, leftLink, rightLink, runQueryRightAway, itemObject, itemID, query, coord, bbox, remark, overpassUrl, primitives, timeout, style, logo
	local args = frame.args
	
	if args.display then
		-- text to display on link
		textToDisplay = ' ' .. args.display
	else
		textToDisplay = ''
	end
	if args.timeout then
		timeout = '[timeout:' .. args.timeout .. '][out:json];\n'
	else
		timeout = '[timeout:20][out:json];\n'
	end
	if args.link and args.link == 'no' then
		-- just return the url
		leftLink = ''
		rightLink = ''
		textToDisplay = ''
	else
		leftLink = '['
		rightLink = ']'
	end
	if args.run and args.run == 'no' then
		-- don't run immediately
		runQueryRightAway = ''
	else
		runQueryRightAway = '&R'
	end
	if frame.args.overpass then
		itemID = ""
		itemObject = nil
	else
		if args.id then
			-- build query for specific Q-item(s) 
			itemID = args.id
			pcall(function () itemObject = mw.wikibase.getEntityObject(mw.text.split(itemID,";")[1]) end)
		else
			itemObject = mw.wikibase.getEntityObject()
			if itemObject == nil then
				return "This page doesn't have a wikidata entry"
			end
			-- build query for current page
			itemID = itemObject.id
		end
	end
	-- Always perform a regular expression based search
    -- The data may contain multiple values
    if frame.args.overpass == nil then
		itemID = '"~"(^|;)(' .. itemID:gsub(";", "\|") .. ')(;|$)'
		leftbracket = '["'
		rightbracket = '"]'
	else
		leftbracket = ''
		rightbracket = ''
	end

	if args.query then
		-- user can add their own tags to filter on
		query = args.query
	else
		if frame.args.overpass then
			return "If you invoke with overpass, you have to include a query="
		end
		query = ''
	end
	if args.coord and not(args.limitToBBOX=='no') then
		-- The user can provide coordinates and a zoom factor
		coord = '&C=' .. args.coord
		-- In that case we can limit the search to the area in view
		bbox = '({{bbox}})'
		-- and tell them how to search wider.
		remark = ' // remove the ' .. bbox .. 'if you want the query to be executed globally'
	else
		coord = ''
		bbox = ''
		remark = ''
	end
	overpassUrl = timeout .. '(\n'
	-- if the user specifies prim(itives), but then leaves the string empty, abort
	if args.prim then
		if args.prim == '' then
			return "Please indicate which primitives you want to query for"
		end
		primitives = args.prim
	else
		primitives = 'nwr'
	end

	if primitives:find("n") then
		-- Include nodes
		overpassUrl = overpassUrl .. 'node' .. leftbracket .. target .. itemID .. rightbracket .. query .. bbox .. ';' .. remark .. '\n'
	end
	if primitives:find("w") then
		-- Include ways
		overpassUrl = overpassUrl .. 'way' .. leftbracket .. target .. itemID .. rightbracket .. query .. bbox .. ';\n'
	end
	if primitives:find("r") then
		-- Include relations
		overpassUrl = overpassUrl .. 'relation' .. leftbracket .. target .. itemID .. rightbracket .. query .. bbox .. ';\n>>;\n'
	end	
	overpassUrl = overpassUrl .. ');\n'
	overpassUrl = overpassUrl .. 'out geom;\n'
	if args.style then
			style = args.style
	else
		if args.logo then
			logo = "  icon-image: url(" .. args.logo .. ');\n'
		else
			if itemObject then
				logo = tostring(itemObject:formatPropertyValues('P154')['value']):gsub("&#39;", "'")
			end
			if logo and not(logo == '') then
				logo = '  icon-image: url("https://commons.wikimedia.org/wiki/Special:Redirect/file/'.. logo .. '");\n'
			end
		end
		if logo then
			style = "node [".. target .."]{\n  text: name;\n".. logo .. "  icon-width: 32;}"
		end
	end
	if style then
		overpassUrl = overpassUrl .. '{{style:\n' .. style .. '\n}}\n'
	end

	return leftLink .. 'http://overpass-turbo.eu/?Q=' .. mw.uri.encode(overpassUrl, "PATH" ) .. coord .. runQueryRightAway .. textToDisplay .. rightLink
end

local p = {}

function p.overpass( frame )
	frame.args.overpass = true
	return buildquery(frame, '')
end

function p.wd( frame )
	return buildquery(frame, 'wikidata')
end

function p.pt( frame )
 	frame.args.style = "node {\n  opacity: 0;\n  fill-opacity: 0;}\nnode[highway=bus_stop], way[highway=bus_stop]{\n  text: name;\n  icon-image: url('icons/maki/bus-18.png');\n  icon-width: 18;}"
 	frame.args.prim = "r"
 	frame.args.timeout = 50
	return buildquery(frame, 'wikidata')
end

function p.etym( frame )
	return buildquery(frame, 'name:etymology:wikidata')
end

function p.subject( frame )
	return buildquery(frame, 'subject:wikidata')
end

function p.artist( frame )
	return buildquery(frame, 'artist:wikidata')
end

function p.architect( frame )
	return buildquery(frame, 'architect:wikidata')
end

function p.operator( frame )
	return buildquery(frame, 'operator:wikidata')
end

function p.brand( frame )
	return buildquery(frame, 'brand:wikidata')
end

return p