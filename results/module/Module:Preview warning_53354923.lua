local p = {}

--[[
main

This function returns parameter 1 as a warning if the page containing it is being previewed.

Usage:
{{#invoke:Preview warning|main|warning_text}}

]]

function p.main(frame)
	local preview = frame.args[1]:match('^%s*(.-)%s*$') or ''
	if preview == '' then preview = 'Something is wrong with this template' end
	if frame:preprocess( "{{REVISIONID}}" ) == "" then return '<div class="hatnote" style="color:red"><strong>Warning:</strong> ' .. preview .. ' (this message is shown only in preview)</div>' end
end

return p