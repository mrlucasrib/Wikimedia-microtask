local mRedirectHatnote = require('Module:Redirect hatnote')
local mArguments = require('Module:Arguments')
local mHatnote = require('Module:Hatnote')
local p = {}

function p.redirectMulti (frame)
	local args = mArguments.getArgs(frame)
	--Get maxArg manually because getArgs and table.maxn aren't friends
	local maxArg = 0
	for k, v in pairs(args) do
		if type(k) == 'number' and k > maxArg then maxArg = k end
	end
	--Get number of redirects then remove it from the args table
	local numRedirects = tonumber(args[1]) or 1
	--Manual downshift of arguments; not using table.remove because getArgs is
	--gnarly and it's not a sequence anyway
	for i = 2, maxArg + 1 do args[i - 1] = args[i] end
	--if no arguments past redirects exist, add in a default set
	if maxArg - 2 <= numRedirects then
		for i = 1, numRedirects do
			args[numRedirects + (2 * i)] = args[i] and mHatnote.disambiguate(args[i])
			--this does add in an "and" after the last item, but it's ignored
			args[numRedirects + (2 * i) + 1] = 'and'
		end
	end
	local options = {selfref = args.selfref}
	return mRedirectHatnote._redirect(args, numRedirects, options)
end

return p