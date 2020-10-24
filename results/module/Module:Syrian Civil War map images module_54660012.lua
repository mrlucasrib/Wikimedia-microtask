return { 
	marks = { 
-- Road map
{lat= 34.212, long= 38.8, mark= "Syria location map road overlay.svg", marksize= 2500},
		
-- Detailed citymaps
{lat = 36.103, long= 37.308, mark= "Rif_Aleppo2.svg", marksize= 184, label= "[[Battle of Aleppo (2012–2016)|Aleppo]]", link= "Battle of Aleppo (2012–2016)", label_size= 0},
{lat = 36.103, long= 37.308, mark= "Rif_Aleppo2.svg", marksize= 184}, -- This is here so that the mobile version can see the minimap at right size
{lat= 34.212, long= 38.8, mark= "Syria location map road overlay.svg", marksize= 2500}, -- Syria road map
{lat= 37.0, long= 41.225, mark= "Battle of Qamishli.svg", marksize= 80, label= "[[Cities and towns during the Syrian Civil War#Qamishli|Qamishli]]", link= "Cities and towns during the Syrian Civil War#Qamishli", label_size= 100, position= "left"},
{lat= 37.0, long= 41.225, mark= "Battle of Qamishli.svg", marksize= 80}, -- This is here so that the mobile version can see the minimap at right size

-- Scale gifs 
{lat= 37.23, long= 35.282, mark= "Graphical scale.gif", marksize= 156 }, -- Kilometers scale NW
{lat= 37.23, long= 42.35, mark= "Graphical scale.gif", marksize= 156 }, -- Kilometers scale NE
{lat= 32, long= 35.282, mark= "Graphical scale.gif", marksize= 156 }, -- Kilometers scale SW
{lat= 32, long= 42.35, mark= "Graphical scale.gif", marksize= 156 }, -- Kilometers scale SE
}, 
	containerArgs = {
		'Syria',
		AlternativeMap = 'Syria location map3.svg',
		float = 'left',
		width = 2500,
	},
}