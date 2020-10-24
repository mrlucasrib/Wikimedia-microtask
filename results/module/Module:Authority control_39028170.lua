require('Module:No globals')

local p = {}
local title = mw.title.getCurrentTitle()
local namespace = title.namespace
local testcases = (string.sub(title.subpageText,1,9) == 'testcases')

--[[==========================================================================]]
--[[                            Category functions                            ]]
--[[==========================================================================]]

function p.getCatForId( id )
	local catName = ''
	if namespace == 0 then
		catName = 'Wikipedia articles with '..id..' identifiers'
	elseif namespace == 2 and not title.isSubpage then
		catName = 'User pages with '..id..' identifiers'
	else
		catName = 'Miscellaneous pages with '..id..' identifiers'
	end
	return '[[Category:'..catName..']]'..p.redCatLink(catName)
end

function p.redCatLink( catName ) --catName == 'Blah' (not 'Category:Blah', not '[[Category:Blah]]')
	if catName and catName ~= '' and
	   testcases == false and
	   mw.title.new(catName, 14).exists == false
	then
		return '[[Category:Pages with red-linked authority control categories]]'
	end
	return ''
end

--[[==========================================================================]]
--[[                      Property formatting functions                       ]]
--[[==========================================================================]]

function p.aagLink( id )
	--P3372's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://www.aucklandartgallery.com/explore-art-and-ideas/artist/'..id..'/ '..id..']'..p.getCatForId( 'AAG' )
end

