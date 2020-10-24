local p = {}
 
function p.tracking(frame)
    function isblank( val ) 
        return (val == nil) or val:match('^[%s]*$')
    end
	local function isnotblank(s)
		return s and s:match( '^%s*(.-)%s*$' ) ~= ''
	end
 
    local cats = ''
    local args = frame:getParent().args
    
    local hasbr = 0
    local hasli = 0
    local hasul = 0
    local hasnewline = 0
    local toohighnumber = 0
    local missingyears = {0, 0, 0}
    local missingteams = {0, 0, 0}
    local hasyears = {0, 0, 0}
    local hasteams = {0, 0, 0}
    
    local prefixes = {'pro', 'amateur', 'manage'}
    local maxindices = {25, 15, 25}
    for k=1,3 do
		local prefix = prefixes[k]
		local maxindex = maxindices[k]
		if (isnotblank(args[prefix .. 'years']) ) then hasyears[k] = 1 end
		if (isnotblank(args[prefix .. 'years']) and isblank(args[prefix .. 'teams']) ) then
			missingteams[k] = 1
		end
		if (isnotblank(args[prefix .. 'teams']) ) then hasteams[k] = 1 end
		if (isnotblank(args[prefix .. 'teams']) and isblank(args[prefix .. 'years']) ) then
			missingyears[k] = 1
		end
		if (args[prefix .. 'years'] or ''):match('<[\t ]*[Bb]') then
			hasbr = 1
		end
		if (args[prefix .. 'years'] or ''):match('<[\t ]*[Ll][Ii]') then
			hasli = 1
		end
		if (args[prefix .. 'years'] or ''):match('<[\t ]*[Uu][Ll]') then
			hasul = 1
		end
		if (args[prefix .. 'teams'] or ''):match('<[\t ]*[Bb]') then
			hasbr = 1
		end
		if (args[prefix .. 'teams'] or ''):match('<[\t ]*[Ll][Ii]') then
			hasli = 1
		end
		if (args[prefix .. 'teams'] or ''):match('<[\t ]*[Uu][Ll]') then
			hasul = 1
		end
		if (args[prefix .. 'years'] or ''):match('[\r\n]') then
			hasnewline = 1
		end
		if (args[prefix .. 'teams'] or ''):match('[\r\n]') then
			hasnewline = 1
		end
		for i = 1,maxindex do
			if (isnotblank(args[prefix .. 'years'.. tostring(i)]) ) then hasyears[k] = 1 end
			if (isnotblank(args[prefix .. 'years'.. tostring(i)]) and isblank(args[prefix .. 'team'.. tostring(i)]) ) then
				missingteams[k] = 1
			end
			if (isnotblank(args[prefix .. 'team'.. tostring(i)]) ) then hasteams[k] = 1 end
			if (isnotblank(args[prefix .. 'team'.. tostring(i)]) and isblank(args[prefix .. 'years'.. tostring(i)]) ) then
				missingyears[k] = 1
			end
			if(args[prefix .. 'years' .. tostring(i)] or ''):match('<[\t ]*[Bb]') then
				hasbr = 1
			end
			if(args[prefix .. 'years' .. tostring(i)] or ''):match('<[\t ]*[Ll][Ii]') then
				hasli = 1
			end
			if(args[prefix .. 'years' .. tostring(i)] or ''):match('<[\t ]*[Uu][Ll]') then
				hasul = 1
			end
			if(args[prefix .. 'team' .. tostring(i)] or ''):match('<[\t ]*[Bb]') then
				hasbr = 1
			end
			if(args[prefix .. 'team' .. tostring(i)] or ''):match('<[\t ]*[Ll][Ii]') then
				hasli = 1
			end
			if(args[prefix .. 'team' .. tostring(i)] or ''):match('<[\t ]*[Uu][Ll]') then
				hasul = 1
			end
			if(args[prefix .. 'years' .. tostring(i)] or ''):match('[\r\n]') then
				hasnewline = 1
			end
			if(args[prefix .. 'team' .. tostring(i)] or ''):match('[\r\n]') then
				hasnewline = 1
			end
		end
		if (isnotblank(args[prefix .. 'team'.. tostring(maxindex+1)]) or isnotblank(args[prefix .. 'years'.. tostring(maxindex+1)]) ) then
			toohighnumber = 1
		end
	end
	if (isnotblank(args['weight'])) then
		local w = frame:expandTemplate{ title = 'Infobox person/weight', args = {args['weight'] .. ' '} }
		w = mw.ustring.gsub(w, '[≈~]', ' ')
		w = mw.ustring.gsub(w, '<abbr[^<>]*>c.</abbr> ', '')
		w = mw.ustring.gsub(w, '–[%d][%d]*%.[%d]', '')
		w = mw.ustring.gsub(w, '–[%d][%d]*', '')
		w = mw.ustring.gsub(w, '[%d][%d]%.[%d]&nbsp;kg %([%d][%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]%.[%d]&nbsp;kg %([%d][%d]*&nbsp;lb; [%d][%.%d]*&nbsp;st%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]%.[%d]&nbsp;kg %([%d][%d]*&nbsp;lb; [%d][%d]*&nbsp;st [%d][%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]%.[%d]&nbsp;kg %([%d][%.%d]*&nbsp;st; [%d][%.%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;kg %([%d][%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;kg %([%d][%d]*&nbsp;lb; [%d][%.%d]*&nbsp;st%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;kg %([%d][%d]*&nbsp;lb; [%d][%d]*&nbsp;st [%d][%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;kg %([%d][%d]*&nbsp;st; [%d][%.%d]*&nbsp;lb%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;st [%d][%d]*&nbsp;lb %([%d][%d]*&nbsp;kg%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;lb %([%d][%d]*&nbsp;kg%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*&nbsp;lb %([%d][%d]*&nbsp;kg; [%d][%.%d]*&nbsp;st%)', '')
		w = mw.ustring.gsub(w, '[%d][%d]*[ ]*kg ', '')
		w = mw.ustring.gsub(w, '[%d][%d]*[ ]*lb ', '')
		w = mw.ustring.gsub(w, '%([1-2][%d][%d][%d]%)', '')
		w = mw.ustring.gsub(w, '%([1-2][%d][%d][%d]%-[%d][%d]%)', '')
		w = mw.text.unstrip(w)
		w = mw.ustring.gsub(w, '[<]', '.LT.')
		w = mw.ustring.gsub(w, '[>]', '.GT.')
		w = mw.ustring.gsub(w, '&', '&amp;')
		if(isnotblank(w)) then
			cats = cats .. '[[Category:Pages using infobox cyclist with atypical values for height or weight|W]]'
			-- cats = cats .. '<span class=error>Atypical value: weight = ' .. w  .. '</span>'
		end
	end
	if (isnotblank(args['height'])) then
		local h = frame:expandTemplate{ title = 'Infobox person/height', args = {args['height'] .. ' '} }
		h = mw.ustring.gsub(h, '[≈~]', ' ')
		h = mw.ustring.gsub(h, '<abbr[^<>]*>c.</abbr> ', '')
		h = mw.ustring.gsub(h, '<span class="frac nowrap">([%d][%d]*)<span class="visualhide">&nbsp;<%/span><sup>1<%/sup>&frasl;<sub>2<%/sub><%/span>', '%1')
		h = mw.ustring.gsub(h, '<span class="frac nowrap"><sup>1<%/sup>&frasl;<sub>2<%/sub><%/span>', '0')
		h = mw.ustring.gsub(h, '[1-2]%.[%d][%d]?&nbsp;m %([4-7]&nbsp;ft [%d][%d]*&nbsp;in%)', '')
		h = mw.ustring.gsub(h, '[1-2][%d][%d]&nbsp;cm %([4-7]&nbsp;ft [%d][%d]*&nbsp;in%)', '')
		h = mw.ustring.gsub(h, '[4-7]&nbsp;ft [%d][%d]*&nbsp;in %([1-2]%.[%d][%d]&nbsp;m%)', '')
		h = mw.ustring.gsub(h, '[4-7]&nbsp;ft [%d][%d]*&nbsp;in %([1-2][%d][%d]&nbsp;cm%)', '')
		h = mw.ustring.gsub(h, '[1-2]%.[%d][%d][ ]*m ', '')
		h = mw.ustring.gsub(h, '[1-2][%d][%d][ ]*cm ', '')
		h = mw.ustring.gsub(h, '[4-7] ft [%d][%d]* in ', '')
		h = mw.ustring.gsub(h, '%([1-2][%d][%d][%d]%)', '')
		h = mw.ustring.gsub(h, '%([1-2][%d][%d][%d]-[%d][%d]%)', '')
		h = mw.text.unstrip(h)
		h = mw.ustring.gsub(h, '[<]', '.LT.')
		h = mw.ustring.gsub(h, '[>]', '.GT.')
		h = mw.ustring.gsub(h, '&', '&amp;')
		if(isnotblank(h)) then
			cats = cats .. '[[Category:Pages using infobox cyclist with atypical values for height or weight|H]]'
			-- cats = cats .. '<span class=error>Atypical value: height = ' .. h  .. '</span>'
		end
	end
	if (hasli > 0) then
        cats = cats .. '[[Category:Pages using infobox cyclist with multiple entries in single field|λ]]'
    end
    if (hasul > 0) then
        cats = cats .. '[[Category:Pages using infobox cyclist with multiple entries in single field|μ]]'
    end
    if (hasbr > 0) then
        cats = cats .. '[[Category:Pages using infobox cyclist with multiple entries in single field|β]]'
    end
    if (hasnewline > 0) then
        cats = cats .. '[[Category:Pages using infobox cyclist with multiple entries in single field|ν]]'
    end
	for k=1,3 do
		if (missingyears[k] > 0 and hasyears[k] > 0) then
			cats = cats .. '[[Category:Pages using infobox cyclist with unknown parameters|Υ]]'
		end
		if (missingteams[k] > 0 and hasteams[k] > 0) then
			cats = cats .. '[[Category:Pages using infobox cyclist with unknown parameters|Τ]]'
		end
	end
 
    return cats
end
 
return p