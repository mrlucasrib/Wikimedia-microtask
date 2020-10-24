--2020-06-16 fix error when vtos(nil), then it showed two nil
--2020-06-08 if a variable is a function now is displayed as function (before "function")
--2020-06-06 fix error which occasionally happens when a value == nil
local p = {}

p.s = ''
p.tab = {
	oneline = true,
	allidx = false, 
	}
p.dec = -1
p.maxlines = {
	num = 100,
	doerror = true,
	}
p.enabled = true
p.nowiki = false
p.nohtml = false
p._plaintext = false
p.counter = false

local LinCount = 0
local vep = '  •  '
local function MessRaised (n)
	return '\n\nIt has been reached to '..n..', you can change this limit with "maxlines.num".'
end	
local function arrow()
	return ' => '
end

function p.breakline ()
	LinCount = LinCount + 1
	p.s = p.s..'\n\n'
	if p.counter then
		p.s = p.s..LinCount..vep
	end	
	if (LinCount > p.maxlines.num) and p.maxlines.doerror then
		p.pa = p.s..MessRaised(p.maxlines.num)
		error (p.s,0)
	end	
end	--breakline

local function CheckWhereName (wn, what)
	if wn == nil then
		return '"'..what..'" == nil'
	elseif (type(wn) == "table") then
		return 'Table as "'..what..'"!'
	else
		return wn	
	end	
end --CheckWhereName

