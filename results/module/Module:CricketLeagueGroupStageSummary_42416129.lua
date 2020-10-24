local p = {}

---------- Background colours for table cells ----------
local colours = {
    H = "#CCCCFF", -- Home team wins
    A = "#FFCCCC", -- Away team wins
    N = "#FFDEAD", -- Match abandoned
    D = "#F0E68C", -- Match drawn
    T = "#DDFFDD"  -- Match tied
}

local noMatchColour = "#C0C0C0"     -- No match defined
local notPlayedColour = "inherit"   -- Not played yet
local errorColour = "#FF7777"       -- Error

function trim(s)
    if not s then
        return nil
    else
        return (mw.ustring.gsub(s, "^%s*(.-)%s*$", "%1"))
    end
end

function getArgs(frame)
    local parent = frame:getParent();
    local args = {}
    for k,v in pairs(parent.args) do
        args[k] = trim(v)
    end
    for k,v in pairs(frame.args) do
        args[k] = trim(v)
    end
    return args;
end

--
--   Match class
--
local cricmatch = {}

cricmatch.__index = function(t, key)
    local ret = rawget(t, key)
    if ret then
        return ret
    end
    ret = cricmatch[key]
    if type(ret) == 'function' then
        return function(...)
            return ret(t, ...)
        end
    else
        return ret
    end
end

cricmatch.addResultLink = function(m, cell, text)
    cell:tag('span')
        :attr('title', string.format('Match %d', m.id))
        :wikitext(string.format('[[#match%s|%s]]', m.id, text))
end

cricmatch.getMarginResult = function(m, row, matchNo)
    local team = m.result == 'H' and m.home or m.away
    local marginText
    if m.margin == 'F' then
        marginText = "Forfeited"
    elseif m.margin == 'SO' then
        marginText = "Super Over"
    else
        local n = tonumber(string.sub(m.margin, 1, -2))
        local t = string.upper(string.sub(m.margin, -1, -1))
        if t == 'R' then
            marginText = "%d run"
        elseif t == 'W' then
            marginText = "%d wicket"
        elseif t == 'I' then
            marginText = "Inns & %d run"
        end
        if marginText and n then
            marginText = string.format(marginText, n)
            if n > 1 then marginText = marginText .. "s" end
        else
            marginText = matchNo
        end
        if m.dl then
            marginText = marginText
                .. ' <span style="font-size: 85%">(' .. m.dl .. ')</span>'
        end
    end
    local cell = addTableCell(row, colours[m.result])
        :tag('span'):wikitext(team.shortName):done()
        :tag('br'):done()
    m.addResultLink(cell, marginText)
    return cell:css('padding', '3px 5px')
end

cricmatch.getResult = function(m, row)
    local colour, text
    local matchNo = string.format('[[#match%s|Match %s]]', m.id, m.id)
    if m.result == 'D' then
        -- Drawn match
        colour = colours.D
        text = 'Match drawn'
    elseif m.result == 'N' then
        -- Abandoned match
        colour = colours.N
        text = 'Match<br />abandoned'
    elseif m.result == 'T' then
        -- Tied match
        colour = colours.T
        text = 'Match tied'
    elseif m.result == 'H' or m.result == 'A' then
        return m.getMarginResult(row, matchNo)
    end
    local cell
    if text and colour then
        cell = addTableCell(row, colour)
        m.addResultLink(cell, text)
    else
        cell = addTableCell(row, notPlayedColour, matchNo)
    end
    return cell:css('padding', '3px 5px')
end

function createMatch(id, home, away, result, margin, dl)
    if not home or not away then
        return nil
    end
    local match = {}
    setmetatable(match, cricmatch)
    match.id = id
    match.home = home
    match.away = away
    match.result = result
    match.margin = margin
    match.dl = dl
    return match
end

--
--   Html Builder helpers
--
function addTableRow(tbl)
    return tbl:tag('tr')
end
function addTableCell(row, bg, text)
    return row:tag('td'):css('background-color', bg):wikitext(text)
end
function addNoMatch(row)
    addTableCell(row, noMatchColour)
    return row
end

