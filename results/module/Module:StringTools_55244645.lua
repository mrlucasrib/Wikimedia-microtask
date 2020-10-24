local p = {}

--[=[
	Similar to gmatch, but it returns the count of the match in addition to the
	list of captures, something like ipairs().
	
	If the pattern doesn't contain any captures, the whole match is returned.
	
	Invoke thus:
	
		for i, whole_match in require("Module:string").imatch(text, pattern) do
			[ do something with i and whole_match ]
		end
	
	or
	
		for i, capture1[, capture2[, capture3[, ...]]] in require("Module:string").imatch(text, pattern) do
			[ do something with i and capture1 ]
		end
]=]

function p.imatch(text, pattern, start, plain)
	local i = 0
	local pos = start or 0
	if not mw.ustring.find(pattern, "%b()") then
		pattern = "(" .. pattern .. ")"
	end
	return function()
		i = i + 1
		local return_values = { mw.ustring.find(text, pattern, pos, plain) }
		local j = return_values[2]
		
		if #return_values > 0 then
			pos = j + 1
			-- Skip the first two returned values, which are the indices of the
			-- whole match.
			return i, unpack(return_values, 3)
		else
			return nil, nil
		end
	end
end

return p