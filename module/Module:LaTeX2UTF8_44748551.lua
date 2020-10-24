local p = {}

--[[
These are what wikipedia deems to be "Latin" special characters that 
are NOT yet handled by this module.

ĐđĢģĦħıĶķĻļĽľŅņŖŗŠšȘșȚțŤťǖǘǚǜ
ÆæǢǣØøŒœßÐðÞþƏə

And these are the ones that are.

ÀàÈèÌìÒòÙù					-- (`) grave accent
ÁáĆćÉéÍíĺŃńÓóŔŕŚśÚúÝýŹź		-- (') acute accent
ÂâĈĉÊêĜĝĤĥÎîĴĵÔôŜŝÛûŴŵŶŷ	-- (^) circumflex
ÄäËëÏïÖöÜüŸÿ				-- (") umlaut, trema or dieresis
ŐőŰű						-- (H) long Hungarian umlaut (double acute)
ÃãĨĩÑñÕõŨũ					-- (~) tilde
ÇçĘęĮįǪǫŞşŲų				-- (c) cedilla
Ąą							-- (k) ogonek
Łł							-- (l) barred L (L with stroke)
ĀāĒēĪīŌōŪūȲȳ				-- (=) macron accent (a bar over the letter)
ĊċĖėĠġİŻż					-- (.) dot over the letter
ÅåŮů						-- (r) ring over the letter
ĂăĔĕĞğĬĭŎŏŬŭ				-- (u) breve over the letter
ǍǎČčĎďĚěǏǐŇňǑǒŘřǓǔŽž		-- (v) caron/háček ("v") over the letter

]]

p.diacrit = {}

p.diacrit["`"] = {}			-- grave accent
p.diacrit["`"]["a"] = "à"
p.diacrit["`"]["A"] = "À"
p.diacrit["`"]["e"] = "è"
p.diacrit["`"]["E"] = "È"
p.diacrit["`"]["i"] = "ì"
p.diacrit["`"]["I"] = "Ì"
p.diacrit["`"]["o"] = "ò"
p.diacrit["`"]["O"] = "Ò"
p.diacrit["`"]["u"] = "ù"
p.diacrit["`"]["U"] = "Ù"

p.diacrit["'"] = {}			-- accute accent
p.diacrit["'"]["a"] = "á"
p.diacrit["'"]["A"] = "Á"
p.diacrit["'"]["c"] = "ć"
p.diacrit["'"]["C"] = "Ć"
p.diacrit["'"]["e"] = "é"
p.diacrit["'"]["E"] = "É"
p.diacrit["'"]["i"] = "í"
p.diacrit["'"]["I"] = "Í"
p.diacrit["'"]["l"] = "ĺ"
p.diacrit["'"]["n"] = "ń"
p.diacrit["'"]["N"] = "Ń"
p.diacrit["'"]["o"] = "ó"
p.diacrit["'"]["O"] = "Ó"
p.diacrit["'"]["r"] = "ŕ"
p.diacrit["'"]["R"] = "Ŕ"
p.diacrit["'"]["s"] = "ś"
p.diacrit["'"]["S"] = "Ś"
p.diacrit["'"]["u"] = "ú"
p.diacrit["'"]["U"] = "Ú"
p.diacrit["'"]["y"] = "ý"
p.diacrit["'"]["Y"] = "Ý"
p.diacrit["'"]["z"] = "ź"
p.diacrit["'"]["Z"] = "Ź"

p.diacrit["^"] = {}			-- circumflex
p.diacrit["^"]["A"] = "Â"
p.diacrit["^"]["a"] = "â"
p.diacrit["^"]["C"] = "Ĉ"
p.diacrit["^"]["c"] = "ĉ"
p.diacrit["^"]["E"] = "Ê"
p.diacrit["^"]["e"] = "ê"
p.diacrit["^"]["G"] = "Ĝ"
p.diacrit["^"]["g"] = "ĝ"
p.diacrit["^"]["H"] = "Ĥ"
p.diacrit["^"]["h"] = "ĥ"
p.diacrit["^"]["I"] = "Î"
p.diacrit["^"]["i"] = "î"
p.diacrit["^"]["J"] = "Ĵ"
p.diacrit["^"]["j"] = "ĵ"
p.diacrit["^"]["O"] = "Ô"
p.diacrit["^"]["o"] = "ô"
p.diacrit["^"]["S"] = "Ŝ"
p.diacrit["^"]["s"] = "ŝ"
p.diacrit["^"]["U"] = "Û"
p.diacrit["^"]["u"] = "û"
p.diacrit["^"]["W"] = "Ŵ"
p.diacrit["^"]["w"] = "ŵ"
p.diacrit["^"]["Y"] = "Ŷ"
p.diacrit["^"]["y"] = "ŷ"

p.diacrit["\""] = {}		-- umlaut, trema or dieresis
p.diacrit["\""]["A"] = "Ä"
p.diacrit["\""]["a"] = "ä"
p.diacrit["\""]["E"] = "Ë"
p.diacrit["\""]["e"] = "ë"
p.diacrit["\""]["I"] = "Ï"
p.diacrit["\""]["i"] = "ï"
p.diacrit["\""]["O"] = "Ö"
p.diacrit["\""]["o"] = "ö"
p.diacrit["\""]["U"] = "Ü"
p.diacrit["\""]["u"] = "ü"
p.diacrit["\""]["Y"] = "Ÿ"
p.diacrit["\""]["y"] = "ÿ"

p.diacrit["H"] = {} 		-- long Hungarian umlaut (double acute)
p.diacrit["H"]["o"] = "ő"
p.diacrit["H"]["O"] = "Ő"
p.diacrit["H"]["u"] = "ű"
p.diacrit["H"]["U"] = "Ű"

p.diacrit["~"] = {}			-- tilde
p.diacrit["~"]["A"] = "Ã"
p.diacrit["~"]["a"] = "ã"
p.diacrit["~"]["I"] = "Ĩ"
p.diacrit["~"]["i"] = "ĩ"
p.diacrit["~"]["N"] = "Ñ"
p.diacrit["~"]["n"] = "ñ"
p.diacrit["~"]["O"] = "Õ"
p.diacrit["~"]["o"] = "õ"
p.diacrit["~"]["U"] = "Ũ"
p.diacrit["~"]["u"] = "ũ"

p.diacrit["c"] = {}			-- cedilla
p.diacrit["c"]["C"] = "Ç"
p.diacrit["c"]["c"] = "ç"
p.diacrit["c"]["E"] = "Ę"
p.diacrit["c"]["e"] = "ę"
p.diacrit["c"]["I"] = "Į"
p.diacrit["c"]["i"] = "į"
p.diacrit["c"]["O"] = "Ǫ"
p.diacrit["c"]["o"] = "ǫ"
p.diacrit["c"]["S"] = "Ş"
p.diacrit["c"]["s"] = "ş"
p.diacrit["c"]["U"] = "Ų"
p.diacrit["c"]["u"] = "ų"

p.diacrit["k"] = {}			-- ogonek
p.diacrit["k"]["A"] = "Ą"
p.diacrit["k"]["a"] = "ą"

p.diacrit["l"] = {}			-- barred L (L with stroke)
p.diacrit["l"]["L"] = "Ł"
p.diacrit["l"]["l"] = "ł"

p.diacrit["="] = {}			-- macron accent (a bar over the letter)
p.diacrit["="]["A"] = "Ā"
p.diacrit["="]["a"] = "ā"
p.diacrit["="]["E"] = "Ē"
p.diacrit["="]["e"] = "ē"
p.diacrit["="]["I"] = "Ī"
p.diacrit["="]["i"] = "ī"
p.diacrit["="]["O"] = "Ō"
p.diacrit["="]["o"] = "ō"
p.diacrit["="]["U"] = "Ū"
p.diacrit["="]["u"] = "ū"
p.diacrit["="]["Y"] = "Ȳ"
p.diacrit["="]["y"] = "ȳ"

p.diacrit["."] = {}			-- dot over the letter
p.diacrit["."]["C"] = "Ċ"
p.diacrit["."]["c"] = "ċ"
p.diacrit["."]["E"] = "Ė"
p.diacrit["."]["e"] = "ė"
p.diacrit["."]["G"] = "Ġ"
p.diacrit["."]["g"] = "ġ"
p.diacrit["."]["I"] = "İ"
p.diacrit["."]["Z"] = "Ż"
p.diacrit["."]["z"] = "ż"

p.diacrit["r"] = {}			-- ring over the letter
p.diacrit["r"]["A"] = "Å"
p.diacrit["r"]["a"] = "å"
p.diacrit["r"]["U"] = "Ů"
p.diacrit["r"]["u"] = "ů"

p.diacrit["u"] = {}			-- breve over the letter
p.diacrit["u"]["A"] = "Ă"
p.diacrit["u"]["a"] = "ă"
p.diacrit["u"]["E"] = "Ĕ"
p.diacrit["u"]["e"] = "ĕ"
p.diacrit["u"]["G"] = "Ğ"
p.diacrit["u"]["g"] = "ğ"
p.diacrit["u"]["I"] = "Ĭ"
p.diacrit["u"]["i"] = "ĭ"
p.diacrit["u"]["O"] = "Ŏ"
p.diacrit["u"]["o"] = "ŏ"
p.diacrit["u"]["U"] = "Ŭ"
p.diacrit["u"]["u"] = "ŭ"

p.diacrit["v"] = {}			-- caron/háček ("v") over the letter
p.diacrit["v"]["A"] = "Ǎ"
p.diacrit["v"]["a"] = "ǎ"
p.diacrit["v"]["C"] = "Č"
p.diacrit["v"]["c"] = "č"
p.diacrit["v"]["D"] = "Ď"
p.diacrit["v"]["d"] = "ď"
p.diacrit["v"]["E"] = "Ě"
p.diacrit["v"]["e"] = "ě"
p.diacrit["v"]["I"] = "Ǐ"
p.diacrit["v"]["i"] = "ǐ"
p.diacrit["v"]["N"] = "Ň"
p.diacrit["v"]["n"] = "ň"
p.diacrit["v"]["O"] = "Ǒ"
p.diacrit["v"]["o"] = "ǒ"
p.diacrit["v"]["R"] = "Ř"
p.diacrit["v"]["r"] = "ř"
p.diacrit["v"]["U"] = "Ǔ"
p.diacrit["v"]["u"] = "ǔ"
p.diacrit["v"]["Z"] = "Ž"
p.diacrit["v"]["z"] = "ž"

p.cc = "[%~%`%'%^\"%=%.Hcklruv]"	-- LaTeX control characters we care about
-- Note that these need to be applied in order, 
-- otherwise we're left with stray braces littering the text.
p.c1 = "{\\" .. p.cc .. "{%a}}"		-- e.g., {\'{a}}
p.c2 = "{\\" .. p.cc .. " %a}"		-- e.g., {\' a}
p.c3 = "{\\" .. p.cc .. "%a}"		-- e.g., {\'a}
p.c4 = "\\" .. p.cc .. "%a"			-- e.g., \'a

p.latex_patterns = {}
p.latex_patterns[p.c1] = {}
p.latex_patterns[p.c1]["ctl"] = 3	-- 3rd character is the control character
p.latex_patterns[p.c1]["ltr"] = 5	-- 5th character is the accented letter

p.latex_patterns[p.c2] = {}
p.latex_patterns[p.c2]["ctl"] = 3
p.latex_patterns[p.c2]["ltr"] = 5

p.latex_patterns[p.c3] = {}
p.latex_patterns[p.c3]["ctl"] = 3
p.latex_patterns[p.c3]["ltr"] = 4

p.latex_patterns[p.c4] = {}
p.latex_patterns[p.c4]["ctl"] = 2
p.latex_patterns[p.c4]["ltr"] = 3


function p.translate_diacritics( s )
	local str = "_"	-- the string that matches the LaTeX control sequence
	local ctl = "_"	-- the LaTeX control character (e.g., "k" adds an ogonek
	local ltr = "_" -- the letter receiving the diacritic
	local utf = "_" -- the UTF8 representation of the control sequence
	
	for k, v in pairs(p.latex_patterns)	do			-- many ways to create diacritics
		while mw.ustring.find( s, k ) do
			str = mw.ustring.match( s, k ) 
			ctl	= mw.ustring.sub( str, v["ctl"], v["ctl"] ) 
			ltr	= mw.ustring.sub( str, v["ltr"], v["ltr"] ) 
			utf = p.diacrit[ ctl ][ ltr ]
			if utf then
				s = mw.ustring.gsub( s, k, utf )
			else
				s = mw.ustring.gsub( s, k, "<<<UNHANDLED DIACRIT>>>" )
			end
		end
	end	
	return s
end

function p.translate_special_characters( s )
	s = mw.ustring.gsub( s, "\\%%", "%%" )
	s = mw.ustring.gsub( s, "\\$", "$" )
	s = mw.ustring.gsub( s, "\\{", "{" )
	s = mw.ustring.gsub( s, "\\_", "_" )
	s = mw.ustring.gsub( s, "\\#", "#" )
	s = mw.ustring.gsub( s, "\\&", "&" )
	s = mw.ustring.gsub( s, "\\}", "}" )
	return s
end

return p