require('Module:No globals')
local TaxonItalics = require('Module:TaxonItalics')
local Autotaxobox = require('Module:Autotaxobox')
local ItalicTitle = require('Module:Italic title')
local p = {} -- functions made public
local l = {} -- nonpublic internal functions and variables global to the module
l.system = '' -- '' for normal scientific classification (default)
              -- 'ichnos' for trace fossil classification
              -- 'veterovata' for egg fossil classification

-- =============================================================================
-- ichnobox implements Template:Ichnobox; see the documentation of that
-- template for details.
-- The only difference from Template:Automatic taxobox is in the taxobox colour
-- and classification link.
-- =============================================================================

function p.ichnobox(frame)
	l.system = 'ichnos'
	return p.automaticTaxobox(frame)
end

-- =============================================================================
-- oobox implements Template:Oobox; see the documentation of that
-- template for details.
-- The only difference from Template:Automatic taxobox is in the taxobox colour
-- and classification link.
-- =============================================================================

function p.oobox(frame)
	l.system = 'veterovata'
	return p.automaticTaxobox(frame)
end

-- =============================================================================
-- automaticTaxobox implements Template:Automatic taxobox; see the documentation
-- of that template for details.
-- It also implements Template:Ichnobox and Template:Oobox. The small
-- differences are signalled by the module-wide variable l.system.
-- The following parameters present in the old template code version of
-- Template:Automatic taxobox were not used and have not been implemented:
--   image_caption_align
--   image2_caption_align
--   binomial2
--   binomial2_authority
--   binomial3
--   binomial3_authority
--   binomial4
--   binomial4_authority
-- =============================================================================

