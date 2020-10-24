local p = {}

function p.files(frame)
	local nav  = require( 'Module:Navbox' )
	local conf = require( 'Module:Authority control' ).conf
	local exclude = {
		['MBAREA'] = 'redundant [[MusicBrainz]] link',
		['MBI'] = 'redundant [[MusicBrainz]] link',
		['MBL'] = 'redundant [[MusicBrainz]] link',	
		['MBP'] = 'redundant [[MusicBrainz]] link',	
		['MBRG'] = 'redundant [[MusicBrainz]] link',
		['MBS'] = 'redundant [[MusicBrainz]] link',
		['MBW'] = 'redundant [[MusicBrainz]] link',
	}
	
	local elements = {}
	for _, c in pairs( conf ) do
		if exclude[c[1]] == nil then
			table.insert( elements, c[2] )
		end
	end
	
	return nav._navbox( {
			name        = 'Authority control files',
			navboxclass = 'authority-control-files',
			title       = '[[Authority control|Authority control files]]',
			bodyclass   = 'hlist',
			state       = 'collapsed',
			list1       = table.concat( elements, ' • ' )
			} )
end

return p