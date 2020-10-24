local p = {}

-- There's probably a way to use strptime or some other more sophisticated way, but you're not supposed to be using a non-timestamp as input anyway.

local function endswith(String,End)
	return End == '' or string.sub(String,-string.len(End)) == End
end

local function trim(s)
	return s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\226\128\142", "")
end

local function addUtcToStringIfItDoesNotEndWithUtc(s)
	if s == "" or endswith(s, "~~~~") then return s end
	if not endswith(s, "(UTC)") then
		return s .. " (UTC)"
	end
	return s
end

local function _main(args)
	local hopefullyTimestamp = args[1] or os.date('%H:%M, %d %B %Y (%Z)')
	return addUtcToStringIfItDoesNotEndWithUtc(trim(hopefullyTimestamp))
end

function p.main(frame)
	local args
	if type(frame.args) == 'table' then
		-- We're being called via #invoke. The args are passed through to the module
		-- from the template page, so use the args that were passed into the template.
		args = frame.args
	else
		-- We're being called from another module or from the debug console, so assume
		-- the args are passed in directly.
		args = frame
	end
	return _main(args)
end

return p