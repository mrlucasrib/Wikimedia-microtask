p = {} 
function p.main( frame )
	local args = {}
	local nArgs = 0
	for k, v in pairs(require('Module:Arguments').getArgs(frame)) do
		if tonumber(k) then nArgs = math.max(nArgs, k) end
		args[k] = v
	end
	use_dmy_dates = require('Module:Citation/CS1/Configuration').global_df == 'dmy-all'
	if args['df'] or (use_dmy_dates and not args['mf'])
		then df = 'df=y' else df = 'mf=y'
	end
	if args['nowrap'] == 'no' or args['nowrap'] == 'n' or args['wrap'] 
		then nowrap = '' else nowrap = '|class=nowrap'
	end
	if args['tv'] or args['TV']
		then tv = ' television' else tv = ''
	end
	if args['cats'] == 'no' or args['cats'] == 'n' or args['nocats']
		then addCats = false else addCats = true
	end 
	if mw.title.getCurrentTitle().namespace ~= 0 and string.lower(args['demospace'] or '') ~= 'main' then
		addCats = false
	end
	if nArgs == 0 then return '' end
	local rows = {}
	local i = 1
	local n = 1
	while n <= nArgs do 
		local p1,p2,p3,p4 = args[n], args[n+1] or '', args[n+2] or '', args[n+3]
		local sd = {}
		local yyyy,mm,dd = tonumber(p1), tonumber(p2), tonumber(p3)
		if yyyy then
			table.insert(sd, yyyy)
			if mm then
				table.insert(sd, mm)
				if dd then
					table.insert(sd, dd)
				else
				end
			else
			end
			table.insert(sd, df)
			local xx = nil
			local n2 = n + 1
			while n2 <= math.min(nArgs, n+3) do
				if args[n2] and not tonumber(args[n2]) then xx = args[n2] break end
				n2 = n2 + 1
			end
			
			local r = {}
			table.insert(r, '{{start date|'..table.concat(sd, '|')..'}}')
			if xx then
				n = n2 + 1
				table.insert(r, '('..xx..')')
			else
				n = n + 3
			end
			local t = os.time{year=yyyy or 2525, month=mm or 1, day=dd or 1}
			table.insert(rows, {t, '*'..table.concat(r, ' ')..(args['ref'..i] or '')..'\n'})
		else
			n = n + 1
		end
		i = i + 1
	end
	if #rows == 0 then return '' end
	table.sort(rows, function(a, b) return a[1] < b[1] end)
	local li = {}
	for i = 1,#rows do table.insert(li, rows[i][2]) end
	local html = '{{plainlist|'..table.concat(li)..nowrap..'}}'
	if addCats then
		html = html..'[[Category:'..os.date("%Y", rows[1][1])..tv..' films]]'
		if rows[1][1] > os.time() then 
			html = html..'[[Category:Upcoming'..tv..' films]]'
		end
	end
	return frame:preprocess(html)
end

return p