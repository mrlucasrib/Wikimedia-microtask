pgn = require('module:pgn')


local function moveToIndex(move)
	if not move:match('^%d+[dl]$') then return -1 end -- not a move
	local num, color = move:match('(%d+)([dl])')
	return num * 2 + (color == 'd' and 1 or 0)
end

local function indexToMove(index)
	return string.format('%d%s', math.floor( index / 2), index % 2 == 0 and 'l' or 'd')
end
	
function display_game(frame)
	local args = frame:getParent().args
	for k, v in pairs(frame.args) do args[k] = v end
	local game = args['pgn']
	if not game then error('must have "pgn" parameter') end
	
	local moves = pgn.pgn2fen(game)
	local template = args['template']
	if not template then error('must have "template" parameter') end
	local tmTable = {}
	
	local hydrate = function(index, comment) 
		local temp = template:gsub('%$fen%$', moves[index])
		temp = temp:gsub('%$comment%$', comment)
		temp = temp:gsub('%$move%$', indexToMove(index))
		table.insert(tmTable,  { index, temp } )
	end
	template = mw.text.unstripNoWiki( template )
	for arg, val in pairs(args) do -- collect boards of the form "12l = comment"
		local index = moveToIndex(arg)
		if index >= 0 then hydrate(index, val) end
	end

	for arg, val in pairs(args) do -- collect boards of the form "| from1 = 7d | to1 = 8l | comments1 = { "comment", "comment" }
		if arg:match('^from%d+$') then
			local hunk = arg:match(('^from(%d+)$'))
			toMove = args['to' .. hunk]
			if not toMove then error (string.format('parameter %s exists, but no parameter to%s', arg, hunk)) end
			local fromIndex = moveToIndex(val)
			if fromIndex < 0 then error(string.format('malformed value for parameter %s', arg)) end
			local toIndex = moveToIndex(toMove)
			if toIndex < 0 then error(string.format('malformed value for parameter to%s', hunk)) end
			local comments = {}
			local commentsVal = args['comments' .. hunk] or ''
			for comment in commentsVal:gmatch('{([^}]*)}') do table.insert(comments, comment) end
			for index = fromIndex, toIndex do hydrate(index, table.remove(comments, 1) or '') end
		end
	end
	table.sort(tmTable, function(a, b) return a[1] < b[1] end)
	local res = ''
	for _, item in ipairs(tmTable) do res = res ..  frame:preprocess(item[2]) end
	return res
end

return {
	['display game'] = display_game
}