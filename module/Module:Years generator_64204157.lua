local p = {} --p stands for package

function p.templateEveryYearToPresent ( frame )
	-- use the parent args if available, assuming this is embedded in a template
	parentArgs = frame:getParent().args
	argsToUse = ((parentArgs[1] and parentArgs) or frame.args)
	
	years = yearsFromYearToPresent( argsToUse[1] )
	toReturn = ""
	
	templateArgs = {}
	templateDoNotConsume = {}
	
	-- allow transcluding templates to specify arguments they consume,
	-- so we should ignore them
	for arg in mw.text.gsplit( frame.args['templatedonotconsume'] or '', ',', true )
	do
		templateDoNotConsume[arg] = true
	end
	
	for key, arg in pairs( argsToUse ) do
		-- taking everything beyond the second arg, we pass it onto the template
		-- this includes named args, so we don't want to just do > 2
		if (
			key ~= 1
			and key ~= 2
			and not templateDoNotConsume[key]
			)
		then
			numericKey = tonumber( key )
			if ( numericKey )
			then
				-- templateArgs[1] will always be the year (lua arrays start at 1)
				-- templateArgs[2] should be the first other template param
				-- which is args[3], so we have here [key - 1]
				templateArgs[key - 1] = arg
			else
				-- named params we just shove in
				templateArgs[key] = arg
			end
		end
	end
	
	for index, year in ipairs( years ) do
		templateArgs[1] = tostring( year )
		toReturn = toReturn .. ( index == 0 and '' or '<br />' )
	    .. "<strong>" .. templateArgs[1] .. "</strong> &mdash; "
	    -- if parentArgs is used, then frame.args[1] will be the template,
	    -- as no other args are going to be in the immediate frame. if
	    -- there are no parentArgs, then it'll be the second param,
	    -- because the year will have been directly passed to the module
	    .. frame:expandTemplate{ title = ((parentArgs[1] and frame.args[1]) or frame.args[2]), args = templateArgs }
	end
	return toReturn
end

function yearsFromYearToPresent( year )
	startyear = tonumber( year )
	if ( startyear == nil )
	then
		error( "Invalid start year provided" )
	end
	
	years = {}
    numyears = ( tonumber( os.date( "%Y" ) ) - startyear )
    for numadded = 0, numyears do -- equiv of i = 0; i <= numyears; i++
    	years[numadded + 1] = startyear + numadded
    end
	return years
end

return p