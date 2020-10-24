-- This module implements [[Template:ISBNT]]

local p = {}

function p.link(frame)
	local check_isbn = require( "Module:Check isxn" ).check_isbn
	local isxns = mw.text.split(frame.args[1] or frame:getParent().args[1] or '', "%s*,%s*")
	local res = {}
	for i, isxn in ipairs(isxns) do
		table.insert(res, '[[Special:BookSources/' .. isxn .. '|' .. isxn .. ']]' 
			.. check_isbn({['args'] = {isxn, ['error'] = '<span class="error" style="font-size:88%">Check ISBN</span>' ..
				frame:preprocess('{{main other|[[Category:Pages with ISBN errors]]}}')}})
			)
	end
	return table.concat(res, ', ')
end

return p