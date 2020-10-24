-- This module implements [[Template:NLLGameLog]].

local yesno = require('Module:Yesno')
local lang = mw.language.getContentLanguage()

--------------------------------------------------------------------------------
-- Game class
--------------------------------------------------------------------------------

local Game = {}
Game.__index = Game

Game.keys = {
	'opp',
	'opp_link',
	'team_score',
	'opp_score',
	'num',
	'date',
	'road_game',
	'loc',
	'loc_link',
	'ot',
	'attendance',
}

function Game.new(data)
	local self = setmetatable({}, Game)
	local args = data.args

	-- Set properties from arguments
	self.id = data.id
	do
		local prefix = 'game' .. self.id .. '_'
		for i, key in ipairs(Game.keys) do
			self[key] = args[prefix .. key]
		end
	end

	-- Set other properties
	self.arena = args.arena
	self.arena_link = args.arena_link

	-- Abort if we don't have required fields
	if not self.opp and not self.opp_link then
		return nil
	end

	-- Set wins and losses
	self.total_wins = data.previous_wins
	self.total_losses = data.previous_losses
	if self:is_win() then
		self.total_wins = self.total_wins + 1
	else
		self.total_losses = self.total_losses + 1
	end

	-- Do some simple data preprocessing
	self.road_game = yesno(self.road_game) or false

	return self
end

function Game:get_number()
	return self.num or self.id
end

function Game:get_total_wins()
	return self.total_wins
end

function Game:get_total_losses()
	return self.total_losses
end

function Game:get_team_score()
	return tonumber(self.team_score) or 0
end

function Game:get_opponent_score()
	return tonumber(self.opp_score) or 0
end

function Game:has_valid_score()
	return self:get_team_score() + self:get_opponent_score() > 0
end

function Game:is_win()
	-- Only record win/loss, as there are no draws in box lacrosse
	return self:get_team_score() - self:get_opponent_score() > 0
end

function Game:get_date()
	-- TODO: Convert [[Template:Date]] to Lua and call the module from here.
	local date = self.date or string.format('{{{game%d_date}}}', self.id)
	local frame = mw.getCurrentFrame()
	return frame:expandTemplate{title = 'Date', args = {date, 'mdy'}}
end

function Game:make_link(page, display)
	if display and page then
		return string.format('[[%s|%s]]', page, display)
	elseif display then
		return display
	elseif page then
		return string.format('[[%s]]', page)
	else
		return ''
	end
end

function Game:make_opponent_text()
	local ret = ''
	if self.road_game then
		ret = ret .. '@ '
	end
	ret = ret .. self:make_link(self.opp_link, self.opp)
	return ret
end

function Game:make_location_text()
	if self.road_game then
		return self:make_link(self.loc_link, self.loc)
	else
		return self:make_link(self.arena_link, self.arena)
	end
end

function Game:make_score_text()
	local team = self:get_team_score()
	local opp = self:get_opponent_score()
	local ret = ''
	if self:is_win() then
		ret = ret .. 'W'
	else
		ret = ret .. 'L'
	end
	return ret .. ' ' .. team .. '&ndash;' .. opp
end

function Game:make_overtime_text()
	local ot = tonumber(self.ot) or 0
	local ret = ''
	if ot > 0 then
		if ot > 1 then
			ret = ret .. ot
		end
		ret = ret .. 'OT'
	end
	return ret
end

function Game:make_attendance_text()
	local att = tonumber(self.attendance) or 0
	return lang:formatNum(att)
end

function Game:make_record()
	-- The record of the wins and losses so far in the game log.
	return self:get_total_wins() .. '&ndash;' .. self:get_total_losses()
end

function Game:render_html()
	local row = mw.html.create('tr')

	-- Row color
	if self:has_valid_score() then
		row:css('background-color', self:is_win() and '#ccffcc' or '#ffbbbb')
	end

	local function addCell(content)
		if content then
			row:tag('td')
				:css('text-align', 'center')
				:wikitext(content)
		else
			row:tag('td')
		end
	end

	addCell(self:get_number())
	addCell(self:get_date())
	addCell(self:make_opponent_text())
	addCell(self:make_location_text())

	if self:has_valid_score() then
		addCell(self:make_score_text())
		addCell(self:make_overtime_text())
		addCell(self:make_attendance_text())
		addCell(self:make_record())
	else
		for i = 1, 4 do
			addCell()
		end
	end

	return row
end

--------------------------------------------------------------------------------
-- GameLog class
--------------------------------------------------------------------------------

local GameLog = {}
GameLog.__index = GameLog

function GameLog.new(args)
	local self = setmetatable({}, GameLog)

	-- Set game objects
	self.games = {}
	local i = 0
	local wins = 0
	local losses = 0
	while true do
		i = i + 1
		local game = Game.new{
			id = i,
			args = args,
			previous_wins = wins,
			previous_losses = losses,
		}
		if game then
			wins = game:get_total_wins()
			losses = game:get_total_losses()
			self.games[i] = game
		else
			break
		end
	end

	return self
end

function GameLog:get_game(id)
	return self.games[id]
end

function GameLog:__tostring()
	local root = mw.html.create('table')
	root
		:addClass('wikitable')
		:css('width', '85%')

	-- Headers
	do
		local headerRow = root:tag('tr')

		local function addHeader(header, width)
			headerRow
				:tag('th')
					:css('width', width .. '%')
					:wikitext(header)
		end

		addHeader('Game', 5)
		addHeader('Date', 15)
		addHeader('Opponent', 25)
		addHeader('Location', 30)
		addHeader('Score', 10)
		addHeader('OT', 5)
		addHeader('Attendance', 5)
		addHeader('Record', 5)
	end

	-- Data
	local i = 0
	while true do
		i = i + 1
		local game = self:get_game(i)
		if game then
			root:node(game:render_html())
		else
			break
		end
	end

	return tostring(root)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p._main(args)
	return tostring(GameLog.new(args))
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:NLL game log'
	})
	return p._main(args)
end

return p