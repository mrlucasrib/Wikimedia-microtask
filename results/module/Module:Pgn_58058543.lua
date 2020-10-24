--[[
the purpose of this module is to provide pgn analysis local functionality
main local function, called pgn2fen:
input: either algebraic notation or full pgn of a single game
output: 
* 1 table of positions (using FEN notation), one per each move of the game
* 1 lua table with pgn metadata (if present)


purpose:
	using this local , we can create utility local functions to be used by templates.
	the utility local function will work something like so:
	it receives (in addition to the pgn, of course) list of moves and captions, and some wikicode in "nowiki" tag.
	per each move, it will replace the token FEN with the fen of the move, and the token COMMENT with the comment (if any) of the move.
	it will then parse the wikicode, return all the parser results concataneted.
	others may fund other ways to use it.

the logic:
the analysis part copies freely from the javascipt "pgn" program.

main object: "board": 0-based table(one dimensional array) of 64 squares (0-63), 
	each square is either empty or contains the letter of the charToFile, e.g., "pP" is pawn.

utility local functions
index to row/col
row/col to index
disambig(file, row): if file is number, return it, otherwise return rowtoindex().
create(fen): returns ready board
generateFen(board) - selbverständlich

pieceAt(coords): returns the piece at row/col
findPieces(piece): returns list of all squares containing specific piece ("black king", "white rook" etc).
roadIsClear(start/end row/column): start and end _must_ be on the same row, same column, or a diagonal. will error if not.
	returns true if all the squares between start and end are clear.
canMove(source, dest, capture): boolean (capture is usually reduntant, except for en passant)
promote(coordinate, designation, color)
move(color, algebraic notation): finds out which piece should move, error if no piece or more than one piece found,
	and execute the move.
	
rawPgnAnalysis(input)
gets a pgn or algebraic notation, returns a table withthe metadata, and a second table with the algebraic notation individual moves

main:
-- metadata, notations := rawPgnAnalysis(input)
-- result := empty table
-- startFen := metadata.fen || default; results += startFen
-- board := create(startFen)
-- loop through notations 
----- pass board, color and notation, get modified board
----- results += generateFen()
-- return result

the "meat" is the "canMove. however, as it turns out, it is not that difficult.
the only complexity is with pawns, both because they are asymmetrical, and irregular. brute force (as elegantly as possible)

other pieces are a breeze. color does not matter. calc da := abs(delta raw), db := abs(delta column)
piece  | rule
Knight: 	da * db - 2 = 0
Rook:		da * db = 0
Bishop: 	da - db = 0
King		db | db = 1 (bitwise or)
Queen		da * db * (da - db) = 0


move:
find out which piece. find all of them on the board. ask each if it can execute the move, and count "yes". 
	there should be only one yes (some execptions to be handled). execute the move. 



]]

local BLACK = "black"
local WHITE = "white"

local PAWN  = "P"
local ROOK  = "R"
local KNIGHT = "N"
local BISHOP = "B"
local QUEEN = "Q"
local KING = "K"

local KINGSIDE = 7
local QUEENSIDE = 12

local DEFAULT_BOARD = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR'

local bit32 = bit32 or require('bit32')

--[[ following lines require when running locally - uncomment.
mw = mw or {
	ustring = string,
	text = {
		['split'] = local function(s, pattern)
			local res = {}
			while true do
				local start, finish = s:find(pattern)
				if finish and finish > 1 then
					local frag = s:sub(1, start - 1)
					table.insert(res, frag)
					s = s:sub(finish + 1) 
				else
					break
				end
			end
			if #s then table.insert(res, s) end
			return res
		end,
		['trim'] = local function(t)
			t = type(t) == 'string' and t:gsub('^%s+', '')
			t = t:gsub('%s+$', '')
			return t
		end
	}
}
]]

-- in lua 5.3, unpack is not a first class citizen anymore, but - assign table.unpack
local unpack = unpack or table.unpack
		
