local p = {}

local format = string.format -- Local version of string formatting function

local function hatnote(args)
	local insert = table.insert
	local text = {args.region_note}
	local tense
	
	local hatnoteArg = args.hatnote
	if hatnoteArg == 'off' then
		insert(text, '')
	elseif hatnoteArg then
		insert(text, hatnoteArg .. "&nbsp;")
	else
		local indep_city = args.indep_city
		local sub1 = args.sub1
		local sub2 = args.sub2
		if indep_city or sub1 or sub2 then
			local region = args.region
			tense = args.former == 'yes'
			local verb = tense and 'was' or 'is'
			insert(text, format("The entire %s %s in ", args.type or 'route', verb))
			if indep_city then
				insert(text, format("[[%s, %s|%s]]", indep_city, region, indep_city))
			else
				local sub1name = args.sub1name
				if sub2 then
					insert(text, "[[" .. sub2)
					local area = args.area
					if area then
						insert(text, format(" (%s)", area))
					end
					if args.sub1dab == 'yes' then
						insert(text, format(", %s %s", sub1, sub1name))
					end
					insert(text, format(", %s|%s]]", region, sub2))
				end
				if sub1 then
					if sub2 then
						insert(text, ', ')
					end
					insert(text, format("[[%s %s, %s|%s %s]]", sub1, sub1name, region, sub1, sub1name))
				end
			end
		insert(text, '. ')
		insert(text, args.sub1_ref)
		insert(text, args.sub2_ref)
		end
	end
	
	if args.unnum == 'yes' then
		insert(text, format("All exits %s unnumbered.", tense and 'were' or 'are'))
	end
	
	return mw.text.trim(table.concat(text))
end

local function header(args)
	local row = mw.html.create('tr')
	local region_col = args.region_col
	if region_col then
		row:tag('th'):attr('scope', 'col'):wikitext(mw.language.getContentLanguage():ucfirst(region_col))
	end
	
	local indep_city = args.indep_city
	if not(args.nosub1 == 'yes' or args.sub1 or indep_city) then
		local tag = row:tag('th'):attr('scope', 'col')
		local sub1disp = args.sub1disp
		if sub1disp then
			tag:wikitext(sub1disp)
		else
			tag:wikitext(args.sub1name):wikitext(args.sub1_ref)
		end
	end
	
	if not(args.sub2 or indep_city) then
		row:tag('th'):attr('scope', 'col')
			:wikitext(args.location_def or 'Location'):wikitext(args.sub2_ref)
	end
	
	local altunit = args.altunit
	if altunit then
		row:tag('th'):attr('scope', 'col'):wikitext(altunit):wikitext(args.altunit_ref)
	else
		local unit = args.length or args.unit
		if unit ~= 'off' then
			row:tag('th'):attr('scope', 'col'):wikitext(unit):wikitext(args.length_ref):done():tag('th'):attr('scope', 'col'):wikitext(args.unit2)
		end
	end
	
	local exit = args[1]
	if exit == 'old' then
		row:tag('th'):attr('scope', 'col'):wikitext(args.old_def or 'Old exit'):wikitext(args.old_ref)
		row:tag('th'):attr('scope', 'col'):wikitext(args.exit_def or 'New exit'):wikitext(args.exit_ref)
	elseif exit == 'exit' then
		row:tag('th'):attr('scope', 'col'):wikitext(args.exit_def or 'Exit'):wikitext(args.exit_ref)
	end
	
	if args[2] == 'name' then
		row:tag('th'):attr('scope', 'col'):wikitext(args.name_def or 'Name'):wikitext(args.name_ref)
	end
	
	row:tag('th'):attr('scope', 'col'):wikitext(args.dest_def or 'Destinations'):wikitext(args.dest_ref)
	
	row:tag('th'):attr('scope', 'col'):wikitext(args.notes_def or 'Notes'):wikitext(args.notes_ref)
	
	return '\n{| class="plainrowheaders wikitable hlist"\n' .. tostring(row)
end

function p._jcttop(args)
	-- This function calls two other functions to generate a hatnote and header row.
	-- This function is accessible from other Lua modules.
	return hatnote(args) .. header(args)
end

function p.jcttop(frame)
	-- Entry function for {{jcttop/core}}
	return p._jcttop(require('Module:Arguments').getArgs(frame)) -- Simply call another function with those arguments to actually create the header.
end

return p