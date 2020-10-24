-- This module implements polls used in articles of the Signpost.

local CONFIG_MODULE = 'Module:Signpost poll/config'

local yesno = require('Module:Yesno')
local lang = mw.language.getContentLanguage()

-------------------------------------------------------------------------------
-- Message method
-- This method is available in every class, so it is defined separately.
-------------------------------------------------------------------------------

local function message(self, key, params, isPreprocessed)
	local msg = self.cfg.msg[key]
	if params and #params > 0 then
		msg = mw.message.newRawMessage(msg, params):plain()
	end
	if isPreprocessed then
		msg = self.frame:preprocess(msg)
	end
	return msg
end

-------------------------------------------------------------------------------
-- Option class
-------------------------------------------------------------------------------

local Option = {}
Option.__index = Option
Option.message = message

function Option.new(t)
	local self = setmetatable({}, Option)
	self.cfg = t.cfg
	self.frame = t.frame
	self.nOption = t.nOption
	self.votePage = t.votePage
	self.preload = t.preload
	self.text = t.text
	self.voteText = t.voteText
	self.color = t.color
	return self
end

function Option:getCount()
	if self.count then
		return self.count
	else
		self.count = mw.getCurrentFrame():expandTemplate{title="String count",args={
			page = self.votePage,
			search = self:getVoteText(n)
		}}
		return self.count
	end
end

function Option:setVoteTotal(n)
	self.total = n
end

function Option:getVoteTotal()
	return self.total or error('total number of votes has not been set')
end

function Option:getPercentage()
	if self.percentage then
		return self.percentage
	else
		self.percentage = self:getCount() / self:getVoteTotal() * 100
		return self.percentage
	end
end

function Option:getColor()
	-- Get the default color for option n
	if self.color then
		return self.color
	end
	local colors = self.cfg.colors
	local color = colors[self.nOption]
	if color then
		self.color = color
	else
		-- Loop to find the length of colors. We can't use the # operator as
		-- a metatable is set by mw.loadData. This is bad for polls with
		-- more options than there are colors in the config, as we would loop
		-- for every single option object. This will likely never be a problem
		-- in practice, however.
		local nColors = 0
		for i in ipairs(colors) do
			nColors = i
		end
		-- colors[nColors] is necessary as Lua arrays are indexed starting at
		-- 1, and n % self.nColors might sometimes equal 0.
		self.color = colors[self.nOption % nColors] or colors[nColors]
	end
	return self.color
end

function Option:getVoteText()
	self.voteText = self.voteText or self:message(
		'vote-default',
		{self.nOption},
		true
	)
	return self.voteText
end

function Option:makeVoteURL()
	local url = mw.uri.fullUrl(
		self.votePage,
		{
			action = 'edit',
			section = 'new',
			nosummary = 'true',
			preload = self.preload,
			['preloadparams[]'] = self:getVoteText()
		}
	)
	return tostring(url)
end

function Option:renderButton()
	local button = mw.html.create('span')
		:addClass('mw-ui-button mw-ui-progressive')
		:attr('role', 'button')
		:attr('aria-disabled', 'false')
		:wikitext(self.text)
	local wrapper = mw.html.create('span')
		:addClass('plainlinks')
		:css('margin', '0 4px')
		:wikitext(string.format(
			'[%s %s]',
			self:makeVoteURL(),
			tostring(button)
		))
	return wrapper
end

function Option:renderLegendRow()
	local legend = mw.html.create('div')
	legend
		:css('margin', '4px')
		:tag('span')
			:css('display', 'inline-block')
			:css('width', '1.5em')
			:css('height', '1.5em')
			:css('margin', '1px 0')
			:css('border', '1px solid black')
			:css('background-color', self:getColor())
			:css('text-align', 'center')
			:wikitext('&nbsp;')
			:done()
		:wikitext('&nbsp;')
		:wikitext(self:message('legend-option-text', {
			self.text,
			self:getCount(),
			string.format('%.0f', self:getPercentage())
		}, true))
	return legend
end

