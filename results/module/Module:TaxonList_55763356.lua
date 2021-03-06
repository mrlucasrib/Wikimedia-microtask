--[[
This module provides the core functionality to a set of templates used to
display a list of taxon name/authority pairs, with the taxon names optionally
italicized, wikilinked and/or emboldened. Such lists are usually part of
taxoboxes.
]]

-- use a function from Module:TaxonItalics to italicize a taxon name
local TaxonItalics = require("Module:TaxonItalics")

local p = {}

--[[=========================================================================
Utility function to strip off any initial † present to mark the taxon as
extinct. The † must not be italicized, emboldened, or included in the
wikilinked text, so needs to be added back afterwards.
† is assumed to be present as one of:
* the unicode character †
* the HTML entity &dagger;
* the output of {{extinct}} – this will have been expanded before reaching this
  module and is assumed to have the form '<span ... </span>'
The function returns two values: the taxon name with any † before it removed
and either '†' if it was present or the empty string if not.
=============================================================================]]
function p.stripDagger(taxonName)
	local dagger = ''
	if mw.ustring.sub(taxonName,1,1) == '†' then
		taxonName = mw.ustring.sub(taxonName,2,#taxonName)
		dagger = '†'
	else 
		if string.sub(taxonName,1,8) == '&dagger;' then
			taxonName = string.sub(taxonName,9,#taxonName)
			dagger = '†'
		else
			-- did the taxon name originally have {{extinct}} before it?
			if (string.sub(taxonName,1,5) == '<span') and mw.ustring.find(taxonName, '†') then
				taxonName = string.gsub(taxonName, '^.*</span>', '', 1)
				dagger = '†'
			end
		end
	end
	return taxonName, dagger
end

--[[=========================================================================
The function returns a list of taxon names and authorities, appropriately
formatted.
Usage:
{{#invoke:TaxonList|main
|italic = yes - to italicize the taxon name
|linked = yes - to wikilink the taxon name
|bold = yes - to emboldent the taxon name
|incomplete = yes - to output "(incomplete)" at the end of the list
}}
The template that transcludes the invoking template must supply an indefinite
even number of arguments in the format
|Name1|Author1 |Name2|Author2| ... |NameN|AuthorN
=============================================================================]]
function p.main(frame)
	local italic = frame.args['italic'] == 'yes'
	local bold = frame.args['bold'] == 'yes'
	local linked = frame.args['linked'] == 'yes'
	if bold then linked = false end -- must not have bold and wikilinked
	local incomplete = frame.args['incomplete'] == 'yes'
	local taxonArgs = frame:getParent().args
	local result = ''
	-- iterate over unnamed variables
	local taxonName
	local dagger
	local first = true -- is this the first of a taxon name/author pair?
	for param, value in pairs(taxonArgs) do
		if tonumber(param) then
			if first then
				taxonName = mw.text.trim(value)
				-- if necessary separate any initial † from the taxon name
				if linked or italic or bold then
					taxonName, dagger = p.stripDagger(taxonName)
				else
					dagger = ''
				end
				if linked and not italic then
					taxonName = '[[' .. taxonName .. ']]'
				end
				if italic then
					taxonName = TaxonItalics.italicizeTaxonName(taxonName, linked)
				end
				if bold then
					taxonName = '<b>' .. taxonName .. '</b>'
				end
				result = result .. '<li>' .. dagger .. taxonName
			else
				result = result .. ' <small>' .. value .. '</small></li>'
			end
			first = not first
		end
	end
	if incomplete then
		result = result .. '<small>(incomplete list)</small>'
	end
	return '<ul style="plainlist">' .. result .. '</ul>'
end

return p