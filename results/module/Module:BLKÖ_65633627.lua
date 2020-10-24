local objid = {
 [1] = 12537,
 [2] = 11806,
 [3] = 11807,
 [4] = 11808,
 [5] = 11809,
 [6] = 11804,
 [7] = 11810,
 [8] = 11811,
 [9] = 11812,
[10] = 11813,
[11] = 11814,
[12] = 11815,
[13] = 11816,
[14] = 11636,
[15] = 11770,
[16] = 11769,
[17] = 11639,
[18] = 11640,
[19] = 11771,
[20] = 11772,
[21] = 11773,
[22] = 11774,
[23] = 12538,
[24] = 12539,
[25] = 12904,
[26] = 11775,
[27] = 11776,
[28] = 11777,
[29] = 11778,
[30] = 11779,
[31] = 12540,
[32] = 11780,
[33] = 11781,
[34] = 11782,
[35] = 11783,
[36] = 11784,
[37] = 11785,
[38] = 11786,
[39] = 11805,
[40] = 11641,
[41] = 11642,
[42] = 11643,
[43] = 11644,
[44] = 11646,
[45] = 11664,
[46] = 11665,
[47] = 11668,
[48] = 11707,
[49] = 11708,
[50] = 11709,
[51] = 11710,
[52] = 11711,
[53] = 11712,
[54] = 11713,
[55] = 11714,
[56] = 11715,
[57] = 12541,
[58] = 12542,
[59] = 12543,
[60] = 12544
}