-------------------------------------------------------------------------------
-- Poll class
-------------------------------------------------------------------------------

local Poll = {}
Poll.__index = Poll
Poll.message = message

function Poll.new(args, cfg, frame)
	local self = setmetatable({}, Poll)
	self.cfg = cfg or mw.loadData(CONFIG_MODULE)
	self.frame = frame or mw.getCurrentFrame()

	-- Set required fields
	self.question = assert(args.question, self:message('no-question-error'))
	self.votePage = assert(args.votepage, self:message('no-votepage-error'))

	-- Set optional fields
	self.headerText = args.header or self:message('header-text')
	self.icon = args.icon or self:message('icon-default')
	self.overlay = args.overlay or self:message('overlay-default')
	self.minimum = tonumber(args.minimum) or self:message('minimum-default')
	self.expiry = args.expiry
	self.lineBreak = args['break']

	-- Set options
	self.options = {}
	do
		local preload = self:message('preload-page')
		local i = 1
		while true do
			local key = 'option' .. tostring(i)
			local text = args[key]
			if not text then
				break
			end
			table.insert(self.options, Option.new{
				nOption = i,
				text = text,
				voteText = args[key .. 'vote'],
				color = args[key .. 'color'],
				cfg = self.cfg,
				frame = self.frame,
				votePage = self.votePage,
				preload = preload
			})
			i = i + 1
		end
		if #self.options < 2 then
			error(self:message('not-enough-options-error'))
		end
	end

	-- Check for duplicate vote text
	do
		local votes = {}
		for option in self:iterateOptions() do
			if votes[option:getVoteText()] then
				error(self:message(
					'duplicate-vote-text-error',
					{votes[option:getVoteText()], option.nOption},
					true
				))
			else
				votes[option:getVoteText()] = option.nOption
			end
		end
	end

	-- Prompt users to create the vote page if it doesn't exist.
	do
		local success, votePageContent = pcall(function ()
			return mw.title.new(self.votePage):getContent()
		end)
		if not success or not votePageContent then
			local createVotePageUrl = mw.uri.fullUrl(
				self.votePage,
				{
					action = 'edit',
					preload = self:message('vote-page-preload-default'),
					['preloadparams[]'] = mw.title.getCurrentTitle().prefixedText,
					summary = self:message('vote-page-create-summary'),
					editintro = self:message('vote-page-create-editintro')
				}
			)
			error(self:message(
				'votepage-nonexistent-error',
				{tostring(createVotePageUrl)}
			), 0)
		end
	end

	-- Find total number of votes
	do
		local total = 0
		for option in self:iterateOptions() do
			total = total + option:getCount()
		end
		for option in self:iterateOptions() do
			option:setVoteTotal(total)
		end
		self.voteTotal = total
	end

	return self
end

-- Static methods

function Poll.getUnixDate(date)
	date = lang:formatDate('U', date)
	return tonumber(date)
end

-- Normal methods

function Poll:iterateOptions()
	local i = 0
	local n = #self.options
	return function ()
		i = i + 1
		if i <= n then
			return self.options[i]
		end
	end
end

function Poll:renderHeader()
	local headerDiv = mw.html.create('div')
	headerDiv
		:css('border-top', '1px solid #CCC')
		:css('font-family', 'Georgia, Palatino, Palatino Linotype, Times, Times New Roman, serif')
		:css('color', '#333')
		:css('padding', '5px 0')
		:css('line-height', '120%')
		:wikitext(string.format(
			'[[File:%s|right|30px|link=]]',
			self.icon
		))
		:tag('span')
			:css('text-transform', 'uppercase')
			:css('color', '#999')
			:css('font-size', '105%')
			:css('font-weight', 'bold')
			:wikitext(self.headerText)
	return headerDiv
end

function Poll:renderQuestion()
	local question = mw.html.create('div')
		:css('margin-top', '10px')
		:css('margin-bottom', '10px')
		:css('line-height', '100%')
		:css('font-size', '95%')
		:wikitext(self.question)
	return question
end

