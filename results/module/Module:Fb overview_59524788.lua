-- This implements {{fb overview}}
local p = {}

-- Internationalisation
local trackingcat = 'Category:Pages using sports overview with unknown parameters'
local labels = {
	competition = 'Competition',
	firstmatch = 'First match',
	lastmatch = 'Last match',
	startinground = 'Starting round',
	finalposition = 'Final position',
	record = 'Record',
	total = 'Total',
	source = 'Source: ',
	lastupdated = 'Last updated: ',
	sourcedefault = '[[#Competitions|Competitions]]',
	unknownparameter = 'Unknown parameter: ',
	pld = '<abbr title="Games played">Pld</abbr>',
	w = '<abbr title="Games won">W</abbr>',
	d = '<abbr title="Games drawn">D</abbr>',
	l = '<abbr title="Games lost">L</abbr>',
	pf = '<abbr title="Points for">PF</abbr>',
	pa = '<abbr title="Points against">PA</abbr>',
	pd = '<abbr title="Point difference">PD</abbr>',
	gf = '<abbr title="Goals for">GF</abbr>',
	ga = '<abbr title="Goals against">GA</abbr>',
	gd = '<abbr title="Goal difference">GD</abbr>',
	wp = '<abbr title="Winning percentage">Win %</abbr>',
	winner = 'Winner',
	runnerup = 'Runner-up',
	runnersup = 'Runners-up'
}

-- Main function
function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)

	-- Get the row numbers and check for invalid input
	local rownumbers = {}
	local unknown = {}
	local showdates, showrounds, showpos = false, false, false
	local maxrow = -1
	local rowlimit = 99

	local function addrownumber(num, flag)
		if num <= rowlimit then
			table.insert(rownumbers, num)
			maxrow = (num > maxrow) and num or maxrow
			return true
		end
		return flag
	end

	for k, v in pairs(args) do
		k = tostring(k)
		local n = tonumber(k:match('^[a-z]+(%d+)$') or '-1')
		if k == 'u' or k == 'c' or k == 's' or k == 'pts' then
			-- These are valid
		elseif k:match('^[cwdlfa]%d+$') then
			local added = addrownumber(n, false)
		elseif k:match('[dfl]m%d%d*$') then
			showdates = addrownumber(n, showdates)
		elseif k:match('sr%d%d*$') then
			showrounds = addrownumber(n, showrounds)
		elseif k:match('fp%d%d*$') then
			showpos = addrownumber(n, showpos)
		else
			table.insert(unknown, {k, v})
		end
	end
	-- Sort the row numbers
	table.sort(rownumbers)

	-- Remove duplicates
	for i=#rownumbers,2,-1 do
		if rownumbers[i-1] == rownumbers[i] then
			table.remove(rownumbers,i)
		end
	end

	local root = {}
	if maxrow > -1 then
		local WDL = require('Module:WDL').main
		-- Make the table
		table.insert(root,'{| class="wikitable" style="text-align:center"')
		-- Add the headers
		table.insert(root,'|-')
		table.insert(root,'! rowspan=2 | ' .. labels['competition'])
		local totspan = 1
		if showdates then
			table.insert(root,'! rowspan=2 | ' .. labels['firstmatch'])
			table.insert(root,'! rowspan=2 | ' .. labels['lastmatch'])
			totspan = totspan + 2
		end
		if showrounds then
			table.insert(root,'! rowspan=2 | ' .. labels['startinground'])
			totspan = totspan + 1
		end
		if showpos then
			table.insert(root,'! rowspan=2 | ' .. labels['finalposition'])
			totspan = totspan + 1
		end
		table.insert(root,'! colspan=8 | ' .. labels['record'])
		table.insert(root,'|-')
		table.insert(root,'! ' .. labels['pld'])
		table.insert(root,'! ' .. labels['w'])
		table.insert(root,'! ' .. labels['d'])
		table.insert(root,'! ' .. labels['l'])
		local pg = args.pts and args.pts == 'y' and 'p' or 'g'
		table.insert(root,'! ' .. labels[pg .. 'f'])
		table.insert(root,'! ' .. labels[pg .. 'a'])
		table.insert(root,'! ' .. labels[pg .. 'd'])
		table.insert(root,'! ' .. labels['wp'])
		local evenodd = 'odd'

		-- Now add the rows
		local wtot, dtot, ltot, ftot, atot = 0, 0, 0, 0, 0
		for i=1,#rownumbers do
			local r = rownumbers[i]
			if evenodd == 'even' then
				table.insert(root,'|- style="background-color:#EEE"')
				evenodd = 'odd'
			else
				table.insert(root,'|-')
				evenodd = 'even'
			end
			table.insert(root,'| ' .. (args['c' .. r] or ''))
			if showdates then
				if args['dm' .. r] then
					table.insert(root,'| colspan=2 | ' .. args['dm' .. r])
				else
					table.insert(root,'| ' .. (args['fm' .. r] or ''))
					table.insert(root,'| ' .. (args['lm' .. r] or ''))
				end
			end
			if showrounds then
			table.insert(root,'| ' .. (args['sr' .. r] or ''))
			end
			if showpos then
				local fp = args['fp' .. r] or ''
				local bg =
					(fp:match('^' .. labels['winner']) and 'gold') or
					(fp:match('^' .. labels['runnersup']) and 'silver') or
					(fp:match('^' .. labels['runnerup']) and 'silver') or nil
				if bg then
					table.insert(root,'| style="background-color:' .. bg .. '" | ' .. fp)
				else
					table.insert(root,'| ' .. fp)
				end
			end
			wtot = wtot + (tonumber(args['w' .. r]) or 0)
			dtot = dtot + (tonumber(args['d' .. r]) or 0)
			ltot = ltot + (tonumber(args['l' .. r]) or 0)
			ftot = ftot + (tonumber(args['f' .. r]) or 0)
			atot = atot + (tonumber(args['a' .. r]) or 0)
			table.insert(root, WDL(frame,
				{nil, args['w' .. r],  args['d' .. r],  args['l' .. r],
				['for'] = args['f' .. r], ['against'] = args['a' .. r], ['diff'] = 'yes'})
			)
		end
		table.insert(root,'|-')
		if totspan > 1 then
			table.insert(root,'! colspan=' .. totspan .. ' | ' .. labels['total'])
		else
			table.insert(root,'! ' .. labels['total'])
		end
		table.insert(root, WDL(frame,
				{wtot+dtot+ltot, wtot, dtot, ltot, ['total'] = 'y',
				['for'] = ftot, ['against'] = atot, ['diff'] = 'yes'})
			)
		table.insert(root, '|}' .. frame:expandTemplate{title = 'refbegin'})
		if args.u then
			table.insert(root, labels['lastupdated'] .. args.u .. '<br>')
		end
		table.insert(root, labels['source'] .. (args.s or labels['sourcedefault']) .. frame:expandTemplate{title = 'refend'})
	end

	if #unknown > 0 then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			for i=1,#unknown do
				table.insert(root,'<div class="error" style="font-weight:normal">' ..
					labels['unknownparameter'] .. ' "' .. unknown[i][1] .. '"</div>')
			end
		else
			table.insert(root, '[[' .. trackingcat .. '|' .. mw.uri.anchorEncode(tostring(unknown[1][1])) .. ' ]]')

		end
	end

	return table.concat(root, '\n')
end

return p