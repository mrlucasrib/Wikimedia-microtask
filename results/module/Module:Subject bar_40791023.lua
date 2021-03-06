local getPortalImage = require('Module:Portal').image

local p = {}

local function getArgNums(prefix, args)
    -- Returns a table containing the numbers of the arguments that exist for the specified prefix. For example, if the
    -- prefix was 'data', and 'data1', 'data2', and 'data5' exist, it would return {1, 2, 5}.
    local nums = {}
    for k, v in pairs(args) do
        local num = tostring(k):match('^' .. prefix .. '([1-9]%d*)$')
        if num then table.insert(nums, tonumber(num)) end
    end
    table.sort(nums)
    return nums
end

local function makeHorizontalRule()
    local row = mw.html.create('tr')
    row
        :tag('td')
            :attr('colspan', '2')
            :tag('hr', {selfClosing = true})
    return tostring(row)
end

local function makeItem(image, text)
    local root = mw.html.create('li')
    root
        :css('float', 'left')
        :css('margin-left', '0.3em')
        :css('height', '3.6em')
        :tag('span')
            :css('display', 'inline-block')
            :css('margin-right', '0.3em')
            :css('width', '30px')
            :css('line-height', '3.6em')
            :css('text-align', 'center')
            :wikitext(image)
            :done()
        :tag('span')
            :css('display', 'inline-block')
            :css('width', '11em')
            :css('vertical-align', 'middle')
            :wikitext(text)
    return tostring(root)
end

local function makeRow(items, heading, subheading, options)
    if #items < 1 then return end
    local swapHeadingSize = type(options) == 'table' and options.swapHeadingSize or false
    local row = mw.html.create('tr')
    row
        :tag('td')
            :css('width', '125px')
            :cssText('border-right:solid 1px black; padding-left:3px; padding-right:3px;')
            :tag('span')
                :css('font-size', swapHeadingSize and '90%' or '125%')
                :wikitext(heading)
                :done()
            :tag('br', {selfClosing = true})
                :done()
            :tag('span')
                :css('font-size', swapHeadingSize and '125%' or '90%')
                :wikitext(subheading)
    local list = row:tag('td'):css('text-align', 'left'):tag('ul')
    for i, item in ipairs(items) do
        local image = item[1]
        local text = item[2]
        list
            :wikitext(makeItem(image, text))
    end
    return tostring(row)
end

local function makeNumberedRow(prefix, args, heading, subheading, getItemValsFunc, options)
    if args[prefix] then
        args[prefix .. '1'] = args[prefix]
    end
    local argNums = getArgNums(prefix, args)
    local items = {}
    for i, argNum in ipairs(argNums) do
        local image, text = getItemValsFunc(args[prefix .. tostring(argNum)])
        table.insert(items, {image, text})
    end
    return makeRow(items, heading, subheading, options)
end

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

local redlinkedportal = ""

