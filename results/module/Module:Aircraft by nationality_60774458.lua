local p = {}

--Similar to {{LinkCatIfExists2}}: make a piped link to a category, if it exists;
--if it doesn't exist, just display the greyed link title without linking
function catlink( name, disp )
	name = mw.text.trim(name or '')
	disp = mw.text.trim(disp or '')
	local grey = '#888'
	
	local exists = mw.title.new( name, 'Category' ).exists
	if exists then
		return '[[:Category:'..name..'|'..disp..']]'
	else
		return '<span style="color:'..grey..'">'..disp..'</span>'
	end
end

--checks for existance & returns tracking [[Category:Aircraft catnav missing parent]] if missing
function checkparent( colon, name, sortkey )
	local exists = mw.title.new( name, 'Category' ).exists
	if not exists then
		return '[['..colon..'Category:Aircraft catnav missing parent|'..sortkey..']]'
	end
	return ''
end


--[[==========================================================================]]
--[[                                   Main                                   ]]
--[[==========================================================================]]

function p.catnav( frame )
	local currtitle = mw.title.getCurrentTitle()
	local namespace = currtitle.nsText
	local testcases = (currtitle.subpageText == 'testcases')
	local colon = ''
	if namespace ~= 'Category' then colon = ':' end
	
	local args = frame:getParent().args
	local nation = args['nation'] --live {{Template}}
