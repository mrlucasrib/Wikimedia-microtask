local p = {}

local function setCleanArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				cleanArgs[key] = val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

p.main = function(frame)
	local parent = frame.getParent(frame)
	local output = p._main(parent.args)
	return frame:extensionTag{ name='templatestyles', args = { src='Flex columns/styles.css'} } .. frame:preprocess(output)
end

p._main = function(_args)
	local args = setCleanArgs(_args)
	local ii = 1
	local container = mw.html.create('div')
	:addClass('flex-columns-container' )
	while args[ii] do
		local column = container:tag('div')
		:addClass('flex-columns-column' )
		:wikitext(args[ii])
		if args['flex'..ii] then
			column:css('flex', args['flex'..ii])
		end
		ii = ii + 1
	end
	return tostring(container)
end

return p