local p = {}

local function isnotempty(s)
	return s and s:match('%S')
end

function p.main(frame)
	local player = {}
	local coach = {}
	local pargs = frame:getParent().args
	local tracking = ''
	local iargs = {}
	local pmax = tonumber(frame.args['pmax'] or '40') or 40
	local cmax = tonumber(frame.args['cmax'] or '30') or 30
	for k,v in pairs(pargs) do
		if type(k) == 'string' and isnotempty(v) then
			if k:match('^team%d%d*$') then
				local num = mw.ustring.gsub(k,'^team(%d%d*)$','%1')
				table.insert(player, {tonumber(num) or 0, pargs['years' .. num] or '', v})
			elseif k:match('^cteam%d%d*$') then
				local num = mw.ustring.gsub(k,'^cteam(%d%d*)$','%1')
				table.insert(coach, {tonumber(num) or 0, pargs['cyears' .. num] or '', v})
			end
		end
	end
	
	table.sort(player, function (a, b) return a[1] < b[1] end)
	table.sort(coach, function (a, b) return a[1] < b[1] end)
	
	local i = 1
	if #player > 0 then
		iargs['header' .. i] = frame.args['pheader'] or 'As player:'
		i = i + 1
		for k,v in ipairs(player) do
			if v[2] ~= '' then iargs['label' .. i] = v[2] end
			if v[3] ~= '' then iargs['data' .. i] = v[3] end
			i = i + 1
		end
	end
	if #coach > 0 then
		iargs['header' .. i] = frame.args['cheader'] or 'As coach:'
		i = i + 1
		for k,v in ipairs(coach) do
			if v[2] ~= '' then iargs['label' .. i] = v[2] end
			if v[3] ~= '' then iargs['data' .. i] = v[3] end
			i = i + 1
		end
	end
	
	if i > 1 then
		iargs['child'] = 'yes'
		iargs['labelstyle'] = 'font-weight: normal;' .. (frame.args['yearstyle'] or '')
		iargs['headerstyle'] = 'line-height: 1.2em;text-align: left;' .. (frame.args['headerstyle'] or '')
		iargs['datastyle'] = 'line-height: 1.2em;text-align: left;' .. (frame.args['teamstyle'] or '')
		if #player > pmax then
			tracking = tracking .. (frame.args['pmaxcat'] or '')
		end
		if #coach > cmax then
			tracking = tracking .. (frame.args['cmaxcat'] or '')
		end
		return (frame.args['title'] or 'Career history') .. require('Module:Infobox').infobox(iargs) .. tracking
	end
	
	return tracking
end

return p