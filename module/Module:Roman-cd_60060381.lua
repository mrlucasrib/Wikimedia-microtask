--[[
This module converts Arabic numerals into Roman numerals.
It currently works for any non-negative integer below 5 billions (up to 4 999 999 999).

Zero is represented as "N" (from Classical Latin adverbs "nec" or "non"), like in standard CLDR data.

For numbers starting at 4 thousands, this version no longer generates any HTML+CSS, but only plain-text:
standard Unicode combining diacritics are used for overlines (U+0305 for the first level,
then U+0304 for the second level, but both are treated equivalently when parsing Roman numbers).

For numbers starting at 4 billions, it still uses 4 letters M with double overlines because
triple overlines are not supported in plain-text (this is acceptable, just like "MMMM" is also
acceptable for representing 4000 but this version chooses the shorter "IV" with a single overline).

The Roman number parser will accept all valid notations (except apostrophic/Claudian/lunate notations
using reversed C), more than what it generates, and will correctly convert them to Arabic numbers.

Please do not modify this code without applying the changes first at Module:Roman/sandbox and testing
at Module:Roman/sandbox/testcases and Module talk:Roman/sandbox/testcases.

Authors and maintainers:
* User:RP88, User:Verdy_p
]]
local p = {}

--[============[
   Private data
--]============]
-- See CLDR data /common/rbnf/root.xml for "roman-upper" rules. However we still don't
-- use the rarely supported Roman extension digits after 'M' (in U+2160..2188), but use
-- the more common notation with diacritical overlines ('ↁ'='V̅', 'ↂ'='X̅', etc.).
-- Please avoid using HTML with "text-decoration:overline" style, but use plain-text
-- combining characters (U+0304 and/or U+0305).
local decimalRomans = {
    d0 = { [0] = '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX' },
    d1 = { [0] = '', 'X', 'XX', 'XXX', 'XL', 'L', 'LX', 'LXX', 'LXXX', 'XC' },
    d2 = { [0] = '', 'C', 'CC', 'CCC', 'CD', 'D', 'DC', 'DCC', 'DCCC', 'CM' },
    d3 = { [0] = '', 'M', 'MM', 'MMM', 'I̅V̅', 'V̅', 'V̅I̅', 'V̅I̅I̅', 'V̅I̅I̅I̅', 'I̅X̅' },
    d4 = { [0] = '', 'X̅', 'X̅X̅', 'X̅X̅X̅', 'X̅L̅', 'L̅', 'L̅X̅', 'L̅X̅X̅', 'L̅X̅X̅X̅', 'X̅C̅' },
    d5 = { [0] = '', 'C̅', 'C̅C̅', 'C̅C̅C̅', 'C̅D̅', 'D̅', 'D̅C̅', 'D̅C̅C̅', 'D̅C̅C̅C̅', 'C̅M̅' },
    d6 = { [0] = '', 'M̅', 'M̅M̅', 'M̅M̅M̅', 'I̿V̿', 'V̿', 'V̿I̿', 'V̿I̿I̿', 'V̿I̿I̿I̿', 'I̿X̿' },
    d7 = { [0] = '', 'X̿', 'X̿X̿', 'X̿X̿X̿', 'X̿L̿', 'L̿', 'L̿X̿', 'L̿X̿X̿', 'L̿X̿X̿X̿', 'X̿C̿' },
    d8 = { [0] = '', 'C̿', 'C̿C̿', 'C̿C̿C̿', 'C̿D̿', 'D̿', 'D̿C̿', 'D̿C̿C̿', 'D̿C̿C̿C̿', 'C̿M̿' },
    d9 = { [0] = '', 'M̿', 'M̿M̿', 'M̿M̿M̿', 'M̿M̿M̿M̿' },
}
local romanDecimals = {
    -- Basic Latin capital letters
    N = 0, -- abbreviated "nec" or "non" adverb in Classical Latin
    I = 1, V = 5, X = 10, L = 50, C = 100,
    D = 500,-- TODO: add Medieval "apostrophic/Claudian/lunate" notations like "IƆ"
    M = 1000,
    -- Basic Latin small letters (not used in Classical Latin, but added in Medieval Latin)
    n = 0, -- abbreviated "nec" or "non" adverb in Classical Latin
    i = 1, v = 5, x = 10, l = 50, c = 100,
    d = 500,-- TODO: add Medieval "apostrophic/Claudian/lunate" notations like "IƆ"
    m = 1000,
    -- U+0304 .. U+0305 : COMBINING (MACRON|OVERLINE)
    ['\204\132'] = -1000, -- (0xCC,0x84 in UTF-8) multiplier (thousand) 
    ['\204\133'] = -1000, -- (0xCC,0x85 in UTF-8) multiplier (thousand), considered equivalent here
    -- U+033F : COMBINING DOUBLE OVERLINE
    ['\204\191'] = -1000000, -- (0xCC,0xBF in UTF-8) multiplier (million)
    -- U+012A
    ['Ī'] = 1000, ['ī'] = 1000, -- LATIN LETTER WITH COMBINING MACRON, canonically equivalent to 'I' and U+0304
    -- U+2160 .. U+216F : Roman capital digit symbols (compatibility, monospaced in CJK fonts)
    ['Ⅰ'] = 1, ['Ⅱ'] = 2, ['Ⅲ'] = 3, ['Ⅳ'] = 4, ['Ⅴ'] = 5, ['Ⅵ'] = 6,
    ['Ⅶ'] = 7, ['Ⅷ'] = 8, ['Ⅸ'] = 9, ['Ⅹ'] = 10, ['Ⅺ'] = 11, ['Ⅻ'] = 12,
    ['Ⅼ'] = 50, ['Ⅽ'] = 100, ['Ⅾ'] = 500, ['Ⅿ'] = 1000,
    -- U+2170 .. U+217F : Roman lowercase digit symbols (compatibility, monospaced in CJK fonts)
    ['ⅰ'] = 1, ['ⅱ'] = 2, ['ⅲ'] = 3, ['ⅳ'] = 4, ['ⅴ'] = 5, ['ⅵ'] = 6,
    ['ⅶ'] = 7, ['ⅷ'] = 8, ['ⅸ'] = 9, ['ⅹ'] = 10, ['ⅺ'] = 11, ['ⅻ'] = 12,
    ['ⅼ'] = 50, ['ⅽ'] = 100, ['ⅾ'] = 500, ['ⅿ'] = 1000,
    -- U+2180 .. U+2182 : Old Roman symbols (these have no case pairs)
    ['ↀ'] = 1000, -- = 'I̅' = 'M'. TODO: add Medieval "apostrophic/Claudian/lunate" notations like "CIƆ"; do not confuse it with "CD" (400)
    ['ↁ'] = 5000, -- = 'V̅'. TODO: add Medieval "apostrophic/Claudian/lunate" notations like "DƆ" and "IƆƆ"
    ['ↂ'] = 10000, -- = 'X̅'. TODO: add Medieval "apostrophic/Claudian/lunate" notations like "CCIƆƆ"
    -- U+2183..U+2184 : ROMAN DIGIT (CAPITAL|LOWER) REVERSED C. TODO: add for "apostrophic/Claudian/lunate" notations (and support "Ɔ" OPEN O as aliases)
    -- The reversed "C" is a trailing multiplier by 10 but if it is not paired by a leading "C", the surrounded value will be divided by 2:
    -- * "I" = 1, but if followed by followed by "Ɔ", it takes the value 100:
    -- * when followed by a first "Ɔ" it multiplies it by 10 giving 1000 (assuming "CIƆ"), but if not prefixed by a pairing "C", gives 500 for "IƆ" = "D".
    -- * when followed by a second "Ɔ" it multiplies it by 10 giving 1000 (assuming "CCIƆƆ"), but if not prefixed by a pairing "C", gives 5000 for "IƆƆ" = "DƆ".
    -- * for higher multiples, using overlines is highly preferred for noting multipliers by 1000.
    -- U+2185: ROMAN NUMERAL SIX LATE FORM
    ['ↅ'] = 6, -- = 'VI' (overstriked letters)
    -- U+2186: ROMAN NUMERAL FIFTY EARLY FORM (Borrowed in Latin in capital form, from Greek Final sigma, similar to "C" with a leg meaning "half")
    ['ↆ'] = 50, -- = 'L'
    -- U+2187 .. U+2188: ROMAN NUMERAL (ONE HUNDRED|FIFTY) THOUSAND (Archaic, rarely supported in fonts)
    ['ↇ'] = 50000, -- = 'L̅'. TODO: add Medieval "apostrophic/Claudian/lunate" notations like "DƆƆ" and "IƆƆƆ"
    ['ↈ'] = 100000, -- = 'C̅'. TODO: add Medieval "apostrophic/Claudian/lunate" notations like "CCCDƆƆ" and "CCCIƆƆƆ"
}

