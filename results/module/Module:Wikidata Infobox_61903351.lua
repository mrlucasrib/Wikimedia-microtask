
local p = {}
local WikidataIB = require("Module:WikidataIB")

-- Code from 'Module:No globals'
local mt = getmetatable(_G) or {}
function mt.__index (t, k)
	if k ~= 'arg' then
		error('Tried to read nil global ' .. tostring(k), 2)
	end
	return nil
end
function mt.__newindex(t, k, v)
	if k ~= 'arg' then
		error('Tried to write global ' .. tostring(k), 2)
	end
	rawset(t, k, v)
end
setmetatable(_G, mt)
-- End of code from 'Module:No globals'

function p.getMID()
	return "M" .. mw.title.getCurrentTitle().id
end
function p.getFilename()
	return mw.title.getCurrentTitle().nsText .. ':' .. mw.title.getCurrentTitle().text
end

function p.getP180vals(frame)
	local mid = frame.args[1]
	local prefix = frame.args[2] or ''
	local postfix = frame.args[3] or ' '
	local text = ''
	local tablevals = mw.wikibase.getBestStatements( mid, 'P180')
	for i, v in ipairs(tablevals) do
		text = text .. prefix .. v.mainsnak.datavalue.value.id .. postfix
	end
	return text
end

function p.getCombinedWikidataTemplates(frame)
	local qid = frame.args[1] or ''
	local outputcode = ''
	if mw.text.trim(qid or '') ~= '' then
		local tablevals = mw.wikibase.getAllStatements( qid, 'P971')
		for i, v in ipairs(tablevals) do
			outputcode = outputcode .. frame:expandTemplate{ title = 'Wikidata Infobox/core', args = { qid=v.mainsnak.datavalue.value.id, embed='Yes', conf_authoritycontrol='yes' } }
		end
	end
	return outputcode
end

function p.ifThenShow(frame)
	if mw.text.trim(frame.args[1] or '') ~= '' then
		return (frame.args[3] or '') .. (frame.args[1] or '') .. (frame.args[4] or '')
	else
		return (frame.args[2] or '')
	end
end

--  Given an input area, return a map zoom level to use with mw:Extension:Kartographer in {{Wikidata Infobox}}. Defaults to mapzoom=15. 
function p.autoMapZoom(frame)
	local size = tonumber(frame.args[1]) or 0
	local LUT = { 5000000, 1000000, 100000, 50000, 10000, 2000, 150, 50, 19, 14, 5, 1, 0.5 } 
	for zoom, scale in ipairs(LUT) do
		if size > scale then
			return zoom+1
		end
	end
	return 15
end

function p.formatLine(frame)
	local part2 = mw.text.trim(frame.args[2] or '')
	local returnstr = ''
	if part2 ~= '' then
		returnstr = '<tr '
		if (frame.args.mobile or 'n') == 'y' then
			returnstr = returnstr .. 'class="wdinfo_nomobile"'
		end
		local newframe = {}
		newframe.args = {}
		newframe.args.qid = frame.args[1]
		returnstr = returnstr .. '><th class="wikidatainfobox-lcell">' .. mw.getContentLanguage():ucfirst(WikidataIB.getLabel(newframe))
		returnstr = returnstr .. '</th><td '
		if (frame.args.wrap or 'n') == 'y' then
			returnstr = returnstr .. 'style="white-space: nowrap"'
		end
		returnstr = returnstr .. '>' .. part2 .. '</td></tr>'
	end
	return returnstr
end

function p.hasValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- baseLang is a utility function that returns the base language in use
-- so for example, both English (en) and British English (en-gb) return 'en'
-- from https://commons.wikimedia.org/wiki/Module:Wikidata2
function p.baseLang(frame)
	local txtlang = frame:callParserFunction( "int", "lang" ) or ""
	-- This deals with specific exceptions: be-tarask -> be_x_old
	if txtlang == "be-tarask" then
		return "be_x_old"
	end
	local pos = txtlang:find("-")
	local ret = ""
	if pos then
		ret = txtlang:sub(1, pos-1)
	else
		ret = txtlang
	end
	return ret
end

function p.langDirection(frame)
	local lang = mw.text.trim(frame.args[1] or '') 
	if (not mw.language.isSupportedLanguage(lang)) then 
		lang = frame:callParserFunction( "int", "lang" ) -- get user's chosen language
	end
	return mw.getLanguage(lang):getDir()
end

--[[
convertChar returns the non-diacritic version of the supplied character.
stripDiacrits replaces words with diacritical characters with their non-diacritic equivalent.
strip_diacrits is available for export to other modules.
stringIsLike tests two words, returning true if they only differ in diacritics, false otherwise.
stringIs_like is available for export to other modules.
--]]

