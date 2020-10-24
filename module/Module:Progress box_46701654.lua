-- This module implements [[Template:Progress box]]

local makePurgeLink = require('Module:Purge')._main
local lang = mw.language.getContentLanguage()
local CONFIG_MODULE = 'Module:Progress box/config'

-------------------------------------------------------------------------------
-- Message mixin
-- 
-- This function is mixed into all of the other classes
-------------------------------------------------------------------------------

local function message(self, key, ...)
	local msg = self._cfg[key]
	if not msg then
		error(string.format("no message found with key '%s'", tostring(key)), 2)
	end
	if select('#', ...) > 0 then
		return mw.message.newRawMessage(msg, ...):plain()
	else
		return msg
	end
end

-------------------------------------------------------------------------------
-- Category class
-------------------------------------------------------------------------------

local Category = {}
Category.__index = Category
Category.message = message

function Category.new(data)
	local self = setmetatable({}, Category)
	self._cfg = data.cfg
	self._whatToCount = data.whatToCount
	self:setCategory(data.category)
	return self
end

function Category:setCategory(category)
	self._category = category
end

function Category:getCategory()
	return self._category
end

function Category:makeCategoryLink(display)
	local cat = self:getCategory()
	display = display or cat
	return string.format('[[:Category:%s|%s]]', cat, display)
end

function Category:getCount()
	if not self._count then
		local counts = mw.site.stats.pagesInCategory(self:getCategory(), '*')
		self._count = counts[self._whatToCount or 'pages']
		if not self._count then
			error("the count type must be one of 'pages', 'subcats', 'files' or 'all'")
		end
	end
	return self._count
end

function Category:getFormattedCount()
	return lang:formatNum(self:getCount())
end

function Category:exists()
	return mw.title.makeTitle(14, self:getCategory()).exists
end

-------------------------------------------------------------------------------
-- DatedCategory class
-- Inherits from Category
-------------------------------------------------------------------------------

local DatedCategory = {}
DatedCategory.__index = DatedCategory
setmetatable(DatedCategory, Category)

function DatedCategory.new(data)
	local self = setmetatable(Category.new(data), {__index = DatedCategory})
	self._date = data.date
	self._dateFormat = data.dateFormat or self:message('date-format')
	self._formattedDate = self:formatDate(self._date)
	do
		local category = self:message(
			'dated-category-format',
			data.baseCategory,
			self._formattedDate,
			data.from or self:message('dated-category-format-from'),
			data.suffix or ''
		)
		category = category:match('^%s*(.-)%s*$') -- trim whitespace
		self:setCategory(category)
	end
	return self
end

function DatedCategory:formatDate(date)
	return lang:formatDate(self._dateFormat, date)
end

function DatedCategory:getDate()
	return self._date
end

function DatedCategory:getFormattedDate()
	return self._formattedDate
end

-------------------------------------------------------------------------------
-- ProgressBox class
-------------------------------------------------------------------------------

local ProgressBox = {}
ProgressBox.__index = ProgressBox
ProgressBox.message = message

function ProgressBox.new(args, cfg, title)
	local self = setmetatable({}, ProgressBox)

	-- Argument defaults
	args = args or {}
	self._cfg = cfg or mw.loadData(CONFIG_MODULE)
	self._title = title or mw.title.getCurrentTitle()

	-- Set data
	self._float = args.float or 'left'
	self._margin = args.float == 'none' and 'auto' or nil
	self._header = args[1]
	self._frame = mw.getCurrentFrame()

	-- Make the base category object
	if not args[1] then
		error('no base category specified', 3)
	end
	self._baseCategoryObj = Category.new{
		cfg = self._cfg,
		category = args[1],
	}

	-- Make datedCategory objects
	self._datedCategories = {}
	do
		local cfg = self._cfg
		local baseCategory = args[2] or self._baseCategoryObj:getCategory()
		local whatToCount = args.count
		local from = args.from or self:message('dated-category-format-from')
		local suffix = args.suffix
		local currentDate = lang:formatDate('Y-m')
		local date = self:findEarliestCategoryDate()
		local dateFormat = self:message('date-format')
		while date <= currentDate do
			local datedCategoryObj = DatedCategory.new{
				cfg = cfg,
				baseCategory = baseCategory,
				whatToCount = whatToCount,
				from = from,
				suffix = suffix,
				date = date,
				dateFormat = dateFormat,
			}
			if datedCategoryObj:getCount() > 0 then
				table.insert(self._datedCategories, datedCategoryObj)
			end
			date = ProgressBox.incrementDate(date)
		end
	end

	-- Make all-article category object
	do
		local allCategory
		if args[3] then
			allCategory = args[3]
		else
			allCategory = self:message(
				'all-articles-category-format',
				self._baseCategoryObj:getCategory()
			)
			allCategory = self._frame:preprocess(allCategory)
		end
		self._allCategoryObj = Category.new{
			cfg = self._cfg,
			category = allCategory,
		}
	end

	return self