--[=================[
   Private functions
--]=================]

--[==[
This function returns a string containing the input value formatted as a Roman numeral.
It works for non-negative integers lower than 5 billions (up to 4 999 999 999: this covers
all unsigned 32-bit integers), otherwise it returns the number formatted using Latin
digits. The result string will be an UTF-8-encoded plain-text alphabetic string.
]==]--
local function convertArabicToRoman(value)
    if value >= 1 and value <= 4999999999 and value == math.floor(value) then
        local d0, d1, d2, d3, d4, d5, d6, d7, d8
        d0, value = value % 10, math.floor(value / 10)
        d1, value = value % 10, math.floor(value / 10)
        d2, value = value % 10, math.floor(value / 10)
        d3, value = value % 10, math.floor(value / 10)
        d4, value = value % 10, math.floor(value / 10)
        d5, value = value % 10, math.floor(value / 10)
        d6, value = value % 10, math.floor(value / 10)
        d7, value = value % 10, math.floor(value / 10)
        d8, value = value % 10, math.floor(value / 10)
        return table.concat({
            decimalRomans.d9[value],
            decimalRomans.d8[d8],
            decimalRomans.d7[d7],
            decimalRomans.d6[d6],
            decimalRomans.d5[d5],
            decimalRomans.d4[d4],
            decimalRomans.d3[d3],
            decimalRomans.d2[d2],
            decimalRomans.d1[d1],
            decimalRomans.d0[d0],
        })
    elseif value == 0 then
        return 'N' -- for adverbs "nec" or "non" in Classical Latin (which had no zero)
    end
    return tostring(value)
