local p = {}
local getArgs = require('Module:Arguments').getArgs

function p.outdent (frame) 
	local args = getArgs(frame)
	local width = 0
	
	args['r'] = args['reverse'] or args['indent'] or args['r'] or args['in']	-- aliases for reverse
	if not args[1] then args[1] = '' end                                        -- un-nil args[1]
	
	width = width + select(2, string.gsub(args[1],':',''))						-- increase by 1 for every :
	width = width + select(2, string.gsub(args[1],'*',''))						-- increase by 1 for every *
	width = width + select(2, string.gsub(args[1],'#','')) * 2					-- increase by 2 for every #
	
	if width == 0 then width = tonumber(args[1]) end							-- set width to args[1] if needed
	
	if not width then width = 10 end											-- default width
	if width < 0
	then
		width = -width
		args['r'] = not args['r']
	end
	if width > 40 then width = 40 end											-- max width
	
	width = width * 1.6															-- set width to proper width
	
	local top = '<span style="display:block;width:' .. width .. 'em;height:0.5em;' .. (width == 0 and '' or 'border-bottom:1px solid #AAA;') .. 'border-' .. ((width == 0 or args['r']) and 'left' or 'right') ..':1px solid #AAA;"></span>' -- top half
	local bottom = '<span style="display:block;width:' .. width .. 'em;height:0.5em;border-' .. (args['r'] and 'right' or 'left') .. ':1px solid #AAA;"></span>' -- bottom half
	local note = args[2] and '<span>([[Wikipedia:Indentation#Outdenting|outdent]])&#32;</span>' or '' -- note
	
	return '<div class="outdent-template" style="position:relative;left:1px;">' .. top .. bottom .. note .. '</div>';
end

return p