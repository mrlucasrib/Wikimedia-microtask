local p = {}

function p.row(frame)
	local data = frame.args[1]
	local div = frame.args['div']
	local result, sep, default = '', ''
	local args = {}
	data = mw.text.split(data, '+')
	for i1, v1 in ipairs(data) do
		args = {}
		if v1 ~= '' and v1 ~= '\\' then
			local tmp = mw.text.split(v1, '\\')
			if i1 == 1 then
				default = tmp[1]
			else
				sep = ' '
			end
			for i2, v2 in ipairs(tmp) do
				if i2 < 5 then
					if i2 == 1 then
						args[i2] = (string.find((v2 or ''), '^%s*$') and default or v2)
					else
						args[i2] = (string.find((v2 or ''), '^%s*$') and nil or v2)
					end
				end
			end
			if args[1] or args[2] then
				result = result .. sep .. frame:expandTemplate{ title = 'Rail-interchange', args = args }
			end
		end
	end
	if div == 'yes' or div == 'y' then result = '<div style="display:table-cell;vertical-align:middle;padding-left:3px;white-space:nowrap">' .. result .. '</div>' end
	return result
end

function p.doublerow(frame)
	local data = frame.args[1]
	local result, sep, default = '', ''
	local args = {}
	local sep_code = {
		[0] = '<br/>',
		[1] = '</div><div style="display:table-cell;vertical-align:middle;padding-left:3px;white-space:nowrap">'
	}
	data = mw.text.split(data, '+')
	for i1, v1 in ipairs(data) do
		args = {}
		if v1 ~= '' and v1 ~= '\\' then
			local tmp = mw.text.split(v1, '\\')
			if i1 == 1 then
				default = tmp[1]
			else
				sep = sep_code[i1 % 2]
			end
			for i2, v2 in ipairs(tmp) do
				if i2 < 5 then
					if i2 == 1 then
						args[i2] = (string.find((v2 or ''), '^%s*$') and default or v2)
					else
						args[i2] = (string.find((v2 or ''), '^%s*$') and nil or v2)
					end
				end
			end
			if args[1] or args[2] then
				result = result .. sep .. frame:expandTemplate{ title = 'Rail-interchange', args = args }
			end
		end
	end
	result = '<div style="display:table-cell;vertical-align:middle;padding-left:3px;white-space:nowrap">' .. result .. '</div>'
	return result
end

return p