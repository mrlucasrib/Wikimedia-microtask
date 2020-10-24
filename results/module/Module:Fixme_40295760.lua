-- This module searches through the specified Lua module, and if it finds the text "FIXME" it adds it to a tracking category.

local trackingCategory = 'Lua modules with fixme tags'

local p = {}

-- Gets a title object for the specified page, and defaults to the
-- title object for the current page if it is not specified or if
-- there are any errors.
local function getTitleObject( page )
    local currentTitle = mw.title.getCurrentTitle()
    if page then
        -- Get the title object, passing the function through pcall 
        -- in case we are over the expensive function count limit.
        local noError, titleObject = pcall( mw.title.new, page )
        if not noError or not titleObject then
            return currentTitle
        else
            return titleObject
        end
    else
        return currentTitle
    end    
end

local function _main( page )
    page = getTitleObject( page )
    -- This module should only be used to search for other modules.
    if page.nsText ~= 'Module' then
        return
    end
    -- Match the base page if we are being called from a sandbox or a /doc page.
    local subpage = page.subpageText
    if page.isSubpage and ( subpage == 'doc' or subpage == 'sandbox' ) then
        page = getTitleObject( page.baseText )
    end
    -- The module shouldn't match itself.
    if page.prefixedText == 'Module:Fixme' then
        return
    end
    -- Get the page content.
    local content = page:getContent()
    if not content then
        return
    end
    -- Find any "FIXME" text.
    local fixmeExists = false
    local fixmePattern = '%WFIXME%W'
    for singleLineComment in mw.ustring.gmatch( content, '%-%-([^\n]*)' ) do
        if mw.ustring.find( singleLineComment, fixmePattern ) then
            fixmeExists = true
        end
    end
    if not fixmeExists then
        for multiLineComment in mw.ustring.gmatch( content, '(%-%-%[(=*)%[.-%]%2%])' ) do
            if mw.ustring.find( multiLineComment, fixmePattern ) then
                fixmeExists = true
            end
        end
    end
    -- If any FIXMEs were found, return the tracking category.
    if fixmeExists then
        return mw.ustring.format( '[[Category:%s|%s]]', trackingCategory, page.text )
    end
end

function p.main( frame )
    -- If we are being called from #invoke, then the page name is the first positional
    -- argument. If not, it is the frame parameter.
    local page
    if frame == mw.getCurrentFrame() then
        page = frame:getParent().args[ 1 ]
        local framePage = frame.args[ 1 ]
        if framePage then
            page = framePage
        end
    else
        page = frame
    end
    return _main( page )
end

return p