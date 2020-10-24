local p = {}

function p.MoMP(frame)
	-- For calling from #invoke.
	local pframe = frame:getParent()
	local args = pframe.args
	return p._MoMP(args)
end

function p._MoMP(args)
	local link, result
	-- For calling from other Lua modules.
	local num = tonumber(args[1])
	local subsec = string.sub(tostring(num + 1000), -3)
	if (num <= 1000) then
		link = "Meanings of minor planet names: 1–1000#" .. subsec
	else
		local pagefrom = math.floor((num - 1) / 1000)
		local pageto = pagefrom + 1
		link = "Meanings of minor planet names: " .. pagefrom .. "001–" .. pageto .. "000#" .. subsec
	end
	if (args[2] == nil) then
		result = "[[" .. link .. "]]"
	else
		result = "[[" .. link .. "|" .. args[2] .. "]]"
	end
	return result
end

return p