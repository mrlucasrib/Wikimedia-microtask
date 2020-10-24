-- module to turn a parameter list into a list of [[Dynkin diagram]] images.
-- See the template documentation or any example for how it is used and works.
local p = {}

function p.Dynkin(frame)
	-- For calling from #invoke.
	local pframe = frame:getParent()
	local args = pframe.args
	return p._Dynkin(args)
end
	
function p._Dynkin(args)
	-- For calling from other Lua modules.
	local body ='<span style="display:inline-block;">'         -- create and start the output string
	for v, x in ipairs(args) do                                -- process params, ignoring any names
		body = body .. "[[File:dyn-" .. x .. ".png]]"          -- write file for this parameter
	end
	body = body .. "</span>"                                   -- finish output string
	return body                                                -- return result
end

return p