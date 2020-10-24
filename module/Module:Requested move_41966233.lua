-- This module implements {{requested move}}.

-- Load necessary modules
local getArgs = require('Module:Arguments').getArgs
local tableTools = require('Module:TableTools')
local yesno = require('Module:Yesno')
local mRedirect = require('Module:Redirect')

-- Set static values
local defaultNewPagename = '?' -- Name of new pages that haven't been specified

local p = {}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------
 
local function err(msg, numargs, reason, count)
	-- Generates a wikitext error message
	local commented = '<!-- {{subst:requested move|'
	if count ~= 1 then
	   commented = commented .. 'new1='
	end
	commented = commented .. numargs[1]['new']
	for i = 2,count do
		commented = commented .. string.format('|current%i=%s', i, (numargs[i]['current'] or ''))
		commented = commented .. string.format('|new%i=%s', i, (numargs[i]['new'] or ''))
	end
	if reason then 
	    commented = commented .. '|reason=' .. reason
	end
	commented = commented .. '}} -->'
	return string.format('{{error|%s}}', msg) .. commented
end

local function validateTitle(page, paramName, paramNum) 
	-- Validates a page name, and if it is valid, returns true and the title
	-- object for that page. If it is not valid, returns false and the
	-- appropriate error message.

	-- Check for a small subset of characters that cannot be used in MediaWiki
	-- titles. For the full set of restrictions, see
	-- [[Wikipedia:Page name#Technical restrictions and limitations]]. This is
	-- also covered by the invalid title check, but with this check we can give
	-- a more specific error message.
	local invalidChar = page:match('[#<>%[%]|{}]')
	if invalidChar then
		local msg = 'Invalid character "'
			.. invalidChar
			.. '" found in the "'
			.. paramName
			.. paramNum
			.. '" parameter'
		return false, msg
	end

	-- Get the title object. This also checks for invalid titles that aren't
	-- covered by the previous check.
	local titleObj = mw.title.new(page)
	if not titleObj then
		local msg = 'Invalid title detected in parameter "'
			.. paramName
			.. paramNum 
			.. '"; check for [[Wikipedia:Page name#'
			.. 'Technical restrictions and limitations|invalid characters]]'
		return false, msg
	end

	-- Check for interwiki links. Titles with interwikis make valid title
	-- objects, but cannot be created on the local wiki.
	local interwiki = titleObj.interwiki
	if interwiki and interwiki ~= '' then
		local msg = 'Invalid title detected in parameter "'
			.. paramName
			.. paramNum 
			.. '"; has [[Help:Interwiki linking|interwiki prefix]] "'
			.. titleObj.interwiki
			.. ':"'
		return false, msg
	end

	return true, titleObj
end

--------------------------------------------------------------------------------
-- Validate title entry point (used at [[Template:RMassist/core]])
--------------------------------------------------------------------------------
function p.validateTitle(frame)
	local value = frame.args[1]
	local validTitle, currentTitle = validateTitle(value or '', '1', '')
	if not validTitle then
		-- If invalid, the second parameter is the error message.
		local msg = currentTitle
		return msg
	end
	return 'yes'
end

--------------------------------------------------------------------------------
-- Main function
--------------------------------------------------------------------------------

function p.main(frame)
	----------------------------------------------------------------------------
	-- Initialise variables and preprocess the arguments
	----------------------------------------------------------------------------
	
	local args = getArgs(frame, {parentOnly = true})
	local title = mw.title.getCurrentTitle()

	--[[
	-- To iterate over the current1, new1, current2, new2, ... arguments
	-- we get an array of tables sorted by number and compressed so that
	-- it can be traversed with ipairs.	The table format looks like this:
	-- {
	--  {current = x, new = y, num = 1},
	--  {current = z, new = q, num = 2},
	--  ...
	-- }
	-- The "num" field is used to correctly preserve the number of the parameter
	-- that was used, in case users skip any numbers in the invocation.
	--
	-- The current1 parameter is a special case, as it does not need to be
	-- specified. To avoid clashes with later current parameters, we need to
	-- add it to the args table manually.
	--
	-- Also, we allow the first positional parameter to be an alias for the
	-- new1 parameter, so that the syntax for the old templates
	-- {{requested move}} and {{move-multi}} will both be supported.
	--
	-- The "multi" variable tracks whether we are using the syntax previously
	-- produced by {{requested move}}, or the syntax previously produced by
	-- {{move-multi}}. For the former, multi is false, and for the latter it is
	-- true.
	--]]
	if not args.current1 then
		args.current1 = title.subjectPageTitle.prefixedText
	end

	-- Find the first new page title, if specified, and keep a record of the
	-- prefix used to make it; the prefix will be used later to make error
	-- messages.
	local firstNewParam
	if args.new1 then
		firstNewParamPrefix = 'new'
	elseif args[1] then
		args.new1 = args[1]
		firstNewParamPrefix = ''
	else
		firstNewParamPrefix = ''
	end

	-- Build the sorted argument table.
	local argsByNum = {}
	for k, v in pairs(args) do
		k = tostring(k)
		local prefix, num = k:match('^(%l*)([1-9][0-9]*)$')
		if prefix == 'current' or prefix == 'new' then
			num = tonumber(num)
			local subtable = argsByNum[num] or {}
			subtable[prefix] = v
			subtable.num = num
			argsByNum[num] = subtable
		end
	end
	argsByNum = tableTools.compressSparseArray(argsByNum)

	-- Calculate the number of arguments and whether we are dealing with a
	-- multiple nomination.
	local argsByNumCount = #argsByNum
	local multi
	if argsByNumCount >= 2 then
		multi = true
	else
		multi = false
	end
	
	--[[
	-- Validate new params.
	-- This check ensures we don't have any absent new parameters, and that
	-- users haven't simply copied in the values from the documentation page.
	--]]
	if multi then
		for i, t in ipairs(argsByNum) do
			local new = t.new
			local num = t.num
			if not new or new == 'New title for page ' .. tostring(num) then
				argsByNum[i].new = defaultNewPagename
			end
		end
	else
		local new = argsByNum[1].new
		if not new or new == 'NewName' then
			argsByNum[1].new = defaultNewPagename
		end
	end

	----------------------------------------------------------------------------
	-- Error checks
	----------------------------------------------------------------------------
	
	-- Subst check
	if not mw.isSubsting() then
		local lb = mw.text.nowiki('{{')
		local rb = mw.text.nowiki('}}')
		local msg = '<strong class="error">'
			.. 'This template must be [[Wikipedia:Template substitution|substituted]];'
			.. ' replace %srequested move%s with %ssubst:requested move%s'
			.. '</strong>'
		msg = string.format(msg, lb, rb, lb, rb)
		return msg
	end
	
	-- Check we are on a talk page
	if not title.isTalkPage then
		local msg = '[[Template:Requested move]] must be used in a TALKSPACE, e.g., [[%s:%s]]'
		msg = string.format(msg, mw.site.namespaces[title.namespace].talk.name, title.text)
		return err(msg, argsByNum, args.reason, argsByNumCount)
	end
	
	-- Check the arguments
	local currentDupes, newDupes = {}, {}
	for i, t in ipairs(argsByNum) do
		local current = t.current
		local new = t.new
		local num = t.num
		local validCurrent
		local currentTitle
		local subjectSpace

		-- Check for invalid or missing currentn parameters
		-- This check must come first, as mw.title.new will give an error if
		-- it is given invalid input.
		if not current then
			local msg = '"current%d" parameter missing;'
				.. ' please add it or remove the "new%d" parameter'
			msg = string.format(msg, num, num)
			return err(msg, argsByNum, args.reason, argsByNumCount)
		end

		-- Get the currentn title object, and check for invalid titles. This check
		-- must come before the namespace and existence checks, as they will
		-- produce script errors if the title object doesn't exist.
		validCurrent, currentTitle = validateTitle(current, 'current', num)
		if not validCurrent then
			-- If invalid, the second parameter is the error message.
			local msg = currentTitle 
			return err(msg, argsByNum, args.reason, argsByNumCount)
		end

		-- Category namespace check
		subjectSpace = mw.site.namespaces[currentTitle.namespace].subject.id
		if subjectSpace == 14 then
			local msg = '[[Template:Requested move]] is not for categories,'
				.. ' see [[Wikipedia:Categories for discussion]]'
			return err(msg, argsByNum, args.reason, argsByNumCount)
		
		-- File namespace check
		elseif subjectSpace == 6 then
			local msg = '[[Template:Requested move]] is not for files;'
				.. ' see [[Wikipedia:Moving a page#Moving a file page]]'
				.. ' (use [[Template:Rename media]] instead)'
			return err(msg, argsByNum, args.reason, argsByNumCount)

		-- Draft and User namespace check
		elseif subjectSpace == 2 or subjectSpace == 118 then
			local msg = '[[Template:Requested move]] is not for moves from draft or user space.'
				.. '<br>If you would like to submit your draft for review, add <code>{{tlf|subst:submit}}</code>'
				    .. 'to the top of the page.'
				.. '<br>Otherwise, see [[Help:How to move a page]] for instructions.'
				.. '<br>If you cannot move it yourself, see [[Wikipedia:Requested moves#Requesting technical moves|Requesting technical moves]].'
			return err(msg, argsByNum, args.reason, argsByNumCount)
		end

		-- Request to move a single page must be placed on that page's talk, or the page it redirects to
		if not multi and args.current1 ~= title.subjectPageTitle.prefixedText then
			local idealpage = mw.title.new(args.current1).talkPageTitle
			local rtarget = mRedirect.getTarget(idealpage)
			if rtarget == title.prefixedText then
				multi = true
			else
				local msg = 'Request to move a single page must be placed on that page\'s talk or the page its talk redirects to'
				return err(msg, argsByNum, args.reason, argsByNumCount)
			end
		end

		-- Check for non-existent titles.
		if not currentTitle.exists then
			local msg = 'Must create [[:%s]] before requesting that it be moved'
			msg = string.format(msg, current)
			return err(msg, argsByNum, args.reason, argsByNumCount)
		end

		-- Check for duplicate current titles
		-- We know the id isn't zero because we have already checked for
		-- existence.
		local currentId = currentTitle.id
		if currentDupes[currentId] then
			local msg = 'Duplicate title detected ("'
				.. currentTitle.prefixedText
				.. '"); cannot move the same page to two different places'
			return err(msg, argsByNum, args.reason, argsByNumCount)
		else
			currentDupes[currentId] = true
		end

		-- Check for invalid new titles. This check must come before the
		-- duplicate title check for new titles, as it will produce a script
		-- error if the title object doesn't exist.
		local validNew, newTitle = validateTitle(
			new,
			multi and 'new' or firstNewParamPrefix,
			num
		)
		if not validNew then
			-- If invalid, the second parameter is the error message.
			local msg = newTitle
			return err(msg, argsByNum, args.reason, argsByNumCount)
		end

		-- Check for duplicate new titles.
		-- We can't use the page_id, as new pages might not exist, and therefore
		-- multiple pages may have an id of 0. Use the prefixedText as a
		-- reasonable fallback. We also need to check that we aren't using the
		-- default new page name, as we don't want it to be treated as a duplicate
		-- page if more than one new page name has been omitted.
		local newPrefixedText = newTitle.prefixedText
		if newPrefixedText ~= defaultNewPagename then
			if newDupes[newPrefixedText] then
				local msg = 'Duplicate title detected ("'
					.. newTitle.prefixedText
					.. '"); cannot move two different pages to the same place'
				return err(msg, argsByNum, args.reason, argsByNumCount)
			else
				newDupes[newPrefixedText] = true
			end
		end
	end

	----------------------------------------------------------------------------
	-- Generate the heading
	----------------------------------------------------------------------------

	-- For custom values of |heading=, use those.
	-- For |heading=no, |heading=n, etc., don't include a heading.
	-- Otherwise use the current date as a heading.
	local heading = args.heading or args.header
	local useHeading = yesno(heading, heading)
	if heading and useHeading == heading then
		heading = '== ' .. heading .. ' ==\n\n'
	elseif useHeading == false then
		heading = ''
	else
		local lang = mw.language.getContentLanguage()
		local headingDate = lang:formatDate('j F Y')
		heading = '== Requested move ' .. headingDate .. ' ==\n\n'
	end
	
	----------------------------------------------------------------------------
	-- Build the {{requested move/dated}} invocation
	----------------------------------------------------------------------------

	local rmd = {}
	rmd[#rmd + 1] = '{{requested move/dated'

	if multi then
		rmd[#rmd + 1] = '|multiple=yes'
		rmd[#rmd + 1] = '\n|current1=' .. argsByNum[1].current
	end

	--[[
	-- The first new title. This is used both by single and by multi; for single
	-- it is the only parameter used. For single the parameter name is the first
	-- positional parameter, and for multi the parameter name is "new1".
	--]]
	local new1param = multi and 'new1=' or ''
	rmd[#rmd + 1] = '|' .. new1param .. argsByNum[1].new

	-- Add the rest of the arguments for multi.
	if multi then
		for i = 2, argsByNumCount do
			local t = argsByNum[i]
			local numString = tostring(i)
			local current = t.current
			local new = t.new
			rmd[#rmd + 1] = '|current' .. numString .. '=' .. current
			rmd[#rmd + 1] = '|new' .. numString .. '=' .. new
		end
		-- The old multi template always has a bar before the closing curly
		-- braces, so we will do that too.
		rmd[#rmd + 1] = '|'
	end
	
	rmd[#rmd + 1] = '}}'
	rmd = table.concat(rmd)

	----------------------------------------------------------------------------
	-- Generate the list of links to the pages to be moved
	----------------------------------------------------------------------------

	local linkList = {}
	for i, t in ipairs(argsByNum) do
		local current = t.current
		local new = t.new
		local msg = '\n%s[[:%s]] → '
		if new ~= defaultNewPagename then
			msg = msg .. '{{no redirect|%s}}'
		else
			msg = msg .. '%s'
		end
		local item = string.format(
			msg,
			multi and '* ' or '', -- Don't make a list for single page moves.
			current,
			new
		)
		linkList[#linkList + 1] = item
	end
	linkList = table.concat(linkList)

	----------------------------------------------------------------------------
	-- Reason and talk blurb
	----------------------------------------------------------------------------

	-- Reason
	local reason = args.reason or args[2] or 'Please place your rationale for the proposed move here.'
	reason = '– ' .. reason
	if yesno(args.sign or args.sig or args.signature or 'unspecified', not reason:match("~~~$")) then
		reason = reason .. ' ~~~~'
	end

	-- Talk blurb
	local talk
	if yesno(args.talk, true) then
		talk = frame:expandTemplate{title = 'Requested move/talk'}
	else
		talk = ''
	end

	----------------------------------------------------------------------------
	-- Assemble the output
	----------------------------------------------------------------------------

	-- The old templates start with a line break, so we will do that too.
	local ret = string.format(
		'\n%s%s\n%s%s%s%s',
		heading,
		rmd,
		linkList,
		multi and '\n' or ' ',
		reason,
		talk
	)
	return ret
end

return p