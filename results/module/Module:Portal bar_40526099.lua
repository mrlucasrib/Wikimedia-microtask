-- This module implements {{portal bar}}.

require('Module:No globals')

local p = {}
local function checkPortalExists(portal)
	return not (mw.title.makeTitle(100, portal).id == 0)
end
local getImageName = require( 'Module:Portal' ).image
local yesno = require( 'Module:Yesno' )

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
		or (thisPage.namespace == 109) -- Book talk
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


-- Builds the portal bar used by {{portal bar}}.
function p._main( portals, args )
	
	if #portals < 1 then return '' end -- Don't display a blank navbox if no portals were specified.
	
	local nav = mw.html.create( 'div' )
		:addClass( 'noprint metadata' )
		:attr( 'role', 'navigation' )
		:attr( 'aria-label' , 'Portals' )
		:css( 'font-weight', 'bold' )
	if yesno( args.border ) == false then
		nav
			:css( 'padding', '0.3em 1.7em 0.1em' )
			:css( 'font-size', '88%' )
			:css( 'text-align', 'center' )
	else
		nav
			:addClass( 'navbox' )
			:css( 'padding', '0.4em 2em' )
	end
	
	if (args.tracking == 'no') or (args.tracking == 'n') or (args.tracking == 'false') then
		trackingEnabled = false
	end
	if (checkTrackingNamespace() == false) then
		trackingEnabled = false
	end
	if (checkTrackingPagename() == false) then
		trackingEnabled = false
	end

	-- If no portals have been specified, display an error and add the page to a tracking category.
	if not portals[1] then
		if (args.nominimum == 'yes') or (args.nominimum == 'y') or (args.nominimum == 'true') then
		-- if nominimum as been set to yes (or similar), omit the warning
			
		else
			root:wikitext('<strong class="error">No portals specified: please specify at least one portal</strong>')
		end
		if (trackingEnabled) then
			root:wikitext('[[Category:Portal templates without a parameter]]')
		end
		return tostring(root)
	end

	-- scan for nonexistent portals, if they exist remove them from the portals table. If redlinks=yes, then don't remove
	local portallen = #portals
	-- traverse the list backwards to ensure that no portals are missed (table.remove also moves down the portals in the list, so that the next portal isn't checked if going fowards.
	-- going backwards allows us to circumvent this issue
	for i=portallen,1,-1 do
		-- the use of pcall here catches any errors that may occour when attempting to locate pages when the page name is invalid
		-- if pcall returns true, then rerun the function to find if the page exists
		if not pcall(checkPortalExists, portals[i]) or not checkPortalExists(portals[i]) then
			-- Getting here means a redlinked portal has been found
			if (args.redlinks == 'yes') or (args.redlinks == 'y') or (args.redlinks == 'true') or (args.redlinks == 'include') then
				-- if redlinks as been set to yes (or similar), add the cleanup category and then break the loop before the portal is removed from the list
				if trackingEnabled then
					nav:wikitext('[[Category:Portal templates with redlinked portals]]')
				end
				break
			end
			-- remove the portal (this does not happen if redlinks=yes)
			table.remove(portals,i)
		end
	end
	
	-- if the length of the table is different, then rows were removed from the table, so portals were removed. If this is the case add the cleanup category
	if not (portallen == #portals) then
		if #portals == 0 then
        	if trackingEnabled then
				return '[[Category:Portal templates with all redlinked portals]]'
			else
				return ""
			end
        end
		if trackingEnabled then
			nav:wikitext('[[Category:Portal templates with redlinked portals]]')
		end
	end
	
	local list = mw.html.create( 'ul' )
		:css( 'margin', '0.1em 0 0' )
	for _, portal in ipairs( portals ) do
		list
			:tag( 'li' )
				:css( 'display', 'inline' )
				:tag( 'span' ) -- Inline-block on inner span for IE6-7 compatibility.
					:css( 'display', 'inline-block' )
					:css( 'white-space', 'nowrap' )
					:tag( 'span' )
						:css( 'margin', '0 0.5em' )
						:wikitext( string.format( '[[File:%s|24x21px]]', getImageName{ portal } ) )
						:done()
					:wikitext( string.format( '[[Portal:%s|%s portal]]', portal, portal ) )
	end
	
	nav
		:node( list )
	
	return tostring( nav )
end

-- Processes external arguments and sends them to the other functions.
function p.main( frame )
	-- If called via #invoke, use the args passed into the invoking
	-- template, or the args passed to #invoke if any exist. Otherwise
	-- assume args are being passed directly in from the debug console
	-- or from another Lua module.
	local origArgs
	if type( frame.getParent ) == 'function' then
		origArgs = frame:getParent().args
		for k, v in pairs( frame.args ) do
			origArgs = frame.args
			break
		end
	else
		origArgs = frame
	end
	-- Process the args to make an array of portal names that can be used with ipairs. We need to use ipairs because we want to list
	-- all the portals in the order they were passed to the template, but we also want to be able to deal with positional arguments
	-- passed explicitly, for example {{portal|2=Politics}}. The behaviour of ipairs is undefined if nil values are present, so we
	-- need to make sure they are all removed.
	local portals, args = {}, {}
	for k, v in pairs( origArgs ) do
		if type( k ) == 'number' and type( v ) == 'string' then -- Make sure we have no non-string portal names.
			if mw.ustring.find( v, '%S' ) then -- Remove blank values.
				table.insert( portals, k )
				end
			elseif type( k ) ~= 'number' then -- Separate named arguments from portals.
			if type( v ) == 'string' then
				v = mw.text.trim( v )
			end
			args[ k ] = v
		end
	end
	table.sort( portals )
	for i, v in ipairs( portals ) do
		portals[ i ] = mw.text.trim( origArgs[ v ] ) -- Swap keys with values, trimming whitespace.
	end
	return p._main( portals, args )
end

return p