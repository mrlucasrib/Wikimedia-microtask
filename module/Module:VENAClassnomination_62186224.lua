-- This module implements {{VENAClassnomination}}.

local lang = mw.language.getContentLanguage()

-------------------------------------------------------------------------------
-- Output template
-------------------------------------------------------------------------------

-- This template contains the final output of the module. Parameters like
-- ${PARAMETER_NAME} are substituted with the results of the output template
-- parameter functions below.

local OUTPUT_TEMPLATE = [=[
${MONTH_AND_YEAR}
* ${HEADING}
* ${COMMENT}
<small>${STATUS} by ${AUTHORS}. ${NOMINATED} at ~~~~~.</small>

:* <!-- REPLACE THIS LINE TO WRITE FIRST COMMENT, KEEPING   :*   -->

<!--Please do not write below this line or remove this line. Place comments above this line.-->]=]

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

-- Creates a formatted error message that can be used with substitution.
local function formatError(msg)
	return string.format('{{error|1=%s}}', msg)
end

-- Creates a boilerplate error message for invalid titles.
local function formatInvalidTitleError(page, pageType)
	local msg = string.format(
		'"%s" is not a valid %s; check for bad characters',
		page, pageType
	)
	return formatError(msg)
end

-- Same as {{ROOTPAGENAME}}. If the page is an invalid title, returns nil.
local function getRootPageText(page)
	local title = mw.title.new(page)
	if title then
		return title.rootPageTitle.text
	end
end

-- Normalize positional parameters for a template invocation. If any of the
-- parameters contain equals signs, the parameters are all prefixed with
-- numbers.
local function normalizeTemplateParameters(params)
	local ret = {}
	local hasEquals = false
	for i, param in ipairs(params) do
		if param:find('=') then
			hasEquals = true
			break
		end
	end
	if hasEquals then
		for i, param in ipairs(params) do
			ret[i] = string.format('%d=%s', i, param)
		end
	else
		for i, param in ipairs(params) do
			ret[i] = param
		end
	end
	return ret
end

-- Makes a link to a user's user page and talk page, like found in a standard
-- signature.
local function makeUserLinks(user)
	return string.format(
		'[[User:%s|%s]] ([[User talk:%s|talk]])',
		user, user, user
	)
end

-- Returns an array of authors. If the user didn't specify any authors, the
-- first one is the result of {{REVISIONUSER}}.
local function getNormalisedAuthors(data)
	local authors = {}
	for i, author in ipairs(data.authors) do
		authors[i] = author
	end
	authors[1] = authors[1] or data.revisionUser
	return authors
end

-- Removes gaps from sparse arrays. This is used to process numbered arguments
-- like author2 and ALT4.
local compressSparseArray = require("Module:TableTools").compressSparseArray

-- Splits numbered arguments by their prefixes. A table of arguments like this:
--    {foo1 = "foo1", foo2 = "foo2", bar3 = "bar3"}
-- Would be turned into this:
--    {foo = {[1] = "foo1", [2] = "foo2"}, bar = {[3] = "bar3"}}
-- Note that the subtables of the returned tables are not normal arrays, but
-- sparse arrays (there can be gaps between values).
local function splitByPrefix(args)
	local ret = {}
	for key, val in pairs(args) do
		if type(key) == 'string' then
			local prefix, num = key:match('^(.-)([1-9][0-9]*)$')
			if prefix then
				num = tonumber(num)
				ret[prefix] = ret[prefix] or {}
				ret[prefix][num] = val
			end
		end
	end
	return ret
end

-- Returns an array of numbered arguments with the given prefixes. Earlier
-- prefixes have precedence, and args[prefix] will overwrite args[prefix .. 1].
-- For example, for this arguments table:
--   {
--      author = "author",
--      author1 = "author1",
--      author2 = "author2,
--      creator2 = "creator2"
--   }
-- The function call getPrefixedArgs(args, splitArgs, {'creator', 'author'})
-- will produce:
--   {"author", "creator2"}
--
-- Parameters:
-- args - the table of arguments specified by the user
-- splitArgs - the table of arguments as processed by splitByPrefix
-- prefixes - an array of prefixes
local function getPrefixedArgs(args, splitArgs, prefixes)
	local ret = {}
	for i, prefix in ipairs(prefixes) do
		if splitArgs[prefix] then
			for num, val in pairs(splitArgs[prefix]) do
				if not ret[num] then
					ret[num] = val
				end
			end
		end
	end
	-- Allow prefix to overwrite prefix1.
	for _, prefix in ipairs(prefixes) do
		local val = args[prefix]
		if val then
			ret[1] = val
			break
		end
	end
	return compressSparseArray(ret)
end

-------------------------------------------------------------------------------
-- Output template parameter functions
-------------------------------------------------------------------------------

