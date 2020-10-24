p = {}

p.makelist = function(frame)
	local args = frame.args
	if not args[1] then
		args = frame:getParent().args
		if not args[1] then return end
	end
	local semi = (args.semi or ""):sub(1,1):lower()
	semi = (semi == "t") or (semi == "y")
	local embedded = (args.embedded or ""):sub(1,1):lower()
	embedded = (embedded == "y")
	local out = ""
	for k, v in ipairs(args) do
		v = mw.text.trim(v)
		if v ~= "" then
			out = out .. "<li>" .. v .. "</li>"
		end
	end
	local listclass = ""
	if semi then
		listclass = listclass .. "sslist"
	else
		listclass = listclass .. "cslist"
	end
	if embedded then
		listclass = listclass .. " cslist-embedded"
	end
	if out ~= "" then
		return '<ul class="'.. listclass ..'">' .. out .. '</ul>'
	end
end

return p