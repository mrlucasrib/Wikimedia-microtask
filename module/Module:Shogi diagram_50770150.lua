local shogiobject = {}

-----------------------
-- internal functions 
-----------------------


-- returns a japanese character for a roman letter abbreviation
-- called by the shogiboard() function
local function piecesymbol(abbreviation)
	-- the abbreviation argument is a string of 1-3 letters that stand for the English names of the shogi pieces
	-- the abbreviation is extracted out of a longer string by the processString() function
	
	-- letter to character mapping (hash table)
	local piecenames = {
		p = '歩',
		t = 'と',
		l = '香',
		pl = '杏',
		n = '桂',
		pn = '圭',
		s = '銀',
		ps = '全',
		g = '金',
		b = '角',
		h = '馬',
		r = '飛',
		d = '龍',
		gyoku = '玉',
		ou = '王',
		tx = '个',
		plx = '仝',
		pnx = '今',
		dx = '竜',
		e = '象',
		a = '太'
	}
	-- spit out the character corresponding to abbreviation
	-- if the abbreviation string is empty, then spit out nobreak space (for html tables)		
	piece = piecenames[abbreviation] or '&nbsp;'
	return string.format( piece )
end


-- function separates out the piece, the side, and the boldness info present in the string argument
-- it returns an array with these three values plus the color (for promoted pieces)
-- this info is passed to the makeTD() function
function processString(ss)
	-- strip whitespace
	ss = mw.text.trim(ss)
	
	-- get the last character of the string
	local lastchar = mw.ustring.sub(ss, -1)
	
	-- chop off last character of string
	local restofstring = mw.ustring.sub(ss, 1, -2)

	-- default is normal font
	-- but if the string ends with 'l' for 'last move', 
	-- then the font should be bold and we need to get a new string with the this 'l' chopped off (with a new last character)
	local boldness = 'normal'
	if lastchar:match('l') then
		boldness = 'bold'
		lastchar = mw.ustring.sub(restofstring, -1)
		restofstring = mw.ustring.sub(restofstring, 1, -2)
	end
	
	-- the side is either 'g' for 'gote' or 's' for 'sente'
	-- it's the last character in the string (and if the string ended)
	local side = lastchar
	
	-- the leftover string is the shogi piece abbreviation
	local pieceabbr = restofstring
	
	-- default is black font
	-- if the piece is promoted (one the abbreviations below), then the piece should be red
	local color = 'black'
	if pieceabbr:match('t') or pieceabbr:match('pl') or pieceabbr:match('pn') or pieceabbr:match('ps') or pieceabbr:match('h') or pieceabbr:match('d') then
		color = 'red'
	end
	-- this is an exceptional bit:
	-- gote's king is usually 王 instead of 玉 by convention, 
	-- but it's convenient to use the 'k' code for both sente and gote and let the default character be side-dependent
	if pieceabbr:match('k') and side:match('g') then
		pieceabbr = 'ou'
	end
	if pieceabbr:match('k') and side:match('s') then
		pieceabbr = 'gyoku'
	end
	-- similar to above exception, reverse default
	if pieceabbr:match('ak') and side:match('s') then
		pieceabbr = 'ou'
	end
	if pieceabbr:match('ak') and side:match('g') then
		pieceabbr = 'gyoku'
	end
	-- convert abbreviation to Japanese character
	local piecechar = piecesymbol(pieceabbr)
	
	if ss:match('yy') or ss:match('gr') or ss:match('rat') or ss:match('lat') or ss:match('uat') or ss:match('dat') or 
           ss:match('lra') or ss:match('las') or ss:match('ras') or ss:match('uda') or ss:match('das') or ss:match('uas') or 
           ss:match('da') or ss:match('dau') or ss:match('dad') or ss:match('daus') or ss:match('dads') or ss:match('daa') or 
           ss:match('daad') or ss:match('daau') or ss:match('daaus') or ss:match('daads') or ss:match('kar') or ss:match('kal') or 
           ss:match('kadr') or ss:match('kadl') or ss:match('rah') or ss:match('lah') or ss:match('dah') or ss:match('uah') or 
           ss:match('durh') or ss:match('dulh') or ss:match('ddrh') or ss:match('ddlh') or ss:match('ddl') or ss:match('ddr') or 
           ss:match('dul') or ss:match('dur') then
		piecechar = '[[File:shogi_' .. ss .. '22.svg|20px]]'
		side = 'arrow'
		color = 'arrow'
		boldness = 'arrow'
	end
	
	local result = {piecechar, side, color, boldness}
	return result
