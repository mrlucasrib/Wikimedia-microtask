-- This module implements {{NLLDivisionStanding}}.

local yesno = require('Module:Yesno')

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

local function abbr(shortForm, longForm)
	return tostring(mw.html.create('abbr')
		:attr('title', longForm)
		:wikitext(shortForm)
	)
end

-------------------------------------------------------------------------------
-- Team class
-------------------------------------------------------------------------------

local Team = {}
Team.__index = Team

Team.stringFields = {
	'name',
	'link',
	'short',
}

Team.numberFields = {
	'pos',
	'clinch_playoff',
	'clinch_division',
	'clinch_best_record',
	'ga',
	'gf',
	'home_loss',
	'home_win',
	'road_loss',
	'road_win',
}

function Team.new(options)
	options = options or {}
	local self = setmetatable({}, Team)
	for i, field in ipairs(Team.stringFields) do
		self[field] = options[field]
	end
	for i, field in ipairs(Team.numberFields) do
		self[field] = tonumber(options[field])
	end
	return self
end

function Team:getPosition()
	return tostring(self.pos) or '--'
end

function Team:getShortName()
	return self.short
end

function Team:getName()
	return self.name
end

function Team:getLink()
	local name = self:getName()
	local link = self.link
	if link and name then
		return string.format('[[%s|%s]]', link, name)
	elseif link then
		return string.format('[[%s]]', link)
	else
		return name
	end
end

function Team:makeDisplayName()
	local ret = self:getLink()
	if not ret then
		return nil
	end
	local clinches = {}
	-- The numerical syntax here is a hangover from the wikitext template
	-- which used #expr hacks to calculate the number of clinches
	if self.clinch_playoff == 1 then
		table.insert(clinches, 'x')
	end
	if self.clinch_playoff == 2 then
		table.insert(clinches, 'c')
	end
	if self.clinch_division == 1 then
		table.insert(clinches, 'y')
	end
	if self.clinch_best_record == 1 then
		table.insert(clinches, 'z')
	end
	if clinches[1] then
		ret = string.format("%s &ndash; '''%s'''", ret, table.concat(clinches))
	end
	return ret
end

function Team:getHomeWins()
	return self.home_win or 0
end

function Team:getHomeLosses()
	return self.home_loss or 0
end

function Team:getRoadWins()
	return self.road_win or 0
end

function Team:getRoadLosses()
	return self.road_loss or 0
end

function Team:getGamesPlayed()
	return self:getHomeWins() +
		self:getRoadWins() +
		self:getHomeLosses() +
		self:getRoadLosses()
end

function Team:getWins()
	return self:getHomeWins() + self:getRoadWins()
end

function Team:getLosses()
	return self:getHomeLosses() + self:getRoadLosses()
end

function Team:_divideByGamesPlayed(val)
	local gp = self:getGamesPlayed()
	if gp > 0 then -- avoid divide-by-zero error
		return val / gp
	else
		return 0
	end
end

function Team:getWinPercentage()
	local percent = self:_divideByGamesPlayed(self:getWins())
	if percent > 1 then
		percent = 1
	elseif percent < 0 then
		percent = 0
	end
	local ret = string.format('%.3f', percent)
	if ret:sub(1, 1) == '0' then
		-- Use strings like .123 instead of 0.123 as that is how it's done
		-- in sports publications
		ret = ret:sub(2, -1)
	end
	return ret
end

function Team:getGamesBack(teamInFirst)
	local tifDiff = teamInFirst:getWins() - teamInFirst:getLosses()
	local selfDiff = self:getWins() - self:getLosses()
	return string.format('%.1f', (tifDiff - selfDiff) / 2)
end

function Team:getHomeRecord()
	return self:getHomeWins() .. '&ndash;' .. self:getHomeLosses()
end

function Team:getRoadRecord()
	return self:getRoadWins() .. '&ndash;' .. self:getRoadLosses()
end

function Team:getGoalsScored()
	return self.gf or 0
end

function Team:getGoalsAllowed()
	return self.ga or 0
end

function Team:getDifferential()
	local diff = self:getGoalsScored() - self:getGoalsAllowed()
	if diff > 0 then
		return '+' .. tostring(diff)
	else
		return tostring(diff)
	end
end

function Team:getGameScoredAverage()
	local avg = self:_divideByGamesPlayed(self:getGoalsScored())
	return string.format('%.2f', avg)
end

function Team:getGameAllowedAverage()
	local avg = self:_divideByGamesPlayed(self:getGoalsAllowed())
	return string.format('%.2f', avg)
end

-------------------------------------------------------------------------------
-- DivisionStanding class
-------------------------------------------------------------------------------

local DivisionStanding = {}
DivisionStanding.__index = DivisionStanding

