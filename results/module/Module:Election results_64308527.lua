require('Module:No globals')
local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame)
	local index, headings, showtotal = {}, {}, {}
	local cols, rounds = 0, 1
	local winner, winner_votes = {0, 0}, {0, 0}
	local valid = {0, 0}
	local invalid = {tonumber(args.invalid) or 0, tonumber(args.invalid2) or 0}
	local totalvotes = {tonumber(args.totalvotes) or 0, tonumber(args.totalvotes2) or tonumber(args.totalvotes) or 0}
	local electorate = {tonumber(args.electorate) or 0, tonumber(args.electorate2) or tonumber(args.electorate) or 0}
	local turnout = {tonumber(args.turnout) or 0, tonumber(args.turnout2) or 0}
	local seats = 0, 0
	local row, secondrow
	local tracking = ''
	local max_rows = 0
	
	-- helper functions
	local lang = mw.getContentLanguage()
	local function fmt(n)
		return n and tonumber(n) and lang:formatNum(tonumber(n)) or nil
	end
	local function pct(n,d)
		n, d = tonumber(n), tonumber(d)
		if n and d and d > 0 then
			return string.format('%.2f', n / d * 100)
		end
		return '&ndash;'
	end
	local function tonumdash(s)
		if s then
			s = mw.ustring.gsub(s, '&[MmNn][Dd][Aa][Ss][Hh];', '-')
			s = mw.ustring.gsub(s, '&[Mm][Ii][Nn][Uu][Ss];', '-')
			s = mw.ustring.gsub(s, '[—–−]', '-')
			return tonumber(s) or 0
		end
	end
	local function unlink(s)
		if s then
			s = s:match("^[^%[]-%[%[([^%]]-)|[^%]]-%]%].*$") or s
			s = s:match("^[^%[]-%[%[([^%]]-)%]%].*$") or s
		end
		return s
	end

	-- preprocess the input
	local stop_flag = false
	local i = 0
	while stop_flag == false do
		stop_flag = true
		for kk = 1, 20 do
			i = i + 1
			for k, key in ipairs({'cand', 'vp', 'party', 'sc', 'sw', 'seats', 'totalvotes'}) do
				if args[key .. i] then
					headings[key] = true
					stop_flag = false
					max_rows = i > max_rows and i or max_rows
				end
			end
			if args['row' .. i] then
				stop_flag = false
				max_rows = i > max_rows and i or max_rows
			end

			if args['row' .. i] or args['cand' .. i] or args['party' .. i] then
				table.insert(index, i)
				if args['votes' .. i] then
					if tonumber(args['votes' .. i]) then showtotal.votes = 1 end
					local votesi = tonumber(args['votes' .. i]) or 0
					args['votes' .. i] = votesi
					if votesi > winner_votes[1] then
						winner[1] = i
						winner_votes[1] = votesi
					end
					valid[1] = valid[1] + votesi
				end
				if args['votes' .. i .. '_2'] then
					rounds = 2
					if tonumber(args['votes' .. i .. '_2']) then showtotal.votes_2 = 1 end
					local votesi = tonumber(args['votes' .. i .. '_2']) or 0
					args['votes' .. i .. '_2'] = votesi
					if votesi > winner_votes[2] then
						winner[2] = i
						winner_votes[2] = votesi
					end
					valid[2] = valid[2] + votesi
				end
				if args['seats' .. i] then
					if tonumber(args['seats' .. i]) then showtotal.seats = 1 end
					seats = seats + (tonumber(args['seats' .. i]) or 0)
				end
			end
		end
	end

	local ovalid = {valid[1], valid[2]}
	seats = ((args['total_seats'] or '') == 'TOTAL' and seats) or args['total_seats'] or seats
	if seats or args['total_sc'] or args['valid'] or ((rounds > 1) and args['valid2']) then
		max_rows = max_rows + 1
		local i = max_rows
		table.insert(index,i)
		args['votes' .. i] = showtotal.votes and valid[1] or nil
		args['votes' .. i .. '_2'] = showtotal.votes_2 and valid[2] or nil
		args['colour' .. i] = 'inherit'
		args['color' .. i] = 'inherit'
		args['row' .. i] = 'Total'
		args['sw' .. i] = '–'
		args['seats' .. i] = showtotal.seats and seats or nil
		args['sc' .. i] = args['total_sc']
		args['font-weight' .. i] = 'bold'
		args['class' .. i] = 'sortbottom'
		ovalid[1] = tonumber(args['valid']) or valid[1]
		ovalid[2] = tonumber(args['valid2']) or valid[2]
	end

	-- build the table
	local root = mw.html.create('table')
	root
		:addClass('wikitable sortable')
		:tag('caption')
			:wikitext(args.caption)
	
	local topcell = nil
	if args['image'] then
		topcell = root
			:tag('tr')
				:tag('td')
					:wikitext(args['image'])
					:css('text-align', 'center')
	end
		
	local rowspan = (rounds > 1) and 2 or nil
	row = root:tag('tr')
	if headings['cand'] then
		row
			:tag('th')
				:wikitext('Candidate')
				:attr('scope', 'col')
				:attr('colspan', 2)
				:attr('rowspan', rowspan)
		cols = cols + 2
		if headings['vp'] then
			row
				:tag('th')
						:wikitext('Running mate')
						:attr('scope', 'col')
						:attr('rowspan', rowspan)
			cols = cols + 1
		end
		if headings['party'] then
			row
				:tag('th')
				:wikitext('Party')
				:attr('scope', 'col')
				:attr('rowspan', rowspan)
			cols = cols + 1
		end
	else
		row
			:tag('th')
				:wikitext(headings['party'] and 'Party' or '')
				:attr('scope', 'col')
				:attr('colspan', 2)
				:attr('rowspan', rowspan)
		cols = cols + 2
	end
	if rounds > 1 then
		row
			:tag('th')
				:wikitext(args.firstround or 'First round')
				:attr('scope', 'col')
				:attr('colspan', 2)
			:tag('th')
				:wikitext(args.secondround or 'Second round')
				:attr('scope', 'col')
				:attr('colspan', 2)
		secondrow = root:tag('tr')
	else
		secondrow = row
	end
	for k=1,rounds do
		secondrow
			:tag('th')
				:wikitext('Votes')
				:attr('scope', 'col')
			:tag('th')
				:wikitext('%')
				:attr('scope', 'col')
		cols = cols + 2
	end
	if headings['sw'] then
		row
			:tag('th')
				:wikitext('+/–')
				:attr('scope', 'col')
				:attr('rowspan', rowspan)
		cols = cols + 1
	end
	if headings['seats'] then
		row
			:tag('th')
				:wikitext('Seats')
				:attr('scope', 'col')
				:attr('rowspan', rowspan)
		cols = cols + 1
	end
	if headings['sc'] then
		row
			:tag('th')
				:wikitext(headings['seats'] and '+/–' or 'Seats&pm;')
				:attr('scope', 'col')
				:attr('rowspan', rowspan)
		cols = cols + 1
	end

	if topcell then
		topcell:attr('colspan', cols)
	end
	
	local cs = cols - 2*rounds 
			- (headings['sw'] and 1 or 0)
			- (headings['seats'] and 1 or 0)
			- (headings['sc'] and 1 or 0)
	local rsuff = (rounds > 1) and {'', '_2'} or {''}
	for i, v in ipairs(index) do
		row = root:tag('tr')
			:addClass(args['class' .. v])
			:css('font-weight', args['font-weight' .. v])

		-- determine the color
		local color = args['colour' .. v] or args['color' .. v] or nil
		if color == nil then
			local party = unlink(args['party' .. v]) or ''
			if party ~= '' and mw.title.new('Template:' .. party .. '/meta/color').exists then
				color = frame:expandTemplate{title = party .. '/meta/color'}
			end
		end

		if args['row' .. v] then
			row
				:tag('td')
					:wikitext(args['row' .. v])
					:attr('colspan', cs)
		else
			-- create the empty color cell
			row
				:tag('td')
					:css('background-color', color)

			-- add the rest of the row
			if headings['cand'] then
				row
					:tag('td')
						:wikitext(args['cand' .. v])
				if headings['vp'] then
					row
						:tag('td')
							:wikitext(args['vp' .. v])
				end
			end
			if headings['party'] then
				row
					:tag('td')
						:wikitext(args['party' .. v])
			end
		end
		for kk, suf in ipairs(rsuff) do
			if(args['votes' .. v .. suf]) then
				row:tag('td')
					:css('text-align', 'right')
					:wikitext(fmt(args['votes' .. v .. suf]))
				row:tag('td')
					:css('text-align', 'right')
					:wikitext(pct(args['votes' .. v .. suf], valid[kk]))
			elseif headings['sw'] then
				row:tag('td'):attr('colspan', 3)
			else
				row:tag('td'):attr('colspan', 2)
			end
		end
		if headings['sw'] and (args['votes' .. v]) then
			row
				:tag('td')
					:css('text-align', 'right')
					:wikitext(args['sw' .. v])
		end
		if headings['seats'] and (args['seats' .. v]) then
			row
				:tag('td')
					:css('text-align', 'right')
					:wikitext(fmt(args['seats' .. v]))
		elseif headings['seats'] then
			row
				:tag('td')
					:css('text-align', 'right')
					:wikitext('–')
		end
		if headings['sc'] and (args['seats' .. v]) then
			row
				:tag('td')
					:css('text-align', 'right')
					:wikitext(args['sc' .. v])
		elseif headings['sc'] then
			row
				:tag('td')
					:css('text-align', 'right')
					:wikitext('–')
		end
	end
	-- separating line
	row = root
		:tag('tr')
			:addClass('sortbottom')
	row
		:tag('td')
			:css('background', '#eaecf0')
			:attr('colspan', cols)
	-- valid votes
	if args['invalid'] then
	row = root
		:tag('tr')
			:addClass('sortbottom')
			:css('text-align', 'right')
	row
		:tag('th')
			:wikitext('Valid votes')
			:attr('scope', 'row')
			:attr('colspan', cs)
	        :css('text-align', 'left')
	        :css('font-weight', 'normal')
	        :css('background', 'inherit')
	for k=1,rounds do
		row
			:tag('td')
				:wikitext(fmt(ovalid[k]))
			:tag('td')
				:wikitext(pct(ovalid[k], ovalid[k] + invalid[k]))
	end
	if args['invalidsw'] then
		row:tag('td')
			:wikitext(args['validsw'])
		local cspan = (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
	if headings['seats'] or headings['sc'] then
		local cspan = (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	elseif headings['sw'] or headings['seats'] or headings['sc'] then
		local cspan = (headings['sw'] and 1 or 0) + (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	-- invalid votes
	row = root:tag('tr')
			:addClass('sortbottom')
			:css('text-align', 'right')
        if args['blank'] then 
   	row
		:tag('th')
			:wikitext('Invalid votes')
			:attr('scope', 'row')
			:attr('colspan', cs)
 	        :css('text-align', 'left')
	        :css('font-weight', 'normal')
	        :css('background', 'inherit')
   	else
   	row
		:tag('th')
			:wikitext('Invalid/blank votes')
			:attr('scope', 'row')
			:attr('colspan', cs)
 	        :css('text-align', 'left')
	        :css('font-weight', 'normal')
	        :css('background', 'inherit')
   	end
   	for k=1,rounds do
		row
			:tag('td')
				:wikitext(fmt(invalid[k]))
			:tag('td')
				:wikitext(pct(invalid[k], ovalid[k] + invalid[k]))
   	end
	if args['invalidsw'] then
		row:tag('td')
			:wikitext(args['invalidsw'])
	if headings['seats'] or headings['sc'] then
		local cspan = (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	elseif headings['sw'] or headings['seats'] or headings['sc'] then
		local cspan = (headings['sw'] and 1 or 0) + (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	-- total	
	row = root:tag('tr')
			:addClass('sortbottom')
			:css('font-weight', 'bold')
			:css('text-align', 'right')
	row
		:tag('th')
			:wikitext('Total votes')
			:attr('scope', 'row')
			:attr('colspan', cs)
	        :css('text-align', 'left')
	        :css('background', 'inherit')
   	for k=1,rounds do
		row
			:tag('td')
				:wikitext(fmt(ovalid[k] + invalid[k]))
			:tag('td')
				:wikitext(pct(1,1))
   	end
   	if args['invalidsw'] then
		row:tag('td')
			:wikitext('–')
	if headings['seats'] or headings['sc'] then
		local cspan = (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	elseif headings['sw'] or headings['seats'] or headings['sc'] then
		local cspan = (headings['sw'] and 1 or 0) + (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
   	end
   	end
   	if args['totalvotes'] then 
	row = root:tag('tr')
			:addClass('sortbottom')
			:css('font-weight', 'bold')
			:css('text-align', 'right')
	row
		:tag('th')
			:wikitext('Total votes')
			:attr('scope', 'row')
			:attr('colspan', cs)
	        :css('text-align', 'left')
	        :css('background', 'inherit')
   	for k=1,rounds do
		row
			:tag('td')
				:wikitext(fmt(totalvotes[k]))
			:tag('td')
				:wikitext('–')
   	end
	if headings['sw'] or headings['seats'] or headings['sc'] then
		local cspan = (headings['sw'] and 1 or 0) + (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
   		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
   	end
   	end
	-- registered
	if args['electorate'] or args['turnout'] then
	row = root:tag('tr')
			:addClass('sortbottom')
			:css('text-align', 'right')
	row
		:tag('th')
			:wikitext('Registered voters/turnout')
			:attr('scope', 'row')
			:attr('colspan', cs)
 			:css('text-align', 'left')
	        :css('font-weight', 'normal')
	        :css('background', 'inherit')
   	if args['electorate'] and args['turnout'] then
		for k=1,rounds do
		row:tag('td')
			:wikitext(fmt(electorate[k]))
		row:tag('td')
			:wikitext(fmt(turnout[k]))
	end
   	elseif args['turnout'] then
		for k=1,rounds do
		row:tag('td')
		row:tag('td')
			:wikitext(fmt(turnout[k]))
	end
   	elseif args['invalid'] then
		for k=1,rounds do
		row:tag('td')
			:wikitext(fmt(electorate[k]))
		row:tag('td')
			:wikitext(pct(ovalid[k] + invalid[k], electorate[k]))
	end
   	elseif args['totalvotes'] then
		for k=1,rounds do
		row:tag('td')
			:wikitext(fmt(electorate[k]))
		row:tag('td')
			:wikitext(pct(totalvotes[k], electorate[k]))
	end
	else 
		for k=1,rounds do
		row:tag('td')
			:wikitext(fmt(electorate[k]))
		row:tag('td')
			:wikitext('–')
	end
	end
	if args['turnoutsw'] then
		row:tag('td')
			:wikitext(args['turnoutsw'])
	if headings['seats'] or headings['sc'] then
		local cspan = (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
   		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	elseif headings['sw'] or headings['seats'] or headings['sc'] then
		local cspan = (headings['sw'] and 1 or 0) + (headings['seats'] and 1 or 0) + (headings['sc'] and 1 or 0)
   		row
			:tag('td')
				:attr('colspan', cspan > 1 and cspan or nil)
	end
	end
	row = root:tag('tr')
			:addClass('sortbottom')
			:css('text-align', 'right')
	row:tag('td')
		:wikitext('Source: ', args.source)
		:attr('colspan', cols)
 		:css('text-align', 'left')
 		
	return tostring(root) .. tracking
end

return p