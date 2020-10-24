local p = {}
local yesno = require("Module:Yesno")
function p.main(frame)
	local pframe = frame:getParent()
	local code = frame.args[1]
	if mw.text.trim(mw.text.killMarkers(code)) == "" or yesno(frame.args.unstrip) then
		code = mw.text.unstripNoWiki(code);
	end
	return pframe:preprocess(code)
end

return p