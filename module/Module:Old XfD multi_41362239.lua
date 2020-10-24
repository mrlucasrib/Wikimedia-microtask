local yesno = require('Module:Yesno')
local mMessageBox = require('Module:Message box')
local TEMPLATE_PAGE = 'Template:Old XfD multi'

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

local function exists(page)
	local success, exists = pcall(function ()
		local title = mw.title.new(page)
		return title.exists
	end)
	return success and exists
end

local function getAfdPage(page)
	if page and mw.title.new(page) then
		if mw.title.new(page).namespace ~= 0 then
			return page
		else
			return 'Wikipedia:Articles for deletion/' .. page
		end
	else return nil
	end
end

local function getVfdPage(page)
	if page and mw.title.new(page) then
		if mw.title.new(page).rootPageTitle.fullText == 'Wikipedia:Votes for deletion' then
			return page
		else
			return 'Wikipedia:Votes for deletion/' .. page
		end
	else return nil
	end
end

local function makeWikilink(page, display)
	display = display or 'discussion'
	if page then
		return string.format('[[%s|%s]]', page, display)
	else
		return display --probably a bad title
	end
end

local function makeUrlLink(page, display)
	display = display or 'discussion'
	return string.format('[%s %s]', page, display)
end

local function pageTypeName(title)
	local display = mw.ustring.lower(title.subjectNsText)
	local pageTypes = {
		[''] = 'article',
		['user'] = 'user page',
		['wikipedia'] = 'project page',
		['mediawiki'] = 'interface page',
		['help'] = 'help page'
	}
	if pageTypes[display] then display = pageTypes[display] end
	return display
end

local function cleanupTitle(title)
	if not title then return title end
	title = mw.uri.decode(title, 'PATH')
	title = string.gsub(title, '|.*', '')
	title = string.gsub(title, '[%[%]{}]', '')
	return title
end

-------------------------------------------------------------------------------
-- OldAfdMulti class
-------------------------------------------------------------------------------

local OldAfdMulti = {}
OldAfdMulti.__index = OldAfdMulti

