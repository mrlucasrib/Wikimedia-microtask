--
-- This module will implement {{TeamBracket}}
--

local p = {}
local args
local rounds
local padding
local hideSeeds
local showSeeds
local tracking = ''

function getSeeds()
	local seeds = {1, 2}
	local count = 2
	local before = false
	for r = 2, rounds do
		local max = math.pow(2, r)
		for i = 1, count do
			local pos = i * 2
			if before then pos = pos - 1 end
			table.insert(seeds, pos, max - seeds[i * 2 - 1] + 1)
			before = not before
		end
		count = count * 2
	end
	return seeds
end

function addTableRow(tbl)
	return tbl:tag('tr')
end

function addBlank(row, width)
	local cell = row:tag('td')
	if width then
		cell:css('width', width)
	end
	return cell
end

function addPath(rows, index, round, top, left)
	local prop = top and 'border-bottom-width' or 'border-top-width'
	if left and round == 1 then
		addBlank(rows[index]):css('height', '7px')
		addBlank(rows[index + 1]):css('height', '7px')
		return nil
	else
		local cell = addBlank(rows[index])
			:attr('rowspan', '2')
			:css('border-width', '0')
			:css('border-style', 'solid')
			:css('border-color', 'black')
		if left or round < rounds and not left then
			cell:css(prop, '2px')
		end
		return cell
	end
end

function addCompactPath(rows, index, round, top, left)
	local prop = top and 'border-bottom-width' or 'border-top-width'
	if left and round == 1 then
		addBlank(rows[index])
		return nil
	else
		local cell = addBlank(rows[index])
			:css('border-width', '0')
			:css('border-style', 'solid')
			:css('border-color', 'black')
		if left or round < rounds and not left then
			cell:css(prop, '2px')
		end
		return cell
	end
end

function getWidth(param, default)
	local arg = args[param .. '-width']
	if not arg or string.len(arg) == 0 then
		arg = default
	end
	if tonumber(arg) ~= nil then
		arg = arg .. 'px'
	end
	return arg
end

function getTeamArg(round, type, team)
	return args[getTeamArgName(round, type, team)]
end

function getTeamArgName(round, type, team)
	return string.format('RD%d-%s' .. padding, round, type, team)
end

function getRoundName(round)
	local name = args['RD' .. round]
	if name and string.len(name) > 0 then
		return name
	end
	local roundFromLast = rounds - round + 1
	if roundFromLast == 1 then
		return "Finals"
	elseif roundFromLast == 2 then
		return "Semifinals"
	elseif roundFromLast == 3 then
		return "Quarterfinals"
	else
		return "Round of " .. math.pow(2, roundFromLast)
	end
end

function renderTeam(row, round, team, top, compact)
	local seedCell
	local seedArg = getTeamArg(round, 'seed', team)
	-- seed value for the paired team
	local pairSeedArg = getTeamArg(round, 'seed',
		team % 2 == 0 and team - 1 or team + 1)
	-- show seed if seed is defined for either or both
	local showSeed = showSeeds 
		or (seedArg and string.len(seedArg) > 0)
		or (pairSeedArg and string.len(pairSeedArg) > 0)
	if showSeed and (not hideSeeds) then
		seedCell = row:tag('td')
			:css('text-align', 'center')
			:css('background-color', '#f2f2f2')
			:css('border-color', '#aaa')
			:css('border-style', 'solid')
			:css('border-top-width', '1px')
			:css('border-left-width', '1px')
			:css('border-right-width', '1px')
			:css('border-bottom-width', '0')
			:wikitext(seedArg)
			:newline()
	end

	local teamArg = getTeamArg(round, 'team', team)
	if not teamArg or string.len(teamArg) == 0 then
		teamArg = '&nbsp;'
	end
	local teamCell = row:tag('td')
		:css('background-color', '#f9f9f9')
		:css('border-color', '#aaa')
		:css('border-style', 'solid')
		:css('border-top-width', '1px')
		:css('border-left-width', '1px')
		:css('border-right-width', '0')
		:css('border-bottom-width', '0')
		:css('padding', '0 2px')
		:wikitext(teamArg)
		:newline()
	if not showSeed and (not hideSeeds) then
		teamCell:attr('colspan', '2')
	end

	local scoreCell = row:tag('td')
		:css('text-align', 'center')
		:css('border-color', '#aaa')
		:css('border-style', 'solid')
		:css('border-top-width', '1px')
		:css('border-left-width', '1px')
		:css('border-right-width', '1px')
		:css('border-bottom-width', '0')
		:css('background-color', '#f9f9f9')
		:wikitext(getTeamArg(round, 'score', team))
		:newline()

	if not compact then
		if seedCell then
			seedCell:attr('rowspan', '2')
				:css('border-bottom-width', '1px')
		end
		scoreCell:attr('rowspan', '2')
			:css('border-bottom-width', '1px')
		teamCell:attr('rowspan', '2')
			:css('border-right-width', '1px')
			:css('border-bottom-width', '1px')
	else
		if not top then
			if seedCell then
				seedCell:css('border-bottom-width', '1px')
			end
			teamCell:css('border-bottom-width', '1px')
			scoreCell:css('border-bottom-width', '1px')
		end
	end
