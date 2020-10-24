local getArgs = require('Module:Arguments').getArgs
local p = {}

local function makeInvokeFunc(funcName)
	return function (frame)
		local args = getArgs(frame)
		return p[funcName](args)
	end
end

p.italic = makeInvokeFunc('_italic')

function p._italic(args)
	local title = args[1]
	local invert = args[2]
	local prefix, parenthetical = mw.ustring.match(title, '^(.+) %(([^%(%)]+)%)$')
	local result
	if prefix and parenthetical and args.all ~= 'yes' then	
		if invert == 'i' or invert == 'inv' or invert == 'invert' then
			result = string.format("%s \(\'\'%s\'\'\)", prefix, parenthetical)
		else
			result = string.format("\'\'%s\'\' \(%s\)", prefix, parenthetical)
		end
	else
		result = string.format("\'\'%s\'\'", title)
	end
	return result
end

p.quotes = makeInvokeFunc('_quotes')

function p._quotes(args)
	local title = args[1]
	local invert = args[2]
	local prefix, parenthetical = mw.ustring.match(title, '^(.+) %(([^%(%)]+)%)$')
	local result
	if prefix and parenthetical and args.all ~= 'yes' then
		if invert == 'i' or invert == 'inv' or invert == 'invert' then
			result = string.format("%s \(\"%s\"\)", prefix, parenthetical)
		else	
			result = string.format("\"%s\" \(%s\)", prefix, parenthetical)
		end
	else
		result = string.format("\"%s\"", title)
	end
	return result
end

return p