--
--   Helper functions
--
function buildLegend(container, types, homeaway)
    local key = container:tag('table')
        :addClass('wikitable')
        :css('float', 'right')
        :css('text-align', 'center')
        :css('font-size', '90%')
        :css('margin', '0 0 0 10px')

    local keys = { 'H', 'A' }
    local text = {
        H = 'Home team won',
        A = 'Visitor team won',
        D = 'Match drawn',
        N = 'Match abandoned',
        T = 'Match tied'
    }
    local count = 0
    for _, _ in pairs(types) do count = count + 1 end
    local row = addTableRow(key)
    for _, k in ipairs(keys) do
        if types[k] then addTableCell(row, colours[k], text[k]) end
    end

    local list = container:tag('ul')
        :css('font-size', '90%')
        :tag('li')
            :wikitext(homeaway and "'''Note''': Results listed are according to the " ..
                "home (horizontal) and visitor (vertical) teams." or
                "'''Note''': Results listed are according to the " ..
                "first encounter (top-right) and second encounter (bottom-left).")
            :done()
        :tag('li')
            :wikitext("'''Note''': Click on a result to see " ..
                "a summary of the match.")
        :done()
    return container
end

function getMatchData(args, teams)
    local i, m = 0, 1
    local match
    local matches = {}
    local dlText = args.dls == 'Y' and 'DLS' or 'D/L'
    local home, away, result, margin, dl
    while args[i * 5 + 5] do
        home = teams[trim(args[i * 5 + 1])]
        away = teams[args[i * 5 + 2]]
        result = args[i * 5 + 3]
        margin = args[i * 5 + 4]
        dl = args[i * 5 + 5] == "Y"
        match = createMatch(m, home, away, result, margin, dl and dlText or nil)
        if match then
            table.insert(matches, match)
            m = m + 1
        end
        i = i + 1
    end
    return matches
end