function Poll:renderVisualization()
	local overlayWidth = '253px'
	local vzn = mw.html.create('div')
		:css('height', '250px')
		:css('border-spacing', '0')
		:css('width', overlayWidth)
		:css('margin-left', 'auto')
		:css('margin-right', 'auto')

	-- Overlay
	vzn
		:tag('div')
			:css('position', 'absolute')
			:css('z-index', '2')
			:css('padding', '0')
			:css('margin', '0')
			:wikitext(string.format(
				'[[File:%s|%s|link=]] &nbsp;',
				self.overlay,
				overlayWidth
			))

	-- Option colors
	for option in self:iterateOptions() do
		vzn:tag('div')
			:css('background', option:getColor())
			:css('padding', '0')
			:css('margin', '0')
			:css('width', '250px')
			:css('height', string.format(
				'%.3f%%', -- Round to 3 decimal places and add a percent sign
				option:getPercentage()
			))
			:wikitext('&nbsp;')
	end
	
	return vzn
end

function Poll:renderLegend()
	local legend = mw.html.create('div')
		:css('margin-top', '3px')
		:css('display', 'flex')
		:css('justify-content', 'center')
	local centered = legend:tag('div')
	for option in self:iterateOptions() do
		centered:node(option:renderLegendRow())
	end
	return legend
end

function Poll:hasLineBreaks()
	-- Try to auto-detect whether we should have line breaks
	if self.lineBreak then
		return yesno(self.lineBreak) or true
	end
	local nOptions = #self.options
	if nOptions > 3 then
		return true
	end
	local wordCount = 0
	for option in self:iterateOptions() do
		wordCount = wordCount + mw.ustring.len(option.text)
	end
	if nOptions == 3 then
		return wordCount >= 12
	else
		return wordCount >= 15
	end
end

function Poll:renderButtons()
	local hasBreaks = self:hasLineBreaks()
	local buttons = mw.html.create('div')
		:css('margin-top', '5px')
		:css('display', 'flex')
		:css('justify-content', 'center')
	local centered = buttons:tag('div')
	if not hasBreaks then
		centered:css('text-align', 'center')
	end
	for option in self:iterateOptions() do
		local button
		if hasBreaks then
			button = centered:tag('div')
				:css('margin', '4px 0')
		else
			button = centered
		end
		button:node(option:renderButton())
	end
	return buttons
end

function Poll:renderWarning(s)
	local warning = mw.html.create('div')
	warning
		:css('line-height', '90%')
		:css('width', '100%')
		:css('margin-top', '5px')
		:css('text-align', 'center')
		:css('color', 'red')
		:css('font-size', '85%')
		:wikitext(s)
	return warning
end

function Poll:hasMinimumVoteCount()
	return self.voteTotal >= self.minimum
end

function Poll:isOpen()
	if self.expiry then
		return self.getUnixDate() < self.getUnixDate(self.expiry)
	else
		return true
	end
end

function Poll:__tostring()
	local root = mw.html.create('div')
		:css('width', '270px')
		:css('float', 'right')
		:css('clear', 'right')
		:css('background', 'none')
		:css('margin-bottom', '10px')
		:css('margin-left', '10px')
		:addClass('signpost-sidebar')

	root:node(self:renderHeader())
	root:node(self:renderQuestion())

	-- Visualization and legend
	if self:hasMinimumVoteCount() then
		root:node(self:renderVisualization())
		root:node(self:renderLegend())
	else
		root:node(self:renderWarning(self:message(
			'not-enough-votes-warning',
			{self.minimum - self.voteTotal},
			true
		)))
	end

	-- Buttons
	if self:isOpen() then
		root:node(self:renderButtons())
	else
		root:node(self:renderWarning(self:message('poll-closed-warning')))
	end

	return tostring(root)
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._main(args, cfg, frame)
	return tostring(Poll.new(args, cfg, frame))
end

function p.main(frame, cfg)
	cfg = cfg or mw.loadData(CONFIG_MODULE)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = cfg.wrappers
	})
	return p._main(args, cfg, frame)
end

return p