require('Module:No globals')

local getArgs = require('Module:Arguments').getArgs
local p = {}

local function award(builder, text)
	builder:tag('td')
		:attr('class', 'dt')
		:css('font-weight', 'bold')
		:css('vertical-align', 'middle')
		:css('text-align', 'center')
		:wikitext(text)
end

local function won(builder, text)
	builder:tag('td')
		:css('vertical-align', 'middle')
		:css('text-align', 'center')
		:css('background-color', '#9F9')
		:wikitext(text)
end			

local function nom(builder, text)
	builder:tag('td')
		:css('vertical-align', 'middle')
		:css('text-align', 'center')
		:css('background-color', '#FDD')
		:wikitext(text)
end	

local function row(builder, args, i)
	builder = builder:tag('tr')
		:css('background-color', '#DDF')
	award(builder, args['award' .. i])
	won(builder, args['award' .. i ..'W'] or 0)
	nom(builder, args['award' .. i ..'N'] or 0)
end

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	-- Main module code goes here.
	local ret, temp
	local totalW, totalN = 0, 0
	
-- Award list begin
	for i = 1, 99 do
		if args['award' ..i] then
			temp = ''
			break
		end
	end
	
	if temp then
		temp = mw.html.create('table')
			:attr('class', 'collapsible collapsed')
			:css('width', '100%')
			
		temp:tag('tr'):tag('th')
			:attr('colspan', '3')
			:css('background-color', '#D9E8FF')
			:css('text-align', 'center')
			:wikitext('Accolades')
			
		temp:tag('tr')
			:css('background-color', '#D9E8FF')
				:tag('th')
				:wikitext('Award')
				:css('text-align', 'center')
				:done()
			:tag('th')
				:css('background-color', '#cec')
				:css('text-size', '0.9em')
				:css('width', '5.8em')	
				:css('text-align', 'center')
				:wikitext('Won')
				:done()
			:tag('th')
				:css('background-color', '#fcd')
				:css('text-size', '0.9em')
				:css('width', '5.8em')
				:css('text-align', 'center')
				:wikitext('Nominated')
				:done()
				
		for i = 1, 99 do
			if args['award' .. i] then
				row(temp, args, i)
				totalW = totalW + (args['award' .. i ..'W'] or 0)
				totalN = totalN + (args['award' .. i ..'N'] or 0)
			end
		end
	end

-- Award list end

	ret = mw.html.create('table')
		:attr('class', 'infobox')
		:css('width', '26em')
		:css('font-size', '90%')
		:css('vertical-align', 'align')
		
	ret:tag('caption')
		:css('font-size', '9pt')
		:css('font-weight', 'bold')
		:wikitext('List of accolades' .. (args.name and (' received by <i>' .. args.name .. '</i>') or ''))

	if args.image then
		ret:tag('tr'):tag('td')
			:attr('colspan', '3')
			:css('text-align', 'center')
			:wikitext(string.format('%s%s',
				require('Module:InfoboxImage').InfoboxImage{args = {
					image = args.image,
					sizedefault = 'frameless',
					size = args['image_size'],
					alt = args.alt,
				}},
				args.caption and ('<div style="display: block;"></div>' .. args.caption) or ''
			))
	end

	if temp then
		ret:tag('tr'):tag('td')
			:attr('colspan', '3')
			:wikitext(tostring(temp))

	end
		
	if args.totals ~= 'no' then
		local totalW = args.awards or totalW
		local totalN = args.nominations or totalN
		
		ret:tag('tr')
			:css('background-color', '#d9e8ff')
			:css('border-spacing', '4px 2px 2px')
			:css('font-weight', 'bold')
			:attr('class', 'dt')
			:tag('td')
				:attr('colspan', '3')
				:css('text-align', 'center')
				:wikitext('Total number of awards and nominations')
			
		ret:tag('tr')
			:css('font-weight', 'bold')
			:tag('td')
				:css('vertical-align', 'middle')
				:css('text-align', 'center')
				:css('background-color', '#9F9')
				:wikitext('Total')
				:done()
			:tag('td')
				:css('vertical-align', 'middle')
				:css('text-align', 'center')
				:css('background-color', '#9F9')
				:css('width', '5.9em')
				:wikitext(totalW)
				:done()
			:tag('td')
				:css('vertical-align', 'middle')
				:css('text-align', 'center')
				:css('background-color', '#FDD')
				:css('width', '5.9em')
				:wikitext(totalN)
				:done()
	end
	
	if args.reflink ~= 'no' then
		ret:tag('tr')
			:css('font-size', 'smaller')
			:css('background-color', '#d9e8ff')
			:tag('td')
				:attr('colspan', '3')
				:css('vertical-align', 'middle')
				:css('text-align', 'center')
				:wikitext('[[#References|Footnotes]]')
	end
	
	return ret
	
end

return p