function p.automaticTaxobox(frame)
	local args
	if frame.args['direct'] == 'yes' then args = frame.args
	else args = frame:getParent().args end
	-- ---------------------------------------------------------------------
	-- pick up taxobox parameters from the caller that need to be processed;
	-- most will be passed on unchanged
	-- ---------------------------------------------------------------------
	local pagename = args['pagename'] or '' -- for testing and debugging only
	local italicTitle = args['italic_title'] or args['italic title'] or ''
	local ichnos = ''
	if l.system == 'ichnos' then ichnos = 'true' end
	local veterovata = ''
	if l.system == 'veterovata' then veterovata = 'true' end
	local fossilRange = args['fossil_range'] or args['fossil range'] or args['temporal_range'] or args['temporal range'] or ''
    local oldestFossil = args['oldest_fossil'] or args['oldest fossil'] or ''
    local youngestFossil =  args['youngest_fossil'] or args['youngest fossil'] or ''
	local name = args['name'] or ''
	local colourAs = args['color_as'] or args['color as'] or args['colour_as']  or args['colour as'] or ''
	local taxon = args['taxon'] or ''
	local authority = args['authority'] or ''
    local parentAuthority = args['parent_authority'] or args['parent authority'] or ''
	local subdivision = args['subdivision'] or ''
	local subdivisionRef = args['subdivision_ref'] or args['subdivision ref'] or ''
	local subdivisionRanks = args['subdivision_ranks'] or args['subdivision ranks'] or ''
	local manualFlag = 'text' -- marks manually specified ranks
	local binomial = args['binomial'] or args['binomial_'..manualFlag] or args['binomial '..manualFlag] or ''
	local binomialAuthority = args['binomial_authority'] or args['binomial_authority'] or''
	local genusManual = args['genus_'..manualFlag] or args['genus '..manualFlag] or''
	local speciesManual = args['species_'..manualFlag] or args['species '..manualFlag] or''
	-- ------------------------------------------------------
	-- set the taxobox parameters determined by this function
	-- ------------------------------------------------------
    fossilRange = l.setfossilRange(frame, fossilRange, oldestFossil, youngestFossil)
	-- use the base page name as the taxon if the taxon parameter is missing
	local currentPagename = mw.title.getCurrentTitle()
	if pagename == '' then pagename = currentPagename.text end -- pagename para only used in testing and debugging
	local basePagename = mw.ustring.gsub(pagename, '%s+%b()$', '', 1)
	local taxonParaMissingError = false
	if taxon == '' then
		taxonParaMissingError = true
		taxon = basePagename
	end
	-- decide if the page name and taxobox name need to be italicized;
	-- if italic_title is not set, then if the names are the taxon, use its rank to decide
	local ok, taxonRank = Autotaxobox.getTaxonInfoItem(frame, taxon, 'rank') -- taxonRank needed later if not here
	if italicTitle == '' then
		if not (ok and taxonRank ~= '' and
			    frame:expandTemplate{ title = 'Is italic taxon', args = {taxonRank} } == 'yes') then
			italicTitle = 'no'
		end
	end
	--   remove any " (DISAMBIG)" or "/MODIFIER" from the taxon's name;
	--   if the base page name is the same as the base taxon name, then italicization can be applied
	local baseTaxon = mw.ustring.gsub(mw.ustring.gsub(taxon, '%s+%b()$', '', 1), '/.*$', '', 1)
	if italicTitle == '' and basePagename == baseTaxon then
		italicTitle = 'yes'
	end
	-- italicize the page name (page title) if required
	if italicTitle == 'yes' and currentPagename.namespace == 0 then
		ItalicTitle._main({})
	end
	-- set the taxobox name if not supplied, italicizing it if appropriate.
	if name == '' then
		name = basePagename
		if italicTitle == 'yes' then
			name = TaxonItalics.italicizeTaxonName(name, false, false)
		end
		-- name = name ..  '/' .. baseTaxon .. '/' .. nameRank
	end
	-- determine taxobox colour
	local colour = ''
	if colourAs ~= '' then
		colour = frame:expandTemplate{ title = 'Taxobox colour', args = {colourAs} }
	elseif l.system == 'ichnos' then
		colour = frame:expandTemplate{ title = 'Taxobox colour', args = {'Ichnos'} }
	elseif l.system == 'veterovata' then
		colour = frame:expandTemplate{ title = 'Taxobox colour', args = {'Veterovata'} }
	else
		colour = Autotaxobox.getTaxoboxColour(frame, taxon)
	end
	-- fill in a missing subdivision_ranks parameter
	if subdivision ~= '' and subdivisionRanks == '' and ok and taxonRank ~= '' then
		subdivisionRanks =  frame:expandTemplate{ title = 'Children rank', args = {taxonRank} }
	end
	-- set binomial parameters if the target taxon is (unusually) a species
	local genusAuthority = ''
	if binomial == '' then
		if ok and taxonRank == 'species' then
			binomial = TaxonItalics.italicizeTaxonName(taxon, false, false)
			binomialAuthority = authority
		end
	end
	-- handle any manually set ranks
	local boldFirst = ''
	local offset = 0
	if speciesManual ~= '' then
		offset = offset + 1
		binomialAuthority = authority
		if binomial == '' then binomial = '<span class="error">Error: binomial parameter value is missing</span>' end
	end
	if genusManual ~= '' then
		boldFirst = 'link'
		offset = offset + 1
		if offset == 1 then
			genusAuthority = authority
		else
			genusAuthority = parentAuthority
		end
	end
	-- process type genus and type species if present; italicize if they seem not to have an authority attached
	local typeGenus = ''
	local typeGenusAuthority = ''
	local typeSpecies = ''
	local typeSpeciesAuthority = ''
	local typeIchnogenus = ''
	local typeIchnogenusAuthority = ''
	local typeIchnospecies = ''
	local typeIchnospeciesAuthority = ''
	local typeOogenus = ''
	local typeOogenusAuthority = ''
	local typeOospecies = ''
	local typeOospeciesAuthority = ''
	if l.system == '' then
		typeGenus = l.italicizeTypeName(args['type_genus'] or args['type genus'] or '')
		typeGenusAuthority = args['type_genus_authority'] or args['type genus authority'] or ''
		typeSpecies = l.italicizeTypeName(args['type_species'] or args['type species'] or '')
		typeSpeciesAuthority = args['type_species_authority'] or args['type species authority'] or ''
	elseif l.system == 'ichnos' then
		typeIchnogenus = l.italicizeTypeName(args['type_ichnogenus'] or args['type ichnogenus'] or '')
		typeIchnogenusAuthority = args['type_ichnogenus_authority'] or args['type ichnogenus authority'] or ''
		typeIchnospecies = l.italicizeTypeName(args['type_ichnospecies'] or args['type ichnospecies'] or '')
		typeIchnospeciesAuthority = args['type_ichnospecies_authority'] or args['type ichnospecies authority'] or ''
	elseif l.system == 'veterovata' then
		typeOogenus = l.italicizeTypeName(args['type_oogenus'] or args['type oogenus'] or '')
		typeOogenusAuthority = args['type_oogenus_authority'] or args['type oogenus authority'] or ''
		typeOospecies = l.italicizeTypeName(args['type_oospecies'] or args['type oospecies'] or '')
		typeOospeciesAuthority = args['type_oospecies_authority'] or args['type oospecies authority'] or ''
	end
	-- ------------------------------------------------
	-- now call Taxobox/core with all of its parameters
	-- ------------------------------------------------
	local res = frame:expandTemplate{ title = 'Taxobox/core', args =
		{ ichnos = ichnos,
		  veterovata = veterovata,
		  ['edit link'] = 'e',
		  temporal_range = fossilRange,
		  display_taxa = args['display_parents'] or args['display parents'] or '1',
		  parent = taxon,
		  authority = authority,
          parent_authority = parentAuthority,
		  grandparent_authority = args['grandparent_authority'] or args['grandparent authority'] or '',
		  greatgrandparent_authority = args['greatgrandparent_authority'] or args['greatgrandparent authority'] or '',
		  greatgreatgrandparent_authority = args['greatgreatgrandparent_authority'] or args['greatgreatgrandparent authority'] or '',
		  name = name,
		  colour = colour,
		  status = args['status'] or '',
		  status_system = args['status_system'] or args['status system'] or '',
		  status_ref = args['status_ref'] or args['status ref'] or '',
		  status2 = args['status2'] or '',
		  status2_system = args['status2_system'] or args['status2 system'] or '',
		  status2_ref = args['status2_ref'] or args['status2 ref'] or '',
		  trend = args['trend'] or '',
		  extinct = args['extinct'] or '',
		  image = args['image'] or '',
		  upright = args['image_upright'] or args['image upright'] or '',
		  image_alt = args['image_alt'] or args['image alt'] or '',
		  image_caption = args['image_caption'] or args['image caption'] or '',
		  image2 = args['image2'] or '',
		  upright2 = args['image2_upright'] or args['image2 upright'] or '',
		  image2_alt = args['image2_alt'] or args['image2 alt'] or '',
		  image2_caption = args['image2_caption'] or args['image2 caption'] or '',
		  classification_status = args['classification_status'] or args['classification status'] or '',
		  diversity = args['diversity'] or '',
		  diversity_ref = args['diversity_ref'] or args['diversity ref'] or '',
		  diversity_link = args['diversity_link'] or args['diversity link'] or '',
		  bold_first = boldFirst,
		  offset = offset,
		  genus = genusManual,
		  genus_authority = genusAuthority,
		  species = speciesManual,
		  binomial = binomial,
		  binomial_authority = binomialAuthority,
		  trinomial = args['trinomial'] or '',
		  trinomial_authority = args['trinomial_authority'] or args['trinomial authority'] or '',
		  type_genus = typeGenus,
		  type_genus_authority = typeGenusAuthority,
		  type_species = typeSpecies,
		  type_species_authority = typeSpeciesAuthority,
		  type_ichnogenus = typeIchnogenus,
		  type_ichnogenus_authority = typeIchnogenusAuthority,
		  type_ichnospecies = typeIchnospecies,
		  type_ichnospecies_authority = typeIchnospeciesAuthority,
		  type_oogenus = typeOogenus,
		  type_oogenus_authority = typeOogenusAuthority,
		  type_oospecies = typeOospecies,
		  type_oospecies_authority = typeOospeciesAuthority,
		  subdivision = subdivision,
		  subdivision_ref = subdivisionRef,
		  subdivision_ranks = subdivisionRanks,		  
		  type_strain = args['type_strain'] or args['type strain'] or '',
		  range_map = args['range_map'] or args['range map'] or '',
		  range_map_upright = args['range_map_upright'] or args['range map upright'] or '',
		  range_map_alt = args['range_map_alt'] or args['range map alt'] or '',
		  range_map_caption = args['range_map_caption'] or args['range map caption'] or '',
		  range_map2 = args['range_map2'] or args['range map2'] or '',
		  range_map2_upright = args['range_map2_upright'] or args['range map2 upright'] or '',
		  range_map2_alt = args['range_map2_alt'] or args['range map2 alt'] or '',
		  range_map2_caption = args['range_map2_caption'] or args['range map2 caption'] or '',
		  range_map3 = args['range_map3'] or args['range map3'] or '',
		  range_map3_upright = args['range_map3_upright'] or args['range map3 upright'] or '',
		  range_map3_alt = args['range_map3_alt'] or args['range map3 alt'] or '',
		  range_map3_caption = args['range_map3_caption'] or args['range map3 caption'] or '',
		  range_map4 = args['range_map4'] or args['range map4'] or '',
		  range_map4_upright = args['range_map4_upright'] or args['range map4 upright'] or '',
		  range_map4_alt = args['range_map4_alt'] or args['range map4 alt'] or '',
		  range_map4_caption = args['range_map4_caption'] or args['range map4 caption'] or '',
		  synonyms_ref = args['synonyms_ref'] or args['synonyms ref'] or '',
		  synonyms = args['synonyms'] or ''
		} }
	-- put page in error-tracking categories if required
	local errCat1 = ''
	if genusManual ~= '' or speciesManual ~= '' or binomial ~= '' then errCat1 = '[[Category:Automatic taxoboxes using manual parameters]]' end
	local errCat2 = ''
	if taxonParaMissingError then errCat2 = '[[Category:Automatic taxoboxes relying on page title]]' end
	res = res .. frame:expandTemplate{ title = 'Main other', args = {errCat1..errCat2} }
	return res