local function characterMap()
	-- table with characters with diacrits and their equivalent basic latin characters
	local charMap_from, charMap_to
	charMap_from =  'ÁÀÂÄǍĂĀÃÅĄƏĆĊĈČÇĎĐḌÐÉÈĖÊËĚĔĒẼĘẸĠĜĞĢĤĦḤİÍÌÎÏǏĬĪĨĮỊĴĶĹĿĽĻŁḶḸṂŃŇÑŅṆŊÓÒÔÖǑŎŌÕǪỌŐØŔŘŖṚṜŚŜŠŞȘṢŤŢȚṬÚÙÛÜǓŬŪŨŮŲỤŰǗǛǙǕŴÝŶŸỸȲŹŻŽ'..
					'áàâäǎăāãåąəćċĉčçďđḍðéèėêëěĕēẽęẹġĝğģĥħḥıíìîïǐĭīĩįịĵķĺŀľļłḷḹṃńňñņṇŋóòôöǒŏōõǫọőøŕřŗṛṝśŝšşșṣťţțṭúùûüǔŭūũůųụűǘǜǚǖŵýŷÿỹȳźżž'
	charMap_to   =  'AAAAAAAAAAACCCCCDDDDEEEEEEEEEEEGGGGHHHIIIIIIIIIIIJKLLLLLLLMNNNNNNOOOOOOOOOOOORRRRRSSSSSSTTTTUUUUUUUUUUUUUUUUWYYYYYZZZ'..
					'aaaaaaaaaaacccccddddeeeeeeeeeeegggghhhiiiiiiiiiiijklllllllmnnnnnnoooooooooooorrrrrssssssttttuuuuuuuuuuuuuuuuwyyyyyzzz'
	local charMap = {}
	for i = 1,mw.ustring.len(charMap_from) do
		charMap[mw.ustring.sub(charMap_from, i, i)] = mw.ustring.sub(charMap_to, i, i)
	end
	charMap['ß'] = 'ss'
	return charMap
end

function p.convertChar(frame)
	local ch = frame.args.char or mw.text.trim(frame.args[1]) or ""
	local charMap = characterMap()
	return charMap[ch] or ch
end

function p.strip_diacrits(wrd)
	if wrd then 
		local charMap = characterMap()
		wrd = string.gsub(wrd, "[^\128-\191][\128-\191]*", charMap )
	end
	return wrd
end

function p.stripDiacrits(frame)
	return p.strip_diacrits(frame.args.word or mw.text.trim(frame.args[1]))
end

function p.stringIs_like(wrd1, wrd2)
	return p.strip_diacrits(wrd1) == p.strip_diacrits(wrd2)
end

function p.stringIsLike(frame)
	local wrd1 = frame.args.word1 or frame.args[1]
	local wrd2 = frame.args.word2 or frame.args[2]
	if p.strip_diacrits(wrd1) == p.strip_diacrits(wrd2) then
		return true
	else
		return nil
	end
end

function p.expandhiero(frame, hiero)
	-- added by Jura1
	-- for string values in Wikihiero syntax
	-- inline recommended by https://meta.wikimedia.org/wiki/Help_talk:WikiHiero_syntax#Unwanted_newlines https://en.wikipedia.org/wiki/Help:WikiHiero_syntax
	-- maybe not needed in all contexts
	return 	frame:preprocess('<div style="text-align:center;display:inline"> <hiero> ' .. hiero .. ' </hiero> </div>')
end

local function format2rowline(cell1, cell2)
	-- added by Jura1
	local tr = ""
	tr = '<tr><th class="wikidatainfobox-lcell" style="text-align: left; vertical-align: text-top;" colspan="2">' .. cell1 .. '</th></tr>'
	tr = tr .. '<tr><td valign="top" colspan="2">' .. cell2 .. '</td></tr>' 
	return tr 							
end

local function format1rowline(trqid, cell1, cell2)
	-- added by Jura1
	local tr = ""
	tr = '<tr id="' .. trqid .. '"><th class="wikidatainfobox-lcell" style="vertical-align: top">' .. cell1 .. '</th>'
    tr = tr .. '<td valign="top" style="vertical-align: top">' .. cell2 .. '</td></tr>'							
	return tr 							
end

