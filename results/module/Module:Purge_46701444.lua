-- This module implements [[Template:Purge]].

local p = {}

local function makeUrlLink(url, display)
	return string.format('[%s %s]', url, display)
end

function p._main(args)
	-- Make the URL
	local url
	do
		local title
		if args.page then
			title = mw.title.new(args.page)
			if not title then
				error(string.format(
					"'%s' is not a valid page name",
					args.page
				), 2)
			end
		else
			title = mw.title.getCurrentTitle()
		end
		if args.anchor then
			title.fragment = args.anchor
		end
		url = title:fullUrl{action = 'purge'}
	end
	
	-- Make the display
	local display
	if args.page then
		display = args[1] or 'Purge'
	else
		display = mw.html.create('span')
		display
			:attr('title', 'Purge this page')
			:wikitext(args[1] or 'Purge')
		display = tostring(display)
	end
	
	-- Output the HTML
	local root = mw.html.create('span')
	root
		:addClass('noprint')
		:addClass('plainlinks')
		:addClass('purgelink')
		:wikitext(makeUrlLink(url, display))
	
	return tostring(root)
end

function p.main(frame)
	local args = frame:getParent().args
	return p._main(args)
end

return p