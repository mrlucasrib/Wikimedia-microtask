local p = {}

local macron = mw.ustring.char(0x304)
local breve = mw.ustring.char(0x306)
local rough = mw.ustring.char(0x314)
local smooth = mw.ustring.char(0x313)
local diaeresis = mw.ustring.char(0x308)
local acute = mw.ustring.char(0x301)
local grave = mw.ustring.char(0x300)
local circumflex = mw.ustring.char(0x342)
local Latin_circumflex = mw.ustring.char(0x302)
local subscript = mw.ustring.char(0x345)
local macron_circumflex = macron .. diaeresis .. '?' .. Latin_circumflex

local is_velar = { ['κ'] = true, ['γ'] = true, ['χ'] = true, ['ξ'] = true, }

local UTF8_char = "[%z\1-\127\194-\244][\128-\191]*"
local basic_Greek = "[\206-\207][\128-\191]" -- excluding first line of Greek and Coptic block: ͰͱͲͳʹ͵Ͷͷͺͻͼͽ;Ϳ

local info = {}

-- The tables are shared among different characters so that they can be checked
-- for equality if needed, and to use less space.
local vowel = { vowel = true, diacritic_seat = true }
local iota = { vowel = true, diacritic_seat = true, offglide = true }
local upsilon = { vowel = true, diacritic_seat = true, offglide = true }
-- Technically rho is only a seat for rough or smooth breathing.
local rho = { consonant = true, diacritic_seat = true }
local consonant = { consonant = true }
local diacritic = { diacritic = true }
-- Needed for equality comparisons.
local breathing = { diacritic = true }

local function add_info(characters, t)
	if type(characters) == "string" then
		for character in string.gmatch(characters, UTF8_char) do
			info[character] = t
		end
	else
		for _, character in ipairs(characters) do
			info[character] = t
		end
	end
end

add_info({ macron, breve,
		diaeresis,
		acute, grave, circumflex,
		subscript,
	}, diacritic)

add_info({rough, smooth}, breathing)
add_info("ΑΕΗΟΩαεηοω", vowel)
add_info("Ιι", iota)
add_info("Υυ", upsilon)
add_info("ΒΓΔΖΘΚΛΜΝΞΠΡΣΤΦΧΨϜϘϺϷͶϠβγδζθκλμνξπρσςτφχψϝϙϻϸͷϡ", consonant)
add_info("Ρρ", rho)

local not_recognized = {}
setmetatable(info, { __index =
	function()
		return not_recognized
	end
})

local function quote(str)
	return "“" ..  str .. "”"
end

local correspondences = {
	-- Vowels
	["α"] = "a",
	["ε"] = "e",
	["η"] = "e" .. macron,
	["ι"] = "i",
	["ο"] = "o",
	["υ"] = "u",
	["ω"] = "o" .. macron,

	-- Consonants
	["β"] = "b",
	["γ"] = "g",
	["δ"] = "d",
	["ζ"] = "z",
	["θ"] = "th",
	["κ"] = "k",
	["λ"] = "l",
	["μ"] = "m",
	["ν"] = "n",
	["ξ"] = "x",
	["π"] = "p",
	["ρ"] = "r",
	["σ"] = "s",
	["ς"] = "s",
	["τ"] = "t",
	["φ"] = "ph",
	["ψ"] = "ps",
	
	-- Archaic letters
	["ϝ"] = "w",
	["ϻ"] = "ś",
	["ϙ"] = "q",
	["ϡ"] = "š",
	["ͷ"] = "v",
	
	-- Diacritics
	[smooth] = '',
	[rough] = '', -- h is added below in the `transliterate` function.
	[breve] = '',
}

local ALA_LC = {
	["χ"] = "ch",
	[acute] = '',
	[grave] = '',
	[circumflex] = '',
	[subscript] = '',
	[diaeresis] = '',
	[macron] = '',
}

local Wiktionary_transliteration = {
	["χ"] = "kh",
	[circumflex] = Latin_circumflex,
	[subscript] = 'i',
}

local function add_index_metamethod(t, index_metamethod)
	local mt = getmetatable(t)
	if not mt then
		mt = {}
		setmetatable(t, mt)
	end
	mt.__index = index_metamethod
end

