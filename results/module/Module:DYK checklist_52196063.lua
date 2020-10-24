-- This module implements {{DYK checklist}}.

-- Load modules
require('Module:No globals')
local yesno = require('Module:Yesno')
local data = mw.loadData('Module:DYK checklist/data')
local responseIcons = data.responseIcons
local statusIcons = data.statusIcons

-- Template for making collapsed sections.
local COLLAPSED_WIKITABLE = [[
{| class="collapsible collapsed" border="1" style="border-collapse:collapse;"
|-
! style="font-weight:normal; " | %s
|-
| %s
|}]]

-- Template for making uncollapsed sections.
local UNCOLLAPSED_WIKITABLE = [[
{| border="1" style="border-collapse:collapse;"
|-
| %s
|}]]

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Make the given key in args lowercase if when lowercased it equals val.
local function makeArgLowerCase(args, key, val)
	if args[key] and string.lower(args[key]) == val then
		args[key] = val
	end
end

-- Normalize the args table to make it easier to work with elsewhere in the
-- module.
local function normalizeArguments(args)
	-- Consolidate aliases
	args.plagiarismfree = args.plagiarismfree or args.plagarismfree
	args.plagarismfree = nil

	-- Normalize special values
	makeArgLowerCase(args, 'hookcited', 'agf')
	makeArgLowerCase(args, 'picfree', 'na')
	makeArgLowerCase(args, 'qpq', 'na')
end

-- If any of the keys in the keys array are in the table t, return true;
-- otherwise, return false.
local function anyKeysInTable(t, keys)
	for i, key in ipairs(keys) do
		if t[key] then
			return true
		end
	end
	return false
end

-- Make a wikitext error message.
local function makeWikitextError(msg)
	return string.format([['''<span style="color: red;">%s</span>''']], msg)
end

-- Format a user-supplied string for display in error messages.
-- This prevents input from being displayed as special wiki markup, converts
-- multi-line strings to a single line, and truncates long strings so that they
-- are easier to read.
local function escapeUserString(s)
	if #s > 28 then
		s = s:sub(1, 12) .. '...' .. s:sub(-12, -1)
	end
	s = s:gsub("\n", " ")
	return mw.text.nowiki(s)
end

-- Make a collapsed wikitable with the given header and content. 
local function makeCollapsedWikitable(header, content)
	return string.format(COLLAPSED_WIKITABLE, header, content)
end

-- Make an uncollapsed wikitable with the given content. 
local function makeUncollapsedWikitable(content)
	return string.format(UNCOLLAPSED_WIKITABLE, content)
end

-- Make a bulleted list from an array of strings.
local function makeBulletedList(items)
	local ret = {}
	for i, item in ipairs(items) do
		ret[i] = '* ' .. item
	end
	return table.concat(ret, '\n')
end

-- Make a checklist item from the given issue and status.
local function makeChecklistItem(issue, status, defaultMarker)
	if not status then
		return string.format('%s: %s', issue, responseIcons.UNKNOWN)
	elseif yesno(status) then
		return string.format('%s: %s', issue, responseIcons.YES)
	else
		return string.format(
			'%s: %s - %s',
			issue,
			defaultMarker or responseIcons.NO,
			status
		)
	end
end

-- Return true if all issues have been resolved; return false otherwise.
-- mainIssues is an array of tables as passed to makeSection. otherIssues is a
-- string value or nil (again, as passed to makeSection).
local function allIssuesAreResolved(mainIssues, otherIssues)
	if otherIssues then
		return false
	end
	for i, t in ipairs(mainIssues) do
		if t.isResolved == false
			or (
				t.isResolved ~= true
				and not yesno(t.status)
			)
		then
			return false
		end
	end
	return true
end

-- Assemble a section of the DYK checklist.
local function makeSection(options)
	local issues = {}

	-- Add main issues
	options.mainIssues = options.mainIssues or {}
	for i, t in ipairs(options.mainIssues) do
		local checklistItem
		if t.isResolved then
			checklistItem = makeChecklistItem(t.issue, t.status, responseIcons.YES)
		else
			checklistItem = makeChecklistItem(t.issue, t.status)
		end
		table.insert(issues, checklistItem)
	end

	-- Add other issues
	if options.otherIssues then
		table.insert(issues, makeChecklistItem('Other problems', options.otherIssues))
	end

	-- Make the section output.
	local content = makeBulletedList(issues)
	if allIssuesAreResolved(options.mainIssues, options.otherIssues) then
		return makeCollapsedWikitable(options.resolvedHeader, '\n' .. content)
	else
		return options.unresolvedHeader .. '\n' .. content
	end
end

--------------------------------------------------------------------------------
-- Section functions
-- Each of these functions makes a single section of the DYK checklist.
--------------------------------------------------------------------------------

local function makeGeneralEligibilitySection(args)
	return makeSection{
		unresolvedHeader = "'''General eligibility:'''",
		resolvedHeader = "'''General:''' Article is new enough and long enough",
		mainIssues = {
			{
				issue = '[[WP:Did you know#New|New Enough]]',
				status = args.newness,
			},
			{
				issue = '[[WP:Did you know#Long enough|Long Enough]]',
				status = args.length,
			},
		},
		otherIssues = args.eligibilityother,
	}
end

