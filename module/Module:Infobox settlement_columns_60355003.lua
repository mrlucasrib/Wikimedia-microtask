local p = {}

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame, {frameOnly = true});
	local r = mw.html.create('div')
		:css('display','table')
		:css('width','100%')
		:css('background','none')
	local r2 = ''
		
	if args['c0'] then
		local subtable = mw.html.create('div')
			:css('display','table')
			:css('width','100%')
			:css('background','none')
		local hassubtable = false
		for k=1,5 do
			if args['c' .. k] then
				hassubtable = true
				subtable:tag('div')
					:css('display', 'table-row')
					:tag('div')
						:css('display', 'table-cell')
						:css('vertical-align','middle')
						:css('text-align','center')
						:wikitext(args['c' .. k])
			end
		end
		if hassubtable == true then
			local row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display', 'table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(tostring(subtable))
			row:tag('div')
				:css('display', 'table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c0'])
		else
			local row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display', 'table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c0'])
		end
		
	else -- no zero cell
		if args['c1'] and args['c2'] and args['c3'] and args['c4'] then
			local row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c1'])
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c2'])
			row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c3'])
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c4'])
		elseif (args['c1'] or args['c2']) and args['c3'] and args['c4'] then
			local row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c1'] or args['c2'])
			r2 = mw.html.create('div')
				:css('display','table')
				:css('width','100%')
				:css('background','none')
			row = r2:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c3'])
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c4'])
		elseif args['c1'] and args['c2'] and (args['c3'] or args['c4']) then
			local row = r:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c1'])
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c2'])
			r2 = mw.html.create('div')
				:css('display','table')
				:css('width','100%')
				:css('background','none')
			row = r2:tag('div'):css('display', 'table-row')
			row:tag('div')
				:css('display','table-cell')
				:css('vertical-align','middle')
				:css('text-align','center')
				:wikitext(args['c3'] or args['c4'])

		elseif args['c1'] or args['c2'] or args['c3'] or args['c4'] then
			local row = r:tag('div'):css('display','table-row')
			for k=1,5 do
				if args['c' .. k] then
					row:tag('div')
						:css('display','table-cell')
						:css('vertical-align','middle')
						:css('text-align','center')
						:wikitext(args['c' .. k])
				end
			end
		end
	end
	
	return tostring(r) .. tostring(r2)
end

return p