end

function renderRound(rows, count, r)
	local teams = math.pow(2, rounds - r + 1)
	local step = count / teams
	local topTeam = true -- is top row in match-up
	local topPair = true -- is top match-up in pair of match-ups
	local team = 1
	for i = 1, count, step do
		local offset, height, blank
		-- leave room for groups for teams other than first and last
		if team == 1 or team == teams then
			offset = topTeam and i or i + 2
			height = step - 2
		else
			offset = topTeam and i + 1 or i + 2
			height = step - 3
		end
		if height > 0 then
			blank = addBlank(rows[offset])
				:attr('colspan', hideSeeds and '4' or '5')
				:attr('rowspan', height)
				:css('border-color', 'black')
				:css('border-style', 'solid')
				:css('border-width', '0')
		end
		-- add bracket
		local j = topTeam and i + step - 2 or i
		-- add left path
		addPath(rows, j, r, topTeam, true)
		renderTeam(rows[j], r, team, topTeam, false)
		local rightPath = addPath(rows, j, r, topTeam, false)
		if not topTeam then topPair = not topPair end
		if not topPair and r < rounds then
			if blank then blank:css('border-right-width', '2px') end
			rightPath:css('border-right-width', '2px')
		end
		team = team + 1
		topTeam = not topTeam
	end
end

function renderCompactRound(rows, count, r)
	local teams = math.pow(2, rounds - r + 1)
	local step = count / teams
	local topTeam = true -- is top row in match-up
	local topPair = true -- is top match-up in pair of match-ups
	local team = 1

	for i = 1, count, step do
		local offset, height, blank
		-- empty space above or below
		local offset = topTeam and i or i + 1
		local height = step - 1

		if height > 0 then
			blank = addBlank(rows[offset])
				:attr('colspan', hideSeeds and '4' or '5')
				:css('border-color', 'black')
				:css('border-style', 'solid')
				:css('border-width', '0')
				:attr('rowspan', height)
		end
		-- add bracket
		local j = topTeam and i + step - 1 or i
		-- add left path
		addCompactPath(rows, j, r, topTeam, true)
		renderTeam(rows[j], r, team, topTeam, true)
		local rightPath = addCompactPath(rows, j, r, topTeam, false)
		if not topTeam then topPair = not topPair end
		if not topPair and r < rounds then
			if blank then blank:css('border-right-width', '2px') end
			rightPath:css('border-right-width', '2px')
		end
		team = team + 1
		topTeam = not topTeam
	end
end

