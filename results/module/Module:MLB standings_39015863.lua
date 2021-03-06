-- This module copies content from Template:MLB_standings; see the history of that page
-- for attribution.

local me = { }

local mlbData = mw.loadData('Module:MLB standings/data')
local Navbar = require('Module:Navbar')

local defaultOutputForInput = {
    default = 'default',
    overallWinLoss = 'winLossOnly',
}

local readTeamInfo = {
    default = function(args, currentIdx, returnData)
        if (args[currentIdx]   == nil or
            args[currentIdx+1] == nil or
            args[currentIdx+2] == nil or
            args[currentIdx+3] == nil or
            args[currentIdx+4] == nil ) then
            return nil
        end
        teamInfo = {
            name       = mw.text.trim(args[currentIdx]),
            homeWins   = tonumber(mw.text.trim(args[currentIdx+1])),
            homeLosses = tonumber(mw.text.trim(args[currentIdx+2])),
            roadWins   = tonumber(mw.text.trim(args[currentIdx+3])),
            roadLosses = tonumber(mw.text.trim(args[currentIdx+4])),
        }
        returnData.cIndicesRead = 5
        teamInfo.wins = teamInfo.homeWins + teamInfo.roadWins
        teamInfo.losses = teamInfo.homeLosses + teamInfo.roadLosses
        return teamInfo
    end,  -- function readTeamInfo.default()

    overallWinLoss = function(args, currentIdx, returnData)
        if (args[currentIdx]   == nil or
            args[currentIdx+1] == nil or
            args[currentIdx+2] == nil ) then
            return nil
        end
        teamInfo = {
            name   = mw.text.trim(args[currentIdx]),
            wins   = tonumber(mw.text.trim(args[currentIdx+1])),
            losses = tonumber(mw.text.trim(args[currentIdx+2])),
        }
        returnData.cIndicesRead = 3
        return teamInfo
    end,  -- function readTeamInfo.default()

}  -- readTeamInfo object

local generateTableHeader = {
    default = function(tableHeaderInfo)
        return
'{| class="wikitable" width="535em" style="text-align:center;"\
! width="50%" |' .. tableHeaderInfo.navbarText .. '[[' .. tableHeaderInfo.divisionLink
.. '|' .. tableHeaderInfo.division .. ']]\
! width="7%" | [[Win (baseball)|W]]\
! width="7%" | [[Loss (baseball)|L]]\
! width="9%" | [[Winning percentage|Pct.]]\
! width="7%" | [[Games behind|GB]]\
! width="10%" | [[Home (sports)|Home]]\
! width="10%" | [[Road (sports)|Road]]\
'
    end,  -- function generateTableHeader.default()

    winLossOnly = function(tableHeaderInfo)
        return
'{| class="wikitable" width="380em" style="text-align:center;"\
! width="66%" | ' .. tableHeaderInfo.navbarText .. tableHeaderInfo.division .. '\
! width="10%" | [[Win (baseball)|W]]\
! width="10%" | [[Loss (baseball)|L]]\
! width="14%" | [[Winning percentage|Pct.]]\
'
    end,  -- function generateTableHeader.winLossOnlyNoNavBar()

    wildCard2012 = function(tableHeaderInfo)
        return
'{| class="wikitable" width="375em" style="text-align:center;"\
! width="60%" | ' .. tableHeaderInfo.navbarText .. 'Wild Card teams<br><small>(Top two qualify for postseason)</small>\
! width="8%" | [[Win (baseball)|W]]\
! width="8%" | [[Loss (baseball)|L]]\
! width="12%" | [[Winning percentage|Pct.]]\
! width="12%" | [[Games behind|GB]]\
'
    end,  -- function generateTableHeader.wildCard2012
}  -- generateTableHeader object