p.create = function(args, teams, tableStyle)
    local matches = getMatchData(args, teams)

    -- organise by team
    local codes, results, types = {}, {}, {}
    for i, match in ipairs(matches) do
        local home = match.home.code
        local away = match.away.code
        if not results[home] then
            table.insert(codes, home)
            results[home] = {}
        end
        if not results[away] then
            table.insert(codes, away)
            results[away] = {}
        end
        results[home][away] = match
        types[match.result] = true
    end
    local teamsort = function(t1, t2)
        return teams[t1].fullName < teams[t2].fullName
    end
    table.sort(codes, teamsort)

    local wrapper = mw.html.create('div')

    -- Construct the header
    local container = wrapper:tag('div')
        :css('float', 'left')
        :css('max-width', '100%')
    local tbl = container:tag('table')
        :attr('class', 'wikitable')
        :css('width', '100%')
        :css('display', 'block')
        :css('overflow', 'auto')
        :css('border', 'none')
    if tableStyle then
        tbl:cssText(tableStyle)
    else
        tbl:css('text-align', 'center')
            :css('white-space', 'nowrap')
            :css('width', '100%')
        if #codes > 8 then
            tbl:css('font-size', (100 - (#codes - 8) * 10) .. '%')
        end
    end
    local homeaway = not (args['homeaway'] and (args['homeaway'] == 'no' or args['homeaway'] == 'n'))
    local header = addTableRow(tbl)
        :tag('th')
            :attr('scope', 'row')
            :wikitext(homeaway and 'Visitor team →' or nil)
        :done()
    for i, code in ipairs(codes) do
        local team = teams[code]
        header:tag('th')
            :attr('rowspan', homeaway and '2' or nil)
            :attr('scope', 'col')
            :css('padding', 'inherit 10px')
            :wikitext(string.format('[[%s|%s]]', team.pageName, team.abbr or team.code))
            :newline()
    end
    if homeaway then
        tbl:tag('tr'):tag('th'):attr('scope', 'col'):wikitext('Home team ↓')
    else
        types['H'] = false
        types['A'] = false
    end

    -- Output the main body of the table
    for i, homecode in ipairs(codes) do
        local home = teams[homecode]
        local row = addTableRow(tbl)
        local teamcell = row:tag('th')
            :attr('scope', 'row')
            :css('text-align', 'left')
            :css('padding', '3px 5px')
            :css('white-space', 'normal')
            :wikitext(string.format('[[%s|%s]]', home.pageName, home.fullName))
        for j, awaycode in ipairs(codes) do
            local match = results[homecode][awaycode]
            if match then match.getResult(row) else addNoMatch(row) end
        end
    end

    -- Legend and notes
    buildLegend(container, types, homeaway)
    wrapper:tag('div'):css('clear', 'both')
    return tostring(wrapper)
end

p.IPL = function(frame)
    local args = getArgs(frame)
    local teams = mw.loadData("Module:Indian Premier League teams")
    local teamsAssoc = {}
    local i = 1
    while teams[i] do
        teamsAssoc[teams[i].code] = teams[i]
        i = i + 1
    end
    return p.create(args, teamsAssoc)
end

p.BBL = function(frame)
    local args = getArgs(frame)
    local teams = {
        ADS = {
            code       = "ADS",
            fullName   = "Adelaide Strikers",
            shortName  = "Strikers",
            pageName   = "Adelaide Strikers"
        },
        BRH = {
            code       = "BRH",
            fullName   = "Brisbane Heat",
            shortName  = "Heat",
            pageName   = "Brisbane Heat"
        },
        HBH = {
            code       = "HBH",
            fullName   = "Hobart Hurricanes",
            shortName  = "Hurricanes",
            pageName   = "Hobart Hurricanes"
        },
        MLR = {
            code       = "MLR",
            fullName   = "Melbourne Renegades",
            shortName  = "Renegades",
            pageName   = "Melbourne Renegades"
        },
        MLS = {
            code       = "MLS",
            fullName   = "Melbourne Stars",
            shortName  = "Stars",
            pageName   = "Melbourne Stars"
        },
        PRS = {
            code       = "PRS",
            fullName   = "Perth Scorchers",
            shortName  = "Scorchers",
            pageName   = "Perth Scorchers"
        },
        SYS = {
            code       = "SYS",
            fullName   = "Sydney Sixers",
            shortName  = "Sixers",
            pageName   = "Sydney Sixers"
        },
        SYT = {
            code       = "SYT",
            fullName   = "Sydney Thunder",
            shortName  = "Thunder",
            pageName   = "Sydney Thunder"
        }
    }
    return p.create(args, teams)
end
p.WBBL = function(frame)
    local args = getArgs(frame)
    local teams = {
        ADS = {
            code       = "ADS",
            fullName   = "Adelaide Strikers",
            shortName  = "Strikers",
            pageName   = "Adelaide Strikers (WBBL)"
        },
        BRH = {
            code       = "BRH",
            fullName   = "Brisbane Heat",
            shortName  = "Heat",
            pageName   = "Brisbane Heat (WBBL)"
        },
        HBH = {
            code       = "HBH",
            fullName   = "Hobart Hurricanes",
            shortName  = "Hurricanes",
            pageName   = "Hobart Hurricanes (WBBL)"
        },
        MLR = {
            code       = "MLR",
            fullName   = "Melbourne Renegades",
            shortName  = "Renegades",
            pageName   = "Melbourne Renegades (WBBL)"
        },
        MLS = {
            code       = "MLS",
            fullName   = "Melbourne Stars",
            shortName  = "Stars",
            pageName   = "Melbourne Stars (WBBL)"
        },
        PRS = {
            code       = "PRS",
            fullName   = "Perth Scorchers",
            shortName  = "Scorchers",
            pageName   = "Perth Scorchers (WBBL)"
        },
        SYS = {
            code       = "SYS",
            fullName   = "Sydney Sixers",
            shortName  = "Sixers",
            pageName   = "Sydney Sixers (WBBL)"
        },
        SYT = {
            code       = "SYT",
            fullName   = "Sydney Thunder",
            shortName  = "Thunder",
            pageName   = "Sydney Thunder (WBBL)"
        }
    }
    return p.create(args, teams)
end
p.PSL = function(frame)
    local args = getArgs(frame)
    local teams = mw.loadData("Module:PakistanSuperLeagueTeams")
    local teamsAssoc = {}
    local i = 1
    while teams[i] do
        teamsAssoc[teams[i].code] = teams[i]
        i = i + 1
    end
    return p.create(args, teamsAssoc)
end

p.Aus = function(frame)
    local args = getArgs(frame)
    local teams = {
        NSW = {
            code       = "NSW",
            fullName   = "New South Wales",
            shortName  = "NSW",
            pageName   = "New South Wales cricket team"
        },
        QLD = {
            code       = "QLD",
            fullName   = "Queensland",
            shortName  = "Queensland",
            pageName   = "Queensland cricket team"
        },
        SA = {
            code       = "SA",
            fullName   = "South Australia",
            shortName  = "SA",
            pageName   = "South Australia cricket team"
        },
        TAS = {
            code       = "TAS",
            fullName   = "Tasmania",
            shortName  = "Tasmania",
            pageName   = "Tasmania cricket team"
        },
        VIC = {
            code       = "VIC",
            fullName   = "Victoria",
            shortName  = "Victoria",
            pageName   = "Victoria cricket team"
        },
        WA = {
            code       = "WA",
            fullName   = "Western Australia",
            shortName  = "WA",
            pageName   = "Western Australia cricket team"
        }
    }
    return p.create(args, teams)
end
return p