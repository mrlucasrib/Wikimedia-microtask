--[[
ShowArguments
 
Displays all the arguments passed into the module 
Usage:
    {{ Invoke:ShowArguments | display }}
/*
*/
    if args[1] == nil then
        local pFrame = frame:getParent();
        args = pFrame.args;
        for k,v in pairs( frame.args ) do
            args[k] = v;
        end
    end

]]

local ShowArguments = {}

function ShowArguments.display(frame)
    local text='';
    globalFrame = frame
    local args = frame.args
    if args[1] == nil then
        text = 'Arguments from parent'
        local pFrame = frame:getParent();
        args = pFrame.args;
        for k,v in pairs( frame.args ) do
            args[k] = v;
        end
    end
        for k,v in pairs( frame.args ) do
             text = text .. 'key (' .. k .. ') value ('.. v .. ')';
        end
    return text
end

function ShowArguments.join(frame)
    local res='';
    local args = {};
    for k,v in pairs( frame.args ) do
      if v ~= nil and v ~= '' then
         args[k]=v
      end
    end
    local sep = args[1];
    res = table.concat( args, sep, 2, j );
    return 'sep (' .. sep ..')' .. res
end
 
return ShowArguments