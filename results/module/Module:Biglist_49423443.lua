-- This module provides some functions to help avoid problems with templates
-- that might exceed expand size or time and which might put the page in
-- [[:Category:Pages where template include size is exceeded]] or
-- [[:Category:Pages with script errors]] (time exceeding 10 seconds).

local function collection()
	-- Return a table to hold items.
	return {
		n = 0,
		add = function (self, item)
			self.n = self.n + 1
			self[self.n] = item
		end,
		join = function (self, sep)
			return table.concat(self, sep)
		end,
	}
end

local function strip_to_nil(text)
	-- If text is a non-empty string, return its trimmed content,
	-- otherwise return nothing (empty string or not a string).
	if type(text) == 'string' then
		return text:match('(%S.-)%s*$')
	end
end

local function message(msg, nocat)
	-- Return formatted message text for an error.
	-- Can append "#FormattingError" to URL of a page with a problem to find it.
	-- This should not be called because there is no validity checking.
	local anchor = '<span id="FormattingError"></span>'
	local category = nocat and '' or '[[Category:Biglist errors]]'
	return anchor ..
		'<strong class="error">Error: ' ..
		msg ..
		'</strong>' ..
		category .. '\n'
end

local function urlencode(text)
	-- Return equivalent of {{urlencode:text}}.
	local function byte(char)
		return string.format('%%%02X', string.byte(char))
	end
	return text:gsub('[^ %w%-._]', byte):gsub(' ', '+')
end

local function replace2(text, template)
	-- Return template after substituting text and urlencoded text.
	local plain = text:gsub('%%', '%%%%')  -- for gsub, '%' has a special meaning in replacement
	local plainp = plain:gsub(' ', '+')    -- plain and space replaced with plus
	local encoded = urlencode(text):gsub('%%', '%%%%')
	return template:gsub('<TXT>', plain):gsub('<TXTP>', plainp):gsub('<UENC>', encoded)
end

local function clean(text, default)
	-- Return text, if not empty, after trimming leading/trailing whitespace.
	-- Otherwise return default which may be nil.
	if text then
		text = text:match("^%s*(.-)%s*$")
		if text ~= '' then
			return text
		end
	end
	return default
end

