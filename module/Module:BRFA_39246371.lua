local p = {}

local function splitNameNumber( title )
    -- First, name with number?
    local name, number = title:match( '^Wikipedia:Bots/Requests for approval/(.-) (%d+)$' )
    if name then
        return name, number, name .. ' ' .. number
    end
    
    -- Extract name
    name = title:match( '^Wikipedia:Bots/Requests for approval/(.*)$' )
    if name then
        return name, '', name
    end
    
    -- Error
    error( 'Invalid page name' )
end

function p.userpageLink( frame )
    local name, number, nameNumber = splitNameNumber( mw.title.getCurrentTitle().fullText )
    return '[[User:' .. name .. '|' .. nameNumber .. ']]'
end

function p.newbotTemplate( frame )
    local name, number, nameNumber = splitNameNumber( mw.title.getCurrentTitle().fullText )
    return '{{Newbot|' .. name .. '|' .. number .. '}}'
end

function p.botNameNumber( frame )
    local name, number, nameNumber = splitNameNumber( mw.title.getCurrentTitle().fullText )
    return nameNumber
end


return p