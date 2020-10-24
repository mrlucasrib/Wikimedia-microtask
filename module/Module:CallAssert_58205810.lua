local function pack(...)
	return {...}, select('#', ...)
end

local function mapArray(func, array, count)
	local result = {}
	for i = 1, count or #array do
		result[i] = func(array[i])
	end
	return result
end

local function quote(value)
	if type(value) == 'string' then
		return (string.gsub(string.format('%q', value), '\\\n', '\\n'))  -- Outer parentheses remove second value returned by gsub
	end
	local str = tostring(value)
	if type(value) == 'table' and str ~= 'table' then
		return '{' .. str .. '}'
	end
	return str
end

local function callAssert(func, funcName, ...)
	local result, resultCount = pack(func(...))
	if not result[1] then
		local args, argsCount = pack(...)
		args = mapArray(quote, args, argsCount)
		local message = mw.ustring.format(
			'%s(%s) failed',
			funcName,
			table.concat(args, ', ')
		)
		error(message, 2)
	end
	return unpack(result, 1, resultCount)
end

return callAssert