end

--[==[
This function converts a plain-text string containing a Roman numeral to an integer.
It works for values between 0 (N) and 4 999 999 999 (M̿M̿M̿M̿C̿M̿X̿C̿I̿X̿C̅M̅X̅C̅I̅X̅CMXCIX).
]==]--
local function convertRomanToArabic(roman)
    if roman == '' then return nil end
    local result, prevRomanDecimal, multiplier = 0, 0, 1
    for i = mw.ustring.len(roman), 1, -1 do
        local currentRomanDecimal = romanDecimals[mw.ustring.sub(roman, i, i)]
        if currentRomanDecimal == nil then
            return nil
        elseif currentRomanDecimal < 0 then
            multiplier = multiplier * -currentRomanDecimal
        else
            currentRomanDecimal, multiplier = currentRomanDecimal * multiplier, 1
            if currentRomanDecimal < prevRomanDecimal then
                result = result - currentRomanDecimal
            else
                result = result + currentRomanDecimal
                prevRomanDecimal = currentRomanDecimal
            end
        end
    end
    return result
end

--[==[
This function converts a string containing a Roman numeral to an integer.
It works for values between 0 and 4999999999.
The input string may contain HTML tags using style="text-decoration:overline" (not recommended).
]==]--
local function convertRomanHTMLToArabic(roman)
    local result = convertRomanToArabic(roman)
    if result == nil then
        result = tonumber(roman)
    end
    return result
    [==[ DISABLED FOR NOW, NOT REALLY NEEDED AND NOT CORRECTLY TESTED
    local result = 0
    local overline_start_len = mw.ustring.len(overline_start)
    if mw.ustring.sub(roman, 1, overline_start_len) == overline_start then
        local end_tag_start, end_tag_end = mw.ustring.find(roman, overline_end, overline_start_len, true)
        if end_tag_start ~= nil then
            local roman_high = mw.ustring.sub(roman, overline_start_len + 1, end_tag_start - 1)
            local roman_low = mw.ustring.sub(roman, end_tag_end + 1, mw.ustring.len(roman)) or ''
            if (mw.ustring.find(roman_high, "^[mdclxvi]+$") ~= nil) and (mw.ustring.find(roman_low, "^[mdclxvi]*$") ~= nil) then
                result = convertRomanToArabic(roman_high) * 1000 + convertRomanToArabic(roman_low)
            end
        end
    end
    return result
    ]==]
