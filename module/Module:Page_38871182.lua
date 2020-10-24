local callAssert = require('Module:CallAssert')

local function main(frame, field)
	local args, pargs = frame.args, ( frame:getParent() or {} ).args or {}
	local makeTitle=args.makeTitle or pargs.makeTitle
	local namespace=args.namespace or pargs.namespace or ""
	local fragment=args.fragment or pargs.fragment or ""
	local interwiki=args.interwiki or pargs.interwiki or ""
	local page=args.page or args[1] or pargs.page or pargs[1] or ""
	local id= tonumber( args.id or pargs.id )
	local pn = {}
	local title -- holds the result of the mw.title.xxx call

	for i = 1,9 do pn[i] = args['p'..i] or pargs['p'..i] end
	if not id and not mw.ustring.match( page, '%S' ) then page = nil end

	if id then
		title = callAssert(mw.title.new, 'mw.title.new', id)
	elseif not page then
		title = callAssert(mw.title.getCurrentTitle, 'getCurrentTitle')
	elseif makeTitle then
		title = callAssert(mw.title.makeTitle, 'makeTitle', namespace, page, fragment, interwiki)
	else
		title = callAssert(mw.title.new, 'mw.title.new', page, namespace)
	end

	local result = title[field]
	if type(result) == "function" then
		result = result(title, unpack(pn))
	end

	return tostring(result or "")
end

-- handle all errors in main
main = require('Module:Protect')(main)

local p = {}

-- main function does all the work
local meta = {}
function meta.__index(self, key)
	return function(frame)
		return main(frame, key)
	end
end
setmetatable(p, meta)

function p.getContent(frame)
	local args, pargs = frame.args, ( frame:getParent() or {} ).args or {}
	local fmt = args.as or pargs.as or "pre"
	local text = main(frame, "getContent")

	fmt = mw.text.split( fmt, ", ?" )

	for _, how in ipairs( fmt ) do
		if how == "pre" then
			text = table.concat{ "<pre>", text, "</pre>" }
		elseif how == "expand" then
			text = frame:preprocess(text)
		elseif how == "nowiki" then
			text = mw.text.nowiki(text)
		end
	end

	return text
end

return p