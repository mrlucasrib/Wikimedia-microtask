local mArguments -- lazily initialise [[Module:Arguments]]
local mUserLinks -- lazily initialise [[Module:UserLinks]]
local data = mw.loadData('Module:RFPP/data')

local p = {}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function makeTimeBlurb(time)
	local indefStrings = data.indefStrings -- matches "indef", "infinite", etc.
	if not time then
		return ''
	elseif indefStrings[time] then
		return " '''indefinitely'''"
	else
		local stringToFormat = " for a period of '''%s'''."
			.. ' After %s the page will be automatically unprotected'
		return string.format(stringToFormat, time, time)
	end
end

local function makeUserLinks(user, userType)
	mUserLinks = mUserLinks or require('Module:UserLinks')
	local ulargs
	if userType == 'admin' then
		ulargs = {'t', 'c', 'bls', 'pr', 'del', 'm', 'rl', 'rfa'}
	else
		ulargs = {'t', 'c'}
	end
	ulargs.user = user
	return mUserLinks._main(ulargs)
end

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

function p.main(frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame, {parentOnly = true})
	return p._main(args) or ''
end

function p._main(args)
	local code = args[1]
	if not code then
		return nil
	end

	-- Get the blurb from the data table.
	local responseData = data.codes[code]
	if not responseData then
		return nil
	end
	local blurb = responseData.blurb

	-- Set up the table of parameter functions.
	local maxParam = 1 -- Tracks the parameter to use for the note.
	local function setMaxParam(n)
		if n > maxParam then
			maxParam = n
		end
	end
	local parameterFunctions = {
		['$1'] = function ()
			local param = 2
			setMaxParam(param)
			return makeTimeBlurb(args[param])
		end,
		['$2'] = function ()
			local param = 2
			setMaxParam(param)
			local username = args[param]
			if username then
				return ': ' .. makeUserLinks(username, 'user')
			end
		end,
		['$3'] = function ()
			local param = 3
			setMaxParam(param)
			local username = args[param]
			if username then
				return ' blocked by ' .. makeUserLinks(username, 'admin')
			end
		end,
		['$4'] = function ()
			local param = 2
			setMaxParam(param)
			local username = args[param]
			if username then
				return ' by ' .. makeUserLinks(username, 'admin')
			end
		end
	}

	-- Substitute the parameters into the blurb using the parameter functions.
	blurb = blurb:gsub(
		'$[1-4]',
		function (param)
			return parameterFunctions[param]() or ''
		end
	)

	-- Add the note.
	local note = args[maxParam + 1]
	if note then
		local noteType = responseData.note
		local stringToFormat
		if noteType == 'sentence' then
			stringToFormat = "%s ''%s''"
		elseif noteType == 'fragment' then
			stringToFormat = "%s, ''%s''"
		else
			stringToFormat = ''
		end
		blurb = string.format(stringToFormat, blurb, note)
	end

	return blurb
end

return p