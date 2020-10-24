require('Module:No globals')

local p = {}

local function format_score(s)
	s = mw.ustring.gsub(s or '', '^[%s\']*([%d%.]+)[%s\']*[–−—%-][%s\']*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*([%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[%[[^%[%]]*%|[%d%.]+)%s*%-%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[[^%[%]%s]*%s+[%d%.]+)%s*%-%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[%[[^%[%]]*%|[%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[[^%[%]%s]*%s+[%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	return s
end

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame, { parentFirst = true })
	local n1 = args[1] or 'X'
	local n2 = args[2] or 'X'
	local s  = args['sc'] or (n1..'–'..n2)

	s = format_score(s)
	
    -- following codes obtained from Module:Sports results
	-- delink if necessary
	if s:match('^%s*%[%[[^%[%]]*%|([^%[%]]*)%]%]') then
		s = s:match('^%s*%[%[[^%[%]]*%|([^%[%]]*)%]%]')
	end
	if s:match('^%s*%[[^%[%]%s]*%s([^%[%]]*)%]') then
		s = s:match('^%s*%[[^%[%]%s]*%s([^%[%]]*)%]')
	end
	
	-- get the scores
	local s1 = tonumber(mw.ustring.gsub( s or '',
		'^%s*([%d][%d%.]*)%s*–%s*([%d][%d%.]*).*', '%1' ) or nil)
		or mw.ustring.gsub(s or '', '^([WL]*)–([WL]*).*', '%1' )
		or ''
	local s2 = tonumber(mw.ustring.gsub( s or '',
		'^%s*([%d][%d%.]*)%s*–%s*([%d][%d%.]*).*', '%2' ) or nil)
		or mw.ustring.gsub(s or '', '^([WL]*)–([WL]*).*', '%2' )
		or ''
	

	if type(s1) == 'number' and type(s2) == 'number' then
		return (s1 > s2) and 'W' or ((s2 > s1) and 'L' or 'T')
	elseif s1:match('[WL]') and s2:match('[WL]') and s1 ~= s2 then
		return s1
	else
		return string.format("''%s''", 'Result unknown')
	end
end

return p