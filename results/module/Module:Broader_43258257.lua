--[[
-- This module produces a "For a broader coverage related to this topic" link. It implements
-- the {{broader}} template.
--]]
 
local mHatlist = require('Module:Hatnote list')
local mHatnote = require('Module:Hatnote')
local mArguments -- lazily initialize
local mTableTools --lazily initialize

local p = {}

local s = { --localizable strings
	broaderForm = 'For broader coverage of %s, see %s.',
	defaultTopic = 'this topic'
}

function p.broader(frame)
	mArguments = require('Module:Arguments')
	mTableTools = require('Module:TableTools')
	local originalArgs = mArguments.getArgs(frame, {parentOnly = true})
	local args = mTableTools.compressSparseArray(originalArgs)
	-- re-add non-numeric arguments omitted by compressSparseArray
	for _, name in pairs({'category', 'selfref', 'topic'}) do
		args[name] = originalArgs[name]
	end
	return p._broader(args)
end

function p._broader(args)
	if not args[1] then
		return mHatnote.makeWikitextError(
			'no page name specified',
			'Template:Broader#Errors',
			args.category
		)
	end
	local list = mHatlist.andList(args, true)
	local topic = args.topic or s.defaultTopic
	local text = string.format(s.broaderForm, topic, list)
	options = {selfref = args.selfref}
	return mHatnote._hatnote(text, options)
end

return p