-- The results of these functions are substituted into parameters in the
-- output template. The parameters look like ${PARAMETER_NAME}. Trying to use
-- a parameter that doesn't have a function defined here will result in an
-- error.
--
-- The functions take a data table as a single argument. This table contains
-- the following fields:
-- * errors - a table of formatted error messages that were found when
--     processing the input.
-- * args - the table of arguments supplied by the user.
-- * articles - an array of the article names found in the arguments.
-- * authors - an array of the expanders/creators/writers/authors found in the
--     arguments.
-- * revisionUser - the user that last edited the page. As this module is only
--     substitited, this is always the current user.
-- * alts - an array of the ALT hooks found in the arguments.
-- * title - the mw.title object for the current page.
--
-- Template parameter functions should return a string, false, or nil.
-- Functions returning false or nil will be treated as outputting the empty
-- string "".

local params = {}

-- Renders any errors that were found when processing the input.
function params.INPUT_ERRORS(data)
	local nErrors = #data.errors
	if nErrors > 1 then
		return '\n* ' .. table.concat(data.errors, '\n* ')
	elseif nErrors == 1 then
		return '\n' .. data.errors[1]
	end
end

-- The current month and year, e.g. "March 2015".
function params.MONTH_AND_YEAR()
	return lang:formatDate('F Y')
end

-- The contents of the heading.
function params.HEADING(data)
	return table.concat(data.articles, ', ')
end

-- The current subpage name.
function params.NOM_SUBPAGE(data)
	return data.title.subpageText
end

-- Other arguments for the nompage link template, separated by pipes.
function params.NOMPAGE_LINK_ARGS(data)
	local vals = normalizeTemplateParameters(data.articles)
	return table.concat(vals, '|')
end

-- A comment.
function params.COMMENT(data)
	if data.args.comment then
		return "\n:* ''Comment'': " .. data.args.comment
	end
end

-- The status of the article when it was nominated.
function params.STATUS(data)
	local status = data.args.status
	status = status and status:lower()

	-- C
	if status == 'C' then
		return 'C-class'
	-- B
	elseif status == 'B' then
		return 'B-class'

	-- Improved to GA
	elseif status == 'ga' then
		return 'Good Article'

	-- Default
	else
		return 'unknown'
	end
end	

-- A list of the authors, with user and user talk links.
function params.AUTHORS(data)
	local authors = getNormalisedAuthors(data)
	for i, author in ipairs(authors) do
		authors[i] = makeUserLinks(author)
	end
	local separator = ', '
	local conjunction
	if #authors > 2 then
		conjunction = ', and '
	else
		conjunction = ' and '
	end
	return mw.text.listToText(authors, separator, conjunction)
end

-- Blurb for who the article was nominated by.
function params.NOMINATED(data)
	local authors = data.authors
	if #authors > 1 or authors[1] and authors[1] ~= data.revisionUser then
		return 'Nominated by ' .. makeUserLinks(data.revisionUser)
	else
		return 'Self-nominated'
	end
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._main(args, frame, title)
	-- Subst check.
	-- Check for the frame object as well to make debugging easier from the
	-- debug console.
	if frame and not mw.isSubsting() then
		return '<strong class="error">' ..
			'This template must be [[Wikipedia:Substitution|substituted]]. ' ..
			'Replace <code>{{VENAClassnomination}}</code> with ' ..
			'<code>{{subst:VENAClassnomination}}</code>.</strong>'
	end

	-- Set default arguments.
	frame = frame or mw.getCurrentFrame()
	title = title or mw.title.getCurrentTitle()

	-- Process data from the arguments.
	local splitArgs = splitByPrefix(args)
	local articles = getPrefixedArgs(args, splitArgs, {'article'})
	local authors = getPrefixedArgs(
		args,
		splitArgs,
		{'expander', 'creator', 'writer', 'author'}
	)
	local alts = getPrefixedArgs(args, splitArgs, {'ALT'})

	-- Input sanity checks.
	local errors = {}
	for i, article in ipairs(articles) do
		local articleTitle = mw.title.new(article)
		if not articleTitle then
			table.insert(errors, formatInvalidTitleError(
				article,
				'article name'
			))
			articles[i] = ''
		end
	end
	if #articles < 1 then
		articles[1] = title.subpageText
	end
	for i, author in ipairs(authors) do
		authors[i] = getRootPageText(author)
		if not authors[i] then
			table.insert(errors, formatInvalidTitleError(author, 'user name'))
			authors[i] = ''
		end
	end

	-- Substitute the parameters in the output template.
	local data = {
		errors = errors,
		args = args,
		articles = articles,
		authors = authors,
		revisionUser = frame:preprocess('{{safesubst:REVISIONUSER}}'),
		alts = alts,
		title = title,
	}
	local ret = OUTPUT_TEMPLATE:gsub('${([%u_]+)}', function (funcName)
		local func = params[funcName]
		if not func then
			error(string.format(
				"invalid parameter '${%s}' " ..
				"(no corresponding parameter function found)",
				funcName
			))
		end
		return func(data) or ''
	end)
	return ret
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:VENAClassnomination'
	})
	return p._main(args, frame)
end

return p