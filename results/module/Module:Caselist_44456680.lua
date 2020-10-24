-- This module implements {{caselist}}.

local mNavbox = require('Module:Navbox')

local p = {}

local function wraplinks(s)
	-- add allow wrap
	if s and not mw.ustring.match(s, '<span class="wrap">') then
		-- probably a more efficient way to match 40 or more characters
		local m = '[^%[%]<>|][^%[%]<>|][^%[%]<>|][^%[%]<>|][^%[%]<>|]'
		m = m .. m .. m .. m
		m = m .. m
		s = mw.ustring.gsub(s, 
			'%[%[(' .. m .. '[^%[%]<>|]*)%]%]', 
			'[[%1|<span class="wrap">%1</span>]]')
		s = mw.ustring.gsub(s, 
			'%[%[([^%[%]<>|]*)|(' .. m .. '[^%[%]<>|]*)%]%]', 
			'[[%1|<span class="wrap">%2</span>]]')
	end
	
	return s
end

function p._main(args)
	local nargs = {} -- Navbox args

	-- Cases
	do
		local caseNums = {}
		for k in pairs(args) do
			if type(k) == 'string' then
				local num = k:match('^case([1-9][0-9]*)$')
				if num then
					table.insert(caseNums, tonumber(num))
				end
			end
		end
		if #caseNums < 1 then
			error("no 'case1', 'case2', etc. parameters specified in [[Template:Caselist]]", 2)
		end
		table.sort(caseNums)
		for i, num in ipairs(caseNums) do
			nargs['list' .. tostring(i)] = wraplinks(args['case' .. tostring(num)])
		end
	end

	-- Other args
	nargs.name = args.name or 'Caselist'
	nargs.navbar = args.navbar or 'top'
	nargs.style = string.format(
		'width: %s; text-align: %s; font-size: 80%%; line-height: 1.5em; background-color: #fafafa; %s',
		args.width or '350px',
		args.textalign or 'center',
		args.align == 'left'
			and 'float: left; clear: left; margin: 0 1em 1em 0;'
			or 'float: right; clear: right; margin: 0 0 1em 1em;'
	)
	nargs.evenodd = 'off'
	nargs.title = args.title or args.name or error(
		"no 'title' or 'name' parameters specified in [[Template:Caselist]]",
		2
	)
	nargs.below = args.notes or args.below
	nargs.tracking = 'no'

	return mNavbox._navbox(nargs)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Caselist'
	})
	return p._main(args)
end

return p