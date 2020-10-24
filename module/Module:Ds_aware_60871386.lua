local p = {}
local getArgs = require('Module:Arguments').getArgs

function p.detect(frame)
	local title
	local args = getArgs(frame)
	if args.testTitle then
		title = mw.title.new(args.testTitle)
	else
		title = mw.title.getCurrentTitle()
	end
	local content = title:getContent() or ''
	local codes = string.match(content, "{{%s-D[sS]/[aA]ware%s-|([^}]-)}}")
	if not codes then return end
	local text = p._listToText(frame, mw.text.split(codes, "|"))
	return frame:preprocess(
		"<div style = 'font-weight: bold'>It is not necessary to notify this user of sanctions for the following topic area(s):"
		..text..
		"\n The user has indicated that they are already aware of these sanctions using the template <nowiki>{{Ds/aware}}</nowiki> on their talk page.</div>"
	)
end

function p.listToText(frame)
	return p._listToText(frame, getArgs(frame))
end

function p._listToText(frame, t)
	local new = {}
	local t = require('Module:TableTools').compressSparseArray(t)
	for i,v in ipairs(t) do
		table.insert(new, frame:expandTemplate{title = 'Ds/topics', args = {["sanctions scope"] = v}})
	end
	return '\n*'..table.concat(new, '\n*')
end

return p