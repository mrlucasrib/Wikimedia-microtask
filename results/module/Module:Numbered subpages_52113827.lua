-- This module implements {{numbered subpages}}.

local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')

p = {}

local function ifexist(page)
    if not page then return false end
    if mw.title.new(page).exists then return true end
    return false
end

function p.main(frame)
	local args = getArgs(frame)
	local maxk = tonumber(args.max or '50') or 50
	local mink = tonumber(args.min or '1') or 1
	local root = ''
	local missing = args.missing or (args.max and 'transclude' or 'skip')
	local ret = {}
	local headertemplate = args.headertemplate or ''
	local subpageTemplate = 'Portal subpage'
	if yesno(args.inline) then
		subpageTemplate = 'Portal subpage inline'
	end
	
	if missing ~= 'transclude' then
		root = frame:preprocess('{{FULLPAGENAME}}')
	end
	maxk = (maxk > (mink + 250)) and (mink + 250) or maxk
	local SPAN = args.SPAN or ''
	local preload = args.preload or ''
	for i=mink,maxk do
		if missing == 'transclude' then
			if headertemplate == '' then
				ret[#ret + 1] = frame:expandTemplate{title = subpageTemplate, args = { i, SPAN=SPAN } }
			else 
				ret[#ret + 1] = frame:expandTemplate{title = subpageTemplate, args = { i, headertemplate=headertemplate, SPAN=SPAN } }
			end
		else
			subpagename = root .. '/' .. i
			if ifexist(subpagename) then
				if headertemplate == '' then
					ret[#ret + 1] = frame:expandTemplate{title = subpageTemplate, args = { i, SPAN=SPAN } }
				else 
					ret[#ret + 1] = frame:expandTemplate{title = subpageTemplate, args = { i, headertemplate=headertemplate, SPAN=SPAN } }
				end
			else
				if missing == 'link' then
					if preload then
						ret[#ret + 1] = '* ' .. frame:expandTemplate{title = 'edit', args = { subpagename, 'Create ' .. subpagename, preload=preload } }
					else
						ret[#ret + 1] = '* [[' .. subpagename .. ']]'
					end
				elseif missing == 'stop' then
					i = maxk + 1
				end
			end
		end
	end
	
	return table.concat(ret, '\n')
end

return p