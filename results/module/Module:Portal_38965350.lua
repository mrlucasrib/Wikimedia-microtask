--[==[ This module is a Lua implementation of the old {{Portal}} template. As of February 2019 it is used on nearly 7,900,000 articles.
-- Please take care when updating it! It outputs two functions: p.portal, which generates a list of portals, and p.image, which
-- produces the image name for an individual portal.

-- The portal image data is kept in submodules of [[Module:Portal/images]], listed below:
-- [[Module:Portal/images/a]]		- for portal names beginning with "A".
-- [[Module:Portal/images/b]]		- for portal names beginning with "B".
-- [[Module:Portal/images/c]]		- for portal names beginning with "C".
-- [[Module:Portal/images/d]]		- for portal names beginning with "D".
-- [[Module:Portal/images/e]]		- for portal names beginning with "E".
-- [[Module:Portal/images/f]]		- for portal names beginning with "F".
-- [[Module:Portal/images/g]]		- for portal names beginning with "G".
-- [[Module:Portal/images/h]]		- for portal names beginning with "H".
-- [[Module:Portal/images/i]]		- for portal names beginning with "I".
-- [[Module:Portal/images/j]]		- for portal names beginning with "J".
-- [[Module:Portal/images/k]]		- for portal names beginning with "K".
-- [[Module:Portal/images/l]]		- for portal names beginning with "L".
-- [[Module:Portal/images/m]]		- for portal names beginning with "M".
-- [[Module:Portal/images/n]]		- for portal names beginning with "N".
-- [[Module:Portal/images/o]]		- for portal names beginning with "O".
-- [[Module:Portal/images/p]]		- for portal names beginning with "P".
-- [[Module:Portal/images/q]]		- for portal names beginning with "Q".
-- [[Module:Portal/images/r]]		- for portal names beginning with "R".
-- [[Module:Portal/images/s]]		- for portal names beginning with "S".
-- [[Module:Portal/images/t]]		- for portal names beginning with "T".
-- [[Module:Portal/images/u]]		- for portal names beginning with "U".
-- [[Module:Portal/images/v]]		- for portal names beginning with "V".
-- [[Module:Portal/images/w]]		- for portal names beginning with "W".
-- [[Module:Portal/images/x]]		- for portal names beginning with "X".
-- [[Module:Portal/images/y]]		- for portal names beginning with "Y".
-- [[Module:Portal/images/z]]		- for portal names beginning with "Z".
-- [[Module:Portal/images/other]]	- for portal names beginning with any other letters. This includes numbers,
-- 									  letters with diacritics, and letters in non-Latin alphabets.
-- [[Module:Portal/images/aliases]]	- for adding aliases for existing portal names. Use this page for variations
-- 									  in spelling and diacritics, etc., no matter what letter the portal begins with.
--
-- The images data pages are separated by the first letter to reduce server load when images are added, changed, or removed.
-- Previously all the images were on one data page at [[Module:Portal/images]], but this had the disadvantage that all
-- 5,000,000 pages using this module needed to be refreshed every time an image was added or removed.
]==]

local p = {}

local trackingEnabled = true

local templatestyles = 'Module:Portal/styles.css'

local yesno = require('Module:Yesno')

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


local function matchImagePage(s)
	-- Finds the appropriate image subpage given a lower-case
	-- portal name plus the first letter of that portal name.
	if type(s) ~= 'string' or #s < 1 then return end
	local firstLetter = mw.ustring.sub(s, 1, 1)
	local imagePage
	if mw.ustring.find(firstLetter, '^[a-z]') then
		imagePage = 'Module:Portal/images/' .. firstLetter
	else
		imagePage = 'Module:Portal/images/other'
	end
	return mw.loadData(imagePage)[s]
end

local function getAlias(s)
	-- Gets an alias from the image alias data page.
	local aliasData = mw.loadData('Module:Portal/images/aliases')
	for portal, aliases in pairs(aliasData) do
		for _, alias in ipairs(aliases) do
			if alias == s then
				return portal
			end
		end
	end
end

local function getImageName(s)
	-- Gets the image name for a given string.
	local default = 'Portal-puzzle.svg|link=|alt='
	if type(s) ~= 'string' or #s < 1 then
		return default
	end
	s = mw.ustring.lower(s)
	return matchImagePage(s) or matchImagePage(getAlias(s)) or default
end

local function checkPortalExists(portal)
	return not (mw.title.makeTitle(100, portal).id == 0)
end

