local p = {}

function p.tracking(frame)
	local args = frame:getParent().args
	for k, v in pairs(args) do
		if tostring(k):match('%-team[0-9]') then
			if tostring(v):match('[Bb][Rr][^<>]*>[%s]*.[Nn][Bb][Ss][Pp]') then
				return '[[Category:Pages using a team bracket with nbsp]]'
			end
			if tostring(v):match('[Bb][Rr][^<>]*>[%s]*<span[^<>]*>[%s]*.[Nn][Bb][Ss][Pp]') then
				return '[[Category:Pages using a team bracket with nbsp]]'
			end
		end
	end
	return ''
end

return p