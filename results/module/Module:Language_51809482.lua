require('Module:No globals')
local m_data = mw.loadData("Module:Language/data")
local langData = m_data.languages or m_data

local p = {}

local function ifNotEmpty(value)
	if value == "" then
		return nil
	else
		return value
	end
end

local function makeLinkedName(languageCode)
	local data = langData[languageCode]
	local article = data["article"]
	local name = data["Wikipedia_name"] or data["name"]
	return "[[" .. article .. "|" .. name .. "]]:&nbsp;"
end

local function makeEntryName(word, languageCode)
	local data = langData[languageCode]
	local ugsub = mw.ustring.gsub
	word = tostring(word)
	if word == nil then
		error("The function makeEntryName requires a string argument")
	elseif word == "" then
		return ""
	else
		-- Remove bold and italics, so that words that contain bolding or emphasis can be linked without piping.
		word = word:gsub("\'\'\'", "")
		word = word:gsub("\'\'", "")
		if data == nil then
			return word
		else
			local replacements = data and data["replacements"]
			if replacements == nil then
				return word
			else
				-- Decompose so that the diacritics of characters such
				-- as á can be removed in one go.
				-- No need to compose at the end, because the MediaWiki software
				-- will handle that.
				if replacements.decompose then
					word = mw.ustring.toNFD(word)
					for i, from in ipairs(replacements.from) do
						word = ugsub(
							word,
							from,
							replacements.to and replacements.to[i] or "")
					end
				else
					for regex, replacement in pairs(replacements) do
						word = ugsub(word, regex, replacement)
					end
				end
				return word
			end
		end
	end
end

p.makeEntryName = makeEntryName

local function fixScriptCode(firstLetter, threeLetters)
	return string.upper(firstLetter) .. string.lower(threeLetters)
end

local function getCodes(codes, text)
	local languageCode, scriptCode, invalidCode
	local errorText
	if codes == nil or codes == "" then
		errorText = 'no language or script code provided'
	elseif codes:find("^%a%a%a?$") or codes:find("^%a%a%a?%-%a%a%a%a$") then
		-- A three- or two-letter lowercase sequence at beginning of first parameter
		languageCode =
			codes:find("^%a%a%a?") and (
				codes:match("^(%l%l%l?)")
				or codes:match("^(%a%a%a?)")
					:gsub("(%a%a%a?)", string.lower, 1)
			)
		-- One uppercase and three lowercase letters at the end of the first parameter
		scriptCode =
			codes:find("%a%a%a%a$") and (
				codes:match("(%u%l%l%l)$")
				or gsub(
					codes:match("(%a%a%a%a)$"),
					"(%a)(%a%a%a)",
					fixScriptCode,
					1
				)
			)
	elseif codes:find("^%a%a%a?%-%a%a%a?$")
	or codes:find("^%a%a%a%-%a%a%a%-%a%a%a$") then
		languageCode = codes
	
	-- Private-use subtag: x followed by one or more sequences of 1-8 lowercase
	-- letters separated by hyphens. This only allows for one sequence, as it is
	-- needed for proto-languages such as ine-x-proto (Proto-Indo-European).
	elseif codes:find("^%a%a%a?%-x%-%a%a?%a?%a?%a?%a?%a?%a?$") then
		languageCode, scriptCode =
			codes:match("^(%a%a%a%-x%-%a%a?%a?%a?%a?%a?%a?%a?)%-?(.*)$")
		if not languageCode then
			errorText = '<code>'..codes..'</code> is not a valid language or script code.'
		elseif scriptCode ~= "" and not scriptCode:find("%a%a%a%a") then
			errorText = '<code>'..scriptCode..'</code> is not a valid script code.'
		else
			scriptCode = scriptCode:gsub(
				"(%a)(%a%a%a)",
				fixScriptCode,
				1
			)
		end
	elseif codes:find("^%a%a%a?") then
		languageCode, invalidCode = codes:match("^(%a%a%a?)%-?(.*)")
		languageCode = string.lower(languageCode)
		errorText = '<code>'..invalidCode..'</code> is not a valid script code.'
	elseif codes:find("%-?%a%a%a%a$") then
		invalidCode, scriptCode = codes:match("(.*)%-?(%a%a%a%a)$")
		scriptCode = gsub(
			scriptCode,
			"(%a)(%a%a%a)",
			fixScriptCode
		)
		errorText = '<code>'..invalidCode..'</code> is not a valid language code.'
	else
		errorText = '<code>'..codes..'</code> is not a valid language or script code.'
	end
	if not scriptCode or scriptCode == "" then
		scriptCode = require("Module:Unicode data").is_Latin(text) and "Latn" or "unknown"
	end
	if errorText then
		errorText = ' <span style="font-size: smaller">[' .. errorText .. ']</span>'
	else
		errorText = ""
	end
	languageCode = m_data.redirects[languageCode] or languageCode
	return languageCode, scriptCode, errorText
end