function p._portal(portals, args)
	-- This function builds the portal box used by the {{portal}} template.
	local root = mw.html.create('div')
		:attr('role', 'navigation')
		:attr('aria-label', 'Portals')
		:addClass('noprint portal plainlist')
		:addClass(args.left and 'tleft' or 'tright')
		:css('margin', args.margin or nil)
		:newline()

	-- Tracking is on by default.
	-- It is disabled if any of the following is true
	-- 1/ the parameter "tracking" is set to 'no, 'n', or 'false'
	-- 2/ the current page fails the namespace tests in checkTrackingNamespace()
	-- 3/ the current page fails the pagename tests in checkTrackingPagename()
	trackingEnabled = yesno(args.tracking, trackingEnabled)
	if (checkTrackingNamespace() == false) then
		trackingEnabled = false
	end
	if (checkTrackingPagename() == false) then
		trackingEnabled = false
	end

	-- If no portals have been specified, display an error and add the page to a tracking category.
	if not portals[1] then
		if yesno(args.nominimum) then
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
			if yesno(args.redlinks) or (args.redlinks == 'include') then
				-- if redlinks as been set to yes (or similar), add the cleanup category and then break the loop before the portal is removed from the list
				if (trackingEnabled) then
					root:wikitext('[[Category:Portal templates with redlinked portals]]')
				end
				break
			end
			-- remove the portal (this does not happen if redlinks=yes)
			table.remove(portals,i)
		end
	end
	
	-- if the length of the table is different, then rows were removed from the table, so portals were removed. If this is the case add the cleanup category
	if not (portallen == #portals) then
		if (trackingEnabled) then
			if #portals == 0 then
				return '[[Category:Portal templates with all redlinked portals]]'
			else
				root:wikitext('[[Category:Portal templates with redlinked portals]]')
			end
		end
	end

	-- Start the list. This corresponds to the start of the wikitext table in the old [[Template:Portal]].
	local listroot = root:tag('ul')
		:css('width', type(args.boxsize) == 'string' and (args.boxsize .. 'px') or nil)

	-- Display the portals specified in the positional arguments.
	for _, portal in ipairs(portals) do
		local image = getImageName(portal)

		-- Generate the html for the image and the portal name.
		listroot
			:newline()
			:tag('li')
				:tag('span')
					:wikitext(string.format('[[File:%s|32x28px|class=noviewer]]', image))
					:done()
				:tag('span')
					:wikitext(string.format('[[Portal:%s|%s%sportal]]', portal, portal, args['break'] and '<br />' or ' '))
	end
	return tostring(root)
end

function p._image(portals)
	-- Wrapper function to allow getImageName() to be accessed through #invoke.
	local name = getImageName(portals[1])
	return name:match('^(.-)|') or name -- FIXME: use a more elegant way to separate borders etc. from the image name
end

local function getAllImageTables()
	-- Returns an array containing all image subpages (minus aliases) as loaded by mw.loadData.
	local images = {}
	for i, subpage in ipairs{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'other'} do
		images[i] = mw.loadData('Module:Portal/images/' .. subpage)
	end
	return images
end

function p._displayAll(portals, args)
	-- This function displays all portals that have portal images. This function is for maintenance purposes and should not be used in
	-- articles, for two reasons: 1) there are over 1500 portals with portal images, and 2) the module doesn't record how the portal
	-- names are capitalized, so the portal links may be broken.
	local lang = mw.language.getContentLanguage()
	local count = 1
	for _, imageTable in ipairs(getAllImageTables()) do
		for portal in pairs(imageTable) do
			portals[count] = lang:ucfirst(portal)
			count = count + 1
		end
	end
	return p._portal(portals, args)
end

function p._imageDupes()
	-- This function searches the image subpages to find duplicate images. If duplicate images exist, it is not necessarily a bad thing,
	-- as different portals might just happen to choose the same image. However, this function is helpful in identifying images that
	-- should be moved to a portal alias for ease of maintenance.
	local exists, dupes = {}, {}
	for _, imageTable in ipairs(getAllImageTables()) do
		for portal, image in pairs(imageTable) do
			if not exists[image] then
				exists[image] = portal
			else
				table.insert(dupes, string.format('The image "[[:File:%s|%s]]" is used for both portals "%s" and "%s".', image, image, exists[image], portal))
			end
		end
	end
	if #dupes < 1 then
		return 'No duplicate images found.'
	else
		return 'The following duplicate images were found:\n* ' .. table.concat(dupes, '\n* ')
	end
end

local function processPortalArgs(args)
	-- This function processes a table of arguments and returns two tables: an array of portal names for processing by ipairs, and a table of
	-- the named arguments that specify style options, etc. We need to use ipairs because we want to list all the portals in the order
	-- they were passed to the template, but we also want to be able to deal with positional arguments passed explicitly, for example
	-- {{portal|2=Politics}}. The behaviour of ipairs is undefined if nil values are present, so we need to make sure they are all removed.
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
		
		local results = ''
		if funcName == '_portal' or funcName == '_displayAll' then
			results = frame:extensionTag{ name = 'templatestyles', args = { src = templatestyles} }
		end
		return results .. p[funcName](processPortalArgs(args)) -- passes two tables to func: an array of portal names, and a table of named arguments.
	end
end

for _, funcName in ipairs{'portal', 'image', 'imageDupes', 'displayAll'} do
	p[funcName] = makeWrapper('_' .. funcName)
end

return p