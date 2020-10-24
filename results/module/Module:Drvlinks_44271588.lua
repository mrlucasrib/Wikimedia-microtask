-- This module implements {{drvlinks}}

local lang = mw.language.getContentLanguage()
local mToolbar = require('Module:Toolbar')

local p = {}

local function para(k, v)
	return string.format('|%s=%s', k, v or '')
end

local function makeWikilink(page, display)
	if display then
		return string.format('[[%s|%s]]', page, display)
	else
		return string.format('[[%s]]', page)
	end
end

local function makeExternalLink(url, display)
	-- The URL can be a URL string or a mw.uri object.
	url = tostring(url)
	return string.format('[%s %s]', url, display)
end

function p._main(args, frame)
	frame = frame or mw.getCurrentFrame()

	-- Get the page name
	local page = args.pg
	if not page then
		error('no page name specified; please use ' .. para('pg', "''pagename''"), 2)
	end

	-- Get the namespace table from mw.site.namespaces
	local ns = args.ns
	if type(ns) == 'string' then
		ns = ns:lower()
		ns = lang:ucfirst(ns)
	end
	ns = tonumber(ns) or ns
	if not ns or ns == 'Article' then
		ns = 0
	end
	ns = mw.site.namespaces[ns]
	if not ns or ns.id < 0 then -- Invalid parameter or a special namespace
		error(string.format(
			'Invalid %s, please use "Article" or a namespace name listed ' ..
				'at [[Wikipedia:Namespaces]] (excluding special namespaces)',
			para('ns')
		), 2)
	end

	-- Get the page links
	local pageLinks
	do
		local templateTitle
		if ns.id == 0 then
			templateTitle = 'la'
		elseif ns.id == 1 then
			templateTitle = 'lat'
		elseif ns.isTalk then
			templateTitle = 'lnt'
		else
			templateTitle = 'ln'
		end

		local targs = {}
		if templateTitle == 'ln' then
			targs[1] = ns.name
			targs[2] = page
		elseif templateTitle == 'lnt' then
			targs[1] = ns.subject.name
			targs[2] = page
		else
			targs[1] = page
		end

		pageLinks = frame:expandTemplate{title = templateTitle, args = targs}
	end

	-- Get the tool links
	local toolLinks
	do
		local tlargs = {}
		local fullPageName
		if ns.id == 0 then
			fullPageName = page
		else
			fullPageName = ns.name .. ':' .. lang:ucfirst(page)
		end

		-- Restore link
		tlargs[#tlargs + 1] = makeWikilink(
			'Special:Undelete/' .. fullPageName,
			'restore'
		)

		-- Google cache link
		local pageUrl = mw.uri.fullUrl(fullPageName)
		pageUrl = tostring(pageUrl)
		tlargs[#tlargs + 1] = makeExternalLink(
			'//www.google.com/search?q=cache:' .. pageUrl,
			'cache'
		)

		-- XfD link
		if ns.id ~= 6 and ns.id ~= 10 and ns.id ~= 14 then
			-- No XfD links for files, templates or categories.
			local xfdPage, display
			if ns.id == 0 then
				xfdPage = 'Wikipedia:Articles for deletion/' .. fullPageName
				display = 'AfD'
			else
				xfdPage = 'Wikipedia:Miscellany for deletion/' .. fullPageName
				display = 'MfD'
			end
			tlargs[#tlargs + 1] = makeWikilink(xfdPage, display)
		end

		toolLinks = mToolbar._main(tlargs)
	end

	return pageLinks .. ' ' .. toolLinks
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Drvlinks'
	})
	return p._main(args, frame)
end

return p