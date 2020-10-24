-- This module implements {{shortcut}}.

-- Set constants
local CONFIG_MODULE = 'Module:Shortcut/config'

-- Load required modules
local checkType = require('libraryUtil').checkType
local yesno = require('Module:Yesno')

local p = {}

local function message(msg, ...)
	return mw.message.newRawMessage(msg, ...):plain()
end

local function makeCategoryLink(cat)
	return string.format('[[%s:%s]]', mw.site.namespaces[14].name, cat)
end

function p._main(shortcuts, options, frame, cfg)
	checkType('_main', 1, shortcuts, 'table')
	checkType('_main', 2, options, 'table', true)
	options = options or {}
	frame = frame or mw.getCurrentFrame()
	cfg = cfg or mw.loadData(CONFIG_MODULE)
	local isCategorized = yesno(options.category) ~= false

	-- Validate shortcuts
	for i, shortcut in ipairs(shortcuts) do
		if type(shortcut) ~= 'string' or #shortcut < 1 then
			error(message(cfg['invalid-shortcut-error'], i), 2)
		end
	end

	-- Make the list items. These are the shortcuts plus any extra lines such
	-- as options.msg.
	local listItems = {}
	for i, shortcut in ipairs(shortcuts) do
		if yesno(options['target']) then
			listItems[i] = string.format("[[%s]]",shortcut)
		else
			listItems[i] = frame:expandTemplate{
				title = 'No redirect',
				args = {shortcut}
			}
		end
	end
	table.insert(listItems, options.msg)

	-- Return an error if we have nothing to display
	if #listItems < 1 then
		local msg = cfg['no-content-error']
		msg = string.format('<strong class="error">%s</strong>', msg)
		if isCategorized and cfg['no-content-error-category'] then
			msg = msg .. makeCategoryLink(cfg['no-content-error-category'])
		end
		return msg
	end

	local root = mw.html.create()
	root:wikitext(frame:extensionTag{ name = 'templatestyles', args = { src = 'Shortcut/styles.css'} })
	-- Anchors
	local anchorDiv = root
		:tag('div')
			:addClass('module-shortcutanchordiv')
	for i, shortcut in ipairs(shortcuts) do
		local anchor = mw.uri.anchorEncode(shortcut)
		anchorDiv:tag('span'):attr('id', anchor)
	end

	-- Shortcut heading
	local shortcutHeading
	do
		local nShortcuts = #shortcuts
		if nShortcuts > 0 then
			local headingMsg = options['shortcut-heading'] or cfg['shortcut-heading']
			shortcutHeading = message(headingMsg, nShortcuts)
			shortcutHeading = frame:preprocess(shortcutHeading)
		end
	end

	-- Shortcut box
	local shortcutList = root
		:tag('div')
			:addClass('module-shortcutboxplain plainlist noprint')
			:attr('role', 'note')
	if shortcutHeading then
		shortcutList
			:tag('div')
				:addClass('module-shortcutlist')
				:wikitext(shortcutHeading)
	end
	local list = shortcutList:tag('ul')
	for i, item in ipairs(listItems) do
		list:tag('li'):wikitext(item)
	end
	return tostring(root)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame)

	-- Separate shortcuts from options
	local shortcuts, options = {}, {}
	for k, v in pairs(args) do
		if type(k) == 'number' then
			shortcuts[k] = v
		else
			options[k] = v
		end
	end

	-- Compress the shortcut array, which may contain nils.
	local function compressArray(t)
		local nums, ret = {}, {}
		for k in pairs(t) do
			nums[#nums + 1] = k
		end
		table.sort(nums)
		for i, num in ipairs(nums) do
			ret[i] = t[num]
		end
		return ret
	end
	shortcuts = compressArray(shortcuts)

	return p._main(shortcuts, options, frame)
end

return p