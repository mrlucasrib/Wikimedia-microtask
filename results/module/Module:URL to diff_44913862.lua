-- This module converts Wikipedia diff URLs to the {{diff}} template format.

local newBuffer = require('Module:OutputBuffer')

local p = {}

local function decodeUrl(url)
	if type(url) ~= 'string' then
		return nil
	end
	url = mw.uri.new(url)
	if not url or url.host ~= 'en.wikipedia.org' then
		return nil
	end
	local data = {}
	data.title = url.query.title and mw.uri.decode(url.query.title, 'WIKI')
	data.diff = url.query.diff
	data.oldid = url.query.oldid
	data.diffonly = url.query.diffonly
	return data
end

local function encodeDiffTemplate(data)
	if not data.title and not data.diff and not data.oldid then
		return nil
	end
	local isNamed = false -- Track whether we need to use named parameters
	for k, v in pairs(data) do
		if string.find(v, '=') then
			isNamed = true
			break
		end
	end
	local getBuffer, print, printf = newBuffer()
	print('diff')
	printf('%s%s', isNamed and 'page=' or '', data.title or '')
	printf('%s%s', isNamed and 'diff=' or '', data.diff or '')
	printf('%s%s', isNamed and 'oldid=' or '', data.oldid or '')
	if data.label then
		printf('%s%s', isNamed and 'label=' or '', data.label)
	end
	if data.diffonly then
		printf('diffonly=%s', data.diffonly)
	end
	local ret = getBuffer('|')
	ret = '{{' .. ret .. '}}'
	return ret
end

function p._url(args)
	local data = decodeUrl(args.url)
	if data then
		data.label = args.label
		return encodeDiffTemplate(data)
	else
		return nil
	end
end

function p.url(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:URL to diff',
	})
	return p._url(args)
end

return p