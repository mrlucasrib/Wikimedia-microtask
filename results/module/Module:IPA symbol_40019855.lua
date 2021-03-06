local data = mw.loadData('Module:IPA symbol/data').data
local p = {}

local gsub = mw.ustring.gsub
local len = mw.ustring.len
local sub = mw.ustring.sub

local function reverseLook(t, s)
	local ret
	for i = 1, len(s) - 1 do
		-- Look for 2-char matches first
		ret = t[sub(s, i, i + 1)] or t[sub(s, i, i)]
		if ret then
			return ret
		end
	end
	ret = t[sub(s, -1)] -- Last character
	if ret then
		return ret
	end
end

local function returnData(s, dataType)
	for _, v in ipairs(data.univPatterns) do
		s = gsub(s, v.pat, v.rep)
	end
	local key = s
	for _, v in ipairs(data.keyPatterns) do
		key = gsub(key, v.pat, v.rep)
	end
	local ret = data.sounds[key] or data.diacritics[key]
		or reverseLook(data.diacritics, s)
	if ret and dataType then
		if ret[dataType] then
			ret = ret[dataType]
		else
			error(string.format('Invalid data type "%s"', dataType))
		end
	end
	return ret
end

local function returnErrorCat()
	return require('Module:Category handler').main{
		'[[Category:International Phonetic Alphabet pages needing attention]]',
		other = ''
	}
end

local function returnError(s)
	return string.format(
		'<span class="error">Error using {{[[Template:IPA symbol|IPA symbol]]}}: "%s" not found in list</span>%s',
		s, returnErrorCat())
end

function p._main(s, errorText, output)
	return returnData(s, output or 'article') or errorText or returnError(s)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame.args) do
		args[k] = v ~= '' and v
	end
	if not args.symbol then
		return '' -- Exit early
	end
	if args.errortext == 'blank' then
		args.errortext = ''
	end
	return p._main(args.symbol, args.errortext, args.output)
end

function p._link(s, displayText, prefix, suffix, audio, addSpan, errorText)
	local t = returnData(s)
	if t then
		s = string.format('%s[[:%s|%s]]%s',
			prefix or '', t.article, displayText or s, suffix or '')
		if addSpan ~= 'no' then
			local span = mw.html.create('span'):addClass('IPA')
			if prefix or suffix then
				span:addClass('nowrap'):attr('title',
					'Representation in the International Phonetic Alphabet (IPA)')
			end
			s = tostring(span:wikitext(s))
		end
		if audio then
			audio = require('Module:Yesno')(audio, audio)
			audio = audio == true and t.audio or audio
			if audio ~= '' then
				audio = mw.getCurrentFrame():expandTemplate{
					title = 'Template:Audio',
					args = { audio, 'listen', help = 'no' }
				}
				audio = ' <span class="nowrap" style="font-size:85%">(' .. audio
					.. ')</span>'
			end
		else
			audio = ''
		end
		return s .. audio
	 else
		return errorText or returnError(s)
	end
end

function p.link(frame)
	local args = {}
	for k, v in pairs(frame.args) do
		args[k] = v ~= '' and v
	end
	if not args.symbol then
		return '' -- Exit early
	end
	if args.errortext == 'blank' then
		args.errortext = ''
	end
	return p._link(args.symbol, args.text, args.prefix, args.suffix, args.audio,
		args.span, args.errortext)
end

return p