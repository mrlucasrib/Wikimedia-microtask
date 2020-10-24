local mOtheruses = require('Module:Other uses')
local p = {}
p.otherusesof = function (frame)
	function getArg (num)
		local x = frame:getParent().args[num]
		return x ~= '' and x or nil
	end
	local currentTitle = mw.title.getCurrentTitle().prefixedText
	local ofWhat = getArg(1) or currentTitle
	local page = getArg(2)
	local options = {
		title = ofWhat,
		otherText = string.format('uses of "%s"', ofWhat)
	}
	local oddCat = "[[Category:Hatnote templates using unusual parameters]]"
	if (mw.ustring.lower(getArg(1) or "") == mw.ustring.lower(currentTitle)) or
		((not getArg(1)) and not getArg(2)) then
			options.otherText = options.otherText .. oddCat
	end
	arg = page and {page} or {}
	return mOtheruses._otheruses(arg, options)
end
return p