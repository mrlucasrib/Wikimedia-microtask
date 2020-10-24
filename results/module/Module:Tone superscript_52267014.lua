local p = {}

function p.main(frame)
	local root = mw.html.create()
	local arg = frame:getParent().args[1] or ""
	local x = arg:gsub("%f[%d%s]([%d\*]+)", "<sup>%1</sup>")
	root:tag('span'):wikitext(x)
	local tracking = ''
	if string.match(arg, "</?sup>") then tracking = '[[Category:Pages using Tone superscript with sup tags]]' end
	return tostring(root)..tracking
end

return p