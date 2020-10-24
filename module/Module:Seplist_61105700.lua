--[[
Module to implement an unordered list with a generalised separator.
Use TemplateStyles with an associated template to style the list.
It will recognise "hr" as the horizontal rule.
--]]

p = {}

p.makelist = function(frame)
	local args = frame.args
	if not args[1] then
		args = frame:getParent().args
		if not args[1] then return end
	end
	local sep = (args.sep or "")
	if sep == "hr" then sep = "<hr>" end
	local out = {}
	for k, v in ipairs(args) do
		v = mw.text.trim(v)
		table.insert(out, "<li>" .. v .. "</li>")
	end
	if #out > 0 then
		return '<ul class="seplist">' .. table.concat(out, sep) .. '</ul>'
	end
end

return p