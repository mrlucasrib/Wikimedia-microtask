require('Module:No globals')

local data = mw.loadData('Module:PTV route/data')
local p = {}

local INVALID_ROUTE_CATEGORY = 'PTV route templates with invalid routes'
local DEPRECATED_PARAMETER_CATEGORY = 'PTV route templates with deprecated parameters'

local function makeExternalLink(url, display)
	-- Make an external link, given a URL and an optional display string.
	if display then
		return string.format('[%s %s]', url, display)
	else
		return string.format('[%s]', url)
	end
end

local function makePtvUrl(routeData)
	-- Generate the URL for a PTV route page.
	return 'https://www.ptv.vic.gov.au/route/' .. routeData.page
end

local function makeDisplayText(args, routeData)
	-- Make the display text for a link to a PTV route page.
	if args.display == 'num' or args.display == 'number' or args.numtext then
		return args.route
	elseif args.display == 'desc' or args.display == 'description' or args.deftext then
		return routeData.text
	else
		return args.text
	end
end

local function getRouteData(mode, route)
	-- Get the route data for a route from the data module.
	if not route then
		return nil
	end
	mode = mode or 'bus'
	local modeData = data[mode]
	if not modeData then
		return nil
	end
	return modeData[route]
end

local function makePtvLink(args, routeData)
	-- Make a link to a PTV route page.
	local url = makePtvUrl(routeData)
	local display = makeDisplayText(args, routeData)
	return makeExternalLink(url, display)
end

local function makePtvCitation(args, routeData)
	-- Make a citation for a PTV route page.
	local title
	if args.route == routeData.text then
		title = routeData.text
	else
		title = string.format('%s %s', args.route, routeData.text)
	end
	local citeArgs = {
		title = title,
		url = makePtvUrl(routeData),
		publisher = 'Public Transport Victoria',
		df = 'dmy-all',
	}
	for _, field in ipairs{
		'access-date',
		'accessdate',
		'archive-date',
		'archivedate',
		'archive-url',
		'archiveurl',
		'dead-url',
		'deadurl',
	} do
		citeArgs[field] = args[field]
	end
	return mw.getCurrentFrame():expandTemplate{
		title = 'Cite web',
		args = citeArgs,
	}
end

local function normalizeArguments(args)
	-- Normalize the arguments that we received.
	-- First, make a copy of the table so we don't alter our caller's data.
	local ret = {}
	for key, value in pairs(args) do
		ret[key] = value
	end
	-- Set aliases
	ret.route = ret.route or ret[1]
	return ret
end

local function hasDeprecatedParameters(args)
	-- Whether the argument table contains deprecated parameters.
	return args.numtext or args.deftext
end

local function makeCategoryLink(category)
	-- Make a category wikilink.
	return string.format('[[Category:%s]]', category)
end

local function renderTrackingCategory(category)
	-- Render a tracking category, if the current page is in mainspace.
	if mw.title.getCurrentTitle().namespace == 0 then
		return makeCategoryLink(category)
	else
		return ''
	end
end

local function renderPtvTemplate(args, renderFunc)
	-- Render the output of a PTV template, given a table of arguments and a
	-- function to render the template from the arguments and route data.
	args = normalizeArguments(args)
	local routeData = getRouteData(args.mode, args.route)
	if not routeData then
		return renderTrackingCategory(INVALID_ROUTE_CATEGORY)
	end

	local ret = ''
	ret = ret .. renderFunc(args, routeData)
	if hasDeprecatedParameters(args) then
		ret = ret .. renderTrackingCategory(DEPRECATED_PARAMETER_CATEGORY)
	end
	return ret
end

function p._main(args)
	-- Generate a link to a Public Transport Victoria route.
	return renderPtvTemplate(args, makePtvLink)
end

function p._cite(args)
	-- Generate a citation for a Public Transport Victoria route.
	return renderPtvTemplate(args, makePtvCitation)
end

local function makeInvokableFunction(func, wrappers)
	-- Make a function that can be accessed with #invoke.
	return function (frame)
		local args = require('Module:Arguments').getArgs(frame, {
			wrappers = wrappers,
		})
		return func(args)
	end
end

p.main = makeInvokableFunction(p._main, 'Template:PTV route')
p.cite = makeInvokableFunction(p._cite, 'Template:Cite PTV route')

return p