local function apply(f, ...)
	res = {}
	targ = {...}
	for ind = 1, #targ do
		res[ind] = f(targ[ind])
	end
	return unpack(res)
end

local function empty(s)
	return not s or mw.text.trim(s) == ''
end

local function falseIfEmpty(s)
	return not empty(s) and s
end

local function charToFile(ch)
	return falseIfEmpty(ch) and string.byte(ch) - string.byte('a')
end

local function charToRow(ch)
	return falseIfEmpty(ch) and tonumber(ch) - 1
end

local function indexToCoords(index)
	return index % 8, math.floor(index / 8)
end

local function coordsToIndex(file, row) 
	return row * 8 + file
end

local function charToPiece(letter)
	local piece = mw.ustring.upper(letter)
	return piece, piece == letter and WHITE or BLACK
end

local function pieceToChar(piece, color)
	return color == WHITE and piece or mw.ustring.lower(piece)
end

local function ambigToIndex(file, row)
	if row == nil then return file end
	return coordsToIndex(file, row)
end

local function enPasantRow(color)
	return color == WHITE and 5 or 2
end



local function sign(a)
	return a < 0 and -1 
		or a > 0 and 1 
		or 0
end

local function pieceAt(board, fileOrInd, row) -- called with 2 params, fileOrInd is the index, otherwise it's the file.
	local letter = board[ambigToIndex(fileOrInd, row)] 
	if not letter then return end
	return charToPiece(letter)
end

local function findPieces(board, piece, color)
	local result = {}
	local lookFor = pieceToChar(piece, color)
	for index = 0, 63 do
		local letter = board[index]
		if letter == lookFor then table.insert(result, index) end
	end
	return result
end

local function roadIsClear(board, ind1, ind2)
	if ind1 == ind2 then error('call to roadIsClear with identical indices', ind1) end
	local file1, row1 = indexToCoords(ind1)
	local  file2, row2 = indexToCoords(ind2) 
	if (file1 - file2) * (row1 - row2) * (math.abs(row1 - row2) - math.abs(file1 - file2)) ~= 0 then
		error('sent two indices to roadIsClear which are not same row, col, or diagonal: ', ind1, ind2)
	end
	local hdelta = sign(file2 - file1)
	local vdelta = sign(row2 - row1)
	local row, file = row1 + vdelta, file1 + hdelta
	while row ~= row2 or file ~= file2 do
		if pieceAt(board, file, row) then return false end
		row = row + vdelta
		file = file + hdelta
	end
	return true
end

local function pawnCanMove(board, color, startFile, startRow, file, row, capture)
	local hor, ver = file - startFile, row - startRow
	local absVer = math.abs(ver)
	if capture then
		local ok = hor * hor == 1 and (
				color == WHITE and ver == 1 or
				color == BLACK and ver == - 1
			)
			
		local enpassant = ok and
			row == enPasantRow(color) and 
			pieceAt(board, file, row) == nil
		return ok, enpassant
	else 
		if hor ~= 0 then return false end
	end
	if absVer == 2 then
		if not roadIsClear(board, coordsToIndex(startFile, startRow), coordsToIndex(file, row)) then return false end
		return color == WHITE and startRow == 1 and ver == 2 or
			color == BLACK and startRow == 6 and ver == -2
	end
	return color == WHITE and ver == 1 or color == BLACK and ver == -1
end

local function canMove(board, start, dest, capture, verbose)
	local startFile, startRow = indexToCoords(start) 
	local file, row = indexToCoords(dest)
	local piece, color = pieceAt(board, startFile, startRow)
	if piece == PAWN then return pawnCanMove(board, color, startFile, startRow, file, row, capture) end
	local dx, dy = math.abs(startFile - file), math.abs(startRow - row)
	return 	piece == KNIGHT and dx * dy == 2
			or piece == KING and bit32.bor(dx, dy) == 1 
			or (
				piece == ROOK and dx * dy == 0 
				or piece == BISHOP and dx == dy 
				or piece == QUEEN and dx * dy * (dx - dy) == 0
			) and roadIsClear(board, start, dest, verbose)
