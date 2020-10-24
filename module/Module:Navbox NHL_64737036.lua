-- This module implements {{navbox NHL}}
local p = { }

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
    local args = {}
    local parentArgs = getArgs(frame)
    
    -- Get the template name
    local name = parentArgs['teamname'] or 'National Hockey League'
    
    -- Set defaults
    args['bodyclass'] = 'hlist'
    args['title'] = '[[' .. name .. ']]'
    
    -- Coloring
	local sportscolor = require('Module:Sports color')
	args['titlestyle'] = sportscolor.titlestripe({['args'] = {name, ['width'] = '5', ['sport'] = 'ice hockey'}})
	args['groupstyle'] = sportscolor.cellborder({['args'] = {name, ['width'] = '2', ['sport'] = 'ice hockey'}})
	args['abovestyle'] = args['groupstyle']
	args['belowstyle'] = sportscolor.cellborder2({['args'] = {name, ['width'] = '2', ['sport'] = 'ice hockey'}})

    -- Copy args to pass them to the Navbox helper function
    for argName, value in pairs(parentArgs) do
        if value ~= '' then
            if type(argName) == 'string' then
                if argName == 'teamname' then
                    value = ''
                end
                args[argName] = value
            end
        end
    end
    -- Note Navbox.navbox() has a kludge to order the parent frame's args
    -- into a specific order. For now, this is omitted from this module.

	local Navbox = require('Module:Navbox')
    return Navbox._navbox(args)

end

return p