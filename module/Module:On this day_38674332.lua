local p = {}

function p.countDates( frame )
    local args = frame:getParent().args
    local i = 1
    while true do
        local oldid = args['oldid' .. i] or ''
        if oldid == '' then
            return i - 1
        end
        i = i + 1
    end
end

function p.showDates( frame )
    local args = frame:getParent().args
    local i = 1
    local ret = {}
    local page = mw.title.getCurrentTitle().text
    local fmt = '[//en.wikipedia.org/wiki/Wikipedia:Selected_anniversaries/%s?oldid=%s %s]'
    if not args.demo then
        fmt = fmt .. '[[Category:Selected anniversaries (%s)|%s]]'
    end
    local lang = mw.getContentLanguage()

    while true do
        local date = args['date' .. i] or ''
        local oldid = args['oldid' .. i] or ''
        if oldid == '' then
            break
        end
        ret[i] = string.format( fmt,
            lang:formatDate( 'F_j', date ),
            oldid,
            lang:formatDate( 'F j, Y', date ),
            lang:formatDate( 'F Y', date ),
            page
        )
        i = i + 1
    end

    i = #ret
    if i > 1 then
        ret[i] = 'and ' .. ret[i]
    end
    return table.concat( ret, i > 2 and ', ' or ' ' )
end

return p