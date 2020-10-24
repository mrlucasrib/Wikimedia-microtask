-- This module creates a section link with multiple section names.

local p = {}

local function normalizePageName(page)
	local title = mw.title.new(page)
	if not title then
		error(string.format("'%s' is not a valid page name", page), 3)
	elseif title.namespace == 6 or title.namespace == 14 then
		return ':' .. title.prefixedText
	else
		return title.prefixedText
	end
end

function p._main(args)
	local displayParts = {}
	for i, v in ipairs(args) do
		displayParts[i] = v
	end
	local nParts = #displayParts
	if nParts < 1 then
		error('no page name found in parameter |1=', 2)
	elseif nParts == 1 then
		return string.format('[[%s]]', normalizePageName(displayParts[1]))
	else
		local display = {}
		for i, s in ipairs(displayParts) do
			table.insert(display, s)
			if i ~= nParts then
				table.insert(display, ' ')
				table.insert(display, string.rep('§', i))
				table.insert(display, '&nbsp;')
			end
		end
		display = table.concat(display)
		local page = normalizePageName(displayParts[1])
		local fragment = displayParts[nParts]
		return string.format('[[%s#%s|%s]]', page, fragment, display)
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Multi-section link'
	})
	return p._main(args)
end

return p