end


-- function makes a <td> containing the piece with CSS stuff
-- uses the info from processString() to customize the CSS based on which side, color, and boldness
function makeTD(stringarg)
	-- got to process the string argument into its informational bits
	-- this processedstring is an array (or whatever the equivalent is in Lua)
	local processedstring = processString(stringarg)
	-- saving the pieces of the array as separate objects to be referred to below
	local piecechar = processedstring[1]
	local side = processedstring[2]
	local color = processedstring[3]
	local bold = processedstring[4]
	
	-- i guess one needs a root node?
	local root = mw.html.create('')
	
	-- the default <td>
	local td = root:tag('td')
		td:css('border', 'black 1px solid')
		td:css('width', '20px')
		td:css('height', '20px')
		td:css('padding', '0')
		td:css('line-height', '0')
		td:css('font-family', '"Hiragino Mincho ProN", serif')
	
		if not side:match('arrow') then
			td:wikitext( piecechar )
		end
	
	-- g = gote
	-- gote should be upside down text
	if side:match( 'g' ) then
		td:css('transform', 'rotate(180deg)')
	end
	
	-- for promoted pieces
	if color:match( 'red' ) then
		-- this is a darkish reddish color
		td:css('color', '#E00303')
	end

	-- for bold pieces
	if bold:match( 'bold' ) then
		td:css('font-weight', 'bolder')
		-- traditionally bold type is gothic (sans serif) in Japanese typesetting of shogi diagrams within Japanese shogi books
		td:css('font-family', ' HiraginoSans-W5, sans-serif')
	end
	
	-- for arrow svgs 
	if side:match('arrow') then
		td:css('padding', '0')
		td:css('width', '20px')
		td:css('height', '20px')
		td:css('font-size', '1px')
		td:css('line-height', '0')
		td:wikitext( piecechar )
	end
	return tostring(root)
end


