local p = {}
local getArgs = require('Module:Arguments').getArgs

function p.width(frame)
	local args = getArgs(frame)
	return p._width(args)
end

function p._width(args)
	local new_width = 140
	local page = mw.title.makeTitle('File', args[1])
	if not page.fileExists then
		return new_width
	end

	new_width = math.floor ( ( page.file.width / math.sqrt ( ( page.file.width * page.file.height ) / 19600 ) ) + 0.5 )

	return new_width
end

return p