local function tag(text, languageCode, script, italics)
	local data = langData[languageCode]
	-- Use Wikipedia code if it has been given: for instance,
	-- Proto-Indo-European has the Wiktionary code "ine-pro" but the Wikipedia
	-- code "ine-x-proto".
	languageCode = data and data.Wikipedia_code or languageCode
	
	local italicize = script == "Latn" and italics
	
	if not text then text = "[text?]" end
	
	local textDirectionMarkers = { "", "", "" }
	if data and data["direction"] == "rtl" then
		textDirectionMarkers = { ' dir="rtl"', '&rlm;', '&lrm;' }
	end
	
	local out = { textDirectionMarkers[2] }
	if italicize then
		table.insert(out, "<i lang=\"" .. languageCode .. "\" xml:lang=\"" .. languageCode  .. "\"" .. textDirectionMarkers[1] .. ">" .. text .. "</i>")
	else
		table.insert(out, "<span lang=\"" .. languageCode .. "\" xml:lang=\"" .. languageCode .. "\"" .. textDirectionMarkers[1] .. ">" .. text .. "</span>")
	end
	table.insert(out, textDirectionMarkers[3])
	
	return table.concat(out)
end



function p.lang(frame)
	local parent = frame:getParent()
	local args = parent.args[1] and parent.args or frame.args
	
	local codes = args[1] and mw.text.trim(args[1])
	local text = args[2] or error("Provide text in the second parameter")
	
	local languageCode, scriptCode, errorText = getCodes(codes, text)
	
	local italics = args.italics or args.i or args.italic
	italics = not (italics == "n" or italics == "-" or italics == "no")
	
	return tag(text, languageCode, scriptCode, italics) .. errorText
end

local function linkToWiktionary(entry, linkText, languageCode)
	local data = langData[languageCode]
	local name
	if languageCode then
		if data and data.name then
			name = data.name
		else
			-- On other languages' wikis, use mw.getContentLanguage():getCode(),
			-- or replace 'en' with that wiki's language code.
			name = mw.language.fetchLanguageName(languageCode, 'en')
			if name == "" then
				error("Name for the language code " .. ("%q"):format(languageCode or nil)
					.. " could not be retrieved with mw.language.fetchLanguageName, "
					.. "so it should be added to [[Module:Language/data]]")
			end
		end
		if entry:sub(1, 1) == "*" then
			if name ~= "" then
				entry = "Reconstruction:" .. name .. "/" .. entry:sub(2)
			else
				error("Language name is empty")
			end
		elseif data and data.type == "reconstructed" then
			mw.log("Reconstructed language without asterisk:", languageCode, name, entry)
			local frame = mw.getCurrentFrame()
			-- Track reconstructed entries with no asterisk by transcluding
			-- a nonexistent template. This technique is used in Wiktionary:
			-- see [[wikt:Module:debug]].
			-- [[Special:WhatLinksHere/tracking/wikt-lang/reconstructed with no asterisk]]
			pcall(frame.expandTemplate, frame,
				{ title = 'tracking/wikt-lang/reconstructed with no asterisk' })
			if name ~= "" then
				entry = "Reconstruction:" .. name .. "/" .. entry
			else
				error("Language name is empty")
			end
		elseif data and data.type == "appendix" then
			if name ~= "" then
				entry = "Appendix:" .. name .. "/" .. entry
			else
				error("Language name is empty")
			end
		end
		if entry and linkText then
			return "[[wikt:" .. entry .. "#" .. name .. "|" .. linkText .. "]]"
		else
			error("linkToWiktionary needs a Wiktionary entry or link text, or both")
		end
	else
		return "[[wikt:" .. entry .. "|" .. linkText .. "]]"
	end
end

function p.wiktlang(frame)
	local parent = frame:getParent()
	local args = parent.args[1] and parent.args or frame.args
	
	local codes = args[1] and mw.text.trim(args[1])
	local word1 = ifNotEmpty(args[2])
	local word2 = ifNotEmpty(args[3])
	
	if not args[2] then
		error("Parameter 2 is required")
	end
	
	local languageCode, scriptCode, errorText = getCodes(codes, word2 or word1)
	
	local italics = args.italics or args.i
	italics = not (italics == "n" or italics == "-")
	
	local entry, linkText
	if word2 and word1 then
		entry = makeEntryName(word1, languageCode)
		linkText = word2
	elseif word1 then
		entry = makeEntryName(word1, languageCode)
		linkText = word1
	end
	
	local out
	if languageCode and entry and linkText then
		out = tag(linkToWiktionary(entry, linkText, languageCode), languageCode, scriptCode, italics)
	elseif entry and linkText then
		out = linkToWiktionary(entry, linkText)
	else
		out = '<span style="font-size: smaller;">[text?]</span>'
	end
	
	if out and errorText then
		return out .. errorText
	else
		return errorText or error("The function wiktlang generated nothing")
	end
end

function p.wikt(frame)
	local parent = frame:getParent()
	local args = parent.args[1] and parent.args or frame.args
	
	local codes = args[1] and mw.text.trim(args[1])
	local word1 = ifNotEmpty(args[2])
	local word2 = ifNotEmpty(args[3])
	
	if not word1 then
		error("Provide a word in parameter 2.")
	end
	
	local languageCode, scriptCode, errorText = getCodes(codes, word1)
	
	local entry, linkText
	if word2 and word1 then
		entry = makeEntryName(word1, languageCode)
		linkText = word2
	elseif word1 then
		entry = makeEntryName(word1, languageCode)
		linkText = word1
	end
	
	local out
	if languageCode and entry and linkText then
		out = linkToWiktionary(entry, linkText, languageCode) 
	elseif entry and linkText then
		out = linkToWiktionary(entry, linkText)
	else
		out = '<span style="font-size: smaller;">[text?]</span>'
	end
	
	if out and errorText then
		return out and out .. errorText
	else
		return errorText or error("The function wikt generated nothing")
	end
end

return p