function p._plain (text) --Modified from "Module:Plain text"
	if not text then return end
	text = mw.text.killMarkers(text)
		:gsub('&nbsp;', ' ') --replace nbsp spaces with regular spaces
		:gsub('<br ?/?>', ', ') --replace br with commas
		:gsub('<span.->(.-)</span>', '%1') --remove spans while keeping text inside
		:gsub('<b>(.-)</b>', '%1') --remove bold while keeping text inside
		:gsub('<i>(.-)</i>', '%1') --remove italic while keeping text inside
		:gsub('<sub>(.-)</sub>', '%1') --remove bold while keeping text inside
		:gsub('<sup>(.-)</sup>', '%1') --remove bold while keeping text inside
		:gsub('<.->.-<.->', '') --strip out remaining tags and the text inside
		:gsub('<.->', '') --remove any other tag markup
		:gsub('%[%[%s*[Ff]ile%s*:.-%]%]', '') --strip out files
		:gsub('%[%[%s*[Ii]mage%s*:.-%]%]', '') --strip out use of image:
		:gsub('%[%[%s*[Cc]ategory%s*:.-%]%]', '') --strip out categories
		:gsub('%[%[[^%]]-|', '') --strip out piped link text
		:gsub('[%[%]]', '') --then strip out remaining [ and ]
		:gsub("'''''", "") --strip out bold italic markup
		:gsub("'''?", "") --not stripping out '''' gives correct output for bolded text in quotes
		:gsub('----', '') --remove ---- lines
		:gsub("^%s+", "") --strip leading
		:gsub("%s+$", "") --and trailing spaces
		:gsub("%s+", " ") --strip redundant spaces
	return text
end --plain

function p._plain_len (text)
	return mw.ustring.len (p._plain(text))
end	
	
function p.plain (frame)
	return p._plain (frame.args[1])
end

function p.plain_len (frame)
	return p._plain_len (frame.args[1])
end

local function totext (text)
	if p._plaintext then
		return p._plain (text)
	else
		return text
	end	
end --totext

local function NumToStr (N)		
	if (p.dec == -1) or (N == math.floor(N)) then
		return tostring(N)
	else
		return tostring (math.floor ((N*10^p.dec)+0.5) / (10^p.dec))
	end	
end	--NumToStr

local iniTab1Line = true
function p.containsTab (avar)
	result = false
	for k,v in pairs(avar) do
		if type(v) == 'table' then
			result = true
			break
		end	
	end
	return result
end --containsTab

local var
	
local function DumTab (tbl, indent)
	if not indent then indent = 1 end
	local toprint = " {\r\n"
	indent = indent + 2 
	for k, v in pairs(tbl) do
		toprint = toprint..string.rep(" ", indent)
		local id = k
		if (type(k) == "string") then
			k = '"'..k..'"'
		end
		toprint = toprint.."["..k.."] = "
		if (type(v) == "number") then
			toprint = toprint..NumToStr(v)..",\r\n"
		elseif (type(v) == "string") then
			toprint = toprint.."\""..totext(v).."\",\r\n"
		elseif (type(v) == "table") then
			if iniTab1Line and (not p.containsTab (v)) then
				local wds = '{'
				for kk,vv in pairs(v) do
					if (p.tab.allidx == true) or (type(kk) ~= 'number')  then 
						wds = wds..'['..kk..']='..var(vv)..', '
					else	
						wds = wds..var(vv)..', '
					end
				end
				toprint = toprint..wds.."},\r\n"
			else	
				toprint = toprint..DumTab(v, indent + 2)..",\r\n"
			end
		else
			toprint = toprint.."\""..tostring(v).."\",\r\n"
		end
	end
	toprint = toprint..string.rep(" ", indent-2).."}"
	return toprint
end --DumTab

function var (avar)
	local EndStr = ''
	if avar == nil then	
		EndStr = 'nil'
	elseif type(avar) == 'table' then
		if #avar > 0 then
			p.s = p.s..'\r\n'
		end	
		if p.tab.oneline then
			local wds = '{ '
			for k,v in pairs(avar) do
				if (p.tab.allidx == true) or (type(k) ~= 'number')  then 
					wds = wds..'['..k..']='..var(v)..', '
				else	
					wds = wds..var(v)..', '
				end
			end
			EndStr = wds .. '} '
		else
			EndStr = DumTab (avar)
		end	
	elseif type(avar) == 'number' then
		EndStr = NumToStr (avar)
	elseif type(avar) == 'boolean' then
		if avar == true then
			EndStr = 'true'
		else
			EndStr = 'false'
		end	
	elseif type(avar) == 'function' then	
		EndStr = 'function'
	else
		avar = totext (tostring(avar))
		if p.nohtml then
			avar = string.gsub (avar, "<", "⪡")
			avar = string.gsub (avar, ">", "⪢")
		end	
		EndStr = '"'..avar..'"'
	end
	return EndStr
end --var

function p.w (where)
	if p.enabled then
		return CheckWhereName (where, 'w')
	end	
end --w

local function varx (avar)
	iniTab1Line = p.tab.oneline
	if p.tab.oneline and (type(avar) == 'table') then
		p.tab.oneline = not p.containsTab(avar)
	end
	local ss = var(avar)
	p.tab.oneline = iniTab1Line
	return ss
end --varx

function p.v (...)
	if p.enabled then
		local str = ''
		if #arg == 0 then
			str = 'nil'
		else
			local c = 0
			for k, i in ipairs(arg) do
				c = k
			end	
			--error (c)
			for i = 1, #arg do
				if str ~= '' then
					str = str..vep
				end	
				str = str..varx(arg[i])
			end	
		end	
		return str
	end	
end	--v

function p.wv (where, ...)
	if p.enabled then
		return CheckWhereName(where,'w')..arrow()..p.v(unpack(arg))
	end	
end	--wv

function p.nv (...)
	if p.enabled then
		if math.mod(#arg,2) ~= 0 then
			EndStr = 'Any parameter has not a name or variable'
		else
			local s = ''
			local IsName = true
			function Concat(wds)
				if s ~= '' then
					if IsName then
						s = s..vep
					else	
						s = s..': '
					end	
				end
				s = s..wds
			end
			for i = 1, #arg do
				if IsName then
					Concat (CheckWhereName(arg[i],'n'))
					IsName = false
				else	
					Concat (varx(arg[i]))
					IsName = true
				end	
			end
			EndStr = s
		end
		return EndStr
	end	
end --nv

function p.wnv (where, ...)
	if p.enabled then
		return CheckWhereName(where,'w')..arrow()..p.nv (unpack(arg))
	end	
end

----------

local function EnabAndBl ()
	if p.enabled then
		if LinCount < p.maxlines.num then
			p.breakline ()
			return true
		else
			p.s = p.s..MessRaised(p.maxlines.num)
			error (p.s)
			return false
		end	
	else
		return false
	end
end --EnabAndBl

function p.wtos (where)
	if EnabAndBl () then
		p.s = p.s..p.w (where)
	end	
end --wtos

function p.vtos (...)
	if EnabAndBl () then
		local end_nil_count = arg["n"] - #arg
		p.s = p.s..p.v (unpack(arg))
		if #arg == 0 then
			end_nil_count = end_nil_count-1
		end	
		for i = 1, end_nil_count do
			p.s = p.s..vep..'nil'
		end	
	end	
end --vtos

function p.wvtos (where, ...)
	if EnabAndBl () then
		p.s = p.s..p.wv (where,unpack(arg))
	end	
end --wvtos

function p.nvtos (...)
	if EnabAndBl () then
		local end_nil_count = arg["n"] - #arg
		if end_nil_count > 0 then
			for i = 1, arg["n"] do
				if math.mod(i,2) ~= 0 then
					p.s = p.s..arg[i]..': '
				else
					p.s = p.s..p.v(arg[i])
					if i < arg["n"] then
						p.s = p.s..vep
					end	
				end	
			end	
		else
			p.s = p.s..p.nv (unpack(arg))
		end	
	end	
end --nvtos

function p.wnvtos (where, ...)
	if EnabAndBl () then
		local end_nil_count = arg["n"] - #arg
		if end_nil_count > 0 then
			p.s = p.s..where..arrow()
			for i = 1, arg["n"] do
				if math.mod(i,2) ~= 0 then
					p.s = p.s..arg[i]..': '
				else
					p.s = p.s..p.v(arg[i])
					if i < arg["n"] then
						p.s = p.s..vep
					end	
				end	
			end	
		else
			p.s = p.s..p.wnv (where, unpack(arg))
		end	
	end	
end --wnvtos

return p