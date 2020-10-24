-- This module implements [[Template:Tfd links]]
local p = {}

local function urlencode(text)
	-- Return equivalent of {{urlencode:text}}.
	local function byte(char)
		return string.format('%%%02X', string.byte(char))
	end
	return text:gsub('[^ %w%-._]', byte):gsub(' ', '+')
end

local function fullurllink(t, a, s)
	return '[//en.wikipedia.org/w/index.php?title=' .. urlencode(t) .. '&' .. a .. ' ' .. s .. ']'
end

function p.main(frame)
	local args = frame:getParent().args
	local ns = ((args['catfd'] and args['catfd'] ~= '') and 'Category')
		or ((args['module'] and args['module'] ~= '') and 'Module') 
		or  'Template'
	local tname = mw.getContentLanguage():ucfirst(args['1'] or 'Example')
	local fname = ns .. ':' .. tname
	local ymd = args['2'] or ''
	local fullpagename = (ymd ~= '')
		and	'WP:Templates for discussion/Log/' .. ymd
		or frame:preprocess('{{FULLPAGENAME}}')
	local sep = '&nbsp;<b>·</b> '
	
	local res = '<span id="' .. ns .. ':' .. tname 
		.. '" class="plainlinks nourlexpansion 1x">'
		.. '[[:' .. ns .. ':' .. tname .. ']]&nbsp;('
	
	if ymd ~= '' then
		local dmy = frame:expandTemplate{ title='date', args={ymd, 'dmy'} } 
		res = res .. '[[' .. fullpagename .. '#' .. fname 
			.. '|' .. dmy .. ']]) ('
	end
	res = res .. fullurllink(fname, 'action=edit', 'edit') .. sep
	res = res .. '[[' .. ns .. ' talk:' .. tname .. '|talk]]' .. sep
	res = res .. fullurllink(fname, 'action=history', 'history') .. sep
	if ns ~= 'Category' then
		res = res .. fullurllink('Special:Whatlinkshere/' 
			.. fname, 'limit=5000', 'links') .. sep
		res = res .. fullurllink('Special:Whatlinkshere/' 
			.. fname, 'limit=5000&hidelinks=1', 'transclusions') .. sep
	end
	res = res .. fullurllink('Special:Log', 'page=' 
		.. urlencode(fname), 'logs') .. sep
	res = res .. '[[Special:PrefixIndex/' .. fname .. '/|subpages]]'
	res = res .. '<span class="sysop-show">' .. sep .. fullurllink(fname, 'action=delete&wpReason=' 
		.. urlencode('[[' .. fullpagename .. '#' .. fname .. ']]'), 'delete') .. '</span>'
	res = res .. ')</span>'
	
	return res
end

return p