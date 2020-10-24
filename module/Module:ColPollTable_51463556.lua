local p = {}

local getArgs

local CC_backgrounds = {
	r = { ['background-color'] = '#FFE6E6' },
	d = { ['background-color'] = '#FFE6E6' },
	g = { ['background-color'] = '#D8FFEB' },
	u = { ['background-color'] = '#D8FFEB' },
	y = { ['background-color'] = '#FFFFE6' },
	npr = { ['background-color'] = '#FFFFE6' },
	tg = { ['background-color'] = '#D8FFEB', ['border-bottom'] = '1px solid #D8FFEB;' },
	tu = { ['background-color'] = '#D8FFEB', ['border-bottom'] = '1px solid #D8FFEB;' },
	tr = { ['background-color'] = '#FFE6E6', ['border-bottom'] = '1px solid #FFE6E6;' },
	td = { ['background-color'] = '#FFE6E6', ['border-bottom'] = '1px solid #FFE6E6;' },
	ty = { ['background-color'] = '#FFFFE6', ['border-bottom'] = '1px solid #FFFFE6;' },
	tnpr = { ['background-color'] = '#FFFFE6', ['border-bottom'] = '1px solid #FFFFE6;' },
	tw = { ['background-color'] = 'white', ['border-bottom'] = '1px solid white;' },
	t = { ['background-color'] = 'white', ['border-bottom'] = '1px solid white;' },
	b = { ['background-color'] = '#99CCFF' },
	nc = { ['background-color'] = '#99CCFF' },
	w = { ['background-color'] = 'white' },
	default = { ['background-color'] = 'white' } 
}
function p.doc(frame)
	local desc = {
		{'r', 'red'},
		{'d', 'down'},
		{'g', 'green'},
		{'u', 'up'},
		{'y', 'yellow'},
		{'npr', 'not previously ranked'},
		{'tg', 'tie green'},
		{'tu', 'tie up'},
		{'tr', 'tie red'},
		{'td', 'tie down'},
		{'ty', 'tie yellow'},
		{'tnpr', 'tie not previously ranked'},
		{'tw', 'tie white'},
		{'-', 'default'}
	}
	local ret = mw.html.create('table'):addClass('wikitable')
	ret:tag('tr')
		:tag('th'):wikitext('Code'):done()
		:tag('th'):wikitext('Abbreviation for'):done()
		:tag('th'):wikitext('Result'):done()
	for i=1,#desc do
		local d = desc[i]
		local c = string.lower(d[1])
		local s = CC_backgrounds[c] or CC_backgrounds.default
		ret:tag('tr')
			:tag('td'):wikitext(c):done()
			:tag('td'):wikitext(d[2]):done()
			:tag('td'):css(s):done()
	end
	return ret
end

function p.main(frame)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end

	local args = getArgs(frame, {wrappers = 'Template:ColPollTable'})
	
	-- get highest number looked at
	-- Template doc says "Week#" is a required field, so we'll use that as an indicator
	local max_week = 0
	for i=1,50 do
		if not args['Week'..i] then
			break
		end
		max_week = i
	end
	
	local max_sub_week = 0
	-- get the highest subweek to look at
	-- Week1-Y should suffice, assuming all parameters require definition
	for i=1,50 do
		if not args['Week1-'..i] then
			break
		end
		max_sub_week = i
	end
	
	local tbl_args = {
		max = max_week,
		max_sub = max_sub_week,
		weeks = {}
		}

	-- looks for parameter "name", otherwise returns "{{{name}}}"
	local function argOrCall(name)
		return mw.text.trim(args[name] or '') or string.format('{{{%s}}}',name)
	end
		
	for i=1,max_week do
		local week_tbl = {}
		week_tbl.name = 'Week ' .. argOrCall('Week'..i)
		week_tbl.date = argOrCall('Week'..i..'Date')
		week_tbl.cells = {}

		for j=1,max_sub_week do
			local wkdt = string.format('Week%s-%s',i,j)
			local wkcolor = string.format('Week%s-%s-Color',i,j)
			wkdt = argOrCall(wkdt)
			wkcolor = string.lower(argOrCall(wkcolor))
			
			wkcolor = CC_backgrounds[wkcolor] or CC_backgrounds.default

			table.insert(week_tbl.cells, { res = wkdt, style = wkcolor })
		end
		local dropped = args['Week'..i..'Dropped']
		if not dropped or not string.find(dropped or '','%S') then
			dropped = nil
		end
		week_tbl.dropped = dropped
		table.insert(tbl_args.weeks,week_tbl)
	end

	-- week 1 is 0 --> "Preseason"
	if tbl_args.weeks[1] and tbl_args.weeks[1].name == 'Week 0' then
		tbl_args.weeks[1].name = 'Preseason'
	end
	
	-- last week is f or final --> "Final"
	if tbl_args.weeks[max_week] then
		local week_f_name = tbl_args.weeks[max_week].name
		week_f_name = string.lower(week_f_name)
		
		if week_f_name == 'week f' or week_f_name == 'week final' then
			tbl_args.weeks[max_week].name = 'Final'
		end
	end

	return p._main(tbl_args)
end

function p._main(args)
	local ret = mw.html.create('div'):css('overflow', 'auto')
	-- return table
	local root = ret:tag('table')
					:addClass('wikitable')
					:css({ ['font-size'] = '90%',
							['white-space'] = 'nowrap',
							['background-color'] = 'white' })
	
	-- header
	local header_row = root:tag('tr'):tag('th'):done()
	
	for _, v in ipairs(args.weeks) do
		header_row:tag('th'):wikitext(v.name)
			:tag('br', { selfClosing = true }):done()
			:wikitext(v.date):done()
	end
	
	header_row:tag('th'):done():done()
	
	for i=1,args.max_sub do
		local cur_row = root:tag('tr')
		cur_row:tag('th'):wikitext(i..'.'):done()
		for _, v in ipairs(args.weeks) do
			local cur_cell = v.cells[i]
			cur_row:tag('td'):css(cur_cell.style):wikitext(cur_cell.res):done()
		end
		cur_row:tag('th'):wikitext(i..'.'):done()
		cur_row:done()
	end
	
	-- footer
	local footer_row = root:tag('tr'):tag('th'):done()
	
	for _, v in ipairs(args.weeks) do
		footer_row:tag('th'):wikitext(v.name)
			:tag('br', { selfClosing = true }):done()
			:wikitext(v.date):done()
	end
	
	footer_row:tag('th'):done():done()
	
	-- drop outs
	local dropped_row = root:tag('tr')
	dropped_row:tag('td'):attr('colspan','2'):css({ background = 'transparent', ['border-bottom-style'] = 'hidden', ['border-left-style'] = 'hidden' }):done()
	
	for i, v in ipairs(args.weeks) do
		if v.dropped and i > 1 then
			dropped_row:tag('td'):css({ ['vertical-align'] = 'top', ['background-color'] = '#FFE6E6' })
				:tag('b'):wikitext('Dropped:'):done()
				:tag('br', { selfClosing = true }):done()
				:wikitext(v.dropped)
			:done()
		elseif i > 1 then
			dropped_row:tag('td'):css({ ['vertical-align'] = 'top', ['background-color'] = '#FFFFFF' })
				:tag('i'):wikitext('None'):done()
				:done()
		end
	end
	dropped_row:tag('td'):css({ background = 'transparent', ['border-bottom-style'] = 'hidden', ['border-right-style'] = 'hidden' }):done()

	return ret
end
return p