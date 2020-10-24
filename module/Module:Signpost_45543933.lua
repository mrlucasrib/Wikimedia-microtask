local INDEX_MODULE = 'Module:Signpost/index'
local lang = mw.language.getContentLanguage()
local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType
local checkTypeForNamedArg = libraryUtil.checkTypeForNamedArg

--------------------------------------------------------------------------------
-- Article class
--------------------------------------------------------------------------------

local Article = {}
Article.__index = Article

Article.rowMethods = {
	page = 'getPage',
	fullpage = 'getFullPage',
	date = 'getDate',
	title = 'getTitle',
	subpage = 'getSubpage',
}

function Article.new(data)
	local self = setmetatable({}, Article)
	self.data = data
	self.matchedTags = {}
	return self
end

function Article:getSortKey()
	return self.data.sortKey
end

function Article:getPage()
	return self.data.page
end

function Article:getDate()
	return self.data.date
end

function Article:getTitle()
	return self.data.title
end

function Article:getSubpage()
	return self.data.subpage
end

function Article:getFragment()
	local fragment = self:getMatchedTags()[1]
	if fragment then
		return mw.uri.anchorEncode(fragment)
	end
end

function Article:getFullPage()
	local page = self:getPage()
	local fragment = self:getFragment()
	if fragment then
		return page .. '#' .. fragment
	else
		return page
	end
end

function Article:addMatchedTag(tag)
	table.insert(self.matchedTags, tag)
end

function Article:getMatchedTags()
	table.sort(self.matchedTags)
	return self.matchedTags
end

function Article:hasAllTags(t)
	local tags = self.data.tags
	for i, testTag in ipairs(t) do
		local hasTag = false
		for j, tag in ipairs(tags) do
			if tag == testTag then
				hasTag = true
			end
		end
		if not hasTag then
			return false
		end
	end
	return true
end

function Article:makeRowArgs()
	local methods = self.rowMethods
	local args = setmetatable({}, {
		__index = function (t, key)
			local method = methods[key]
			if method then
				return self[method](self)
			else
				error(string.format(
					"'%s' is not a valid parameter name",
					key
				), 2)
			end
		end
	})
	return args
end

function Article:renderTemplate(template, frame)
	frame = frame or mw.getCurrentFrame()
	local args = {}
	for key, method in pairs(self.rowMethods) do
		args[key] = self[method](self)
	end
	return frame:expandTemplate{
		title = template,
		args = args
	}
end

function Article:renderFormat(format)
	local args = self:makeRowArgs(articleObj)
	local ret = format:gsub('(%${(%a+)})', function (match, key)
		return args[key] or match
	end)
	return ret
end

--------------------------------------------------------------------------------
-- List class
--------------------------------------------------------------------------------

local List = {}
List.__index = List

function List.new(options)
	checkType('List.new', 1, options, 'table')
	checkTypeForNamedArg('List.new', 'args', options.args, 'table', true)
	local self = setmetatable({}, List)
	self.index = options.index or mw.loadData(INDEX_MODULE)
	self.frame = options.frame or mw.getCurrentFrame()
	local args = options.args or {}

	-- Set output formats
	if not options.suppressFormatErrors
		and args.rowtemplate
		and args.rowformat
	then
		error("you cannot use both the 'rowtemplate' and the 'rowformat' arguments", 2)
	elseif not options.suppressFormatErrors
		and not args.rowtemplate
		and not args.rowformat
	then
		error("you must use either the 'rowtemplate' or the 'rowformat' argument", 2)
	else
		self.rowtemplate = args.rowtemplate
		self.rowformat = args.rowformat
	end
	if args.rowseparator == 'newline' then
		self.rowseparator = '\n'
	else
		self.rowseparator = args.rowseparator
	end
	self.noarticles = args.noarticles
	
	-- Get article objects, filtered by page, date and tag, and sort them.
	if args.page then
		self.articles = { self:getPageArticle(args.page) }
	elseif args.date then
		self.articles = self:getDateArticles(args.date)
	else
		self.articles = self:getTagArticles(args.tags, args.tagmatch)
		if not self.articles then
			self.articles = self:getAllArticles()
		end
		self:filterArticlesByDate(args.startdate, args.enddate)
	end
	self:sortArticles(args.sortdir, args.sortfield)
	if (args.limit and tonumber(args.limit)) or (args.start and tonumber(args.start)) then
		self:limitArticleCount(tonumber(args.start), tonumber(args.limit))
	end
	return self
end

-- Static methods

function List.normalizeDate(date)
	if not date then
		return nil
	end
	return lang:formatDate('Y-m-d', date)
end

-- Normal methods

