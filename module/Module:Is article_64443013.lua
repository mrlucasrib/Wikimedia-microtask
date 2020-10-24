local p = {}

local disambiguationTemplates = {
	"[Dd]isambiguation",
	"[Dd]isambig",
	"[Dd]isamb",
	"[Dd]ab",
	"[Ss]urname"
	}

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	title = args[1]
	page = mw.title.new(title, 0)
	
	if (not page) then
		return "badtitle"
	end

	if (not page.exists) then
		return "empty"
	end

	if (page.isRedirect) then
		return "redirect"
	end

	local content = page:getContent()
	if (content) then
		for i, name in ipairs(disambiguationTemplates) do
			if (content:match('{{%s*' .. name .. '.*}}')) then
				return "dab"
			end
		end
	end

	return "article"
end

return p