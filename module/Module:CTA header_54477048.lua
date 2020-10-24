local getArgs = require('Module:Arguments').getArgs
local p = {}

function p.main(frame)
	local args = getArgs(frame, {parentOnly = true})
	
	local function getArgNums(prefix)
	-- Returns a table containing the numbers of the arguments that exist
	-- for the specified prefix. For example, if the prefix was 'data', and
	-- 'data1', 'data2', and 'data5' exist, it would return {1, 2, 5}.
		local nums = {}
		for k, v in pairs(args) do
	 		local num = tostring(k):match('^' .. prefix .. '([1-9]%d*)$')
			if num then table.insert(nums, tonumber(num)) end
		end
		table.sort(nums)
		return nums
	end
	
	local dataTable = require('Module:Adjacent stations/CTA')['lines']
	local function getColor(line)
		if dataTable[line] then
			return dataTable[line]['color'] or ''
		else
			return ''
		end
	end
	
	local tmp, tmp2
	local color = args.color or ''
	local name = args.name or mw.ustring.gsub(mw.ustring.gsub(mw.title.getCurrentTitle().text, '%s+%b()$', '', 1), ' station', '', 1)
	local grid = (args.grid and '&nbsp;<div style="display:inline-block;vertical-align:middle;line-height:0.9;text-align:'..(((color ~= '') and 'center') or 'right')..'">'..mw.ustring.gsub(args.grid, '%s+', '<br/>')..'</div>') or ''
	tmp2 = mw.ustring.gsub(name, '< ?/? ?[Ss][Mm][Aa][Ll][Ll] ?>', '')
	local size, length, br, size1, align = 15.4*(tonumber(args.size or 1))..'px', mw.ustring.len(tmp2), mw.ustring.match(tmp2, '< */? *[Bb][Rr] */? *>'), '200%', {'', ''}
	if br then
		size1 = '100%'
		tmp2 = mw.text.split(tmp2, '%s*< */? *[Bb][Rr] */? *>%s*')
		for k, v in ipairs(tmp2) do
			tmp2[k] = mw.ustring.len(v)
		end
		if tmp2[2] > tmp2[1] then length = tmp2[2] else length = tmp2[1] end
		if length > 15 then size = 15.4*(tonumber(args.size) or ((1/(0.1*(length-15)+1.7))+0.4))..'px' end
	elseif length > 6 then
		size = 15.4*(tonumber(args.size) or ((1/(0.35*(length-6)+1.7))+0.4))..'px'
	end
	if color ~= '' then
		color = getColor(color)
		return '<div style="color:white;background:#'..color..';height:38px;display:block;vertical-align:middle;line-height:38px;border:0px solid transparent;font-size:'..size..'"><div class="fn org" style="display:inline-block;vertical-align:middle;line-height:1;font-size:'..size1..';text-align:left">'..name..'</div>'..grid..'</div>'
	end
	local colors, total = getArgNums('line'), 0
	for k, v in ipairs(colors) do
		colors[k] = getColor(args['line'..v])
		total = total + 1
	end
	local ratio = {1, 9, 17/3, 8.75, 6.8}
	ratio = mw.clone(ratio[total] or 10)
	total = total+(total-1)/ratio
	local gradient = 'linear-gradient(to bottom'
	local webkitGradient = '-webkit-linear-gradient(top'
	for k, v in ipairs(colors) do
		tmp = ', #'..colors[k]..' '..100*((1+1/ratio)*(k-1))/total..'%, #'..colors[k]..' '..100*(k+(k-1)/ratio)/total..'%'..(colors[k+1] and ', #FFF '..100*(k+(k-1)/ratio)/total..'%'..', #FFF '..100*((1+1/ratio)*k)/total..'%' or '')
		gradient = gradient..tmp
		webkitGradient = webkitGradient..tmp
	end
	gradient = gradient..') 1'
	webkitGradient = webkitGradient..') 1'
	return '<div style="color:white;background:#5F6062;height:38px;display:block;vertical-align:middle;line-height:38px;border-top:0px solid transparent;border-bottom:0px solid transparent;border-left:50px solid #'..(colors[1] or '000000')..';border-right:50px solid #'..(colors[1] or '000000')..';font-size:'..size..';border-image:'..webkitGradient..';border-image:'..gradient..'"><div class="fn org" style="display:inline-block;vertical-align:middle;line-height:1;font-size:'..size1..';text-align:left">'..name..'</div>'..grid..'</div>'
end

return p