local mHatnote = require('Module:Hatnote')
local mHatlist = require('Module:Hatnote list')
local mArguments --initialize lazily
local mTableTools = require('Module:TableTools')
local p = {}

function p.redirectDistinguish (frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame)
	return p._redirectDistinguish(args)
end

function p._redirectDistinguish(args)
	if not args[1] then
		return mHatnote.makeWikitextError(
			'no redirect supplied',
			'Template:Redirect-distinguish',
			args.category
		)
	end
	local redirectTitle = mw.title.new(args[1])
	if redirectTitle and redirectTitle.exists then
		if not redirectTitle.isRedirect then
			args[1] = args[1] .. '[[Category:Articles with redirect hatnotes needing review]]'
		end
	elseif not string.match(args[1], 'REDIRECT%d+') and not args[1] == 'TERM' then
		args[1] = args[1] .. '[[Category:Missing redirects]]'
	end
	if not args[2] then
		return mHatnote.makeWikitextError(
			'no page to be distinguished supplied',
			'Template:Redirect-distinguish',
			args.category
		)
	end
	args = mTableTools.compressSparseArray(args)
	--Assignment by removal here makes for convenient concatenation later
	local redirect = table.remove(args, 1)
	local text = string.format(
		'"%s" redirects here. It is not to be confused with %s.',
		redirect,
		mHatlist.orList(args, true)
	)
	return mHatnote._hatnote(text)
end

return p