end

-- Increments a date in the format YYYY-MM
function ProgressBox.incrementDate(date)
	local year, month = date:match('^(%d%d%d%d)%-(%d%d)$')
	year = tonumber(year)
	month = tonumber(month)
	if not year or not month then
		error(string.format("error parsing date '%s'", tostring(date)), 2)
	end
	month = month + 1
	if month > 12 then
		month = 1
		year = year + 1
	end
	return string.format('%04d-%02d', year, month)
end

function ProgressBox:findEarliestCategoryDate()
	return self:message('start-date')
end

function ProgressBox:isCollapsed()
	return self._title.namespace ~= 10 -- is not in template namespace
end

function ProgressBox:makeTotalLabel()
	local display = self:message('all-articles-label')
	if self._allCategoryObj:exists() then
		return self._allCategoryObj:makeCategoryLink(display)
	else
		return display
	end
end

function ProgressBox:getTotalCount()
	local count = 0
	for i, obj in ipairs(self._datedCategories) do
		count = count + obj:getCount()
	end
	count = count + self._baseCategoryObj:getCount()
	return count
end

function ProgressBox:getFormattedTotalCount()
	return lang:formatNum(self:getTotalCount())
end

function ProgressBox:__tostring()
	data = data or {}
	local root = mw.html.create('table')
	
	-- Base classes and styles
	root
		:addClass('infobox')
		:css('float', self._float)
		:css('clear', self._float)
		:css('margin', self._margin)
		:css('width', '22em')

	-- Header row
	root:tag('tr'):tag('th')
		:attr('colspan', 2)
		:addClass('navbox-title')
		:css('padding', '0.2em')
		:css('font-size', '125%')
		:wikitext(self._header)

	-- Refresh row
	root:tag('tr'):tag('td')
		:attr('colspan', 2)
		:css('text-align', 'center')
		:wikitext(makePurgeLink{self:message('purge-link-display')})

	-- Subtotals
	local subtotalTable = root
		:tag('tr')
			:tag('td')
				:attr('colspan', 2)
				:css('padding', 0)
				:tag('table')
					:addClass('collapsible')
					:addClass(self:isCollapsed() and 'collapsed' or nil)
					:css('width', '100%')
					:css('margin', 0)
	subtotalTable
		:tag('tr')
			:tag('th')
				:attr('colspan', 2)
				:wikitext(self:message('subtotal-heading'))
	for i, datedCategoryObj in ipairs(self._datedCategories) do
		subtotalTable
			:tag('tr')
				:tag('td')
					:wikitext(datedCategoryObj:makeCategoryLink(
						datedCategoryObj:getFormattedDate()
					))
					:done()
				:tag('td')
					:css('text-align', 'right')
					:wikitext(datedCategoryObj:getFormattedCount())
	end

	-- Undated articles
	subtotalTable
		:tag('tr')
			:tag('td')
				:wikitext(self._baseCategoryObj:makeCategoryLink(
					self:message('undated-articles-label')
				))
				:done()
			:tag('td')
				:css('text-align', 'right')
				:wikitext(self._baseCategoryObj:getFormattedCount())

	-- Total
	root
		:tag('tr')
			:css('font-size', '110%')
			:tag('td')
				:wikitext(string.format("'''%s'''", self:makeTotalLabel()))
				:done()
			:tag('td')
				:css('text-align', 'right')
				:wikitext(string.format(
					"'''%s'''",
					self:getFormattedTotalCount()
				))

	return tostring(root)
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._exportClasses()
	return {
		Category = Category,
		DatedCategory = DatedCategory,
		ProgressBox = ProgressBox,
	}
end

function p._main(args, cfg, title)
	return tostring(ProgressBox.new(args, cfg, title))
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Progress box'
	})
	return p._main(args)
end

return p