--	local nation = frame.args['nation'] --direct {{#invoke:}} from cat
	local pagename = currtitle.baseText
	local trackingcats = {
		'', --[1] placeholder for [[Category:Aircraft catnav missing parameter]] (civ/mil)
		'', --[2] placeholder for [[Category:Aircraft catnav missing parent]] (civ/mil/air)
		'', --[3] placeholder for [[Category:Aircraft catnav failed to generate navbox]] !(civ/mil/air)
	}
	local parentcats = {
		'', --[1] placeholder for [[Category:Aircraft manufactured in {{{nation}}}]] (civ) or 
			--					  [[Category:International aircraft]] (mil)
			--					  [[Category:Aircraft by country]] (air)
			
		'', --[2] placeholder for [[Category:Civil aircraft]] (civ) or
			--					  [[Category:Military aircraft by country]] (mil)
			--					  [[Category:Aircraft in <nation>]] (air)
	}
	local countries = {
	--	{ 'the Country Name', 'Adjectival' },
	-- 'the' gets removed as needed
		{ 'Algeria', 'Algerian' },
		{ 'Argentina', 'Argentine' },
		{ 'Australia', 'Australian' },
		{ 'Austria', 'Austrian' },
		{ 'Austria and Austria-Hungary', 'Austrian and Austro-Hungarian' }, --[[Category:Austrian and Austro-Hungarian civil aircraft]]
		{ 'Belgium', 'Belgian' },
		{ 'Brazil', 'Brazilian' },
		{ 'Bulgaria', 'Bulgarian' },
		{ 'Canada', 'Canadian' },
		{ 'Chile', 'Chilean' },
		{ 'China', 'Chinese' },
		{ 'Colombia', 'Colombian' },
		{ 'Cyprus', 'Cypriot' },
		{ 'the Czech Republic and Czechoslovakia', 'Czech and Czechoslovakian' },
		{ 'Denmark', 'Danish' },
		{ 'Egypt', 'Egyptian' },
		{ 'Estonia', 'Estonian' },
		{ 'Finland', 'Finnish' },
		{ 'France', 'French' },
		{ 'Georgia (country)', 'Georgian' }, --only 1 [[WP:AIR]] adj precedent: [[Category:Georgian aircraft designers]] (doesn't disambig)
		{ 'East Germany', 'East German' },
		{ 'Germany', 'German' },
		{ 'Greece', 'Greek' },
		{ 'Hungary', 'Hungarian' },
		{ 'India', 'Indian' },
		{ 'Indonesia', 'Indonesian' },
		{ 'Iran', 'Iranian' },
		{ 'Israel', 'Israeli' },
		{ 'Italy', 'Italian' },
		{ 'Japan', 'Japanese' },
		{ 'Jordan', 'Jordanian' },
		{ 'Latvia', 'Latvian' },
		{ 'Lithuania', 'Lithuanian' },
		{ 'Malaysia', 'Malaysian' },
		{ 'Mexico', 'Mexican' },
		{ 'the Netherlands', 'Dutch' },
		{ 'New Zealand', 'New Zealand' },
		{ 'Norway', 'Norwegian' },
		{ 'the State of Palestine', 'Palestinian' },
		{ 'Pakistan', 'Pakistani' },
		{ 'Peru', 'Peruvian' },
		{ 'the Philippines', 'Philippine' },
		{ 'Poland', 'Polish' },
		{ 'Portugal', 'Portuguese' },
		{ 'the Republic of China', 'Republic of China' },
		{ 'Romania', 'Romanian' },
		{ 'Russia', 'Russian' },
		{ 'Saudi Arabia', 'Saudi Arabian' },
		{ 'Singapore', 'Singaporean' }, --[[Category:Singaporean military aircraft]]
		{ 'Slovakia', 'Slovak' },
		{ 'Slovenia', 'Slovenian' },
		{ 'South Africa', 'South African' },
		{ 'South Korea', 'South Korean' },
		{ 'the Soviet Union', 'Soviet Union' },
		{ 'Soviet Union and CIS', 'Soviet and Russian' },
		{ 'Spain', 'Spanish' },
		{ 'Sweden', 'Swedish' },
		{ 'Switzerland', 'Swiss' },
		{ 'Taiwan', 'Taiwanese' },
		{ 'Thailand', 'Thai' },
		{ 'Turkey', 'Turkish' },
		{ 'the United Arab Emirates', 'Emirati' },
		{ 'the United Kingdom', 'British' },
		{ 'the United States', 'United States' },
		{ 'Ukraine', 'Ukrainian' },
		{ 'Vietnam', 'Vietnamese' },
		{ 'Yugoslavia', 'Yugoslav' },
		{ 'Yugoslavia and Serbia', 'Yugoslav and Serbian' },
	}
	
	--determine category type
	local nation_airtitle = nil --autodetected from air title
	local adj, civmilair = string.match(pagename, '^(.+) (civil) aircraft$') --assume civ
	if civmilair == nil then
		adj, civmilair = string.match(pagename, '^(.+) (military) aircraft$') --mil
	end
	if civmilair == nil then
		civmilair, nation_airtitle = string.match(pagename, '^(Aircraft) manufactured in ([^%/]+)$') --air
	end
	if civmilair == nil then
		civmilair = string.match(pagename, '^(International) aircraft$') --int (special case)
	end
	if civmilair == nil then
		 if namespace == 'Category' or testcases then
		 	trackingcats[3] = '[['..colon..'Category:Aircraft catnav failed to generate navbox]]'
		 end
 		return table.concat(trackingcats)
	end
	local CivMilAir = civmilair:gsub("^%l", string.upper)
	
	--proceed according to category type
	local civmil = (civmilair ~= 'Aircraft' and civmilair ~= 'International')
	if civmil then
		--if {{{nation}}} DNE, find it via the title adjective
		if nation == nil or (nation and nation == '') then
			for _, kv in pairs (countries) do
				if kv[2] == adj then
					nation = kv[1]
					break
		end	end	end
		
		--tracking cats 1 & 2; parent cat 1
		if nation == nil or (nation and nation == '') then
			trackingcats[1] = '[['..colon..'Category:Aircraft catnav missing parameter|N]]'
		elseif nation == 'International' then
			local basename = 'International aircraft' --static: no check/tracking needed
			if CivMilAir == 'Civil' then
				parentcats[1] = '[['..colon..'Category:'..basename..'|Civil]]'
			else
				parentcats[1] = '[['..colon..'Category:'..basename..'|Military aircraft, International]]'
			end
		else
			local basename = 'Aircraft manufactured in '..nation
			trackingcats[2] = checkparent(colon, basename, 'Q')
			parentcats[1] = '[['..colon..'Category:'..basename..'| '..CivMilAir..' aircraft, '..nation..']]'
		end
		
		--parent 2 static: no check/tracking needed
		if CivMilAir == 'Civil' then
			parentcats[2] = '[['..colon..'Category:Civil aircraft]]'
		else
			parentcats[2] = '[['..colon..'Category:Military aircraft by country]]'
		end
		
	elseif civmilair == 'Aircraft' then
		if nation == nil or (nation and nation == '') then
			nation = nation_airtitle --use title if {{{nation}}} DNE
		end
		
		--air parent 1
		parentcats[1] = '[['..colon..'Category:Aircraft by country|'..nation..']]' --static: no check/tracking needed
		
		--air tracking/parent 2
		local basename = 'Aviation in '..nation
		trackingcats[2] = checkparent(colon, basename, 'R') --TODO: update cat description text & inc {{Milairnd}} sortkeys
		parentcats[2] = '[['..colon..'Category:'..basename..'|Aircraft]]'
		
	else --if civmilair == 'International' then
		parentcats[1] = '[['..colon..'Category:Aircraft by country| ]]' --static: no check/tracking needed
		
	end
	
	local heading1 = CivMilAir..' aircraft' --assume civmil
	local heading2 = civmilair..' aircraft' --assume civmil
	if not civmil then
		heading1 = 'Aircraft'
		heading2 = 'aircraft'
	end
	
	local sep = ' • '
	local catnav =  '{| class="toccolours" cellpadding="2" cellspacing="0" style="margin:3px auto; border: 1px solid; font-size:95%;  align="center"\n'..
		'|-\n'..
		'| style="text-align:center;" |\n'..
		"'''"..heading1.." by nationality of original manufacturer'''<br/> "..
		'[[:Category:International '..heading2..'|International joint ventures]]<br/>'
	for _, kv in pairs (countries) do
		local the_c = kv[1]
		local a = kv[2]
		local c = (string.gsub(the_c, '^the ', ''))
		local basename = a..' '..civmilair..' aircraft' --assume civmil
		if not civmil then
			basename = 'Aircraft manufactured in '..the_c
		end
		catnav = catnav..catlink(basename, c)..sep
	end
	catnav = mw.text.trim(catnav, sep)
	catnav = catnav..'\n'..
		'|}\n'..
		'<br/>'
	
	return catnav..table.concat(trackingcats)..table.concat(parentcats)
end

return p