-- This module may be used to compare the arguments passed to the parent
-- with a list of arguments, returning a specified result if an argument is
-- on the list
local p = {}

local function trim(s)
	return s:match('^%s*(.-)%s*$')
end

local function isnotempty(s)
	return s and trim(s) ~= ''
end

function p.check (frame)
	local args = frame.args
	local pargs = frame:getParent().args
	local ignoreblank = isnotempty(frame.args['ignoreblank'])
	local deprecated = frame.args['category']
	local preview = frame.args['preview'] or 'Page using [['..frame:getParent():getTitle()..']] with deprecated parameter _VALUE_'

	local dep_values = {}
	local values = {}
	local res = {}

	-- create the table of deprecated values and their matching new value
	for k, v in pairs(args) do
		if k == 'ignoreblank' or k == 'preview' or k == 'deprecated' then else
			dep_values[k] = v
		end
	end
	
	if isnotempty(preview) then 
		preview = '<div class="hatnote" style="color:red"><strong>Warning:</strong> ' .. preview .. ' (this message is shown only in preview).</div>'
	elseif preview == nil then
		preview = deprecated
	end

	-- loop over the parent args and see if any are deprecated
	for k, v in pairs(pargs) do
		if ignoreblank then
			if dep_values[k] and v~='' then
				table.insert(values, k)
			end
		else
			if dep_values[k] then
				table.insert(values, k)
			end	
		end
	end

	-- add resuls to the output tables
	if #values > 0 then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			deprecated = preview
			for k, v in pairs(values) do
				if v == '' then
				-- Fix odd bug for | = which gets stripped to the empty string and
				-- breaks category links
				v = ' '
				end
				local r =  deprecated:gsub('_VALUE_', ('"'..v..'". replace with "'..dep_values[v]..'"'))
				table.insert(res, r)
			end
		else
			for k, v in pairs(values) do
				local r =  deprecated:gsub('_VALUE_', v)
				table.insert(res, r)
			end
		end
	end

	return table.concat(res)
end

return p