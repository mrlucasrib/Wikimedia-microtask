local mt = getmetatable(_G) or {}

local function print(val)
	if type(val) == "table" then
		local printout = {}
		local i = 1
		for k, v in pairs(val) do
			table.insert(printout, ("[%s] = %s"):format(tostring(k), tostring(v)) )
			i = i + 1
			if i > 5 then
				table.insert(printout, "...")
				break
			end
		end
		printout = { table.concat(printout, ", ") }
		table.insert(printout, 1, "{")
		table.insert(printout, "}")
		return table.concat(printout)
	elseif type(val) == "string" then
		return '"' .. val .. '"'
	else
		return tostring(val)
	end
end
		

mt.__newindex = function (self, key, value)
	if key ~= "arg" then
		mw.log("Global variable " .. print(key) .. " was set to "
			.. print(value) .. " somewhere:",
			debug.traceback("", 2))
	end
	return rawset(self, key, value)
end

mt.__index = function (self, key)
	if key ~= "arg" then
		mw.log("Nil global variable " .. print(key) .. " was read somewhere:",
			debug.traceback("", 2))
	end
	return rawget(self, key)
end

setmetatable(_G, mt)