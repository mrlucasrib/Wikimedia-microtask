-- This module implements {{search}}
local p = {}

local ll = ''

local function urlencode(text)
	-- Return equivalent of {{urlencode:text}}.
	local function byte(char)
		return string.format('%%%02X', string.byte(char))
	end
	return text:gsub('[^ %w%-._]', byte):gsub(' ', '+')
end

local function addlink(p, u, a, t, s)
	local item = ll:tag('li'):css('display', 'inline')
	item:wikitext(p .. '[' .. u .. ' ')
	item:tag('abbr')
		:attr('title', a)
		:css('border-bottom', 'none')
		:css('text-decoration', 'none')
		:css('cursor', 'inherit')
		:wikitext(t)
	item:wikitext(']' .. s)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Search'
	})
	local ss = args[1] or 'example phrase'
	local ssenc = urlencode(ss)
	local long = (args.long or '') ~= ''
	
	local ret = mw.html.create('div')
		:addClass('plainlist')
		:addClass('plainlinks')
		:css('display', 'inline')
	ll = ret:tag('ul'):css('display', 'inline')
	
	addlink('(', '//en.wikipedia.org/w/index.php?title=Special:Search&search=' .. ssenc, 'Wikipedia', 'wp', ' ')
	if long then
		addlink('', 'https://www.google.com/search?q=site%3Awikipedia.org+' .. ssenc, 'Wikipedia over Google', 'gwp', ' ')
	end
	addlink('', 'https://www.google.com/search?q=' .. ssenc, 'Google', 'g', ' ')
	if long then
		addlink('', 'https://www.bing.com/search?q=site%3Awikipedia.org+' .. ssenc, 'Wikipedia over Bing', 'bwp', ' ')
		addlink('', 'https://www.bing.com/search?q=' .. ssenc, 'Bing', 'b', ' | ')
		addlink('', 'https://www.britannica.com/search?nop&query=' .. ssenc, 'Encyclopaedia Britannica', 'eb', ' ')
		addlink('', 'http://www.bartleby.com/cgi-bin/texis/webinator/65search?query=' .. ssenc, 'Columbia Encyclopedia', 'co', ' ')
		addlink('', 'https://www.google.com/search?q=site%3Ahttp%3A%2F%2Fwww.pcmag.com%2Fencyclopedia_term%2F+' .. ssenc, 'PC Magazine Encyclopedia over Google', 'gct', ' ')
		addlink('', 'http://scienceworld.wolfram.com/search/index.cgi?as_q=' .. ssenc, 'World of Science', 'sw', ' ')
		addlink('', 'https://archive.org/search.php?query=' .. ssenc, 'Internet Archive', 'arc', ' ')
		addlink('', 'https://babel.hathitrust.org/cgi/ls?field1=ocr;q1=' .. ssenc .. ';a=srchls;lmt=ft', 'HathiTrust', 'ht', ')')
	else
		addlink('', 'https://www.bing.com/search?q=' .. ssenc, 'Bing', 'b', ')')
	end
	
	return ret
end

return p