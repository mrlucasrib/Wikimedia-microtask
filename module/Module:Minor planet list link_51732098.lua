local p = {}

function p.LoMP(frame)
	-- For calling from #invoke.
	local pframe = frame:getParent()
	local args = pframe.args
	return p._LoMP(args)
end

function p._LoMP(args)
	local link, result
	-- For calling from other Lua modules.
	local num = tonumber(args[1])
	local subsec = string.sub(tostring(num + 1000), -3)
	if (num <= 1000) then
		link = "List of minor planets: 1–1000#" .. subsec
	else
		local pagefrom = math.floor((num - 1) / 1000)
		local pageto = pagefrom + 1
		link = "List of minor planets: " .. pagefrom .. "001–" .. pageto .. "000#" .. subsec
	end
	if (args[2] == nil) then
		result = "[[" .. link .. "]]"
	else
		result = "[[" .. link .. "|" .. args[2] .. "]]"
	end
	return result
end

return p