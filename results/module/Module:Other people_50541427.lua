local mOtheruses = require('Module:Other uses')
local mArguments = require('Module:Arguments')
local compressArray = require('Module:TableTools').compressSparseArray
local p = {}

function p.otherPeople (frame)
	--Get arguments
	local origArgs = mArguments.getArgs(frame)
	local named = origArgs.named
	local args = compressArray(origArgs)
	if not origArgs[1] then table.insert(args, 1, nil) end
	-- Assemble arguments and return
	local title = args[1] or mw.title.getCurrentTitle().text
	local options = {
		title = title,
		defaultPage = args[2],
		otherText = (args[2] and not args[1] and 'people with the same name') or
			string.format('people %s %s', named or 'named', title)
	}
	-- Don't pass args[1] through as a target page. Manual downshift because Lua
	-- expectation of sequences means table.remove() doesn't necessarily work
	for i = 2, math.max(table.maxn(args), 2) do
		args[i - 1] = args[i]
		args[i] = nil
	end
	return mOtheruses._otheruses(args, options)
end

return p