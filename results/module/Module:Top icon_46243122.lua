-- This module implements {{top icon}}

local categoryHandler = require( 'Module:Category handler' ).main

local p = {}

local function makeName(sort, body)
	local sortnum = tonumber(sort)
	if sortnum then
		-- Zero-pad numbers so that they will sort properly in alphabetical
		-- order. (Yes, there really are decimal sort keys used on enwiki.)
		sort = string.format('%07.2f', sortnum)
	end
	math.randomseed(os.clock() * 1000000000)
	local ret = {}
	ret[#ret + 1] = sort
	-- There should always be a body value present. This will force numeric
	-- sort keys to sort alphabetically.
	ret[#ret + 1] = body
	-- Add a random number to stop names from duplicating others on a page
	ret[#ret + 1] = math.random(1, 100000)
	return table.concat(ret, '-')
end

local function makeFileLink(t)
	local ret = {}
	ret[#ret + 1] = '[[File:'
	ret[#ret + 1] = t.image
	ret[#ret + 1] = '|'
	ret[#ret + 1] = t.width or 20
	ret[#ret + 1] = 'x'
	ret[#ret + 1] = t.height or 20
	ret[#ret + 1] = 'px'
	if t.link then
		ret[#ret + 1] = '|link='
		ret[#ret + 1] = t.link
	end
	if t.alt then
		ret[#ret + 1] = '|alt='
		ret[#ret + 1] = t.alt
	end
	if t.text then
		ret[#ret + 1] = '|'
		ret[#ret + 1] = t.text
	end
	ret[#ret + 1] = ']]'
	return table.concat(ret)
end

local function renderCategories(args, title)
	local categories = categoryHandler{
		user = args.usercat,
		main = args.maincat,
		subpage = args.subpage or 'no',
		nocat = args.nocat,
		page = title.prefixedText
	}
	return categories or ''
end

function p._main(args, frame, title)
	frame = frame or mw.getCurrentFrame()
	title = title or mw.title.getCurrentTitle()
	local image = args.image or args.imagename
	if not image then
		error('no image name specified', 2)
	end
	local name = makeName(
		args.icon_nr or args.number,
		args.name or args.id or image
	)
	local fileLink = makeFileLink{
		image = image,
		width = args.width,
		height = args.height,
		link = args.link or args.wikilink,
		alt = args.alt,
		text = args.text or args.description
	}
	local nowiki = frame:extensionTag{name = 'nowiki'}
	local indicator = frame:extensionTag{
		name = 'indicator',
		args = {name = name},
		content = fileLink
	}
	local categories = renderCategories(args, title)
	return nowiki .. indicator .. categories
end

function p.main(frame)
	local origArgs = require('Module:Arguments').getArgs(frame, {
		parentOnly = true
	})
	-- Copy all the specified arguments over to minimise the number of times we
	-- have to access the frame object.
	local args = {}
	for k, v in pairs(origArgs) do
		args[k] = v
	end
	return p._main(args, frame)
end

return p