--[[
-- This module produces a link to a main article or articles. It implements the
-- template {{main}}.
-- 
-- If the module is used in category or category talk space, it produces "The
-- main article for this category is xxx." Otherwise, it produces
-- "Main article: xxx".
--]]

local mHatnote = require('Module:Hatnote')
local mHatlist = require('Module:Hatnote list')
local mArguments -- lazily initialise
local p = {}

function p.main(frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame, {parentOnly = true})
	local pages = {}
	for k, v in pairs(args) do
		if type(k) == 'number' then
			local display = args['label ' .. k] or args['l' .. k]
			local page = display and
				string.format('%s|%s', string.gsub(v, '|.*$', ''), display) or v
			pages[#pages + 1] = page
		end
	end
	if #pages == 0 and mw.title.getCurrentTitle().namespace == 0 then
		return mHatnote.makeWikitextError(
			'no page names specified',
			'Template:Main#Errors',
			args.category
		)
	end
	local options = {
		selfref = args.selfref
	}
	return p._main(pages, options)
end

function p._main(args, options)
	-- Get the list of pages. If no first page was specified we use the current
	-- page name.
	local currentTitle = mw.title.getCurrentTitle()
	if #args == 0 then args = {currentTitle.text} end
	local firstPage = string.gsub(args[1], '|.*$', '')
	-- Find the pagetype.
	local pageType = mHatnote.findNamespaceId(firstPage) == 0 and 'article' or 'page'
	-- Make the formatted link text
	list = mHatlist.andList(args, true)
	-- Build the text.
	local isPlural = #args > 1
	local mainForm
	local curNs = currentTitle.namespace
	if (curNs == 14) or (curNs == 15) then --category/talk namespaces
		mainForm = isPlural and
			'The main %ss for this [[Help:Categories|category]] are %s.'
			or
			'The main %s for this [[Help:Categories|category]] is %s.'
	else
		mainForm = isPlural and 'Main %ss: %s' or 'Main %s: %s'
	end
	local text = string.format(mainForm, pageType, list)
	-- Process the options and pass the text to the _rellink function in
	-- [[Module:Hatnote]].
	options = options or {}
	local hnOptions = {
		selfref = options.selfref
	}
	return mHatnote._hatnote(text, hnOptions)
end

return p