local p = {}
local mRedirect = require('Module:Redirect')

local disambigTemplates = {
	"[Dd][Aa][Bb]",
	"[Dd]big",
	"[%w_%s]-%f[%w][Dd]isam[%w]-",
	"[Hh][Nn][Dd][Ii][Ss]"
}

p.isDisambiguation = function(content)
	-- false if there is no content
	if content == nil then return false end
	
	-- redirects are not disambiguation pages
	if mRedirect.getTargetFromText(content) ~= nil then return false end
	
	-- check for disambiguation templates in the content
	for _i, v in ipairs(disambigTemplates) do
		if mw.ustring.find(content, "{{%s*".. v .. "%s*%f[|}]") ~= nil then
			return true
		end
	end
	return false
end

p._isDisambiguationPage = function(page)
	-- Look "(disambiguation)" in the title
	if mw.ustring.find(page, "(disambiguation)",0,true) ~= nil then
		return true;
	end
	-- Look for disamiguation template in page content
	local title = mw.title.new(page)
	if not title then return false end
	local content = title:getContent()
	return p.isDisambiguation(content)
end

-- Entry points for templates
p.isDisambiguationPage = function(frame)
	local title = frame.args[1]
	return p._isDisambiguationPage(title) and "yes" or ""
end

return p