-- function makes the shogi diagram
-- this is basically a <div> enclosing a .css <div> wrapper with a <table> inside
function shogiboard(args)
	-- these are the column coordinate labels 9-1
	local colLabels = {'9', '8', '7', '6', '5', '4', '3', '2', '1', '&nbsp;'}
	-- these are the row coordinate labels a-i (western notation)
	local rowLabels = {'1', '2', '3', '4', '5', '6', '7', '8', '9'}
	-- these are the row coordinate labels 1-9 (Japanese notation)
	-- this isn't set up for use yet
	local rowLabelsJP = {'一', '二', '三', '四', '五', '六', '七', '八', '九'}
	
	local headerarg = args[2]
	local toppieceinhandarg = args[3]
	
	local root = mw.html.create('div')

	-- <div> wrapper
	local shogiboardwrapper = root:tag('div')
		:addClass('shogiboardwrapper')
		:css('padding-left', '4px')
		:css('padding-bottom', '2px')
	
	-- the diagram header/caption
	local headerstring = mw.text.trim(headerarg)
	local header = shogiboardwrapper:tag('div')
		header:css('padding', '0')
		header:wikitext(headerstring)
		header:css('font-size', '14px')

	-- this is the 'piece-in-hand' argument for gote
	-- strip whitespace
	local strippedpieceinhandtop = mw.text.trim(toppieceinhandarg) or ''
	-- put it in a <div> with .css formating
	local pieceinhandtopdiv = shogiboardwrapper:tag('div')
		pieceinhandtopdiv:css('padding', '0')
		pieceinhandtopdiv:css('font-size', '12px')
		pieceinhandtopdiv:wikitext('☖ pieces in hand: ')
	-- i was going to put the actual argument text into conditional <span> .css formating, but i couldn't get the logical test in an if/else structure right...
	local piecesinhandtopspan = pieceinhandtopdiv:tag('span')
		piecesinhandtopspan:css('font-size', '13px')
		piecesinhandtopspan:wikitext(strippedpieceinhandtop)
	
	-- the shogi table
	local shogitable = shogiboardwrapper:tag('table')
		:addClass('shogitable')
		:attr('border', '1')
		:css('border-collapse', 'collapse')
		:css('border', 'none')
		:css('padding-top', '0')
		:css('background-color', 'white')
		
	-- font size for the shogi piece text
	piecefontsize = '17px'
	-- font size for the column/row piece coordinate labels (9-1) and (a-i)
	colrowfontsize = '11px'
	-- padding amount for the row piece coordinate labels (a-i)
	padrowlab = '1px'
	
	-- the row for the column coordinate labels
	local columnlabelrow = shogitable:tag('tr')
		:css('font-size', colrowfontsize)
		:css('background-color', '#f9f9f9')
	-- iterating over the column label to put each label in a <td>
	for i,v in ipairs(colLabels) do 
		local td = columnlabelrow:tag('td')
			:css('border', 'none')
			:css('width', '20px')
			:css('height', '5px')
			:wikitext( v )
	end
	
	-- iterate over the 81 shogi piece arguments (left to right, top to bottom)
	-- i couldn't figure out how to do this is in a clever loopy way as i couldn't figure out how to close the html tags
	-- whatever, it's repetitive, but it works
	
	-- index number displacement/offset
	-- this is just the number of arguments that precede the 81 shogi piece arguments that are in the html <table>
	-- i just keep the piece arguments as indexes 1-81, then add nx to the index value
	nx = 3
	
	-- the row for the shogi pieces
	-- row 1
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	-- put a single piece into a <td>
	-- iterate over 9 pieces in the row
	for irow = 1,9 do
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	-- add row coordinate label <td>
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('padding-top', '0')
		:css('padding-bottom', '0')
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[1] )
	-- row 2
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 10,18 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[2] )
	-- row 3
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 19,27 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[3] )
	-- row 4
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 28,36 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[4] )
	-- row 5
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 37,45 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[5] )
	-- row 6
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 46,54 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[6] )
	-- row 7
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 55,63 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[7] )
	-- row 8
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 64,72 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[8] )
	-- row 9
	local trow = shogitable:tag('tr')
		:css('font-size', piecefontsize)
	for irow = 73,81 do		
		trow:wikitext( makeTD(args[(irow+nx)]) )
	end
	local rowlabel = trow:tag('td')
		:css('border', 'none')
		:css('font-size', colrowfontsize)
		:css('padding-left', padrowlab)
		:css('background-color', '#f9f9f9')
		:wikitext( rowLabels[9] )
	
	-- this is the 'piece-in-hand' argument for sente (same as above for gote)
	-- only difference is the black shogi piece glyph (☗)
	local strippedpieceinhandbottom = mw.text.trim(args[81+1+nx]) or ''	
	local pieceinhandbottomdiv = shogiboardwrapper:tag('div')
		pieceinhandbottomdiv:css('padding', '0')
		pieceinhandbottomdiv:css('font-size', '12px')
		pieceinhandbottomdiv:wikitext('☗ pieces in hand: ')
	local piecesinhandbottomspan = pieceinhandbottomdiv:tag('span')
		piecesinhandbottomspan:css('font-size', '13px')
		piecesinhandbottomspan:wikitext(strippedpieceinhandbottom)
		
	return tostring(root)
end


-----------------------
-- main function 
-----------------------

function shogiobject.board(frame)
	-- need to use getParent().args for reasons i dont understand
	local args = frame:getParent().args
	return shogiboard(args)
end

return shogiobject