function renderGroups(rows, count, round)
	local roundFromLast = rounds - round + 1
	local groups = math.pow(2, roundFromLast - 2)
	local step = count / groups
	local group = 1
	for i = step / 2, count, step do
		local name = 'RD' .. round .. '-group' .. group
		addBlank(rows[i]):css('height', '7px')
		addBlank(rows[i + 1]):css('height', '7px')
		addBlank(rows[i])
			:attr('rowspan', '2')
			:attr('colspan', (hideSeeds and 4 or 5) * round - 1)
			:css('text-align', 'center')
			:css('border-color', 'black')
			:css('border-style', 'solid')
			:css('border-width', '0 2px 0 0')
			:wikitext(args[name])
			:newline()
		group = group + 1
	end
end

function renderTree(tbl, compact)
	-- create 3 or 1 rows for every team
	local count = math.pow(2, rounds) * (compact and 1 or 3)
	local rows = {}
	for i = 1, count do
		rows[i] = addTableRow(tbl)
	end
	if not compact then
		-- fill rows with groups
		for r = 1, rounds - 1 do
			renderGroups(rows, count, r)
		end
	end
	-- fill rows with bracket
	for r = 1, rounds do
		if compact then
			renderCompactRound(rows, count, r)
		else
			renderRound(rows, count, r)
		end
	end
end

function renderHeading(tbl, compact)
	local titleRow = addTableRow(tbl)
	local widthRow = addTableRow(tbl)
	for r = 1, rounds do
		addBlank(titleRow)
		addBlank(widthRow, r > 1 and '5px' or nil)
		titleRow:tag('td')
			:attr('colspan', hideSeeds and '2' or '3')
			:css('text-align', 'center')
			:css('border', '1px solid #aaa')
			:css('background-color', '#f2f2f2')
			:wikitext(getRoundName(r))
			:newline()
		local seedCell
		if not hideSeeds then
			seedCell = addBlank(widthRow, getWidth('seed', '25px'))
		end
		local teamCell = addBlank(widthRow, getWidth('team', '150px'))
		local scoreCell = addBlank(widthRow, getWidth('score', '25px'))
		addBlank(titleRow)
		addBlank(widthRow, r < rounds and '5px' or nil)

		if compact then
			teamCell:css('height', '7px')
		else
			if seedCell then
				seedCell:wikitext('&nbsp;')
			end
			teamCell:wikitext('&nbsp;')
			scoreCell:wikitext('&nbsp;')
		end
	end
end

function p.teamBracket(frame)
	local getArgs = require('Module:Arguments').getArgs
	args = getArgs(frame, {trim = false, removeBlanks = false})

	-- exit early if this section is not to be transcluded
	if args['section'] and args['transcludesection'] 
		and args['section'] ~= args['transcludesection'] then return ''
	end

	rounds = tonumber(args.rounds) or 2
	local teams = math.pow(2, rounds)
	padding = '%0' .. (teams < 10 and 1 or 2) .. 'd'
	local compact = (args['compact'] and (args['compact'] == 'yes' or args['compact'] == 'y'))
	local autoSeeds = (args['autoseeds'] and (args['autoseeds'] == 'yes' or args['autoseeds'] == 'y'))
	hideSeeds = (args['seeds'] and (args['seeds'] == 'no' or args['seeds'] == 'n'))
	showSeeds = (args['seeds'] and (args['seeds'] == 'yes' or args['seeds'] == 'y'))

	if autoSeeds then
		-- set default seeds for round 1
		local seeds = getSeeds()
		for i = 1, table.getn(seeds) do
			local argname = getTeamArgName(1, 'seed', i)
			if not args[argname] then
				args[argname] = seeds[i]
			end
		end
	end

	local tbl = mw.html.create('table')
		:css('border-style', 'none')
		:css('font-size', '90%')
		:css('margin', '1em 2em 1em 1em')
		:css('border-collapse', 'separate')
		:css('border-spacing', '0')

	if (args['nowrap'] and (args['nowrap'] == 'yes' or args['nowrap'] == 'y')) then
		tbl:css('white-space', 'nowrap')
	end

	if compact then
		tbl:css('font-size', '90%'):attr('cellpadding', '0')
	end

	renderHeading(tbl, compact)
	renderTree(tbl, compact)
	return tostring(tbl) .. tracking
end

return p