local getArgs = require('Module:Arguments').getArgs

p = {}

local function add_header_row(frame, tbl, text)
	local row = tbl:tag('tr')
	row:tag('th')
		:attr('colspan', '2')
		:wikitext(text)
end

local function edit(frame, pagename)
	return frame:expandTemplate{ title='edit', args={ pagename } }
end

local function add_template_row(frame, tbl, pagename)
	local row = tbl:tag('tr')
	row:tag('td')
		:wikitext(frame:expandTemplate{ title='tl', args={ pagename } })
	row:tag('td')
		:wikitext(edit(frame, 'Template:' .. pagename))
end

local function add_wikilink_row(frame, tbl, pagename, text, right)
	local row = tbl:tag('tr')
	row:tag('td')
		:wikitext('[[' .. pagename .. '|' .. (text or pagename) .. ']]')
	row:tag('td')
		:wikitext(right or edit(frame, pagename))
end

local function add_section(frame, args, tbl, add_section_header, arg_prefix, page_prefix, row_function)
	if row_function == nil then
		row_function = add_wikilink_row
	end
	local nums = {}
	for k, _ in pairs(args) do
		if type(k) == 'string' then
			local num = k:match('^' .. arg_prefix .. '(%d+)$')
			if num then
				table.insert(nums, tonumber(num))
			end
		end
	end
	if #nums == 0 then
		return
	end
	table.sort(nums)
	add_header_row(frame, tbl, add_section_header)
	for _, num in ipairs(nums) do
		local arg_name = arg_prefix .. num
		local arg = args[arg_name]
		local pagename = page_prefix .. arg
		local text = args[arg_name .. 'text']
		local right = args[arg_name .. 'right']
		row_function(frame, tbl, pagename, text or arg, right)
	end
end

local function main(frame)
	local args = getArgs(frame)
	local tbl = mw.html.create('table')
		:cssText('float:right; border:1px navy solid;')
	tbl:tag('caption')
		:wikitext('Portal toolbox')
	add_header_row(frame, tbl, 'Main portal page')
	local rootTitle = mw.title.getCurrentTitle().rootPageTitle.subjectPageTitle
	add_wikilink_row(frame, tbl, rootTitle.fullText)
	
	add_section(frame, args, tbl, 'Static subpages', 'static', rootTitle.fullText .. '/')
	add_section(frame, args, tbl, 'Dynamic subpages', 'dynamic', rootTitle.fullText .. '/')
	add_section(frame, args, tbl, 'Templates', 'template', '', add_template_row)
	add_section(frame, args, tbl, 'Other', 'other', '')
	return tbl
end

p.main = main

return p