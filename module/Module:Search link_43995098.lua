-- This module implements {{search link}}

local p = {}

local searchProfiles = {
	-- "advanced" is not included, as we automatically use the advanced profile
	-- if individual namespaces are specified.
	default = true,
	images = true,
	all = true
}

local function escapeTemplate(s)
	s = s:gsub('[{}|=]', function(match)
		return mw.text.nowiki(match)
	end)
	return s
end

local function parseNamespaceList(ns)
	-- s can be a search profile, a comma-separated list of namespaces, or a
	-- Lua array.
	-- Items in the list can be any valid key to mw.site.namespaces.
	-- We return either a profile string or a table of namespace numbers.

	-- Check for no input or search profile strings.
	local default = 'default'
	if not ns then
		return default
	elseif searchProfiles[ns] then
		return ns
	end
	
	-- Parse the string for valid namespaces
	local ret = {}
	local keys
	if type(ns) == 'table' then
		keys = ns
	else
		keys = mw.text.split(ns, '%s*,%s*')
	end
	for _, key in ipairs(keys) do
		key = tonumber(key) or key
		if type(key) == 'string' and key:lower() == 'main' then
			key = 0
		end
		if mw.site.namespaces[key] then
			ret[#ret + 1] = mw.site.namespaces[key].id
		end
	end

	-- Check that we were passed at least one namespace, and return the table.
	if #ret < 1 then
		return default
	else
		return ret
	end
end

local function makeLink(searchString, display, ns)
	-- Normalise the input.
	if not searchString then
		-- Show the correct syntax if we are not passed a search string.
		return '<code>' ..
			escapeTemplate("{{search link|''search string''|''link text''}}") ..
			'</code>'
	end
	display = display or searchString
	ns = parseNamespaceList(ns)

	-- Build the query table
	local query = {
		search = searchString,
		fulltext = 'Search'
	}
	if searchProfiles[ns] then
		query.profile = ns
	else
		query.profile = 'advanced'
		for _, nsid in ipairs(ns) do
			query['ns' .. tostring(nsid)] = '1'
		end
	end
	
	-- Make the URL.
	local url = mw.uri.fullUrl('Special:Search', query)
	url = tostring(url)
	
	-- Add the span tags and display value.
	return string.format(
		'<span class="plainlinks">[%s %s]</span>',
		url,
		display
	)
end

local function makeNamespaceWarningBanner(title)
	if title.namespace == 0 then
		return require('Module:Message box').main('mbox', {
			type = 'content',
			text = mw.text.nowiki('{{') ..
				'[[Template:Search link|Search link]]' ..
				mw.text.nowiki('}}') ..
				' ' ..
				'should not be used in [[WP:WIAA|articles]] as links to ' ..
				'"search result pages" are among the ' ..
				'[[WP:LINKSTOAVOID|links normally to be avoided]].',
			textstyle = 'text-align: center'
		})
	else
		return ''
	end
end

function p._main(searchString, display, ns, title)
	title = title or mw.title.getCurrentTitle()
	return makeLink(searchString, display, ns) .. makeNamespaceWarningBanner(title)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Search link'
	})
	local searchString = args[1]
	local display = args[2]
	local ns = args.ns
	return p._main(searchString, display, ns)
end

return p