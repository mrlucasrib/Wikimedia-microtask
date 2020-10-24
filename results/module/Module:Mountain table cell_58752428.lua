-- This module implements [[Template:Mountain table cell]]
local p = {}

function p.row(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)

	local res = '|'	
	if args[1] then
		local n = args['name'] and '[[' .. args[1] .. '|' .. args['name'] .. ']]' or '[[' .. args[1] .. ']]'
		res = res .. n
		
		local refs = {}
		local notes = {}
		if args['hp'] then
			table.insert(notes, {'X', 'The summit of ' .. n .. ' is the highest point of ' .. args['hp'] .. '.'})
		end
		if args['peak'] then
			table.insert(notes, {'Y', n .. ' ' .. args['peak'] .. '.'})
		end
		if args['note'] then
			table.insert(notes, {'Z', args['note'] .. '.'})
		end
		if args['ngs'] then
			local r = frame:expandTemplate{ title = 'cite web', args = {
				title = args['stn'] or args['name'] or args[1],
				url = 'http://www.ngs.noaa.gov/cgi-bin/ds_mark.prl?PidBox=' .. args['ngs'],
				work = 'Datasheet for NGS Station ' .. args['ngs'],
				publisher = '[[U.S. National Geodetic Survey]]',
				accessdate = args['date']} }
			table.insert(refs, {'D', r})
		end
		if args['gnis'] then
			local r = frame:expandTemplate{ title = 'cite gnis', 
				args = {name = args['name'] or args[1], id = args['gnis']} }
			table.insert(refs, {'E', r})
		end
		if args['nrc'] then
			local r = frame:expandTemplate{ title = 'cite web', args = {
				title = args['name'] or args[1],
				url = 'http://www4.rncan.gc.ca/search-place-names/unique?id=' .. args['nrc'],
				work = 'Geographical Names of Canada',
				publisher = '[[Natural Resources Canada]]',
				accessdate = args['date']} }
			table.insert(refs, {'F', r})
		end
		if args['vo'] then
			local rnd = require('Module:Math')._round
			local vo = tonumber(args['vo'])
			vo = (vo > 0 and '+' or '') .. vo .. '&nbsp;m (' .. rnd(vo / 0.3048, 1) .. '&nbsp;ft)'
			table.insert(notes, {'G', 'The summit elevation of ' .. n .. ' includes a vertical offset of ' .. vo .. ' from the station benchmark.'})
		end
		if args['va'] then
			local rnd = require('Module:Math')._round
			local va = tonumber(args['va'])
			va = (va > 0 and '+' or '') .. va .. '&nbsp;m (' .. rnd(va / 0.3048, 2) .. '&nbsp;ft)'
			table.insert(notes, {'H', 'The elevation of ' .. n .. ' includes an adjustment of ' .. va .. ' from [[NGVD 29|NGVD&nbsp;29]] to [[NAVD 88|NAVD&nbsp;88]].'})
		end
		if args['pb'] and args['nor'] == nil then
			local r = frame:expandTemplate{ title = 'cite web', args = {
				title = args['name'] or args[1],
				url = 'http://www.peakbagger.com/peak.aspx?pid=' .. args['pb'],
				website = 'Peakbagger.com',
				accessdate = args['date'] } }
			table.insert(refs, {'I', r})
		end
		if args['cme'] and args['nor'] == nil then
			local r = frame:expandTemplate{ title = 'cite web', args = {
				title = args['name'] or args[1],
				url = 'http://www.bivouac.com/MtnPg.asp?MtnId=' .. args['cme'],
				website = 'Bivouac.com',
				accessdate = args['date'] } }
			table.insert(refs, {'J', r})
		end
		if args['pw'] and args['nor'] == nil then
			local r = frame:expandTemplate{ title = 'cite peakware', args = {
				title = args['name'] or args[1],
				id = args['pw'],
				accessdate = args['date'] } }
			table.insert(refs, {'K', r})
		end
		for i, r in ipairs(refs) do
			res = res .. frame:extensionTag ('ref', r[2], {name=r[1] .. '_' .. args[1]})
		end
		for i, r in ipairs(notes) do
			res = res .. frame:extensionTag ('ref', r[2], {name=r[1] .. '_' .. args[1], group='lower-alpha'})
		end
		if args['alt'] then
			res = res .. '<br/>' .. '([[' .. args[1] .. '|' .. args['alt'] .. ']])'
		end
	end
	
	return res
end

return p