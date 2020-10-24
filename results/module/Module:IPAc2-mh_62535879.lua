-- This module is primarily maintained at:
-- https://en.wiktionary.org/wiki/Module:mh-pronunc
-- Please direct all technical queries and contributions there.
-- The version of this script on Wikipedia is only a mirror.

local export = {}

local MERGED_VOWELS = false
local PARENTHETICAL_EPENTHESIS = true
local PHONETIC_DETAILS = false
local W_OFF_GLIDES = true

local ASYLL = "̯"
local BREVE = "̆"
local CEDILLA = "̧"
local MACRON = "̄"
local TIE = "͡"
local TIE2 = "͜"

local C1_ = "pbtdSZszkgmnNrlyYhH_"
local C1 = "["..C1_.."]"
local C2_ = "jGw"
local C = ".["..C2_.."]"
local V_ = "aEeiAV7MQOou"
local V = "["..V_.."]"
local VI_ = V_.."I"
local VI = "["..VI_.."]"
local S = "[%s%-]+"

local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

local EMPTY = {}

-- Adds elements to a sequence as if it's a set (retains unique elements only).
local function addUnique(seq, value)
	for _, value2 in pairs(seq) do
		if value == value2 then
			return
		end
	end
	seq[#seq + 1] = value
end

-- Intended to work the same as JavaScript's Object.assign() function.
local function assign(target, ...)
	local args = { ... }
	for _, source in pairs(args) do
		if type(source) == "table" then
			for key, value in pairs(source) do
				target[key] = value
			end
		end
	end
	return target
end

local function fastTrim(text)
	return string.match(text, "^%s*(.-)%s*$")
end

local function parseBoolean(text)
	if type(text) == "string" then
		text = string.gsub(text, "[^0-9A-Za-z]", "")
		if text ~= "" and text ~= "0" and string.lower(text) ~= "false" then
			return true
		end
	end
	return false
end

local function splitChars(text, pattern, chars, shorten)
	chars = chars or {}
	local index = 1
	for ch in string.gmatch(text, pattern or UTF8_CHAR) do
		chars[index] = ch
		index = index + 1
	end
	if index <= #chars then
		if shorten then
			table.remove(chars, index)
		else
			repeat
				chars[index] = nil
				index = index + 1
			until index > #chars
		end
	end
	return chars
end

local function string_gsub2(text, pattern, subst)
	return string.gsub(string.gsub(text, pattern, subst), pattern, subst)
end

local function tableGet(value, key1, key2, key3)
	if type(value) ~= "table" or key1 == nil then
		return value
	end
	value = value[key1]
	if key2 == nil then
		return value
	end
	if type(value) ~= "table" then
		return nil
	end
	value = value[key2]
	if key3 == nil then
		return value
	end
	if type(value) ~= "table" then
		return nil
	end
	return value[key3]
end

local function ZTBL(text, sep)
	local tbl = {}
	for key in mw.text.gsplit(text, sep or " ") do
		tbl[key] = true
	end
	return tbl
end



local PARSE_PSEUDO_GLIDE = {
	["y"] = "0",
	["h"] = "0h",
	["w"] = "0w"
}

local PARSE_C_CH_CW = {
	["k"]   = "kG",
	["kh"]  = "kGh", -- N\A
	["kw"]  = "kW",
	["l"]   = "lJ",
	["lh"]  = "lG",
	["lw"]  = "lW",
	["m"]   = "mJ",
	["mh"]  = "mG",
	["mw"]  = "mJw", -- N\A
	["n"]   = "nJ",
	["nh"]  = "nG",
	["nw"]  = "nW",
	["ng"]  = "NG",
	["ngh"] = "NGh", -- N\A
	["ngw"] = "NW",
	["r"]   = "rG",
	["rh"]  = "rGh", -- N\A
	["rw"]  = "rW",
	["0"]   = "_J",
	["0h"]  = "_G",
	["0w"]  = "_W"
}

local PARSE_REMAINING = {
	["b"] = "pG",
	["d"] = "rj",
	["e"] = "E",
	["&"] = "e",
	["h"] = "hG",
	["j"] = "tj",
	["J"] = "j",
	["p"] = "pj",
	["t"] = "tG",
	["w"] = "hw",
	["W"] = "w",
	["y"] = "hj",
	["z"] = "yj",
	["Z"] = "Yj",
	["'"] = ""
}

local function parse(code)
	
	local outSeq = {}
	code = mw.ustring.gsub(code, "%s+", " ")
	code = string.lower(code)
	for text in mw.text.gsplit(code, " *,[ ,]*") do
		
		text = fastTrim(text)
		if text ~= "" then
			
			local temp = string.gsub(text, "[abdeghijklmnprtwy_&'%- ]", "")
			if temp ~= "" then
				error("'"..code.."' contains unsupported characters: "..temp)
			end
			
			-- Recognize "y_", "h_", "w_", "_y", "_h", "_w" as pseudo-glides.
			text = string.gsub(text, "_*([hwy])_+", PARSE_PSEUDO_GLIDE)
			text = string.gsub(text, "_+([hwy])", PARSE_PSEUDO_GLIDE)
			if string.find(text, "_") then
				error("contains misplaced underscores: "..code)
			end
			
			-- a plain {i} protected from dialect-specific reflexes
			text = string.gsub(text, "'i", "I")
			
			-- "yi'y" and "'yiy" sequences
			text = string.gsub(text, "('?)yi('*)y", function(aposA, aposB)
				if aposA ~= "" then
					-- "dwelling upon" i
					return "Z"
				elseif aposB ~= "" then
					-- "passing over lightly" i
					return "z"
				end
			end)
			
			-- Convert multigraphs to pseudo-X-SAMPA format.
			text = string.gsub(text, "[klmnr0]g?[hw]?", PARSE_C_CH_CW)
			if string.find(text, "g") then
				error("contains g that is not part of ng: "..code)
			end
			
			-- Convert remaining sequences to pseudo-X-SAMPA format.
			text = string.gsub(text, ".", PARSE_REMAINING)
			
			-- Enforce CVC, CVCVC, CVCCVC, etc. phonotactics,
			-- but allow VC, CV at affix boundaries
			-- where a vowel may link to another morpheme's consonant.
			temp = string.gsub(text, "[%s%-]+", "")
			if	string.find(temp, "_..[jGw]") or
				string.find(temp, ".[jGw]_.")
			then
				error("pseudo-glides may not neighbor a consonant")
			end
			if string.find(temp, VI.."_."..VI) then
				error("pseudo-glides may only be at the beginning or end"..code)
			end
			if string.find(temp, VI..VI) then
				error("vowels must be separated by a consonant: "..code)
			end
			if string.find(temp, ".[jGw].[jGw].[jGw]") then
				error("each consonant cluster is limited to two: "..code)
			end
			if string.find(temp, ".[jGw].[jGw]$") then
				error("may not end with a consonant cluster: "..code)
			end
			string.gsub(temp, "^(.[jGw])(.[jGw])", function(consonX, consonY)
				if consonX ~= consonY then
					error("may only begin with single or geminated consonant: "
						..code)
				end
			end)
			
			if text ~= "" then
				addUnique(outSeq, text)
			end
			
		end
		
	end
	
	return outSeq
	
end



local BENDER_1968 = {
	["pj"] = "p", ["pG"] = "b",
	["tj"] = "j", ["tG"] = "t",
	              ["kG"] = "k", ["kw"] = "q",
	["mj"] = "m", ["mG"] = "ṁ",
	["nj"] = "n", ["nG"] = "ṅ", ["nw"] = "n̈",
	              ["NG"] = "g", ["Nw"] = "g̈",
	["rj"] = "d", ["rG"] = "r", ["rw"] = "r̈",
	["lj"] = "l", ["lG"] = "ł", ["lw"] = "l̈",
	["yj"] = "yi'y",
	["Yj"] = "'yiy",
	["hj"] = "y", ["hG"] = "h", ["hw"] = "w",
	["_j"] = "",  ["_G"] = "",  ["_w"] = "",
	["a"]  = "a",
	["E"]  = "e",
	["e"]  = "&",
	["i"]  = "i",
	["I"]  = "i"
}
local BENDER_MED = assign({}, BENDER_1968, {
	["mG"] = "m̧",
	["nG"] = "ņ",
	["nw"] = "ņ°",
	["Nw"] = "g°",
	["rw"] = "r°",
	["lG"] = "ļ",
	["lw"] = "ļ°",
	["e"]  = "ȩ"
})
local BENDER_MOD = assign({}, BENDER_MED, {
	["kw"] = "kʷ",
	["mG"] = "ṃ",
	["nG"] = "ṇ",
	["nw"] = "ṇʷ",
	["Nw"] = "gʷ",
	["rw"] = "rʷ",
	["lG"] = "ḷ",
	["lw"] = "ḷʷ",
	["e"]  = "ẹ"
})
local BENDER_DEFAULT = assign({}, BENDER_MOD, {
	["mG"] = "m̧",
	["nG"] = "ņ",
	["nw"] = "ņʷ",
	["lG"] = "ļ",
	["lw"] = "ļʷ",
	["e"]  = "ȩ"
})
local BENDER_MAPS = {
	["1968"] = BENDER_1968,
	["med"]  = BENDER_MED,
	["mod"]  = BENDER_MOD
}

local function toBender(inSeq, args)
	-- "1968" is from "Marshallese Phonology" (1968 by Byron W. Bender).
	-- "med" is from the Marshallese-English Dictionary (1976).
	-- "mod" is from the Marshallese-English Online Dictionary.
	-- "default" is the same as "mod" but with cedillas.
	local version = args and args.version
	local map = BENDER_MAPS[
		type(version) == "string" and string.lower(version) or ""
	] or BENDER_DEFAULT
	local outSeq = {}
	for _, text in pairs(inSeq) do
		text = string.gsub(text, ".[jGw]?", map)
		addUnique(outSeq, text)
	end
	return outSeq
end



local TO_MOD = {
	["Ȩ"] = "Ẹ", ["ȩ"] = "ẹ",
	["Ļ"] = "Ḷ", ["ļ"] = "ḷ",
	["M̧"] = "Ṃ", ["m̧"] = "ṃ",
	["Ņ"] = "Ṇ", ["ņ"] = "ṇ",
	["N̄"] = "Ñ", ["n̄"] = "ñ",
	["O̧"] = "Ọ", ["o̧"] = "ọ"
}

local function toMOD(text)
	text = mw.ustring.gsub(text, ".["..CEDILLA..MACRON.."]?", TO_MOD)
	return text
end



local PHONEMIC_MAP = {
	["pj"] = "pʲ", ["pG"] = "pˠ",
	["tj"] = "tʲ", ["tG"] = "tˠ",
	               ["kG"] = "k",  ["kw"] = "kʷ",
	["mj"] = "mʲ", ["mG"] = "mˠ",
	["nj"] = "nʲ", ["nG"] = "nˠ", ["nw"] = "nʷ",
	               ["NG"] = "ŋ",  ["Nw"] = "ŋʷ",
	["rj"] = "rʲ", ["rG"] = "rˠ", ["rw"] = "rʷ",
	["lj"] = "lʲ", ["lG"] = "lˠ", ["lw"] = "lʷ",
	["hj"] = "j",  ["hG"] = "ɰ",  ["hw"] = "w",
	["_j"] = "",   ["_G"] = "",   ["_w"] = "",
	["a"]  = "æ",
	["E"]  = "ɛ",
	["e"]  = "e",
	["i"]  = "i",
	["I"]  = "i"
}
if false then
	assign(PHONEMIC_MAP, {
		["a"] = "ɐ",
		["E"] = "ə",
		["e"] = "ɘ",
		["i"] = "ɨ",
		["I"] = "ɨ"
	})
end
assign(PHONEMIC_MAP, {
	["yj"] = PHONEMIC_MAP.hj..PHONEMIC_MAP.i..ASYLL..PHONEMIC_MAP.hj,
	["Yj"] = PHONEMIC_MAP.hj..PHONEMIC_MAP.i..PHONEMIC_MAP.hj..PHONEMIC_MAP.hj
})

local function toPhonemic(inSeq)
	local outSeq = {}
	for _, text in pairs(inSeq) do
		text = string.gsub(text, ".[jGw]?", PHONEMIC_MAP)
		addUnique(outSeq, text)
	end
	return outSeq
end



local VOWEL = { -- VOWELS[f1][f2]
	{ "a", "A", "Q" },
	{ "E", "V", "O" },
	{ "e", "7", "o" },
	{ "i", "M", "u" }
}

local F1 = {}
local F2_FRONT = 1
local F2_BACK = 2
local F2_ROUND = 3
local F2 = {
	["j"] = F2_FRONT,
	["G"] = F2_BACK,
	["w"] = F2_ROUND
}

local FRONT_VOWEL = {}
local BACK_VOWEL = {}
local ROUND_VOWEL = {}

for f1, row in pairs(VOWEL) do
	local front = row[F2_FRONT]
	local back = row[F2_BACK]
	local round = row[F2_ROUND]
	for f2, vowel in pairs(row) do
		F1[vowel] = f1
		F2[vowel] = f2
		FRONT_VOWEL[vowel] = front
		BACK_VOWEL[vowel] = back
		ROUND_VOWEL[vowel] = round
	end
end

local function maxF1(a, b, c)
	if c then
		return VOWEL[math.max(F1[a], F1[b], F1[c])][F2_FRONT]
	elseif b then
		return VOWEL[math.max(F1[a], F1[b])][F2_FRONT]
	else
		return FRONT_VOWEL[a]
	end
end

local function toPhoneticDialect(text, config, isRalik)
	
	-- Morphemes can begin with geminated consonants, but spoken words cannot.
	text = string.gsub(text, "^(.[jGw])( *)%1( *)("..VI..")",
		function(conson, _, __, vowel)
			if conson == "hG" then
				if isRalik then
					return "hG"..vowel.._.."hG"..__..vowel
				else
					return "hG".._..__..vowel
				end
			else
				if isRalik then
					return "hj"..maxF1(vowel, "E")..conson.._..conson..__..vowel
				else
					return conson..maxF1(vowel, "E").._..conson..__..vowel
				end
			end
		end
	)
	
	-- Initial {yiyV-, yiwV-, wiwV-} sequences have special behavior.
	-- To block this in the template argument, use "'i" instead of "i".
	text = " "..text
	text = string.gsub(text,
		"([ jGw])( *)(h[jw])( *)i( *)(h[jw])( *)("..VI..")",
		function(nonVowel, _, consonX, __, ___, consonY, ____, vowel)
			if consonY == "hw" then
				-- {yiwV-, wiwV-} sequences
				if isRalik then
					-- Rālik {wiwV-} becomes {yiwV-}.
					consonX = "hj"
				end
				-- {[yw]iwV-} becomes {[yw]iwwV-} in both dialects.
				return nonVowel.._..consonX..__..
					"I"..___..consonY..____..consonY..vowel
			elseif consonX == "hj" then
				-- {yiyV-} sequences
				if isRalik then
					-- "dwelling upon" i
					return nonVowel.._..__.."Yj"..___..____..vowel
				else
					-- "passing over lightly" i
					return nonVowel.._..__.."yj"..___..____..vowel
				end
			end
		end
	)
	text = string.sub(text, 2)
	
	-- Restore protected {i}, we won't be checking for it anymore.
	text = string.gsub(text, "I", "i")
	
	return text
	
end



local IS_VOWEL = FRONT_VOWEL

local VOWEL_REFLEX
if true then
	-- [f1]
	local aEei = { "a", "E", "e", "i" }
	local AEei = { "A", "E", "e", "i" }
	local AV7i = { "A", "V", "7", "i" }
	local AV7M = { "A", "V", "7", "M" }
	local AV7u = { "A", "V", "7", "u" }
	local AOou = { "A", "O", "o", "u" }
	local QOou = { "Q", "O", "o", "u" }
	-- [F2[secondaryR]][f1]
	local _jv_X = { aEei, AEei, QOou }
	local njv_X = { aEei, AV7i, QOou }
	local hjvtX = { aEei, aEei, QOou }
	local hjvkX = { AV7i, AV7i, QOou }
	local _Gv_X = { AV7i, AV7M, QOou }
	local rGv_X = { AEei, AV7M, QOou } -- not currently used
	local hGv_X = { AV7M, AV7M, AV7M }
	local _wv_X = { AV7u, AOou, QOou }
	local rwv_X = { AOou, AOou, QOou }
	local hwv_X = { AV7M, AOou, QOou }
	local hwvtX = { AV7M, AV7M, QOou }
	-- [F2[secondaryL]][F2[secondaryR]][f1]
	local _Xv__ = { _jv_X, _Gv_X, _wv_X }
	local nXv__ = { njv_X, _Gv_X, hwv_X }
	local rXv__ = { _jv_X, _Gv_X, rwv_X }
	local hXv__ = { _jv_X, hGv_X, hwv_X }
	local hXvt_ = { hjvtX, hGv_X, hwvtX }
	local hXvk_ = { hjvkX, hGv_X, _wv_X }
	local hXvr_ = { hjvtX, hGv_X, hwv_X }
	-- [primaryR][F2[secondaryL]][F2[secondaryR]][f1]
	local __vX_ = {
		["p"] = _Xv__, ["t"] = _Xv__, ["k"] = _Xv__,
		["m"] = _Xv__, ["n"] = _Xv__, ["N"] = _Xv__,
		["r"] = _Xv__, ["l"] = _Xv__
	}
	local n_vX_ = {
		["p"] = nXv__, ["t"] = nXv__, ["k"] = nXv__,
		["m"] = nXv__, ["n"] = nXv__, ["N"] = nXv__,
		["r"] = nXv__, ["l"] = nXv__
	}
	local r_vX_ = {
		["p"] = rXv__, ["t"] = rXv__, ["k"] = rXv__,
		["m"] = rXv__, ["n"] = rXv__, ["N"] = rXv__,
		["r"] = rXv__, ["l"] = _Xv__
	}
	local h_vX_ = {
		["p"] = hXv__, ["t"] = hXvt_, ["k"] = hXvk_,
		["m"] = hXv__, ["n"] = hXv__, ["N"] = hXvk_,
		["r"] = hXvr_, ["l"] = hXv__
	}
	-- [primaryL][primaryR][F2[secondaryL]][F2[secondaryR]][f1]
	VOWEL_REFLEX = {
		["p"] = __vX_, ["t"] = __vX_, ["k"] = __vX_,
		["m"] = __vX_, ["n"] = n_vX_, ["N"] = n_vX_,
		["r"] = r_vX_, ["l"] = n_vX_, ["h"] = h_vX_
	}
end

local CONSON_REFLEX
if true then
	local map = {
		["t"] = { ["j"] = "T" },
		["n"] = { ["j"] = "J" },
		["r"] = { ["j"] = "R" },
		["l"] = { ["j"] = "L" }
	}
	for primary in mw.text.gsplit("ptkmnNrl", "") do
		local map2 = map[primary]
		if not map2 then
			map2 = {}
			map[primary] = map2
		end
		map2["j"] = map2["j"] or primary
		map2["G"] = map2["G"] or primary
		map2["w"] = map2["w"] or primary
	end
	map["T"] = map["t"]
	map["J"] = map["n"]
	map["R"] = map["r"]
	map["L"] = map["l"]
	CONSON_REFLEX = map
end

local VOICED_PRIMARY =
	{ ["p"]="b", ["t"]="d", ["T"]="D", ["S"]="Z", ["s"]="z", ["k"]="g" }
local VOICELESS_PRIMARY =
	{ ["b"]="p", ["d"]="t", ["D"]="T", ["Z"]="S", ["z"]="s", ["g"]="k" }

local PHONETIC_IPA
if true then
	local map = {
		["p"] = "p",
		["b"] = "b",
		["B"] = "β̞",
		["t"] = "t",
		["d"] = "d",
		["s"] = "s",
		["z"] = "z",
		["k"] = "k",
		["g"] = "ɡ",
		["m"] = "m",
		["n"] = "n",
		["N"] = "ŋ",
		["r"] = "r",
		["l"] = "l",
		["Hj"] = "j",
		["HG"] = "ʔ",
		["Hw"] = "w",
		["_"] = "‿",
		["j"] = "ʲ",
		["G"] = "ˠ",
		["w"] = "ʷ",
		["a"] = "æ",
		["E"] = "ɛ",
		["e"] = "e",
		["i"] = "i",
		["A"] = "ɑ",
		["V"] = "ʌ",
		["7"] = "ɤ",
		["M"] = "ɯ",
		["Q"] = "ɒ",
		["O"] = "ɔ",
		["o"] = "o",
		["u"] = "u",
		["^"] = ASYLL,
		["@"] = ASYLL,
		["("] = "(",
		[")"] = ")",
		[":"] = "ː",
		["="] = TIE2
	}
	if PHONETIC_DETAILS then
		assign(map, {
			["t"] = "t̪",
			["T"] = "t̠",
			["d"] = "d̪",
			["D"] = "d̠",
			["s"] = "s̠",
			["z"] = "z̠",
			["k"] = "k̠",
			["g"] = "ɡ̠",
			["n"] = "n̠",
			["J"] = "n̪",
			["N"] = "ŋ̠",
			["r"] = "r̠",
			["R"] = "r̪",
			["l"] = "l̠",
			["L"] = "l̪",
			["a"] = "æ̝",
			["E"] = "ɛ̝",
			["E@"] = "e"..map["@"],
			["E^"] = "e"..map["^"],
			["Q"] = "ɒ̝",
			["O"] = "ɔ̝",
			["O@"] = "o"..map["@"],
			["O^"] = "o"..map["^"]
		})
	end
	map["T"] = map["T"] or map["t"]
	map["D"] = map["D"] or map["d"]
	map["S"] = map["S"] or (map["T"]..map["s"])
	map["Z"] = map["Z"] or (map["D"]..map["z"])
	map["kG"] = map["kG"] or map["k"]
	map["gG"] = map["gG"] or map["g"]
	map["J"] = map["J"] or map["n"]
	map["NG"] = map["NG"] or map["N"]
	map["R"] = map["R"] or map["r"]
	map["L"] = map["L"] or map["l"]
	map["Hj"] = map["Hj"] or map["i"]..map["^"]
	local key
	for primary in mw.text.gsplit("pbBtdTDSZszkgmnJNrRlL_", "") do
		for secondary in mw.text.gsplit("jGw", "") do
			key = primary..secondary
			map[key] = map[key] or (map[primary]..map[secondary])
		end
	end
	for vowel in mw.text.gsplit(V_, "") do
		key = vowel.."@"
		map[key] = map[key] or (map[vowel]..map["@"])
		key = vowel.."^"
		map[key] = map[key] or (map[vowel]..map["^"])
	end
	PHONETIC_IPA = map
end

local function toPhoneticRemainder(code, config, leftFlag, rightFlag)
	
	local text = code
	local chars, subst
	
	local diphthongs = config.diphthongs
	
	-- If the phrase begins or ends with a bare vowel
	-- and no pseudo-glide, display phrase up to five times
	-- with each of the different pseudo-glides and possible vowel reflexes.
	if IS_VOWEL[string.sub(text, 1, 1)] then
		text = "_j"..code
		toPhoneticRemainder(text, config, false, rightFlag)
		if not diphthongs then
			toPhoneticRemainder(text, config, true, rightFlag)
		end
		text = "_G"..code
		toPhoneticRemainder(text, config, false, rightFlag)
		if not diphthongs then
			toPhoneticRemainder(text, config, true, rightFlag)
		end
		text = "_w"..code
		toPhoneticRemainder(text, config, false, rightFlag)
		if not diphthongs then
			toPhoneticRemainder(text, config, true, rightFlag)
		end
		return
	end	
	if IS_VOWEL[string.sub(text, -1)] then
		text = code.."_j"
		toPhoneticRemainder(text, config, leftFlag, false)
		if not diphthongs then
			toPhoneticRemainder(text, config, leftFlag, true)
		end
		text = code.."_G"
		toPhoneticRemainder(text, config, leftFlag, false)
		if not diphthongs then
			toPhoneticRemainder(text, config, leftFlag, true)
		end
		text = code.."_w"
		toPhoneticRemainder(text, config, leftFlag, false)
		if not diphthongs then
			toPhoneticRemainder(text, config, leftFlag, true)
		end
		return
	end
	
	local initialJ   = config.initialJ
	local medialJ    = config.medialJ
	local finalJ     = config.finalJ
	local noHints    = config.noHints
	local outSeq     = config.outSeq
	local voice      = config.voice
	
	if	initialJ == "x" or
		medialJ == "x" or
		finalJ == "x"
	then
		local subSeq = {}
		config.outSeq = subSeq
		if initialJ == "x" then
			config.initialJ = "t"
		end
		if medialJ == "x" then
			config.medialJ = "t"
		end
		if finalJ == "x" then
			config.finalJ = "t"
		end
		toPhoneticRemainder(code, config)
		if initialJ == "x" then
			config.initialJ = "s"
		end
		if medialJ == "x" then
			config.medialJ = "s"
		end
		if finalJ == "x" then
			config.finalJ = "s"
		end
		toPhoneticRemainder(code, config)
		addUnique(outSeq, table.concat(subSeq, " ~ "))
		config.outSeq = outSeq
		config.initialJ = initialJ
		config.medialJ = medialJ
		config.finalJ = finalJ
		return
	end
	
	-- Glides always trigger epenthesis, even neighboring other glides.
	text = string_gsub2(text, "([aEei])( *h)(.)( *)(h)%3( *)([aEei])",
		function(vowelL, _, secondary, __, primaryR, ___, vowelR)
			if secondary == "w" then
				primaryR = "H"
			end
			return (
				vowelL.._..secondary..
				maxF1(vowelL, vowelR).."@"..
				__..primaryR..secondary..___..vowelR
			)
		end
	)
	text = string.gsub(text, "([aEei])( *)hG( *.[jGw])", "%1%2hG%1@%3")
	text = string.gsub(text, "(.[jGw])( *)hG( *)([aEei])", "%1%4@%2hG%3%4")
	text = string.gsub(text, "([aEei])( *)h(.)( *.[jGw])", "%1%2h%3%1@%4")
	text = string.gsub(text, "(.[jGw])( *)h(. *)([aEei])", "%1%4@%2h%3%4")
	text = string.gsub(text, "(.[jGw])( *[yY].)", "%1i@%2")
	
	-- Preserve these exceptionally stable clusters.
	text = string.gsub(text, "l([jG] *)tG", "l%1|tG")
	
	-- Unstable consonant clusters trigger epenthesis.
	
	-- Liquids before coronal obstruents.
	text = string.gsub(text, "([rl].)( *)t", "%1v%2t")
	
	-- Nasals and liquids after coronal obstruents.
	text = string.gsub(text, "t(.)( *[nrl])", "t%1v%2")
	
	-- Heterorganic clusters.
	
	-- Labial consonants neighboring coronal or dorsal consonants.
	text = string.gsub(text, "([pm].)( *[tnrlkN])", "%1v%2")
	
	-- Coronal consonants neighboring labial or dorsal consonants.
	text = string.gsub(text, "([tnrl].)( *[pmkN])", "%1v%2")
	
	-- Dorsal consonants neighboring labial or coronal consonants.
	text = string.gsub(text, "([kN].)( *[pmtnrl])", "%1v%2")
	
	-- Organic speech involves certain consonant cluster assimilations.
	
	-- Forward assimilation of rounded consonants.
	-- There is no rounded coronal obstruent.
	text = string.gsub(text, "(w *[^t])[jG]", "%1w")
	
	-- Backward assimilation of remaining secondary articulations.
	text = string.gsub(text, "[jGw]( *.)([jGw])", "%2%1%2")
	
	-- Backward nasal assimilation of primary articulations.
	text = string.gsub(text, "[pkrl](. *)([mnN])", "%2%1%2")
	
	-- No longer need to protect exceptionally stable consonant clusters.
	text = string.gsub(text, "|", "")
	
	-- Give a vowel height to all epenthetic vowels that still lack one.
	text = string_gsub2(text, "(.)( *..)v( *.. *)(.)",
		function(vowelL, consonL, consonR, vowelR)
			return vowelL..consonL..
				maxF1(vowelL, vowelR, "E").."@"..
				consonR..vowelR
		end
	)
	
	-- Tag all vowels for next set of operations.
	text = string.gsub(text, "([aEei])", "/%1")
	
	-- There is no variation in the surface realizations of vowels
	-- between two identical secondary articulations.
	text = string_gsub2(text, "([jGw])( *)/([aEei])(@? *.)%1",
		function(secondary, _, vowel, infix)
			return (
				secondary.._..VOWEL[F1[vowel]][F2[secondary]]..
				infix..secondary
			)
		end
	)
	
	if diphthongs then
		
		text = string_gsub2(text, "(.)([jGw])( *)/([aEei])(@?)( *)(.)([jGw])",
			function(
				primaryL, secondaryL, _, vowel, epenth, __, primaryR, secondaryR
			)
				local f1 = F1[vowel]
				return (
					primaryL..secondaryL.._..
					VOWEL[f1][F2[secondaryL]]..epenth.."="..
					VOWEL[f1][F2[secondaryR]]..epenth..__..
					primaryR..secondaryR
				)
			end
		)
		
	else
		
		-- Vowels neighboring pseudo-glides.
		subst = function(
			primaryL, secondaryL, _, vowel, epenth,
			__, primaryR, secondaryR, flag
		)
			local f2L = F2[secondaryL]
			local f2R = F2[secondaryR]
			local f2
			if flag then
				f2 = math.max(f2L, f2R)
			else
				f2 = math.min(f2L, f2R)
			end
			return (
				primaryL..secondaryL.._..
				VOWEL[F1[vowel]][f2]..epenth..__..
				primaryR..secondaryR
			)
		end
		text = string.gsub(text, "(_)([jGw])( *)/("..V..")(@?)( *)(.)([jGw])",
			function(a, b, c, d, e, f, g, h)
				return subst(a, b, c, d, e, f, g, h, leftFlag)
			end
		)
		text = string.gsub(text, "(.)([jGw])( *)/("..V..")(@?)( *)(_)([jGw])",
			function(a, b, c, d, e, f, g, h)
				return subst(a, b, c, d, e, f, g, h, rightFlag)
			end
		)
		
		-- Vowels between two non-glides have the most predictable reflexes.
		text = string_gsub2(text,
			"([ptkmnNrl])(.)( *)/([aEei])(@? *)([ptkmnNrl])(.)",
			function(
				primaryL, secondaryL, _, vowel, infix, primaryR, secondaryR
			)
				return primaryL..secondaryL.._..
					VOWEL_REFLEX[primaryL][primaryR]
						[F2[secondaryL]][F2[secondaryR]][F1[vowel]]..
					infix..primaryR..secondaryR
			end
		)
		
		-- Exceptionally for the single word "rej".
		text = string.gsub(text, "^(rG *)([V7])( *tj)$",
			function(prefix, vowel, suffix)
				return prefix..FRONT_VOWEL[vowel]..suffix
			end
		)
		
		-- Vowels always claim the secondary articulation
		-- of a neighboring back unrounded glide.
		text = string.gsub(text, "(hG *)/([aEei])", function(prefix, vowel)
			return prefix..BACK_VOWEL[vowel]
		end)
		text = string.gsub(text, "/([aEei])(@? *hG)", function(vowel, suffix)
			return BACK_VOWEL[vowel]..suffix
		end)
		
		-- Unless already claimed, epenthetic vowels after a glide
		-- always claim the secondary articulation to the left.
		text = string.gsub(text, "([hH])(.)( *)/([aEei])@",
			function(primaryL, secondaryL, _, vowel)
				return (
					primaryL..secondaryL.._..
					VOWEL[F1[vowel]][F2[secondaryL]].."@"
				)
			end
		)
		
		-- Unless already claimed, vowels before a glide
		-- always claim the secondary articulation to the right.
		text = string.gsub(text, "/([aEei])(@?)( *[hHyY])(.)",
			function(vowel, epenth, primaryR, secondaryR)
				return (
					VOWEL[F1[vowel]][F2[secondaryR]]..epenth..
					primaryR..secondaryR
				)
			end
		)
		
		-- For now, unless already claimed, vowels before a rounded consonant
		-- claim the secondary articulation to the right.
		text = string.gsub(text, "/([aEei])(@? *.w)", function(vowel, suffix)
			return ROUND_VOWEL[vowel]..suffix
		end)
		
		-- For now, unless already claimed, remaining vowels
		-- claim the secondary articulation to the left.
		text = string.gsub(text, "([jGw])( *)/([aEei])",
			function(secondaryL, _, vowel)
				return secondaryL.._..VOWEL[F1[vowel]][F2[secondaryL]]
			end
		)
		
		-- Change certain vowels in a special environment from round to front.
		text = string_gsub2(text, "(hj *)([Oou])( *.w *"..V.." *h[jh])",
			function(prefix, vowel, suffix)
				return prefix..FRONT_VOWEL[vowel]..suffix
			end
		)
		text = string.gsub(text, "(hj *)([Oou])( *)(.w)( *)("..V..")",
			function(prefix, vowelL, _, conson, __, vowelR)
				if conson ~= "hw" or F1[vowelL] ~= F1[vowelR] then
					return prefix..FRONT_VOWEL[vowelL].._..conson..__..vowelR
				end
			end
		)
		text = string.gsub(text, "(hj *)([Oou])( *.w *.w)",
			function(prefix, vowel, suffix)
				return prefix..FRONT_VOWEL[vowel]..suffix
			end
		)
		text = string.gsub(text, "(a@? *hj *)Q( *.w *"..V..")", "%1a%2")
		text = string.gsub(text, "(a@? *hj *)Q( *.w *.w)", "%1a%2")
		
		-- Tag certain glide-vowel-non-glide sequences for special reflexes.
		text = string.gsub(text, "([HyY][jw] *)("..V.." *[ptkmnNrl])", "%1/%2")
		text = string.gsub(text, "^ *(h[jw] *)("..V.." *[ptkmnNrl])", "%1/%2")
		text = string.gsub(text, "(@ *h[jw] *)("..V.." *[ptkmnNrl])", "%1/%2")
		text = string.gsub(text,
			"([EeiAV7MOou] *h[jw] *)([aAQ] *[ptkmnNrl])", "%1/%2")
		text = string.gsub(text, "([iMu] *hj *)([EeV7] *[kN]G)", "%1/%2")
		text = string.gsub(text,
			"(hj *[aEei]@? *hw *)("..V.." *[ptkmnNrl])", "%1/%2")
		
		-- Untag certain sequences, exempting them from special reflexes.
		text = string.gsub(text, "(hj *)/([aEei] *[knNrl]w)", "%1%2")
		
		-- Special reflexes.
		text = string.gsub(text, "([jw])( *)/("..V..")( *)(.)([jGw])",
			function(secondaryL, _, vowel, __, primaryR, secondaryR)
				return (
					secondaryL.._..
					VOWEL_REFLEX["h"][primaryR]
						[F2[secondaryL]][F2[secondaryR]][F1[vowel]]..
					__..primaryR..secondaryR
				)
			end
		)
		
		-- Exceptional phrase-initial reflex.
		text = string.gsub(text, "^ *([Hh]j *)([V7])( *[kN]G)",
			function(prefix, vowel, suffix)
				return prefix..FRONT_VOWEL[vowel]..suffix
			end
		)
		text = string.gsub(text, "^ *([Hh]w *)M( *tG)", "%1u%2")
		
	end
	
	-- Temporarily cancel epenthetic {i} neighboring {yi'y}.
	text = string.gsub(text, "i@( *yj)", "%1")
	-- {yi'y} neighboring {i} may now be demoted to {y}.
	text = string.gsub(text, "([iMu]@? *)yj", "%1hj")
	text = string.gsub(text, "yj( *[iMu])", "hj%1")
	-- {'yiy} may now be demoted everywhere.
	text = string.gsub(text, "(i@ *)Yj", "%1hjihj")
	text = string.gsub(text, "Yj", "hjihji@hj")
	
	-- For the purposes of this template,
	-- surface all glides pronounced in isolation.
	text = string.gsub(text, "^ *h(.) *$", "H%1")
	
	if not diphthongs then
		
		-- Opportunistically front these vowels.
		text = string.gsub(text, "(hj *)([A7M])( *[kN]G *[kN]?G? *"..V..")",
			function(prefix, vowel, suffix)
				return prefix..FRONT_VOWEL[vowel]..suffix
			end
		)
		
		-- Surface certain glides.
		text = string.gsub(text, "^ *h(w *[Oou])", "H%1")
		text = string.gsub(text, "h(w *[aEeiAV7M])", "H%1")
		text = string.gsub(text, "^ *h(j *[AV7MQOou])", "H%1")
		text = string.gsub(text, "([ptkmnNrl]..@ *)h(w *[Oou])", "%1H%2")
		text = string.gsub(text, "([ptkmnNrl]..@ *)h(j *"..V..")", "%1H%2")
		text = string.gsub(text, "([AV7MQOou]@? *)h(j *[AV7MQOou])", "%1H%2")
		text = string.gsub(text, "([aEeiAV7M])(@? *)hw( *)([QOou])",
			function(vowelL, infix, _, vowelR)
				if F1[vowelL] > F1[vowelR] then
					return vowelL..infix.."Hw".._..vowelR
				end
			end
		)
		text = string.gsub(text, "([AV7MQOou])(@? *)hj( *)([aEei])",
			function(vowelL, infix, _, vowelR)
				if F1[vowelL] > F1[vowelR] then
					return vowelL..infix.."Hj".._..vowelR
				end
			end
		)
		text = string.gsub(text, "([aEei])(@? *)hj( *)([AV7MQOou])",
			function(vowelL, infix, _, vowelR)
				if F1[vowelL] < F1[vowelR] then
					return vowelL..infix.."Hj".._..vowelR
				end
			end
		)
		text = string.gsub(text, "("..V..")( *)h([jw]) *$",
			function(vowel, _, secondary)
				if F2[vowel] ~= F2[secondary] then
					return vowel.._.."H"..secondary
				end
			end
		)
		
		-- Protect word-final epenthetic vowels after non-glides
		-- from the next operation.
		text = string.gsub(text, "([ptkmnNrl]."..V..")(@ )", "%1/%2")
		
		-- De-epenthesize vowels if they still neighbor unsurfaced glides.
		text = string.gsub(text, "("..V..")@( *h.)", "%1%2")
		text = string.gsub(text, "(h. *"..V..")@", "%1")
		
		-- Adjust F1 of currently remaining epenthetic vowels.
		text = string_gsub2(text,
			"("..V..")( *.[jGw])(.)@( *.[jGw] *)("..V..")",
			function(vowelL, infixL, vowel, infixR, vowelR)
				return (
					vowelL..infixL..
					VOWEL[F1[maxF1(vowelL, vowelR, "E")]][F2[vowel]].."/@"..
					infixR..vowelR
				)
			end
		)
		
		text = string.gsub(text, "/", "")
		
	end
	
	-- Delete all remaining unsurfaced glides.
	text = string.gsub(text, "h.", "")
	
	-- Surface realization for {yi'y}.
	text = string.gsub(text, "yj", "i^")
	
	if not diphthongs then
		
		-- Realization for surfaced {y}.
		text = string_gsub2(text, "("..V.."?)(@?)( *)Hj( *)("..V.."?)",
			function(vowelL, epenthL, _, __, vowelR)
				if vowelL ~= "" then
					if vowelR ~= "" then
						if	vowelL == vowelR and
							F2[vowelL] == F2_FRONT
						then
							return vowelL.._..__..vowelR
						else
							return (
								vowelL..epenthL.._..
								maxF1(vowelL, vowelR, "E").."^"..__..vowelR
							)
						end
					else
						return vowelL.._..epenthL..maxF1(vowelL, "E").."^"..__
					end
				else
					if vowelR ~= "" then
						return _..maxF1(vowelR, "E").."^"..__..vowelR
					else
						return _.."i^"..__
					end
				end
			end
		)
		
		-- Flatten this epenthetic vowel and surfaced glide.
		text = string_gsub2(text, "([aAQ] *"..C..")E@( *)E%^( *)a", "%1a%2%3a")
		
		-- Collapse this epenthetic vowel and surfaced glide into a semi-vowel.
		text = string.gsub(text, "([aEei])@( *)%1%^", "%2%1^")
		
	end
	
	if MERGED_VOWELS then
		text = string.gsub(text, "[EO]", function(vowel)
			return VOWEL[F1[vowel] + 1][F2[vowel]]
		end)
	end
	
	chars = splitChars(text, ".")
	
	if not diphthongs then
		-- Geminate long vowels.
		local index = #chars
		repeat
			local ch = chars[index]
			local index2 = index - 1
			if IS_VOWEL[ch] then
				local ch2 = chars[index + 1]
				if	ch2 ~= "@" and
					ch2 ~= "^" and
					chars[index2] == ch
				then
					chars[index] = ":"
				end
			end
			index = index2
		until index == 1
		text = table.concat(chars, "")
	end
	
	-- Tweak remaining consonants, using offsets as a guide.
	text = string.gsub(text, "()(.)([jGw])( *)([ptkmnNrl]?)([jGw]?)()",
		function(
			offsetL, primaryL, secondaryL, _, primaryR, secondaryR, offsetR
		)
			local isInitial = offsetL == 1
			local isFinal = offsetR == #chars + 1
			if	primaryL == "H" or
				primaryL == "y"
			then
				return primaryL..secondaryL.._
			end
			if primaryL == "_" then
				if noHints then
					-- Delete pseudo-glide.
					return _
				end
				if isInitial then
					-- Show secondary articulation to the left, not the right.
					return secondaryL..primaryL.._
				end
				return primaryL..secondaryL.._
			end
			local geminated = primaryL == primaryR
			if primaryL ~= "t" and primaryR == "t" then
				-- /tʲ/         is  palatalized postalveolar.
				-- /tˠ/         is  velarized   dental.
				-- /nʲ, rʲ, lʲ/ are palatalized dental.
				-- /nˠ, rˠ, lˠ/ are velarized   postalveolar.
				-- Regressively assimilate primary dental or postalveolar.
				-- None of this will be visible unless PHONETIC_DETAILS == true.
				primaryL = CONSON_REFLEX[primaryL]
					[secondaryL == "j" and "G" or "j"]
				primaryR = CONSON_REFLEX[primaryR][secondaryR]
			else
				primaryL = CONSON_REFLEX[primaryL][secondaryL]
				if primaryR ~= "" then
					primaryR = CONSON_REFLEX[primaryR][secondaryR]
				end
			end
			if primaryR == "T" then
				if primaryL == "T" then
					primaryL = finalJ
					primaryR = initialJ
					if	primaryL == "S" and
						primaryR ~= "s"
					then
						primaryL = "T"
					elseif
						primaryL == "T" and
						primaryR == "s" and
						medialJ == "S"
					then
						primaryL = "S"
					end
				else
					primaryR = medialJ
				end
			elseif primaryL == "T" then
				if isInitial then
					primaryL = initialJ
				elseif isFinal then
					primaryL = finalJ
				else
					primaryL = medialJ
				end
			end
			if primaryR ~= "" then
				-- Consonant cluster.
				-- For some reason, the {t} in {lt} and {ļt} is voiceless.
				if	not geminated and
					primaryL ~= "l" and
					primaryL ~= "L"
				then
					primaryL = VOICED_PRIMARY[primaryL] or primaryL
					primaryR = VOICED_PRIMARY[primaryR] or primaryR
				end
				-- Display secondary articulation only once for the cluster.
				secondaryL = ""
			elseif
				not isInitial and
				not isFinal
			then
				-- Medial single consonant.
				primaryL = VOICED_PRIMARY[primaryL] or primaryL
			end
			if voice == false then
				primaryL = VOICELESS_PRIMARY[primaryL] or primaryL
				primaryR = VOICELESS_PRIMARY[primaryR] or primaryR
			elseif voice == true then
				primaryL = VOICED_PRIMARY[primaryL] or primaryL
				primaryR = VOICED_PRIMARY[primaryR] or primaryR
			end
			return primaryL..secondaryL.._..primaryR..secondaryR
		end
	)
	
	if not diphthongs then
		
		-- Elegantly connect long and epenthetic vowels across word gaps.
		text = string.gsub(text, "(["..V_..":]): +", "%1 : ")
		text = string.gsub(text, "("..V..") +%1([^%^])", "%1 :%2")
		text = string.gsub(text, "("..V..") +%1$", "%1 :")
		text = string.gsub(text, "("..V..")@ +%1", " %1 :")
		text = string.gsub(text, "("..V.."@) +", " %1 ")
		
		if W_OFF_GLIDES then
			-- Add [w] off-glides after certain consonants.
			subst = function(primary, _, epenth)
				if epenth == "" then
					return primary.."Hw".._
				end
			end
			if false and PHONETIC_DETAILS then
				text = string.gsub(text, "([pbm])(G *[aEei])(@?)",
					function(primary, _, epenth)
						if epenth == "" then
							return primary.."B".._
						end
					end
				)
			else
				text = string.gsub(text, "([pbm])G( *[aEei])(@?)", subst)
			end
			text = string.gsub(text, "([kgnNrl])w( *[aEeiAV7M])(@?)", subst)
			-- Remove [w] off-glides after certain consonants
			-- when they occur after rounded vowels.
			text = string.gsub(text, "([QOou] *[nrl]? *[nrl])Hw", "%1w")
			text = string.gsub(text, "([QOou] *[kgN]? *N)Hw( *M)", "%1w%2")
		end
		
	end
	
	if PARENTHETICAL_EPENTHESIS then
		if not diphthongs then
			text = string.gsub(text, "(.)@("..V..")", "%1^%2")
		end
		text = string.gsub(text, "(.)@", "(%1)")
		text = string.gsub(text, "%)(=?)%(", "%1")
		if not diphthongs and W_OFF_GLIDES then
			if false and PHONETIC_DETAILS then
				text = string.gsub(text, "([pbm]G%()([aEei])", "%1BG%2")
			else
				text = string.gsub(text, "([pbm]G%()([aEei])", "%1Hw%2")
			end
			text = string.gsub(text, "([kgnNrl]w%()([aEeiAV7M])", "%1Hw%2")
			text = string.gsub(text, "([QOou] *[nrl]w%()Hw", "%1")
			text = string.gsub(text, "([QOou] *Nw%()HwM", "%1M")
		end
	end
	
	-- Convert remaining word gaps to liaison.
	text = fastTrim(text)
	text = string.gsub(text, " +", false and "_" or "")
	
	text = string.gsub(text, ".[jGw@%^]?", PHONETIC_IPA)
	
	addUnique(outSeq, text)
	
end



local PHONETIC_ARG_J = { ["t"] = "T", ["c"] = "S", ["s"] = "s", ["x"] = "x" }

local function toPhonetic(inSeq, args)
	
	-- Recognize "ralik" for Rālik Chain (western dialect).
	-- Recognize "ratak" for Ratak Chain (eastern dialect).
	-- For other values, list both possible dialect reflexes where applicable.
	local dialect = args and args.dialect and
		mw.ustring.lower(mw.text.trim(args.dialect)) or ""
	if dialect == "rālik" then
		dialect = "ralik"
	end
	
	-- If enabled, display full diphthong allophones for short vowels.
	local diphthongs = not not (args and parseBoolean(args.diphthongs))
	
	-- Argument "J" has format like "tst".
	-- Recognized letters are "t" = plosive, "c" = affricate, "s" = fricative.
	-- Letters for initial, medial and final respectively.
	-- Real-world pronunciation said to vary by sociological factors,
	-- but all realizations may occur in free variation.
	local modeJ = splitChars(args and args.J and string.lower(args.J) or "tst")
	local initialJ = PHONETIC_ARG_J[modeJ[1] or ""] or "t"
	local medialJ = PHONETIC_ARG_J[modeJ[2] or ""] or "s"
	local finalJ = PHONETIC_ARG_J[modeJ[3] or ""] or initialJ
	
	-- If enabled, do not display pseudo-glide hints at all.
	local noHints = not not (args and parseBoolean(args.nohints))
	
	-- "false" will display all obstruent allophones as voiceless.
	-- "true" will display all obstruent allophones as voiced.
	-- Empty string or absent by default will display
	-- only medial obstruent allophones as semi-voiced.
	local voice = args and args.voice or ""
	if voice ~= "" then
		voice = parseBoolean(voice)
	end
	
	local outSeq = {}
	local config = {
		["outSeq"] = outSeq,
		["diphthongs"] = diphthongs,
		["initialJ"] = initialJ,
		["medialJ"] = medialJ,
		["finalJ"] = finalJ,
		["noHints"] = noHints,
		["voice"] = voice
	}
	
	for _, str in pairs(inSeq) do
		str = string.gsub(str, S, " ")
		str = string.gsub(str, "^ *", "")
		str = string.gsub(str, " *$", "")
		local isRalik = dialect == "ralik"
		if isRalik or dialect == "ratak" then
			str = toPhoneticDialect(str, config, isRalik)
			toPhoneticRemainder(str, config)
		else
			local ralik = toPhoneticDialect(str, config, true)
			local ratak = toPhoneticDialect(str, config, false)
			-- If both dialect reflexes are the same, display only one of them.
			toPhoneticRemainder(ralik, config)
			if ralik ~= ratak then
				toPhoneticRemainder(ratak, config)
			end
		end
	end
	
	return outSeq
	
end



export._parse = parse
export._toBender = toBender
export._toMOD = toMOD
export._toPhonemic = toPhonemic
export._toPhonetic = toPhonetic

function export.bender(frame)
	return table.concat(toBender(parse(frame.args[1], frame.args)), ", ")
end

function export.MOD(frame)
	return toMOD(frame.args[1])
end

function export.parse(frame)
	return table.concat(parse(frame.args[1]), ", ")
end

function export.phonemic(frame)
	return table.concat(toPhonemic(parse(frame.args[1])), ", ")
end

function export.phonetic(frame)
	return table.concat(toPhonetic(parse(frame.args[1]), frame.args), ", ")
end

function export.phoneticMED(frame)
	return "DEPRECATED"
end

function export.phoneticChoi(frame)
	return "DEPRECATED"
end

function export.phoneticWillson(frame)
	return "DEPRECATED"
end

return export