--[[
-- This module produces a "For more details on this topic" link. It implements
-- the {{Main list}} template.
--]]

local mHatnote = require('Module:Hatnote')
local mHatlist = require('Module:Hatnote list')
local mArguments -- lazily initialise
local mTableTools -- lazily initialise
local p = {}

function p.mainList(frame)
	mArguments = require('Module:Arguments')
	mTableTools = require('Module:TableTools')
	local args = mArguments.getArgs(frame, {parentOnly = true})
	if not args[1] then
		return mHatnote.makeWikitextError(
			'no page name specified',
			'Template:Main list#Errors',
			args.category
		)
	end
	return p._mainList(mTableTools.compressSparseArray(args))
end

function p._mainList(args)
	local pages = mHatlist.andList(args, true)
	local text = string.format('For a more comprehensive list, see %s.', pages)
	return mHatnote._hatnote(text)
end

return p