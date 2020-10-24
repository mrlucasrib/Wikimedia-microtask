local p = {}

local U = mw.ustring.char
-- Slashes \, apostrophes ', and double quotes " are escaped with \.
-- \\ = \, \' = ', \" = "

local data = {
	["a"] = { "a" },
	["b"] = { "b" },
	-- not in official X-SAMPA; from http://www.kneequickie.com/kq/Z-SAMPA and used by Wiktionary
	["b\\"] = { "ⱱ" },
	["b_<"] = { "ɓ" },
	["c"] = { "c" },
	["d"] = { "d" },
	["d`"] = { "ɖ", has_descender = true },
	["d_<"] = { "ɗ" },
	-- not in official X-SAMPA; Wikipedia-specific
	["d`_<"] = { "ᶑ", has_descender = true },
	["e"] = { "e" },
	["f"] = { "f" },
	["g"] = { "ɡ", has_descender = true  },
	["g_<"] = { "ɠ", has_descender = true },
	["h"] = { "h" },
	["h\\"] = { "ɦ" },
	["i"] = { "i" },
	["j"] = { "j", has_descender = true  },
	["j\\"] = { "ʝ", has_descender = true  },
	["k"] = { "k" },
	["l"] = { "l" },
	["l`"] = { "ɭ", has_descender = true  },
	["l\\"] = { "ɺ" },
	["m"] = { "m" },
	["n"] = { "n" },
	["n`"] = { "ɳ", has_descender = true  },
	["o"] = { "o" },
	["p"] = { "p", has_descender = true  },
	["p\\"] = { "ɸ", has_descender = true  },
	["q"] = { "q", has_descender = true  },
	["r"] = { "r" },
	["r`"] = { "ɽ", has_descender = true  },
	["r\\"] = { "ɹ" },
	["r\\`"] = { "ɻ", has_descender = true  },
	["s"] = { "s" },
	["s`"] = { "ʂ", has_descender = true  },
	["s\\"] = { "ɕ" },
	["t"] = { "t" },
	["t`"] = { "ʈ" },
	["u"] = { "u" },
	["v"] = { "v" },
	["v\\"] = { "ʋ" },
	["w"] = { "w" },
	["x"] = { "x" },
	["x\\"] = { "ɧ", has_descender = true  },
	["y"] = { "y", has_descender = true  },
	["z"] = { "z" },
	["z`"] = { "ʐ", has_descender = true  },
	["z\\"] = { "ʑ" },
	["A"] = { "ɑ" },
	["B"] = { "β", has_descender = true  },
	["B\\"] = { "ʙ" },
	["C"] = { "ç", has_descender = true  },
	["D"] = { "ð" },
	["E"] = { "ɛ" },
	["F"] = { "ɱ", has_descender = true  },
	["G"] = { "ɣ", has_descender = true  },
	["G\\"] = { "ɢ" },
	["G\\_<"] = { "ʛ" },
	["H"] = { "ɥ", has_descender = true  },
	["H\\"] = { "ʜ" },
	["I"] = { "ɪ" },
	["I\\"] = { "ɪ̈" },
	["J"] = { "ɲ", has_descender = true  },
	["J\\"] = { "ɟ" },
	["J\\_<"] = { "ʄ", has_descender = true  },
	["K"] = { "ɬ" },
	["K\\"] = { "ɮ", has_descender = true  },
	["L"] = { "ʎ" },
	["L\\"] = { "ʟ" },
	["M"] = { "ɯ" },
	["M\\"] = { "ɰ", has_descender = true  },
	["N"] = { "ŋ", has_descender = true  },
	["N\\"] = { "ɴ" },
	["O"] = { "ɔ" },
	["O\\"] = { "ʘ" },
	["P"] = { "ʋ" },
	["Q"] = { "ɒ" },
	["R"] = { "ʁ" },
	["R\\"] = { "ʀ" },
	["S"] = { "ʃ", has_descender = true  },
	["T"] = { "θ" },
	["U"] = { "ʊ" },
	["U\\"] = { "ʊ̈" },
	["V"] = { "ʌ" },
	["W"] = { "ʍ" },
	["X"] = { "χ", has_descender = true  },
	["X\\"] = { "ħ" },
	["Y"] = { "ʏ" },
	["Z"] = { "ʒ", has_descender = true  },
	["."] = { "." },
	["\""] = { "ˈ" },
	["%"] = { "ˌ" },
	-- not in official X-SAMPA; from http://www.kneequickie.com/kq/Z-SAMPA and used by Wiktionary
	["%\\"] = { "ᴙ" }, 
	["'"] = { "ʲ", is_diacritic = true },
	[":"] = { "ː", is_diacritic = true },
	[":\\"] = { "ˑ", is_diacritic = true },
	["@"] = { "ə" },
	["@`"] = { "ɚ" },
	["@\\"] = { "ɘ" },
	["{"] = { "æ" },
	["}"] = { "ʉ" },
	["1"] = { "ɨ" },
	["2"] = { "ø" },
	["3"] = { "ɜ" },
	["3`"] = { "ɝ" },
	["3\\"] = { "ɞ" },
	["4"] = { "ɾ" },
	["5"] = { "ɫ" },
	["6"] = { "ɐ" },
	["7"] = { "ɤ" },
	["8"] = { "ɵ" },
	["9"] = { "œ" },
	["&"] = { "ɶ" },
	["?"] = { "ʔ" },
	["?\\"] = { "ʕ" },
	["<\\"] = { "ʢ" },
	[">\\"] = { "ʡ" },
	["^"] = { "ꜛ" },
	["!"] = { "ꜜ" },
	-- not in official X-SAMPA
	["!!"] = { "‼" }, 
	["!\\"] = { "ǃ" },
	["|"] = { "|", has_descender = true  },
	["|\\"] = { "ǀ", has_descender = true  },
	["||"] = { "‖", has_descender = true  },
	["|\\|\\"] = { "ǁ", has_descender = true  },
	["=\\"] = { "ǂ", has_descender = true  },
	-- linking mark, liaison
	["-\\"] = { "‿", is_diacritic = true }, 
	-- coarticulated; not in official X-SAMPA; used by Wiktionary
	["__"] = { U(0x361) }, 
	-- fortis, strong articulation; not in official X-SAMPA; used by Wiktionary
	["_:"] = { U(0x348) }, 
	["_\""] = { U(0x308), is_diacritic = true },
	-- advanced
	["_+"] = { U(0x31F), with_descender = "˖", is_diacritic = true }, 
	-- retracted
	["_-"] = { U(0x320), with_descender = "˗", is_diacritic = true }, 
	-- rising tone
	["_/"] = { U(0x30C), is_diacritic = true }, 
	-- voiceless
	["_0"] = { U(0x325), with_descender = U(0x30A), is_diacritic = true }, 
	-- syllabic
	["="] = { U(0x329), with_descender = U(0x30D), is_diacritic = true }, 
	-- syllabic
	["_="] = { U(0x329), with_descender = U(0x30D), is_diacritic = true }, 
	-- strident: not in official X-SAMPA; from http://www.kneequickie.com/kq/Z-SAMPA and used by Wiktionary
	["_%\\"] = { U(0x1DFD) }, 
	-- ejective
	["_>"] = { "ʼ", is_diacritic = true }, 
	-- pharyngealized
	["_?\\"] = { "ˤ", is_diacritic = true }, 
	-- falling tone
	["_\\"] = { U(0x302), is_diacritic = true }, 
	-- non-syllabic
	["_^"] = { U(0x32F), with_descender = U(0x311), is_diacritic = true }, 
	-- no audible release
	["_}"] = { U(0x31A), is_diacritic = true }, 
	-- r-coloring (colouring), rhotacization
	["`"] = { U(0x2DE), is_diacritic = true }, 
	-- nasalization
	["~"] = { U(0x303), is_diacritic = true }, 
	-- advanced tongue root
	["_A"] = { U(0x318), is_diacritic = true }, 
	-- apical
	["_a"] = { U(0x33A), is_diacritic = true }, 
	-- extra-low tone
	["_B"] = { U(0x30F), is_diacritic = true }, 
	-- low rising tone
	["_B_L"] = { U(0x1DC5), is_diacritic = true }, 
	-- less rounded
	["_c"] = { U(0x31C), is_diacritic = true }, 
	-- dental
	["_d"] = { U(0x32A), is_diacritic = true }, 
	-- velarized or pharyngealized (dark)
	["_e"] = { U(0x334), is_diacritic = true }, 
	-- downstep
	["<F>"] = { "↘" }, 
	-- falling tone
	["_F"] = { U(0x302), is_diacritic = true }, 
	-- velarized
	["_G"] = { "ˠ", is_diacritic = true }, 
	-- high tone
	["_H"] = { U(0x301), is_diacritic = true }, 
	-- high rising tone
	["_H_T"] = { U(0x1DC4), is_diacritic = true }, 
	-- aspiration
	["_h"] = { "ʰ", is_diacritic = true }, 
	-- palatalization
	["_j"] = { "ʲ", is_diacritic = true }, 
	-- creaky voice, laryngealization, vocal fry
	["_k"] = { U(0x330), is_diacritic = true }, 
	-- low tone
	["_L"] = { U(0x300), is_diacritic = true }, 
	-- lateral release
	["_l"] = { "ˡ", is_diacritic = true }, 
	-- mid tone
	["_M"] = { U(0x304), is_diacritic = true }, 
	-- laminal
	["_m"] = { U(0x33B), is_diacritic = true }, 
	-- linguolabial
	["_N"] = { U(0x33C), is_diacritic = true }, 
	-- nasal release
	["_n"] = { "ⁿ", is_diacritic = true }, 
	-- more rounded
	["_O"] = { U(0x339), is_diacritic = true }, 
	-- lowered
	["_o"] = { U(0x31E), with_descender = "˕", is_diacritic = true }, 
	-- retracted tongue root
	["_q"] = { U(0x319), is_diacritic = true }, 
	-- global rise
	["<R>"] = { "↗" }, 
	-- rising tone
	["_R"] = { U(0x30C), is_diacritic = true }, 
	-- rising falling tone
	["_R_F"] = { U(0x1DC8), is_diacritic = true }, 
	-- raised
	["_r"] = { U(0x31D), is_diacritic = true }, 
	-- extra-high tone
	["_T"] = { U(0x30B), is_diacritic = true }, 
	-- breathy voice, murmured voice, murmur, whispery voice
	["_t"] = { U(0x324), is_diacritic = true }, 
	-- voiced
	["_v"] = { U(0x32C), is_diacritic = true }, 
	-- labialized
	["_w"] = { "ʷ", is_diacritic = true }, 
	-- extra-short
	["_X"] = { U(0x306), is_diacritic = true }, 
	-- mid-centralized
	["_x"] = { U(0x33D), is_diacritic = true }, 
	["__T"] = { "˥" },
	["__H"] = { "˦" },
	["__M"] = { "˧" },
	["__L"] = { "˨" },
	["__B"] = { "˩" },
	["0"] = { "◌" },	-- dotted circle
}