end

-- =============================================================================
-- l.setfossilRange(frame, fossilRange, oldestFossil, youngestFossil) checks
-- the parameters that determine the fossil range, returning an appropriate
-- range.
-- =============================================================================
-- temporary public function for debugging
function p.chkFossilRange(frame)
	local args = frame.args
	local fossilRange = args['temporal_range'] or args['temporal range'] or args['fossil_range'] or args['fossil range'] or ''
    local oldestFossil = args['oldest_fossil'] or args['oldest fossil'] or ''
    local youngestFossil =  args['youngest_fossil'] or args['youngest fossil'] or ''
    local fossilRange = l.setfossilRange(frame, fossilRange, oldestFossil, youngestFossil)
	return fossilRange
end

function l.setfossilRange(frame, fossilRange, oldestFossil, youngestFossil)
	local res = ''
	if fossilRange ~= '' then
		if mw.ustring.find(frame:expandTemplate{ title = 'Period start', args = { fossilRange } }, '[Ee]rror') then
			res = fossilRange
		else 
			res = frame:expandTemplate{ title = 'Geological range', args = { fossilRange } }
		end
	elseif oldestFossil ~= '' then
		if youngestFossil == '' then youngestFossil = 'Recent' end
		if mw.ustring.find(frame:expandTemplate{ title = 'Period start', args = { oldestFossil } }, '[Ee]rror') or
		   mw.ustring.find(frame:expandTemplate{ title = 'Period start', args = { youngestFossil } }, '[Ee]rror') then
			res = oldestFossil..'–'..youngestFossil
		else
		res = frame:expandTemplate{ title = 'Geological range', args = { oldestFossil, youngestFossil } }
		end
	end
	return res
