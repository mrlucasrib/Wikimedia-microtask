local p = {}

---------- Background colours for table cells ----------
local colours = {
    W = "#99FF99",
    L = "#FFDDDD",
    N = "#DFDFFF",
    D = "#F0E68C",
    T = "#DDFFDD",
    X = "#FFD"
}
local classes = {
    W = "yes table-yes2",
    L = "no table-no2",
    N = "noresult",
    X = "partial table-partial"
}
local elimColour = "#DCDCDC" -- Eliminated

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

cricmatch.title = function(m, home)
    local opponent = home and m.away or m.home
    local venue = home and 'H' or 'A'
    local title = string.format('vs. %s (%s)', opponent.fullName, venue)
    if m.result ~= 'H' and m.result ~= 'A' then
        return title
    end

    local marginText = (m.result == 'H' and home or
        m.result == 'A' and not home) and 'Won by ' or 'Lost by '
    if m.margin == 'F' then
        marginText = marginText .. "forfeit"
    elseif m.margin == 'SO' then
        marginText = marginText .. "Super Over"
    else
        local n = tonumber(string.sub(m.margin, 1, -2))
        local t = string.upper(string.sub(m.margin, -1, -1))
        if t == 'R' then
            marginText = marginText .. "%d run"
        elseif t == 'W' then
            marginText = marginText .. "%d wicket"
        elseif t == 'I' then
            marginText = marginText .. "an innings and %d run"
        end
        if marginText and n then
            marginText = string.format(marginText, n)
            if n > 1 then marginText = marginText .. "s" end
        end
        if m.dl then
            marginText = marginText
                .. ' (' .. m.dl .. ')'
        end
    end
    return marginText .. ' ' .. title
end

cricmatch.render = function(m, row, team, points)
    local cell = row:tag('td')
    local home = m.home == team
    local span = cell:tag('span'):attr('title', m.title(home))

    local result = m.result
    local gained = 0
    if m.result == 'H' then
        result = home and 'W' or 'L'
        gained = home and 2 or 0
    elseif m.result == 'A' then
        result = home and 'L' or 'W'
        gained = home and 0 or 2
    elseif m.result == 'N' or m.result == 'T' then
        gained = 1
    else
        cell
            :css('background-color', colours.X)
            :attr('class', classes.X)
        span:wikitext(string.format('[[#match%d|?]]', m.id))
        return points
    end

    points = points + gained
    cell:css('background-color', colours[result])
    span:wikitext(string.format('[[#match%d|%d]]', m.id, points))
    if classes[cell] then cell:attr('class', classes[cell]) end
    return points
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
--   Helper functions
--
function buildLegend(container, types)
    local key = container:tag('table')
        :addClass('wikitable')
        :css('float', 'right')
        :css('text-align', 'center')
        :css('font-size', '90%')
        :css('margin', '0 0 0 10px')
        :tag('td')
            :css('background-color', colours.W)
            :css('padding-left', '10px')
            :css('padding-right', '10px')
            :wikitext('Win')
        :done()
        :tag('td')
            :css('background-color', colours.L)
            :css('padding', '0 10px')
            :wikitext('Loss')
        :done()
        :tag('td')
            :css('background-color', colours.N)
            :css('padding', '0 10px')
            :wikitext('No result')
        :done()

    local list = container:tag('ul')
        :css('font-size', '90%')
        :tag('li')
            :wikitext("'''Note''': The total points " ..
                "at the end of each group match are listed.")
        :done()
        :tag('li')
            :wikitext("'''Note''': Click on the points (group matches) " ..
                "or W/L (playoffs) to see the match summary.")
        :done()
    return container
end

function getMatchData(args, teams)
    local i, m = 0, 1
    local match
    local matches = {}
    local home, away, result, margin, dl
    local dlText = args.dls == 'Y' and 'DLS' or 'D/L'
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

function renderTeam(tbl, count, team, matches, koStages, total)
    local row = tbl:tag('tr')
        :tag('th')
            :css('text-align', 'left')
            :css('padding-right', '10px')
            :css('border-right', 'black solid 2px')
            :css('min-width', '160px')
            :wikitext(string.format('[[%s|%s]]', team.pageName, team.fullName))
        :done()
    local points = 0
    for i = 1, count do
        if matches[i] then
            points = matches[i].render(row, team, points)
        else
            row:tag('td')
        end
    end
    local cell, koMatches, koMatch, result, colour, matchNo
    local eliminated = true
    for i = 1, #koStages do
        result = nil
        cell = row:tag('td')
        if i == 1 then cell:css('border-left', 'black solid 2px') end
        koMatches = koStages[i].matches
        for j = 1, #koMatches do
            total = total + 1
            koMatch = koMatches[j]
            if result then
            elseif not koMatch.winner then
                eliminated = false
            else
                if koMatch.winner == team.code then
                    result = 'W'
                    matchNo = total
                elseif koMatch.loser == team.code then
                    result = 'L'
                    matchNo = total
                end
            end
        end
        if result then
            cell:css('background-color', colours[result])
                :wikitext(string.format('[[#match%d|%s]]', matchNo, result))
        elseif eliminated then
            cell:css('background-color', elimColour)
        end
    end
