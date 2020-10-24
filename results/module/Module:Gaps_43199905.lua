local p = {}

local getArgs

function p.main(frame)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end
	local args = getArgs(frame, {wrappers = 'Template:Gaps'})

	local ret = mw.html.create('span')
		:css({['white-space'] = 'nowrap',
				['font-size'] = args.size})

	if args.lhs then
		ret:wikitext(args.lhs .. ' = ')
	end

	local gap = string.lower(args.gap or '')
	
	local gapSize, gapUnit = string.match(gap,'([%d%.]+)%s*([ep][mnx])')
	
	local acceptedUnits = { em = 'em', en = 'en', px = 'px' }
	
	gapUnit = acceptedUnits[gapUnit]
	
	if gapSize and gapUnit then
		gap = gapSize..gapUnit
	else
		gap = '0.25em'
	end
	
	for k,v in ipairs(args) do
		if k == 1 then
			ret:wikitext(v)
		else
			ret:tag('span')
				:css('margin-left',gap)
				:wikitext(v)
		end
	end

	if args.e then
		ret
			:tag('span')
				:css({['margin-left'] = '0.27em',
						['margin-right']= '0.27em'})
				:wikitext('×')
			:done()
			:wikitext(args.base or '10')
			:tag('span')
				:css('display','none')
				:wikitext('^')
			:done()
			:tag('sup')
				-- the double parentheses here are not redundant.
				-- they keep the second return value from being passed
				:wikitext((mw.ustring.gsub(args.e,'-','−')))
			:done()
	end

	if args.u then
		ret:wikitext('&nbsp;' .. args.u)
	end

	return ret
end

return p