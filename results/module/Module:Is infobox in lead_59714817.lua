local p = {}

function p.main (frame)
	return p._main (frame.args[1])
end

function p._main (searchString)
	local content = mw.title.getCurrentTitle():getContent()
	local offset = string.find(content, "==", 1 , true)
	if offset then
		local lead = string.sub(content, 1, offset-1)
		if (string.find(lead, searchString)) then
			lead = lead
				:gsub( "{{%s-[Ii]nfobox%s-mapframe", "") --don't check for infobox mapframe
				:gsub( "{{%s-[Ii]nfobo[^}]-%|%s-embed%s-=%s-yes", "") --don't check for embeded infoboxes
				:gsub( "{{%s-[Ii]nfobo[^}]-%|%s-child%s-=%s-yes", "") --don't check for child infoboxes
			local iter = string.gmatch(lead, "{{%s-[Ii]nfobox")
			iter()
			if not iter() then --if able to find two infoboxes in the lead, then don't return true
				local iter2 = string.gmatch(content, searchString)
				iter2()
				if not iter2() then --if able to find two of the specific infobox in the article, then don't return true
					return true
				end
			end
		end
	end
end

return p