end

--[==[
Helper function to handle error messages.
]==]--
local function outputError(message)
    return table.concat({
        '<strong class="error">Roman Module Error: ', message,
        '</strong>[[Category:Errors reported by Module Roman]]'
    })
end

--[================[
   Public functions
--]================]

--[==[
isRoman

Tests if the trimmed input is a valid Roman numeral. Returns true if so, false if not.
For the purposes of this function, the empty string (after trimming whitespaces) is not a Roman numeral.

Parameters
   s: string to test if it is a valid Roman numeral

Error Handling:
   If the input is not a valid Roman numeral this function returns false.
]==]--
function p.isRoman(s)
    return type(s) == 'string' and convertRomanToArabic(mw.text.trim(s)) ~= nil
end

--[==[
toArabic

This function converts a Roman numeral into an Arabic numeral.
It works for values between 0 and 4999999999.
'N' is converted to 0 and the empty string is converted to nil.

Parameters
   roman: string containing value to convert into an Arabic numeral

Error Handling:
   If the input is not a valid Roman numeral this function returns nil.
]==]--
function p.toArabic(roman)
    if type(roman) == 'string' then
        roman = mw.text.trim(roman)
        local result = convertRomanToArabic(roman)
        if result == nil then
            result = tonumber(roman)
        end
        return result
    elseif type(roman) == 'number' then
        return roman
    else
        return nil
    end
end

--[==[
_Numeral

This function returns a string containing the input value formatted as a Roman numeral.
It works for values between 0 and 4999999999.

Parameters
   value: integer or string containing value to convert into a Roman numeral

Error Handling:
   If the input does not look like it contains a number or the number is outside of the
   supported range an error message is returned.
]==]--
function p._Numeral(value)
    if value == nil then
        return outputError('missing value')
    end
    if type(value) == 'string' then
        value = tonumber(value)
    elseif type(value) ~= 'number' then
        return outputError('unsupported value')
    end
    return convertArabicToRoman(value)
end

--[==[
Numeral

This function for MediaWiki converts an Arabic numeral into a Roman numeral.
It works for values between 0 and 4999999999 (includes the whole range of unsigned 32-bit integers).
Arabic numeral zero is output as 'N' (for Latin negation adverbs "nec" or "non").

Usage:
    {{#invoke:Roman|Numeral|<value>}}
    {{#invoke:Roman|Numeral}} - uses the caller's parameters

Parameters
    1: Value to convert into a Roman numeral. Must be at least 0 and less than 5,000,000.

Error Handling:
    If the input does not look like it contains a number or the number is outside of the
    supported range an error message is returned.
]==]--
function p.Numeral(frame)
    -- if no argument provided than check parent template/module args
    local args = frame.args
    if args[1] == nil then
        args = frame:getParent().args
    end
    return p._Numeral(args[1])
end

return p