-------------------------------------------------------------------------------
--                       Automatic archive navigator
--
-- This module produces a talk archive banner, together with an automatically-
-- generated list of navigation links to other archives of the talk page in
-- question. It implements {{Automatic archive navigator}} and
-- {{Talk archive navigation}}.
-------------------------------------------------------------------------------

local yesno = require('Module:Yesno')

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

local function makeWikilink(page, display)
	if display then
		return string.format('[[%s|%s]]', page, display)
	else
		return string.format('[[%s]]', page)
	end
end

local function escapePattern(s)
	-- Escape punctuation in a string so it can be used in a Lua pattern.
	s = s:gsub('%p', '%%%0')
	return s
end

-------------------------------------------------------------------------------
-- Navigator class
-------------------------------------------------------------------------------

local Navigator = {}
Navigator.__index = Navigator

function Navigator.new(args, cfg, currentTitle)
	local obj = setmetatable({}, Navigator)
	
	-- Set inputs
	obj.args = args
	obj.cfg = cfg
	obj.currentTitle = currentTitle

	-- Archive prefix
	-- Decode HTML entities so users can enter things like "Archive&#32;" from
	-- wikitext.
	obj.archivePrefix = obj.args.prefix or obj:message('archive-prefix')
	obj.archivePrefix = mw.text.decode(obj.archivePrefix)

	-- Current archive number
	do
		local pattern = string.format(
			'^%s([1-9][0-9]*)$',
			escapePattern(obj.archivePrefix)
		)
		obj.currentArchiveNum = obj.currentTitle.subpageText:match(pattern)
		obj.currentArchiveNum = tonumber(obj.currentArchiveNum)
	end
	
	-- Highest archive number
	obj.highestArchiveNum = require('Module:Highest archive number')._main(
		 obj.currentTitle.nsText ..
		 	':' .. 
			obj.currentTitle.baseText .. 
			'/' .. 
			obj.archivePrefix
	)

	return obj
end

function Navigator:message(key, ...)
	local msg = self.cfg[key]
	if select('#', ...) > 0 then
		return mw.message.newRawMessage(msg, ...):plain()
	else
		return msg
	end
end

function Navigator:makeBlurb()
	local args = self.args
	if args[1] == '1' then
		-- The old template used "|1" to suppress the blurb.
		return ''
	else
		local ret
		if args.text then
			ret = args.text
		else
			local talkPage = self.currentTitle.nsText ..
				':' ..
				self.currentTitle.baseText
			if args.period then
				ret = self:message('blurb-period', talkPage, args.period)
			else
				ret = self:message('blurb-noperiod', talkPage)
			end
		end
		return ret
	end
end

function Navigator:makeMessageBox()
	local args = self.args
	
	local image
	if args.image then
		image = args.image
	else
		local icon = args.icon or self:message('default-icon')
		image = string.format(
			'[[File:%s|%s|alt=|link=]]',
			icon,
			self:message('image-size')
		)
	end

	local mbox = require('Module:Message box').main('tmbox', {
		image = image,
		imageright = args.imageright,
		style = args.style or 'width:80%;margin-left:auto;margin-right:auto',
		textstyle = args.textstyle or 'text-align:center',
		text = self:makeBlurb()
	})

	return mbox
end