local generateTeamRow = {
    default = function(teamRowInfo, teamInfo)
        return
'|-' .. teamRowInfo.rowStyle .. '\
|| ' .. teamRowInfo.seedText .. '[[' .. teamRowInfo.teamSeasonPage .. '|' .. teamInfo.name .. ']]\
|| ' .. teamInfo.wins .. ' || ' .. teamInfo.losses .. '\
|| ' .. teamRowInfo.winningPercentage .. '\
|| ' .. teamRowInfo.gamesBehind .. '\
|| ' .. teamInfo.homeWins .. '–' .. teamInfo.homeLosses ..'\
|| ' .. teamInfo.roadWins .. '–' .. teamInfo.roadLosses .. '\n'

    end,  -- function generateTeamRow.default()

    winLossOnly = function(teamRowInfo, teamInfo)
        return
'|-' .. teamRowInfo.rowStyle .. '\
|| ' .. teamRowInfo.seedText .. '[[' .. teamRowInfo.teamSeasonPage .. '|' .. teamInfo.name .. ']]\
|| ' .. teamInfo.wins .. ' || ' .. teamInfo.losses .. '\
|| ' .. teamRowInfo.winningPercentage .. '\n'
    end,  -- function generateTeamRow.winLossOnly

    wildCard2012 = function(teamRowInfo, teamInfo)
        return
'|-' .. teamRowInfo.rowStyle .. '\
|| ' .. teamRowInfo.seedText .. '[[' .. teamRowInfo.teamSeasonPage .. '|' .. teamInfo.name .. ']]\
|| ' .. teamInfo.wins .. ' || ' .. teamInfo.losses .. '\
|| ' .. teamRowInfo.winningPercentage .. '\
|| ' .. teamRowInfo.gamesBehind .. '\n'
    end,  -- function generateTeamRow.wildCard2012
}   -- generateTeamRow object

