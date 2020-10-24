local p = {}

local redirModule = require "Module:Redirect"
local redir = redirModule.luaMain


-- Named arguments (optional) |YYYY= and |WW= used, like: {{#invoke:TAFI article|main|YYYY=2016|WW=06}}
function p.main(frame)
	local year = frame.args.YYYY or os.date( "%G" )        -- Specified year, or else the current year
	local week = frame.args.WW or os.date( "%V" )          -- Specified week, or else the current week
        week = tonumber(week)                                  -- Remove zero-padding, if present
	local title = frame:expandTemplate{ title = 'Wikipedia:Today\'s articles for improvement/' .. year .. '/' .. week .. '/1' } -- transclude page to get article title
        article = redir(title) or title                      -- Get target if title is a redirect
        return article

end

return p