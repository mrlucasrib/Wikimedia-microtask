local mt = getmetatable(_G) or {}
function mt.__index (t, k)
	if k ~= 'arg' then
		error('Tried to read nil global ' .. tostring(k), 2)
	end
	return nil
end
function mt.__newindex(t, k, v)
	if k ~= 'arg' then
		error('Tried to write global ' .. tostring(k), 2)
	end
	rawset(t, k, v)
end
setmetatable(_G, mt)