p = {}
p.stripzeros = function(frame)
	x = tonumber(frame.args[1])
	if x then
		return x
	else
		return "Incorrect"
	end
end
return p