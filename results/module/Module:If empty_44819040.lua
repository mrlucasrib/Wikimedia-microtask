local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {wrappers = 'Template:If empty', removeBlanks = false})

	-- For backwards compatibility reasons, the first 8 parameters can be unset instead of being blank,
	-- even though there's really no legitimate use case for this. At some point, this will be removed.
	local lowestNil = math.huge
	for i = 8,1,-1 do
		if args[i] == nil then
			args[i] = ''
			lowestNil = i
		end
	end

	for k,v in ipairs(args) do
		if v ~= '' then
			if lowestNil < k then
				-- If any uses of this template depend on the behavior above, add them to a tracking category.
				-- This is a rather fragile, convoluted, hacky way to do it, but it ensures that this module's output won't be modified
				-- by it.
				frame:extensionTag('ref', '[[Category:Instances of Template:If_empty missing arguments]]', {group = 'TrackingCategory'})
				frame:extensionTag('references', '', {group = 'TrackingCategory'})
			end
			return v
		end
	end
end

return p