--
-- This module implements [[Template:Bumps chart]]
-- which was originally created by [[User:Richard B]]
--
local p = {}

function p.chart(frame)
	local args = frame:getParent().args
	-- compute the number of images plus 1
	local cellcount = 0
	for k, v in pairs( args ) do
		if type( k ) == 'number' then
			cellcount = math.max(cellcount, k)
			args[k] = mw.ustring.gsub( args[k], '^%s*(.-)%s*$', '%1' )
		end
	end
	-- compute the number of rows
	local rows = math.ceil((cellcount - 1) / 4)
    -- size is stored in 4*rows + 1
    local size = mw.ustring.match(args[4*rows+1] or '', '[%d]+' ) or '28'
	-- create the root table
	local root = mw.html.create('table')
	root
		:css('border-collapse', 'collapse')
		:attr('cellspacing', '0')
		:attr('cellpadding', '0')
	-- add the rows
	for i=1,rows do
		local row = root:tag('tr')
		for k=1,4 do
			row:tag('td')
				:wikitext('[[File:bumps_' .. (args[4*(i-1)+k] or '') .. '.svg|' .. size .. 'px]]')
		end
	end
	return tostring(root)
end

return p