function p.acmLink( id )
	--P864's format regex: \d{11} (e.g. 12345678901)
	if not id:match( '^%d%d%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://dl.acm.org/profile/'..id..' '..id..']'..p.getCatForId( 'ACM-DL' )
end

function p.adbLink( id )
	--P1907's format regex: [a-z][-a-z]+-([1-2]\d|[1-9])\d{0,3} (e.g. barton-sir-edmund-toby-71)
	if not id:match( '^[a-z][-a-z]+-[1-2]%d%d?%d?%d?$' ) and
	   not id:match( '^[a-z][-a-z]+-[1-9]%d?%d?%d?$' ) then
		return false
	end
	return '[http://adb.anu.edu.au/biography/'..id..' '..id..']'..p.getCatForId( 'ADB' )
end

function p.agsaLink( id )
	--P6804's format regex: [1-9]\d* (e.g. 3625)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://www.agsa.sa.gov.au/collection-publications/collection/creators/_/'..id..'/ '..id..']'..p.getCatForId( 'AGSA' )
end

function p.autoresuyLink( id )
	--P2558's format regex: [1-9]\d{0,4} (e.g. 12345)
	if not id:match( '^[1-9]%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://autores.uy/autor/'..id..' '..id..']'..p.getCatForId( 'autores.uy' )
end

function p.awrLink( id )
	--P4186's format regex: (([A-Z]{3}\d{4})|([A-Z]{2}\d{5}))[a-z] (e.g. PR00768b)
	if not id:match( '^[A-Z][A-Z][A-Z]%d%d%d%d[a-z]$' ) and
	   not id:match( '^[A-Z][A-Z]%d%d%d%d%d[a-z]$' ) then
		return false
	end
	return '[http://www.womenaustralia.info/biogs/'..id..'.htm '..id..']'..p.getCatForId( 'AWR' )
end

function p.balatLink( id )
	--P3293's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[http://balat.kikirpa.be/object/104257'..id..' '..id..']'..p.getCatForId( 'BALaT' ) --no https as of 9/2019
end

function p.bibsysLink( id )
	--P1015's format regex: [1-9]\d* or [1-9](\d{0,8}|\d{12}) (e.g. 1234567890123)
	--TODO: follow up @ [[d:Property talk:P1015#Discrepancy between the 2 regex constraints]] or escalate/investigate
	if not id:match( '^[1-9]%d?%d?%d?%d?%d?%d?%d?%d?$' ) and
	   not id:match( '^[1-9]%d%d%d%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://authority.bibsys.no/authority/rest/authorities/html/'..id..' '..id..']'..p.getCatForId( 'BIBSYS' )
end

function p.bildLink( id )
	--P2092's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://www.bildindex.de/document/obj'..id..' '..id..']'..p.getCatForId( 'Bildindex' )
end

function p.bncLink( id )
	--P1890's format regex: \d{9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://www.bncatalogo.cl/F?func=direct&local_base=red10&doc_number='..id..' '..id..']'..p.getCatForId( 'BNC' )
end

function p.bneLink( id )
	--P950's format regex: (XX|FF|a)\d{4,7}|(bima|bimo|bica|bis[eo]|bivi|Mise|Mimo|Mima)\d{10} (e.g. XX1234567)
	if not id:match( '^[XF][XF]%d%d%d%d%d?%d?%d?$' ) and
	   not id:match( '^a%d%d%d%d%d?%d?%d?$' ) and
	   not id:match( '^bi[mcsv][aoei]%d%d%d%d%d%d%d%d%d%d$' ) and
	   not id:match( '^Mi[sm][eoa]%d%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://catalogo.bne.es/uhtbin/authoritybrowse.cgi?action=display&authority_id='..id..' '..id..']'..p.getCatForId( 'BNE' ) --no https as of 9/2019
end

function p.bnfLink( id )
	--P268's format regex: \d{8}[0-9bcdfghjkmnpqrstvwxz] (e.g. 123456789)
	if not id:match( '^c?b?%d%d%d%d%d%d%d%d[0-9bcdfghjkmnpqrstvwxz]$' ) then
		return false
	end
	--Add cb prefix if it has been removed
	if not id:match( '^cb.+$' ) then
		id = 'cb'..id
	end
	return '[https://catalogue.bnf.fr/ark:/12148/'..id..' '..id..'] [https://data.bnf.fr/ark:/12148/'..id..' (data)]'..p.getCatForId( 'BNF' )
end

function p.botanistLink( id )
	--P428's format regex: ('t )?(d')?(de )?(la )?(van (der )?)?(Ma?c)?(De)?(Di)?\p{Lu}?C?['\p{Ll}]*([-'. ]*(van )?(y )?(d[ae][nr]?[- ])?(Ma?c)?[\p{Lu}bht]?C?['\p{Ll}]*)*\.? ?f?\.? (e.g. L.)
	--not easily/meaningfully implementable in Lua's regex since "(this)?" is not allowed...
	if not mw.ustring.match( id, "^[%u%l%d%. '-]+$" ) then --better than nothing
		return false
	end
	local id2 = id:gsub(' +', '%%20')
	return '[https://www.ipni.org/ipni/advAuthorSearch.do?find_abbreviation='..id2..' '..id..']'..p.getCatForId( 'Botanist' )
end

function p.bpnLink( id )
	--P651's format regex: \d{6,8} (e.g. 00123456)
	if not id:match( '^%d%d%d%d%d%d%d%d$' ) and --original format regex, changed 8/2019 to
	   not id:match( '^0?%d%d%d%d%d%d%d$' ) and --allow 1-2 leading 0s, allowed by the website
	   not id:match( '^0?0?%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://www.biografischportaal.nl/en/persoon/'..id..' '..id..']'..p.getCatForId( 'BPN' ) --no https as of 9/2019
end

function p.canticLink( id )
	--P1273's format regex: a\d{7}[0-9x] (e.g. a10640745)
	if not id:match( '^a%d%d%d%d%d%d%d[%dx]$' ) then
		return false
	end
	return '[http://cantic.bnc.cat/registres/CUCId/'..id..' '..id..']'..p.getCatForId( 'CANTIC' ) --no https as of 10/2019
end

function p.ciniiLink( id )
	--P271's format regex: DA\d{7}[\dX] (e.g. DA12345678)
	if not id:match( '^DA%d%d%d%d%d%d%d[%dX]$' ) then
		return false
	end
	return '[https://ci.nii.ac.jp/author/'..id..'?l=en '..id..']'..p.getCatForId( 'CINII' )
end

function p.cwgcLink( id )
	--P1908's format regex: [1-9]\d* (e.g. 75228351)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://www.cwgc.org/find-war-dead/casualty/'..id..'/ '..id..']'..p.getCatForId( 'CWGC' )
end

function p.daaoLink( id )
	--P1707's format regex: [a-z\-]+\d* (e.g. rolf-harris)
	if not id:match( '^[a-z%-]+%d*$' ) then
		return false
	end
	return '[https://www.daao.org.au/bio/'..id..' '..id..']'..p.getCatForId( 'DAAO' )
end

function p.dblpLink( id )
	--P2456's format regex: \d{2,3} /\d+(-\d+)?|[a-z] /[a-zA-Z][0-9A-Za-z]*(-\d+)? (e.g. 123/123)
	if not id:match( '^%d%d%d?/%d+$' ) and
	   not id:match( '^%d%d%d?/%d+%-%d+$' ) and
	   not id:match( '^[a-z]/[a-zA-Z][0-9A-Za-z]*$' ) and
	   not id:match( '^[a-z]/[a-zA-Z][0-9A-Za-z]*%-%d+$' ) then
		return false
	end
	return '[https://dblp.org/pid/'..id..' '..id..']'..p.getCatForId( 'DBLP' )
end

function p.dsiLink( id )
	--P2349's format regex: [1-9]\d* (e.g. 1538)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[http://www.uni-stuttgart.de/hi/gnt/dsi2/index.php?table_name=dsi&function=details&where_field=id&where_value='..id..' '..id..']'..p.getCatForId( 'DSI' )
end

function p.fnzaLink( id )
	--P6792's format regex: [1-9]\d* (e.g. 9785)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://findnzartists.org.nz/artist/'..id..'/ '..id..']'..p.getCatForId( 'FNZA' )
end

function p.gndLink( id )
	--P227's format regex: 1[012]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X] (e.g. 4079154-3)
	if not id:match( '^1[012]?%d%d%d%d%d%d%d[0-9X]$' ) and
	   not id:match( '^[47]%d%d%d%d%d%d%-%d$' ) and
	   not id:match( '^[1-9]%d?%d?%d?%d?%d?%d?%d?%-[0-9X]$' ) and
	   not id:match( '^3%d%d%d%d%d%d%d[0-9X]$' ) then
		return false
	end
	return '[https://d-nb.info/gnd/'..id..' '..id..']'..p.getCatForId( 'GND' )
end

function p.hdsLink( id )
	--P902's format regex: \d{6} (e.g. 050123)
	if not id:match( '^%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://hls-dhs-dss.ch/fr/articles/'..id..' '..id..']'..p.getCatForId( 'HDS' )
end

function p.iaafLink( id )
	--P1146's format regex: [0-9][0-9]* (e.g. 012)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://www.iaaf.org/athletes/_/'..id..' '..id..']'..p.getCatForId( 'IAAF' )
end

function p.iciaLink( id )
	--P1736's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://www.imj.org.il/artcenter/newsite/en/?artist='..id..' '..id..']'..p.getCatForId( 'ICIA' )
end

function p.isniLink( id )
	id = p.validateIsni( id ) --e.g. 0000-0000-6653-4145
	if not id then
		return false
	end
	return '[https://isni.org/isni/'..id..' '..id:sub( 1, 4 )..' '..id:sub( 5, 8 )..' '..id:sub( 9, 12 )..' '..id:sub( 13, 16 )..']'..p.getCatForId( 'ISNI' ) --no https as of 9/2019
end

function p.jocondeLink( id )
	--P347's format regex: [\-0-9A-Za-z]{11} (e.g. 12345678901)
	local regex = '^'..string.rep('[%-0-9A-Za-z]', 11)..'$'
	if not id:match( regex ) then
		return false
	end
	return '[https://www.pop.culture.gouv.fr/notice/joconde/'..id..' '..id..']'..p.getCatForId( 'Joconde' )
end

function p.kulturnavLink( id )
	--P1248's format regex: [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[http://kulturnav.org/'..id..' '..id..']'..p.getCatForId( 'KULTURNAV' ) --no https as of 9/2019
end

function p.lccnLink( id )
	local parts = p.splitLccn( id ) --e.g. n78039510
	if not parts then
		return false
	end
	local lccnType = parts[1] ~= 'sh' and 'names' or 'subjects'
	id = parts[1] .. parts[2] .. p.append( parts[3], '0', 6 )
	return '[https://id.loc.gov/authorities/'..lccnType..'/'..id..' '..id..']'..p.getCatForId( 'LCCN' )
end

function p.lirLink( id )
	--P886's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[http://www.e-lir.ch/e-LIR___Lexicon.'..id..'.450.0.html '..id..']'..p.getCatForId( 'LIR' ) --no https as of 9/2019
end

function p.lnbLink( id )
	--P1368's format regex: \d{9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://kopkatalogs.lv/F?func=direct&local_base=lnc10&doc_number='..id..'&P_CON_LNG=ENG '..id..']'..p.getCatForId( 'LNB' )
end

function p.leonoreLink( id )
	--P640's format regex: LH/\d{1,4}/\d{1,3}|19800035/\d{1,4}/\d{1,5}(Bis)?|C/0/\d{1,2} (e.g. LH/2064/18)
	if not id:match( '^LH/%d%d?%d?%d?/%d%d?%d?$' ) and             --IDs from       LH/1/1 to         LH/2794/54 (legionaries)
	   not id:match( '^19800035/%d%d?%d?%d?/%d%d?%d?%d?%d?$' ) and --IDs from 19800035/1/1 to 19800035/385/51670 (legionnaires who died 1954-1977 & some who died < 1954)
	   not id:match( '^C/0/%d%d?$' ) then                          --IDs from        C/0/1 to             C/0/84 (84 famous legionaries)
		return false
	end
	return '[http://www.culture.gouv.fr/public/mistral/leonore_fr?ACTION=CHERCHER&FIELD_1=COTE&VALUE_1='..id..' '..id..']'..p.getCatForId( 'Léonore' ) --no https as of 9/2019
end

function p.mbaLink( id )
	--P434's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/artist/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz' ) --special category name
end

function p.mbareaLink( id )
	--P982's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/area/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz area' ) --special category name
end

function p.mbiLink( id )
	--P1330's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/instrument/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz instrument' ) --special category name
end

function p.mblLink( id )
	--P966's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/label/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz label' ) --special category name
end

function p.mbpLink( id )
	--P1004's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/place/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz place' ) --special category name
end

function p.mbrgLink( id )
	--P436's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/release-group/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz release group' ) --special category name
end

function p.mbsLink( id )
	--P1407's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/series/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz series' ) --special category name