local page = {
[1] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	VII = 7,
	VIII = 8,
	IX = 9,
	X = 10,
	XI = 11,
	XII = 12,
	XIII = 13,
	XIV = 14,
	default = function (s) return s + 14 end
},
[3] = {
	III = 3,
	IV = 4,
	default = function (s) return s + 4 end
},
[6] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	VII = 7,
	VIII = 8,
	default = function (s) return s + 8 end
},
[7] = {
	III = 4,
	IV = 5,
	default = function (s) return s + 5 end
},
[9] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	T1 = 359,
	default = function (s)
		if s <= 171 then return s + 8 end
		if s <= 348 then return s + 10 end -- Duplikate der Seiten 170–171 werden übersprungen
		return s + 11 end
},
[11] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	T1 = 19,
	T2 = 92,
	T3 = 137,
	T4 = 166,
	T5 = 241,
	T6 = 242,
	T7 = 317,
	T8 = 318,
	default = function (s)
		if s <=  12 then return s + 6 end
		if s <=  84 then return s + 7 end
		if s <= 128 then return s + 8 end
		if s <= 156 then return s + 9 end
		if s <= 230 then return s + 10 end
		if s <= 304 then return s + 12 end
		return s + 14 end
},
[12] = {
	T1 = 225,
	T2 = 368,
	T3 = 369,
	T4 = 402,
	T5 = 403,
	T6 = 404,
	T7 = 405,
	default = function (s)
		if s <= 222 then return s + 2 end
		if s <= 364 then return s + 3 end
		if s <= 396 then return s + 5 end
		return s + 9 end
},
[13] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	VII = 7,
	VIII = 8,
	IX = 9,
	X = 10,
	XI = 11,
	XII = 12,
	XIII = 13,
	XIV = 14,
	XV = 15,
	XVI = 16,
	XVII = 17,
	XVIII = 18,
	XIX = 19,
	XX = 20,
	XXI = 21,
	XXII = 22,
	T1 = 157,
	T2 = 336,
	T3 = 343,
	T4 = 354,
	default = function (s)
		if s <= 134 then return s + 22 end
		if s <= 312 then return s + 23 end
		if s <= 318 then return s + 24 end
		if s <= 328 then return s + 25 end
		return s + 26 end
},
[14] = {
	III = 3,
	IV = 4,
	T1 = 51,
	T2 = 52,
	T3 = 53,
	T4 = 54,
	T5 = 249,
	T6 = 250,
	default = function (s)
		if s <=  46 then return s + 4 end
		if s <= 240 then return s + 8 end
		return s + 10 end
},
[15] = {
	T1 = 122,
	T2 = 389,
	T3 = 390,
	default = function (s)
		if s <= 118 then return s + 3 end
		if s <= 384 then return s + 4 end
		return s + 6 end
},
[16] = {
	III = 4,
	IV = 5,
	T1 = 325,
	default = function (s)
		if s <= 320 then return s + 5 end
		return s + 6 end
},
[17] = {
	T1 = 251,
	default = function (s)
		if s <= 248 then return s + 2 end
		return s + 3 end
},
[18] = {
	III = 3,
	IV = 4,
	T1 = 69,
	T2 = 378,
	T3 = 403,
	T4 = 408,
	default = function (s)
		if s <=  64 then return s + 4 end
		if s <= 372 then return s + 5 end
		if s <= 396 then return s + 6 end
		if s <= 400 then return s + 7 end
		return s + 8 end
},
[19] = {
	III = 5,
	IV = 6,
	T1 = 118,
	T2 = 162,
	T3 = 451,
	T4 = 506,
	default = function (s)
		if s <= 112 then return s + 6 end
		if s <= 154 then return s + 7 end
		if s <= 442 then return s + 8 end
		if s <= 496 then return s + 9 end
		return s + 10 end
},
[20] = {
	T1 = 14, -- Nadasdy 1
	T2 = 15, -- Nadasdy 2
	T3 = 158, -- Neipperg
	default = function (s)
		if s <=  10 then return s + 3 end
		if s <= 152 then return s + 5 end
		return s + 6 end
},
[21] = {
	T1 = 88,
	T2 = 149,
	T3 = 210,
	T4 = 441,
	T5 = 486,
	default = function (s)
		if s <=  84 then return s + 3 end
		if s <= 144 then return s + 4 end
		if s <= 204 then return s + 5 end
		if s <= 434 then return s + 6 end
		if s <= 478 then return s + 7 end
		return s + 8 end
},
[22] = {
	III = 4,
	IV = 5,
	T1 = 10, -- Pergen
	default = function (s)
		if s <= 4 then return s + 5 end
		return s + 6 end
},
[23] = {
	T1 = 152,
	T2 = 187,
	default = function (s)
		if s <= 150 then return s + 1 end
		if s <= 184 then return s + 2 end
		return s + 3 end
},
[24] = {
	III = 5,
	IV = 6,
	V = 7,
	T1 = 21, -- Pronay
	T2 = 182, -- Raday
	default = function (s)
		if s <=  12 then return s + 8 end
		if s <= 172 then return s + 9 end
		return s + 10 end
},
[25] = {
	T1 = 243,
	T2 = 372,
	T3 = 397,
	default = function (s)
		if s <= 240 then return s + 2 end
		if s <= 368 then return s + 3 end
		if s <= 392 then return s + 4 end
		return s + 5 end
},
[26] = {
	III = 4,
	IV = 5,
	V = 6,
	VI = 7,
	T1 = 427, -- Rogendorf (S. 420)
	T2 = 428, -- Rohan (S. 421)
	default = function (s) return s + 7 end
},
[27] = {
	T1 = 8,
	T2 = 123,
	default = function (s)
		if s <=   4 then return s + 3 end
		if s <= 118 then return s + 4 end
		return s + 5 end
},
[28] = {
	III = 4,
	IV = 5,
	V = 6,
	T1 = 134,
	T2 = 291,
	default = function (s)
		if s <= 126 then return s + 7 end
		if s <= 282 then return s + 8 end
		return s + 9 end
},
[29] = {
	T1 = 72,
	T2 = 73,
	default = function (s)
		if s <= 68 then return s + 3 end
		return s + 5 end
},
[30] = {
	III = 4,
	IV = 5,
	T1 = 44, -- Schirndinger
	T2 = 107, -- Schlik 1
	T3 = 108, -- Schlik 2
	T4 = 203, -- Schmidburg
	default = function (s)
		if s <=  38 then return s + 5 end
		if s <= 100 then return s + 6 end
		if s <= 194 then return s + 8 end
		return s + 9 end
},
[31] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	VII = 7,
	VIII = 8,
	IX = 9,
	X = 10,
	XI = 11,
	XII = 12,
	XIII = 13,
	XIV = 14,
	XV = 15,
	XVI = 16,
	XVII = 17,
	XVIII = 18,
	XIX = 19,
	XX = 20,
	T1 = 157, -- Schönborn
	T2 = 290, -- Schrattenbach
	default = function (s)
		if s <= 136 then return s + 20 end
		if s <= 268 then return s + 21 end
		return s + 22 end
},
[32] = {
	default = function (s) return s + 3 end
},
[33] = {
	III = 4,
	T1 = 8, -- Schwarzenberg 1
	T2 = 9, -- Schwarzenberg 2
	default = function (s)
		if s <= 2 then return s + 5 end
		return s + 7 end
},
[34] = {
	T1 = 24,
	T2 = 133,
	T3 = 148,
	T4 = 159,
	T5 = 316,
	default = function (s)
		if s <=  20 then return s + 3 end
		if s <= 128 then return s + 4 end
		if s <= 142 then return s + 5 end
		if s <= 152 then return s + 6 end
		if s <= 308 then return s + 7 end
		return s + 8 end
},
[35] = {
	III = 4,
	IV = 5,
	T1 = 18,
	T2 = 91,
	T3 = 230,
	default = function (s)
	if s <=  12 then return s + 5 end
	if s <=  84 then return s + 6 end
	if s <= 222 then return s + 7 end
	return s + 8 end
},
[36] = {
	T1 = 92, -- Spaur 1
	T2 = 93, -- Spaur 2
	T3 = 94, -- Spaur 3
	T4 = 95, -- Spaur 4
	T5 = 158, -- Spiegelfeld
	T6 = 179, -- Spindler
	T7 = 212, -- Spleny
	T8 = 235, -- Spork
	T9 = 292, -- Sprinzenstein
	default = function (s)
		if s <=  88 then return s + 3 end
		if s <= 150 then return s + 7 end
		if s <= 170 then return s + 8 end
		if s <= 202 then return s + 9 end
		if s <= 224 then return s + 10 end
		if s <= 280 then return s + 11 end
		return s + 12 end
},
[37] = {
	T1 = 38, -- Stadion
	T3 = 165, -- Starhemberg (rechter Teil)
	T2 = 166, -- Starhemberg (linker Teil)
	T4 = 239, -- Starzenski
	default = function (s)
	if s <=  34 then return s + 3 end
	if s <= 160 then return s + 4 end
	if s <= 232 then return s + 6 end
	return s + 7 end
},
[38] = {
	T1 = 180, -- Stellwag
	T3 = 255, -- Sternbach
	T2 = 270, -- Sternberg 1
	T4 = 271, -- Sternberg 2
	T5 = 304, -- Sterneck
	default = function (s)
		if s <= 176 then return s + 3 end
		if s <= 250 then return s + 4 end
		if s <= 264 then return s + 5 end
		if s <= 296 then return s + 7 end
		return s + 8 end
},
[39] = {
	T1 = 56, -- Stillfried
	T2 = 71, -- Stockar
	default = function (s)
		if s <= 52 then return s + 3 end
		if s <= 66 then return s + 4 end
		return s + 5 end
,
},
[40] = {
	T1 = 119, -- Stubenberg 1
	T2 = 120, -- Stubenberg 2
	T3 = 121, -- Stubenberg Versippung 
	T4 = 304, -- Sulkowski
	default = function (s)
		if s <= 116 then return s + 2 end
		if s <= 298 then return s + 5 end
		return s + 6 end
},
[41] = {
	III = 3,
	IV = 4,
	V = 5,
	T1 = 29,
	T2 = 176,
	T3 = 237,
	default = function (s)
		if s <=  28 then return s + 6 end
		if s <= 168 then return s + 7 end
		if s <= 228 then return s + 8 end
		return s + 9 end
},
[42] = {
	III = 3,
	IV = 4,
	V = 5,
	T1 = 131, -- Szeptycky
	T2 = 268, -- Sztary
	T3 = 309, -- Taaffe
	default = function (s)
		if s <= 124 then return s + 6 end
		if s <= 260 then return s + 7 end
		if s <= 300 then return s + 8 end
		return s + 9 end
},
[43] = {
	T1 = 173,
	T2 = 234,
	T3 = 235,
	default = function (s)
		if s <= 170 then return s + 2 end
		if s <= 230 then return s + 3 end
		return s + 5 end
},
[44] = {
	T1 = 5,
	T2 = 42,
	T3 = 65,
	T4 = 66,
	T5 = 295,
	T6 = 296,
	default = function (s)
		if s <=   2 then return s + 2 end
		if s <=  38 then return s + 3 end
		if s <=  60 then return s + 4 end
		if s <= 288 then return s + 6 end
		return s + 8 end
},
[45] = {
	III = 3,
	IV = 4,
	V = 5,
	T1 = 23, -- Thun 1
	T2 = 24, -- Thun 2
	T3 = 77, -- Thurn-Taxis
	T4 = 108, -- Thurn-Valsassina 1
	T5 = 109, -- Thurn-Valsassina 
	T6 = 272, -- Török
	default = function (s)
	if s <=  16 then return s + 6 end
	if s <=  68 then return s + 8 end
	if s <=  98 then return s + 9 end
	if s <= 260 then return s + 11 end
	return s + 12 end
},
[46] = {
	T1 = 15, -- Toldolagi
	T2 = 172, -- Toscana
	T3 = 279, -- Trapp
	default = function (s)
		if s <=  12 then return s + 2 end
		if s <= 168 then return s + 3 end
		if s <= 274 then return s + 4 end
		return s + 5 end
},
[47] = {
	T1 = 17,
	T2 = 18,
	T3 = 51,
	T4 = 70,
	T5 = 257,
	default = function (s)
		if s <=  14 then return s + 2 end
		if s <=  46 then return s + 4 end
		if s <=  64 then return s + 5 end
		if s <= 250 then return s + 6 end
		return s + 7 end
},
[48] = {
	III = 3,
	IV = 4,
	V = 5,
	T1 = 51,
	T2 = 274,
	T3 = 275,
	default = function (s)
		if s <=  44 then return s + 6 end
		if s <= 266 then return s + 7 end
		return s + 9 end
},
[49] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	default = function (s) return s + 6 end
},
[50] = {
	T1 = 42,
	T2 = 59,
	default = function (s)
		if s <= 38 then return s + 3 end
		if s <= 54 then return s + 4 end
		return s + 5 end
},
[51] = {
T1 = 315,
default = function (s)
	if s <= 312 then return s + 2 end
	return s + 3 end
},
[52] = {
	T1 = 9,
	T2 = 78,
	T3 = 213,
	T4 = 214,
	T5 = 265,
	default = function (s)
		if s <=   8 then return s + 2 end
		if s <=  74 then return s + 3 end
		if s <= 208 then return s + 4 end
		if s <= 258 then return s + 6 end
		return s + 7 end
},
[53] = {
	T1 = 37,
	default = function (s)
		if s <= 34 then return s + 2 end
		return s + 3 end
},
[54] = {
	T1 = 181,
	T2 = 208,
	T3 = 225,
	T4 = 238,
	T5 = 255,
	T6 = 274,
	default = function (s)
		if s <= 178 then return s + 2 end
		if s <= 204 then return s + 3 end
		if s <= 220 then return s + 4 end
		if s <= 232 then return s + 5 end
		if s <= 248 then return s + 6 end
		if s <= 266 then return s + 7 end
		return s + 8 end
},
[55] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	T1 = 151, -- Wesselenyi
	T2 = 184, -- Westphalen
	default = function (s)
		if s <= 144 then return s + 6 end
		if s <= 176 then return s + 7 end
		if s <= 226 then return s + 8 end
		if s <= 250 then return s + 6 end
		if s <= 260 then return s + 7 end
		return s + 8 end
},
[56] = {
	T1 = 115, -- Wilczek
	T2 = 150, -- Wildenstein
	T3 = 233, -- Wickenburg
	_227 = 234,
	_228 = 235,
	default = function (s)
		if s <= 112 then return s + 2 end
		if s <= 146 then return s + 3 end
		if s <= 228 then return s + 4 end
		return s + 7 end -- falsch eingebundene Seiten 227/228 aus Band 55
},
[57] = {
	T1 = 43, -- Windisch-Grätz 1
	T2 = 44, -- Windisch-Grätz 2
	T3 = 213, -- Wodziczki
	default = function (s)
		if s <=  40 then return s + 2 end
		if s <= 208 then return s + 4 end
		return s + 5 end
},
[58] = {
	T1 = 57, -- Wolkenstein 1
	T2 = 58, -- Wolkenstein 2
	T3 = 157, -- Wratislaw 1
	T4 = 158, -- Wratislaw 2
	T5 = 181, -- Wrbna 1
	T6 = 182, -- Wrbna 2
	T7 = 246, -- Württemberg
	T8 = 300, -- Wurmbrand 1
	T9 = 301, -- Wurmbrand 2
	default = function (s)
		if s <=  54 then return s + 2 end
		if s <= 152 then return s + 4 end
		if s <= 174 then return s + 6 end
		if s <= 236 then return s + 8 end
		if s <= 290 then return s + 9 end
		return s + 11 end
},
[59] = {
	T1 = 123,
	T2 = 144,
	T3 = 229,
	default = function (s)
		if s <= 120 then return s + 2 end
		if s <= 140 then return s + 3 end
		if s <= 224 then return s + 4 end
		return s + 5 end
},
[60] = {
	III = 3,
	IV = 4,
	V = 5,
	VI = 6,
	VII = 7,
	VIII = 8,
	IX = 9,
	X = 10,
	XI = 11,
	XII = 12,
	XIII = 13,
	XIV = 14,
	XV = 15,
	XVI = 16,
	XVII = 17,
	XVIII = 18,
	XIX = 19,
	XX = 20,
	XXI = 21,
	XXII = 22,
	XXIII = 23,
	XXIV = 24,
	XXV = 25,
	XXVI = 26,
	XXVII = 27,
	XXVIII = 28,
	XXIX = 29,
	XXX = 30,
	XXXI = 31,
	XXXII = 32,
	XXXIII = 33,
	XXXIV = 34,
	XXXV = 35,
	XXXVI = 36,
	XXXVII = 37,
	XXXVIII = 38,
	XXXIX = 39,
	XXXX = 40,
	T1 = 45,
	T2 = 46,
	T3 = 117,
	T4 = 258,
	default = function (s)
		if s <=   4 then return s + 40 end
		if s <=  74 then return s + 42 end
		if s <= 214 then return s + 43 end
		return s + 44 end
},
default = {
	default = function (s) return s + 2 end
}
}

function getPage(band, seite)
	local vol = page[band] or page.default
	return vol[seite] or vol.default(tonumber(seite))
end

local p = {}

function p.getURL(frame)
	local band = tonumber(frame.args[1])
	local seite = frame.args[2]
	
	-- falsch eingebundene Seiten in Band 56
	if band == 55 and (seite == "227" or seite == "228") then
		band = 56
		seite = "_" .. seite
	end
	
	if seite ~= nil then
		return string.format("www.literature.at/viewer.alo?objid=%u&page=%u&scale=3.33&viewmode=fullscreen", objid[band], getPage(band, seite))
	else
		return string.format("www.literature.at/alo?objid=%u", objid[band])
	end
end

return p