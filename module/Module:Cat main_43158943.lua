-- This module implements {{cat main}}.

local mHatnote = require('Module:Hatnote')
local yesno = require('Module:Yesno')
local mTableTools -- lazily initialise
local mArguments -- lazily initialise

local p = {}

function p.catMain(frame)
	mTableTools = require('Module:TableTools')
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame, {wrappers = 'Template:Cat main'})
	local pages = mTableTools.compressSparseArray(args)
	local options = {
		article = args.article,
		selfref = args.selfref
	}
	return p._catMain(options, unpack(pages))
end

function p._catMain(options, ...)
	options = options or {}

	-- Get the links table.
	local links = mHatnote.formatPages(...)
	if not links[1] then
		local page = mw.title.getCurrentTitle().text
		links[1] = mHatnote._formatLink{link = page}
	end
	for i, link in ipairs(links) do
		links[i] = string.format("'''%s'''", link)
	end

	-- Get the pagetype.
	local pagetype
	if yesno(options.article) ~= false then
		pagetype = 'article'
	else
		pagetype = 'page'
	end

	-- Work out whether we need to be singular or plural.
	local stringToFormat
	if #links > 1 then
		stringToFormat = 'The main %ss for this [[Help:Categories|category]] are %s.'
	else
		stringToFormat = 'The main %s for this [[Help:Categories|category]] is %s.'
	end

	-- Get the text.
	local text = string.format(
		stringToFormat,
		pagetype,
		mw.text.listToText(links)
	)
	
	-- Pass it through to Module:Hatnote.
	local hnOptions = {}
	hnOptions.selfref = options.selfref
	hnOptions.extraclasses = 'relarticle mainarticle'

	return mHatnote._hatnote(text, hnOptions)
end

return p