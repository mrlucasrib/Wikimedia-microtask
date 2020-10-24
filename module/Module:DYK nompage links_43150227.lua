-- This module implements {{DYK nompage links}}.


local formatStringSingle = [[
<div class="plainlinks hlist">
* ( %s
* %s )
</div>]]

local formatStringMulti = [[
<div class="plainlinks hlist">
* ( %s )
</div>
<div class="plainlinks hlist">
* ( Article history links: %s )
</div>]]

local p = {}

local function makeWikitextError(msg)
	return string.format('<strong class="error">Error: %s</strong>', msg)
end

local function makeFullUrl(page, query, display)
	local url = mw.uri.fullUrl(page, query)
	if not url then
		url = makeWikitextError(string.format(
			'"%s" is not a valid page name',
			tostring(page)
		))
	end
	return string.format(
		'[%s %s]',
		tostring(url),
		display
	)
end

function p.main(frame)
	local mArguments = require('Module:Arguments')
	local mTableTools = require('Module:TableTools')
	local args = mArguments.getArgs(frame, {
		wrappers = 'Template:DYK nompage links'
	})
	local nominationPage = args.nompage
	local historyPages = mTableTools.compressSparseArray(args)
	return p._main(nominationPage, historyPages)
end

function p._main(nominationPage, historyPages)
	-- Deal with bad input.
	if not nominationPage then
		return makeWikitextError('no nomination page specified')
	end
	if not historyPages or not historyPages[1] then
		return makeWikitextError('no articles specified')
	end

	-- Find out whether we are dealing with multiple history pages.
	local isMulti = #historyPages > 1

	-- Make the nompage link.
	local nominationLink
	do
		local currentPage = mw.title.getCurrentTitle().prefixedText
		local dykSubpage = 'Template:Did you know nominations/' .. nominationPage
		if currentPage == dykSubpage then
			nominationLink = string.format(
				'[[Template talk:Did you know#%s|Back to T:TDYK]]',
				nominationPage
			)
		else
			nominationLink = makeFullUrl(
				'Template:Did you know nominations/' .. nominationPage,
				{action = 'edit'},
				'Review or comment'
			)
		end
	end

	-- Make the history links.
	local historyLinks
	do
		if isMulti then
			local links = {}
			for i, page in ipairs(historyPages) do
				links[#links + 1] = makeFullUrl(
					page,
					{action = 'history'},
					page
				)
			end
			historyLinks = table.concat(links, '\n* ')
		else
			historyLinks = makeFullUrl(
				historyPages[1],
				{action = 'history'},
				'Article history'
			)
		end
	end

	-- Assemble the output.
	local stringToFormat = isMulti and formatStringMulti or formatStringSingle
	return string.format(stringToFormat, nominationLink, historyLinks)
end

return p