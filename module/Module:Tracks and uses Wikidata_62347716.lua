local p = {}

function p.tuProperty(frame)
	local parent = frame.getParent(frame)
	local result = ''
	local ii = 1
	while true do
		local p_num = mw.text.trim(parent.args[ii] or '')
		if p_num ~= '' then
			local label = mw.wikibase.label(p_num) or "NO LABEL"
			result = result .. "<ul><li><span style='font-size:90%;line-height:1;'>●</span>&nbsp;&nbsp;[[d:Property:" .. p_num .. "|" .. label .. "]] <span style='font-size:90%;'>([[d:Property talk:" .. string.upper(p_num) .. "|" .. p_num .. "]])</span></li></ul>"
			ii = ii + 1
		else break
		end
	end
	return result
end

return p