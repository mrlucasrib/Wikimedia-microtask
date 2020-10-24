local p = {}

function p.latestafd(frame)

	if frame.args[2] then
		display = "|" .. frame.args[2]
	else
		display = ""
	end

	local input = frame.args[1]
	local lang = mw.language.getContentLanguage()
	local page = lang:ucfirst(input)
	local base_string = "Wikipedia:Articles for deletion/" .. page

	local base_title = mw.title.new(base_string)
	local afd2_title = mw.title.new(base_string .. " (2nd nomination)")

	if not base_title.exists then
		output = frame:expandTemplate{ title = 'error', args = { 'Warning: No AfD discussion exists for the linked article.' } }
	elseif not afd2_title.exists then
		output = "[[" .. base_string .. display .. "]]"
	else
		local afd_num = 2
		local latest = false
		while not latest do
			local next_ordinal = frame:expandTemplate{ title = 'ordinal', args = { afd_num + 1 } }
			local next_title = mw.title.new(base_string .. " (" .. next_ordinal .. " nomination)")
			if not next_title.exists then
				latest = true
				local ordinal = frame:expandTemplate{ title = 'ordinal', args = { afd_num } }
				output = "[[" .. base_string .. " (" .. ordinal .. " nomination)" .. display .. "]]"
			end
			afd_num = afd_num + 1
		end
	end
	return output
end

return p