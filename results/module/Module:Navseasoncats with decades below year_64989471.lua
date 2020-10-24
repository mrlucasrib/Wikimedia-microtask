local p = {}
local nsc = require('Module:Navseasoncats')

function p.dby( frame )
	local currtitle = mw.title.getCurrentTitle()
	local testcases = (currtitle.subpageText == 'testcases')
	local avoidself =  (currtitle.text ~= 'Navseasoncats with decades below year' and          --avoid self
						currtitle.text ~= 'Navseasoncats with decades below year/doc' and      --avoid self
						currtitle.text ~= 'Navseasoncats with decades below year/sandbox' and  --avoid self
						(currtitle.nsText ~= 'Template' or testcases)) --avoid nested transclusion errors
	
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	local testcase = args[1]
	if testcase == nil and avoidself == false then return '' end
	
	local pagename = testcase or currtitle.baseText
	local findvar = nsc.find_var(pagename) --picks up years/decades/seasons/etc.
	if findvar[1] == 'error' then
		local errorout = 	a
		if avoidself then
			local errors = nsc.errorclass('Function find_var can\'t recognize the year for category "'..pagename..'".')
			errorout = nsc.failedcat(errors, 'P')
			if testcases then string.gsub(errorout, '(%[%[)(Category)', '%1:%2') end
		end
		return errorout
	end
	
	local year = tonumber(string.match(findvar[2], '^(%d+)'))
	if year == nil or findvar[1] ~= 'year' then
		local errorout = ''
		if avoidself then
			local errors = nsc.errorclass('{{Navseasoncats with decades below year}} can\'t recognize the year for category "'..pagename..'".')
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
	
	local decade = math.floor(year/10)
	
	local decadecat
	if (firstpart == '') then
		decadecat = mw.text.trim( firstpart..' '..decade..'0s '..lastpart )
	else
		decadecat = mw.text.trim( firstpart..' the '..decade..'0s '..lastpart )
	end
	
	local exists = mw.title.new( decadecat, 'Category' ).exists
		
	if exists then
		local args = { ['decade-below-year'] = decadecat }
		local nav2 = frame:expandTemplate{ title = 'Navseasoncats', args = args } --not sure how else to pass frame & args together
		return '<div style="display:block !important; max-width: calc(100% - 25em);">' .."\n" .. nav1..nav2 .."\n" .. '</div>'
	else
		return nav1 -- .. '<br /> <br /> [[:Category:' .. decadecat .. ']] does not exist'
	end
end

return p