end

-- =============================================================================
-- l.italicizeTypeName(typeName) checks whether the name of a type genus or
-- species should be italicized, because it appears to be a bare name.
-- =============================================================================

function l.italicizeTypeName(typeName)
	if typeName and not (string.find(typeName, "<", 1, true) or string.find(typeName, ">", 1, true)) then
		typeName = TaxonItalics.italicizeTaxonName(typeName, false, false)
	end
	return typeName
end

-- **************************** Speciesbox support *****************************

-- =============================================================================
-- l.genusOf(str) extracts the genus from a string. Normally this will be the
-- first word of the string (e.g. given 'Bellis perennis' it returns 'Bellis').
-- It also handles a string containing a nothogenus with a spaced × (e.g. given
-- '× Heucherella tiarelloides' it returns '× Heucherella').
-- =============================================================================

function l.genusOf(str)
	local res = mw.ustring.match(str, '^[^%s]*', 1)
	if res == mw.ustring.char(215) then
		res = res .. ' ' .. mw.ustring.match(str, '^[^%s]*', 3)
	end
	return res
end

-- =============================================================================
-- l.doSpeciesboxName(name, taxon, genus, species, basePageTitle, italicTitle)
-- returns a name for a taxobox created by Template:Speciesbox. The name will be
-- italicized if appropriate. It also generates code to italicize the page title
-- if appropropriate. In both cases the test for italicization is that the base
-- taxon name (stripped of any disambiguation or qualifier) is the same as the
-- base page title.
-- =============================================================================

function p.speciesboxName(frame)
	local name = frame.args[1] or ''
	local taxon = frame.args[2] or ''
	local genus = frame.args[3] or ''
	local species = frame.args[4] or ''
	local basePageTitle = frame.args[5] or ''
	local italicTitle = frame.args[6] or ''
	return l.doSpeciesboxName(name, taxon, genus, species, basePageTitle, italicTitle)
end
	
function l.doSpeciesboxName(name, taxon, genus, species, basePageTitle, italicTitle)
	if taxon ~= '' then
		genus = mw.ustring.gsub(l.genusOf(taxon), '/.*$', '', 1) -- strip any qualifier
	else
		genus = mw.ustring.gsub(mw.ustring.gsub(genus, '%s+%b()$', '', 1), '/.*$', '', 1) -- strip any disambig and qualifier
		if species == '' then taxon = genus
		else taxon = genus .. ' ' .. species
		end
	end
	local italicizeP = italicTitle ~= 'no' and (basePageTitle == taxon or basePageTitle == genus)
	if name == '' then
		name = basePageTitle
		if italicizeP then name = TaxonItalics.italicizeTaxonName(name, false, false) end
	end
	if italicizeP then
		if italicTitle ~= 'test' then ItalicTitle._main({})
		else name = name .. '\\Italic title\\' -- for testing and debugging
		end
	end
	return name
end

return p