function DivisionStanding.new(args)
	local self = setmetatable({}, DivisionStanding)

	-- Set template-wide arguments
	self.division = args.division
	self.team = args.team
	self.hideLegend = yesno(args.hideLegend, false)

	-- Separate args starting with "team" by team number.
	local teamArgs = {}
	for k, v in pairs(args) do
		if type(k) == 'string' then
			local num, suffix = k:match('^team([1-9][0-9]*)_([a-z_]+)$')
			if num then
				num = tonumber(num)
				teamArgs[num] = teamArgs[num] or {}
				teamArgs[num][suffix] = v
			end
		end
	end

	-- Make the team objects
	self.teams = {}
	for num, t in pairs(teamArgs) do
		self.teams[num] = Team.new(t)
	end

	-- Find the first-place team if it has been specified
	self.teamInFirst = tonumber(args.teamInFirst)
	if self.teamInFirst then
		self.teamInFirst = self.teams[self.teamInFirst]
	end

	-- Compress the teams array, which at the moment may contain nils
	self.teams = (function (t)
		local nums, ret = {}, {}
		for num in pairs(t) do
			nums[#nums + 1] = num
		end
		table.sort(nums)
		for i, num in ipairs(nums) do
			ret[i] = t[num]
		end
		return ret
	end)(self.teams)

	-- Assume the first-place team is the first team in the teams array if it
	-- was not specified earlier
	if not self.teamInFirst then
		self.teamInFirst = self.teams[1]
	end

	return self
end

function DivisionStanding:__tostring()
	local root = mw.html.create()
	local tableRoot = root:tag('table')
	tableRoot
		:addClass('wikitable sortable')
		:css('width', '65%')

	-- Caption
	if self.division then
		tableRoot:tag('caption')
			:wikitext(self.division)
			:wikitext(' Division')
	end

	-- Headers
	local headerRow = tableRoot:tag('tr')
	local function addHeader(display, width, sort)
		headerRow:tag('th')
			:css('width', tostring(width) .. '%')
			:attr('data-sort-type', sort)
			:wikitext(display)
	end
	addHeader(abbr('P', 'Position'), 4, 'number')
	addHeader('Team', 38, 'text')
	addHeader('GP', 4, 'number')
	addHeader('W', 4, 'number')
	addHeader('L', 4, 'number')
	addHeader('PCT', 5, 'number')
	addHeader('GB', 5, 'number')
	addHeader('Home', 6, 'number')
	addHeader('Road', 6, 'number')
	addHeader('GF', 4, 'number')
	addHeader('GA', 4, 'number')
	addHeader(abbr('Diff', 'Differential'), 4, 'number')
	addHeader('GF/GP', 6, 'number')
	addHeader('GA/GP', 6, 'number')

	-- Empty header row. This is purely to hold the up-down arrow icons added
	-- with the "sortable" class, which helps to keep the table width down.
	local emptyHeaderRow = tableRoot:tag('tr')
	emptyHeaderRow:tag('th'):tag('br', {selfClosing = true})
	for i = 1, 13 do
		emptyHeaderRow:tag('th')
	end

	-- Rows
	local function addTeamCell(teamRow, val, align)
		teamRow:tag('td')
			:css('text-align', align)
			:wikitext(val)
	end
	for i, team in ipairs(self.teams) do
		if team:getLink() then
			local teamRow = tableRoot:tag('tr')
			teamRow
				:css('text-align', 'center')
				:css('background-color', self.team and
					self.team == team:getShortName() and
					'#ccffcc' or
					nil
				)
			addTeamCell(teamRow, team:getPosition())	
			addTeamCell(teamRow, team:makeDisplayName(), 'left')
			addTeamCell(teamRow, team:getGamesPlayed())
			addTeamCell(teamRow, team:getWins())
			addTeamCell(teamRow, team:getLosses())
			addTeamCell(teamRow, team:getWinPercentage())
			addTeamCell(teamRow, team:getGamesBack(self.teamInFirst))
			addTeamCell(teamRow, team:getHomeRecord())
			addTeamCell(teamRow, team:getRoadRecord())
			addTeamCell(teamRow, team:getGoalsScored())
			addTeamCell(teamRow, team:getGoalsAllowed())
			addTeamCell(teamRow, team:getDifferential())
			addTeamCell(teamRow, team:getGameScoredAverage())
			addTeamCell(teamRow, team:getGameAllowedAverage())
		end	
	end

	-- Legend
	if not self.hideLegend then
		local function makeLegend(key, val)
			return string.format("'''%s''':&nbsp;%s", key, val)
		end
		root:newline()
		root:tag('small')
			:wikitext(table.concat({
				makeLegend('x', 'Clinched playoff berth'),
				makeLegend('c', 'Clinched playoff berth by crossing over to another division'),
				makeLegend('y', 'Clinched division'),
				makeLegend('z', 'Clinched best regular season record'),
				makeLegend('GP', 'Games Played'),
			}, '; '))
			:tag('br', {selfClosing = true}):done()
			:wikitext(table.concat({
				makeLegend('W', 'Wins'),
				makeLegend('L', 'Losses'),
				makeLegend('GB', '[[Games behind|Games back]]'),
				makeLegend('PCT', 'Win percentage'),
				makeLegend('Home', 'Record at Home'),
				makeLegend('Road', 'Record on the Road'),
				makeLegend('GF', 'Goals scored'),
				makeLegend('GA', 'Goals allowed'),
			}, '; '))
			:tag('br', {selfClosing = true}):done()
			:wikitext(table.concat({
				makeLegend('Differential', 'Difference between goals scored and allowed'),
				makeLegend('GF/GP', 'Average number of goals scored per game'),
				makeLegend('GA/GP', 'Average number of goals allowed per game'),
			}, '; '))
	end

	return tostring(root)
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._main(args)
	return tostring(DivisionStanding.new(args))
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:NLLDivisionStanding'
	})
	return p._main(args)
end

return p