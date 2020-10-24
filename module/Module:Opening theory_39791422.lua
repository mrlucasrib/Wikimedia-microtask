local p = {}
function p.pgn_links_wikibooks(frame)
    local args = frame.args
    local pargs = frame:getParent().args
    local pgn = args.pgn or args[1] or pargs.pgn or pargs[1]
    if not pgn then return "" end
    --fix possible castling syntax discrepancy
    pgn = string.gsub(pgn, '0%-0%-0', 'O-O-O')
    pgn = string.gsub(pgn, '0%-0', 'O-O')
    local movestrip = "[!?+#%s]" --filter checks, mates, and value judgments out of wbooks page-link
    local linky = "[[%s|%s]]"
    local wb_page = 'wikibooks:Chess Opening Theory'
    local turn_n = 1
    local lines = {}
    local turns = mw.text.split(pgn, '%s*%d+%.%s*')
    for k1, v1 in pairs(turns) do
        if string.match(v1, '%S') then --ignore blank lines
            local moves = mw.text.split(v1, "%s+")
            local whitemove = string.gsub(moves[1], movestrip, "")
            wb_page = string.format("%s/%s. %s", wb_page, turn_n, whitemove)
            local tmp = string.format(linky, wb_page, moves[1])
            if moves[2] then
                local blackmove = string.gsub(moves[2], movestrip, "")
                wb_page = string.format("%s/%s...%s", wb_page, turn_n, blackmove)
                tmp = tmp .. " " .. string.format(linky, wb_page, moves[2])
            end
            table.insert(lines, "# " .. tmp)
            turn_n = turn_n + 1
        end
    end
    return table.concat(lines, "\n")
end

return p