local function make_list(args, formatter, template)
	-- Return a list of formatted items.
	-- Input is a string of multiple lines, one item per line.
	local text = args.list or args[1] or ''
	local prefix = clean(args.prefix) or ''
	local comment = clean(args.comment)
	local results = collection()
	for line in string.gmatch(text .. '\n', '[\t ]*(.-)[\t\r ]*\n') do
		-- Skip line if empty or a comment.
		if line ~= '' then
			if not (comment and line:sub(1, #comment) == comment) then
				results:add(prefix .. formatter(line, template))
			end
		end
	end
	return results:join('\n')
end

local templates = {
	-- Equivalent of {{userlinks|text}}.
	userlinks = [=[
<span class="plainlinks userlinks">[[User:<TXT>|<TXT>]] <span class="plainlinks">([[User talk:<TXT>|talk]] '''·''' [[Special:Contributions/<TXT>|contribs]]<span class="sysop-show"> '''·''' [[Special:DeletedContributions/<TXT>|deleted contribs]]</span> '''·''' [//en.wikipedia.org/w/index.php?title=Special:Log&user=<UENC> logs] '''·''' [//en.wikipedia.org/w/index.php?title=Special:AbuseLog&wpSearchUser=<UENC> edit filter log]<span class="sysop-show"> '''·''' [[Special:Block/<TXT>|block user]]</span> '''·''' [//en.wikipedia.org/w/index.php?title=Special:Log&type=block&page=User:<UENC> block log])</span></span>]=],
	-- Equivalent of how {{search|topic}} is used.
	topicsearch = [=[
[[<TXT>]] – <span class="plainlinks">([//en.wikipedia.org/w/index.php?title=Special:Search&search=<UENC> wp] [https://www.google.com/search?q=site%3Awikipedia.org+<TXTP> gwp] [https://www.google.com/search?q=<TXTP> g] [https://www.bing.com/search?q=site%3Awikipedia.org+<TXTP> bwp] [https://www.bing.com/search?q=<TXTP> b] | [http://www.britannica.com/search?query=<TXTP> eb] [https://www.google.com/custom?sitesearch=1911encyclopedia.org&q=<TXTP> 1911] [http://www.bartleby.com/cgi-bin/texis/webinator/65search?query=<TXTP> co] [https://www.google.com/search?q=site%3Ahttp%3A%2F%2Fwww.pcmag.com%2Fencyclopedia_term%2F+<TXTP> gct] [http://scienceworld.wolfram.com/search/index.cgi?as_q=<TXTP> sw] [https://archive.org/search.php?query=<UENC> arc] [http://babel.hathitrust.org/cgi/ls?field1=ocr;q1=<UENC>;a=srchls;lmt=ft ht])</span>]=],
}

local function main(formatter, tname)
	local template = templates[tname]
	if template then
		return function (frame)
			local args = frame.args
			local success, result = pcall(make_list, args, formatter, template)
			if success then
				return result
			end
			return message(result, clean(args.nocat))
		end
	else
		return function (frame)
			local args = frame.args
			return message('Unknown template name "' .. tname .. '"', clean(args.nocat))
		end
	end
end

local function coltit(frame)
	-- [[List of RAL colors]] has "node-count limit exceeded" problem.
	-- Following are equivalent:
	--   {{coltit|xxx}}
	--   {{#invoke:biglist|coltit|xxx}}
	-- or
	--   {{coltit|rgb=xxx}}
	--   {{#invoke:biglist|coltit|rgb=xxx}}
	-- Output is an empty cell for a table; the cell has the given background color.
	-- This does not emulate other features of the template.
	local args = frame.args
	local hex = strip_to_nil(args[1])  -- should be hex color code such as 'AABBCC'
	if hex then
		return string.format('title="color %s" style="background:#%s;"| ', hex, hex)
	end
	local rgb = strip_to_nil(args.rgb)  -- should be decimal triple such as '123,123,123'
	if rgb then
		return string.format('title="color %s" style="background:rgb(%s);"| ', rgb, rgb)
	end
	error('biglist coltit: need parameter 1 or rgb', 0)
end

local function columnslist(frame)
	-- [[List of least concern fishes]] has problem exceeding template expansion size.
	-- Will possibly be other articles with similar problems.
	-- Following are equivalent:
	--   {{columns-list|colwidth=30em|xxx}}
	--   {{#invoke:biglist|columns-list|colwidth=30em|xxx}}
	-- Output is:
	--   <div ...>xxx</div>
	-- This assumes colwidth is wanted and does not emulate other features of the template.
	local args = frame.args
	local content = strip_to_nil(args[1]) or ''
	local colwidth = strip_to_nil(args.colwidth) or '30em'
	return
		'<div class="div-col columns column-width" ' ..
		'style="-moz-column-width: ' .. colwidth ..
		'; -webkit-column-width: ' .. colwidth ..
		'; column-width: ' .. colwidth .. ';">\n' ..
		content ..
		'</div>'
end

local function storm(frame)
	-- [[Wikipedia:What Wikipedia is not]] has an example at [[WP:CRYSTAL]]
	-- where the name of a "virtually certain" future storm is needed.
	-- This function returns the next such name (unlinked) depending on the current date.
	-- Usage:
	--   {{#invoke:biglist|storm}}
	-- Output example:
	--   Tropical Storm Alex (2022)
	local storms = {
		[2017] = 'Tropical Storm Alberto (2018)',
		[2018] = 'Tropical Storm Andrea (2019)',
		[2019] = 'Tropical Storm Arthur (2020)',
		[2020] = 'Tropical Storm Ana (2021)',
		[2021] = 'Tropical Storm Alex (2022)',
		default = 'Tropical Storm Alberto (2030)',
	}
	local date = os.date('!*t')  -- today's UTC date
	local y, m = date.year, date.month  -- full year, month (1-12)
	if m >= 11 then
		y = y + 1
	end
	return storms[y] or storms.default
end

local function weatherboxcols(frame)
	-- [[List of cities by sunshine duration]] has problem exceeding time available.
	-- Examples:
	--   {{#invoke:biglist|weatherboxcols|123.4}}         → style="background:#B9B94C; font-size:85%;"|123.4
	--   {{#invoke:biglist|weatherboxcols|123.4|1,823.0}} → style="background:#B9B94C; font-size:85%;"|1,823.0
	local args = frame.args
	local display = strip_to_nil(args[1]) or ''
	local value = tonumber((display:gsub(',', '')))
	local function show(bg, fg)
		local text = strip_to_nil(args[2]) or display
		if not fg and (value and value < 62) then
			fg = 'FFFFFF'
		end
		if fg then
			fg = 'color:#' .. fg .. ';'
		else
			fg = ''
		end
		return 'style="background:#' .. bg .. ';' .. fg .. ' font-size:85%;"' .. '|' .. text
	end
	if not value then
		return show('FFFFFF', '000000')
	end
	local redgreen, blue
	if value <= 0 then
		redgreen = 0
	elseif value <= 90 then
		redgreen = 1.889 * value
	elseif value <= 180 then
		redgreen = 0.472 * (270.169 + value)
	elseif value < 360 then
		redgreen = 0.236 * (720.424 + value)
	else
		redgreen = 255
	end
	if value <= 0 then
		blue = 0
	elseif value <= 90 then
		blue = 1.889 * value
	elseif value < 150 then
		blue = 2.883 * (150 - value)
	elseif value <= 270 then
		blue = 0
	elseif value < 719.735 then
		blue = 0.567 * (value - 270)
	else
		blue = 255
	end
	return show(string.format('%02X%02X%02X', redgreen, redgreen, blue))
end

return {
	coltit = coltit,
	['columns-list'] = columnslist,
	storm = storm,
	topicsearch = main(replace2, 'topicsearch'),
	userlinks = main(replace2, 'userlinks'),
	weatherboxcols = weatherboxcols,
}