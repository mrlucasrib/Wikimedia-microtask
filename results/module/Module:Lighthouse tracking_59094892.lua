local p = {}
function p.tracking(frame)
	local res = ''
	local isNRHP = false
	local hasNRHPbox = false
	local heritage = frame.args.heritage or ''
	if heritage == '' then
	elseif (heritage:match('National Register of Historic Places') or
		heritage:match('NRHP') ) then
		res = res .. '[[Category:Pages using infobox lighthouse with NRHP heritage]]'
		isNRHP = true
	else
		heritage = mw.ustring.gsub(heritage,'^%[%[', '')
		res = res .. '[[Category:Pages using infobox lighthouse with non-NRHP heritage|' .. mw.uri.encode(heritage) .. ']]'
	end
	
	for k, v in pairs( frame:getParent().args ) do
		if k and k == 'module' then
			if v and v:match('<tr') then
				if v:match('National Register of Historic Places') or v:match('NRHP') 
					or v:match('U.S. Historic district') 
					or v:match('U.S. National Register of Historic Places') then
					res = res .. '[[Category:Pages using infobox lighthouse with NRHP embedded]]'
					hasNRHPbox = true
				else
					res = res .. '[[Category:Pages using infobox lighthouse with non-NRHP embedded]]'
				end
				if v:match('<div style="position') then
					local pushpin_map = frame:getParent().args.pushpin_map
					if pushpin_map and pushpin_map ~= '' then
						res = res .. '[[Category:Pages using infobox lighthouse with two location maps]]'
					end
				end
			end
		elseif type(k) == 'string' then
			if v and v:match('<tr') then
				res = res .. '[[Category:Pages using infobox lighthouse with NRHP embedded outside the module parameter]]'
			end
		end
	end
	if hasNRHPbox == false and isNRHP == true then
		res = res .. '[[Category:Pages using infobox lighthouse with NRHP heritage|‽]]'
	end
	if hasNRHPbox == true and isNRHP == false then
		res = res .. '[[Category:Pages using infobox lighthouse with NRHP heritage|¶]]'
	end
	return res
end
return p