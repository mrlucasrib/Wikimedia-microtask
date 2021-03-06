local p = {}

function chessboard(args, size, rows, cols, rev, trans, lightdark, altprefix, letters, numbers, header, footer, align, clear)
    function colchar( col )
        return (col <= 26) and ( "abcdefghijklmnopqrstuvwxyz" ):sub( col, col ) 
        	or ( "abcdefghijklmnopqrstuvwxyz" ):sub( math.floor((col-1)/26), math.floor((col-1)/26) ) 
        		.. ( "abcdefghijklmnopqrstuvwxyz" ):sub( col-math.floor((col-1)/26)*26, col-math.floor((col-1)/26)*26)
    end
    function image_square( pc, row, col, size, t, flip, altprefix )
        local colornames = { l = 'white', d = 'black', u = 'unknown color' }
        local piecenames = { 
            p = 'pawn', 
            r = 'rook', 
            n = 'knight', 
            b = 'bishop', 
            q = 'queen', 
            k = 'king', 
            a = 'princess',
            c = 'empress', 
            z = 'champion', 
            w = 'wizard', 
            t = 'fool', 
            h = 'upside-down pawn', 
            m = 'upside-down rook', 
            s = 'upside-down knight', 
            f = 'upside-down king',  
            e = 'upside-down bishop', 
            g = 'upside-down queen',
            G = 'giraffe',
            U = 'unicorn',
            Z = 'zebra'
            }
        local symnames = { 
            xx = 'black cross', 
            ox = 'white cross', 
            xo = 'black circle', 
            oo = 'white circle',
            ul = 'up-left arrow', 
            ua = 'up arrow', 
            ur = 'up-right arrow', 
            la = 'left arrow', 
            ra = 'right arrow',
            dl = 'down-left arrow', 
            da = 'down arrow', 
            dr = 'down-right arrow', 
            lr = 'left-right arrow', 
            ud = 'up-down arrow',
            db = 'up-right and down-left arrow',
            dw = 'up-left and down-right arrow',
            x0 = 'zero', 
            x1 = 'one', 
            x2 = 'two', 
            x3 = 'three', 
            x4 = 'four', 
            x5 = 'five', 
            x6 = 'six', 
            x7 = 'seven', 
            x8 = 'eight', 
            x9 = 'nine'
        }
        local color = mw.ustring.gsub( pc, '^.*(%w)(%w).*$', '%2' ) or ''
        local piece = mw.ustring.gsub( pc, '^.*(%w)(%w).*$', '%1' ) or ''
        local alt = altprefix .. colchar( col ) .. row .. ' '
        if ( colornames[color] and piecenames[piece] ) then
            alt = alt .. colornames[color] .. ' ' .. piecenames[piece]
        else
            alt = alt .. ( symnames[piece .. color] or piece .. ' ' .. color )
        end
        local ld = t and 't' or ((((row + col + flip) % 2) == 0) and 'd' or 'l')
        
        return string.format( '[[File:Chess %s%s%s45.svg|%dx%dpx|alt=%s|%s]]', piece, color, ld, size, size, alt, alt )
    end

    function letters_row( rev, num_lt, num_rt, cols )
        local res = '<tr style="vertical-align:middle">' .. ( num_lt and '<td style="padding:0; vertical-align:inherit"></td>' or '' ) .. '<td style="padding:0; vertical-align:inherit; height:18px">'
        for k = 1, cols do
            res = res .. colchar(rev and (cols - k + 1) or k) .. '</td><td style="padding:0; vertical-align:inherit">'
        end
        res = res .. '</td>' .. ( num_lt and '<td style="padding:0; vertical-align:inherit"></td>' or '' ) .. '</tr>'
        return res
    end
    local letters_tp = letters:match('both') or letters:match('top')
    local letters_bt = letters:match('both') or letters:match('bottom')
    local numbers_lt = numbers:match('both') or numbers:match('left')
    local numbers_rt = numbers:match('both') or numbers:match('right')
    local width = cols * size + 2
    local flip = lightdark and 1 or 0
    if ( numbers_lt ) then width = width + 18 end
    if ( numbers_rt ) then width = width + 18 end

    local b = ''
    local caption = ''

    if ( letters_tp ) then b = b .. letters_row(rev, numbers_lt, numbers_rt, cols) .. '\n' end
    for trow = 1,rows do
        local row = rev and trow or (rows - trow + 1)
        b = b .. '<tr style="vertical-align:middle">'
        if ( numbers_lt ) then b = b .. '<td style="padding:0; vertical-align:inherit; width:18px">' .. row .. '</td>' end
        for tcol = 1,cols do
            local col = rev and (cols - tcol + 1) or tcol
            local idx = cols*(rows - row) + col + 2
            if (args[idx] == nil) then args[idx] = '  ' end
            local img = image_square(args[idx]:match('%w%w') or '', row, col, size, trans, flip, altprefix )
            local bg = (((trow + tcol + flip) % 2) == 0) and '#ffce9e' or '#d18b47'
            b = b .. '<td style="padding:0; vertical-align:inherit; background-color: ' .. bg .. ';">' .. img .. '</td>'
        end
        if ( numbers_rt ) then b = b .. '<td style="padding:0; vertical-align:inherit; width:18px">' .. row .. '</td>' end
        b = b .. '</tr>'
    end
    if ( letters_bt ) then b = b .. letters_row(rev, numbers_lt, numbers_rt, cols) .. '\n' end

    if footer:match('^%s*$')
    then
    else    
        caption = '<div class="thumbcaption">' .. footer .. '</div>\n'
    end
    b = '<table cellpadding=0 cellspacing=0 style="line-height: 0; background:white; font-size:88%; border:1px #b0b0b0 solid;'
        .. 'padding:0; margin:auto">\n' .. b .. '\n</table>'

    if noframe then
        return b
    else
        return '<div class="thumb ' .. align .. '" style="clear:' .. clear .. '; text-align:center;">'
        .. header .. '\n<div class="thumbinner" style="width:' .. width .. 'px;">\n' 
        .. b .. '\n' .. caption .. '</div></div>'
    end
    
