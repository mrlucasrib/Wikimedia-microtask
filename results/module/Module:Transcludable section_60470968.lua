-- Module to create selectively transcluded sections using syntax which is
-- compatible with [[Module:Sports table]] and [[Module:Sports results]]

require('Module:No globals')

local p = {}

-- Main function
function p.main(frame)
	-- Declare locals
	local tsection = frame:getParent().args['transcludesection'] or ''
	local bsection = frame.args['section'] or frame.args['1'] or ''
	local editlink = frame.args['edit'] or ''

	-- Exit early if we are using section transclusion for a different section
	if( tsection ~= '' and bsection ~= '' ) then
		if( tsection ~= bsection ) then
			return ''
		end
	end
	
	local text = frame.args['text'] or ''
	
	-- Get VTE button text (but only for non-empty text)
	local VTE_text = ''
	if (text ~= '' and editlink ~= '') then
		VTE_text = frame:expandTemplate{ title = 'navbar', args = { mini=1, style='float:right', brackets=1, editlink} }
	end
	return VTE_text .. text
end
 
return p