-- Calculates the width of the span box for [[Template:Flaglist]]
-- based on the specified image size

local p = {}

function p.luawidth(size)
	--For use within Lua
	local w
	if string.find(size,"^%d+x%d+px$") then -- width and height (eg. 20x10px)
		-- use specified width
		w = tonumber(string.match(size,"(%d+)x%d+px")) + 2 -- (2px for borders)
	elseif string.find(size,"^%d+px$") then -- width only (eg. 20px)
		-- use specified width
		w = tonumber(string.match(size,"(%d+)px")) + 2
	elseif string.find(size,"^x%d+px$") then -- height only (eg. x10px)
		-- assume a width based on the height
		local h = tonumber(string.match(size,"x(%d+)px"))
		w = h * 2.2
		w = math.floor(w+0.5) -- round to integer
	else -- empty or invalid input
		w = 25 -- default width for flagicons including borders
	end
	return tostring(w)
end

function p.width(frame)
	--For external use
	return p.luawidth(frame.args[1])
end

return p