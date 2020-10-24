local mFor = require('Module:For')
local mArguments = require('Module:Arguments')
local p = {}

function p.forFoo (frame)
	local args = mArguments.getArgs(frame, 
		{parentOnly = true}
	)
	local target
	if args[1] then
		target = args[1]
	else
		local title = mw.title.getCurrentTitle().text
		local titles = {
			mw.ustring.lower(mw.ustring.sub(title, 1, 1)) .. mw.ustring.sub(title, 2),
			title
		}
		local forms = frame.args
		for k, v in ipairs(forms) do
			for i, j in pairs(titles) do
				local lookup = string.format(v, j)
				if mw.title.new(lookup, 0).exists then
					target = lookup
					break
				end
			end
			if target then break end
		end
		target = target or string.format(forms[1], title)
	end

	return mFor._For({frame.args.what, target})
end
return p