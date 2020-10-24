--[[ v1.0
]]
local p = {}
local yesno = require("Module:yesno")

function p.main(frame)
	local rawpages = {}
	local nvalid = 0
	local namespace = frame.args.ns
	for i, v in ipairs(frame:getParent().args) do
		if (v ~= nil) then
			local thisArg = mw.text.trim(v)
			if (thisArg ~= "") then
				local title = mw.title.new(thisArg, namespace)
				if title ~= nil and title.exists then
					table.insert(rawpages, title.fullText)
					nvalid = nvalid + 1
				end
			end
		end
	end
	if (nvalid == 0) then
		if yesno(frame.args.warning) then
			if namespace == nil then
				namespace = "page"
			elseif namespace:sub(-1) == "y" then
				namespace = namespace:sub(0, -2) .. "ie"
			end
			mw.addWarning(string.format("'''[[%s]] — no output, because none of the %ss currently exist.'''",
				frame:getParent():getTitle(),namespace))
		end
		return ""
	end
	local mLabelledList = require('Module:Labelled list hatnote')
	local pages = mLabelledList._labelledList(rawpages, "See also", "")
	return pages
end

return p