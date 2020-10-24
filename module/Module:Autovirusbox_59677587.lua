require('Module:No globals')
local ItalicTitle = require('Module:Italic title')
local p = {} -- functions made public
local l = {} -- internal functions, kept separate

-- =============================================================================
-- main implements Template:Virusbox; see the documentation of that template
-- for details.
-- =============================================================================

function p.main(frame)
	local args
	if frame.args['direct'] == 'yes' then args = frame.args
	else args = frame:getParent().args end
	-- ---------------------------------------------------------------------
	-- pick up taxobox parameters from the caller that need to be processed;
	-- most are passed on unchanged
	-- ---------------------------------------------------------------------
	local name = args['name'] or ''
	local taxon = args['taxon'] or ''
	local parent = args['parent'] or ''
	local species = args['species'] or ''
	local strain = args['strain'] or ''
	local serotype = args['serotype'] or ''
	local virus = args['virus'] or ''
	local displayParents = args['display_parents'] or '1'
--[[
	local authority = args['authority'] or ''
	local parentAuthority = args['parent_authority'] or ''
	local gParentAuthority = args['grandparent_authority'] or ''
	local ggParentAuthority = args['greatgrandparent_authority'] or ''
	local gggParentAuthority = args['greatgreatgrandparent_authority'] or ''
	local typeGenusAuthority = args['type_genus_authority'] or ''
]]
	local subdivision = args['subdivision'] or ''
	local subdivisionRanks = args['subdivision_ranks'] or ''
	local subdivisionRef = args['subdivision_ref'] or args['subdivision ref'] or ''

	-- ------------------------------------------------------
	-- set the taxobox parameters determined by this function
	-- ------------------------------------------------------
	local autoTaxon, autoTaxonType, infraTaxon, infraTaxonRank, targetTaxon, targetTaxonRank = l.paramChk(frame, taxon, parent, species, strain, serotype, virus)
	-- set default taxobox name/title
	local italicsRequired = frame:expandTemplate{ title = 'Is italic taxon', args = {targetTaxonRank, virus='yes'} } == 'yes'
	if name == '' then
		if autoTaxonType == 'ERROR' then
			name = '<span class="error">ERROR: parameter(s) specifying taxon are incorrect; see [[Template:Virusbox/doc#Usage|documentation]]</span>'
		else
			name = targetTaxon
			if italicsRequired then
				name = "''" .. targetTaxon .. "''"
			end
		end
	end
	-- the page name (title) should be italicized if it's the same as the target taxon and that is italicized
	local currentPage = mw.title.getCurrentTitle()
	local pagename = currentPage.text
	if pagename == targetTaxon then
		if italicsRequired then ItalicTitle._main({}) end
	end
	-- is the auto-taxon name bold or linked (i.e. will it be the last row in the taxobox or not)?
	local boldFirst = 'bold' 
	if autoTaxonType == 'PARENT' then boldFirst = 'link' end
	-- italicize and link species name, or embolden if nothing below
	if species ~= '' then
		if infraTaxon ~= '' then
			species = "''[["..species.."]]''"
		else
			species = "'''''"..species.."'''''"
		end
	end
	-- embolden lowest rank
	if infraTaxon ~= '' then
		infraTaxon = "'''"..infraTaxon.."'''"
	end
	-- set offset and fix display_parents if there are ranks below autoTaxon
	local offset = 0
	if infraTaxon ~= '' then offset = offset + 1 end
	if species ~= '' then offset = offset + 1 end
	if offset ~= 0 then
		displayParents = tostring(tonumber(displayParents) - offset)
	end
	-- fill in a missing subdivision_ranks parameter
	if subdivision ~= '' and subdivisionRanks == '' then
		subdivisionRanks =  frame:expandTemplate{ title = 'Children rank', args = {targetTaxonRank} }
	end
	-- ------------------------------------------------
	-- now call Taxobox/core with all of its parameters
	-- ------------------------------------------------
	local res = frame:expandTemplate{ title = 'Taxobox/core', args =
		{ ['edit link'] = 'e',
		  virus = 'yes',
		  colour = frame:expandTemplate{ title = 'Taxobox colour', args = { 'virus' } },
		  name = name,
		  parent = autoTaxon,
		  bold_first = boldFirst,
--[[
		  authority = authority,
          parent_authority = parentAuthority,
		  grandparent_authority = gparentAuthority,
		  grandparent_authority = gparentAuthority,
		  greatgrandparent_authority = ggparentAuthority,
		  greatgreatgrandparent_authority = gggparentAuthority,
		  offset = tostring(offset),
]]		  
		  image = args['image'] or '',
		  image_upright = args['image_upright'] or '',
		  image_alt = args['image_alt'] or '',
		  image_caption = args['image_caption'] or '',
		  image2 = args['image2'] or '',
		  image2_upright = args['image2_upright'] or '',
		  image2_alt = args['image2_alt'] or '',
		  image2_caption = args['image2_caption'] or '',
		  species = species,
		  virus_infrasp = infraTaxon,
		  virus_infrasp_rank =  infraTaxonRank,
		  display_taxa = displayParents,
		  type_genus = args['type_genus'] or '',
		  --type_genus_authority = args['type_genus_authority'] or '',
		  type_species = args['type_species'] or '',
		  --type_species_authority = args['type_species_authority'] or ''
		  subdivision_ranks = subdivisionRanks,
		  subdivision_ref = subdivisionRef,
		  subdivision = subdivision,
		  type_strain = args['type_strain'] or '',
		  synonyms = args['synonyms'] or '',
		  synonyms_ref = args['synonyms_ref'] or '',
		  range_map = args['range_map'] or '',
		  range_map_upright = args['range_map_upright'] or '',
		  range_map_alt = args['range_map_alt'] or '',
		  range_map_caption = args['range_map_caption'] or '',
		} }
	-- put page in error-tracking category if required
	if autoTaxonType == 'ERROR' then
		res = res .. frame:expandTemplate{ title = 'Main other', args = {'[[Category:Virusboxes with incorrect parameters that specify taxon]]'} }
	end
	return res
