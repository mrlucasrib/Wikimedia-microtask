--[[=========================================================================
Italicize a taxon name appropriately by invoking italicizeTaxonName.
The algorithm used is:
* If the name has italic markup at the start or the end, do nothing.
* Else
  * Remove (internal) italic markup.
  * If the name is made up of four words and the third word is a
    botanical connecting term, de-italicize the connecting term and add italic
    markup to the outside of the name.
  * Else if the name is made up of three words and the second word is a
    botanical connecting term or a variant of "cf.", de-italicize the
    connecting term and add italic markup to the outside of the name.
  * Else just add italic markup to the outside of the name.
 The module also:
 * Ensures that the hybrid symbol, ×, and parentheses are not italicized
 * Has an option to abbreviate all parts of taxon names other than the last
   to the first letter (e.g. "Pinus sylvestris var. sylvestris" becomes
   "P. s. var. sylvestris").
 * Has an option to wikilink the italicized name to the input name.
=============================================================================]]

local p = {}
local l = {} -- used to store purely local functions

--connecting terms in three part names (e.g. Pinus sylvestris var. sylvestris)
local cTerms3 = {
	--subsp.
    subspecies = "subsp.",
    ["subsp."] = "subsp.",
    subsp = "subsp.",
    ["ssp."] = "subsp.",
    ssp = "subsp.",
    --var.
    varietas = "var.",
    ["var."] = "var.",
    var = "var.",
    --subvar.
    subvarietas = "subvar.",
    ["subvar."] = "subvar.",
    subvar = "subvar.",
    --f.
    forma = "f.",
    ["f."] = "f.",
    f = "f.",
    --subf.
    subforma = "subf.",
    ["subf."] = "subf.",
    subf = "subf."
    }
--connecting terms in two part names (e.g. Pinus sect. Pinus)
local cTerms2 = {
	--subg.
    subgenus = "subg.",
    ["subgen."] = "subg.",
    ["subg."] = "subg.",
    subg = "subg.",
    --supersect.
    supersection = "supersect.",
    ["supersect."] = "supersect.",
    supersect = "supersect.",
    --sect.
    section = "sect.",
    ["sect."] = "sect.",
    sect = "sect.",
    --subsect.
    subsection = "subsect.",
    ["subsect."] = "subsect.",
    subsect = "subsect.",
    --ser.
    series = "ser.",
    ["ser."] = "ser.",
    ser = "ser.",
    --subser.
    subseries = "subser.",
    ["subser."] = "subser.",
    subser = "subser.",
    --cf.
    cf = "cf.",
    ["cf."] = "cf.",
    ["c.f."] = "cf."
    }

--[[=========================================================================
Main function to italicize a taxon name appropriately.
=============================================================================]]
function p.main(frame)
    local name = frame.args[1] or ''
    local linked = frame.args['linked'] == 'yes'
    local abbreviated = frame.args['abbreviated'] == 'yes'
    return p.italicizeTaxonName(name, linked, abbreviated)
end

--[[=========================================================================
Utility local function to abbreviate an input string to its first character
followed by ".".
Both "×" and an HTML entity at the start of the string are skipped over in
determining first character, as is an opening parenthesis and an opening ",
which cause a matching closing character to be included.
=============================================================================]]
function l.abbreviate(str)
	local result = ""
	local hasParentheses = false
	local isQuoted = false
	if mw.ustring.len(str) < 2 then
		--single character strings are left unchanged
		result = str
	else
		--skip over an opening parenthesis that could be present at the start of the string
		if mw.ustring.sub(str,1,1) == "(" then
			hasParentheses = true
			result = "(" 
			str = mw.ustring.sub(str,2,mw.ustring.len(str))
		elseif mw.ustring.sub(str,1,1) == '"' then
			isQuoted = true
			result = '"'
			str = mw.ustring.sub(str,2,mw.ustring.len(str))
		end
		--skip over a hybrid symbol that could be present at the start of the string
		if mw.ustring.sub(str,1,1) == "×" then
			result = "×" 
			str = mw.ustring.sub(str,2,mw.ustring.len(str))
		end
		--skip over an HTML entity that could be present at the start of the string
		if mw.ustring.sub(str,1,1) == "&" then
			local i,dummy = mw.ustring.find(str,";",2,plain)
			result = result .. mw.ustring.sub(str,1,i)
			str = mw.ustring.sub(str,i+1,mw.ustring.len(str))
		end
		--if there's anything left, reduce it to its first character plus ".",
		--adding the closing parenthesis or quote if required
		if str ~= "" then 
			result = result .. mw.ustring.sub(str,1,1) .. "."
			if hasParentheses then result = result .. ")"
			elseif isQuoted then result = result .. '"'
			end
		end
	end
	return result
