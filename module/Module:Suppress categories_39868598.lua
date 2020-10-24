-- This is a simple module to strip categories from wikitext. It does
-- not support nested links or magic words like __TOC__, etc. Even so,
-- it should still handle most categories.

local p = {}

-- Detects if a category link is valid or not. If it is valid,
-- the function returns the blank string. If not, the input
-- is returned with no changes.
local function processCategory( all, submatch )
    local beforePipe = mw.ustring.match( submatch, '^(.-)[%s_]*|[%s_]*.-$' )
    beforePipe = beforePipe or submatch
    if mw.ustring.match( beforePipe, '[%[%]<>{}%c\n]' ) then
        return all
    else
        return ''
    end
end

-- Preprocess the content if we aren't being called from #invoke,
-- and pass it to gsub to remove valid category links.
local function suppress( content, isPreprocessed )
    if not isPreprocessed then
        content = mw.getCurrentFrame():preprocess( content )
    end
    content = mw.ustring.gsub(
        content,
        '(%[%[[%s_]*[cC][aA][tT][eE][gG][oO][rR][yY][%s_]*:[%s_]*(.-)[%s_]*%]%])',
        processCategory
    )
    return content
end

-- Get the content to suppress categories from, and find
-- whether the content has already been preprocessed. (If the
-- module is called from #invoke, it has been preprocessed already.)
function p.main( frame )
    local content, isPreprocessed
    if frame == mw.getCurrentFrame() then
        content = frame:getParent().args[1]
        if frame.args[1] then
            content = frame.args[1]
        end
        isPreprocessed = true
    else
        content = frame
        isPreprocessed = false
    end
    return suppress( content, isPreprocessed )
end

return p