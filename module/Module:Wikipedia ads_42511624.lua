-------------------------------------------------------------------------------
--                         Module:Wikipedia ads
--
-- This module displays a random banner-style advert for a Wikipedia project,
-- page or process. It implements [[Template:Wikipedia ads]].
-------------------------------------------------------------------------------

-- Set constants
local LIST_MODULE = 'Module:Wikipedia ads/list'
local DATA_MODULE = 'Module:Wikipedia ads/data'

local p = {}
local warnings = {}

local function addWarning(msg)
	table.insert(warnings, msg)
end

local function makeWikilink(page, display)
	return string.format('[[%s|%s]]', page, display)
end

local function makeUrlLink(url, display)
	url = tostring(url)
	return string.format('[%s %s]', url, display)
end

local function colorText(s, color)
	return string.format('<span style="color:%s">%s</span>', color, s)
end

local function getImageData(args)
	-- This function gets an image data from the data module. It also tracks
	-- whether the image data choice was random.
	local data = mw.loadData(DATA_MODULE)

	local function getSomeImageData(id, param)
		id = tonumber(id) or id
		local someImageData = data.ids[id]
		if someImageData then
			return someImageData
		else
			addWarning(string.format("ID '%s' does not exist", tostring(id)))
			return nil
		end
	end

	-- Get the image data of the ad to display.
	local imageData, isRandom
	if args.ad then
		imageData = getSomeImageData(args.ad, 'ad')
		if not imageData then
			return nil
		end
		isRandom = false
	else
		local imageDataArray, length
		if args[1] then
			imageDataArray = {}
			for i, id in ipairs(args) do
				imageDataArray[#imageDataArray + 1] = getSomeImageData(id, i)
			end
			length = #imageDataArray
			if length < 1 then
				return nil
			end
		else
			imageDataArray = data.list
			length = data.noAds
		end
		assert(length >= 1, string.format(
			'no ads were found in [[%s]]',
			DATA_MODULE
		))
		isRandom = length > 1
		if isRandom then
			math.randomseed(os.clock() * 1000000000)
			imageData = imageDataArray[math.random(length)]
		else
			imageData = imageDataArray[1]
		end
	end

	-- Check that the image data has the required fields. We have already
	-- checked the ID in the data module.
	for i, field in ipairs{'image', 'link'} do
		assert(imageData[field], string.format(
			"Invalid image data in [[%s]]; table with ID '%s' has no '%s' field",
			LIST_MODULE, tostring(imageData.id), field
		))
	end

	return imageData, isRandom
end

local function renderAd(imageData, args, title, isRandom)
	local width = tonumber(args.width) or 468
	local maxWidth = width + 9
	local linkColor = args.linkcolor or '#002bb8'

	-- Table root
	local root = mw.html.create('table')
	root
		:addClass('plainlinks qxz-ads')
		:css('color', args.color or '#555555')
		:css('border', 'none')
		:css('background', args.background)
		:css('line-height', '1em')
		:css('font-size', '90%')
		:css('display', 'block')
		:css('overflow', 'auto')
		:css('max-width', maxWidth .. 'px')
	if args.float then
		root:css('float', args.float)
		root:css('margin', args.margin)
	else
		root:css('margin', args.margin or '0 auto')
	end
	
	-- Image row
	root
		:tag('tr')
			:tag('td')
				:attr('colspan', 2)
				:css('border', 'none')
				:wikitext(string.format(
					'[[File:%s|%dpx|alt=Wikipedia ad for %s|link=%s]]',
					imageData.image,
					width,
					imageData.link,
					imageData.link
				))
	
	-- Links row
	if not args.nolinks then
		local linksRow = root:tag('tr')

		-- Wikipedia ads link
		linksRow
			:tag('td')
				:css('border', 'none')
				:wikitext(makeWikilink(
					'Template:Wikipedia ads',
					colorText('Wikipedia ads', linkColor)
				))

		-- File info, purge and ID
		local links = {}
		links[#links + 1] = makeWikilink(
			':File:' .. imageData.image,
			colorText('file info', linkColor)
		)
		if args.showpurge or isRandom then
			links[#links + 1] = makeUrlLink(
				title:fullUrl{action = 'purge'},
				colorText('show another', linkColor)
			)
		end
		links[#links + 1] = '#' .. tostring(imageData.id)
		linksRow
			:tag('td')
				:css('text-align', 'right')
				:css('border', 'none')
				:wikitext(table.concat(links, ' – '))
	end

	return tostring(root)
end

local function renderWarnings(args, title)
	if #warnings < 1 then
		return nil
	end

	-- Error list
	local root = mw.html.create('div')
		:css('width', '468px')
	if args.float then
		root
			:css('float', args.float)
			:css('clear', 'both')
	else
		root:css('margin', '0 auto')
	end
	local list = root:tag('ul')
		:addClass('error')
		:css('font-size', '90%')
	for _, msg in ipairs(warnings) do
		list
			:tag('li')
				:wikitext(string.format(
					'Wikipedia ads error: %s ([[Template:Wikipedia ads#Errors|help]]).',
					msg
				))
	end

	-- Category. We use [[Module:Category handler]] for its blacklist.
	local mCatHandler = require('Module:Category handler')
	local category = mCatHandler._main{
		all = '[[Category:Wikipedia ads templates with errors]]',
		nocat = args.nocat,
		page = title and title.prefixedText
	}

	local ret = tostring(root)
	if category then
		ret = ret .. category
	end
	return ret
end

function p._main(args, title)
	title = title or mw.title.getCurrentTitle()
	local ret = {}
	local imageData, isRandom = getImageData(args)
	if imageData then
		ret[#ret + 1] = renderAd(imageData, args, title, isRandom)
	end
	ret[#ret + 1] = renderWarnings(args, title)
	if #ret > 0 then
		return table.concat(ret)
	else
		return nil
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Wikipedia ads'
	})
	return p._main(args)
end

return p