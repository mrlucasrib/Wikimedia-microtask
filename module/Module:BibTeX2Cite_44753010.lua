local p = {}
local l2u = require( "Module:LaTeX2UTF8" )
 
function p.test(frame)
	local s = [[
 	@book {MR0161818,
 	AUTHOR = {Erd{\H{o}}s, P{\'a}l and Sur{\'a}nyi, J{\'a}nos},
 	TITLE = {V\'alogatott fejezetek a sz\'amelm\'eletb{\H o}l},
 	PUBLISHER = {Tank\"onyvkiad\'o V\'allalat, Budapest},
 	YEAR = {1960},
 	PAGES = {250},
 	MRCLASS = {10.00},
 	MRNUMBER = {0161818 (28 \#5022)},
	} 
	]]
	local c = p.BibTeX2Cite(s)
  	return frame:expandTemplate{title = 'cite journal', args = c["citeparms"]}
end
 
function p.BibTeX2Cite(s)
 	s = l2u.translate_diacritics( s )
  	s = l2u.translate_special_characters( s )
  	local c = {}
  	c["citeparms"] = {}
  	c["nonciteparms"] = {}
 
  	local authorlist = mw.ustring.match( s, "AUTHOR = ({.-})" )
  	c["citeparms"]["last1"]  = mw.ustring.match( authorlist, "(%a-), %a- ")
  	c["citeparms"]["first1"] = mw.ustring.match( authorlist, "%a-, (%a-) ")
 
  	local authoridx=2
	for last,first in mw.ustring.gmatch(s, "and (%a-), (%a-)[ }]") do
  		c["citeparms"]["last" .. authoridx] = last
  		c["citeparms"]["first" .. authoridx] = first
  		authoridx = authoridx+1
  	end
 
  	c["nonciteparms"]["type"] 	= mw.ustring.match( s, "@(%a)+ {" )
  	c["citeparms"]["mr"] 		= mw.ustring.match( s, "{(MR%d+)," )
  	c["citeparms"]["title"]		= mw.ustring.match( s, "TITLE = {(.-)}" )
  	c["citeparms"]["publisher"]	= mw.ustring.match( s, "PUBLISHER = {(.-)}" )
  	c["citeparms"]["year"]		= mw.ustring.match( s, "YEAR = {(.-)}" )
  	c["citeparms"]["pages"]		= mw.ustring.match( s, "PAGES = {(.-)}" )
  	c["nonciteparms"]["mrclass"]= mw.ustring.match( s, "MRCLASS = {(.-)}" )
  	c["nonciteparms"]["mrnumber"] = mw.ustring.match( s, "MRNUMBER = {(.-)}" )
 
  	return c
end
 
return p