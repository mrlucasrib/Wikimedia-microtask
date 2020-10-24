local p = {}

function p.main(frame)
	local args = frame:getParent().args
	
	local templateArgs = { }
	for key, value in pairs(args) do
		if type(key) == "number" then
			templateArgs[2 * key - 1] = value
			templateArgs[2 * key] = frame:preprocess(value)
		else
			templateArgs[key] = value
		end
	end
	
	return frame:expandTemplate{ title = "Markup", args = templateArgs }
end

return p