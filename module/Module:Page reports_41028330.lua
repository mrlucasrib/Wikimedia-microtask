--In development. See Template:Page reports.
local p = {};

function p.demo( frame )
    local origArgs
    if frame == mw.getCurrentFrame() then
        origArgs = frame:getParent().args
        for k, v in pairs( frame.args ) do
            origArgs = frame.args
            break
        end
    else
        origArgs = frame
    end
 
    return "hello world" .. origArgs[1]
end

return p