require('Module:No globals')

local conf = require( 'Module:Category described in year/conf' ) --configuration module

--[[==========================================================================]]
--[[                             Local functions                              ]]
--[[==========================================================================]]

local function addOrd( i ) --12 -> 12th, etc.
	if tonumber(i) then
		local s = tostring(i)
		local  tens = string.match(s, '1%d$')
		local  ones = string.match(s,  '%d$')
		if     tens        then return s..'th'
		elseif ones == '1' then return s..'st'
		elseif ones == '2' then return s..'nd'
		elseif ones == '3' then return s..'rd'
		elseif ones ~= nil then return s..'th'
		end
	end
	return ''
end

local function isNilOrEmpty( thing )
	return (thing == nil or thing == '')
end

local p = {}

--[[==========================================================================]]
--[[                            External function                             ]]
--[[==========================================================================]]

function p.autodetect( frame )
	local currentTitle = mw.title.getCurrentTitle()
	local parentArg = frame:getParent().args[1] --accept 1 unnamed category parameter if not in category namespace; required for testing/doc/etc. purposes
	local header = ' ' --header template(s), nav bar, and category description text; whitespace-initialized for convenience
	local nav = nil
	local portal = nil --for {{Portal|...}}
	local commons = nil --for {{Commons|...}}
	local wikispecies = nil --for {{Wikispecies|...}}
	local description = nil
	local toc = nil
	local categories = {}
	local trackingCategories = {
		[1] = '', --placeholder for [[Category:Described in year unknown category]]
		[2] = '', --placeholder for [[Category:Described in year error]]
	}
	local outString = nil
	local bConfError = false
	
	--prelim namespace/title determination
	local currCat = nil
	local currQID = nil
	if currentTitle.namespace == 14 then --category namespace
		currCat = currentTitle.text --without namespace nor interwiki prefixes
		currQID = mw.wikibase.getEntityIdForCurrentPage()
	else
		if parentArg then
			currCat = mw.ustring.gsub(parentArg, 'Category:', '')
			currQID = mw.wikibase.getEntityIdForTitle('Category:' .. currCat)
		else --currQID & currCat both nil
			if currentTitle.fullText ~= 'Template:Category described in year' then --ignore self...
				trackingCategories[2] = '[[Category:Described in year error|P]]' --missing a category parameter outside category namespace
			end
		end
	end
	
	--find commons & wikispecies link(s); produce {{Commons}} and/or {{Wikispecies}} template(s)
	if currQID then
		local commonsLinks = {}
		local currEntity = mw.wikibase.getEntity(currQID)
		if currEntity then
			--check Commons category property (P373)
			local ccPropState = currEntity:getBestStatements('P373')[1]
			if ccPropState then
				local ccPropVal = ccPropState.mainsnak.datavalue.value
				if ccPropVal then
					commonsLinks[#commonsLinks + 1] = 'Category:' .. mw.ustring.gsub(ccPropVal, 'Category:', '')
				end
			end
			--check Commons gallery property (P935)
			local cgPropState = currEntity:getBestStatements('P935')[1]
			if cgPropState then
				local cgPropVal = cgPropState.mainsnak.datavalue.value
				if cgPropVal then
					commonsLinks[#commonsLinks + 1] = cgPropVal
				end
			end
			--check "Other sites" sitelinks for Commons and/or Wikispecies
			local currSiteLinks = currEntity.sitelinks
			if currSiteLinks then
				local currCommonsWiki = currEntity.sitelinks.commonswiki
				if currCommonsWiki then
					local currCommonsWikiTitle = currEntity.sitelinks.commonswiki.title
					if currCommonsWikiTitle then
						commonsLinks[#commonsLinks + 1] = currCommonsWikiTitle
					end
				end
				local currSpeciesWiki = currEntity.sitelinks.specieswiki
				if currSpeciesWiki then
					local currSpeciesWikiTitle = currSpeciesWiki.title
					if currSpeciesWikiTitle then
						wikispecies = frame:expandTemplate{ title = 'Wikispecies', args = { currSpeciesWikiTitle } }
					end
				end
			end
		end
		
		--produce {{Commons}} template(s) (ignore duplicates)
		if commonsLinks[1] then --turn these into a loop if # of commons sources >= 4
			commons = frame:expandTemplate{ title = 'Commons', args = { commonsLinks[1] } }
			if commonsLinks[2] and
			   commonsLinks[2] ~= commonsLinks[1] then
				commons = commons .. frame:expandTemplate{ title = 'Commons', args = { commonsLinks[2] } }
			end
			if commonsLinks[3] and
			   commonsLinks[3] ~= commonsLinks[1] and 
			   commonsLinks[3] ~= commonsLinks[2] then
				commons = commons .. frame:expandTemplate{ title = 'Commons', args = { commonsLinks[3] } }
			end
		end
	end --if currQID then
	
	--[[======================================================================]]
	--[[                                 Main                                 ]]
	--[[======================================================================]]
	if currCat then
		
		--determine current/related/adjacent cats' properties/vars/etc.
		local currGroup = mw.ustring.match(currCat, '^([%w ]+) described in') --Bacteria/Plants/etc.
		if isNilOrEmpty(currGroup) then currGroup = mw.ustring.match(currCat, '^([%w ]+) by year of formal description') end
		if conf[currGroup] == nil then conf[currGroup] = conf['Default'] end --default to Default
		local currYDCF = nil --possible future values: year/decade/century/formal
		local currYear = mw.ustring.match(currCat, 'described in (%d%d%d%d)$')
		local currDeca = mw.ustring.match(currCat, 'described in the (%d%d%d%d)s$') --deprecated
		local currCent = mw.ustring.match(currCat, 'described in the (%d+)[snrt][tdh] century$')
		local currFrml = mw.ustring.match(currCat, 'by year of (formal) description$')
		local parentCent = nil --used with currYear
		local minYear = tonumber(conf[currGroup].minyear)
		if minYear == nil or 
		  (minYear and (minYear <= 1700 or minYear >= 2000)) then
			minYear = 1758 --default to 1758 per ICZN Art. 5
		end
		if currYear then
			currYDCF = 'year'
			if mw.ustring.match(currYear, '^%d%d00') then --1900 in 19th century
				parentCent = mw.ustring.match(currYear, '^%d%d')
			else --1901 in 20th century
				parentCent = 1 + mw.ustring.match(currYear, '^%d%d')
			end
		elseif currDeca then
			currYDCF = 'decade'
			bConfError = true
			trackingCategories[2] = '[[Category:Described in year error|D]]' --invalid decade-parent (deprecated)
		elseif currCent then
			currYDCF = 'century'
		elseif currFrml then
			currYDCF = 'formal'
		else
			bConfError = true
			trackingCategories[2] = '[[Category:Described in year error|N]]' --invalid category name
		end
		
		--conf error checkng (missing keys)
		--Numeric sortkeys are unfortunately grouped together under "0-9".
		--Check phab T203355 (Magic word to force category number headings instead of 0-9).
		if bConfError == false then
			if conf[currGroup] == nil then
				bConfError = true
				trackingCategories[2] = '[[Category:Described in year error|1]]' --group (Bacteria/Plants/etc.) key missing from conf
			elseif conf[currGroup][currYDCF] == nil then
				bConfError = true
				trackingCategories[2] = '[[Category:Described in year error|2]]' --year/century/formal key missing
			else
				if conf[currGroup][currYDCF].description == nil then
					bConfError = true
					trackingCategories[2] = '[[Category:Described in year error|3]]' --description key missing
				end
				if conf[currGroup][currYDCF].parent1 == nil then
					bConfError = true
					trackingCategories[2] = '[[Category:Described in year error|4]]' --parent key missing
				end
			end
		end
		
		if bConfError == false then
			--produce portal
			if currGroup == 'Fossil taxa' or currGroup == 'Fossil parataxa' then
				portal = frame:expandTemplate{ title = 'Portal', args = { 'Paleontology' } }
			end
			
			--produce description, evaluate %variables%
			description = conf[currGroup][currYDCF].description
			if mw.ustring.match(description, '%%year%%') then
				if currYear then description = mw.ustring.gsub(description, '%%year%%', currYear) --"2011"
				else description = mw.ustring.gsub(description, '%%year%%', 'this year') end
			end
			if mw.ustring.match(description, '%%century%%') then
				if currCent then description = mw.ustring.gsub(description, '%%century%%', addOrd(currCent)) --"21st"
				else description = mw.ustring.gsub(description, '%%century%%', 'this century') end
			end
			
			--produce toc
-- {{CatAutoTOC}} now provided via [[Template:Category described in year]]
--[[
			if mw.site.stats.pagesInCategory(currCat, 'pages') >= conf['tocmin'] then --expensive
				local args = { numerals = 'no' }
				toc = frame:expandTemplate{ title = 'Category TOC', args = args }
			end
--]]

			--produce cats & navs
			local iparent = 1
			local parenti = 'parent' .. iparent
			local sortkeyi = 'sortkey' .. iparent
			while conf[currGroup][currYDCF][parenti] do
				local parent = conf[currGroup][currYDCF][parenti]
				local sortkey = conf[currGroup][currYDCF][sortkeyi]
				
				--[[========================== Year ==========================]]
				if currYDCF == 'year' then
					if nav == nil then
						local args = { min = minYear }
						if parentArg and currentTitle.namespace ~= 14 then
							args['testcase'] = parentArg
						end
						nav = frame:expandTemplate{ title = 'Navseasoncats', args = args }
					end
					if parent == 'century' then
						if isNilOrEmpty(sortkey) then sortkey = currYear end --default to currYear
						categories[iparent] = '[[Category:'..currGroup..' described in the '..addOrd(parentCent)..' century|'..sortkey..']]'
					elseif parent == 'biology' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						if tonumber(currYear) < 1865 then
							categories[iparent] = '[[Category:'..currYear..' in science'..sortkey..']]' --biology cat structure doesn't exist pre-1865, as of 10/2018
						else
							categories[iparent] = '[[Category:'..currYear..' in biology'..sortkey..']]' --if/when all biology cats exists, merge this elseif with 'paleontology'
						end
					elseif parent == 'paleontology' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..currYear..' in '..parent..sortkey..']]'
					elseif parent == 'environment' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..currYear..' in the environment'..sortkey..']]'
					elseif mw.ustring.match(parent, '^%u[%l ]+') then --e.g. Animals/Insects/Fossil taxa
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..parent..' described in '..currYear..sortkey..']]'
					else
						trackingCategories[2] = '[[Category:Described in year error|Y]]' --invalid year-parent
					end
					
				--[[======================== Century =========================]]
				elseif currYDCF == 'century' then
					if nav == nil then
						local args = {}
						if parentArg and currentTitle.namespace ~= 14 then
							args['testcase'] = parentArg
						end
						nav = frame:expandTemplate{ title = 'Container category' } .. 
							  frame:expandTemplate{ title = 'Navseasoncats', args = args }
					end
					if parent == 'formal' then
						if isNilOrEmpty(sortkey) then sortkey = addOrd(currCent) end --default to currCent
						categories[iparent] = '[[Category:'..currGroup..' by year of formal description|'..sortkey..']]'
					elseif parent == 'biology' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						if tonumber(currCent) < 19 then
							categories[iparent] = '[[Category:'..addOrd(currCent)..' century in science'..sortkey..']]' --biology cat structure doesn't exist pre-1865, as of 10/2018
						else
							categories[iparent] = '[[Category:'..addOrd(currCent)..' century in biology'..sortkey..']]' --if/when all biology cats exists, merge this elseif with 'paleontology'
						end
					elseif parent == 'paleontology' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..addOrd(currCent)..' century in '..parent..sortkey..']]'
					elseif parent == 'environment' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..addOrd(currCent)..' century in the environment'..sortkey..']]'
					elseif mw.ustring.match(parent, '^%u[%l ]+') then --e.g. Animals/Insects/Fossil taxa
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..parent..' described in the '..addOrd(currCent)..' century'..sortkey..']]'
					else
						trackingCategories[2] = '[[Category:Described in year error|C]]' --invalid century-parent
					end
					
				--[[======================== Formal ==========================]]
				elseif currYDCF == 'formal' then
					if nav == nil then
						nav = frame:expandTemplate{ title = 'Container category' }
					end
					if parent == 'Group' then
						if isNilOrEmpty(sortkey) then sortkey = ' Year' end --default to " Year"
						categories[iparent] = '[[Category:'..currGroup..'|'..sortkey..']]'
					elseif parent == 'Animals' or parent == 'Insects' or parent == 'Molluscs' then
						if isNilOrEmpty(sortkey) then sortkey = ' ' end --default to " "
						categories[iparent] = '[[Category:'..parent..' by year of formal description|'..sortkey..']]'
					elseif parent == 'Species' or parent == 'Taxa' or parent == 'Fossil taxa' then
						if isNilOrEmpty(sortkey) then sortkey = '' --default to none
						else sortkey = '|'..sortkey end
						categories[iparent] = '[[Category:'..parent..' by year of formal description'..sortkey..']]'
					elseif parent == 'paleontology' then
						if isNilOrEmpty(sortkey) then sortkey = ' ' end --default to " "
						categories[iparent] = '[[Category:Paleontology by year|'..sortkey..']]'
					else
						trackingCategories[2] = '[[Category:Described in year error|F]]' --invalid formal-parent
					end
					
				--[[========================= Error ==========================]]
				else
					trackingCategories[2] = '[[Category:Described in year error|U]]' --unknown configuration
				end
				
				iparent = iparent + 1
				parenti = 'parent' .. iparent
				sortkeyi = 'sortkey' .. iparent
			end --while conf[currGroup][currYDCF][parenti] do
		end --if bConfError == false then
		
		--check for non-existent cats
		for _, category in pairs(categories) do
			local cat = mw.ustring.match(category, '%[%[Category:([%w%s]+)')
			if mw.title.new(cat, 14).exists == false then
				trackingCategories[1] = '[[Category:Described in year unknown category]]'
				break
			end
		end
		
	end --if currCat then
	
	--build header & rem surrounding whitespace
	if nav then header = nav end
	if portal then header = header .. portal end
	if commons then header = header .. commons end
	if wikispecies then header = header .. wikispecies end
	if description and description ~= '' then
		header = header .. description
	elseif portal or commons or wikispecies then 
		header = mw.ustring.gsub(header, '<br ?/?>', '')
	end
	if toc then header = header .. '<br />' .. toc end
	header = mw.text.trim(header)
	header = mw.ustring.gsub(header, '^<br />', '')
	header = mw.ustring.gsub(header, '<br />$', '')
	
	--append header to outString
	if outString then outString = outString .. header
	else outString = header end
	
	--append cats to outString
	if currentTitle.namespace == 14 then --category namespace
		if table.maxn(categories) > 0 then outString = outString .. table.concat(categories) end
		outString = outString .. table.concat(trackingCategories)
	else
		if table.maxn(categories) > 0 then --might be 0 if there's an error before setting cats
			outString = outString .. '<br />' .. mw.ustring.gsub(table.concat(categories, '<br />'), '%[%[', '[[:')
		end
		outString = outString .. '<br />' .. mw.ustring.gsub(table.concat(trackingCategories, '<br />'), '%[%[', '[[:')
		outString = mw.ustring.gsub(outString, '<br /><br />', '<br />') --produced by empty ('') first/consecutive tracking cat/s
		outString = mw.ustring.gsub(outString, '<br /><br />', '<br />') --jic (use while loop if #trackingCategories >= 3 or 4)
	end
	
	return outString
end

return p