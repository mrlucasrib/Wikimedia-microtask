require('Module:No globals')

local p = {}

-- articles in which traditional Chinese preceeds simplified Chinese
local t1st = {
	["228 Incident"] = true,
	["Chinese calendar"] = true,
	["Lippo Centre, Hong Kong"] = true,
	["Republic of China"] = true,
	["Republic of China at the 1924 Summer Olympics"] = true,
	["Taiwan"] = true,
	["Taiwan (island)"] = true,
	["Taiwan Province"] = true,
	["Wei Boyang"] = true,
}

-- the labels for each part 
local labels = {
	["c"] = "Chinese",
	["s"] = "simplified Chinese",
	["t"] = "traditional Chinese",
	["p"] = "pinyin",
	["tp"] = "Tongyong Pinyin",
	["w"] = "Wade–Giles",
	["j"] = "Jyutping",
	["cy"] = "Cantonese Yale",
	["sl"] = "Sidney Lau",
	["poj"] = "Pe̍h-ōe-jī",
	["zhu"] = "Zhuyin Fuhao",
	["l"] = "lit.",
}

-- article titles for wikilinks for each part
local wlinks = {
	["c"] = "Chinese language",
	["s"] = "simplified Chinese characters",
	["t"] = "traditional Chinese characters",
	["p"] = "pinyin",
	["tp"] = "Tongyong Pinyin",
	["w"] = "Wade–Giles",
	["j"] = "Jyutping",
	["cy"] = "Yale romanization of Cantonese",
	["sl"] = "Sidney Lau romanisation",
	["poj"] = "Pe̍h-ōe-jī",
	["zhu"] = "Bopomofo",
	["l"] = "Literal translation",
}

-- for those parts which are to be treated as languages their ISO code
local ISOlang = {
	["c"] = "zh",
	["t"] = "zh-Hant",
	["s"] = "zh-Hans",
	["p"] = "zh-Latn-pinyin",
	["tp"] = "zh-Latn",
	["w"] = "zh-Latn-wadegile",
	["j"] = "yue-Latn-jyutping",
	["cy"] = "yue-Latn",
	["sl"] = "yue-Latn",
	["poj"] = "nan-Latn",
	["zhu"] = "zh-Bopo",
}

local italic = {
	["p"] = true,
	["tp"] = true,
	["w"] = true,
	["j"] = true,
	["cy"] = true,
	["sl"] = true,
	["poj"] = true,
}

local superscript = {
	["w"] = true,
	["sl"] = true,
}
-- Categories for different kinds of Chinese text
local cats = {
	["c"] = "[[Category:Articles containing Chinese-language text]]",
	["s"] = "[[Category:Articles containing simplified Chinese-language text]]",
	["t"] = "[[Category:Articles containing traditional Chinese-language text]]",
}

function p.Zh(frame)
	-- load arguments module to simplify handling of args
	local getArgs = require('Module:Arguments').getArgs
	
	local args = getArgs(frame)
	return p._Zh(args)
end
	
function p._Zh(args)
	local uselinks = not (args["links"] == "no") -- whether to add links
	local uselabels = not (args["labels"] == "no") -- whether to have labels
	local capfirst = args["scase"] ~= nil
 
	local t1 = false -- whether traditional Chinese characters go first
	local j1 = false -- whether Cantonese Romanisations go first
	local testChar
	if (args["first"]) then
	 	 for testChar in mw.ustring.gmatch(args["first"], "%a+") do
			if (testChar == "t") then
				t1 = true
			 end
			if (testChar == "j") then
				j1 = true
			 end
		end
	end
	if (t1 == false) then
		local title = mw.title.getCurrentTitle()
		t1 = t1st[title.text] == true
	end

	-- based on setting/preference specify order
	local orderlist = {"c", "s", "t", "p", "tp", "w", "j", "cy", "sl", "poj", "zhu", "l"}
	if (t1) then
		orderlist[2] = "t"
		orderlist[3] = "s"
	end
	if (j1) then
		orderlist[4] = "j"
		orderlist[5] = "cy"
		orderlist[6] = "sl"
		orderlist[7] = "p"
		orderlist[8] = "tp"
		orderlist[9] = "w"
	end
	
	-- rename rules. Rules to change parameters and labels based on other parameters
	if args["hp"] then
		-- hp an alias for p ([hanyu] pinyin)
		args["p"] = args["hp"]
	end
	if args["tp"] then
		-- if also Tongyu pinyin use full name for Hanyu pinyin
		labels["p"] = "Hanyu Pinyin"
	end
	
	if (args["s"] and args["s"] == args["t"]) then
		-- Treat simplified + traditional as Chinese if they're the same
		args["c"] = args["s"]
		args["s"] = nil
		args["t"] = nil
	elseif (not (args["s"] and args["t"])) then
		-- use short label if only one of simplified and traditional
		labels["s"] = labels["c"]
		labels["t"] = labels["c"]
	end

	local body = "" -- the output string
	local params -- for creating HTML spans
	local label -- the label, i.e. the bit preceeding the supplied text
	local val -- the supplied text
	
	-- go through all possible fields in loop, adding them to the output
	for i, part in ipairs(orderlist) do
		if (args[part]) then
			-- build label
			label = ""
			if (uselabels) then
				label = labels[part]
				if (capfirst) then
					label = mw.language.getContentLanguage():ucfirst(label)
					capfirst = false
				end
				if (uselinks) then
					label = "[[" .. wlinks[part] .. "|" .. label .. "]]"
				end
				label = label .. "&#58; "
			end
			-- build value
			val = args[part]
			if (cats[part]) and mw.title.getCurrentTitle().namespace == 0 then
				-- if has associated category AND current page in article namespace, add category
				val = cats[part] .. val
			end
			if (ISOlang[part]) then
				-- add span for language if needed
				params = {["lang"] = ISOlang[part], ["xml:lang"] = ISOlang[part]}
				val = mw.text.tag({name="span",attrs=params, content=val})
			elseif (part == "l") then
				-- put literals in quotes
				val = "'" .. val .. "'"
			end
			if (italic[part]) then
				-- italicise
				val = "<i>" .. val .. "</i>"
			end
			if string.match(val, "</?sup>") then val = val.."[[Category:Pages using template Zh with sup tags]]" end
			if (superscript[part]) then
				-- superscript
				val = val:gsub("(%d)", "<sup>%1</sup>"):gsub("(%d)</sup>%*<sup>(%d)", "%1*%2"):gsub("<sup><sup>([%d%*]+)</sup></sup>", "<sup>%1</sup>")
			end
			-- add both to body
			body = body .. label .. val .. "; "
		end
	end
	
	if (body > "") then -- check for empty string
		return string.sub(body, 1, -3) -- chop off final semicolon and space
	else --no named parameters; see if there's a first parameter, ignoring its name
		if (args[1]) then
			-- if there is treat it as Chinese
			label = ""
			if (uselabels) then
				label = labels["c"]
				if (uselinks) then
					label = "[[" .. wlinks["c"] .. "|" .. label .. "]]"
				end
				label = label .. "&#58; "
			end
			-- default to show links and labels as no options given
			if mw.title.getCurrentTitle().namespace == 0 then
				-- if current page in article namespace
				val = cats["c"] .. args[1]
			else
				val = args[1]
			end
			params = {["lang"] = ISOlang["c"], ["xml:lang"] = ISOlang["c"]}
			val = mw.text.tag({name="span",attrs=params, content=val})
			return label .. val
		end
		return ""
	end
end

return p