local function makePolicyComplianceSection(args)
	return makeSection{
		unresolvedHeader = "'''Policy compliance:'''",
		resolvedHeader = "'''Policy:''' Article is sourced, neutral, and free of copyright problems",
		mainIssues = {
			{
				issue = '[[WP:Citing sources|Adequate sourcing]]',
				status = args.sourced,
			},
			{
				issue = '[[WP:NPOV|Neutral]]',
				status = args.neutral,
			},
			{
				issue = 'Free of [[Wikipedia:Copyright violations|copyright violations]], [[Wikipedia:Plagiarism|plagiarism]], and [[WP:close paraphrasing|close paraphrasing]]',
				status = args.plagiarismfree,
			},
		},
		otherIssues = args.policyother,
	}
end

local function makeHookEligibilitySection(args)
	-- Deal with AGF special case for hook citations
	local hookCiteStatus, isHookSourceAGF
	if args.hookcited == 'agf' then
		hookCiteStatus = 'Offline/paywalled citation accepted in good faith'
		isHookSourceAGF = true
	else
		hookCiteStatus = args.hookcited
		isHookSourceAGF = nil -- use default behaviour
	end

	-- Generate output
	return makeSection{
		unresolvedHeader = "'''Hook eligibility:'''",
		resolvedHeader = "'''Hook:''' Hook has been verified by provided inline citation",
		mainIssues = {
			{
				issue = '[[WP:Did you know#Cited hook|Cited]]',
				status = hookCiteStatus,
				isResolved = isHookSourceAGF
			},
			{
				issue = 'Interesting',
				status = args.hookinterest,
			},
		},
		otherIssues = args.hookother,
	}
end

local function makeImageEligibilitySection(args)
	if args.status
		and (args.picfree == 'na' or not args.picfree)
		and not args.picused
		and not args.picclear
	then
		return nil
	end
	return makeSection{
		unresolvedHeader = "'''Image eligibility:'''",
		resolvedHeader = "'''Image:''' Image is freely licensed, used in the article, and clear at 100px.",
		mainIssues = {
			{
				issue = '[[WP:ICTIC|Freely licensed]]',
				status = args.picfree,
			},
			{
				issue = '[[WP:Did you know#Pictures|Used in article]]',
				status = args.picused,
			},
			{
				issue = 'Clear at 100px',
				status = args.picclear,
			},
		},
	}
end

local function makeQPQSection(args)
	-- The QPQ section is different enough from the other sections that we
	-- will just do everything here rather than trying to use the makeSection
	-- function.
	local isDone = yesno(args.qpq)
	if isDone == true then
		return makeUncollapsedWikitable("'''QPQ''': Done.")
	elseif args.qpq == 'na' then
		return makeUncollapsedWikitable("'''QPQ''': None required.")
	else
		local ret = makeChecklistItem(
			"'''[[Wikipedia:Did you know#QPQ|QPQ]]'''",
			isDone == false and 'Not done' or args.qpq
		)
		return ret .. '<br />'
	end
end

local function makeStatusSection(args)
	if not args.status then
		return makeWikitextError('Review is incomplete - please fill in the "status" field')
	elseif args.status ~= 'y'
		and args.status ~= '?'
		and args.status ~= 'maybe'
		and args.status ~= 'no'
		and args.status ~= 'again'
	then
		return makeWikitextError(string.format(
			'Invalid status "%s" - use one of "y", "?", "maybe", "no" or "again"',
			escapeUserString(args.status)
		))
	end

	local ret = {}
	table.insert(ret, "'''Overall''': ")
	local isOK = yesno(args.status)
	if isOK == true then
		if args.hookcited == 'agf' then
			table.insert(ret, statusIcons.YES_AGF)
		else
			table.insert(ret, statusIcons.YES)
		end
	elseif isOK == false then
		table.insert(ret, statusIcons.NO)
	elseif args.status == '?' then
		table.insert(ret, statusIcons.QUESTION)
	elseif args.status == 'maybe' then
		table.insert(ret, statusIcons.MAYBE)
	elseif args.status == 'again' then
		table.insert(ret, statusIcons.AGAIN)
	end
	if args.comments then
		table.insert(ret, ' ')
		table.insert(ret, args.comments)
	end
	if args.sign then
		table.insert(ret, ' ')
		table.insert(ret, args.sign)
	end
	return table.concat(ret)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p._main(args)
	-- Normalize the args table to make it easier to work with in other
	-- functions.
	normalizeArguments(args)

	-- Check whether the review has been started.
	local params = {
		'newness',
		'length',
		'eligibilityother',
		'sourced',
		'neutral',
		'plagiarismfree',
		'policyother',
		'hookcited',
		'hookinterest',
		'hookother',
		'picfree',
		'picused',
		'picclear',
	}
	if not anyKeysInTable(args, params) then
		return 'Review not started'
	end

	-- The review has been started, so assemble all the review sections.
	local funcs = {
		makeGeneralEligibilitySection,
		makePolicyComplianceSection,
		makeHookEligibilitySection,
		makeImageEligibilitySection,
		makeQPQSection,
		makeStatusSection,
	}
	local ret = {}
	for i, func in ipairs(funcs) do
		table.insert(ret, func(args))
	end
	return table.concat(ret, '\n')
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:DYK checklist',
	})
	return p._main(args)
end

return p