end

--[[=========================================================================
The function which does the italicization.
=============================================================================]]
function p.italicizeTaxonName(name, linked, abbreviated)
    name = mw.text.trim(name)
    -- if the name begins with '[', then assume formatting is present
    if  mw.ustring.sub(name,1,1) == '[' then return name end
    -- otherwise begin by replacing any use of the HTML italic tags
    -- by Wikimedia markup; replace any entity alternatives to the hybrid symbol
    -- by the symbol itself; prevent the hybrid symbol being treated as
    -- a 'word' by converting a following space to the HTML entity
    local italMarker = "''"
    name = string.gsub(mw.text.trim(name), "</?i>", italMarker)
    name = string.gsub(string.gsub(name, "&#215;", "×"), "&times;", "×")
    name = string.gsub(name, "</?span.->", "") -- remove any span markup
    name = string.gsub(name, "× ", "×&#32;")
    -- now italicize and abbreviate if required
    local result = name
    if name ~= '' then
        if string.sub(name,1,2) == italMarker or string.sub(name,-2) == italMarker then
            -- do nothing if the name already has italic markers at the start or end
        else
            name = string.gsub(name, italMarker, "") -- first remove any internal italics
            local words = mw.text.split(name, " ", true)
            if #words == 4 and cTerms3[words[3]] then
                -- the third word of a four word name is a connecting term
                -- ensure the connecting term isn't italicized
                words[3] = '<span style="font-style:normal;">' .. cTerms3[words[3]] .. '</span>'
                if abbreviated then
                	words[1] = l.abbreviate(words[1])
                    words[2] = l.abbreviate(words[2])
            	end
                result = words[1] .. " " .. words[2] .. " " .. words[3] .. " " .. words[4]
            elseif #words == 3 and cTerms2[words[2]] then
                -- the second word of a three word name is a connecting term
                -- ensure the connecting term isn't italicized
                words[2] = '<span style="font-style:normal;">' .. cTerms2[words[2]] .. '</span>'
                if abbreviated then
                	words[1] = l.abbreviate(words[1])
                end
                result = words[1] .. " " .. words[2] .. " " .. words[3]
            else
                -- not a name as above; only deal with abbreviation
                if abbreviated then
                	if #words > 1 then
                		result = l.abbreviate(words[1])
                		for i = 2, #words-1, 1 do
                			result = result .. " " .. l.abbreviate(words[i])
                		end
                		result = result .. " " .. words[#words]
                	end
                else
                	result = name
                end
            end
            -- deal with any hybrid symbol as it should not be italicized
            result = string.gsub(result, "×", '<span style="font-style:normal;">×</span>')
             -- deal with any parentheses as they should not be italicized
            result = string.gsub(string.gsub(result,"%(",'<span style="font-style:normal;">(</span>'),"%)",'<span style="font-style:normal;">)</span>')
            -- any question marks surrounded by spans can have the spans joined
            result = string.gsub(result,'</span>%?<span style="font%-style:normal;">','?')
        	-- add outside markup
            if linked then
                if result ~= name then
                    result = "[[" .. name .. "|" .. italMarker .. result .. italMarker .. "]]"
                else
                    result = italMarker .. "[[" .. name .. "]]" .. italMarker
                end
            else
                result = italMarker .. result .. italMarker
            end
        end
    end
    return result
end

--[[=========================================================================
Utility function used by other modules to check if a connecting term is
present in a name. The value of name is assumed to be plain text.
=============================================================================]]
function p.hasCT(frame)
    return p.hasConnectingTerm(frame.args[1] or '')
end
    
function p.hasConnectingTerm(name)
	local words = mw.text.split(name, " ", true)
	if #words == 4 and cTerms3[words[3]] then return true
	elseif #words == 3 and cTerms2[words[2]] then return true
	else return false
	end
end
	
return p