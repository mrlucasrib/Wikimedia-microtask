-- This module implements [[Template:Transclude random subpage]]. It is alpha software.	

local p = {}

local mRandom = require('Module:Random')
local currentTitle = mw.title.getCurrentTitle()

-- tracking function added by BHG 29/04/2019
-- called as subPageTrackingCategories(pages, args.max)
local function subPageTrackingCategories(pages, max)
	local retval = "";
	local availableSubPageCount = 0;
	local i;
	local thispagetitle = mw.title.getCurrentTitle().text

	-- don't track DYK etc, only selected/featured articles, biogs etc
	if ((string.find(pages.subpage, "/[sS]elected") == -1) and (string.find(pages.subpage, "/[fF]eatured") == -1)) then
		return retval
	end
	-- no tracking unless we are in Portal namespace
	if (mw.title.getCurrentTitle().nsText ~= "Portal") then
		return ""
	end
-- no tracking if this is a subpage
	if ((mw.ustring.match(thispagetitle, "/") ~= nil) and (thispagetitle ~= "AC/DC")) then
		return retval
	end
	
	if (max == nil) then
		return "[[Category:Random portal component with no value for max]]"
	end

	-- limit checking to prevent Lua overload
	local myMaxCheck = 60
	if tonumber(max) < myMaxCheck then
		myMaxCheck = tonumber(max)
	end
	for i=1,myMaxCheck do 
		local aSubPage = mw.title.new(pages.subpage .. '/' .. i)
		if (aSubPage.exists) then
			availableSubPageCount = availableSubPageCount + 1;
		end
	end
	if myMaxCheck >= tonumber(max) then
		if (availableSubPageCount < tonumber(max)) then
			retval = retval .. "[[Category:Random portal component with fewer available subpages than specified max]]"
		elseif (availableSubPageCount > tonumber(max)) then
			retval = retval .. "[[Category:Random portal component with more available subpages than specified max]]"
		end
	end
	-- before categorising, check what type of subpage we are categorising, and if detected, categorise images separately
	local subpageType = "subpages" -- generic type
	local subpageName = pages.subpage
	subpageName = mw.ustring.gsub(subpageName, "^[^/]*/", "")
	subpageName = mw.ustring.lower(subpageName)
	if ((mw.ustring.find(subpageName, "picture", 1, true) ~= nil) or
		(mw.ustring.find(subpageName, "image", 1, true) ~= nil) or
		(mw.ustring.find(subpageName, "panorama", 1, true) ~= nil)) then
		subpageType = "image subpages"
	end
	if (availableSubPageCount < 2) then
		retval = retval .. "[[Category:Random portal component with less than 2 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 5) then
		retval = retval .. "[[Category:Random portal component with 2–5 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 10) then
		retval = retval .. "[[Category:Random portal component with 6–10 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 15) then
		retval = retval .. "[[Category:Random portal component with 11–15 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 20) then
		retval = retval .. "[[Category:Random portal component with 16–20 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 25) then
		retval = retval .. "[[Category:Random portal component with 21–25 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 30) then
		retval = retval .. "[[Category:Random portal component with 26–30 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 40) then
		retval = retval .. "[[Category:Random portal component with 31–40 available " .. subpageType .. "]]"
	elseif (availableSubPageCount <= 50) then
		retval = retval .. "[[Category:Random portal component with 41–50 available " .. subpageType .. "]]"
	else
		retval = retval .. "[[Category:Random portal component with over 50 available " .. subpageType .. "]]"
	end
	return retval;
end

local function getRandomNumber(max)
	-- gets a random integer between 1 and max; max defaults to 1
	return mRandom.number{max or 1}
end

local function expandArg(args, key)
	-- Emulate how unspecified template parameters appear in wikitext. If the
	-- specified argument exists, its value is returned, and if not the argument
	-- name is returned inside triple curly braces.
	local val = args[key]
	if val then
		return val
	else
		return string.format('{{{%s}}}', key)
	end
end

local function getPages(args)
	local pages = {}
	pages.root = args.rootpage or currentTitle.prefixedText
	pages.subpage = pages.root .. '/' .. expandArg(args, 'subpage')
	return pages
end

local function tryExpandTemplate(frame, title, args)
	local success, result = pcall(frame.expandTemplate, frame, {title = title, args = args})
	if success then
		return result
	else
		local msg = string.format(
			'<strong class="error">The page "[[%s]]" does not exist.</strong>',
			title
		)
		if mw.title.getCurrentTitle().namespace == 100 then -- is in the portal namespace
			msg = msg .. '[[Category:Portals needing attention]]'
		end
		return msg
	end
end

local function getNumberedSubpageContent(frame, pages, num)
	return tryExpandTemplate(
		frame,
		pages.subpage .. '/' .. num
	)
end

function p._main(args, frame)
	frame = frame or mw.getCurrentFrame()
	local pages = getPages(args)
	local prefix = args.prefix or ''
	local max = args.max or 1

	local ret = {}
	local r = getRandomNumber(max)
	for i = 1, (args.several or 1) do
		local num = ((r + i - 1) % max) + 1
		ret[#ret + 1] = prefix .. getNumberedSubpageContent(frame, pages, num)
	end

	if args.more then
		ret[#ret + 1] = string.format('<div style="float: right;"><b>[[%s|%s]]</b></div>', pages.subpage, args.more)
	end
	if args.leftfooter then
		ret[#ret + 1] = string.format('<div style="float: left;">%s</div>', args.leftfooter)
	end
	if args.rightfooter then
		ret[#ret + 1] = string.format('<div style="float: right;">%s</div>', args.rightfooter)
	end

	return table.concat(ret, '\n') .. subPageTrackingCategories(pages, max, args.header)
end

local function makeInvokeFunction(func)
	return function (frame)
		local args = require('Module:Arguments').getArgs(frame, {
			trim = false,
			removeBlanks = false,
			wrappers = {
				'Template:Transclude random subpage',
				'Template:Transclude random subpage/BHG-test',
			}
		})
		return func(args, frame)
	end
end

p.main = makeInvokeFunction(p._main)

return p