local p = {}

local data = mw.loadData 'Module:Hangul/data'

---- From [[wikt:Module:ko-hangul]
 
-- Given the "syllable index" of a precomposed Hangul syllable (see
-- above), returns "indices" representing the three constituent jamo
-- ("lead", i.e. initial consonant; "vowel"; and "tail", i.e. final
-- consonant, except that zero denotes the absence of a final consonant).
local function syllableIndex2JamoIndices(syllableIndex)
    local lIndex = math.floor(syllableIndex / 588)
    local vIndex = math.floor((syllableIndex % 588) / 28)
    local tIndex = syllableIndex % 28
 
    return lIndex, vIndex, tIndex
end

----

local tocodepoint = mw.ustring.codepoint

local function indexof(arr, val)
	for i, v in ipairs(arr) do
		if v == val then
			return i
		end
	end
	return -1
end

local function get_name(char)
	local codepoint = tocodepoint(char)
	
	-- Hangul Compatibility Jamo block
	if 0x3130 <= codepoint and codepoint <= 0x318F then
		return ('U+%X: HANGUL LETTER %s'):format(codepoint, data.names[codepoint - 0x3130])
	
	-- Hangul Syllables block
	-- From [[wikt:Module:Unicode data]].
	-- Cheaper to derive names from decomposed form of syllable?
	elseif 0xAC00 <= codepoint and codepoint <= 0xD7A3 then
		local li, vi, ti = syllableIndex2JamoIndices(codepoint - 0xAC00)
		return ("U+%X: HANGUL SYLLABLE %s%s%s"):format(
			codepoint, data.leads[li], data.vowels[vi], data.trails[ti])
	
	else
		error(('No name for U+%X found.'):format(codepoint))
	end
end

local function get_anchor(index)
	return string.char(('a'):byte() + index - 1):rep(2)
end

local function diag_split_header(column_text, row_text)
	return mw.getCurrentFrame():expandTemplate{
		title = 'diagonal_split_header',
		args = { column_text, row_text },
	}
end

local function syllables_by_initial(initial)
	local codepoint = mw.ustring.codepoint(initial)
	if not (0x1100 <= codepoint and codepoint <= 0x1112) then
		error('Incorrect initial ' .. initial .. '. Should be between U+1100 and U+1112.')
	end
	local initial_index = indexof(data.initials, initial)
	
	local output = {}
	local i = 0
	local function push(text)
		i = i + 1
		output[i] = text
	end
	
	push(
([[
{| class="wikitable collapsible collapsed nowrap" style="width: 96px; height: 96px;"
|+ id="%s" | Initial&nbsp;<span lang="ko">%s</span>
|-
! %s]]):format(
	get_anchor(initial_index),
	data.independent_initials[initial_index],
	diag_split_header('Medial', 'Final'))) -- initial jamo

	for _, final in ipairs(data.independent_finals) do
		push(('! title="%s" | <span lang="ko">%s</span>')
			:format(final ~= '' and get_name(final) or '', final))
	end
	
	for i, medial in ipairs(data.medials) do
		push('|- lang="ko"')
		local independent_medial = data.independent_medials[i]
		push(('! scope="row" title="%s" | %s')
			:format(get_name(independent_medial), independent_medial))
		for _, final in ipairs(data.finals) do
			push(('| %s%s%s'):format(initial, medial, final))
		end
	end
	
	push('|}')
	
	output = table.concat(output, '\n')
	output = mw.ustring.toNFC(output)
	output = mw.ustring.gsub( -- Add names of syllable codepoints.
		output,
		'[가-힣]', -- [[Hangul Syllables]] block (U+AC00-D7AF)
		function (syllable)
			return ('title="%s" | %s'):format(get_name(syllable), syllable)
		end)
	
	-- Check for consecutive span tags.
	-- output:gsub('<span[^>]+>[^<]*</span><span[^>]+>[^<]*</span>', mw.log)
	
	return output
end

function p.syllables_by_initial(frame)
	local initial = frame.args[1] or 'ᄀ'
	return syllables_by_initial(initial)
end

function p.all_syllables(frame)
	local tables = {}
	for i, initial in ipairs(data.initials) do
		tables[i] = syllables_by_initial(initial)
	end
	return table.concat(tables, '\n')
end

function p.TOC(frame)
	local output = {}
	for i, initial in ipairs(data.independent_initials) do
		table.insert(output, ('| [[#%s|%s]]'):format(get_anchor(i), initial))
	end
	table.insert(output, 1, '{| class="wikitable" lang="ko" style="width: 96px; height: 10px;"')
	table.insert(output, '|}')
	return table.concat(output, '\n')
end

return p