end

local function exposed(board, color) -- only test for queen, rook, bishop.
	local king = findPieces(board, KING, color)[1]
	for ind = 1, 63 do
		local letter = board[ind]
		if letter then
			local _, pcolor = charToPiece(letter)
			if pcolor ~= color and canMove(board, ind, king, true) then
				return true 
			end
		end
	end
end

local function clone(orig)
	local res = {}
	for k, v in pairs(orig) do res[k] = v end
	return res
end

local function place(board, piece, color, file, row) -- in case of chess960, we have to search
	board[ambigToIndex(file, row)] = pieceToChar(piece, color)
	return board
end

local function clear(board, file, row)
	board[ambigToIndex(file, row)] = nil
	return board
end

local function doCastle(board, color, side)
	local row = color == WHITE and 0 or 7
	local startFile, step = 0, 1
	local kingDestFile, rookDestFile = 2, 3
	local king = findPieces(board, KING, color)[1]
	local rook
	if side == KINGSIDE then
		startFile, step = 7, -1
		kingDestFile, rookDestFile = 6, 5
	end
	for file = startFile, 7 - startFile, step do
		local piece = pieceAt(board, file, row)
		if piece == ROOK then
			rook = coordsToIndex(file, row)
			break
		end
	end
	board = clear(board, king)
	board = clear(board, rook)
	board = place(board, KING, color, kingDestFile, row) 
	board = place(board, ROOK, color, rookDestFile, row)
	return board
end

local function doEnPassant(board, pawn, file, row)
	local _, color = pieceAt(board, pawn)
	board = clear(board, pawn)
	board = place(board, PAWN, color, file, row)
	if row == 5 then board = clear(board, file, 4) end
	if row == 2 then board = clear(board, file, 3) end
	return board
end

