-- This module implements {{GA/Topic}}.

local p = {}

function p.main(frame)
	local topic = frame:getParent().args[1]
	if not topic then
		return ''
	end
	topic = topic:match('^%s*(.-)%s*$') -- Trim whitespace
	local ret
	if topic ~= '' then
		ret = p._main(topic)
	end
	ret = ret or ''
	return ret
end

function p._main(topic)
	topic = topic:lower()
	local data = mw.loadData('Module:Good article topics/data')
	return data[topic]
end

return p