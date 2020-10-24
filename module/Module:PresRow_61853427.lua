-- This is under construction; it will soon provide the code for the template PresRow

local p = {} 

-- Determine whether the main anti-Democrats are Republicans or Whigs
function p.gopwhig(frame)
	local party = 'Republican'
	if 	frame.args[1] < 1856 then party='Whig' end
	return party
end

function p.calcGOP(frame)
	local gop = frame.args[1]
	local dem = frame.args[2]
	local third = frame.args[3]
	return (gop)/(gop+dem+third)
end

function p.func(frame)
	return "Hello, world!"
end

return p