--[=[
		This breaks a word into meaningful "tokens", which are
		individual letters or diphthongs with their diacritics.
		Used by [[Module:grc-accent]] and [[Module:grc-pronunciation]].
--]=]
local function tokenize(text)
	local tokens, vowel_info, prev_info = {}, {}, {}
	local token_i = 1
	local prev
	for character in string.gmatch(mw.ustring.toNFD(text), UTF8_char) do
		local curr_info = info[character]
		-- Split vowels between tokens if not a diphthong.
		if curr_info.vowel then
			if prev and (not (curr_info.offglide and prev_info.vowel)
					-- υυ → υ, υ
					-- ιυ → ι, υ
					or prev_info.offglide and curr_info == upsilon) then
				token_i = token_i + 1
			end
			tokens[token_i] = (tokens[token_i] or "") .. character
			table.insert(vowel_info, { index = token_i })
		elseif curr_info.diacritic then
			tokens[token_i] = (tokens[token_i] or "") .. character
			if prev_info.vowel or prev_info.diacritic then
				if character == diaeresis then
					-- Current token is vowel, vowel, possibly other diacritics,
					-- and a diaeresis.
					-- Split the current token into two:
					-- the first letter, then the second letter plus any diacritics.
					local previous_vowel, vowel_with_diaeresis = string.match(tokens[token_i], "^(" .. basic_Greek .. ")(" .. basic_Greek .. ".+)")
					if previous_vowel then
						tokens[token_i], tokens[token_i + 1] = previous_vowel, vowel_with_diaeresis
						token_i = token_i + 1
					end
				end
			elseif prev_info == rho then
				if curr_info ~= breathing then
					return string.format("The character %s cannot have the accent %s on it.", prev, "◌" .. character)
				end
			else
				error("The character " .. quote(prev) .. " cannot have a diacritic on it.")
			end
		elseif curr_info == rho then
			if prev and not (prev_info == breathing and info[string.match(tokens[token_i], "^" .. basic_Greek)] == rho) then
				token_i = token_i + 1
			end
			tokens[token_i] = (tokens[token_i] or "") .. character
		else
			if prev then
				token_i = token_i + 1
			end
			tokens[token_i] = (tokens[token_i] or "") .. character
		end
		prev = character
		prev_info = curr_info
	end
	return tokens
end

function p.transliterate(text, system)
	add_index_metamethod(correspondences, system == "ALA-LC" and ALA_LC or Wiktionary_transliteration)
	
	if text == '῾' then
		return 'h'
	end
	
	text = mw.ustring.toNFD(text)
	
	--[[
		Replace semicolon or Greek question mark with regular question mark,
		except after an ASCII alphanumeric character (to avoid converting
		semicolons in HTML entities).
	--]]
	text = mw.ustring.gsub(text, "([^A-Za-z0-9])[;" .. mw.ustring.char(0x37E) .. "]", "%1?")
	
	-- Handle the middle dot. It is equivalent to semicolon or colon, but semicolon is probably more common.
	text = text:gsub("·", ";")
	
	local tokens = tokenize(text)

	--now read the tokens
	local output = {}
	for i, token in pairs(tokens) do
		-- substitute each character in the token for its transliteration
		local translit = string.gsub(mw.ustring.lower(token), UTF8_char, correspondences)
		
		if token == 'γ' and is_velar[tokens[i + 1]] then
			-- γ before a velar should be <n>
			translit = 'n'
		elseif token == 'ρ' and tokens[i - 1] == 'ρ' then
			-- ρ after ρ should be <rh>
			translit = 'rh'
		elseif system == "Wiktionary" and mw.ustring.find(token, '^[αΑ].*' .. subscript .. '$') then
			-- add macron to ᾳ
			translit = mw.ustring.gsub(translit, '([aA])', '%1' .. macron)
		end
		
		if token:find(rough) then
			if mw.ustring.find(token, '[Ρρ]') then
				translit = translit .. 'h'
			else -- vowel
				translit = 'h' .. translit
			end
		end
		
		if system == "ALA-LC" and mw.ustring.find(token, '^[υΥ][^ιΙ]*$') then
			translit = translit:gsub('u', 'y'):gsub('U', 'Y')
		end
		
		-- Remove macron from a vowel that has a circumflex.
		if mw.ustring.find(translit, macron_circumflex) then
			translit = translit:gsub(macron, '')
		end
		
		-- Capitalize first character of transliteration.
		if token ~= mw.ustring.lower(token) then
			translit = mw.ustring.gsub(translit, "^.", mw.ustring.upper)
		end
		
		table.insert(output, translit)
	end
	
	return table.concat(output)
end

function p.translit(frame)
	local text = frame.args[1] or frame:getParent().args[1]
	
	local system = frame.args.system
	if system == nil or system == "" then
		system = "Wiktionary"
	elseif not (system == "ALA-LC" or system == "Wiktionary") then
		error('Transliteration system in |system= not recognized; choose between "ALA-LC" and "Wiktionary"')
	end
	
	local transliteration = p.transliterate(text, system)
	return '<span title="Ancient Greek transliteration" lang="grc-Latn"><i>' .. transliteration .. '</i></span>'
end

function p.bare_translit(frame)
	return p.transliterate(frame.args[1] or frame:getParent().args[1])
end

return p