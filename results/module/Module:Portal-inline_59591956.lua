local getImageName = require( 'Module:Portal' ).image

local p = {}

local function checkPortalExists(portal)
	return not (mw.title.makeTitle(100, portal).id == 0)
end

local trackingEnabled = true

-- Check whether to do tracking in this namespace
-- Returns true unless the page is one of the banned namespaces
local function checkTrackingNamespace()
	local thisPage = mw.title.getCurrentTitle()
	if (thisPage.namespace == 1) -- Talk
		or (thisPage.namespace == 2) -- User
		or (thisPage.namespace == 3) -- User talk
		or (thisPage.namespace == 5) -- Wikipedia talk
		or (thisPage.namespace == 7) -- File talk
		or (thisPage.namespace == 11) -- Template talk
		or (thisPage.namespace == 15) -- Category talk
		or (thisPage.namespace == 101) -- Portal talk
		or (thisPage.namespace == 118) -- Draft
		or (thisPage.namespace == 119) -- Draft talk
		or (thisPage.namespace == 829) -- Module talk
		then
		return false
	end
	return true
end

-- Check whether to do tracking on this pagename
-- Returns false if the page title matches one of the banned strings
-- Otherwise returns true
local function checkTrackingPagename()
	local thisPage = mw.title.getCurrentTitle()
	local thisPageLC = mw.ustring.lower(thisPage.text)
	if (string.match(thisPageLC, "/archive") ~= nil) then
		return false
	end
	if (string.match(thisPageLC, "/doc") ~= nil) then
		return false
	end
	if (string.match(thisPageLC, "/test") ~= nil) then
		return false
	end
	return true
end

function p._main(portals, args)
	local root = ""
	mw.logObject(args)
	-- ignore extra portals listed
	-- If no portals have been specified, display an error and add the page to a tracking category.
	-- Tracking is on by default.
	-- It is disabled if any of the following is true
	-- 1/ the parameter "tracking" is set to 'no, 'n', or 'false'
	-- 2/ the current page fails the namespace tests in checkTrackingNamespace()
	-- 3/ the current page fails the pagename tests in checkTrackingPagename()

	if (args.tracking == 'no') or (args.tracking == 'n') or (args.tracking == 'false') then
		trackingEnabled = false
	end
	if (checkTrackingNamespace() == false) then
		trackingEnabled = false
	end
	if (checkTrackingPagename() == false) then
		trackingEnabled = false
	end

	if not portals[1] then
		root = '<span style="font-size:100%;" class="error">error: missing portal name.</span></strong>"'
		if trackingEnabled then
			root = root .. '[[Category:Portal templates without a parameter]][[Category:Portal-inline template without a parameter]]'
		end
		return tostring(root)
	end
	if portals[2] or portals[3] then
		root = '<span style="font-size:100%;" class="error">error: Template:portal-inline accepts only one portal as a parameter</span></strong> &nbsp; &nbsp; "'
		if trackingEnabled then
			root = root .. '[[Category:Portal-inline template with more than one portal parameter]]'
		end
	end
	
	if not pcall(checkPortalExists, portals[1]) or not checkPortalExists(portals[1]) then
		-- Getting here means a redlinked portal has been found
		if not ((args.redlinks == 'yes') or (args.redlinks == 'y') or (args.redlinks == 'true') or (args.redlinks == 'include')) then
			-- just return if redlinks is not "yes" or similar
			if trackingEnabled then
				if portals[2] or portals[3] then
					root = root .. '[[Category:Portal templates with redlinked portals]][[Category:Portal-inline template with redlinked portals]]'
				else
					root = root .. '[[Category:Portal templates with all redlinked portals]][[Category:Portal-inline template with redlinked portals]]'
				end
			end
			return tostring(root)
		end
		if trackingEnabled then
			root = '[[Category:Portal templates with redlinked portals]][[Category:Portal-inline template with redlinked portals]]'
		end
	end
	
	if args['size'] == "tiny" then
		args['size'] = "16x16px"
	else
		args['size'] = "32x28px"
	end
	
	local displayName = ""
	if not (args['text'] == "" or args['text'] == nil) then
		displayName = args['text']
	elseif not (args.short == "" or args.short == nil) then
		displayName = portals[1]
	else
		displayName = portals[1] .. "&#32;portal"
	end
	-- display portal-inline content
	root = root .. string.format('[[File:%s|class=noviewer|%s]]&nbsp;[[Portal:%s|%s]]', getImageName{ portals[1] }, args['size'], portals[1], displayName)
	
	return tostring(root)
end

-- copied from [[Module:Portal]]
local function processPortalArgs(args)
	-- This function processes a table of arguments and returns two tables: an array of portal names for processing by ipairs, and a table of
	-- the named arguments that specify style options, etc. We need to use ipairs because we want to list all the portals in the order
	-- they were passed to the template, but we also want to be able to deal with positional arguments passed explicitly, for example
	-- {{portal-inline|Politics}}. The behaviour of ipairs is undefined if nil values are present, so we need to make sure they are all removed.
	args = type(args) == 'table' and args or {}
	local portals = {}
	local namedArgs = {}
	for k, v in pairs(args) do
		if type(k) == 'number' and type(v) == 'string' then -- Make sure we have no non-string portal names.
			table.insert(portals, k)
		elseif type(k) ~= 'number' then
			namedArgs[k] = v
		end
	end
	table.sort(portals)
	for i, v in ipairs(portals) do
		portals[i] = args[v]
	end
	return portals, namedArgs
end

local function makeWrapper(funcName)
	-- Processes external arguments and sends them to the other functions.
	return function (frame)
		-- If called via #invoke, use the args passed into the invoking
		-- template, or the args passed to #invoke if any exist. Otherwise
		-- assume args are being passed directly in from the debug console
		-- or from another Lua module.
		local origArgs
		if type(frame.getParent) == 'function' then
			origArgs = frame:getParent().args
			for k, v in pairs(frame.args) do
				origArgs = frame.args
				break
			end
		else
			origArgs = frame
		end
		-- Trim whitespace and remove blank arguments.
		local args = {}
		for k, v in pairs(origArgs) do
			if type(v) == 'string' then
				v = mw.text.trim(v)
			end
			if v ~= '' then
				args[k] = v
			end
		end
		return p[funcName](processPortalArgs(args)) -- passes two tables to func: an array of portal names, and a table of named arguments.
	end
end

for _, funcName in ipairs{'main'} do
	p[funcName] = makeWrapper('_' .. funcName)
end

return p