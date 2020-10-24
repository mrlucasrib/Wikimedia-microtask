local p = {}

function p.main(frame)
	local count = 500
	while pcall(mw.incrementExpensiveFunctionCount) do
		count = count - 1
	end
	if count == 500 then
		count = 'at least 500'
	end
	return '<span style="color:yellow;background-color:red">There are ' .. count .. ' expensive function calls before this point</span><span style="display:none">http://www.encyclopediadramatica.com</span>' -- Hidden dead link to blacklisted site prevents accidental saving
end

return p