function OldAfdMulti.new(args)
	local self = setmetatable({}, OldAfdMulti)
	self.currentTitle = mw.title.getCurrentTitle()

	-- Preprocess the row args for easier looping.
	self.rowData = {}
	for k, v in pairs(args) do
		if type(k) == 'string' then
			local prefix, num = k:match('^(.-)([1-9][0-9]*)$')
			if prefix and num then
				num = tonumber(num)
				if prefix == 'result' or
					prefix == 'date' or
					prefix == 'page' or
					prefix == 'link' or
					prefix == 'caption' or
					prefix == 'votepage' or
					prefix == 'merge'
				then
					self.rowData[num] = self.rowData[num] or {}
					self.rowData[num][prefix] = v
					if v and v ~= '' and prefix=='merge' then
						self.isMerge = true
					end
				end
			end
		end
	end
	-- Set aliases for parameters ending in "1".
	if self.rowData[1] then
		self.rowData[1].result = self.rowData[1].result or args.result
		self.rowData[1].date = self.rowData[1].date or args.date
		self.rowData[1].page = self.rowData[1].page or args.page
		self.rowData[1].votepage = self.rowData[1].votepage or args.votepage
		self.rowData[1].link = self.rowData[1].link or args.link
		self.rowData[1].caption = self.rowData[1].caption or args.caption
		self.rowData[1].merge = self.rowData[1].merge or args.merge
	elseif args.result or
		args.date or
		args.page or
		args.votepage or
		args.link or
		args.caption or
		args.merge
	then
		self.rowData[1] = {
			result = args.result,
			date = args.date,
			page = args.page,
			votepage = args.votepage,
			link = args.link,
			caption = args.caption,
			merge = args.merge
		}
	end
	-- Remove any gaps in the array we made.
	local function compressSparseArray(t)
		local ret, nums = {}, {}
		for num, data in pairs(t) do
			nums[#nums + 1] = num
		end
		table.sort(nums)
		for i, num in ipairs(nums) do
			ret[i] = t[num]
		end
		return ret
	end
	self.rowData = compressSparseArray(self.rowData)
	-- Set aliases that apply to all of the data tables.
	for i, data in ipairs(self.rowData) do
		data.page = data.page or data.votepage
		data.page = cleanupTitle(data.page)
		data.votepage = nil
	end

	-- Set collapsedness
	self.collapse = tonumber(args.collapse)
	if not self.collapse then
		self.collapse = yesno(args.collapse)
	end

	-- Set other properties
	self.isNumbered = yesno(args.numbered)
	self.isSmall = yesno(args.small)
	self.pageType = args.type or pageTypeName(self.currentTitle)
	if args.merge and args.merge ~= '' then
		self.isMerge = true
	end
	
	return self
end

function OldAfdMulti:renderResult(result)
	return result or "'''Keep'''"
end

function OldAfdMulti:renderDate(date)
	if date then
		return date
	else
		self.hasMissingDate = true
		return string.format(
			'<sup>%s[[%s|date missing]]%s</sup>',
			mw.text.nowiki('['),
			TEMPLATE_PAGE,
			mw.text.nowiki(']')
		)
	end
end

function OldAfdMulti:renderPageText(linkFunc, page, caption)
	return string.format(', see %s.', linkFunc(page, caption))
end

function OldAfdMulti:renderRow(result, date, link, merge)
	local result = self:renderResult(result)
	local date = self:renderDate(date)
	local mergeText = ''
	if merge and merge ~= '' then
		mergeText = string.format('Merge with [[:%s]]: ', merge)
	end
	if link then
		return string.format('%s%s, %s, see %s.', mergeText, result, date, link)
	else
		return string.format('%s%s, %s', mergeText, result, date)
	end
end

function OldAfdMulti:renderFirstRow(data)
	local link
	if data.link then
		link = makeUrlLink(data.link, data.caption)
	else
		local page = data.page or self.currentTitle.text
		link = makeWikilink(getAfdPage(page), data.caption)
	end
	return self:renderRow(data.result, data.date, link, data.merge)
end

function OldAfdMulti:renderSubsequentRow(data)
	local link
	if data.page then
		link = makeWikilink(getAfdPage(data.page), data.caption)
	elseif data.link then
		link = makeUrlLink(data.link, data.caption)
	end
	return self:renderRow(data.result, data.date, link, data.merge)
end

function OldAfdMulti:renderRows()
	local root = mw.html.create()
	local nRows = #self.rowData
	local i = nRows

	local nCollapsedRows
	if type(self.collapse) == 'number' then
		nCollapsedRows = self.collapse
	elseif self.collapse then
		nCollapsedRows = nRows
	else
		nCollapsedRows = 0
	end
	local hasNormalRows = nRows - nCollapsedRows > 0

	local function makeList(isCollapsed, header)
		local tableRoot = root:tag('table')
		tableRoot
			:addClass(isCollapsed and 'collapsible collapsed' or nil)
			:css('width', '100%')
			:css('background-color', '#f8eaba')
		if header then
			tableRoot
				:tag('tr')
					:tag('th')
						:wikitext(header)
		end
		return tableRoot
			:tag('tr')
				:tag('td')
					:tag(self.isNumbered and 'ol' or 'ul')
	end

	local function renderRow(html, method, data)
		html
			:tag('li')
				:attr('value', self.isNumbered and i or nil)
				:wikitext(self[method](self, data))
	end

	-- Render normal rows
	if hasNormalRows then
		local normalList = makeList(false)
		while i > 1 and i > nCollapsedRows do
			renderRow(normalList, 'renderSubsequentRow', self.rowData[i])
			i = i - 1
		end
		if i == 1 and i > nCollapsedRows then
			renderRow(normalList, 'renderFirstRow', self.rowData[i])
			i = i - 1
		end
	end

	-- Render collapsed rows
	if nCollapsedRows > 0 then
		local header
		if hasNormalRows then
			header = 'Older deletion discussions:'
		elseif nRows > 1 then
			header = 'Deletion discussions:'
		else
			header = 'Deletion discussion:'
		end
		local collapsedList = makeList(true, header)
		while i > 1 do
			renderRow(collapsedList, 'renderSubsequentRow', self.rowData[i])
			i = i - 1
		end
		renderRow(collapsedList, 'renderFirstRow', self.rowData[i])
	end

	return tostring(root)
end

function OldAfdMulti:renderFirstRowOnly()
	local data = self.rowData[1] or {}
	local caption = data.caption or 'the discussion'
	local link
	if data.link then
		link = makeUrlLink(data.link, caption)
	else
		local page = data.page or self.currentTitle.text
		if exists(getAfdPage(page)) then
			link = makeWikilink(getAfdPage(page), caption)
		elseif exists(getVfdPage(page)) then
			link = makeWikilink(getVfdPage(page), caption)
		else
			link = caption -- Make this an error?
		end
	end
	local result = self:renderResult(data.result or "'''keep'''")
	return string.format(
		'The result of %s was %s.',
		link, result
	)
end

function OldAfdMulti:renderBannerText()
	local nRows = #self.rowData
	local ret = {}
	if self.isMerge then
			if nRows < 1 or not self.rowData[1].date then
			ret[#ret + 1] = string.format(
				'This %s was considered for [[Wikipedia:Deletion policy#Merging|merging]] with %s.',
				self.pageType,
				self.rowData[1].merge
			)
		elseif nRows == 1 and self.rowData[1].date then
			ret[#ret + 1] = string.format(
				'This %s was considered for [[Wikipedia:Deletion policy#Merging|merging]] with [[:%s]] on %s.',
				self.pageType,
				self.rowData[1].merge,
				self.rowData[1].date
			)
		else
			ret[#ret + 1] = string.format(
				'This %s was nominated for [[Wikipedia:Deletion policy|deletion]] or considered for [[Wikipedia:Deletion policy#Merging|merging]].',
				self.pageType
			)
		end
	else
		if nRows < 1 or not self.rowData[1].date then
			ret[#ret + 1] = string.format(
				'This %s was previously nominated for [[Wikipedia:Deletion policy|deletion]].',
				self.pageType
			)
		elseif nRows == 1 and self.rowData[1].date then
			ret[#ret + 1] = string.format(
				'This %s was nominated for [[Wikipedia:Deletion policy|deletion]] on %s.',
				self.pageType,
				self.rowData[1].date
			)
		else
			ret[#ret + 1] = string.format(
				'This %s was nominated for [[Wikipedia:Deletion policy|deletion]].',
				self.pageType
			)
		end
	end
	
	if nRows > 1 then
		ret[#ret + 1] = ' '
		if self.isSmall then
			ret[#ret + 1] = 'Review prior discussions if considering re-nomination:'
		else
			ret[#ret + 1] = 'Please review the prior discussions if you are considering re-nomination:'
		end
		ret[#ret + 1] = '\n'
		ret[#ret + 1] = self:renderRows()
	else
		ret[#ret + 1] = ' '
		ret[#ret + 1] = self:renderFirstRowOnly()
	end
	return table.concat(ret)
end

function OldAfdMulti:renderBanner()
	return mMessageBox.main('tmbox', {
		small = self.isSmall,
		type = 'notice',
		image = '[[File:Clipboard.svg|35px|Articles for deletion]]',
		smallimage = 'none',
		text = self:renderBannerText()
	})
end

function OldAfdMulti:renderTrackingCategories()
	local ret = {}
	if self.hasMissingDate and self.currentTitle.isTalkPage then
		ret[#ret + 1] = '[[Category:Old XfD multi templates with errors]]'
	end
	return table.concat(ret)
end

function OldAfdMulti:__tostring()
	return self:renderBanner() .. self:renderTrackingCategories()
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._main(args)
	local afd = OldAfdMulti.new(args)
	return tostring(afd)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = TEMPLATE_PAGE
	})
	return p._main(args)
end

return p