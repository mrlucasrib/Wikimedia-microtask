-- This module implements {{in5}}.

local p = {}

function p.in5(frame)
    local indent = frame.args[1]
    -- Trim whitespace and convert to number. Default to 5 if not present,
    -- as per the template title.
    indent = tonumber( mw.text.trim(indent) ) or 5
    -- Round down to nearest integer. Decimal values produce funky results
    -- from the original template, but there's no need for us to replicate that.
    indent = math.floor( indent )
    -- Don't output anything for zero or less. Again, there was some funky output
    -- here for negatives, but now we're in Lua we should use sane defaults.
    if indent <= 0 then
        return
    end
    
    local base = '&nbsp; '
    local modulo = '&nbsp;'
 
--[[
    Indent values and the corresponding values for base and modulo:

    indent  base    modulo
    1       0       1
    2       0       2
    3       1       1
    4       1       2
    5       2       1
    6       2       2
    7       3       1
    8       3       2
    9       4       1
    10      4       2
]]
    
    local baseNum = math.floor( (indent - 1) / 2 )
    local modNum = math.fmod( indent - 1 , 2 ) + 1
    
    return mw.ustring.rep( base, baseNum) .. mw.ustring.rep( modulo, modNum )
end

return p