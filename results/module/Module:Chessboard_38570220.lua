local p = {}

local function image_square( pc, row, col, size )
	local colornames = { l = 'white', d = 'black', u = 'unknown color' }
	local piecenames = { 
		p = 'pawn',
		r = 'rook',
		n = 'knight',
		b = 'bishop',
		q = 'queen',
		k = 'king',
		a = 'archbishop',
		c = 'chancellor',
		z = 'champion',
		w = 'wizard',
		t = 'fool',
		M = 'mann',
		h = 'upside-down pawn',
		m = 'upside-down rook',
		B = 'upside-down bishop',
		N = 'upside-down knight',
		f = 'upside-down king',
		g = 'upside-down queen',
		e = 'elephant',
		s = 'boat',
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
	local colchar = {'a','b','c','d','e','f','g','h'}
	local color = mw.ustring.gsub( pc, '^.*(%w)(%w).*$', '%2' ) or ''
	local piece = mw.ustring.gsub( pc, '^.*(%w)(%w).*$', '%1' ) or ''
	local alt = colchar[col] .. row .. ' '
	
	if colornames[color] and piecenames[piece] then
		alt = alt .. colornames[color] .. ' ' .. piecenames[piece]
	else
		alt = alt .. ( symnames[piece .. color] or piece .. ' ' .. color )
	end

	return string.format( '[[File:Chess %s%st45.svg|%dx%dpx|alt=%s|%s|link=]]', piece, color, size, size, alt, alt )

end
	
local function innerboard(args, size, rev)
	local root = mw.html.create('div')
	root:addClass('chess-board')
		:css('position', 'relative')
		:wikitext(string.format( '[[File:Chessboard480.svg|%dx%dpx|link=]]', 8 * size, 8 * size ))
	
	for trow = 1,8 do
		local row = rev and trow or ( 9 - trow )
		for tcol = 1,8 do
			local col = rev and ( 9 - tcol ) or tcol
			local piece = args[8 * ( 8 - row ) + col + 2] or ''
			if piece:match( '%w%w' ) then
				local img = image_square(piece:match('%w%w'), row, col, size )
				root:tag('div')
					:css('position', 'absolute')
					:css('z-index', '3')
					:css('top', tostring(( trow - 1 ) * size) .. 'px')
					:css('left', tostring(( tcol - 1 ) * size) .. 'px')
					:css('width', size .. 'px')
					:css('height', size .. 'px')
					:wikitext(img)
			end
		end
	end

	return tostring(root)
end

function chessboard(args, size, rev, letters, numbers, header, footer, align, clear)
	function letters_row( rev, num_lt, num_rt )
		local letters = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'}
		local root = mw.html.create('')
		if num_lt then
			root:tag('td')
				:css('vertical-align', 'inherit')
				:css('padding', '0')
		end
		for k = 1,8 do
			root:tag('td')
				:css('padding', '0')
				:css('vertical-align', 'inherit')
				:css('text-align', 'center')
				:css('height', '18px')
				:css('width', size .. 'px')
				:wikitext(rev and letters[9-k] or letters[k])
		end
		if num_rt then
			root:tag('td')
				:css('vertical-align', 'inherit')
				:css('padding', '0')
		end
		return tostring(root)
	end
	
	local letters_tp = letters:match( 'both' ) or letters:match( 'top' )
	local letters_bt = letters:match( 'both' ) or letters:match( 'bottom' )
	local numbers_lt = numbers:match( 'both' ) or numbers:match( 'left' )
	local numbers_rt = numbers:match( 'both' ) or numbers:match( 'right' )
	local width = 8 * size + 2
	if ( numbers_lt ) then width = width + 18 end
	if ( numbers_rt ) then width = width + 18 end

	local root = mw.html.create('div')
		:addClass('thumb')
		:addClass(align)
		:css('clear', clear)
		:css('text-align', 'center')
		:css('max-width', (width + 8) .. 'px')
	if( header and header ~= '' ) then
		root:tag('div'):css('line-height', '130%'):wikitext(header)
	end
	local div = root:tag('div')
		:addClass('thumbinner')
		:css('width', width .. 'px')
	local b = div:tag('table')
		:attr('cellpadding', '0')
		:attr('cellspacing', '0')
		:css('background', 'white')
		:css('font-size', '88%')
		:css('border' , '1px #b0b0b0 solid')
		:css('padding', '0')
		:css('margin', 'auto')

	if ( letters_tp ) then
		b:tag('tr')
			:css('vertical-align', 'middle')
			:wikitext(letters_row( rev, numbers_lt, numbers_rt ))
	end
	local tablerow = b:tag('tr'):css('vertical-align','middle')
	if ( numbers_lt ) then 
		tablerow:tag('td')
			:css('padding', '0')
			:css('vertical-align', 'inherit')
			:css('text-align', 'center')
			:css('width', '18px')
			:css('height', size .. 'px')
			:wikitext(rev and 1 or 8) 
	end
	local td = tablerow:tag('td')
		:attr('colspan', 8)
		:attr('rowspan', 8)
		:css('padding', '0')
		:css('vertical-align', 'inherit')
		:wikitext(innerboard(args, size, rev))
	
	if ( numbers_rt ) then 
		tablerow:tag('td')
			:css('padding', '0')
			:css('vertical-align', 'inherit')
			:css('text-align', 'center')
			:css('width', '18px')
			:css('height', size .. 'px')
			:wikitext(rev and 1 or 8) 
	end
	if ( numbers_lt or numbers_rt ) then
		for trow = 2, 8 do
			local idx = rev and trow or ( 9 - trow )
			tablerow = b:tag('tr')
				:css('vertical-align', 'middle')
			if ( numbers_lt ) then 
				tablerow:tag('td')
					:css('padding', '0')
					:css('vertical-align', 'inherit')
					:css('text-align', 'center')
					:css('height', size .. 'px')
					:wikitext(idx)
			end
			if ( numbers_rt ) then 
				tablerow:tag('td')
					:css('padding', '0')
					:css('vertical-align', 'inherit')
					:css('text-align', 'center')
					:css('height', size .. 'px')
					:wikitext(idx)
			end
		end
	end
	if ( letters_bt ) then
		b:tag('tr')
			:css('vertical-align', 'middle')
			:wikitext(letters_row( rev, numbers_lt, numbers_rt ))
	end

	if (footer and footer ~= '') then
		div:tag('div')
			:addClass('thumbcaption')
			:wikitext(footer)
	end

	return tostring(root)
end

function convertFenToArgs( fen )
	-- converts FEN notation to 64 entry array of positions, offset by 2
	local res = { ' ', ' ' }
	-- Loop over rows, which are delimited by /
	for srow in string.gmatch( "/" .. fen, "/%w+" ) do
		-- Loop over all letters and numbers in the row
		for piece in srow:gmatch( "%w" ) do
			if piece:match( "%d" ) then -- if a digit
				for k=1,piece do
					table.insert(res,' ')
				end
			else -- not a digit
				local color = piece:match( '%u' ) and 'l' or 'd'
				piece = piece:lower()
				table.insert( res, piece .. color )
			end
		end
	end

	return res
end

function convertArgsToFen( args, offset )
	function nullOrWhitespace( s ) return not s or s:match( '^%s*(.-)%s*$' ) == '' end
	function piece( s ) 
		return nullOrWhitespace( s ) and 1
		or s:gsub( '%s*(%a)(%a)%s*', function( a, b ) return b == 'l' and a:upper() or a end )
	end
	
	local res = ''
	offset = offset or 0
	for row = 1, 8 do
		for file = 1, 8 do
			res = res .. piece( args[8*(row - 1) + file + offset] )
		end
		if row < 8 then res = res .. '/' end
	end
	return mw.ustring.gsub(res, '1+', function( s ) return #s end )
end

function p.board(frame)
	local args = frame.args
	local pargs = frame:getParent().args
	local size = args.size or pargs.size or '26'
	local reverse = ( args.reverse or pargs.reverse or '' ):lower() == "true"
	local letters = ( args.letters or pargs.letters or 'both' ):lower() 
	local numbers = ( args.numbers or pargs.numbers or 'both' ):lower() 
	local header = args[2] or pargs[2] or ''
	local footer = args[67] or pargs[67] or ''
	local align = ( args[1] or pargs[1] or 'tright' ):lower()
	local clear = args.clear or pargs.clear or ( align:match('tright') and 'right' ) or 'none'
	local fen = args.fen or pargs.fen
		
	size = mw.ustring.match( size, '[%d]+' ) or '26' -- remove px from size
	if (fen) then
		align = args.align or pargs.align or 'tright'
		clear = args.clear or pargs.clear or ( align:match('tright') and 'right' ) or 'none'
		header = args.header or pargs.header or ''
		footer = args.footer or pargs.footer or ''
		return chessboard( convertFenToArgs( fen ), size, reverse, letters, numbers, header, footer, align, clear )
	end
	if args[3] then
		return chessboard(args, size, reverse, letters, numbers, header, footer, align, clear)
	else
		return chessboard(pargs, size, reverse, letters, numbers, header, footer, align, clear)
	end
end

function p.fen2ascii(frame)
	-- {{#invoke:Chessboard|fen2ascii|fen=...}}
	local b = convertFenToArgs( frame.args.fen )
	local res = '|=\n'
	local offset = 2
	for row = 1,8 do
		local n = (9 - row)
		res = res .. n .. ' |' .. 
			table.concat(b, '|', 8*(row-1) + 1 + offset, 8*(row-1) + 8 + offset) .. '|=\n'
	end
	res = mw.ustring.gsub( res,'\| \|', '|  |' )
	res = mw.ustring.gsub( res,'\| \|', '|  |' )
	res = res .. '   a  b  c  d  e  f  g  h'
	return res
end

function p.ascii2fen( frame )
	-- {{#invoke:Chessboard|ascii2fen|kl| | |....}}
	return convertArgsToFen( frame.args, frame.args.offset or 1 )
end

return p