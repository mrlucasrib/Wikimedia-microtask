-- This module implements {{GANList3}}.

-- Load modules
require('Module:No globals')
local yesno = require('Module:Yesno')
local data = mw.loadData('Module:GANList3/data')
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
	args.nocopyvio = args.nocopyvio or args.plagiarismfree
	args.plagiarismfree = nil

	-- Normalize special values
	makeArgLowerCase(args, 'picfree', 'fair')
	makeArgLowerCase(args, 'status', 'wtf')
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
-- string value or nil (hold, as passed to makeSection).
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

local function makeWellWrittenEligibilitySection(args)
	return makeSection{
		unresolvedHeader = "'''Well written?:'''",
		resolvedHeader = "'''Writing:''' article reasonably well written",
		mainIssues = {
			{
				issue = '[[Wikipedia:What the Good article criteria are not#(1) Well-written|Prose]]',
				status = args.prose,
			},
			{
				issue = '[[Wikipedia:Copyright violations|Copyvio]]',
				status = args.nocopyvio,
			},
			{
				issue = '[[Wikipedia:Manual of Style|MOS compliance]]',
				status = args.moscomply,
			},
		},
		otherIssues = args.writingother,
	}
end

local function makeVerifiabilityComplianceSection(args)
	return makeSection{
		unresolvedHeader = "'''Verifiable?:'''",
		resolvedHeader = "'''Verifiability:''' Article is factually accurate, verifiable, and contains no original research",
		mainIssues = {
			{
				issue = '[[Wikipedia:Manual of Style/Layout#Notes and references|Reference section]]',
				status = args.refsection,
			},
			{
				issue = '[[Wikipedia:Reliable sources|Reliable sourcing]]',
				status = args.sourcing,
			},
			{
				issue = '[[Wikipedia:No original research|Original research]]',
				status = args.origresearch,
			},
		},
		otherIssues = args.verifyother,
	}
end

local function makeNeutralEligibilitySection(args)
	-- The Neutrality and Stablity sections are different enough from the others
	-- that we will just do everything here rather than trying to use the 
	-- makeSection function.
	local isGood = yesno(args.neutral)
	if isGood == true then
		return makeUncollapsedWikitable("'''Neutral''': Acceptable.")
	else
		local ret = makeChecklistItem(
			"'''[[Wikipedia:Neutral point of view|Neutral]]'''",
			isGood == false and 'Not good' or args.neutral
		)
		return ret .. '<br />'
	end
end

local function makeStableEligibilitySection(args)
	local isStable = yesno(args.stable)
	if isStable == true then
		return makeUncollapsedWikitable("'''Stable''': Yes.")
	else
		local ret = makeChecklistItem(
			"'''[[Wikipedia:What the Good article criteria are not#(5) Stable|Stable]]'''",
			isStable == false and 'Not stable' or args.stable
		)
		return ret .. '<br />'
	end
end

local function makeImageEligibilitySection(args)
	-- Deal with nonfree special case for images
	local imagesUsedStatus, isImageFairUse
	if args.picfree == 'fair' then
		imagesUsedStatus = 'Valid fair use image rationale supplied'
		isImageFairUse = true
	else
		imagesUsedStatus = args.picfree
		isImageFairUse = nil -- use default behaviour
	end

	-- Generate output
	return makeSection{
		unresolvedHeader = "'''Images?:'''",
		resolvedHeader = "'''Images:''' Article provides sufficient illustration relevant to topic.",
		mainIssues = {
			{
				issue = '[[Wikipedia:What the Good article criteria are not#(6) Appropriately illustrated|Illustrated appropriately]]',
				status = args.illustrated,
			},
			{
				issue = '[[Wikipedia:File copyright tags#For image creators|Freely licensed]]',
				status = imagesUsedStatus,
				isResolved = isImageFairUse
			},
			{
				issue = '[[MOS:IMAGERELEVANCE|Relevant]] with captions',
				status = args.picused,
			},
		},
		otherIssues = args.picother,
	}
end

local function makeStatusSection(args)
	if not args.status then
		return makeWikitextError('Review is incomplete - please fill in the "status" field')
	elseif args.status ~= 'y'
		and args.status ~= '?'
		and args.status ~= 'neu'
		and args.status ~= 'no'
		and args.status ~= 'hold'
		and args.status ~= 'wtf'
	then
		return makeWikitextError(string.format(
			'Invalid status "%s" - use one of "y", "?", "neu", "no" or "hold"',
			escapeUserString(args.status)
		))
	end

	local ret = {}
	table.insert(ret, "'''Overall''': ")
	local isOK = yesno(args.status)
	if isOK == true then
		if args.picfree == 'fair' then
			table.insert(ret, statusIcons.YES_FAIR)
		else
			table.insert(ret, statusIcons.YES)
		end
	elseif isOK == false then
		table.insert(ret, statusIcons.NO)
	elseif args.status == '?' then
		table.insert(ret, statusIcons.QUESTION)
	elseif args.status == 'neutral' then
		table.insert(ret, statusIcons.NETURAL)
	elseif args.status == 'hold' then
		table.insert(ret, statusIcons.HOLD)
	elseif args.status == 'wtf' then
		table.insert(ret, statusIcons.CONFUSED)
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
		'prose',
		'nocopyvio',
		'moscomply',
		'writingother',
		'refsection',
		'sourcing',
		'origresearch',
		'verifyother',
		'neutral',
		'stable',
		'illustrated',
		'picfree',
		'picused',
		'picother',
		'picfree',
	}
	if not anyKeysInTable(args, params) then
		return 'Review not started'
	end

	-- The review has been started, so assemble all the review sections.
	local funcs = {
		makeWellWrittenEligibilitySection,
		makeVerifiabilityComplianceSection,
		makeNeutralEligibilitySection,
		makeStableEligibilitySection,
		makeImageEligibilitySection,
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
		wrappers = 'Template:GANList3',
	})
	return p._main(args)
end

return p