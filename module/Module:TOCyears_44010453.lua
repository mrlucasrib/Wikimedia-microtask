-- This module implements [[Template:TOCyears]]

local yesno = require('Module:Yesno')
local p = {}

function p._years(args)
	local i = tonumber(args.startyear) or 1900
	local endYear = tonumber(args.endyear) or tonumber(os.date('%Y'))
	local range = tonumber(args.range)
	local step = tonumber(args.step) or 1
	local links = {}
	while i <= endYear do
		local year = tostring(i)
		if range then
			year = year .. '-' .. tostring(i + range)
		end
		links[#links + 1] = string.format('[[#%s|%s]]', year, year)
		i = i + step
	end
	if #links == 0 then
		return ""
	end
	links = '* ' .. table.concat(links, ' ')
	
	-- Root
	local root = mw.html.create()
	local isPrimary = yesno(args.primary) ~= false
	if isPrimary then
		root:wikitext('__NOTOC__')
	end

	-- Top div tag
	local top = root:tag('div')
	top:addClass('toc plainlinks hlist')
	if isPrimary then
		top
			:attr('id', 'toc')
			:attr('class', 'toc')
	end
	local align = args.align and args.align:lower()
	if align == 'left' then
		top
			:css('float', 'left')
			:css('clear', args.clear or 'left')
	elseif align == 'right' then
		top
			:css('float', 'right')
			:css('clear', args.clear or 'right')
	elseif align == 'center' then
		top
			:css('margin', 'auto')
			:css('clear', args.clear or 'none')
	else
		top
			:css('clear', args.clear or 'left')
	end
	top:newline()

	-- Title div tag
	local title = args.title or mw.message.new('Toc'):plain()
	local titleDiv = top:tag('div')
	titleDiv:attr('id', 'toctitle')
	titleDiv:attr('class', 'toctitle')
	if isPrimary then
		titleDiv:wikitext('<h2>' .. title .. '</h2>')
	else
		titleDiv:tag('strong'):wikitext(title)
	end
	
	-- Content
	top
		:newline()
		:wikitext(links)
		:newline()
	
	return tostring(root)
end

function p.years(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = {
			'Template:TOCyears',
		}
	})
	return p._years(args)
end

return p