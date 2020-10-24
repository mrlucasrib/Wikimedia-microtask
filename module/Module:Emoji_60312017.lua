local p= {}

function p.emocode(frame)
	local emotbl = mw.loadData ('Module:Emoji/data').emotbl
	local emoname = mw.text.trim(frame.args[1] or "")	-- make sure empty and missing parameters both become the empty string
	if '' == emoname then emoname = 'smiley' end		-- use default value of 'smiley' if parameter is empty or missing
	return emotbl[emoname] or emoname
end

function p.emoname(frame)
	local emorevtbl = mw.loadData('Module:Emoji/data/revtable')['emorevtbl']
	local emocode = mw.text.trim(frame.args[1] or "")	-- make sure empty and missing parameters both become the empty string
	if '' == emocode then emocode = '1f603' end		-- use default value of '1f603' if parameter is empty or missing
	return emorevtbl[emocode] or emocode
end

return p