require('Module:No globals')
local getArgs = require('Module:Arguments').getArgs

local p = {}
function p.infobox(frame, args)
	if not args then
		args = getArgs(frame)
	end

	local root = mw.html.create()
	local columns = args.party_column and 4 or 3
	mw.log(columns)
	
	if args.caption then
		args.caption = '<br />' .. tostring(
			mw.html.create('span')
				:cssText(args.captionstyle)
				:wikitext(args.caption)
			)
	end
	if args.topcaption then
		args.topcaption = '<br />' .. tostring(
			mw.html.create('span')
				:cssText(args.topcaptionstyle)
				:wikitext(args.topcaption)
			)
	end
	
	local floatcss = {
		left = 'margin-left:0; margin-right:1em; float:left; clear:left;',
		center = 'margin-left:auto; margin-right:auto; float:none; clear:none;',
		none = 'margin-left:0; margin-right:0; float:none; clear:none;',
		right = 'margin-left:1em; margin-right:0; float:right; clear:right;'
	}
	
	root = root
		:tag('table')
		:addClass('infobox')
		:css('width', 'auto')
		:css('text-align', 'left')
		:css('line-height', '1.2em')
		:cssText(args.float and floatcss[(args.float):lower()] or floatcss['right'])

	if args.topimage then
		root
			:tag('tr'):tag('td')
				:attr('colspan', columns)
				:css('text-align', 'center')
				:wikitext(require('Module:InfoboxImage').InfoboxImage{args = {
							image = args.topimage,
							size = args.topimagesize,
							sizedefault = 'frameless',
							upright = 1,
							alt = args.topimagealt
						}} .. (args.topcaption or '')
					)
	end
	if args.above then
		root
			:tag('tr'):tag('th')
				:attr('colspan', columns)
				:css('line-height','1.5em')
				:css('font-size','110%')
				:css('background','#DCDCDC')
				:css('text-align', 'center')
				:wikitext(args.above)
	end
	if args.image then
		root
			:tag('tr'):tag('td')
				:attr('colspan', columns)
				:css('text-align', 'center')
				:wikitext(require('Module:InfoboxImage').InfoboxImage{args = {
							image = args.image,
							size = args.imagesize,
							sizedefault = 'frameless',
							upright = 1,
							alt = args.imagealt
						}} .. (args.caption or '')
					)
	end
	local header = root:tag('tr')
	header:tag('th')
		:wikitext(args.office_label or 'Office')
	header:tag('th')
		:wikitext(args.name_label or 'Name')
	if args.party_column then 
		header:tag('th')
			:wikitext(args.party_label or 'Party')
	end
	header:tag('th')
		:wikitext(args.term_label or 'Term')
	root:tag('tr')
			:tag('td')
				:attr('colspan', columns)
				:css('background', '#000')

	local subRows = {}
	local keys = {}
	for k,v in pairs(args) do
		k = tostring(k)
		local num = k:match('^office(%d+)$') 
		if num and args['name' .. num .. 'a'] then
			num = tonumber(num)
			if subRows[num] == nil then 
				subRows[num] = {} 
				table.insert(keys, num)
			end
		end

		local num,l = k:match('^name(%d+)([a-z])$')
		if num then
			num = tonumber(num)
			if subRows[num] == nil then 
				subRows[num] = {}
				table.insert(keys,num)
			end
			subRows[num][l] = l
		end
	end
	
	table.sort(keys)

	for i, num in ipairs(keys) do 
		if i > 1 then
			root:tag('tr')
				:tag('td')
					:attr('colspan',columns)
					:css('background','#D1D1D1')
		end
		local r = {}
		for j,l in pairs(subRows[num]) do
			table.insert(r,l)
		end
		table.sort(r)
		local row = root:tag('tr')
		local ocell = row:tag('td'):wikitext(args['office' .. num])
		local subrow = 0
		for j, l in pairs(r) do
			subrow = subrow + 1
			if subrow > 1 then
				row:tag('tr')
			end
			row:tag('th')
				:css('font-weight', 'bold')
				:wikitext(args['name'..num..l])
			if args.party_column then
				row:tag('td')
					:wikitext(args['party'..num..l])
			end
			row:tag('td')
				:wikitext(args['term'..num..l])
		end
		ocell:attr('rowspan', (subrow > 1) and subrow or nil)
	end
	
	if args.below then
		root:tag('tr')
			:tag('td')
				:attr('colspan', columns)
				:css('border-top', '#D1D1D1 2px solid')
				:wikitext(args.below)
	end

	return tostring(root)
end
return p