function Navigator:getArchiveNums()
	-- Returns an array of the archive numbers to format.
	local noLinks = tonumber(self.args.links) or self:message('default-link-count')
	noLinks = math.floor(noLinks)
	-- If |noredlinks is "yes", true or absent, don't allow red links. If it is 
	-- 'no' or false, allow red links.
	local allowRedLinks = yesno(self.args.noredlinks) == false
	
	local current = self.currentArchiveNum
	local highest = self.highestArchiveNum

	if not current or not highest or noLinks < 1 then
		return {}
	elseif noLinks == 1 then
		return {current}
	end

	local function getNum(i, current)
		-- Gets an archive number given i, the position in the array away from
		-- the current archive, and the current archive number. The first two
		-- offsets are consecutive; the third offset is rounded up to the
		-- nearest 5; and the fourth and subsequent offsets are rounded up to
		-- the nearest 10. The offsets are calculated in such a way that archive
		-- numbers will not be duplicated.
		if -2 <= i and i <= 2 then
			return current + i
		elseif -3 <= i and i <= 3 then
			return current + 2 - (current + 2) % 5 + (i / 3) * 5
		elseif 4 <= i then
			return current + 7 - (current + 7) % 10 + (i - 3) * 10
		else
			return current + 2 - (current + 2) % 10 + (i + 3) * 10
		end
	end

	local nums = {}

	-- Archive nums lower than the current page.
	for i = -1, -math.floor((noLinks - 1) / 2), -1 do
		local num = getNum(i, current)
		if num <= 1 then
			table.insert(nums, 1, 1)
			break
		else
			table.insert(nums, 1, num)
		end
	end

	-- Current page.
	if nums[#nums] < current then
		table.insert(nums, current)
	end

	-- Higher archive nums.
	for i = 1, math.ceil((noLinks - 1) / 2) do
		local num = getNum(i, current)
		if num <= highest then
			table.insert(nums, num)
		elseif allowRedLinks and (i <= 2 or i <= 3 and num == nums[#nums] + 1) then
			-- Only insert one red link, and only if it is consecutive.
			table.insert(nums, highest + 1)
			break
		elseif nums[#nums] < highest then
			-- Insert the highest archive number if it isn't already there.
			table.insert(nums, highest)
			break
		else
			break
		end
	end

	return nums
end

function Navigator:makeArchiveLinksWikitable()
	local lang = mw.language.getContentLanguage()
	local nums = self:getArchiveNums()
	local noLinks = #nums
	if noLinks < 1 then
		return ''
	end

	-- Make the table of links.
	local links = {}
	local isCompact = noLinks > 7
	local currentIndex
	for i, num in ipairs(nums) do
		local subpage = self.archivePrefix .. tostring(num)
		local display
		if isCompact then
			display = tostring(num)
		else
			display = self:message('archive-link-display', num)
		end
		local link = makeWikilink('../' .. subpage, display)
		if num == self.currentArchiveNum then
			link = string.format('<span style="font-size:115%%;">%s</span>', link)
			currentIndex = i
		end
		table.insert(links, link)
	end

	-- Add the arrows.
	-- We must do the forwards arrow first as we are adding elements to the
	-- links table. If we did the backwards arrow first the index for the
	-- current archive would be wrong.
	currentIndex = currentIndex or math.ceil(#links / 2)
	for i = currentIndex + 1, #links do
		if nums[i] - nums[i - 1] > 1 then
			table.insert(links, i, lang:getArrow('forwards'))
			break
		end
	end
	for i = currentIndex - 1, 1, -1 do
		if nums[i + 1] - nums[i] > 1 then
			table.insert(links, i + 1, lang:getArrow('backwards'))
			break
		end
	end

	-- Output the wikitable.
	local ret = {}
	local width
	if noLinks <= 3 then
		width = string.format('%dem', noLinks * 10)
	elseif noLinks <= 7 then
		width = string.format('%dem', (noLinks + 3) * 5)
	else
		width = '50em'
	end
	ret[#ret + 1] = string.format(
		'{| style="width:%s;background:transparent;' ..
			'margin:0 auto 0.5em;text-align:center"',
		width
	)
	for i, s in ipairs(links) do
		if i % 20 == 1 then
			ret[#ret + 1] = '\n|-'
		end
		ret[#ret + 1] = '\n| '
		ret[#ret + 1] = s
	end
	ret[#ret + 1] = '\n|}'
	return table.concat(ret)
end

function Navigator:__tostring()
	return self:makeMessageBox() ..
		'\n' .. 
		self:makeArchiveLinksWikitable() .. 
		' __NONEWSECTIONLINK__ __NOEDITSECTION__'
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

function p._exportClasses()
	return {
		Navigator = Navigator
	}
end

function p._aan(args, cfg, currentTitle)
	cfg = cfg or mw.loadData('Module:Automatic archive navigator/config')
	currentTitle = currentTitle or mw.title.getCurrentTitle()
	local aan = Navigator.new(args, cfg, currentTitle)
	return tostring(aan)
end

function p.aan(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Automatic archive navigator',
	})
	return p._aan(args)
end

return p