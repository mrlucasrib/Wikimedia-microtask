-- module to turn a parameter list into a list of [[Coxeter–Dynkin diagram]] images.
-- See the template documentation or any example for how it is used and works.
local p = {}

function p.CDD(frame)
	-- For calling from #invoke.
	local pframe = frame:getParent()
	local args = pframe.args
	return p._CDD(args)
end
	
function p._CDD(args)
	-- For calling from other Lua modules.
	local body ='<span style="display:inline-block;">'         -- create and start the output string
	for v, x in ipairs(args) do                                -- process params, ignoring any names
		if (x ~= '') then					-- check for null/empty names
        		body = body .. "[[File:CDel_" .. x .. ".png|link=]]"   -- write file for this parameter
		end
	end
	body = body .. "</span>"                                   -- finish output string
	return body                                                -- return result
end

return p