end

function p.mbwLink( id )
	--P435's format regex: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} (e.g. 12345678-1234-1234-1234-1234567890AB)
	if not id:match( '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$' ) then
		return false
	end
	return '[https://musicbrainz.org/work/'..id..' '..id..']'..p.getCatForId( 'MusicBrainz work' ) --special category name
end

function p.mgpLink( id )
	--P549's format regex: \d{1,6} (e.g. 123456)
	if not id:match( '^%d%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://genealogy.math.ndsu.nodak.edu/id.php?id='..id..' '..id..']'..p.getCatForId( 'MGP' )
end

function p.naraLink( id )
	--P1225's format regex: ^([1-9]\d{0,8})$ (e.g. 123456789)
	if not id:match( '^[1-9]%d?%d?%d?%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://catalog.archives.gov/id/'..id..' '..id..']'..p.getCatForId( 'NARA' )
end

function p.nclLink( id )
	--P1048's format regex: \d+ (e.g. 1081436)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[http://aleweb.ncl.edu.tw/F/?func=accref&acc_sequence='..id..'&CON_LNG=ENG '..id..']'..p.getCatForId( 'NCL' ) --no https as of 9/2019
end

function p.ndlLink( id )
	--P349's format regex: 0?\d{8} (e.g. 012345678)
	if not id:match( '^0?%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://id.ndl.go.jp/auth/ndlna/'..id..' '..id..']'..p.getCatForId( 'NDL' )
end

function p.ngvLink( id )
	--P2041's format regex: \d+ (e.g. 12354)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://www.ngv.vic.gov.au/explore/collection/artist/'..id..'/ '..id..']'..p.getCatForId( 'NGV' )
end

function p.nkcLink( id )
	--P691's format regex: [a-z]{2,4}[0-9]{2,14} (e.g. abcd12345678901234)
	if not id:match( '^[a-z][a-z][a-z]?[a-z]?%d%d%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://aleph.nkp.cz/F/?func=find-c&local_base=aut&ccl_term=ica='..id..'&CON_LNG=ENG '..id..']'..p.getCatForId( 'NKC' )
end

function p.nlaLink( id )
	--P409's format regex: [1-9][0-9]{0,11} (e.g. 123456789012)
	if not id:match( '^[1-9]%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://nla.gov.au/anbd.aut-an'..id..' '..id..']'..p.getCatForId( 'NLA' )
end

function p.nlgLink( id )
	--P3348's format regex: [1-9]\d* (e.g. 1)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://data.nlg.gr/resource/authority/record'..id..' '..id..']'..p.getCatForId( 'NLG' )
end

function p.nliLink( id )
	--P949's format regex: \d{9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://uli.nli.org.il/F/?func=direct&doc_number='..id..'&local_base=nlx10'..' '..id..']'..p.getCatForId( 'NLI' )
end

function p.nlkLink( id )
	--P5034's format regex: KA.(19|20).{7} (e.g. KAC201501465)
	if not id:match( '^KA.19.......$' ) and
	   not id:match( '^KA.20.......$' ) then
		return false
	end
	return '[https://nl.go.kr/authorities/resource/'..id..' '..id..']'..p.getCatForId( 'NLK' )
end

function p.nlpLink( id )
	--P1695's format regex: 9810[0-9]\d* or A[0-9]{7}[0-9X] (e.g. 9810123456789012345 or A10414836)
	if not id:match( '^9810%d+$' ) and
	   not id:match( '^A%d%d%d%d%d%d%d[%dX]$' ) then
		return false
	end
	return '[https://tools.wmflabs.org/wikidata-externalid-url?p=1695&id='..id..' '..id..']'..p.getCatForId( 'NLP' )
end

function p.nlrLink( id )
	--P1003's format regex: \d{9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://aleph.bibnat.ro:8991/F/?func=direct&local_base=NLR10&doc_number='..id..']'..p.getCatForId( 'NLR' )
end

function p.nskLink( id )
	--P1375's format regex: \d{9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d%d$' ) then
		return false
	end
	return '[http://katalog.nsk.hr/F/?func=direct&doc_number='..id..'&local_base=nsk10 '..id..']'..p.getCatForId( 'NSK' ) --no https as of 9/2019
end

function p.ntaLink( id )
	--P1006's format regex: \d{8}[\dX] (e.g. 12345678X)
	if not id:match( '^%d%d%d%d%d%d%d%d[%dX]$' ) then
		return false
	end
	return '[http://data.bibliotheken.nl/id/thes/p'..id..' '..id..']'..p.getCatForId( 'NTA' )
end

function p.orcidLink( id )
	id = p.validateIsni( id ) --e.g. 0000-0002-7398-5483
	if not id then
		return false
	end
	id = id:sub( 1, 4 )..'-'..id:sub( 5, 8 )..'-'..id:sub( 9, 12 )..'-'..id:sub( 13, 16 )
	return '[https://orcid.org/'..id..' '..id..']'..p.getCatForId( 'ORCID' )
end

function p.picLink( id )
	--P2750's format regex: [1-9]\d* (e.g. 1)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://pic.nypl.org/constituents/'..id..' '..id..']'..p.getCatForId( 'PIC' )
end

function p.ridLink( id )
	--P1053's format regex: [A-Z]{1,3}-\d{4}-20[0-2]\d   (e.g. AAS-5150-2020)
	if not id:match( '^[A-Z][A-Z]?[A-Z]?%-%d%d%d%d%-20[0-2]%d$' ) then
		return false
	end
	return '[https://www.researcherid.com/rid/'..id..' '..id..']'..p.getCatForId( 'RID' )
end

function p.reroLink( id )
	--P3065's format regex: 0[1-2]-[A-Z0-9]{1,10} (e.g. 02-A012345678)
	if not id:match( '^0[1-2]%-[A-Z%d][A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?[A-Z%d]?$' ) then
		return false
	end
	return '[http://data.rero.ch/'..id..' '..id..']'..p.getCatForId( 'RERO' )
end

function p.rkdartistsLink( id )
	--P650's format regex: [1-9]\d{0,5} (e.g. 123456)
	if not id:match( '^[1-9]%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://rkd.nl/en/explore/artists/'..id..' '..id..']'..p.getCatForId( 'RKDartists' )
end

function p.rkdidLink( id )
	--P350's format regex: [1-9]\d{0,5} (e.g. 123456)
	if not id:match( '^[1-9]%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[https://rkd.nl/nl/explore/images/'..id..' '..id..']'..p.getCatForId( 'RKDID' )
end

function p.rslLink( id )
	--P947's format regex: \d{1,9} (e.g. 123456789)
	if not id:match( '^%d%d?%d?%d?%d?%d?%d?%d?%d?$' ) then
		return false
	end
	return '[http://aleph.rsl.ru/F?func=find-b&find_code=SYS&adjacent=Y&local_base=RSL11&request='..id..'&CON_LNG=ENG '..id..']'..p.getCatForId( 'RSL' ) --no https as of 9/2019
end

function p.iccuLink( id )
	--P396's format regex: IT\\ICCU\\(\d{10}|\D\D[\D\d]\D\\\d{6}) (e.g. IT\ICCU\CFIV\000163)
	if not id:match( '^IT\\ICCU\\%d%d%d%d%d%d%d%d%d%d$' ) and
	   not id:match( '^IT\\ICCU\\%u%u[%u%d]%u\\%d%d%d%d%d%d$' ) then --legacy: %u used here instead of %D (but the faulty ID cat is empty, out of ~12k uses)
		return false
	end
	return '[https://opac.sbn.it/opacsbn/opac/iccu/scheda_authority.jsp?bid='..id..' '..id..']'..p.getCatForId( 'ICCU' ) end

function p.selibrLink( id )
	--P906's format regex: [1-9]\d{4,5} (e.g. 123456)
	if not id:match( '^[1-9]%d%d%d%d%d?$' ) then
		return false
	end
	return '[https://libris.kb.se/auth/'..id..' '..id..']'..p.getCatForId( 'SELIBR' )
end

function p.sikartLink( id )
	--P781's format regex: \d{7,9} (e.g. 123456789)
	if not id:match( '^%d%d%d%d%d%d%d%d?%d?$' ) then
		return false
	end
	return '[http://www.sikart.ch/KuenstlerInnen.aspx?id='..id..'&lng=en '..id..']'..p.getCatForId( 'SIKART' ) --no https as of 9/2019
end

function p.snacLink( id )
	--P3430's format regex: \d*[A-Za-z][0-9A-Za-z]* (e.g. A)
	if not id:match( '^%d*[A-Za-z][0-9A-Za-z]*$' ) then
		return false
	end
	return '[https://snaccooperative.org/ark:/99166/'..id..' '..id..']'..p.getCatForId( 'SNAC-ID' )
end

function p.sudocLink( id )
	--P269's format regex: (\d{8}[\dX]|) (e.g. 026927608)
	if not id:match( '^%d%d%d%d%d%d%d%d[%dxX]$' ) then --legacy: allow lowercase 'x'
		return false
	end
	return '[https://www.idref.fr/'..id..' '..id..']'..p.getCatForId( 'SUDOC' )
end

function p.s2authoridLink( id )
	--P4012's format regex: [1-9]\d* (e.g. 1796130)
	if not id:match( '^[1-9]%d*$' ) then
		return false
	end
	return '[https://www.semanticscholar.org/author/'..id..' '..id..']'..p.getCatForId( 'Semantic Scholar author' ) --special category name
end

function p.ta98Link( id )
	--P1323's format regex: A\d{2}\.\d\.\d{2}\.\d{3}[FM]? (e.g. A12.3.45.678)
	if not id:match( '^A%d%d%.%d%.%d%d%.%d%d%d[FM]?$' ) then
		return false
	end
	return '[http://tools.wmflabs.org/wikidata-externalid-url/?p=1323&url_prefix=https:%2F%2Fwww.unifr.ch%2Fifaa%2FPublic%2FEntryPage%2FTA98%20Tree%2FEntity%20TA98%20EN%2F&url_suffix=%20Entity%20TA98%20EN.htm&id='..id..' '..id..']'..p.getCatForId( 'TA98' )
end

function p.tdviaLink( id )
	--P7314's format regex: [a-z/-]+] (e.g. barkan-omer-lutfi)
	if not id:match( '^[a-z/-]+$' ) then
		return false
	end
	return '[https://islamansiklopedisi.org.tr/'..id..' '..id..']'..p.getCatForId( 'TDVİA' )
end

function p.teLink( id )
	--P1693's format regex: E[1-8]\.\d{1,2}\.\d{1,2}\.\d{1,2}\.\d{1}\.\d{1}\.\d{1,3} (e.g. E1.23.45.67.8.9.0)
	local e1, e2 = id:match( '^E([1-8])%.(%d%d?)%.%d%d?%.%d%d?%.%d%.%d%.%d%d?%d?$' )
	if not e1 then
		return false
	end
	local TEnum = 'TEe0'..e1 --no formatter URL in WD, probably due to this complexity
	if e1 == '5' or e1 == '7' then
		if #e2 == 1 then e2 = '0'..e2 end
		TEnum = TEnum..e2
	end
	return '[http://www.unifr.ch/ifaa/Public/EntryPage/ViewTE/'..TEnum..'.html '..id..']'..p.getCatForId( 'TE' )
end

function p.tepapaLink( id )
	--P3544's format regex: \d+ (e.g. 1)
	if not id:match( '^%d+$' ) then
		return false
	end
	return '[https://collections.tepapa.govt.nz/agent/'..id..' '..id..']'..p.getCatForId( 'TePapa' )
end

function p.thLink( id )
	--P1694's format regex: H\d\.\d{2}\.\d{2}\.\d\.\d{5} (e.g. H1.23.45.6.78901)
	local h1, h2 = id:match( '^H(%d)%.(%d%d)%.%d%d%.%d%.%d%d%d%d%d$' )
	if not h1 then
		return false
	end
	local THnum = 'THh'..h1..h2 --no formatter URL in WD, probably due to this complexity
	return '[http://www.unifr.ch/ifaa/Public/EntryPage/ViewTH/'..THnum..'.html '..id..']'..p.getCatForId( 'TH' )
end

function p.tlsLink( id )
	local id2 = id:gsub(' +', '_')
	--P1362's format regex: \p{Lu}[\p{L}\d_',\.\-\(\)\*/–]{3,59} (e.g. Abcd)
	local class = "[%a%d_',%.%-%(%)%*/–]"
	local regex = "^%u"..string.rep(class, 3)..string.rep(class.."?", 56).."$"
	if not mw.ustring.match( id2, regex ) then
		return false
	end
	return '[http://tls.theaterwissenschaft.ch/wiki/'..id2..' '..id..']'..p.getCatForId( 'TLS' ) --no https as of 9/2019
end

function p.troveLink( id )
	--P1315's format regex: [1-9]\d{5,7} (e.g. 12345678)
	if not id:match( '^[1-9]%d%d%d%d%d%d?%d?$' ) then
		return false
	end
	return '[https://trove.nla.gov.au/people/'..id..' '..id..']'..p.getCatForId( 'Trove' )
end

function p.ukparlLink( id )
	--P6213's format regex: [a-zA-Z\d]{8} (e.g. AQUupyiR)
	if not id:match( '^[a-zA-Z%d][a-zA-Z%d][a-zA-Z%d][a-zA-Z%d][a-zA-Z%d][a-zA-Z%d][a-zA-Z%d][a-zA-Z%d]$' ) then
		return false
	end
	return '[https://id.parliament.uk/'..id..' '..id..']'..p.getCatForId( 'UKPARL' )
end

function p.ulanLink( id )
	--P245's format regex: 500\d{6} (e.g. 500123456)
	if not id:match( '^500%d%d%d%d%d%d$' ) then
		return false
	end
	return '[https://www.getty.edu/vow/ULANFullDisplay?find=&role=&nation=&subjectid='..id..' '..id..']'..p.getCatForId( 'ULAN' )
end

function p.uscongressLink( id )
	--P1157's format regex: [A-Z]00[01]\d{3} (e.g. A000123)
	if not id:match( '^[A-Z]00[01]%d%d%d$' ) then
		return false
	end
	return '[http://bioguide.congress.gov/scripts/biodisplay.pl?index='..id..' '..id..']'..p.getCatForId( 'USCongress' ) --no https as of 9/2019
end

function p.vcbaLink( id )
	--P8034's format regex: \d{3}\/[1-9]\d{0,5} (e.g. 494/9793)
	if not id:match( '^%d%d%d\/[1-9]%d?%d?%d?%d?%d?$' ) then
		return false
	end
	local id2 = id:gsub('\/', '_')
	return '[https://opac.vatlib.it/auth/detail/'..id2..' '..id..']'..p.getCatForId( 'VcBA' )
end

function p.viafLink( id )
	--P214's format regex: [1-9]\d(\d{0,7}|\d{17,20}) (e.g. 123456789, 1234567890123456789012)
	if not id:match( '^[1-9]%d%d?%d?%d?%d?%d?%d?%d?$' ) and
	   not id:match( '^[1-9]%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d?%d?%d?$' ) then
		return false
	end
	return '[https://viaf.org/viaf/'..id..' '..id..']'..p.getCatForId( 'VIAF' )
end

--[[=========================== Helper functions =============================]]

function p.append(str, c, length)
	while str:len() < length do
		str = c .. str
	end
	return str
end

--Returns the ISNI check digit isni must be a string where the 15 first elements are digits, e.g. 0000000066534145
function p.getIsniCheckDigit( isni )
	local total = 0
	for i = 1, 15 do
		local digit = isni:byte( i ) - 48 --Get integer value
		total = (total + digit) * 2
	end
	local remainder = total % 11
	local result = (12 - remainder) % 11
	if result == 10 then
		return "X"
	end
	return tostring( result )
end

--Validate ISNI (and ORCID) and retuns it as a 16 characters string or returns false if it's invalid
--See http://support.orcid.org/knowledgebase/articles/116780-structure-of-the-orcid-identifier
function p.validateIsni( id )
	--P213 (ISNI) format regex: [0-9]{4} [0-9]{4} [0-9]{4} [0-9]{3}[0-9X] (e.g. 0000-0000-6653-4145)
	--P496 (ORCID) format regex: 0000-000(1-[5-9]|2-[0-9]|3-[0-4])\d{3}-\d{3}[\dX] (e.g. 0000-0002-7398-5483)
	id = id:gsub( '[ %-]', '' ):upper()
	if not id:match( '^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d[%dX]$' ) then
		return false
	end
	if p.getIsniCheckDigit( id ) ~= string.char( id:byte( 16 ) ) then
		return false
	end
	return id
end

function p.splitLccn( id )
	--P244's format regex: (n|nb|nr|no|ns|sh)([4-9][0-9]|00|20[0-1][0-9])[0-9]{6} (e.g. n78039510)
	if id:match( '^%l%l?%l?%d%d%d%d%d%d%d%d%d?%d?$' ) then
		id = id:gsub( '^(%l+)(%d+)(%d%d%d%d%d%d)$', '%1/%2/%3' )
	end
	if id:match( '^%l%l?%l?/%d%d%d?%d?/%d+$' ) then
		return mw.text.split( id, '/' )
	end
	return false
end

--[[==========================================================================]]
--[[          Wikidata, navigation bar, and documentation functions           ]]
--[[==========================================================================]]

function p.getIdsFromWikidata( itemId, property )
	local ids = {}
	local statements = mw.wikibase.getBestStatements( itemId, property )
	if statements then
		for _, statement in ipairs( statements ) do
			if statement.mainsnak.datavalue then
				table.insert( ids, statement.mainsnak.datavalue.value )
			end
		end
	end
	return ids
end

function p.matchesWikidataRequirements( itemId, reqs )
	for _, group in ipairs( reqs ) do
		local property = 'P'..group[1]
		local qid = group[2]
		local statements = mw.wikibase.getBestStatements( itemId, property )
		if statements then
			for _, statement in ipairs( statements ) do
				if statement.mainsnak.datavalue then
					if statement.mainsnak.datavalue.value['numeric-id'] == qid then
						return true
	end	end	end	end	end
	return false
end

function p.createRow( id, label, rawValue, link, withUid, specialCat )
	if link then
		if withUid then
			return '*<span class="nowrap">'..label..' <span class="uid">'..link..'</span></span>\n'
		end
		return '*<span class="nowrap">'..label..' '..link..'</span>\n'
	end

	local catName = 'Wikipedia articles with faulty '..(specialCat or id)..' identifiers'
	return '* <span class="error">The '..id..' id '..rawValue..' is not valid.</span>[[Category:'..catName..']]'..p.redCatLink(catName)..'\n'
end

-- Creates a human-readable standalone wikitable version of p.conf, and tracking categories with page counts, for use in the documentation
function p.docConfTable( frame )
	local wikiTable = '{| class="wikitable sortable"\n'..
					  '! rowspan=2 | Parameter\n'..
					  '! rowspan=2 | Label\n'..
					  '! rowspan=2; data-sort-type=number | Wikidata property\n'..
					  '! colspan=4 | Tracking categories and page counts\n'..
					  '|-\n'..
					  '! [[:Category:Wikipedia articles with authority control information|'..       'Articles]]\n'..
					  '! [[:Category:User pages with authority control information|'..               'User pages]]\n'..
					  '! [[:Category:Miscellaneous pages with authority control information|'..      'Misc. pages]]\n'..
					  '! [[:Category:Wikipedia articles with faulty authority control information|'..'Faulty IDs]]\n'..
					  '|-\n'
	
	local lang = mw.getContentLanguage()
	for _, conf in pairs( p.conf ) do
		local param, link, pid = conf[1], conf[2], conf[3]
		local category = conf.category or param
		local args = { id = 'f', pid }
		local wpl = frame:expandTemplate{ title = 'Wikidata property link', args = args }
		--cats
		local articleCat = 'Wikipedia articles with '..category..' identifiers'
		local userCat =    'User pages with '..category..' identifiers'
		local miscCat =    'Miscellaneous pages with '..category..' identifiers'
		local faultyCat =  'Wikipedia articles with faulty '..category..' identifiers'
		--counts
		local articleCount = lang:formatNum( mw.site.stats.pagesInCategory(articleCat, 'pages') )
		local userCount =    lang:formatNum( mw.site.stats.pagesInCategory(userCat, 'pages') )
		local miscCount =    lang:formatNum( mw.site.stats.pagesInCategory(miscCat, 'pages') )
		local faultyCount =  lang:formatNum( mw.site.stats.pagesInCategory(faultyCat, 'pages') )
		--concat
		wikiTable = wikiTable..'\n'..
					'|-\n'..
					'||'..param..
					'||'..link..
					'||data-sort-value='..pid..'|'..wpl..
					'||style="text-align: right;"|[[:Category:'..articleCat..'|'..articleCount..']]'..
					'||style="text-align: right;"|[[:Category:'..   userCat..'|'..   userCount..']]'..
					'||style="text-align: right;"|[[:Category:'..   miscCat..'|'..   miscCount..']]'..
					'||style="text-align: right;"|[[:Category:'.. faultyCat..'|'.. faultyCount..']]'
	end
	return wikiTable..'\n|}'
end

--[[==========================================================================]]
--[[                              Configuration                               ]]
--[[==========================================================================]]

-- If a specific "(identifier) redirect" exists for an identifier, please route through this particular redirect rather than linking directly to the target page. This reduces clutter in "What links here" and improves reverse lookup of articles where a manifestation of this particular identifier is used.

-- Check that the Wikidata item has this property-->value before adding it
local reqs = {}

-- Parameter format: { 'parameter name', 'label', propertyId # in Wikidata, formatting/validation function }
p.conf = {
	{ 'AAG', '[[Auckland Art Gallery Toi o Tāmaki|AAG]]', 3372, p.aagLink },
	{ 'ACM-DL', '[[Association for Computing Machinery#Portal and Digital Library|ACM DL]]', 864, p.acmLink },
	{ 'ADB', '[[Australian Dictionary of Biography|ADB]]', 1907, p.adbLink },
	{ 'AGSA', '[[Art Gallery of South Australia|AGSA]]', 6804, p.agsaLink },
	{ 'autores.uy', '[[autores.uy]]', 2558, p.autoresuyLink },
	{ 'AWR', '[[Australian Women\'s Register|AWR]]', 4186, p.awrLink },
	{ 'BALaT', '[[Royal Institute for Cultural Heritage#Online artworks pages|BALaT]]', 3293, p.balatLink },
	{ 'BIBSYS', '[[Bibsys|BIBSYS]]', 1015, p.bibsysLink },
	{ 'Bildindex', '[[Marburg Picture Index|Bildindex]]', 2092, p.bildLink },
	{ 'BNC', '[[National Library of Chile|BNC]]', 1890, p.bncLink },
	{ 'BNE', '[[Biblioteca Nacional de España|BNE]]', 950, p.bneLink },
	{ 'BNF', '[[BNF (identifier)|BNF]]', 268, p.bnfLink },
	{ 'Botanist', '[[Author citation (botany)|Botanist]]', 428, p.botanistLink },
	{ 'BPN', '[[Biografisch Portaal|BPN]]', 651, p.bpnLink },
	{ 'CANTIC', '[[Name and Title Authority File of Catalonia|CANTIC]]', 1273, p.canticLink },
	{ 'CINII', '[[CiNii (identifier)|CiNii]]', 271, p.ciniiLink },
	{ 'CWGC', '[[Commonwealth War Graves Commission|CWGC]]', 1908, p.cwgcLink },
	{ 'DAAO', '[[Dictionary of Australian Artists|DAAO]]', 1707, p.daaoLink },
	{ 'DBLP', '[[DBLP]]', 2456, p.dblpLink },
	{ 'DSI', '[[Stuttgart Database of Scientific Illustrators 1450–1950|DSI]]', 2349, p.dsiLink },
	{ 'FNZA', '[[:d:Property:P6792|FNZA]]', 6792, p.fnzaLink },
	{ 'GND', '[[GND (identifier)|GND]]', 227, p.gndLink },
	{ 'HDS', '[[Historical Dictionary of Switzerland|HDS]]', 902, p.hdsLink },
	{ 'IAAF', '[[World Athletics]]', 1146, p.iaafLink },
	{ 'ICCU', '[[ICCU (identifier)|ICCU]]', 396, p.iccuLink }, --formerly SBN
	{ 'ICIA', '[[Information Center for Israeli Art|ICIA]]', 1736, p.iciaLink },
	{ 'ISNI', '[[ISNI (identifier)|ISNI]]', 213, p.isniLink },
	{ 'Joconde', '[[Joconde]]' , 347, p.jocondeLink },
	{ 'KULTURNAV', '[[KulturNav]]', 1248, p.kulturnavLink },
	{ 'LCCN', '[[LCCN (identifier)|LCCN]]', 244, p.lccnLink },
	{ 'LIR', '[[Historical Dictionary of Switzerland#Lexicon_Istoric_Retic|LIR]]', 886, p.lirLink },
	{ 'LNB', '[[National Library of Latvia|LNB]]', 1368, p.lnbLink },
	{ 'Léonore', '[[Base Léonore|Léonore]]', 640, p.leonoreLink },
	{ 'MBA', '[[MusicBrainz]]', 434, p.mbaLink, category = 'MusicBrainz' }, --special category name
	{ 'MBAREA', '[[MusicBrainz]]', 982, p.mbareaLink, category = 'MusicBrainz area' }, --special category name
	{ 'MBI', '[[MusicBrainz]]', 1330, p.mbiLink, category = 'MusicBrainz instrument' }, --special category name
	{ 'MBL', '[[MusicBrainz]]', 966, p.mblLink, category = 'MusicBrainz label' }, --special category name
	{ 'MBP', '[[MusicBrainz]]', 1004, p.mbpLink, category = 'MusicBrainz place' }, --special category name
	{ 'MBRG', '[[MusicBrainz]] release group', 436, p.mbrgLink, category = 'MusicBrainz release group' }, --special category name
	{ 'MBS', '[[MusicBrainz]]', 1407, p.mbsLink, category = 'MusicBrainz series' }, --special category name
	{ 'MBW', '[[MusicBrainz]] work', 435, p.mbwLink, category = 'MusicBrainz work' }, --special category name
	{ 'MGP', '[[Mathematics Genealogy Project|MGP]]', 549, p.mgpLink },
	{ 'NARA', '[[National Archives and Records Administration|NARA]]', 1225, p.naraLink },
	{ 'NCL', '[[National Central Library|NCL]]', 1048, p.nclLink },
	{ 'NDL', '[[National Diet Library|NDL]]', 349, p.ndlLink },
	{ 'NGV', '[[National Gallery of Victoria|NGV]]', 2041, p.ngvLink },
	{ 'NKC', '[[National Library of the Czech Republic|NKC]]', 691, p.nkcLink },
	{ 'NLA', '[[National Library of Australia|NLA]]', 409, p.nlaLink },
	{ 'NLG', '[[National Library of Greece|NLG]]', 3348, p.nlgLink },
	{ 'NLI', '[[National Library of Israel|NLI]]', 949, p.nliLink },
	{ 'NLK', '[[National Library of Korea|NLK]]', 5034, p.nlkLink },
	{ 'NLP', '[[National Library of Poland|NLP]]', 1695, p.nlpLink },
	{ 'NLR', '[[National Library of Romania|NLR]]', 1003, p.nlrLink },
	{ 'NSK', '[[National and University Library in Zagreb|NSK]]', 1375, p.nskLink },
	{ 'NTA', '[[Royal Library of the Netherlands|NTA]]', 1006, p.ntaLink },
	{ 'ORCID', '[[ORCID (identifier)|ORCID]]', 496, p.orcidLink },
	{ 'PIC', '[[:d:Q23892012|PIC]]', 2750, p.picLink },
	{ 'RID', '[[ResearcherID]]', 1053, p.ridLink },
	{ 'RERO', '[[RERO (Library Network of Western Switzerland)|RERO]]', 3065, p.reroLink },
	{ 'RKDartists', '[[Netherlands Institute for Art History#Online artist pages|RKD]]', 650, p.rkdartistsLink },
	{ 'RKDID', '[[Netherlands Institute for Art History#Online artworks pages|RKDimages ID]]', 350, p.rkdidLink },
	{ 'RSL', '[[Russian State Library|RSL]]', 947, p.rslLink },
	{ 'SELIBR', '[[SELIBR (identifier)|SELIBR]]', 906, p.selibrLink },
	{ 'SIKART', '[[SIKART]]', 781, p.sikartLink },
	{ 'SNAC-ID', '[[SNAC]]', 3430, p.snacLink },
	{ 'SUDOC', '[[SUDOC (identifier)|SUDOC]]', 269, p.sudocLink },
	{ 'S2AuthorId', '[[Semantic Scholar|S2AuthorId]]', 4012, p.s2authoridLink, category = 'Semantic Scholar author' }, --special category name
	{ 'TA98', '[[Terminologia Anatomica|TA98]]', 1323, p.ta98Link },
	{ 'TDVİA', '[[İslâm Ansiklopedisi|TDVİA]]', 7314, p.tdviaLink },
	{ 'TE', '[[Terminologia Embryologica|TE]]', 1693, p.teLink },
	{ 'TePapa', '[[Museum of New Zealand Te Papa Tongarewa|TePapa]]', 3544, p.tepapaLink },
	{ 'TH', '[[Terminologia Histologica|TH]]', 1694, p.thLink },
	{ 'TLS', '[[Theaterlexikon der Schweiz|TLS]]', 1362, p.tlsLink },
	{ 'Trove', '[[Trove]]', 1315, p.troveLink }, --formerly NLA-person
	{ 'UKPARL', '[[UKPARL (identifier)|UKPARL]]', 6213, p.ukparlLink },
	{ 'ULAN', '[[Union List of Artist Names|ULAN]]', 245, p.ulanLink },
	{ 'USCongress', '[[Biographical Directory of the United States Congress|US Congress]]', 1157, p.uscongressLink },
	{ 'VcBA', '[[VcBA (identifier)|VcBA]]', 8034, p.vcbaLink },
	{ 'VIAF', '[[VIAF (identifier)|VIAF]]', 214, p.viafLink },
	{ 'WORLDCATID', '[[WorldCat Identities (identifier)|WorldCat Identities]]', 7859, nil },
}

-- Legitimate aliases to p.conf, for convenience
-- Format: { 'alias', 'parameter name in p.conf' }
p.aliases = {
	{ 'MusicBrainz', 'MBA' },
	{ 'MusicBrainz artist', 'MBA' },
	{ 'MusicBrainz label', 'MBL' },
	{ 'MusicBrainz release group', 'MBRG' },
	{ 'MusicBrainz work', 'MBW' },
	{ 'Leonore', 'Léonore' }, --alias name without diacritics
	{ 'leonore', 'Léonore' }, --lowercase variant without diacritics
        { 'SBN', 'ICCU' }, --SBN alias to be deprecated at a later stage
	{ 'TDVIA', 'TDVİA' }, --alias name without diacritics
	{ 'tdvia', 'TDVİA' }, --lowercase variant without diacritics
}

-- Deprecated aliases to p.conf; tracked in [[Category:Wikipedia articles with deprecated authority control identifiers]]
-- Format: { 'deprecated parameter name', 'replacement parameter name in p.conf' }
p.deprecated = {
	{ 'GKD', 'GND' },
	{ 'PND', 'GND' },
	{ 'RLS', 'RSL' },	
	{ 'SWD', 'GND' },
	{ 'NARA-organization', 'NARA' },
	{ 'NARA-person', 'NARA' },
}

--[[==========================================================================]]
--[[                                   Main                                   ]]
--[[==========================================================================]]

function p.authorityControl( frame )
	local resolveEntity = require( "Module:ResolveEntityId" )
	local parentArgs = frame:getParent().args
	local elements = {} --create/insert rows later
	local worldcatCat = ''
	local suppressedIdCat = ''
	local deprecatedIdCat = ''
	
	--Redirect aliases to proper parameter names
	for _, a in pairs( p.aliases ) do
		local alias, param = a[1], a[2]
		if (parentArgs[param] == nil or parentArgs[param] == '') and parentArgs[alias] then
			parentArgs[param] = parentArgs[alias]
		end
	end
	
	--Redirect deprecated parameters to proper parameter names, and assign tracking cat
	for _, d in pairs( p.deprecated ) do
		local dep, param = d[1], d[2]
		if (parentArgs[param] == nil or parentArgs[param] == '') and parentArgs[dep] then
			parentArgs[param] = parentArgs[dep]
			if namespace == 0 then
				deprecatedIdCat = '[[Category:Wikipedia articles with deprecated authority control identifiers|'..dep..']]'
			end
		end
	end
	
	--Use QID= parameter for testing/example purposes only
	local itemId = nil
	if namespace ~= 0 then
		local qid = parentArgs['qid'] or parentArgs['QID']
		if qid then
			itemId = 'Q'..mw.ustring.gsub(qid, '^[Qq]', '')
			itemId = resolveEntity._id(itemId) --nil if unresolvable
		end
	else
		itemId = mw.wikibase.getEntityIdForCurrentPage()
	end
	
	--Wikidata fallback if requested
	if itemId then
		for _, params in ipairs( p.conf ) do
			if params[3] > 0 then
				local val = parentArgs[mw.ustring.lower(params[1])] or parentArgs[params[1]]
				if val == nil or val == '' then
					local canUseWikidata = nil
					if reqs[params[1]] then
						canUseWikidata = p.matchesWikidataRequirements( itemId, reqs[params[1]] )
					else
						canUseWikidata = true
					end
					if canUseWikidata then
						local wikidataIds = p.getIdsFromWikidata( itemId, 'P'..params[3] )
						if wikidataIds[1] then
							if val == '' and (namespace == 0 or testcases) then
								suppressedIdCat = '[[Category:Wikipedia articles with suppressed authority control identifiers|'..params[1]..']]'
							else
								parentArgs[params[1]] = wikidataIds[1]
	end	end	end	end	end	end	end
	
	--Configured rows
	local rct = 0
	for _, params in ipairs( p.conf ) do
		local val = parentArgs[mw.ustring.lower(params[1])] or parentArgs[params[1]]
		if val and val ~= '' and type(params[4]) == 'function' then
			table.insert( elements, p.createRow( params[1], params[2]..':', val, params[4]( val ), true, params.category ) )
			rct = rct + 1
		end
	end
	
	--WorldCat
	local worldcatId = parentArgs['worldcatid'] or parentArgs['WORLDCATID']
	if worldcatId and worldcatId ~= '' then --if WORLDCATID present & unsuppressed
		table.insert( elements, p.createRow( 'WORLDCATID', '', worldcatId, '[[WorldCat Identities (identifier)|WorldCat Identities]]: [https://www.worldcat.org/identities/'..mw.uri.encode(worldcatId, 'PATH')..' '..worldcatId..']', false ) ) --Validation?
		worldcatCat = '[[Category:Wikipedia articles with WorldCat identifiers]]'
	elseif worldcatId == nil then --if WORLDCATID absent but unsuppressed
		local viafId = parentArgs['viaf'] or parentArgs['VIAF']
		local lccnId = parentArgs['lccn'] or parentArgs['LCCN']
		if viafId and viafId ~= '' and p.viafLink( viafId ) then --VIAF must be present, unsuppressed, & validated
			table.insert( elements, p.createRow( 'VIAF', '', viafId, '[[WorldCat Identities (identifier)|WorldCat Identities]] (via VIAF): [https://www.worldcat.org/identities/containsVIAFID/'..viafId..' '..viafId..']', false ) )
			if namespace == 0 then 
				worldcatCat = '[[Category:Wikipedia articles with WorldCat-VIAF identifiers]]'
			end
		elseif lccnId and lccnId ~= '' and p.lccnLink( lccnId ) then --LCCN must be present, unsuppressed, & validated
			local lccnParts = p.splitLccn( lccnId )
			if lccnParts and lccnParts[1] ~= 'sh' then
				local lccnIdFmtd = lccnParts[1]..lccnParts[2]..'-'..lccnParts[3]
				table.insert( elements, p.createRow( 'LCCN', '', lccnId, '[[WorldCat Identities (identifier)|WorldCat Identities]] (via LCCN): [https://www.worldcat.org/identities/lccn-'..lccnIdFmtd..' '..lccnIdFmtd..']', false ) )
				if namespace == 0 then
					worldcatCat = '[[Category:Wikipedia articles with WorldCat-LCCN identifiers]]'
				end
			end
		end
	elseif worldcatId == '' then --if WORLDCATID suppressed
		suppressedIdCat = '[[Category:Wikipedia articles with suppressed authority control identifiers|WORLDCATID]]'
	end
	
	local Navbox = require('Module:Navbox')
	local elementsCat = ''
	if rct == 0 or rct >= 25 then
		local eCat = 'AC with '..rct..' elements'
		elementsCat  = '[[Category:'..eCat..']]'..p.redCatLink(eCat)
	end
	
	local outString = ''
	if #elements > 0 then
		local args = { pid = 'identifiers' } -- #target the list of identifiers
		if testcases and itemId then args = { pid = 'identifiers', qid = itemId } end --expensive
		local pencil = frame:expandTemplate{ title = 'EditAtWikidata', args = args}
		outString = Navbox._navbox( {
			name  = 'Authority control',
			navboxclass = 'authority-control',
			bodyclass = 'hlist',
			group1 = '[[Help:Authority control|Authority control]]'..pencil,
			list1 = table.concat( elements )
			} )
	end

	local auxCats = worldcatCat .. elementsCat .. suppressedIdCat .. deprecatedIdCat
	if testcases then
		auxCats = mw.ustring.gsub(auxCats, '(%[%[)(Category)', '%1:%2') --for easier checking
	end
	outString = outString .. auxCats
	if namespace ~= 0 then
		outString = mw.ustring.gsub(outString, '(%[%[)(Category:Wikipedia articles)', '%1:%2') --by definition
	end
	
	return outString
end

return p