local function escape(text, pattern, list, i)
	text = mw.ustring.gsub(
		text,
		pattern,
		function(match)
			list[i] = match
			local replacement = string.rep("$", i)
			i = i + 1
			return replacement
		end
	)

	return text
end

local function _XSAMPAtoIPA(text)
	local output = {}
	local characteristics = {}
	
	local escaped = {}
	local i = 1
	local toBeEscaped = { "*(.)", "'''" }

	for i, pattern in pairs(toBeEscaped) do
		text = mw.ustring.gsub(
			text,
			pattern,
			function(match)
				escaped[i] = match
				local replacement = string.rep("$", i) .. "*"
				i = i + 1
				return replacement
			end
		)
	end
	mw.log(i, #escaped, text)
	mw.logObject(escaped)
	
	while #text > 0 do
		local substrings = {
			mw.ustring.sub(text, 1, 4),
			mw.ustring.sub(text, 1, 3),
			mw.ustring.sub(text, 1, 2),
			mw.ustring.sub(text, 1, 1)
		}
		
		for i, substring in ipairs(substrings) do
			local result, IPA, with_descender, has_descender, is_diacritic
			
			if data[substring] then
				result = data[substring]
				IPA = result[1]
				with_descender = result.with_descender
				has_descender = result.has_descender
				diacritic = result.is_diacritic
				if with_descender then
					-- Go backwords through the transcription, skipping any diacritics.
					local i = 0
					while characteristics[#characteristics - i].is_diacritic do
						i = i + 1
					end
					--[[	Look at the first non-diacritic symbol before the current symbol.
							If it has a descender, use the descender form of the current symbol. ]]
					if characteristics[#characteristics - i].has_descender then
						IPA = with_descender
					end
				end
			elseif not substrings[i + 1] then
				IPA = substring
			end
			
			if IPA then
				text = mw.ustring.sub(text, 6 - i)
				table.insert(output, IPA)
				table.insert(characteristics, { has_descender = has_descender, is_diacritic = is_diacritic } )
				break
			end
		end
	end
	
	output = table.concat(output)
	
	output = mw.ustring.gsub(
		output,
		"($+)%*",
		function(match)
			local i = string.len(match)
			return escaped[i]
		end
	)
	
	return output
end

function p.X2IPA(frame)
	local text
	
	if type(frame) == "table" then
		text = frame.getParent and frame:getParent().args[1] or frame.args and frame.args[1]
	else
		text = frame
	end
	
	return _XSAMPAtoIPA(text)
end

local function _IPAspan(text)
	return "<span class=\"IPA\">"..text.."</span>"
end

function p.example(frame)
	local args = frame.args
	local parentargs = frame.getParent and frame:getParent().args
	
	local text = parentargs and parentargs[1]
		or args and args[1]
		or type(frame) == "string" and frame
		or error("No text provided")
	
	local output = { " <code>&#123;&#123;[[mw:Manual:Substitution|subst:]][[Template:x2i|x2i]]&#124;" }
	
	if mw.ustring.find(text, "=") then
		table.insert(output, "1=")
	end
	table.insert(output, text)
	
	table.insert(output, "&#125;&#125;</code>")
	
	table.insert(output, "\n| ")
	local IPA = _IPAspan(p.X2IPA(text))
	table.insert(output, IPA)
	
	return table.concat(output)
end

return p