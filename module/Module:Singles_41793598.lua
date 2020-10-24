local p = {}

-- Ripped from Module:Infobox. TODO: Make a utility module that can do this kind of thing
local function getArgNums(args, prefix)
    -- Returns a table containing the numbers of the arguments that exist
    -- for the specified prefix. For example, if the prefix were to be 'data', and
    -- 'data1', 'data2', and 'data5' were to exist, it would return {1, 2, 5}.
    local nums = {}
    for k, v in pairs(args) do
        local num = tostring(k):match('^' .. prefix .. '([1-9]%d*)$')
        if num then table.insert(nums, tonumber(num)) end
    end
    table.sort(nums)
    return nums
end

-- Forked from Module:Unsubst-infobox

local specialParams = {
	['$B'] = 'template content'
}

p[''] = function ( frame )
	if not frame.args['$B'] then
		error( '{{#invoke:Singles|}} requires parameter $B (template content)' )
	end

	if mw.isSubsting() then
		---- substing
		-- Passed args
		local args = {}
		for k, v in pairs( frame:getParent().args ) do
			args[k] = v
		end

		-- Build an equivalent template invocation
		-- First, find the title to use
		local titleobj = mw.title.new(frame:getParent():getTitle())
		local title
		if titleobj.namespace == 10 then -- NS_TEMPLATE
			title = titleobj.text
		elseif titleobj.namespace == 0 then -- NS_MAIN
			title = ':' .. titleobj.text
		else
			title = titleobj.prefixedText
		end

		-- Remove empty fields
		for k, v in pairs( args ) do
			if v == '' then args[k] = nil end
		end

		-- Pull aliases
		local nums = getArgNums(args, '[Ss]ingle ?')
		for _, num in ipairs(nums) do
			args['single' .. num] = args['single' .. num] or args['single ' .. num] or args['Single ' .. num]
			args['single' .. num .. 'date'] = args['single' .. num .. 'date'] or args['single ' .. num .. ' date'] or args['Single ' .. num .. ' date'] or ''
			args['single ' .. num], args['Single ' .. num], args['single ' .. num .. ' date'], args['Single ' .. num .. ' date'] = nil, nil, nil, nil
		end
		for k, v in pairs( {Type = 'type', Name = 'name'} ) do
			if args[k] and not args[v] then args[v], args[k] = args[k], nil end
		end

		-- Build the invocation body
		local ret = '{{' .. title

		-- Make parameter list
		local params = {'name', 'type'}
		for _, num in ipairs( nums ) do table.insert( params, 'single' .. num ); table.insert( params, 'single' .. num .. 'date' ) end

		-- Align parameters correctly and remove extra ones
		local maxlength = 0
		for k, v in ipairs( params ) do
			local tmp = mw.ustring.len( v )
			if tmp > maxlength then maxlength = tmp end
		end

		for k, v in ipairs( params ) do
			ret = ret .. '\n | ' .. v .. string.rep(' ', (maxlength - mw.ustring.len( v ))) .. ' = ' .. (args[v] or '')
		end

		ret = ret .. '\n}}'

		ret = mw.ustring.gsub(ret, '%s+\n', '\n')

		return ret
	else
		-- Not substing
		-- Just return the "body"
		return frame.args['$B']
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {wrappers = 'Template:Singles'})
	local out = ''
	local nums = getArgNums(args, '[Ss]ingle ?')
	for _, num in ipairs(nums) do
		out = out .. '\n# <span class="item"><span class="fn">"' .. (args['single' .. num] or args['single ' .. num] or args['Single ' .. num]) .. '"</span>'
		local date = args['single' .. num .. 'date'] or args['single ' .. num .. ' date'] or args['Single ' .. num .. ' date']
		if date then
			out = out .. '<br />Released: ' .. date
		end
		out = out .. '</span>'
	end
	
	if out ~= '' then
		if mw.ustring.match(out, '</?t[drh][ >]') then out = out .. ' [[Category:Music infoboxes with malformed table placement|R]]' end
		return '<div style="text-align:left">' .. out .. '\n</div>'
	end
	
	return out
end

return p