function p._main(args)
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

    local rows = {}
    --[=[ disabled per [[Wikipedia:Village pump (technical)/Archive 176#Suppress rendering of Template:Wikipedia books]]
    -- Get the book row text.
    local bookHeading = "'''[[Wikipedia:Books|Books]]'''"
    local bookSubheading = 'View or order collections of articles'
    local function getBookItemVals(book)
        local image = '[[File:Office-book.svg|30px|alt=|link=]]'
        local text = mw.ustring.format("'''''[[Book:%s|%s]]'''''", book, book)
        return image, text
    end
    local bookRow = makeNumberedRow('book', args, bookHeading, bookSubheading, getBookItemVals)
    table.insert(rows, bookRow)
    ]=]
    -- Get the portal row text
    local portalHeading = "'''[[Portal:Contents/Portals|Portals]]'''"
    local portalSubheading = 'Access related topics'
    local function getPortalItemVals(portal)
        local image = mw.ustring.format('[[File:%s|30x30px]]', getPortalImage{portal})
        local text = mw.ustring.format("'''''[[Portal:%s|%s portal]]'''''", portal, portal)
		if not pcall(checkPortalExists, portal) or not checkPortalExists(portal) then
			-- Getting here means a redlinked portal has been found
				if trackingEnabled then
					redlinkedportal = '[[Category:Subject bar templates with redlinked portals]]'
				end
		end
        return image, text
    end
    local portalRow = makeNumberedRow('portal', args, portalHeading, portalSubheading, getPortalItemVals)
    table.insert(rows, portalRow)

    -- Get the sister projects row text.
    local sisters = {
        {arg = 'commons', image = 'Commons-logo.svg', prefix = 'commons', display = 'Media', from = 'Commons'},
        {arg = 'species', image = 'Wikispecies-logo.svg', prefix = 'wikispecies', display = 'Species directories', from = 'Wikispecies'},
        {arg = 'voy', image = 'Wikivoyage-Logo-v3-icon.svg', prefix = 'voy', display = 'Travel guides', from = 'Wikivoyage'},
        {arg = 'n', image = 'Wikinews-logo.svg', prefix = 'wikinews', display = 'News stories', from = 'Wikinews'},
        {arg = 'wikt', image = 'Wiktionary-logo-v2.svg', prefix = 'wiktionary', postfix = 'English', display = 'Definitions', from = 'Wiktionary'},
        {arg = 'b', image = 'Wikibooks-logo.svg', prefix = 'wikibooks', display = 'Textbooks', from = 'Wikibooks'},
        {arg = 'q', image = 'Wikiquote-logo.svg', prefix = 'wikiquote', display = 'Quotations', from = 'Wikiquote'},
        {arg = 's', image = 'Wikisource-logo.svg', prefix = 'wikisource', display = 'Source texts', from = 'Wikisource'},
        {arg = 'v', image = 'Wikiversity-logo.svg', prefix = 'wikiversity', display = 'Learning resources', from = 'Wikiversity'},
        {arg = 'd', image = 'Wikidata-logo.svg', prefix = 'wikidata', display = 'Data', from = 'Wikidata'},
        {arg = 'spoken', image = 'Sound-icon.svg', prefix = 'spoken wikipedia', display = 'Listen to this page', from = 'Spoken Wikipedia'},
    }
    local sisterItems = {}
    for i, t in ipairs(sisters) do
        if args[t.arg] then
            -- Get the image value.
            local image = mw.ustring.format('[[File:%s|30x30px|alt=|link=]]', t.image)
            -- Get the text value.
            local prefix = t.prefix
            local search = args[t.arg .. '-search'] or mw.title.getCurrentTitle().text
            local postfix = t.postfix
            postfix = postfix and ('#' .. postfix) or ''
            local display = t.display
            local from = t.from
            local text = mw.ustring.format(
                '[[%s:Special:Search/%s%s|%s]]<br />from %s',
                prefix,    search,    postfix, display, from
            )
            if t.arg == 'spoken' then
            	 text = mw.ustring.format('%s on %s<br />[[File:%s]]',
                				display, from, args[t.arg] 
                )		
            end
            -- Add the values to the items table.
            table.insert(sisterItems, {image, text})
        end
    end
    local sisterHeading = "Find out more on<br />Wikipedia's"
    local sisterSubheading = "'''[[Wikipedia:Wikimedia sister projects|Sister projects]]'''"
    local sisterRow = makeRow(sisterItems, sisterHeading, sisterSubheading, {swapHeadingSize = true})
    table.insert(rows, sisterRow)

    -- Make the table.
    local root = mw.html.create('table')
    root
        :attr('role', 'presentation')
        :addClass('subjectbar')
        :addClass('noprint')
        :addClass('metadata')
        :addClass('plainlist')
        :wikitext(table.concat(rows, makeHorizontalRule()))

    return tostring(root)
end

function p.main(frame)
    -- If called via #invoke, use the args passed into the invoking template, or the args passed to #invoke if any exist. Otherwise
    -- assume args are being passed directly in from the debug console or from another Lua module.
    local origArgs
    if frame == mw.getCurrentFrame() then
        origArgs = frame:getParent().args
        for k, v in pairs(frame.args) do
            origArgs = frame.args
            break
        end
    else
        origArgs = frame
    end
    -- Remove blank arguments.
    local args = {}
    for k, v in pairs(origArgs) do
        if v ~= '' then
            args[k] = v
        end
    end
    return frame:extensionTag{ name = 'templatestyles', args = { src = 'Subject bar/styles.css'} } .. p._main(args) .. redlinkedportal
end

return p