--[[
convertChar returns the non-diacritic version of the supplied character.
stripDiacrits replaces words with diacritical characters with their non-diacritic equivalent.
strip_diacrits is available for export to other modules.
isLike tests two words, returning true if they only differ in diacritics, false otherwise.
is_like is available for export to other modules.
--]]

local p = {}

local chars = {
	A = { 'Á', 'À', 'Â', 'Ä', 'Ǎ', 'Ă', 'Ā', 'Ã', 'Å', 'Ą' },
	C = { 'Ć', 'Ċ', 'Ĉ', 'Č', 'Ç' },
	D = { 'Ď', 'Đ', 'Ḍ', 'Ð' },
	E = { 'É', 'È', 'Ė', 'Ê', 'Ë', 'Ě', 'Ĕ', 'Ē', 'Ẽ', 'Ę', 'Ẹ' },
	G = { 'Ġ', 'Ĝ', 'Ğ', 'Ģ' },
	H = { 'Ĥ', 'Ħ', 'Ḥ' },
	I = { 'İ', 'Í', 'Ì', 'Î', 'Ï', 'Ǐ', 'Ĭ', 'Ī', 'Ĩ', 'Į', 'Ị' },
	J = { 'Ĵ' },
	K = { 'Ķ' },
	L = { 'Ĺ', 'Ŀ', 'Ľ', 'Ļ', 'Ł', 'Ḷ', 'Ḹ' },
	M = { 'Ṃ' },
	N = { 'Ń', 'Ň', 'Ñ', 'Ņ', 'Ṇ', 'Ŋ' },
	O = { 'Ó', 'Ò', 'Ô', 'Ö', 'Ǒ', 'Ŏ', 'Ō', 'Õ', 'Ǫ', 'Ọ', 'Ő', 'Ø' },
	R = { 'Ŕ', 'Ř', 'Ŗ', 'Ṛ', 'Ṝ' },
	S = { 'Ś', 'Ŝ', 'Š', 'Ş', 'Ș', 'Ṣ' },
	T = { 'Ť', 'Ţ', 'Ț', 'Ṭ' },
	U = { 'Ú', 'Ù', 'Û', 'Ü', 'Ǔ', 'Ŭ', 'Ū', 'Ũ', 'Ů', 'Ų', 'Ụ', 'Ű', 'Ǘ', 'Ǜ', 'Ǚ', 'Ǖ' },
	W = { 'Ŵ' },
	Y = { 'Ý', 'Ŷ', 'Ÿ', 'Ỹ', 'Ȳ' },
	Z = { 'Ź', 'Ż', 'Ž' },

	a = { 'á', 'à', 'â', 'ä', 'ǎ', 'ă', 'ā', 'ã', 'å', 'ą' },
	c = { 'ć', 'ċ', 'ĉ', 'č', 'ç' },
	d = { 'ď', 'đ', 'ḍ', 'ð' },
	e = { 'é', 'è', 'ė', 'ê', 'ë', 'ě', 'ĕ', 'ē', 'ẽ', 'ę', 'ẹ' },
	g = { 'ġ', 'ĝ', 'ğ', 'ģ' },
	h = { 'ĥ', 'ħ', 'ḥ' },
	i = { 'ı', 'í', 'ì', 'î', 'ï', 'ǐ', 'ĭ', 'ī', 'ĩ', 'į' },
	j = { 'ĵ' },
	k = { 'ķ' },
	l = { 'ĺ', 'ŀ', 'ľ', 'ļ', 'ł', 'ḷ', 'ḹ' },
	m = { 'ṃ' },
	n = { 'ń', 'ň', 'ñ', 'ņ', 'ṇ', 'ŋ' },
	o = { 'ó', 'ò', 'ô', 'ö', 'ǒ', 'ŏ', 'ō', 'õ', 'ǫ', 'ọ', 'ő', 'ø' },
	r = { 'ŕ', 'ř', 'ŗ', 'ṛ', 'ṝ' },
	s = { 'ś', 'ŝ', 'š', 'ş', 'ș', 'ṣ' },
	ss = { 'ß' },
	t = { 'ť', 'ţ', 'ț', 'ṭ' },
	u = { 'ú', 'ù', 'û', 'ü', 'ǔ', 'ŭ', 'ū', 'ũ', 'ů', 'ų', 'ụ', 'ű', 'ǘ', 'ǜ', 'ǚ', 'ǖ' },
	w = { 'ŵ' },
	y = { 'ý', 'ŷ', 'ÿ', 'ỹ', 'ȳ' },
	z = { 'ź', 'ż', 'ž' },
}

local char_idx = {}
for k1, v1 in pairs(chars) do
	for k2, v2 in pairs(v1) do
		char_idx[v2] = k1
	end
end


p.convertChar = function(frame)
	local ch = frame.args.char or mw.text.trim(frame.args[1]) or ""
	return char_idx[ch] or ch
end


p.strip_diacrits = function(wrd)
	if not wrd or wrd == "" then return "" end
	for ch in mw.ustring.gmatch(wrd, "%a") do
		if char_idx[ch] then
			wrd = wrd:gsub(ch, char_idx[ch])
		end
	end
	return wrd
end

p.stripDiacrits = function(frame)
	return p.strip_diacrits(frame.args.word or mw.text.trim(frame.args[1]))
end


p.is_like = function(wrd1, wrd2)
	return p.strip_diacrits(wrd1) == p.strip_diacrits(wrd2)
end

p.isLike = function(frame)
	local wrd1 = frame.args.word1 or frame.args[1]
	local wrd2 = frame.args.word2 or frame.args[2]
	if p.strip_diacrits(wrd1) == p.strip_diacrits(wrd2) then
		return true
	else
		return nil
	end
end


return p