function p.hieroP7383(frame)
-- added by Jura1
-- expand P7383 value in <hiero></hiero> tags	
	local qid = mw.text.trim(frame.args.qid or "")
	local rows = ""
	local checkentry = mw.wikibase.isValidEntityId(qid)
	if not checkentry then
		return ''
	end
	local entity = mw.wikibase.getEntityObject(qid)
	if not entity then
		return ''
	end
	local mylang = frame:preprocess('{{int:lang}}')
	if entity.claims and entity.claims.P7383 then
			for _, v in ipairs(entity.claims.P7383) do
				local idv = v.mainsnak.datavalue.value 
				if v.qualifiers and v.qualifiers.P3831 then
					for _, w in ipairs(v.qualifiers.P3831) do
						if w.snaktype == "value" then
							local qualid = w.datavalue.value["id"]
							local encod = mw.wikibase.getEntityObject(qualid)
                   			rows = rows .. format2rowline(encod:getLabel(mylang), p.expandhiero(frame, idv)) 
						end
					end
				else 
					rows = rows .. format2rowline("Name", p.expandhiero(frame, idv)) 
				end
			end
	end	
	return 	rows	
end

function p.urn(frame)
	local qid = mw.text.trim(frame.args.qid or "")
	local mylang = frame:preprocess('{{int:lang}}')
	local entity = mw.wikibase.getEntityObject(qid)
	if not entity then
		return ''
	end
	local urn = ""
	return urn
	--- return "<div style='display:none'>" .. urn .. "</span>"
end

function p.numberInfo(frame)
		-- from additions by Jura1
		-- tests at  Category:987_(number)   Category:8_(number)
		local qid = mw.text.trim(frame.args.qid or "")
		local mylang = frame:preprocess('{{int:lang}}')
		local rows = ""
		local checkentry = mw.wikibase.isValidEntityId(qid)
		if not checkentry then
			return ''
		end
		local entity = mw.wikibase.getEntityObject(qid)
		if not entity then
			return ''
		end
		if entity.claims.P487 then
			for _, v in ipairs(entity.claims.P487) do
				local idv = v.mainsnak.datavalue.value 
				if v.qualifiers and v.qualifiers.P3831 then
					for _, w in ipairs(v.qualifiers.P3831) do
						if w.snaktype == "value" then
							local qualid = w.datavalue.value["id"]
							local encod = mw.wikibase.getEntityObject(qualid)
							rows = rows .. format1rowline(qualid,  encod:getLabel(mylang) , idv)
						end
					end
				end
			end
		end
		-- use code/encoding and render as encoding/code
		if entity.claims.P3295 then
			for _, v in ipairs(entity.claims.P3295) do
				local idv = v.mainsnak.datavalue.value
				local commonsc = ""
				if v.qualifiers and v.qualifiers.P805 then
					for _, t in ipairs(v.qualifiers.P805) do
						if t.snaktype == "value" then
							local subjectframe = {}
							subjectframe.args = {}
							subjectframe.args.qid = t.datavalue.value["id"]
							commonsc = WikidataIB.getCommonsLink( subjectframe )
						end
					end
				end
				if v.qualifiers and v.qualifiers.P3294 then
					for _, w in ipairs(v.qualifiers.P3294) do
						if w.snaktype == "value" then
							local qualid = w.datavalue.value["id"]
							local encod = mw.wikibase.getEntityObject(qualid)
							local encodeframe = {}
							local encodecommons = ""
							encodeframe.args = {}
							encodeframe.args.qid = qualid
							encodecommons = WikidataIB.getCommonsLink( encodeframe ) or ""
                   			if encodecommons == "" then
                   				encodecommons = encod:getLabel(mylang)
                   			else 
                   				encodecommons = "[[:" .. encodecommons .. "|" .. encod:getLabel(mylang) .. "]]"
                   			end

							if qualid == "Q68101340" then
								idv = p.expandhiero(frame, idv)
							elseif commonsc ~= "" then
								idv = "[[:" .. commonsc .. "|" .. idv .. "]]"
							end
							rows = rows .. format1rowline(qualid,  encodecommons , idv)
						end
					end
				end
			end
		end
		if entity.claims.P7415 then
			for _, v in ipairs(entity.claims.P7415) do
				local idv = v.mainsnak.datavalue.value
				if v.qualifiers and v.qualifiers.P3294 then
					for _, w in ipairs(v.qualifiers.P3294) do
						if w.snaktype == "value" then
							local qualid = w.datavalue.value["id"]
							local encod = mw.wikibase.getEntityObject(qualid)
							rows = rows .. format1rowline(qualid,  encod:getLabel(mylang) , '[[File:' .. idv .. '|none|35px|'.. entity:getLabel(mylang) .. ' (' .. encod:getLabel(mylang) ..')]]')
						end
					end
				end
			end
		end		
		return rows
		-- return '<table class="wikitable"><tr><th>Encoding </th><td>code</td></tr>' .. rows ..'</table>'
	end


return p