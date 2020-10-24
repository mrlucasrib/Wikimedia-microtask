-- This module implements {{find sources}} and other similar templates, and
-- also provides a mechanism to easily create new source-finding templates.

-- Define constants
local ROOT_PAGE = 'Module:Find sources'
local TEMPLATE_ROOT = ROOT_PAGE .. '/templates/' -- for template config modules
local LINK_ROOT = ROOT_PAGE .. '/links/' -- for link config modules
local CONFIG_PAGE = ROOT_PAGE .. '/config' -- for global config

-- Load required modules
local checkType = require('libraryUtil').checkType
local cfg = mw.loadData(CONFIG_PAGE)

local p = {}

local function maybeLoadData(page)
	local success, data = pcall(mw.loadData, page)
	return success and data
end

local function substituteParams(msg, ...)
	return mw.message.newRawMessage(msg, ...):plain()
end

local function renderSearchString(searchTerms, separator, transformFunc)
	-- This takes a table of search terms and turns it into a search string
	-- that can be used in a URL or in a display value. The transformFunc
	-- parameter can be used to transform each search term in some way (for
	-- example, URL-encoding them).
	local searchStrings = {}
	for i, s in ipairs(searchTerms) do
		searchStrings[i] = s
	end
	if transformFunc then
		for i, s in ipairs(searchStrings) do
			searchStrings[i] = transformFunc(s)
		end
	end
	return table.concat(searchStrings, separator)
end

function p._renderLink(code, searchTerms, display)
	-- Renders the external link wikicode for one link, given the link code,
	-- a table of search terms, and an optional display value.

	-- Get link config.
	local linkCfg = maybeLoadData(LINK_ROOT .. code)
	if not linkCfg then
		error(string.format(
			"invalid link code '%s'; no link config found at [[%s]]",
			code,
			LINK_ROOT .. code
		))
	end

	-- Make URL.
	local url
	do
		local separator = linkCfg.separator or "+"
		local searchString = renderSearchString(
			searchTerms,
			separator,
			mw.uri.encode
		)
		url = substituteParams(linkCfg.url, searchString)
	end

	return string.format('[%s %s]', url, display or linkCfg.display)
end

function p._main(template, args)
	-- The main access point from Lua.
	checkType('_main', 1, template, 'string')
	checkType('_main', 2, args, 'table', true)
	args = args or {}
	local title = mw.title.getCurrentTitle()

	-- Get the template config.
	local templateCfgPage = TEMPLATE_ROOT .. template
	local templateCfg = maybeLoadData(templateCfgPage)
	if not templateCfg then
		error(string.format(
			"invalid template name '%s'; no template config found at [[%s]]",
			template, templateCfgPage
		))
	end

	-- Namespace check.
	if not templateCfg.isUsedInMainspace and title.namespace == 0 then
		local formatString = '<strong class="error">%s</strong>'
		if cfg['namespace-error-category'] then
			formatString = formatString .. '[[%s:%s]]'
		end
		return string.format(
			formatString,
			cfg['namespace-error'],
			mw.site.namespaces[14].name,
			cfg['namespace-error-category']
		)
	end

	-- Get the search terms from the arguments.
	local searchTerms = {}
	for i, s in ipairs(args) do
		searchTerms[i] = s
	end
	if not searchTerms[1] then
		-- Use the current subpage name as the default search term, unless 
		-- another title is provided. If the page uses a disambiguator like
		-- "Foo (bar)", make "Foo" the first term and "bar" the second.
		local searchTitle = args.title or title.subpageText
		local term, dab = searchTitle:match('^(.*) (%b())$')
		if dab then
			dab = dab:sub(2, -2) -- Remove parens
		end
		if term and dab then
			searchTerms[1] = term
			searchTerms[2] = dab
		else
			searchTerms[1] = searchTitle
		end
	end
	searchTerms[1] = '"' .. searchTerms[1] .. '"'

	-- Make the intro link
	local introLink
	if templateCfg.introLink then
		local code = templateCfg.introLink.code
		local display = templateCfg.introLink.display or renderSearchString(
			searchTerms,
			'&nbsp;'
		)
		introLink = p._renderLink(code, searchTerms, display)
	else
		introLink = ''
	end

	-- Make the other links
	local links = {}
	local separator = templateCfg.separator or cfg['default-separator']
	local sep = ''
	for i, t in ipairs(templateCfg.links) do
		links[i] = sep .. p._renderLink(t.code, searchTerms, t.display) ..
			(t.afterDisplay or '')
		sep = t.separator or separator
	end
	links = table.concat(links)

	-- Make the blurb.
	local blurb = substituteParams(templateCfg.blurb, introLink, links)
	local span = mw.html.create('span')
	span
		:addClass('plainlinks')
		:addClass(templateCfg.class)
		:cssText(templateCfg.style)
		:wikitext(blurb)

	return tostring(span)
end

setmetatable(p, { __index = function(t, template)
	-- The main access point from #invoke.
	-- Invocations will look like {{#invoke:Find sources|template name}},
	-- where "template name" is a subpage of [[Module:Find sources/templates]].
	local tname = template
	if tname:sub(-8) == '/sandbox' then
		-- This makes {{Find sources/sandbox|Albert Einstein}} work.
		tname = tname:sub(1, -9)
	end
	return function(frame)
		local args = require('Module:Arguments').getArgs(frame, {
			wrappers = mw.site.namespaces[10].name .. ':' .. tname
		})
		return t._main(template, args)
	end
end})

return p