local p = {}

local lang -- Lazy initialize
local function formatDate(fmt, d)
	lang = lang or mw.language.getContentLanguage()
	local success, newDate = pcall(lang.formatDate, lang, fmt, d)
	if success then
		return newDate
	else
		error(string.format(
			"invalid date '%s' passed to getDate",
			tostring(date)
		))
	end
end
	
local function caltoc(days, unk, footer, month, year)
	local weekdays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'}
	local j = tonumber(formatDate('N','1 ' .. month .. ' ' .. year))
	local N = tonumber(formatDate('t','1 ' .. month .. ' ' .. year))
	local res = {}

	table.insert(res, '__NOTOC__<table role="navigation" id="toc" class="wikitable toc hlist" style="text-align:center">')
	table.insert(res, '<tr><th colspan=7 id="toctitle" style="background:inherit"><span id="tocheading" style="font-weight:bold">' .. month .. ' ' .. year .. '</span></th></tr>')
    table.insert(res, '<tr><th scope="col">' .. table.concat(weekdays, '</th><th scope="col">') .. '</th></tr>')

    local d = 1-j
    local skip = false
    while d <= N do
    	table.insert(res, '<tr>')
    	for i=1,7 do
    		d = d + 1
    		if d > 0 and d <= N then
    			local f = days[tostring(d)]
    			if f and f == 'df' then
    				table.insert(res, '<td>[[#' .. d .. ' ' .. month .. '|' .. d .. ']]</td>')
    			elseif f and f == 'mf' then
    				table.insert(res, '<td>[[#' .. month .. ' ' .. d .. '|' .. d .. ']]</td>')
    			else
    				table.insert(res, '<td>' .. d .. '</td>')
    			end
    			skip = false
    		elseif (skip == false) then
    			local cs = (d <= 0) and (1 - d) or (8 - i)
    			local v = ''
    			if d > N and cs > 2 and unk then
    				v = '[[#' .. unk .. '|' .. unk .. ']]'
    				unk = nil
    			end
    			if cs < 7 or v ~= '' then
	    			table.insert(res, '<td' .. (cs > 1 and ' colspan=' .. cs or '') .. '>' .. v .. '</td>')
	    		end
    			skip = true
    		end
    	end
    	table.insert(res, '</tr>')
    end
    if unk ~= nil then
		table.insert(res, '<tr><td colspan=7>[[#' .. unk .. '|' .. unk .. ']]</td></tr>')
	end
    if #footer > 0 then
    	table.insert(res, '<tr>')
    	if #footer > 1 then
    		table.insert(res, '<td colspan=7 style="padding: 0.2em;">')
	    	for k,v in ipairs(footer) do
				table.insert(res, '* [[#' .. v .. '|' .. v .. ']]')
			end
			table.insert(res, '</td>')
		else
			table.insert(res, '<td colspan=7>[[#' .. table.concat(footer,'') .. '|' .. table.concat(footer,'') .. ']]</td>')
		end
		table.insert(res, '</tr>')
	end
	table.insert(res, '</table>')
	
	return table.concat(res, '\n')
end

local function listtoc(founddays, days, unk, footer, month)
	local starttxt = [[
__NOTOC__<!--
--><div role="navigation" id="toc" class="toc plainlinks hlist" aria-labelledby="tocheading" style="text-align:left;">
<div id="toctitle" class="toctitle" style="text-align:center;"><span id="tocheading" style="font-weight:bold;">Contents</span></div>
<div style="margin:auto;">
]]
	local closetxt = [[</div></div>]]
	local entries = (#founddays > 0) and { ';' .. month} or {}
	for k,d in ipairs(founddays) do
		local fmt = days[d] 
		if fmt == 'df' then
			table.insert(entries, ': [[#' .. d .. ' ' .. month .. '|' .. d .. ']]')
		elseif fmt == 'mf' then
			table.insert(entries, ': [[#' .. month .. ' ' .. d .. '|' .. d .. ']]')
		end
	end
	if unk ~= nil then
		table.insert(entries, ': [[#' .. unk .. '|' .. unk .. ']]')
	end
	for k,v in ipairs(footer) do
		table.insert(entries, ': [[#' .. v .. '|' .. v .. ']]')
	end
	return starttxt .. table.concat(entries,"\n") .. closetxt
end

local function getYear(s,y)
	if y and mw.ustring.match(y, '^%d+$') then
		return y
	end
	y = mw.ustring.gsub(s, '^.-(%d+).-$', '%1')
	return y
end

local function getMonth(s,m)
	local mnames = {
		['January']=1,
		['February']=2, 
		['March']=3,
		['April']=4,
		['May']=5,
		['June']=6,
		['July']=7,
		['August']=8,
		['September']=9,
		['October']=10,
		['November']=11,
		['December']=12
	}
	if m and mnames[m] then
		return m
	end
	
	for k,n in pairs(mnames) do
		if mw.ustring.match(s or '', k) then
			return k
		end
	end
	
	return ''
end

function p.main(frame)
	local args = frame.args
	local pargs = frame:getParent().args
	local current_title = mw.title.getCurrentTitle()
	local pagename = current_title.text
	local content = current_title:getContent()
	local outfmt = args['format'] or pargs['format'] or ''
	local unknown = nil
	
	if args['_demo'] or pargs['_demo'] then
		content = args['_demo'] or pargs['_demo'] or ''
	end
	
	if not content then
		error "The current page has no content"
	end
	
	-- Remove comments
	content = mw.ustring.gsub(content, '<!--.-?-->', '')

	-- Get the month and year	
	local month = getMonth(pagename, args['month'] or pargs['month'] or '')
	local year = getYear(pagename, args['year'] or pargs['year'] or '')

	-- Get list of valid footer links	
	local extra = args['extra'] or pargs['extra'] or ''
	local footerlinks = {}
	if extra ~= '' then
		footerlinks = mw.text.split(extra, '%s*=%s*')
	else
		footerlinks = {"See also", "References", "Notes", "Further reading", "External links"}
	end
	local validfooter = {}
	for k,v in ipairs(footerlinks) do
		validfooter[v] = 1
	end
	
	-- Get all the level two headings for days of the month
	local days = {}
	local founddays = {}
	local footer = {}
	for v in mw.ustring.gmatch(content, "%f[^\n]==%s*([^\r\n]-)%s*==%f[^=]") do
		v = mw.ustring.gsub(v,'^[=%s]*(.-)[%s=]*', '%1')
		local df = mw.ustring.gsub(v,'^(%d+[%-–%d]*)%s*' .. month .. '$', '%1')
		local mf = mw.ustring.gsub(v,'^' .. month .. '%s*(%d+[%-–%d]*)$', '%1')
		if tonumber(df) then
			days[df] = 'df'
			table.insert(founddays, df)
		elseif tonumber(mf) then
			days[df] = 'mf'
			table.insert(founddays, mf)
		elseif v == "Unknown date" then
			unknown = "Unknown date"
		elseif validfooter[v] then
			table.insert(footer, v)
		end
	end

	-- Now generate the TOC
	if outfmt ~= 'list' then
		return caltoc(days, unknown, footer, month, year)
	end

	return listtoc(founddays, days, unknown, footer, month)
end

return p