end

-- =============================================================================
-- paramChk checks the taxon-specifying parameters for consistency, selecting
-- the target taxon (the taxon that is the target of the taxobox), the
-- infra-taxon (the taxon below species level), if any, and the 'auto-taxon',
-- the taxon that is the entry point into the automated taxobox system.
-- =============================================================================

function l.paramChk(frame, taxon, parent, species, strain, serotype, virus)
	-- set target taxon and infra-taxon
	local infraTaxon = ''
	local infraTaxonRank = ''
	local targetTaxon
	local targetTaxonRank
	if strain ~= '' then
		infraTaxon = strain
		infraTaxonRank = 'strain'
		targetTaxon = infraTaxon
		targetTaxonRank = infraTaxonRank
	elseif serotype ~= '' then
		infraTaxon = serotype
		infraTaxonRank = 'serotype'
		targetTaxon = infraTaxon
		targetTaxonRank = infraTaxonRank
	elseif virus ~= '' then
		infraTaxon = virus
		infraTaxonRank = 'virus'
		targetTaxon = infraTaxon
		targetTaxonRank = infraTaxonRank
	elseif species ~= '' then
		targetTaxon = species
		targetTaxonRank = 'species'
	else
		targetTaxon = taxon
		targetTaxonRank = frame:expandTemplate{ title = 'Taxon info', args = {targetTaxon, 'rank' } }
	end
	-- set the autotaxon (entry into the automated taxobox system) if the
	-- parameters are valid; the default is invalid
	local autoTaxon = ''
	local autoTaxonType = 'ERROR'
	if taxon ~= '' then
		if parent..species..infraTaxon  == '' then
			autoTaxon = taxon
			autoTaxonType = 'TAXON'
		end
	elseif parent ~= '' and  (species ~='' or infraTaxon ~= '') then
		autoTaxon = parent
		autoTaxonType = 'PARENT'
	end
	-- check for multiple infra-taxa
	local count = 0
	if strain ~= '' then count = count + 1 end
	if serotype ~= '' then count = count + 1 end
	if virus ~= '' then count = count + 1 end
	if count > 1 then autoTaxonType = 'ERROR' end
	return autoTaxon, autoTaxonType, infraTaxon, infraTaxonRank, targetTaxon, targetTaxonRank
end

return p