end

function convertFenToArgs( fen )
    -- converts FEN notation to an array of positions, offset by 2
    local res = {' ', ' '}
    -- Loop over rows, which are delimited by /
    for srow in string.gmatch("/" .. fen, "/%w+") do
        -- Loop over all letters and numbers in the row
        for piece in srow:gmatch( "%w" ) do
            if (piece:match("%d")) then
                -- if a digit
                for k=1,piece do
                    table.insert(res,' ')
                end
            else 
                -- not a digit
                local color = piece:match( '%u' ) and 'l' or 'd'
                piece = piece:lower()
                table.insert(res, piece .. color )
            end
        end
    end

    return res
end

function p.board(frame)
    local args = frame.args
    local pargs = frame:getParent().args
    local size = (args.size or pargs.size) or '26'
    local reverse = (args.reverse or pargs.reverse or '' ):lower() == "true"
    local trans = (args.transparent or pargs.transparent or '' ):lower() == "true"
    local lightdark = (args.lightdark or pargs.lightdark or '' ):lower() == "swap"
    local altprefix = args.altprefix or pargs.altprefix or ''
    local rows = args.rows or pargs.rows or 8
    local cols = args.cols or pargs.cols or 8
    local letters = ( args.letters or pargs.letters or 'both' ):lower() 
    local numbers = ( args.numbers or pargs.numbers or 'both' ):lower() 
    local header =  mw.ustring.gsub( args[2] or pargs[2] or '', '^%s*(.-)%s*$', '%1' )
    local footer = args[3 + rows*cols] or pargs[3 + rows*cols] or ''
    local align = ( args[1] or pargs[1] or 'tright' ):lower()
    local clear = ( args.clear or pargs.clear ) or ( align:match('tright') and 'right' or 'none' )
    local noframe = (args.noframe or pargs.noframe or ''):lower() == "true"
    local fen = args.fen or pargs.fen

    size = mw.ustring.match(size, '[%d]+') or '26' -- remove px from size
    if (fen) then
        align = ( args.align or pargs.align or 'tright' ):lower()
        clear = ( args.clear or pargs.clear ) or ( align:match('tright') and 'right' or 'none' )
        header = args.header or pargs.header or ''
        footer = args.footer or pargs.footer or ''
        return chessboard(convertFenToArgs( fen ), size, rows, cols, reverse, trans, lightdark, altprefix, letters, numbers, header, footer, align, clear, noframe)
    end
    if args[3] then
        return chessboard(args, size, rows, cols, reverse, trans, lightdark, altprefix, letters, numbers, header, footer, align, clear, noframe)
    else
        return chessboard(pargs, size, rows, cols, reverse, trans, lightdark, altprefix, letters, numbers, header, footer, align, clear, noframe)
    end
    
end

return p