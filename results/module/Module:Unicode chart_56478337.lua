local mArguments = require('Module:Arguments')
local mTableTools = require('Module:TableTools')
local mUnicode = require('Module:Unicode data')
local mAge = require('Module:Unicode data/age')
local mAliases = require('Module:Unicode data/aliases')
local mBlocks = require('Module:Unicode data/blocks')
local mCategory = require('Module:Unicode data/category')
local mControl = require('Module:Unicode data/control')
local mScripts = require('Module:Unicode data/scripts')
local mVersion = require('Module:Unicode data/version')
local mEntities = require('Module:Unicode chart/entities')
local mDisplay = require('Module:Unicode chart/display')
local mSubsets = require('Module:Unicode chart/subsets')
local p = {} 
local args = {}
local config = {
	useFontCss = true,
	showRefs = true,
	infoMode = false,
	}

local refGrammar = {
	order = { "white", "combining", "control", "format", "reserved", "nonchar", "skip" },
	white = {
		format = 'White area%s within light green cell%s show%s %s of %sotherwise invisible [[whitespace character]]%s.',
		singular = {  '',  '', 's', 'the size', 'an ',  '' },
		plural   = { 's', 's',  '',    'sizes',    '', 's' },
		count = 0,
		},
	combining = {
		format = 'Yellow cell%s with [[dotted circle]]%s (◌) indicate%s %s[[combining character]]%s.',
		singular = {  '',  '', 's', 'a ', '' },
		plural   = { 's', 's',  '',   '','s' },
		count = 0,
		},
	control = {
		format = 'Light blue cell%s indicate%s %snon-printable [[control character]]%s.',
		singular = {  '', 's', 'a ',  '' },
		plural   = { 's',  '',   '', 's' },
		count = 0,
		},
	format = {
		format = 'Pink cell%s indicate%s %s[[format character]]%s.',
		singular = {  '', 's', 'a ',  '' },
		plural   = { 's',  '',   '', 's' },
		count = 0,
		},
	reserved = {
		format = 'Gray cell%s indicate%s %sunassigned (reserved) code point%s.',
		singular = { '', 's', 'an ', '' },
		plural   = { 's', '',     '', 's' },
		count = 0,
		},
	nonchar = {
		format = 'Black cell%s indicate%s %s[[noncharacter]]%s (code point%s that %s guaranteed never to be assigned as %sencoded character%s in the Unicode Standard).',
		singular = {  '','s','a ', '', '', 'is','an ', '' },
		plural   = { 's','',   '','s','s','are',   '','s' },
		count = 0,
		},
	skip = {
		format = 'Black horizontal line%s indicate%s non-consecutive rows.',
		singular = { '', 's' },
		plural   = { 's', '' },
		count = 0,
		},
	}

local infoTable = {}
local err = {
	format = function(...) return error(string.format(...), 0) end,
	blockName = 'Unrecognized block name "%s" does not match those defined in [[Module:Unicode data/blocks]]',
	refGarbage = 'Refs contain non-ref content: "%s"',
	badRange = 'Invalid range "%s" specified. Ranges must match [[regular expression]] <code>^[0-9A-F]+(?:[-–][0-9A-F]+)?$</code>',
	noRange = 'Please specify a valid block name, range of code points, or named subset',
	badSubset = 'Invalid subset "%s" specified',
	}

