local p = {}

-- Cyrillic to Latin substitution table
local c2l = {
    ["а"] = "a", ["А"] = "A",
    ["б"] = "b", ["Б"] = "B",
    ["в"] = "v", ["В"] = "V",
    ["г"] = "g", ["Г"] = "G",
    ["д"] = "d", ["Д"] = "D",
    ["ђ"] = "đ", ["Ђ"] = "Đ",
    ["е"] = "e", ["E"] = "E",
    ["ж"] = "ž", ["Ж"] = "Ž",
    ["з"] = "z", ["З"] = "Z",
    ["и"] = "i", ["И"] = "I",
    ["ј"] = "j", ["Ј"] = "J",
    ["к"] = "k", ["К"] = "K",
    ["л"] = "l", ["Л"] = "L",
    ["љ"] = "ǉ", ["Љ"] = "ǈ",
    ["м"] = "m", ["М"] = "M",
    ["н"] = "n", ["Н"] = "N",
    ["њ"] = "ǌ", ["Њ"] = "ǋ",
    ["о"] = "o", ["О"] = "O",
    ["п"] = "p", ["П"] = "P",
    ["р"] = "r", ["Р"] = "R",
    ["с"] = "s", ["С"] = "S",
    ["т"] = "t", ["Т"] = "T",
    ["ћ"] = "ć", ["Ћ"] = "Ć",
    ["у"] = "u", ["У"] = "U",
    ["ф"] = "f", ["Ф"] = "F",
    ["х"] = "h", ["Х"] = "H",
    ["ц"] = "c", ["Ц"] = "C",
    ["ч"] = "č", ["Ч"] = "Č",
    ["џ"] = "ǆ", ["Џ"] = "ǅ",
    ["ш"] = "š", ["Ш"] = "Š"
}

-- Latin to Cyrillic substitution table
local l2c = {
    ["a"] = "а", ["A"] = "А",
    ["b"] = "б", ["B"] = "Б",
    ["v"] = "в", ["V"] = "В",
    ["g"] = "г", ["G"] = "Г",
    ["d"] = "д", ["D"] = "Д",
    ["đ"] = "ђ", ["Đ"] = "Ђ",
    ["e"] = "е", ["E"] = "E",
    ["ž"] = "ж", ["Ž"] = "Ж",
    ["z"] = "з", ["Z"] = "З",
    ["i"] = "и", ["I"] = "И",
    ["j"] = "ј", ["J"] = "Ј",
    ["k"] = "к", ["K"] = "К",
    ["l"] = "л", ["L"] = "Л",
    ["ǉ"] = "љ", ["ǈ"] = "Љ", ["Ǉ"] = "Љ",
    ["m"] = "м", ["M"] = "М",
    ["n"] = "н", ["N"] = "Н",
    ["ǌ"] = "њ", ["ǋ"] = "Њ", ["Ǌ"] = "Њ",
    ["o"] = "о", ["O"] = "О",
    ["p"] = "п", ["P"] = "П",
    ["r"] = "р", ["R"] = "Р",
    ["s"] = "с", ["S"] = "С",
    ["t"] = "т", ["T"] = "Т",
    ["ć"] = "ћ", ["Ć"] = "Ћ",
    ["u"] = "у", ["U"] = "У",
    ["f"] = "ф", ["F"] = "Ф",
    ["h"] = "х", ["H"] = "Х",
    ["c"] = "ц", ["C"] = "Ц",
    ["č"] = "ч", ["Č"] = "Ч",
    ["ǆ"] = "џ", ["ǅ"] = "Џ", ["Ǆ"] = "Џ",
    ["š"] = "ш", ["Š"] = "Ш"
}


function _cyr2lat(str)
    local lat = mw.ustring.gsub(str, "%a", c2l)
    return lat
end


function _lat2cyr(str)
    local cyr = mw.ustring.gsub(str, "%a", l2c)
    return cyr
end


function p.cyr2lat(frame)
    return _cyr2lat(frame.args[1])
end


function p.lat2cyr(frame)
    return _lat2cyr(frame.args[1])
end


function p.convert(frame)
    local lat = frame.args.latin
    local cyr = frame.args.cyrillic

    if not cyr then
        if lat then
            cyr = _lat2cyr(lat)
        else
            error("Neither Latin nor Cyrillic text is included", 0)
        end
    elseif not lat then
        lat = _cyr2lat(cyr)
    end
    
    return mw.ustring.format("\'\'%s\'\', %s", lat, cyr)
end

return p