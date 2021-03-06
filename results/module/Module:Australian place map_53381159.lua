-- This module implements the selection of the location map
-- in [[Template:Infobox Australian place]] and [[Template:Infobox Australian road]]
require('Module:No globals')
local p = {}

local function isnotblank( s ) return s and s ~= '' end

local statenames = {
	sa = 'South Australia',
	vic = 'Victoria',
	nsw = 'New South Wales',
	qld = 'Queensland',
	nt = 'Northern Territory',
	wa = 'Western Australia',
	tas = 'Tasmania',
	act = 'Australian Capital Territory',
	jbt = 'Jervis Bay Territory',
	ni = 'Norfolk Island'
}
local mapwidths = {
	sa = 230,
	qld = 190,
	nt = 190,
	wa = 180,
	tas = 210,
	act = 180
}

function p.main(frame)
	local largs = frame:getParent().args
	local place_type = (largs.type or ''):lower()
	local map_name = largs.map_type or ''
	local map_type = (largs.map_type or 'auto'):lower()
	local state_abbr = (largs.state or ''):lower()
	local map_width = 270
	
	local coords = largs.coordinates or ''
	local coordsa = largs.coordinates_a or ''
	local coordsb = largs.coordinates_b or ''
	
	-- Default for LGAs is nomap
	-- Default for everywhere else is auto
	if map_type == '' or map_type == 'auto' then
		if place_type == 'lga' then
			map_type = 'nomap'
		else
			map_type = 'auto'
		end
	end
	-- Apply legacy parameters
	if isnotblank( largs.alternative_location_map ) then
		map_type = largs.alternative_location_map
		map_name = map_type
	elseif isnotblank( largs.force_national_map ) then
		map_type = 'national'
		map_name = 'Australia'
	elseif isnotblank( largs.use_lga_map ) then
		map_type = 'lga'
	end
	-- Process the value in map_type 
	if map_type == 'state' or map_type == 'auto' or map_type == 'lga' then
		map_name = 'Australia ' .. (statenames[state_abbr] or '')
		map_width = mapwidths[state_abbr] or 270
		if  map_type == 'lga' then
			map_name = map_name  .. ' ' .. (largs.lga or '')
			map_width = mapwidths[state_abbr] or 270
		end
	elseif map_type == 'national' or map_type == 'australia' then
		map_name = 'Australia'
	end
	
	if isnotblank(coords) or isnotblank(coordsa) then
	else
		map_type = 'nomap'
	end
	
	-- Finally build the map
	if map_type ~= 'nomap' then
		local caption = largs.pushpin_map_caption or ''
		
		if caption ~= '' then caption = '<small>' .. caption .. '</small>' end
		
		if isnotblank(coordsa) then
			return frame:expandTemplate{
				title = 'Location map many',
				args = {
					map_name,
					relief = largs.relief or '',
					label1 = isnotblank(coordsb) and isnotblank(largs.direction_a) and (largs.direction_a .. ' end') or (largs.road_name or ''),
					coordinates1 = coordsa,
					position1 = isnotblank(largs.pushpin_label_position_a) and largs.pushpin_label_position_a or 'left',
					coordinates2 = coordsb,
					label2 = isnotblank(largs.direction_b) and (largs.direction_b .. ' end') or '',
					position2 = isnotblank(largs.pushpin_label_position_b) and largs.pushpin_label_position_b or 'left',
					marksize = 8,
					float = 'center',
					caption = caption,
					border = 'infobox',
					width = map_width,
					alt = largs.map_alt or ''
					}
				}
		end
		return frame:expandTemplate{
			title = 'Location map', 
			args = { 
				map_name,
				label = largs.name or '',
				relief = largs.relief or '',
				coordinates = coords,
				marksize = 6,
				position = largs.pushpin_label_position or '',
				float = 'center',
				caption = caption,
				border = 'infobox',
				width = map_width,
				alt = largs.map_alt or ''
			}
		}
	end
	return ''
end

return p