function debug(...)
	local a = {...}
	if type(a[1]) ~= "string" then mw.log(a[1]) return end
	local _,c = string.gsub(string.gsub(a[1], "%%%%", ""), "%%", "")
	for i = 1,math.max(#a, c+1) do 
		if (type(a[i]) == "nil" or type(a[i]) == "boolean") then a[i] = tostring(a[i]) end
	end
	return mw.log(string.format(unpack(a)))
end

table.concat2 = function(t1,t2) for i=1,#t2 do t1[#t1+1] = t2[i] end return t1 end
table.last = function(t) if t then return t[#t] else return nil end end


string.formatAll = function(fmt, t)
	for i=1,#t do t[i] = string.format(fmt, t[i]) end
	return t
end
function getUtf8(n)
	local t = {}
	for b in mw.ustring.char(n):gmatch('.') do table.insert(t, b:byte()) end
	return t
end
function getUtf16(n)
	if(n < 0 or n > 0x10FFFF) then return nil end
	if(n >= 0xD800 and n <= 0xDFFF) then return nil end
	if(n < 0x10000) then return { n } end
	local u = (n - 0x10000)
	local low = (u % 0x400)
	local high = (u - low) / 0x400
	return { 0xD800 + high, 0xDC00 + low }
end
function getUtf16toStr(n) 
	t = getUtf16(n)
	for i=1,#t do t[i] = string.format("0x%04X", t[i]) end
	return t
end
function getUtf8toStr(n)  return string.formatAll("0x%02X", getUtf8(n) ) end
function getUtf16toStr(n) return string.formatAll("0x%04X", getUtf16(n)) end

function makeRange(a,b)
	if(b) then return {first=math.min(a,b),last=math.max(a,b)} else return {first=a,last=a} end
end
function rangeContains(r, n) return (n >= r.first and n <= r.last) end
function rangeCombine(r1,r2) return {first=math.min(r1.first,r2.first), last=math.max(r1.last,r2.last)} end
function rangesMergeable(r1,r2)
	if not r1 or not r2 then return false end
	return rangeContains(r1, r2.first-1) or rangeContains(r1, r2.last+1) or
		rangeContains(r2, r1.first-1) or rangeContains(r2, r1.last+1)
end
function rangeSort(r1,r2)
	if r1 and not r2 then return true end
	if not r1 then return false end
	if r1.first == r2.first then return r1.last < r2.last end
	return r1.first < r2.first
end

function parseHex(s) if s then return tonumber(s,16) else return nil end end
function parseRanges(str)
	local r = {}
	str = str:upper():gsub("AND", ",") --avoid parsing A and D as single control chars in row U+000x, whoops
	for x in mw.ustring.gmatch(str, "[%dA-FUX%+%-]+") do
		local a,b = mw.ustring.match(x, "^[UX0%+%-]*([%dA-F]+)[-–][UX0%+%-]*([%dA-F]+)$")
		if(a and b) then
			table.insert(r, makeRange(parseHex(a),parseHex(b)))
		else
			local c = mw.ustring.match(x, "^[UX0%+%-]*([%dA-F]+)$")
			if c then
				table.insert(r, makeRange(parseHex(c)))
			else
				err.format(err.badRange, x)
			end
		end
	end
	for i = #r,2,-1 do for j = i-1,1,-1 do if rangesMergeable(r[i], r[j]) then
		r[j] = rangeCombine(r[i], r[j]) r[i] = nil
	end end end
	r2 = {}
	for k,v in pairs(r) do table.insert(r2,v) end
	table.sort(r2, rangeSort)
	return r2
end

-- Official way to match property values that are strings (including block names):
-- Ignore case, whitespace, underscore ('_'), hyphens, and any initial prefix string "is".
-- http://www.unicode.org/reports/tr44/#UAX44-LM3
local function propertyValueKey(val)
	return val:lower():gsub('^is', ''):gsub('[-_%s]+', '')
end

function getDefaultRange(blockName)
	if not blockName then return nil end 
	blockName = propertyValueKey(blockName)
	for i,b in ipairs(mBlocks) do
		if blockName == propertyValueKey(b[3]) then return makeRange(b[1],b[2]) end
	end
end

function getAge(n)
	local a = mAge.singles[n]
	if(a) then return a end
	for k,v in pairs(mAge.ranges) do
		if n >= v[1] and n <= v[2] then return v[3] end
	end
	return nil
end
function getCategory(n)
	local cc = mUnicode.lookup_category(n)
	local cat = mCategory.long_names[cc]
	if cat then return string.gsub(string.lower(cat), "_", " ") else return nil end
end

function getControlAbbrs(n) return getAliasValues(n, "abbreviation") end
function getControlAliases(n) return table.concat2(getAliasValues(n, "control"), getAliasValues(n, "figment")) end

function getAliasValues(n, key)
	local b,r = mAliases[n], {}
	if b then for i,t in ipairs(b) do
		if(not key or t[1] == key) then table.insert(r, t[2]) end 
	end end
	return r
end

function getAnchorId(n) return string.format("info-%04X", n) end
function getTarget(n)
	if(config.infoMode) then return "#"..getAnchorId(n) end
	local t = getParamNx("link", n, true) 
	if(t=="yes") then t = char end
--"ifexist" is a deleted feature, now recognized equal to "no" to avoid linking to the article [[Ifexist]], which incidentally doesn't exist.
	if(t=="no" or t=="ifexist") then t = nil end 
	if(t=="wikt") then t = ":wikt:"..mw.ustring.char(n) end
	return t
end

function getNamedEntity(n)
	local e = mEntities[n]
	if e then return string.gsub(e, "&", "&amp;") else return nil end
end

function getEntities(n)
	local entH = getNamedEntity(n)
	local entN = string.format('&amp;#%d;', n)
	local entXN = string.format('&amp;#x%X;', n)
	local t = {}
	if(entH) then table.insert(t, entH) end
	table.insert(t, entN)
	table.insert(t, entXN)
	return t
end

function isControl(n) return mUnicode.lookup_control(n) == "control" end
function isFormat(n) return mUnicode.lookup_control(n) == "format" end

function isBadTitle(str)
	if str == nil then return true end
	if type(str) == "number" then str = mw.ustring.char(str) end
	if not mUnicode.is_valid_pagename(str) then return true end
	if mw.ustring.match(str, "[\<\>]") then return true end
	if #str == 1 and mw.ustring.match(str, "[\/\.\:\_̸]") then return true end
	return false
end

function makeVersionRef()
	if(not config.showRefs or mVersion == nil or mVersion == '') then return ''
	else return string.format('<ref name="version">As of [[Unicode#Versions|Unicode version]] %s.</ref>', mw.text.nowiki(mVersion)) end
end


function makeAutoRefs()
	if not config.showRefs then return '' end
	local refs = {}
	for i,refType in ipairs(refGrammar.order) do
		local g = refGrammar[refType]
		local refText = nil
		if(g.count == 1) then refText = string.format(g.format, unpack(g.singular)) end
		if(g.count >= 2) then refText = string.format(g.format,   unpack(g.plural)) end
		if(refText) then
			table.insert(refs, string.format('<ref name="%s">%s</ref>', refType, refText))
		end
	end
	return table.concat(refs)
end

--TODO: remove any garbage around/between refs and downgrade this to a warning
function sanitizeUserRefs(refTxt)
	if not config.showRefs then return '' end 
	local trim1 = mw.text.killMarkers(refTxt)
	local trim2 = mw.ustring.gsub(trim1, '%s', '')
	if string.len(trim2) > 0 then err.format(err.refGarbage, mw.text.nowiki(trim1))
	else return refTxt end
end
function makeSpan(str, title, repl)
	local c,t = '',''
	if title then t = string.format(' title="%s"', title) end
	if repl then
		local s,x = mw.ustring.gsub(str, '%s+', '\n')
		if x > 0 then c = string.format(' class="small-%s"', x) str = s end
	end
	return string.format('<span %s%s>%s</span>', c, t, str)
end
function makeLink(a, b)
	if not a or (isBadTitle(a) and not config.infoMode) then return (b or '') end
	if not b then b = a end
	return string.format("[[%s|%s]]",a,b)
end

function makeAliasList(n)
	if not mAliases[n] then return '' end
	local t = {}
	table.insert(t, '<div class="alias"><ul>')
	for k,v in ipairs(mAliases[n]) do
		local tr = string.format('<li class="%s">%s</li>', v[1], v[2])
		table.insert(t, tr)
	end
	table.insert(t, '</ul></div>')
	return table.concat(t)
end
function makeDivUl(t, class) return makeDiv(makeUl(t), class) end
function makeUl(t, class)
	if not t then return '' end
	if class then class = string.format(' class="%s"', class) else class = '' end
	return string.format('<ul%s><li>%s</li></ul>', class, table.concat(t, '</li><li>'))
end
function makeDiv(s, class)
	if not s or string.len(s) == 0 then return '' end
	if class then class = string.format(' class="%s"', class) else class = '' end
	return string.format('<div%s>%s</div>', class, s)
end	
function makeInfoRow(info)						
	local alii = makeAliasList(info.n)
	local html = makeDivUl(getEntities(info.n), 'html')
	local utf8 = makeDivUl(getUtf8toStr(info.n), 'utf8')
	local utf16 = makeDivUl(getUtf16toStr(info.n), 'utf16')
	local age = getAge(info.n)
	if(age) then age = string.format('<div class="age">Introduced in Unicode version %s.</div>', age) else age = '' end
	if(info.category == 'control') then info.name = mw.text.nowiki('<control>') end
	if(info.category == 'space separator') then info.cBox = ' box' end
	local class = ''
	if config.useFontCss then class = class..'script-'..info.sCode end
	local charInfo = '<div class="char">'..table.concat({utf8, utf16, html, age})..'</div>'
	local titleBarFmt = '<div><div class="title">%s %s</div><div class="category">%s</div></div>'
	local titleBar = string.format(titleBarFmt, info.uPlus, info.name, info.category)
	local fmt = '<tr class="info-row" id="%s"><th class="thumb %s%s">%s</th><td colspan="16" class="info">%s%s%s</td></tr>'
	return string.format(fmt, getAnchorId(info.n), class, info.cBox, info.display, titleBar, alii, charInfo)
end

function getParamNx(key, n, c)
	local key4 = string.format("%s_%04X", key, n)
	if args[key4] then return args[key4] end
	if c then
		local key3 = string.format("%s_%03Xx", key, math.floor(n/16))
		return args[key3] or args[key]
	end
	return nil
end

function makeGridCell(n, charMask)
	local uPlus =  string.format("U+%04X", n)
	local char = mw.ustring.char(n)
	local cfFmt = '<td title="%s" class="char%s"><div>\n%s\n</div></td>'
	local isControlN, isFormatN = isControl(n), isFormat(n)
	local charName = table.last(getControlAliases(n)) or mUnicode.lookup_name(n)
	if isControlN then charName = charName or "&lt;control&gt;" end
	local cBox = ''
	local masterListDisplay = mDisplay[n]
	if masterListDisplay then cBox = ' box' end
	local display = masterListDisplay or char
	local title = uPlus..' '..charName
	if isControlN or isFormatN then display = makeSpan(display, title, true) end
	local sCode = nil
	if config.useFontCss then sCode = mUnicode.lookup_script(n) end
	--default dir="ltr" need not be specified
	local sDir = ''
	if mUnicode.is_rtl(char) then sDir = ' dir="rtl"' end
	local sClass = ""
	local linkThis = getTarget(n)
	local cell = ''
	local generateInfoPanel = true
--3 types of empty cells	
	if(not charMask[n]) then 
		--fill extra spaces surrounding an irregular (non-multiple of 16) range of displayed chars  
		cell = '<td class="excluded"></td>'
		generateInfoPanel = false					
	elseif string.match(charName, '<reserved') then
		refGrammar.reserved.count = refGrammar.reserved.count + 1
		cell = string.format('<td title="%s RESERVED" class="reserved"></td>', uPlus)
		generateInfoPanel = false					
	elseif string.match(charName, '<noncharacter') then
		refGrammar.nonchar.count = refGrammar.nonchar.count + 1
		cell = string.format('<td title="%s NONCHARACTER" class="nonchar"></td>', uPlus)
		generateInfoPanel = false					
--actual chars
	elseif mUnicode.is_whitespace(n) then
		refGrammar.white.count = refGrammar.white.count + 1
		local cellFmt = '<td title="%s" class="char whitespace"%s><div>\n%s\n</div></td>'
		display = makeSpan(display, title, false)
		cell = string.format(cellFmt, title, sDir, makeLink(linkThis, makeSpan(char, title, false)))
	elseif isControlN then
		refGrammar.control.count = refGrammar.control.count + 1
		cell = string.format(cfFmt, title, " control box", makeLink(linkThis, display))
	elseif isFormatN then
		refGrammar.format.count = refGrammar.format.count + 1
		cell = string.format(cfFmt, title, " format box", makeLink(linkThis, display))
	else
		if sCode then sClass = sClass..string.format(' script-%s', sCode) end
		sClass = sClass..cBox
		isCombining = mUnicode.is_combining(n)
		if isCombining then
			refGrammar.combining.count = refGrammar.combining.count + 1
			sClass = sClass.." combining"
			display = "◌"..char
		end
		display = makeSpan(display, title, true)
		local cellFmt = '<td title="%s" class="char%s"%s><div>\n%s\n</div></td>'
		cell = string.format(cellFmt, title, sClass, sDir, makeLink(linkThis,display))
	end
	if(config.infoMode and generateInfoPanel) then
		local printable = mUnicode.is_printable(n)
		local category = getCategory(n)
		local info = {
			n = n,
			char = char,
			name = charName,
			sCode = sCode,
			display = display,
			uPlus = uPlus, 
			printable = printable,
			category = category,
			cBox = cBox,
			}
		table.insert(infoTable, makeInfoRow(info))
	end
	return cell
end	
function getMask(ranges)
	local ch,r = {},{}
	for i,range in ipairs(ranges) do
		for n=range.first,range.last do
			ch[n] = true
			r[n-n%16] = true
		end
	end
	local row = {}
	for i,x in pairs(r) do table.insert(row, i) end
	table.sort(row)
	return ch,row
end

function p.main( frame )
	for k, v in pairs(mArguments.getArgs(frame)) do args[k] = v end
	config.infoMode = (args["info"] or 'no'):lower() ~= "no"
	config.useFontCss = (args["fonts"] or args["font"] or 'yes'):lower() ~= "no"
	local userRefs = args["refs"] or args["notes"] or args["ref"] or args["note"] or "" 
	config.showRefs = not(userRefs=='off' or userRefs=='no')
	local state = args["state"] or "expanded"

	local subset = args["subset"]
	local subsetRangeTxt = ''
	if subset then
		subsetRangeTxt = mSubsets[subset:lower():gsub('%s+', '_')]
		if(not subsetRangeTxt) then err.format(err.badSubset, subset) end
	end

	local blockName = args["block_name"] or args["block"] or args["name"] or args[1]
	local blockNameLink = args["link_block"] or args["link_name"]
	local blockNameDisplay = args["display_block"] or args["display_name"] or subset or blockName

	local defaultRange = getDefaultRange(blockName)
	local actualBlock = (defaultRange ~= nil)

	local ranges = parseRanges(subsetRangeTxt..','..(args["ranges"] or args["range"] or ''))

	if actualBlock then
		config.pdf = string.format('https://www.unicode.org/charts/PDF/U%04X.pdf', defaultRange.first)
		if #ranges == 0 then ranges = { defaultRange } end
		blockNameLink = blockNameLink or blockName.." (Unicode block)"
	else
		if #ranges == 0 then err.format(err.noRange, {}) end
	end

	local charMask,rowMask = getMask(ranges)
	local tableBody = {}
	for i=1,#rowMask do
		local rowStart = rowMask[i]
		local trClass=''
		if(i > 1 and rowStart ~= (rowMask[i-1]+16)) then
			trClass = ' class="skip"'
			refGrammar.skip.count = refGrammar.skip.count + 1
		end
		local dataRow = {}
		local rowOpen, rowClose = string.format('<tr%s>', trClass), '</tr>'
		local rowHeader = string.format('<th class="row">U+%03Xx</th>', rowStart/16)
		for c = 0,15 do
			table.insert(dataRow, makeGridCell(rowStart+c, charMask))
		end
		local rowHtml = {rowOpen, rowHeader, table.concat(dataRow), rowClose}
		table.insert(tableBody, table.concat(rowHtml))
	end
	local tableOpenFmt = '<table class="wikitable nounderlines unicode-chart collapsible %s">'
	local tableOpen, tableClose = string.format(tableOpenFmt, state), '</table>'

	local allRefs = table.concat({ makeVersionRef(), makeAutoRefs(), sanitizeUserRefs(userRefs) }) 
	if blockNameLink then
		blockNameLink = string.format("[[%s|%s]]", blockNameLink, blockNameDisplay)
	else
		blockNameLink = blockNameDisplay
	end
	local titleBar = string.format('<div class="title">%s%s</div>', blockNameLink, allRefs)
	local fmtpdf = '<div class="pdf-link">[%s Official Unicode Consortium code chart] (PDF)</div>'
	if config.pdf then
		titleBar = titleBar..string.format(fmtpdf, config.pdf)
	end
	local titleBarRow = '<tr><th class="title-bar" colspan="17">'..titleBar..'</th></tr>'

	local columnHeaders = { '<tr>', '<th class="empty"></th>' }
	for c = 0,15,1 do table.insert(columnHeaders, string.format('<th class="column">%X</th>', c)) end
	table.insert(columnHeaders, '</tr>')

	local infoFooter = ''
	if(config.infoMode) then infoFooter = table.concat(infoTable) end

	local notesFooter = ''
	if config.showRefs and string.len(allRefs) > 0 then
		notesFooter = '<tr><td class="notes" colspan="17">'.."'''Notes:'''{{reflist}}"..'</td></tr>'
	end

	local tStyles = frame:extensionTag{ name = 'templatestyles', args = { src = 'Unicode chart/styles.css'} }
	local cStyles = ''
	if config.useFontCss then
		cStyles = frame:extensionTag{ name = 'templatestyles', args = { src = 'Unicode chart/script styles.css'} }
	end
	local html = table.concat({
		tStyles, cStyles, tableOpen, titleBarRow,
		table.concat(columnHeaders), table.concat(tableBody),
		infoFooter, notesFooter, tableClose
		})
	return frame:preprocess(html)
end
		
return p