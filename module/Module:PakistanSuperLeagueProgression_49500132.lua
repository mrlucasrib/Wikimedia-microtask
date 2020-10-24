--[[
    Module for generating league progresion tables intended for use in Pakistan Super League season articles.
]]

local _module = {}

_module.create = function(frame)
    
    ------------- Functions -------------
    local strFind = string.find
    local strMatch = string.match
    local strSplit = mw.text.split
    local strFormat = string.format
    local strTrim = mw.text.trim
    local strSub = string.sub
    local strRepeat = string.rep
    local strUpper = string.upper
    
    ------------- Arguments -------------
    local args = frame.args
    local matchesPerTeam = tonumber(args.matchesPerTeam) or error("Invalid or missing parameter 'matchesPerTeam'")
    local ktype = tonumber(args.knockoutType) or error("Invalid or missing parameter 'knockoutType'")
    local teams = strSplit(args.teams or error("Invalid or missing parameter 'knockoutType'"), ',', true)
    local matchReportArticle = args.matchReportArticle or ''
    local caption = args.caption

    -- The colours for each result
    local colours_win           = "#99FF99"   -- Win
    local colours_loss          = "#FFDDDD"   -- Loss
    --local colours_tie           = ""
    local colours_noResult      = "#DFDFFF"   -- No result
    local colours_eliminated    = "#DCDCDC"   -- Eliminated
    local colours_notPossible   = "#DCDCDC"   -- Not technically possible (only used for some playoff matches with knockoutType=2)
    
    -- The CSS classes applied to the cells of each result
    local classes_win       = "yes table-yes2"
    local classes_loss      = "no table-no2"
    local classes_noResult  = "noresult"
    --local classes_tie       = ""
    
    -- The output buffer
    local output = {}
    local outputIndex = 1
    function print(s)
        output[outputIndex] = s
        outputIndex = outputIndex + 1
    end
    
    local kMatches = ({ 2, 3 }) [ktype]
    if not kMatches then
        error("Invalid knockout type: " .. ktype)
    end
    
    
    -- Construct the header
    print(strFormat([[
{| class="wikitable" style="text-align: center"%s
! scope="col" rowspan="2" | Team
! colspan="%d" style="border-left: 4px solid #454545" | Group matches
! colspan="%d" style="border-left: 4px solid #454545" | Playoffs
|-
]],
    caption and '\n|+' .. caption or '', matchesPerTeam, kMatches))
    
    for i = 1, matchesPerTeam do
        -- Generate the headers for each group match
        print(strFormat('! scope="col" style="width: 30px;%s" | %d\n', i == 1 and " border-left: 4px solid #454545" or "", i))
    end
    
    --[[
        Headers specific to each knockout type
    ]]
    
    local knockoutHeaders = {
    -- Knockout type 1 (used from 2008 to 2010)
[[
! scope="col" style="width: 32px; border-left: 4px solid #454545" | <abbr title="Semi-final">SF</abbr>
! scope="col" style="width: 32px" | <abbr title="Final">F</abbr>]],
    -- Knockout type 2
[[
! scope="col" style="width: 32px; border-left: 4px solid #454545" | <abbr title="Qualifier 1 or Eliminator">Q1/E</abbr>
! scope="col" style="width: 32px" | <abbr title="Qualifier 2">Q2</abbr>
! scope="col" style="width: 32px" | <abbr title="Final">F</abbr>]]
    
    }
    print(knockoutHeaders[ktype])
    
    local argCounter = 1
    
    -- Generate the table
    for i = 1, #teams do
    
        local team = strTrim(teams[i])
        print('\n|-\n! scope="row" style="text-align: left; padding-right: 10px" | [[' .. team .. ']]\n')   -- Add the team name
        local gs, ks = args[argCounter] or '', args[argCounter + 1] or ''
        local j, comma, runningScore, lastMatch = 0, 0, 0, 0
        argCounter = argCounter + 2
        
        repeat
            j = j + 1
            if j > matchesPerTeam then
                error(strFormat("Too many group stage matches. Expected %d (team: %s)", matchesPerTeam, team))
            end
            
            local startPos = comma + 1
            comma = strFind(gs, ',', startPos, true) or 0
            
            print(j == 1 and '| style="border-left: 4px solid #454545; ' or '|| style="')
            
            local rpos = strFind(gs, '%S', startPos)
            if rpos and (rpos < comma or comma == 0) then
                local result, match = strUpper(strSub(gs, rpos, rpos)), tonumber(strMatch(strSub(gs, rpos + 1, comma - 1), '^(.-)%s*$'))

                -- Check that the match number is a valid non-negative integer greater than the preceding match number.
                if not match or match <= 0 or match % 1 ~= 0 then
                    error(strFormat("Match number does not exist or is not a valid integer greater than 0 for group stage result #%d (team: %s)", j, team))
                elseif match <= lastMatch then
                    error(strFormat("Invalid match number: %d for group stage result #%d, must be greater than the preceding match number (%d) (team: %s)", match, j, lastMatch, team))
                end
                lastMatch = match
                
                if result == 'W' then    -- Win
                    runningScore = runningScore + 2
                    print(strFormat('background-color: %s" class="%s" | [[%s#match%s|%d]] ', colours_win, classes_win, matchReportArticle, match, runningScore))
                elseif result == 'L' then     -- Loss
                    print(strFormat('background-color: %s" class="%s" | [[%s#match%s|%d]] ', colours_loss, classes_loss, matchReportArticle, match, runningScore))
                elseif result == 'N' then     -- No result
                    runningScore = runningScore + 1
                    print(strFormat('background-color: %s" class="%s" | [[%s#match%s|%d]] ', colours_noResult, classes_noResult, matchReportArticle, match, runningScore))
                --elseif result == 'T' then     -- Tie
                --    runningScore = runningScore + 1
                --    print(strFormat('background-color: %s" class="%s" | [[%s#match%s|%d]] ', colours_tie, classes_tie, matchReportArticle, match, runningScore))
                else
                    error(strFormat("Invalid group stage result #%d: '%s', expecting 'W', 'L', 'N', or 'T' as first character (team: %s)", j, result, team))
                end
            else
                -- Result not given
                print('" | ')
            end
        until comma == 0
        if j ~= matchesPerTeam then    -- Output empty cells for the remaining matches
            print(strRepeat('|| ', matchesPerTeam - j))
        end
        
        j, comma = 0, 0

        repeat
            j = j + 1
            if j > kMatches then
                error(strFormat("Too many playoff stage matches. Expected %d (team: %s)", kMatches, team))
            end
            
            local startPos = comma + 1
            comma = strFind(ks, ',', startPos, true) or 0
            
            print(j == 1 and '|| style="border-left: 4px solid #454545; ' or '|| style="')
            
            local rpos = strFind(ks, '%S', startPos)
            if rpos and (rpos < comma or comma == 0) then
                local result, match = strUpper(strSub(ks, rpos, rpos)), tonumber(strMatch(strSub(ks, rpos + 1, comma - 1), '^(.-)%s*$'))
                
                if result == 'E' then
                    if comma ~= 0 then
                        error("The result 'E' must be the last result in the playoff stage result list. (team: " .. team ..")")
                    end
                    print(strFormat('background-color: %s" colspan="%d" | ', colours_eliminated, kMatches - j + 1))
                    j = kMatches    -- To avoid printing empty cells for the remaining matches
                    break
                elseif result == 'U' then
                    print('background-color: ' .. colours_notPossible .. '" | ')
                else
                    if not match or match < 0 or match % 1 ~= 0 then
                        error(strFormat("Match number does not exist or is invalid for playoff stage result #%d (team: %s)", j, team))
                    elseif match <= lastMatch then
                        error(strFormat("Invalid match number: %d for group stage result #%d, must be greater than the preceding match number (%d) (team: %s)", match, j, lastMatch, team))
                    end
                    
                    lastMatch = match
                    
                    if result == 'W' then
                        print(strFormat('background-color: %s" class="%s" | [[%s#match%s|W]] ', colours_win, classes_win, matchReportArticle, match))
                    elseif result == 'L' then
                        print(strFormat('background-color: %s" class="%s" | [[%s#match%s|L]] ', colours_loss, classes_loss, matchReportArticle, match))
                    elseif result == 'N' then
                        print(strFormat('background-color: %s" class="%s" | [[%s#match%s|N]] ', colours_noResult, classes_noResult, matchReportArticle, match))
                    --elseif result == 'T' then
                    --    print(strFormat('background-color: %s" class="%s" | [[%s#match%s|T]] ', colours_tie, classes_tie, matchReportArticle, match))
                    else
                        error(strFormat("Invalid group stage result #%d: '%s', expecting 'W', 'L', 'N', ', 'E' or 'U' as first character (team: %s)", j, result, team))
                    end
                end
            else
                -- Result not given
                print('" | ')
            end
        until comma == 0
        if j ~= kMatches then    -- Output empty cells for the remaining matches
            print(strRepeat('|| ', kMatches - j))
        end
        
    end
    
    -- Footer
    print(strFormat([[

|}
{| class="wikitable" style="float: right; width: 20%%; text-align: center; font-size: 90%%"
| class="%s" style="background-color: %s" | Win
| class="%s" style="background-color: %s" | Loss
| class="%s" style="background-color: %s" | No result
|}

<ul style="font-size: 90%%">
<li>'''Note''': The total points at the end of each group match are listed.</li>
<li>'''Note''': Click on the points (group matches) or W/L (playoffs) to see the match summary.</li>
</ul>]],
    classes_win, colours_win, classes_loss, colours_loss, classes_noResult, colours_noResult))
    
    return table.concat(output)
    
end

return _module