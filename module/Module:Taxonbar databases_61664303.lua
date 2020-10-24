local p = {}

function p.list(frame)
	local nav  = require( 'Module:Navbox' )
	local conf = require( 'Module:Taxonbar/conf' ).databases
	local exclude = {
		['Wikidata'] = 'not citable',
		['Wikispecies'] = 'not citable',
		['emonocotfamily'] = 'redundant [[eMonocot]] link',
		['WSC genus'] = 'redundant [[World Spider Catalog]] link',
		['WSC family'] = 'redundant [[World Spider Catalog]] link',
	}
	local args = frame:getParent().args
	
	local elements = {}
	for _, c in pairs( conf ) do
		if exclude[c[1]] == nil then
			local c3 = tonumber(c[3])
			if (c3 and c3 > 0) or (c3 == nil) then
				table.insert( elements, c[2] )
			end
		end
	end
	
	return nav._navbox( {
			name        = 'Taxonbar databases',
			title       = '[[Help:Taxon identifiers|Taxonbar databases]]',
			bodyclass   = 'hlist',
			state       = args.state or 'collapsed',
			list1       = table.concat( elements, ' • ' )
			} )
end

return p