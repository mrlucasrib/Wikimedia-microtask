local p = {}
local nsc = require('Module:Navseasoncats')

function p.cbd( frame )
	local currtitle = mw.title.getCurrentTitle()
	local testcases = (currtitle.subpageText == 'testcases')
	local avoidself =  (currtitle.text ~= 'Navseasoncats with centuries below decade' and          --avoid self
						currtitle.text ~= 'Navseasoncats with centuries below decade/doc' and      --avoid self
						currtitle.text ~= 'Navseasoncats with centuries below decade/sandbox' and  --avoid self
						(currtitle.nsText ~= 'Template' or testcases)) --avoid nested transclusion errors
	
	local testcase = frame:getParent().args[1]
	if testcase == nil and avoidself == false then return '' end
	
	local pagename = testcase or currtitle.baseText
	local findvar = nsc.find_var(pagename) --picks up decades/seasons/etc.
	if findvar[1] == 'error' then
		local errorout = ''
		if avoidself then
			local errors = nsc.errorclass('Function find_var can\'t recognize the decade for category "'..pagename..'".')
			errorout = nsc.failedcat(errors, 'P')
			if testcases then string.gsub(errorout, '(%[%[)(Category)', '%1:%2') end
		end
		return errorout
	end
	
	local decade = tonumber(string.match(findvar[2], '^(%d+)s'))
	if decade == nil or findvar[1] ~= 'decade' then
		local errorout = ''
		if avoidself then
			local errors = nsc.errorclass('{{Navseasoncats with centuries below decade}} can\'t recognize the decade for category "'..pagename..'".')
			errorout = nsc.failedcat(errors, 'P')
			if testcases then string.gsub(errorout, '(%[%[)(Category)', '%1:%2') end
		end
		return errorout
	end
	
	local firstpart, lastpart = string.match(pagename, '^(.*)'..findvar[2]..'(.*)$')
	firstpart = mw.text.trim(firstpart or '')
	lastpart  = mw.text.trim(lastpart or '')
	
	local nav1 = ''
	if testcase then
		local args = { testcase = testcase }
		nav1 = frame:expandTemplate{ title = 'Navseasoncats', args = args } --not sure how else to pass frame & args together
	else
		nav1 = nsc.navseasoncats(frame)
	end
	
	local century = math.floor( ((decade-1)/100) + 1 ) --from {{CENTURY}}
	if string.match(decade, '00$') then century = century + 1 end --'2000' is technically in the 20th, but the rest of the 2000s is in the 21st
	
	local centurycat = mw.text.trim( firstpart..' '..nsc.addord(century)..' century '..lastpart )
	local exists = mw.title.new( centurycat, 'Category' ).exists
	
	if not exists then --check for hyphenated century
		centurycat = mw.text.trim( firstpart..' '..nsc.addord(century)..'-century '..lastpart )
		exists = mw.title.new( centurycat, 'Category' ).exists
	end
	
	if exists then
		local args = { ['century-below-decade'] = centurycat }
		local nav2 = frame:expandTemplate{ title = 'Navseasoncats', args = args } --not sure how else to pass frame & args together
		return '<div style="display:block !important; max-width: calc(100% - 25em);">' .."\n" .. nav1..nav2 .."\n" .. '</div>'
	else
		return nav1
	end
end

return p