local function parseSeeds(seedsArg, seeds)
    local seedList = mw.text.split(seedsArg, '%s*,%s*')
    if (#seedList == 0) then
        return
    end

    for idx, seed in ipairs(seedList) do
        local seedData = mw.text.split(seed, '%s*:%s*')
        if (#seedData >= 2) then
            local seedNumber = tonumber(mw.text.trim(seedData[1]))
            local team = mw.text.trim(seedData[2])
            seeds[seedNumber] = team
            seeds[team] = seedNumber
        end
    end
end  -- function parseSeeds()

local function parseHighlightArg(highlightArg, teamsToHighlight)
    local teamList = mw.text.split(highlightArg, '%s*,%s*')
    if (#teamList == 0) then
        return
    end

    for idx, team in ipairs(teamList) do
        teamsToHighlight[mw.text.trim(team)] = true
    end

end  -- function parseHighlightArg

local function parseTeamLinks(teamLinksArg, linkForTeam)
    local teamList = mw.text.split(teamLinksArg, '%s*,%s*')
    if (#teamList == 0) then
        return
    end

    for idx, teamLinkInfo in ipairs(teamList) do
        local teamData = mw.text.split(teamLinkInfo, '%s*:%s*')
        if (#teamData >= 2) then
            local team = mw.text.trim(teamData[1])
            local teamLink = mw.text.trim(teamData[2])
            linkForTeam[team] = teamLink
        end
    end
end  -- function parseTeamLinks

function me.generateStandingsTable(frame)
    local inputFormat = 'default'
    if (frame.args.input ~= nil) then
        local inputArg = mw.text.trim(frame.args.input)
        if (inputArg == 'overallWinLoss') then
            inputFormat = 'overallWinLoss'
        end
    end

    local templateName = nil
    if (frame.args.template_name ~= nil) then
        templateName = frame.args.template_name
    end

    local outputFormat = defaultOutputForInput[inputFormat]
    local fDisplayNavbar = true
    local fDisplayGamesBehind = true
    if (frame.args.output ~= nil) then
        local outputArg = mw.text.trim(frame.args.output)
        if (outputArg == 'winLossOnly') then
            outputFormat = 'winLossOnly'
            fDisplayGamesBehind = false
        end
        if (outputArg == 'wildCard2012') then
            outputFormat = 'wildCard2012'
        end
    end

    local year = mw.text.trim(frame.args.year or '')
    local division = mw.text.trim(frame.args.division or '')
    local divisionLink = mw.text.trim(frame.args.division_link or division)

    local seedInfo = {}
    if (frame.args.seeds ~= nil) then
        parseSeeds(frame.args.seeds, seedInfo)
    end

    local teamsToHighlight = {}
    if (frame.args.highlight ~= nil) then
        parseHighlightArg(frame.args.highlight, teamsToHighlight)
    end

    local linkForTeam = {}
    if (frame.args.team_links ~= nil) then
        parseTeamLinks(frame.args.team_links, linkForTeam)
    end

    local listOfTeams = {};
    local currentArgIdx = 1;

    while (frame.args[currentArgIdx] ~= nil) do
        local returnData = { }
        local teamInfo = readTeamInfo[inputFormat](frame.args, currentArgIdx, returnData);
        if (teamInfo == nil) then
            break
        end
        if (linkForTeam[teamInfo.name] ~= nil) then
            teamInfo.teamLink = linkForTeam[teamInfo.name]
        else
            teamInfo.teamLink = teamInfo.name
        end
        table.insert(listOfTeams, teamInfo)
        currentArgIdx = currentArgIdx + returnData.cIndicesRead
    end

    if (#listOfTeams == 0) then
        return ''
    end

    local outputBuffer = { }

    local tableHeaderInfo = {
        division = division,
        divisionLink = divisionLink,
    }

    if (fDisplayNavbar) then
        local divisionForNavbox = division
        if (mlbData.abbreviationForDivision[division] ~= nil) then
            divisionForNavbox = mlbData.abbreviationForDivision[division]
        end

        local standingsPage
        if (templateName ~= nil) then
            standingsPage = templateName
        else
            standingsPage = year .. ' ' .. divisionForNavbox .. ' standings'
        end
        tableHeaderInfo.navbarText =
            Navbar.navbar({
                standingsPage,
                mini = 1,
                style = 'float:left;width:0;',
            })
    end

    table.insert(outputBuffer,
        generateTableHeader[outputFormat](tableHeaderInfo)
    )

    local leadingHalfGames = nil;
    if (fDisplayGamesBehind) then
        local standingsLeaderIdx = 1;
        if (outputFormat == 'wildCard2012' and #listOfTeams > 1) then
            standingsLeaderIdx = 2;
        end
        local teamInfo = listOfTeams[standingsLeaderIdx]
        leadingHalfGames = (teamInfo.wins - teamInfo.losses)
    end

    for idx, teamInfo in ipairs(listOfTeams) do
        local teamRowInfo = {
            teamSeasonPage = year .. ' ' .. teamInfo.teamLink .. ' season',
            winningPercentage = string.format(
                '%.3f', teamInfo.wins / ( teamInfo.wins + teamInfo.losses )
            ),
            gamesBehind = '',
            seedText = '',
            rowStyle = '',
        }

        if (fDisplayGamesBehind) then
            local halfGamesBehind = leadingHalfGames - (teamInfo.wins - teamInfo.losses)
            local prefix = nil
            -- if games behind is negative, take the absolute value and prefix a +
            -- character
            if (halfGamesBehind < 0) then
                halfGamesBehind = -halfGamesBehind
                prefix = '+'
            end
            if (halfGamesBehind == 0) then
                teamRowInfo.gamesBehind = '—'
            else  -- if halfGamesBehind is not 0
                teamRowInfo.gamesBehind = math.floor(halfGamesBehind / 2)
                if (halfGamesBehind % 2 == 1) then
                    if (halfGamesBehind == 1) then
                        teamRowInfo.gamesBehind = '½'
                    else
                        teamRowInfo.gamesBehind = teamRowInfo.gamesBehind .. '½'
                    end
                end
                if ( prefix ~= nil ) then
                    teamRowInfo.gamesBehind = prefix .. teamRowInfo.gamesBehind
                end
            end  -- if halfGamesBehind is not 0
        end  -- if (fDisplayGamesBehind)

        if (seedInfo[teamInfo.name] ~= nil) then
            teamRowInfo.seedText = '<sup>(' .. seedInfo[teamInfo.name] .. ')</sup> '
            teamRowInfo.rowStyle = ' style="background:#CCFFCC"'
        end

        if (teamsToHighlight[teamInfo.name]) then
            teamRowInfo.rowStyle =  ' style="background:#CCFFCC"'
        end

        table.insert(outputBuffer,
            generateTeamRow[outputFormat](teamRowInfo, teamInfo)
        )
    end  -- end of looping over listOfTeams

    table.insert(outputBuffer, '|}')

    return table.concat(outputBuffer)

end  -- function me.generateStandingsTable()

function me.generateStandingsTable_fromTemplate(frame)
    return me.generateStandingsTable(frame:getParent())
end  -- function me.generateStandingsTable_fromTemplate()

return me