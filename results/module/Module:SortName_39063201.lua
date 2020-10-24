local p = {}

function p.sortname(frame)
    local currentpage = mw.title.getCurrentTitle()
    local pagetitle = frame.args[1] or currentpage.text
    local langvar = mw.language.getContentLanguage()
    local text1 = ''
    local text2 = ''
    local parts = { 'de','De','von','Von','du','Du','del','Del','zu','Zu','di','Di','van','Van','na','Na','le','Le','de\'','De\'' }
    local partmatch = false
    if string.find( pagetitle, ' ' ) ~= nil then
        pagetitle = string.gsub( string.gsub( string.gsub( pagetitle, '%b()', '' ), ' +', ' '), ' $', '' )
        if string.find( pagetitle, '^List of ' ) ~= nil then
            pagetitle = langvar:ucfirst( string.gsub( pagetitle, '^List of ', '', 1 ) )
        elseif string.find( pagetitle, '^The ' ) ~= nil then
            pagetitle = string.gsub( pagetitle, '^The ', '' ) .. ', The'
        else
            pagetitle = string.gsub( pagetitle, ',.*$', '' )
            pagetitle = string.gsub( pagetitle, ' of .*$', '' )
            for i in ipairs( parts ) do
                if string.find( pagetitle, ' ' .. parts[i] .. ' ' ) ~= nil then
                    text1 = string.sub( pagetitle, string.find( pagetitle, ' ' .. parts[i] .. ' ' ) + 1, #pagetitle )
                    text2 = string.sub( pagetitle, 0, string.find( pagetitle, ' ' .. parts[i] .. ' ' ) - 1 )
                    pagetitle = text1 .. ', ' .. text2
                    partmatch = true
                    break
                end
            end
            if not partmatch and string.find( pagetitle, ' ' ) ~= nil then
                text1 = string.sub( pagetitle, string.find( pagetitle, ' [^ ]*$' ) + 1, #pagetitle )
                text2 = string.sub( pagetitle, 0, string.find( pagetitle, ' [^ ]*$' ) - 1 )
                local romannumeral = roman_to_numeral(text1)
                if romannumeral == -1 then
                    pagetitle = text1 .. ', ' .. text2
                else
                    if string.find( text2, ' ' ) == nil then
                        pagetitle = text2 .. ' ' .. romannumeral
                    else
                        text1 = string.sub( text2, string.find( text2, ' [^ ]*$' ) + 1, #text2 )
                        text2 = string.sub( text2, 0, string.find( text2, ' [^ ]*$' ) - 1 )
                        pagetitle = text1 .. ' ' .. romannumeral .. ', ' .. text2
                    end
                end
            end
        end
    end
    return pagetitle
end

-- the following table and roman_to_numeral function came from Module:ConvertNumeric, created by User:Dcoetzee
roman_numerals = {
    I = 1,
    V = 5,
    X = 10,
    L = 50,
    C = 100,
    D = 500,
    M = 1000
}
 
-- Converts a given valid roman numeral (and some invalid roman numerals) to a number. Returns -1, errorstring on error
function roman_to_numeral(roman)
    if type(roman) ~= "string" then return -1, "roman numeral not a string" end
    local rev = roman:reverse()
    local raising = true
    local last = 0
    local result = 0
    for i = 1, #rev do
        local c = rev:sub(i, i)
        local next = roman_numerals[c]
        if next == nil then return -1, "roman numeral contains illegal character " .. c end
        if next > last then
            result = result + next
            raising = true
        elseif next < last then
            result = result - next
            raising = false
        elseif raising then
            result = result + next
        else
            result = result - next
        end
        last = next
    end
    return result
end
 
return p