local function generateFen(board)
	local res = ''
	local offset = 0
	for row = 7, 0, -1 do
		for file = 0, 7 do
			piece = board[coordsToIndex(file, row)]
			res = res .. (piece or '1')
		end
		if row > 0 then res = res .. '/' end
	end
	return mw.ustring.gsub(res, '1+', function( s ) return #s end )
end

local function findCandidate(board, piece, color, oldFile, oldRow, file, row, capture, notation)
	local enpassant = {}
	local candidates, newCands = findPieces(board, piece, color), {} -- all black pawns or white kings etc.
	if oldFile or oldRow then 
		local newCands = {}
		for _, cand in ipairs(candidates) do
			local file, row = indexToCoords(cand)
			if file == oldFile then table.insert(newCands, cand) end
			if row == oldRow then table.insert(newCands, cand) end
		end
		candidates, newCands = newCands, {}
	end
	local dest = coordsToIndex(file, row)
	for _, candidate in ipairs(candidates) do
		local can
		can, enpassant[candidate] = canMove(board, candidate, dest, capture)
		if can then table.insert(newCands, candidate) end
	end

	candidates, newCands = newCands, {}
	if #candidates == 1 then return candidates[1], enpassant[candidates[1]] end
	if #candidates == 0 then 
		error('could not find a piece that can execute ' .. notation) 
	end
	-- we have more than one candidate. this means that all but one of them can't really move, b/c it will expose the king 
	-- test for it by creating a new board with this candidate removed, and see if the king became exposed
	for _, candidate in ipairs(candidates) do 
		local cloneBoard = clone(board) -- first, clone the board
		cloneBoard = clear(cloneBoard, candidate) -- now, remove the piece
		if not exposed(cloneBoard, color) then table.insert(newCands, candidate) end
	end
	candidates, newCands = newCands, {}
	if #candidates == 1 then return candidates[1] end
	error(mw.ustring.format('too many (%d, expected 1) pieces can execute %s at board %s', #candidates, notation, generateFen(board)))
end

local function move(board, notation, color)
	local endGame = {['1-0']=true, ['0-1']=true, ['1/2-1/2']=true, ['*']=true}

	local cleanNotation = mw.ustring.gsub(notation, '[!?+# ]', '')

	if cleanNotation == 'O-O' then
		return doCastle(board, color, KINGSIDE)
	end
	if cleanNotation == 'O-O-O' then
		return doCastle(board, color, QUEENSIDE)
	end
	if endGame[cleanNotation] then
		return board, true
	end

	local pattern = '([RNBKQ]?)([a-h]?)([1-8]?)(x?)([a-h])([1-8])(=?[RNBKQ]?)'
	local _, _, piece, oldFile, oldRow, isCapture, file, row, promotion = mw.ustring.find(cleanNotation, pattern)
	oldFile, file = apply(charToFile, oldFile, file) 
	oldRow, row = apply(charToRow, oldRow, row)
	piece = falseIfEmpty(piece) or PAWN
	promotion = falseIfEmpty(promotion)
	isCapture = falseIfEmpty(isCapture)
	local candidate, enpassant = findCandidate(board, piece, color, oldFile, oldRow, file, row, isCapture, notation) -- findCandidates should panic if # != 1
	if enpassant then
		return doEnPassant(board, candidate, file, row)
	end
	board[coordsToIndex(file, row)] = promotion and pieceToChar(promotion:sub(-1), color) or board[candidate]
	board = clear(board, candidate)
	return board
end

local function create( fen )
	-- converts FEN notation to 64 entry array of positions. copied from enwiki Module:Chessboard (in some distant past i prolly wrote it)
	local res = {}
	local row = 8
	-- Loop over rows, which are delimited by /
	for srow in string.gmatch( "/" .. fen, "/%w+" ) do
	srow = srow:sub(2)
		row = row - 1
		local ind = row * 8
		-- Loop over all letters and numbers in the row
		for piece in srow:gmatch( "%w" ) do
			if piece:match( "%d" ) then -- if a digit
				ind = ind + piece
			else -- not a digit
				res[ind] = piece
				ind = ind + 1
			end
		end
	end
	return res
end

local function processMeta(grossMeta) 
	res = {}
	-- process grossMEta here
	for item in mw.ustring.gmatch(grossMeta or '', '%[([^%]]*)%]') do
		key, val = item:match('([^"]+)"([^"]*)"')
		if key and val then
			res[mw.text.trim(key)] = mw.text.trim(val) -- add mw.text.trim()
		else
			error('strange item detected: ' .. item .. #items) -- error later
		end
	end
	return res
end

local function analyzePgn(pgn)
	local grossMeta = pgn:match('%[(.*)%]') -- first open to to last bracket 
	pgn = string.gsub(pgn, '%[(.*)%]', '')
	local steps = mw.text.split(pgn, '%s*%d+%.%s*')
	local moves = {}
	for _, step in ipairs(steps) do
		if mw.ustring.len(mw.text.trim(step)) then
			ssteps = mw.text.split(step, '%s+')
			for _, sstep in ipairs(ssteps) do 
				if sstep and not mw.ustring.match(sstep, '^%s*$') then table.insert(moves, sstep) end
			end
		end
	end
	return processMeta(grossMeta), moves
end

local function pgn2fen(pgn)
	local metadata, notationList = analyzePgn(pgn)
	local fen = metadata.fen or DEFAULT_BOARD
	local board = create(fen)
	local res = {fen}
	local colors = {BLACK, WHITE} 
	for step, notation in ipairs(notationList) do
		local color = colors[step % 2 + 1]
		board = move(board, notation, color)
		local fen = generateFen(board)
		table.insert(res, fen)
	end
	return res, metadata
end

return {
	pgn2fen = pgn2fen,
	main = function(pgn) 
		local res, metadata = pgn2fen(pgn) 
		return metadata, res 
	end,
}