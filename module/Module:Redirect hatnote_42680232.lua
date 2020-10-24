--[[
-- This module produces a "redirect" hatnote. It looks like this:
-- '"X" redirects here. For other uses, see Y.'
-- It implements the {{redirect}} template.
--]]

local mHatnote = require('Module:Hatnote')
local mHatList = require('Module:Hatnote list')
local mArguments --lazily initialize
local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType
local checkTypeMulti = libraryUtil.checkTypeMulti

local p = {}

local function getTitle(...)
	local success, titleObj = pcall(mw.title.new, ...)
	if success then
		return titleObj
	else
		return nil
	end
end

function p.redirect(frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame, {parentOnly=true})
	--Get number of redirects
	local numRedirects = tonumber(frame.args[1]) or 1
	-- Create the options table.
	local options = {}
	options.selfref = args.selfref
	return p._redirect(args, numRedirects, options)
end

function p._redirect(args, numRedirects, options, currentTitle, redirectTitle, targetTitle)
	-- Validate the input. Don't bother checking currentTitle, redirectTitle or
	-- targetTitle, as they are only used in testing.
	checkType('_redirect', 1, args, 'table')
	checkType('_redirect', 2, numRedirects, 'number', true)
	numRedirects = numRedirects or 1
	checkType('_redirect', 3, options, 'table', true)
	options = options or {}
	currentTitle = currentTitle or mw.title.getCurrentTitle()
	-- Get the table of redirects
	local redirect = {}
	for i = 1, numRedirects do
		-- Return an error if a redirect parameter is missing.
		if not args[i] then
			return mHatnote.makeWikitextError(
				'missing redirect parameter',
				'Template:Redirect#Errors',
				args.category
			)
		end
		redirect[i] = args[i]
	end
	-- Generate the text.
	local formattedRedirect = {}
	for k,v in pairs(redirect) do
		formattedRedirect[k] = '"' .. v .. '"'
	end
	local text = {
		mHatList.andList(formattedRedirect) .. ' ' .. (#redirect == 1 and 'redirects' or 'redirect') .. ' here.',
		mHatList._forSee(args, #redirect + 1, {title = redirect[1], extratext = args.text})
	}
	text = table.concat(text, ' ')
	-- Functionality for adding categories	
	local categoryTable = {}
	function addCategory(cat)
		if cat and cat ~= '' then
			-- Add by index to avoid duplicates
			categoryTable[string.format('[[Category:%s]]', cat)] = true
		end
	end
	--Generate tracking categories
	local mhOptions = {}
	for k,v in pairs(redirect) do
		-- We don't need a tracking category if the template invocation has been
		-- copied directly from the docs, or if we aren't in main- or category-space.
		if not v:find('^REDIRECT%d*$') and v ~= 'TERM' -- 
			and currentTitle.namespace == 0 or currentTitle.namespace == 14
		then
			redirectTitle = redirectTitle or getTitle(v)
			if not redirectTitle or not redirectTitle.exists then
				addCategory('Missing redirects')
			elseif not redirectTitle.isRedirect then
				addCategory('Articles with redirect hatnotes needing review')
			else
				local mRedirect = require('Module:Redirect')
				local target = mRedirect.getTarget(redirectTitle)
				targetTitle = targetTitle or target and getTitle(target)
				if targetTitle and targetTitle ~= currentTitle then
					addCategory('Articles with redirect hatnotes needing review')
				end
			end
		end

		-- Generate the options to pass to [[Module:Hatnote]].
		if currentTitle.namespace == 0 and not mhOptions.selfref
			and redirectTitle and redirectTitle.namespace ~= 0
		then
			-- We are on a mainspace page, and the hatnote starts with something
			-- like "Wikipedia:Foo redirects here", so automatically label it as
			-- a self-reference.
			mhOptions.selfref = true
		else
			mhOptions.selfref = options.selfref
		end
	end
	--concatenate all the categories
	local category = ''
	for k,v in pairs(categoryTable) do
		category = category .. k
	end

	return mHatnote._hatnote(text, mhOptions) .. category
end
 
return p