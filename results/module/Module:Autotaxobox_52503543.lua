--[[*************************************************************************
This module provides support to the automated taxobox system – the templates
Automatic taxobox, Speciesbox, Subspeciesbox, Infraspeciesbox, etc.

In particular it provides a way of traversing the taxonomic hierarchy encoded
in taxonomy templates (templates with names of the form
"Template:Taxonomy/TAXON_NAME") without causing template expansion depth
errors.
*****************************************************************************]]

require('Module:No globals')
local TaxonItalics = require('Module:TaxonItalics') -- use a function from Module:TaxonItalics to italicize a taxon name
local TableRow = '|-\n'
local TableEnd = '|}\n'
local p = {} -- functions made public
local l = {} -- internal functions, kept separate
local colour = '' -- colour for taxobox and taxonomy listings

--[[=========================================================================
Limit the maximum depth of a taxonomic hierarchy that can be traversed;
avoids excessive processing time and protects against incorrectly set up
hierarchies, e.g. loops.
The value can be obtained externally via
{{#invoke:Autotaxobox|getMaxSearchLevels}}
=============================================================================]]
local MaxSearchLevels = 100

function p.getMaxSearchLevels()
	return MaxSearchLevels
end

--[[========================== taxoboxColour ================================
Determines the correct colour for a taxobox, by searching up the taxonomic
hierarchy from the supplied taxon for the first taxon (other than
'incertae sedis') that sets a taxobox colour. It is assumed that a valid
taxobox colour is defined using CSS rgb() syntax.
If no taxon that sets a taxobox colour is found, then 'transparent' is
returned unless the taxonomic hierarchy is too deep, when the error colour is
returned.
Usage: {{#invoke:Autotaxobox|taxoboxColour|TAXON}}
=============================================================================]]
function p.taxoboxColour(frame)
	return p.getTaxoboxColour(frame, frame.args[1] or '')
end

function p.getTaxoboxColour(frame, currTaxon)
	-- note that colour is global to this function; default is empty string
	local i = 1 -- count levels processed
	local searching = currTaxon ~= '' -- still searching for a colour?
	local foundICTaxon = false -- record whether 'incertae sedis' found
	while searching and i <= MaxSearchLevels do
		local plainCurrTaxon, dummy = l.stripExtra(currTaxon) -- remove trailing text after /
		if string.lower(plainCurrTaxon) == 'incertae sedis' then
			foundICTaxon = true
		else
			local possibleColour = frame:expandTemplate{ title = 'Template:Taxobox colour', args = { plainCurrTaxon } }
			if string.sub(possibleColour,1,3) == 'rgb' then
				colour = possibleColour
				searching = false
			end
		end
		if searching then
			local ok, parent = p.getTaxonInfoItem(frame, currTaxon, 'parent')
			if ok and parent ~= '' then
				currTaxon = parent
				i = i + 1
			else
				searching = false -- run off the top of the hierarchy or tried to use non-existent taxonomy template
			end
		end
	end
	if colour == '' then
		if foundICTaxon then
			colour = frame:expandTemplate{ title = 'Template:Taxobox colour', args = { 'incertae sedis' } }
		elseif searching then
			-- hierarchy exceeds MaxSearchLevels levels
			colour = frame:expandTemplate{ title = 'Template:Taxobox/Error colour', args = { } }
		else
			colour = 'transparent'
		end
	end
	return colour
end

--[[= = = = = = = = = = = = =  topLevelTaxon  = = = = = = = = = = = = = = = = 
Defines the correct top level taxa, one of which should terminate every
taxonomic hierarchy encoded in taxonomy templates.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.topLevelTaxon(taxon)
	return  taxon == 'Life' or taxon == 'Veterovata' or taxon == 'Ichnos'
end

--[[=========================== taxoboxList =================================
Returns the rows of taxa in an automated taxobox, based on the taxonomic
hierarchy for the supplied taxon.
Usage:
{{#invoke:Autotaxobox|taxoboxList|TAXON
|display_taxa = the number of taxa *above* TAXON to force to be displayed
|authority = taxonomic authority for TAXON
|parent_authority = taxonomic authority for TAXON's parent
|gparent_authority = taxonomic authority for TAXON's grandparent
|ggparent_authority = taxonomic authority for TAXON's greatgrandparent
|ggparent_authority = taxonomic authority for TAXON's greatgreatgrandparent
|bold_first = 'bold' to bold TAXON in its row
|virus = 'yes' to apply virus taxa italicization standards
}}
=============================================================================]]
function p.taxoboxList(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then return '' end
	local displayN = (tonumber(frame.args['display_taxa']) or 1) + 1
	local authTable = {}
	authTable[1] = frame.args['authority'] or ''
	authTable[2] = frame.args['parent_authority'] or ''
	authTable[3] = frame.args['gparent_authority'] or ''
	authTable[4] = frame.args['ggparent_authority'] or ''
	authTable[5] = frame.args['gggparent_authority'] or ''
	local boldFirst = frame.args['bold_first'] or 'link' -- values 'link' or 'bold'
	local virus = frame.args['virus'] or 'no' -- values 'yes' or 'no'
	local offset = tonumber(frame.args['offset'] or 0)
	-- adjust the authority table if 'authority' refers to a rank lower than the target taxon
	if offset ~= 0 then
		for i = 1, 5 do
			local j = i + offset
			if j <= 5 then
				authTable[i] = authTable[j]
			else
				authTable[i] = ''
			end
		end
	end
	local taxonTable, taxonRankTable = l.makeTable(frame, currTaxon)
	local res = ''
	local topTaxonN = taxonTable.n
	-- display all taxa above possible greatgreatgrandparent, without authority
	for i = topTaxonN, 6, -1 do
		res = res .. l.showTaxon(frame, taxonTable[i], taxonRankTable[i], topTaxonN==i, '', displayN >= i, '', virus)
	end
	-- display all taxa above possible parent, with authority if given
	for i = math.min(topTaxonN, 5), 2, -1 do
		res = res .. l.showTaxon(frame, taxonTable[i], taxonRankTable[i], topTaxonN==i, authTable[i], displayN >= i, '', virus)
	end
	-- display target taxon, always displayed and emboldened
	res = res .. l.showTaxon(frame, taxonTable[1], taxonRankTable[1], topTaxonN==1, authTable[1], true, boldFirst, virus)
	return res
end

--[[= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
Show one taxon row in a taxobox.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.showTaxon(frame, taxon, rank, isTopTaxon, auth, force, boldFirst, virus)
	-- it's an error if this is the top taxon and it's not a top level taxon (e.g. "Life")
	if isTopTaxon then
		if l.topLevelTaxon(taxon) then
			return '' -- don't display a top level taxon
		elseif mw.title.new('Taxonomy/'..taxon, 'Template').exists then
			-- taxonomy template for this taxon has no parent specified
			return frame:expandTemplate{ title = 'Template:Create taxonomy', args = {taxon, msg='Taxonomy template does not specify a parent'} } .. '\n' .. TableRow
		else
			-- no taxonomy template for this taxon
			return frame:expandTemplate{ title = 'Template:Create taxonomy', args = {taxon, msg='Missing taxonomy template'} } .. '\n' .. TableRow
		end
	else
		-- if showing is not already forced, force if it's a principal rank or an authority is specified
		force = force or frame:expandTemplate{ title = 'Template:Principal rank', args = {rank} } == 'yes' or
		        auth ~= ''
		if not force then
			-- if showing is still not already forced, force if the taxonomy template has 'always_display' set
			local ok, alwaysDisplay = p.getTaxonInfoItem(frame, taxon, 'always_display')
			force = alwaysDisplay == 'yes' or  alwaysDisplay == 'true'
		end
		if force then
			local res = l.tableCell(frame:expandTemplate{ title = 'Template:Anglicise rank', args = {rank} } .. ':')
			local bold = 'no'
			if boldFirst == 'bold' then bold = 'yes' end
			if auth ~= '' then
				auth = '<br><small>' .. auth .. '</small>'
			end
			local res = res .. l.tableCell(l.getTaxonLink(frame, taxon, rank, bold, '', '', virus) .. auth) -- italic, abbreviated
			return res .. TableRow
		else
			return ''
		end
	end
end

--[[========================== taxonomyList =================================
Returns the cells of the taxonomy table displayed on the right hand side of
"Template:Taxonomy...." pages.
Usage: {{#invoke:Autotaxobox|taxonomyList|TAXON}}
=============================================================================]]
function p.taxonomyList(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then
		return '{|class="infobox biota"\n' .. TableRow .. l.tableCell('') .. l.tableCell('ERROR: no taxon supplied') .. TableEnd
	end
	local taxonTable, taxonRankTable = l.makeTable(frame, currTaxon)
	local rankValTable = l.getRankTable()
	local lastRankVal = 1000000
	local orderOk = true
	-- check whether the taxonomy is for viruses; use already determined taxon colour if possible
	local virus = 'no'
	local taxoColour = colour
	if taxoColour == '' then
		if  taxonTable[taxonTable.n] == 'Ichnos' or taxonTable[taxonTable.n] == 'Veterovata' then
			taxoColour = frame:expandTemplate{ title = 'Template:Taxobox colour', args = { taxonTable[taxonTable.n] } }
		else
			taxoColour = frame:expandTemplate{ title = 'Template:Taxobox colour', args = { taxonTable[taxonTable.n - 1] } }
		end
	end
	if taxoColour == frame:expandTemplate{ title = 'Template:Taxobox colour', args = { 'virus' } } then
		virus = 'yes'
	end
	-- add information message
	local res = '<p style="float:right">Bold ranks show taxa that will be shown in taxoboxes<br>because rank is principal or <code>always_display=yes</code>.</p>\n'

	-- start table
	res =  res .. '{| class="infobox biota" style="text-align: left; font-size:100%"\n' .. TableRow .. '! colspan=4 style="text-align: center; background-color: '
	            .. taxoColour .. '"|Ancestral taxa\n'
	-- deal first with the top level taxon; if there are no errors, it should be Life/Veterovata/Ichnos, which are 
	-- not displayed
	local taxon = taxonTable[taxonTable.n]
	if not l.topLevelTaxon(taxon) then
		local msg = 'Taxonomy template missing'
		if mw.title.new('Taxonomy/'..taxon, 'Template').exists then
			msg = 'Parent taxon needed'
		end
		res = res .. TableRow .. l.tableCell('colspan=2', frame:expandTemplate{title = 'Template:Create taxonomy', args = {taxon, msg = msg}})
	end
	-- now output the rest of the table
	local currRankVal
	for i = taxonTable.n-1, 1, -1 do
		-- check ranks are in right order in the hierarchy
		taxon = taxonTable[i]
		local rank = taxonRankTable[i]
		currRankVal = l.lookupRankVal(rankValTable, rank)
		if currRankVal then
			orderOk = currRankVal < lastRankVal
			if orderOk then lastRankVal = currRankVal end
		else
			orderOk = true
		end
		-- see if the row will be displayed in a taxobox; bold the rank if so
		local boldRank = false
		local ok, alwaysDisplay = p.getTaxonInfoItem(frame, taxon, 'always_display')
		if ok and (alwaysDisplay == 'yes' or alwaysDisplay == 'true') then
			boldRank = true
		else
			boldRank = frame:expandTemplate{ title = 'Template:Principal rank', args = {rank} } == 'yes'
		end
		-- now return a row of the taxonomy table with anomalous ranks marked
		local errorStr = ''
		if not orderOk then errorStr = 'yes' end
		local link = l.getTaxonLink(frame, taxon, rank, '', '', '', virus) -- bold, italic, abbreviated
		res = res .. l.taxonomyListRow(frame, taxon, rank, link, boldRank, errorStr)
	end
	-- close table
	res = res .. TableEnd
	-- error-tracking for taxonomy templates
	-- if the last row has an anomalous rank, put the page in an error-tracking category
	local errCat1 = ''
	if not orderOk then
		errCat1 = '[[Category:Taxonomy templates showing anomalous ranks]]\n'
	end
	-- if the last row has a taxon name in the page name that does not match the link text,
	-- put the taxonomy template in a tracking category
	local dummy, linkText = p.getTaxonInfoItem(frame, taxon, 'link_text')
	local match = l.matchTaxonLink(taxon, linkText, currRankVal and currRankVal < rankValTable['genus'])
	local errCat2 = ''
	if not match then
		errCat2 = '[[Category:Taxonomy templates with name and link text not matching|' .. taxon .. ']]\n'
	end
	if errCat1..errCat2 ~= '' then
		res = res .. frame:expandTemplate{ title = 'Template other', args = { errCat1..errCat2} }
	end
	return res
end

--[[ = = = = = = = = = = = = = = taxonomyListRow  = = = = = = = = = = = = = = 
Returns a single row of the taxonomy table displayed on the right hand side
 of "Template:Taxonomy...." pages.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.taxonomyListRow(frame, taxon, rank, link, boldRank, error)
	local res = ''
	if taxon == '' or rank == '' then return res end
	local baseTaxon, qualifier = l.stripExtra(taxon)
	-- if appropriate, make it clear that some taxa have been skipped via a ... row
	if qualifier == '/skip' then
		res = res .. TableRow .. l.tableCell('.....') .. l.tableCell('.....')
	end
	-- now generate a row of the table
	res = res .. TableRow
	local cellContent = ''
	local anglicizedRank = frame:expandTemplate{ title = 'Template:Anglicise rank', args = { rank } }
	if boldRank then
		cellContent = cellContent .. '<b>' .. anglicizedRank .. '</b>:'
	else
		cellContent = cellContent .. anglicizedRank .. ':'
	end
	if error == 'yes' then
		cellContent = '<span style="background-color:#FDD">' .. cellContent .. '</span>'
	end
	res = res .. l.tableCell(cellContent)
	          .. l.tableCell('<span style="white-space:nowrap;">' .. link .. '</span>')
	          .. l.tableCell('<span style="font-size:smaller;">' .. qualifier  .. '</span>')
	          .. l.tableCell('<span style="white-space:nowrap;">' .. frame:expandTemplate{ title = 'Template:Edit a taxon', args = { taxon } } .. '</span>')
	return res
end

--[[========================= callTaxonomyKey ===============================
Prepares for, and then calls, Template:Taxonomy key to display a taxonomy
template page. It does this by building up the information the template
requires, following one 'same as' link, if required.
Usage:
{{#invoke:Autotaxobox|callTaxonomyKey
|parent=
|rank=
|extinct=
|always_display=
|link_target=value of 'link' parameter in taxonomy template
|link_text=value of parameter 2 in taxonomy template
|same_as=
}}
=============================================================================]]
local PARENT = 1
local RANK = 2
local LINK_TARGET = 3
local LINK_TEXT = 4
local ALWAYS_DISPLAY = 5
local EXTINCT = 6
local SAME_AS = 7
local REFS = 8

function p.callTaxonomyKey(frame)
	local taxon = frame.args['taxon'] or ''
	local parent = frame.args['parent'] or ''
	local rank = frame.args['rank'] or ''
	local extinct = string.lower(frame.args['extinct']) or ''
	local alwaysDisplay = string.lower(frame.args['always_display']) or ''
	local linkTarget = frame.args['link_target'] or ''
	local linkText = frame.args['link_text'] or '' -- this is the "raw" link text, and can be ''
	local refs = frame.args['refs'] or ''
	local sameAsTaxon = frame.args['same_as'] or ''
	if sameAsTaxon ~= '' then
		-- try using the 'same as' taxon; it's an error if it doesn't exist
		local ok, sameAsInfoStr = pcall(frame.expandTemplate, frame, { title = 'Template:Taxonomy/' .. sameAsTaxon, args = {['machine code'] = 'all' } })
		if ok then
			local sameAsInfo = mw.text.split(sameAsInfoStr, '$', true)
			--'same as' taxon's taxonomy template must not have a 'same as' link
			if sameAsInfo[SAME_AS] == '' then
				if parent == '' then parent = sameAsInfo[PARENT] end
				if rank == '' then rank = sameAsInfo[RANK] end
				if extinct == '' then extinct = string.lower(sameAsInfo[EXTINCT]) end
				if alwaysDisplay == '' then alwaysDisplay = string.lower(sameAsInfo[ALWAYS_DISPLAY]) end
				if linkTarget == '' then linkTarget = sameAsInfo[LINK_TARGET] end
				if linkText == '' then linkText = sameAsInfo[LINK_TEXT] end
				if refs == '' and parent == sameAsInfo[PARENT] then refs = sameAsInfo[REFS] end
			else
				return '<span style="color:red; font-size:1.1em">Error: attempt to follow two "same as" links</span>: <code>same_as = ' .. sameAsTaxon .. '</code>, but [[Template:Taxonomy/' .. sameAsTaxon .. ']] also has a<code>same_as</code> parameter.'
			end
		else
			return frame:expandTemplate{ title = 'Template:Taxonomy key/missing template', args = {taxon=sameAsTaxon, msg='given as the value of <code>same as</code>'} }
		end
	end
	local link = linkTarget
	if linkText ~= '' and linkText ~= linkTarget then link = link .. "|" .. linkText end
	-- check consistency of extinct status; if this taxon is not extinct, parent must not be either
	local extinctError = 'no'
	if parent ~= '' and (extinct == '' or extinct == 'no' or extinct == 'false') then
		local ok, parentExtinct = p.getTaxonInfoItem(frame, parent, 'extinct')
		if ok and (parentExtinct == 'yes' or parentExtinct == 'true') then extinctError = 'yes' end
	end
	return frame:expandTemplate{ title = 'Template:Taxonomy key',
			args = {taxon=taxon, parent=parent, rank=rank, extinct=extinct, always_display=alwaysDisplay, link_target=linkTarget, link=link, refs=refs, same_as=sameAsTaxon, extinct_error = extinctError} }
end

--[[============================= showRefs ==================================
Shows the refs field in a taxonomy template, handing incertae sedis taxa and
using '–' for absent refs.
Usage: {{#invoke:Autotaxobox|showRefs|TAXON|REFS}}
=============================================================================]]
function p.showRefs(frame)
	local taxonName = frame.args[1] or ''
	local refs = frame.args[2] or ''
	return l.doShowRefs(taxonName, refs)
end

--[[= = = = = = = = = = = = = = doShowRefs  = = = = = = = = = = = = = = = = =
Show the refs field in a taxonomy template.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.doShowRefs(taxonName, refs)
	if mw.text.split(taxonName, '/', true)[1] == 'Incertae sedis' then
		refs = 'not applicable (<i>incertae sedis</i>)'
	elseif refs == '' then
		refs = '–'
	end
	return refs
end

--[[============================ taxonInfo ==================================
Extracts and returns information from Template:Taxonomy/TAXON, following
one 'same as' link if required.
Usage: {{#invoke:Autotaxobox|taxonInfo|TAXON|ITEM}}
ITEM is one of: 'parent', 'rank', 'link target', 'link text', 'extinct',
'always display', 'refs', 'same as' or 'all'.
If ITEM is not specified, the default is 'all' – all values in a single string
separated by '$'.
=============================================================================]]
function p.taxonInfo(frame)
	local taxon = frame.args[1] or ''
	local item = frame.args[2] or ''
	if item == '' then item = 'all' end
	local ok, info = p.getTaxonInfoItem(frame, taxon, item)
	return info
end

--[[= = = = = = = = = = = getTaxonInfoItem  = = = = = = = = = = = = = = = = =
Utility function to extract an item of information from a 
taxonomy template, following one 'same as' link if required.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function p.getTaxonInfoItem(frame, taxon, item)
	local ok, info
	-- item == 'dagger' is a special case
	if item == 'dagger' then
		ok, info = p.getTaxonInfoItem(frame, taxon, 'extinct')
		if ok then
			if info == 'yes' or info == 'true' then
				info = '&dagger;'
			else
				info = ''
			end
		end
	-- item ~= 'dagger'
	else
		ok, info = pcall(frame.expandTemplate, frame, { title = 'Template:Taxonomy/' .. taxon, args = {['machine code'] = item } })
		if ok then
			if info == '' then
				-- try 'same as'
				local sameAsTaxon = frame:expandTemplate{ title = 'Template:Taxonomy/' .. taxon, args = {['machine code'] = 'same as' } }
				if sameAsTaxon ~= '' then
					ok, info = pcall(frame.expandTemplate, frame, { title = 'Template:Taxonomy/' .. sameAsTaxon, args = {['machine code'] = item } })
				end
			end
		end
	end
	if ok then
		-- if item is 'link_text', trim info and check whether '(?)' needs to be added
		if item == 'link_text' then
			-- there is a newline at the end of linkText when taxonomy template has "|link = LINK_TARGET|LINK_TEXT"
			info = mw.text.trim(info)
			if string.sub(taxon, -2) == '/?' and not string.find(info, '?', 1, true) then
				info = info .. '<span style="font-style:normal;font-weight:normal;"> (?)</span>'
			end
		end
	else
		info = '[[Template:Taxonomy/' .. taxon .. ']]' --error indicator in code before conversion to Lua
	end
	return ok, info
end

--[[============================ taxonLink ==================================
Returns a wikilink to a taxon, if required including '†' before it and
' (?)' after it, and optionally italicized or bolded without a wikilink.
Usage:
{{#invoke:Autotaxobox|taxonLink
|taxon=           : having '/?' at the end triggers the output of ' (?)'
|extinct=         : 'yes' or 'true' trigger the output of '†'
|bold=            : 'yes' makes the core output bold and not wikilinked
|italic=          : 'yes' makes the core output italic
|link_target=     : target for the wikilink
|link_text=        : text of the wikilink (may be same as link_target), without †, italics, etc.
}}
=============================================================================]]
function p.taxonLink(frame)
	local taxon = frame.args['taxon'] or ''
	local extinct = string.lower(frame.args['extinct'] or '')
	local bold = frame.args['bold'] or ''
	local italic = frame.args['italic'] or ''
	local abbreviated = frame.args['abbreviated'] or ''
	local linkTarget = frame.args['link_target'] or ''
	local linkText = frame.args['link_text'] or frame.args['plain_link_text'] or '' --temporarily allow alternative args
	return l.makeLink(taxon, extinct, bold, italic, abbreviated, linkTarget, linkText)
end

--[[= = = = = = = = = = = = = = getTaxonLink  = = = = = = = = = = = = = = = =
Internal function to drive l.makeLink().
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.getTaxonLink(frame, taxon, rank, bold, italic, abbreviated, virus)
	local ok, extinct = p.getTaxonInfoItem(frame, taxon, 'extinct')
	if italic == '' then
		italic = frame:expandTemplate{ title = 'Template:Is italic taxon', args = { rank, virus = virus } }
	end
	local ok, linkTarget = p.getTaxonInfoItem(frame, taxon, 'link_target')
	local ok, linkText = p.getTaxonInfoItem(frame, taxon, 'link_text')
	return l.makeLink(taxon, extinct, bold, italic, abbreviated, linkTarget, linkText)
end

--[[= = = = = = = = = = = = = = makeLink  = = = = = = = = = = = = = = = = = =
Actually make the link.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.makeLink(taxon, extinct, bold, italic, abbreviated, linkTarget, linkText)
	local dummy
	-- if link text is missing, try to find a replacement
	if linkText == '' then
		if string.find(taxon, 'Incertae sedis', 1, true) then
			linkText = "''incertae sedis''"
			linkTarget = 'Incertae sedis'
		else
			linkText, dummy = l.stripExtra(taxon)
		end
	end
	if linkTarget == '' then linkTarget = linkText end
	if italic == 'yes' then linkText = TaxonItalics.italicizeTaxonName(linkText, false, abbreviated=='yes') end
	local link = ''
	if bold == 'yes' then link = '<b>' .. linkText .. '</b>'
	else
		if linkTarget == linkText then link = linkText
		else link = linkTarget .. '|' .. linkText
		end
		link = '[[' .. link .. ']]'
	end
	if (extinct == 'yes' or extinct == 'true') and not string.find(link, '†', 1, true) then
		link = '<span style="font-style:normal;font-weight:normal;">†</span>' .. link
	end
	if string.sub(taxon, -2) == '/?' and not string.find(link, '?', 1, true) then
		link = link .. '<span style="font-style:normal;font-weight:normal;"> (?)</span>'
	end
	return link
end

--[[========================== showRankTable ================================
Returns a wikitable showing the ranks and their values as set up by
getRankTable().
Usage: {{#invoke:Autotaxobox|showRankTable}}
=============================================================================]]
function p.showRankTable(frame)
	local rankTable = l.getRankTable()
	local res = '{| class="wikitable sortable"\n|+ Ranks checked in taxonomy templates\n! Rank !! Shown as !! Value\n'
	for k, v in pairs(rankTable) do
		local rankShown = frame:expandTemplate{ title = 'Template:Anglicise rank', args = { k } }
		res = res .. TableRow .. l.tableCell(k) .. l.tableCell(rankShown) .. l.tableCell(v)
	end
	return res .. TableEnd
end

--[[============================== find =====================================
Returns the taxon above the specified taxon with a given rank.
Usage: {{#invoke:Autotaxobox|find|TAXON|RANK}}
=============================================================================]]
function p.find(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then return '<span class="error">no taxon supplied</span>' end
	local rank = frame.args[2] or ''
	if rank == '' then return '<span class="error">no rank supplied</span>' end
	local inHierarchy = true -- still in the taxonomic hierarchy or off the top?
	local searching = true -- still searching
	while inHierarchy and searching do
		local ok, parent = p.getTaxonInfoItem(frame, currTaxon, 'parent')
			if ok and parent ~= '' then
			currTaxon = parent
			local ok, currRank = p.getTaxonInfoItem(frame, currTaxon, 'rank')
			if currRank == rank then
				searching = false
			end
		else
			inHierarchy = false
		end
	end
	if inHierarchy and not searching then return currTaxon
	else return '<span class="error">rank not found</span>'
	end
end

--[[=============================== nth =====================================
External utility function primarily intended for use in checking and debugging.
Returns the nth level above a taxon in a taxonomic hierarchy, where the taxon
itself is counted as the first level.
Usage: {{#invoke:Autotaxobox|nth|TAXON|n=N}}
=============================================================================]]
function p.nth(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then return 'ERROR: no taxon supplied' end
	local n = tonumber(frame.args['n'] or 1)
	if n > MaxSearchLevels then
		return 'Exceeded maximum number of levels allowed (' .. MaxSearchLevels .. ')'
	end
	local i = 1
	local inHierarchy = true -- still in the taxonomic hierarchy or off the top?
	while i < n and inHierarchy do
		local ok, parent = p.getTaxonInfoItem(frame, currTaxon, 'parent')
			if ok and parent ~= '' then
			currTaxon = parent
			i = i + 1
		else
			inHierarchy = false
		end
	end
	if inHierarchy then return currTaxon
	else return 'Level ' .. n .. ' is past the top of the taxonomic hierarchy'
	end
end

--[[============================= nLevels ===================================
External utility function primarily intended for use in checking and debugging.
Returns number of levels in a taxonomic hierarchy, starting from
the supplied taxon as level 1.
Usage: {{#invoke:Autotaxobox|nLevels|TAXON}}
=============================================================================]]
function p.nLevels(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then return 'ERROR: no taxon supplied' end
	local i = 1
	local inHierarchy = true -- still in the taxonomic hierarchy or off the top?
	while inHierarchy and i < MaxSearchLevels  do
		local ok, parent = p.getTaxonInfoItem(frame, currTaxon, 'parent')
		if ok and parent ~= '' then
			currTaxon = parent
			i = i + 1
		else
			inHierarchy = false
		end
	end
	if inHierarchy then return MaxSearchLevels .. '+'
	else return i
	end
end

--[[============================= listAll ===================================
External utility function primarily intended for use in checking and debugging.
Returns a comma separated list of a taxonomic hierarchy, starting from
the supplied taxon.
Usage: {{#invoke:Autotaxobox|listAll|TAXON}}
=============================================================================]]
function p.listAll(frame)
	local currTaxon = frame.args[1] or ''
	if currTaxon == '' then return 'ERROR: no taxon supplied' end
	return l.doListAll(l.makeTable(frame, currTaxon))
end

function l.doListAll(taxonTable, taxonRankTable)
	local lst = taxonTable[1] .. '-' .. tostring(taxonRankTable[1])
	for i = 2, taxonTable.n, 1 do
		lst = lst .. ', ' .. taxonTable[i] .. '-' .. taxonRankTable[i]
	end
	return lst
end

--[[=========================== removeQualifier ================================
External utility function to remove a qualifier (any part after a "/") from a 
taxon name.
Usage: {{#invoke:Autotaxobox|removeQualifier|TAXON}}
=============================================================================]]
function p.removeQualifier(frame)
	local baseName, qualifier = l.stripExtra(frame.args[1])
	return baseName
end

--[[=========================================================================
Internal functions
=============================================================================]]

--[[= = = = = = = = = = = = stripExtra  = = = = = = = = = = = = = = = = = = =
Internal utility function to strip off any extra parts of a taxon name, i.e.
anything after a '/'. Thus 'Felidae/?' would be split into 'Felidae' and '?'.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.stripExtra(taxonName)
	local i = mw.ustring.find(taxonName, '/', 1, true)
	if i then
		return mw.ustring.sub(taxonName, 1, i-1), mw.ustring.sub(taxonName, i, -1)
	else
		return taxonName, ''
	end
end

--[[= = = = = = = = = = = = splitTaxonName  = = = = = = = = = = = = = = = = =
Internal utility function to split a taxon name into its parts and return
them. Possible formats include:
* taxon
* taxon (disambig)
* taxon (Subgenus)
* taxon/qualifier
* combinations, e.g. taxon (disambig)/qualifier
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.splitTaxonName(taxon)
	-- get any qualifier present
	local qualifier = ''
	local i = mw.ustring.find(taxon, '/', 1, true)
	if i then
		qualifier = mw.ustring.sub(taxon, i+1, -1)
		taxon = mw.ustring.sub(taxon, 1, i-1)
	end
	-- get any disambiguator or subgenus
	local disambig = ''
	local subgenus = ''
	i = mw.ustring.find(taxon, ' (', 1, true)
	if i then
		local parenTerm = mw.ustring.sub(taxon, i+2, -2)
		taxon = mw.ustring.sub(taxon, 1, i-1)
		local char1 = mw.ustring.sub(parenTerm, 1, 1)
		if char1 == mw.ustring.lower(char1) then
			disambig = parenTerm
		else
			subgenus = parenTerm
		end
	end
	return taxon, disambig, subgenus, qualifier
end

--[[= = = = = = = = = = = = matchTaxonLink  = = = = = = = = = = = = = = = = =
Function to determine whether the taxon name derived from the name of the 
taxonomy template (passed in the parameter taxon) matches the link text
(passed in the parameter linkText).
The taxon name may have any of the formats:
* baseTaxon/qualifier
* baseTaxon (disambig)
* baseTaxon (Subgenus) [distinguished by the capital letter]
* a qualifier may be present after the previous two formats.

Examples of matches (baseTaxon ~ linkText):
* Pinus ~ Pinus
* Pinus sect. Trifoliae ~ Pinus sect. Trifoliae
* Pinus sect. Trifoliae ~ ''Pinus'' sect. ''Trifoliae'' [italic markers ignored]
* Pinus sect. Trifoliae ~ P. sect. Trifoliae [abbreviated genus name matches]
* Bombus (Pyrobombus) ~ Bombus (Pyrobombus)
* Bombus (Pyrobombus) ~ B. (Pyrobombus)
* Bombus (Pyrobombus) ~ Pyrobombus [link text may just be the subgenus]
* Heteractinida ~ "Heteractinida" [double-quotes are ignored in link text]
* "Heteractinida" ~ Heteractinida [double-quotes are ignored in base taxon name]
* Incertae sedis ~ anything [link text is ignored for matching in this case]
* Cetotheriidae with qualifier=? ~ Cetotheriidae (?)
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.matchTaxonLink(taxon, linkText, rankBelowGenus)
	local dummy
	linkText, dummy = mw.ustring.gsub(linkText, "''", '') -- remove any italic wikitext in the link text
	linkText, dummy = mw.ustring.gsub(linkText, '<.->', '') -- strip all tags used to format the link text
	linkText, dummy = mw.ustring.gsub(linkText, '"', '') -- remove any occurrences of " in the link text
	local baseTaxon, disambig, subgenus, qualifier = l.splitTaxonName(taxon) -- split up the taxon name
	baseTaxon, dummy = mw.ustring.gsub(linkText, '"', '') -- remove any occurrences of " in the base taxon name
	local match = linkText == baseTaxon or
	              linkText == subgenus or
	              linkText == baseTaxon .. ' (' .. subgenus .. ')' or
	              linkText ==  mw.ustring.sub(baseTaxon, 1, 1) .. '. (' .. subgenus .. ')' or
	              baseTaxon == 'Incertae sedis' or
	              rankBelowGenus and linkText == mw.ustring.gsub(baseTaxon, '([A-Z]).- (.*)', '%1. %2') or 
	              mw.ustring.find(qualifier, '?', 1, true) and mw.ustring.find(linkText, baseTaxon, 1, true) == 1
	return match
end

--[[= = = = = = = = = = = = = makeTable = = = = = = = = = = = = = = = = = = =
Internal utility function to return a table (array) constructed from a
taxonomic hierarchy stored in "Template:Taxonomy/..." templates.
TABLE.n holds the total number of taxa; TABLE[1]..TABLE[TABLE.n] the taxon
names.
The last taxon in the table will either (a) have a taxonomy template but with
no parent given (e.g. 'Life') or (b) not have a taxonomy template.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.makeTable(frame, currTaxon)
	local taxonTable = {}
	local taxonRankTable = {}
	local ok, rank, parent
	local i = 1
	local topReached = false -- reached the top of the taxonomic hierarchy?
	repeat
		taxonTable[i] = currTaxon
		ok, rank = p.getTaxonInfoItem(frame, currTaxon, 'rank')
		if ok then taxonRankTable[i] = string.lower(rank) else taxonRankTable[i] = '' end
		ok, parent = p.getTaxonInfoItem(frame, currTaxon, 'parent')
		if ok and parent ~= '' then
			currTaxon = parent
			i = i + 1
		else
			topReached = true -- reached the top of the hierarchy or tried to use a non-existent taxonomy template
		end
	until topReached or i > MaxSearchLevels
	taxonTable.n = math.min(i, MaxSearchLevels)
	return taxonTable, taxonRankTable
end

--[[= = = = = = = = = = = = getRankTable  = = = = = = = = = = = = = = = = = =
Internal utility function to set up a table of numerical values corresponding
to 'Linnaean' ranks, with upper ranks having higher values. In a valid
taxonomic hierarchy, a lower rank should never have a higher value than a
higher rank. The actual numerical values are arbitrary so long as they are
ordered.
The ranks should correspond to those in Template:Anglicise ranks.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.getRankTable()
	return {
		classis = 1400,
		cohort = 1100,
		divisio = 1500,
		domain = 1700,
		familia = 800,
		forma = 100,
		genus = 600,
		grandordo = 1005,
		['grandordo-mb'] = 1002,
		hyperfamilia = 805;
		infraclassis = 1397,
		infralegio = 1197,
		infraordo = 997,
		infraphylum = 1497,
		infraregnum = 1597,
		infratribus = 697,
		legio = 1200,
		magnordo = 1006,
		microphylum = 1495,
		micrordo = 995,
		mirordo = 1004,
		['mirordo-mb'] = 1001,
		nanophylum = 1494,
		nanordo = 994,
		ordo = 1000,
		parafamilia = 800,
		parvclassis = 1396; -- same as subterclassis
		parvordo = 996,
		phylum = 1500,
		regnum = 1600,
		sectio = 500,
		--series = 400, used too inconsistently to check
		species = 300,
		subclassis = 1398,
		subcohort = 1098,
		subdivisio = 1498,
		subfamilia = 798,
		subgenus = 598,
		sublegio = 1198,
		subordo = 998,
		subphylum = 1498,
		subregnum = 1598,
		subsectio = 498,
		subspecies = 298,
		subterclassis = 1396; -- same as parvclassis
		subtribus = 698,
		superclassis = 1403,
		supercohort = 1103,
		superdivisio = 1503,
		superdomain = 1703,
		superfamilia = 803,
		superlegio = 1203,
		superordo = 1003,
		superphylum = 1503,
		superregnum = 1603,
		supertribus = 703,
		tribus = 700,
		varietas = 200,
		zoodivisio = 1300,
		zoosectio = 900,
		zoosubdivisio = 1298,
		zoosubsectio = 898,
	}
end

--[[= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
Function to look up the arbitrary numerical value of a rank in a rank value
table. "Ichno" and "oo" ranks are not stored separately, so if present the
prefix is removed.
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.lookupRankVal(rankValTable, rank)
	local rankVal = rankValTable[rank]
	if not rankVal then
		-- may be an "ichno" or "oo" rank; try removing "ichno-" or "oo-"
		local baseRank = mw.ustring.gsub(mw.ustring.gsub(rank, '^ichno', ''), '^oo', '')
		if baseRank == 'rdo' then baseRank = 'ordo' end
		-- if an "ichno" or "oo" rank, lower rank value slightly so it is ok below the base rank
		rankVal = rankValTable[baseRank]
		if rankVal then
			rankVal = rankVal - 0.1
		end
	end
	return rankVal
end

--[[= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =]]
function l.tableCell(arg1, arg2)
	local text, style
	if arg2 then
		style = arg1
		text = arg2
	else
		style = ''
		text = arg1
	end
	local res = '|'
	if style ~= '' then
		res = res .. style .. '|'
	end
	return res .. text .. '\n'
end

return p