end

p.create = function(args, teams, koName, koStages)
    local matches = getMatchData(args, teams)
    local wrapper = mw.html.create('div')

    local codes, results = {}, {}
    local count = 0
    for _, match in ipairs(matches) do
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
        table.insert(results[home], match)
        table.insert(results[away], match)
        count = math.max(count, #results[home], #results[away])
    end
    local teamsort = function(t1, t2)
        return teams[t1].fullName < teams[t2].fullName
    end
    table.sort(codes, teamsort)

    local container = wrapper:tag('div')
        :css('float', 'left')
        :css('max-width', '100%')
    local tbl = container:tag('table')
        :attr('class', 'wikitable')
        :css('width', '100%')
        :css('text-align', 'center')
        :css('display', 'block')
        :css('overflow', 'auto')
        :css('border', 'none')

    -- headers
    local row = tbl:tag('tr')
    row
        :tag('th')
            :attr('scope', 'col')
            :attr('rowspan', '2')
            :css('border-right', 'black solid 2px')
            :wikitext('Team')
        :done()
        :tag('th'):attr('colspan', count):wikitext('Group matches'):done()
    if koStages then
        row:tag('th')
            :attr('colspan', #koStages)
            :css('border-left', 'black solid 2px')
            :wikitext(koName or 'Knockout matches')
    end

    row = tbl:tag('tr')
    for i = 1, count do
        row:tag('th'):attr('scope', 'col'):css('min-width', '18px'):wikitext(i)
    end
    local cell
    for i = 1, #koStages do
        cell = row:tag('th')
            :attr('scope', 'col')
            :css('width', '18px')
            :tag('abbr')
                :attr('title', koStages[i].name)
                :wikitext(koStages[i].abbr)
            :done()
        if i == 1 then cell:css('border-left', 'black solid 2px') end
    end

    -- matches
    for _, code in ipairs(codes) do
        renderTeam(tbl, count, teams[code], results[code], koStages, #matches)
    end

    buildLegend(container)
    wrapper:tag('div'):css('clear', 'left')
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
    local playoffs = {
        { name = 'Qualifier 1 or Eliminator', abbr = 'Q1/E', matches = {
            { winner = args.P1W, loser = args.P1L },
            { winner = args.P2W, loser = args.P2L }
        }},
        { name = 'Qualifier 2', abbr = 'Q2', matches = {
            { winner = args.P3W, loser = args.P3L }
        }},
        { name = 'Final', abbr = 'F', matches = {
            { winner = args.P4W, loser = args.P4L }
        }}
    }
    return p.create(args, teamsAssoc, "Playoffs", playoffs)
end

p.IPL_SF = function(frame)
    local args = getArgs(frame)
    local teams = mw.loadData("Module:Indian Premier League teams")
    local teamsAssoc = {}
    local i = 1
    while teams[i] do
        teamsAssoc[teams[i].code] = teams[i]
        i = i + 1
    end
    local knockout = {
        { name = 'Semi-finals', abbr = 'SF', matches = {
            { winner = args.SF1W, loser = args.SF1L },
            { winner = args.SF2W, loser = args.SF2L }
        }},
        { name = 'Final', abbr = 'F', matches = {
            { winner = args.FW, loser = args.FL }
        }}
    }
    return p.create(args, teamsAssoc, "Knockout", knockout)
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
    local playoffs = {
        { name = 'Eliminator 1 or Qualifier', abbr = 'E1/Q', matches = {
            { winner = args.P1W, loser = args.P1L },
            { winner = args.P2W, loser = args.P2L }
        }},
        { name = 'Eliminator 2', abbr = 'E2', matches = {
            { winner = args.P3W, loser = args.P3L }
        }},
        { name = 'Final', abbr = 'F', matches = {
            { winner = args.P4W, loser = args.P4L }
        }}
    }
    return p.create(args, teamsAssoc, "Playoffs", playoffs)
end

p.PSL_SF = function(frame)
    local args = getArgs(frame)
    local teams = mw.loadData("Module:PakistanSuperLeagueTeams")
    local teamsAssoc = {}
    local i = 1
    while teams[i] do
        teamsAssoc[teams[i].code] = teams[i]
        i = i + 1
    end
    local knockout = {
        { name = 'Semi-finals', abbr = 'SF', matches = {
            { winner = args.SF1W, loser = args.SF1L },
            { winner = args.SF2W, loser = args.SF2L }
        }},
        { name = 'Final', abbr = 'F', matches = {
            { winner = args.FW, loser = args.FL }
        }}
    }
    return p.create(args, teamsAssoc, "Knockout", knockout)
end

return p