-- This module implements {{team roster navbox}}
local me = { }

local Navbox = require('Module:Navbox')

local getArgs -- lazily initialized

local function colorlinks(v, s)
	if v and v ~= '' and s and s ~= '' then
		if not mw.ustring.match(v, '<span style') then
			v = mw.ustring.gsub(v, '%[%[([^%[%]|]*)%]%]', 
				'[[%1|<span style="' .. s .. '>%1</span>]]')
			v = mw.ustring.gsub(v, '%[%[([^%[%]|]*)|([^%[%]|]*)%]%]', 
				'[[%1|<span style="' .. s .. '>%2</span>]]')
		end
	end
	return v
end

local function extractstyle(v)
	local r = ''
	local slist = mw.text.split(mw.ustring.gsub(mw.ustring.gsub(v or '', '&#[Xx]23;', '#'), '&#35;', '#'), ';')
	for k = 1,#slist do
		local s = slist[k]
		if s:match('^[%s]*background') or s:match('^[%s]*color') then
			r = r .. s .. ';'
		end
	end
	return r
end	

function me.generateRosterNavbox(frame)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end
    local args = { }
    local parentArgs = getArgs(frame)
    
    -- Default is to nowrap items
    args['nowrapitems'] = 'yes'

    -- Massage the styles for coloring the links
    local basestyle  = extractstyle(parentArgs['basestyle'] or '')
    local titlestyle = extractstyle(parentArgs['titlestyle'] or '')
    local abovestyle = extractstyle(parentArgs['abovestyle'] or '')
    local groupstyle = extractstyle(parentArgs['groupstyle'] or '')
    local belowstyle = extractstyle(parentArgs['belowstyle'] or '')
    
    if basestyle ~= '' then
    	titlestyle = basestyle .. ';' .. titlestyle
    	abovestyle = basestyle .. ';' .. abovestyle
    	groupstyle = basestyle .. ';' .. groupstyle
    	belowstyle = basestyle .. ';' .. belowstyle
    end
    
    -- Color links before passing them to the Navbox helper function
    for argName, value in pairs(parentArgs) do
        if value ~= '' then
            if type(argName) == 'string' then
                if argName == 'title' then
                    value = colorlinks(value, titlestyle)
                elseif argName == 'above' then
                    value = colorlinks(value, abovestyle)
                elseif mw.ustring.find(argName, '^group[0-9][0-9]*$') then
                	if parentArgs[argName .. 'style'] then
	                    value = colorlinks(value, extractstyle(groupstyle .. ';' .. parentArgs[argName .. 'style']))
	                else
	                	value = colorlinks(value, groupstyle)
	                end
                elseif argName == 'below' then
                    value = colorlinks(value, belowstyle)
                end
                args[argName] = value
            end
        end
    end
    -- Note Navbox.navbox() has a kludge to order the parent frame's args
    -- into a specific order. For now, this is omitted from this module.

    return Navbox._navbox(args)

end  -- function me.generateRosterNavbox

return me