function List:parseTagString(s)
	local ret = {}

	-- Remove whitespace and punctuation
	for i, tag in ipairs(mw.text.split(s, ',')) do
		tag = mw.ustring.gsub(tag, '[%s%p]', '')
		if tag ~= '' then
			tag = mw.ustring.lower(tag)
			table.insert(ret, tag)
		end
	end

	-- Resolve aliases
	for i, tag in ipairs(ret) do
		ret[i] = self.index.aliases[tag] or tag
	end
	
	-- Remove duplicates
	local function removeDuplicates(t)
		local vals, ret = {}, {}
		for i, val in ipairs(t) do
			vals[val] = true
		end
		for val in pairs(vals) do
			table.insert(ret, val)
		end
		table.sort(ret)
		return ret
	end
	ret = removeDuplicates(ret)

	return ret
end

function List:getPageArticle(page)
	local data = self.index.pages[page]
	if data then
		return Article.new(data)
	end
end

function List:getDateArticles(date)
	date = self.normalizeDate(date)
	local dates = self.index.dates[date]
	local ret = {}
	if dates then
		for i, data in ipairs(dates) do
			ret[i] = Article.new(data)
		end
	end
	return ret
end

function List:getTagArticles(s, tagMatch)
	if not s then
		return nil
	end
	local tagIndex = self.index.tags
	local ret, pages = {}, {}
	local tags = self:parseTagString(s)
	for i, tag in ipairs(tags) do
		local dataArray = tagIndex[tag]
		if dataArray then
			for i, data in ipairs(dataArray) do
				local obj = Article.new(data)
				-- Make sure we only have one object per page.
				if pages[obj:getPage()] then
					obj = pages[obj:getPage()]
				else
					pages[obj:getPage()] = obj
				end
				-- Record which tag we matched.
				obj:addMatchedTag(tag)
			end
		end
	end
	for page, obj in pairs(pages) do
		if not tagMatch
			or tagMatch == 'any'
			or tagMatch == 'all' and obj:hasAllTags(tags)
		then
			table.insert(ret, obj)
		end
	end
	return ret
end

function List:getAllArticles()
	local ret = {}
	for i, data in ipairs(self.index.list) do
		ret[i] = Article.new(data)
	end
	return ret
end

function List:getArticleCount()
	return #self.articles
end

function List:filterArticlesByDate(startDate, endDate)
	startDate = self.normalizeDate(startDate) or '2005-01-01'
	endDate = self.normalizeDate(endDate) or lang:formatDate('Y-m-d')
	local ret = {}
	for i, article in ipairs(self.articles) do
		local date = article:getDate()
		if startDate <= date and date <= endDate then
			table.insert(ret, article)
		end
	end
	self.articles = ret
end

function List:sortArticles(direction, field)
	local accessor
	if not field or field == 'date' then
		accessor = function (article) return article:getSortKey() end
	elseif field == 'page' then
		accessor = function (article) return article:getPage() end
	elseif field == 'title' then
		accessor = function (article) return article:getTitle() end
	else
		error(string.format("'%s' is not a valid sort field", field), 2)
	end
	local sortFunc
	if not direction or direction == 'ascending' then
		sortFunc = function (a, b)
			return accessor(a) < accessor(b)
		end
	elseif direction == 'descending' then
		sortFunc = function (a, b)
			return accessor(a) > accessor(b)
		end
	else
		error(string.format("'%s' is not a valid sort direction", direction), 2)
	end
	table.sort(self.articles, sortFunc)
end

function List:limitArticleCount(start, limit) 
	local ret = {}
	for i, article in ipairs(self.articles) do 
		if limit and #ret >= limit then
			break
		end
		if not start or i > start then
			table.insert(ret, article)
		end
	end
	self.articles = ret
end

function List:renderRow(articleObj)
	if self.rowtemplate then
		return articleObj:renderTemplate(self.rowtemplate, self.frame)
	elseif self.rowformat then
		return articleObj:renderFormat(self.rowformat)
	else
		error('neither rowtemplate nor rowformat were specified')
	end
end

function List:__tostring()
	local ret = {}
	for i, obj in ipairs(self.articles) do
		table.insert(ret, self:renderRow(obj))
	end
	if #ret < 1 then
		return self.noarticles
			or '<span style="font-color: red;">' ..
			'No articles found for the arguments specified</span>'
	else
		return table.concat(ret, self.rowseparator)
	end
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

local function makeInvokeFunc(func)
	return function (frame, index)
		local args = require('Module:Arguments').getArgs(frame, {
			parentOnly = true
		})
		return func(args, index)
	end
end

function p._exportClasses()
	return {
		Article = Article,
		List = List
	}
end

function p._count(args, index)
	local list = List.new{
		args = args,
		index = index,
		suppressFormatErrors = true
	}
	return list:getArticleCount()
end

p.count = makeInvokeFunc(p._count)

function p._main(args, index)
	return tostring(List.new{args = args, index = index})
end

p.main = makeInvokeFunc(p._main)

return p