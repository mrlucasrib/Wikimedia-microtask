local p = {}

bold, ital, subst = "", false, false

function p.tlxs(frame)
	subst=true
	return p.tlx(frame)
end

function p.tlxb(frame)
	bold="'''"
	return p.tlx(frame)
end

function p.tlxi(frame)
	ital = true
	return p.tlx(frame)
end

function p.tlx(frame)
	local outStr = frame:extensionTag{name='nowiki',content='{{'}
	local args = frame:getParent().args
	
	if (subst or args['subst'] or '') ~= '' then outStr = outStr..'[[Help:Substitution|subst]]:' end
	
	local tempTitle = (args[1] or ' ')
	
	if mw.title.new(tempTitle) ~= nil then
		if (mw.title.new(tempTitle).nsText or '') == '' and (mw.title.new(tempTitle).interwiki or '') == '' then 
			tempLink=frame:callParserFunction{name='ns',args='Template'}..':'..tempTitle
		else
			tempLink = tempTitle
		end 
	else
		tempLink = tempTitle
	end

	outStr = outStr..'[[:'..(args['LANG'] or frame.args['LANG'] or '')..(args['SISTER'] or frame.args['SISTER'] or '')..tempLink..'|'..bold..tempTitle..bold..']]'
	
	local k, v
	
	for k, v in pairs(args) do
		if type(k) == 'number' and k ~= 1 then 
			if ital then outStr = outStr..'|'..frame:extensionTag{name='var',content=v} else outStr = outStr..'|'..v end
		elseif k ~= 1 and k ~= 'subst' and k ~= 'LANG' and k ~= 'SISTER' then
			if ital then outStr = outStr..'|'..frame:extensionTag{name='var',content=k..'='..v} else outStr = outStr..'|'..k..'='..v end
		end
	end
			
	outStr = outStr..frame:extensionTag{name='nowiki',content='}}'}
	
	return frame:extensionTag{name='code',content=outStr}
end

return p