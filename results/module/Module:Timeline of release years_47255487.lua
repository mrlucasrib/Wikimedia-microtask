require('Module:No globals')
local getArgs = require('Module:Arguments').getArgs
local p = {}

local function items(args, year)
	local itemList = {}
	if args[year] or args[year .. 'a'] then
		table.insert(itemList, args[year] or args[year .. 'a'])
	end
	for asciiletter = 98, 106 do -- 98 > b, 106 > j
		if args[year .. string.char(asciiletter)] then
			table.insert(itemList, args[year .. string.char(asciiletter)])
		end
	end
	return table.maxn(itemList), itemList
end

local function color(args, year, itemNum)

	if args[year .. '_color'] then
		return args[year .. '_color'] 
	end

	for yearrange = 1, 5 do
		if args['range' .. yearrange] and args['range' .. yearrange .. '_color'] then
			local _, _, beginyear, endyear = string.find( args['range' .. yearrange], '^(%d%d%d%d)%D+(%d%d%d%d)$' )

			local year = tonumber(year) or 9999 -- For year == 'TBA'
			beginyear = tonumber(beginyear) or 0
			endyear =  tonumber(endyear) or 9999

			if year >= beginyear and year <= endyear then
				local _, _, color1, color2 = string.find( args['range' .. yearrange .. '_color'], '^(%S*)%s*(%S*)$' )
				color2 = string.find(color2, '^#?%w+$') and color2 or color1
				return itemNum > 0 and color1 or color2
			end
		end
	end

	return itemNum > 0 and '#0BDA51' or '#228B22'
end

local function left(builder, args, year, itemNum)
	builder = builder:tag('th')
		:attr('scope', 'row')
		:css('border-right', '1.4em solid ' .. color(args, year, itemNum))
		:wikitext(year)
	if itemNum > 1 then
		builder = builder:attr('rowspan', itemNum)
	end
end

local function right(builder, args, year, itemNum, itemList)
	if itemNum == 0 then return end

	if itemNum == 1 then
		builder:tag('td')
			:wikitext(itemList[1])
		return
	end

	-- if itemNum >= 2
	builder:tag('td')
		:addClass('rt_first')
		:wikitext(itemList[1])

	for key = 2, itemNum - 1 do
		builder = builder:tag('tr')
			:tag('td')
			:addClass('rt_next')
			:wikitext(itemList[key])
	end

	builder = builder:tag('tr')
		:tag('td')
		:addClass('rt_last')
		:wikitext(itemList[itemNum])

end

local function row(builder, args, year)
	local itemNum, itemList = items(args, year)
	builder = builder:tag('tr')
	left(builder, args, year, itemNum)
	right(builder, args, year, itemNum, itemList)
end

--------------------------------------------------------------------------------

function p.main(frame)
	local args = getArgs(frame)
	return frame:extensionTag{ name = 'templatestyles', args = { src = 'Timeline of release years/styles.css'} } .. tostring(p._main(args))
end

function p._main(args)
	-- Main module code goes here.
	local currentyear = os.date('%Y')

	local ret
	local firstyear, lastyear
	local TBA = items(args, 'TBA') > 0 and true or false

	ret = mw.html.create( 'table' )
		:addClass(args.align == 'left' and 'wikitable release_timeline rt_left' or 'wikitable release_timeline')

	ret:tag('caption')
		:addClass('rt_caption')
		:addClass('nowrap')
		:wikitext((args.title or 'Release timeline')..(args.subtitle and ('<div class="rt_subtitle">'..args.subtitle..'</div>') or ''))

	if tonumber(args.first) then
		firstyear = tonumber(args.first)
	else
		for i = 1, currentyear do
			if items(args, i) > 0 then
				firstyear = i
				break
			end
		end
		firstyear = firstyear or (currentyear + 3)
	end

	if tonumber(args.last) then
		lastyear = tonumber(args.last)
	else
		for i = currentyear + 3, TBA and currentyear or firstyear, -1 do
			if items(args, i) > 0 then
				lastyear = i
				break
			end
		end
		lastyear = lastyear or (currentyear - 1)
	end

	for year = firstyear, lastyear do
		row(ret, args, year)
	end

	if TBA then
		row(ret, args, 'TBA')
	end

	return ret
end

return p