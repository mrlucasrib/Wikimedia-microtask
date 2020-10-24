-- This module implements {{find sources notice}}.

local mFindSources = require('Module:Find sources')
local mMessageBox = require('Module:Message box')
local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType
local checkTypeForNamedArg = libraryUtil.checkTypeForNamedArg

local p = {}

local function compressArray(t, func)
	local ret, keys = {}, {}
	for key in pairs(t) do
		keys[#keys + 1] = key
	end
	table.sort(keys, func)
	for i, key in ipairs(keys) do
		ret[i] = t[key]
	end
	return ret
end

function p._main(options)
	-- Validate options table and the searches argument.
	checkType('_main', 1, options, 'table', true)
	options = options or {}
	checkTypeForNamedArg('_main', 'searches', options.searches, 'table', true)
	local searches = options.searches or {}

	-- Make sure that we have something to iterate over. [[Module:Find sources]]
	-- can deal with blank arguments, but even if we are not passed any
	-- arguments we need to call it at least once.
	searches[1] = searches[1] or {}

	-- Get the list items to display.
	local listItems = {}
	for i, t in ipairs(searches) do
		if type(t) ~= 'table' then
			error(string.format(
				'type error in searches table #%d (expected table, got %s)',
				i,
				type(t)
			), 2)
		end
		listItems[i] = mFindSources._main('Find sources', t)
	end

	-- Make the text to pass to [[Module:Message box]].
	local text = '[[Wikipedia:Verifiability|Sources]] for development of this article may be located at'
	if #listItems < 2 then
		text = text .. ' '
	else
		text = text .. ':\n* '
	end
	text = text .. table.concat(listItems, '\n* ')
	text = text .. '\n' -- The ending table tag can't be on a bulleted line

	-- Render the box.
	return mMessageBox.main('tmbox', {
		text = text,
		small = options.small
	})
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Find sources notice'
	})

	-- Sort arguments
	local options, searches, numSearches = {}, {}, {}
	for k, v in pairs(args) do
		if type(k) == 'number' then
			numSearches[k] = v
		else
			-- Assume k is a string
			local num, letter = k:match('^([1-9][0-9]*)([a-z])$')
			if num then
				num = tonumber(num)
				searches[num] = searches[num] or {}
				searches[num][letter] = v
				searches[num].paramNum = num
			else
				options[k] = v
			end
		end
	end

	-- Sort alphabetically so that "aa" comes after "z"
	local function alphaSort(a, b)
		return #a == #b and a < b or #a < #b
	end

	-- Turn sparse arrays with alphabetic keys into normal arrays, and check
	-- we have an "a" key.
	searches = compressArray(searches)
	for i, t in ipairs(searches) do
		if not t.a then
			error(string.format(
				'parameter %d%s was set, but parameter %da is missing',
				t.paramNum, (next(t)), t.paramNum
			), 2)
		end
		t.paramNum = nil -- Erase this so it isn't serialized by compressArray
		searches[i] = compressArray(t, alphaSort)
	end

	options.searches = searches

	return p._main(options)
end

return p