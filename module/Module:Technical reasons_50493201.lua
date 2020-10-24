local mHatnote = require('Module:Hatnote')
local mHatlist = require('Module:Hatnote list')
local mArguments --initialize lazily
local p = {}

function p.technicalReasons (frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame)
	return p._technicalReasons(args)
end

function p._technicalReasons (args)
	--Return an error if no redirect's provided
	if not args[1] then
		return mHatnote.makeWikitextError(
			'no redirect provided',
			'Template:Technical reasons',
			args.category
		)
	end
	--get maxArg manually because getArgs() and table.maxn aren't friends
	local maxArg = 0
	for k, v in pairs(args) do
		if type(k) == 'number' and k > maxArg then maxArg = k end
	end
	--If there's only 1–2 arguments, set from to 1 to default things nicely.
	--Note that if (not args[2]) this doesn't matter either way.
	local from = maxArg > 2 and 2 or 1
	--Structure the forSee table
	local forSee = mHatlist.forSeeArgsToTable(args, from)
	--Suppresses defaulting; for-see table rows that would include defaulting
	--are set to nil.
	for k, v in pairs(forSee) do
		if not v.use or #v.pages == 0 then forSee[k] = nil end
	end
	--Stringify the forSee table or set it nil
	forSee = #forSee ~= 0 and mHatlist.forSeeTableToString(forSee) or nil
	local lead = string.format(
		'For [[Wikipedia:Naming conventions (technical restrictions)#Forbidden characters|technical reasons]], "%s" redirects here.',
		args[1]
	)
	local text = table.concat({lead, forSee}, ' ')
	
	local options = {extraclasses = 'plainlinks selfreference noprint', selfref = true}
	
	return mHatnote._hatnote(text, options)
end

return p