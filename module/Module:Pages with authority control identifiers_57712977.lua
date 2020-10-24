require('Module:No globals')

local p = {}
local ac_conf = require('Module:Authority control').conf
local currentTitle = mw.title.getCurrentTitle()
local title = currentTitle.text
local isCat = (currentTitle.namespace == 14)

--[[==========================================================================]]
--[[                         Local Utility Functions                          ]]
--[[==========================================================================]]

local function whichTOC( frame )
	--local pageCount = mw.site.stats.pagesInCategory(title, 'pages')
	--if pageCount > 1200 then
	--	return frame:expandTemplate{ title = 'Large category TOC' }
	--elseif pageCount > 100 then
	--	return frame:expandTemplate{ title = 'Category TOC', args = { align = 'center' } }
	--end
	--return ''
	
	-- standardize TOC behavior via {{CatAutoTOC}}
	return frame:expandTemplate{ title = 'CatAutoTOC', args = { align = 'center' } }
end

local function redCatCheck( catName ) --catName == 'Blah', not 'Category:Blah', not '[[Category:Blah]]'
	if catName and catName ~= '' and mw.title.new(catName, 14).exists == false then
		return '[[Category:Pages with authority control identifiers red-linked category]]'
	end
	return ''
end

--[[==========================================================================]]
--[[                    Local Category-Specific Functions                     ]]
--[[==========================================================================]]

--For use in [[Category:Pages with authority control information]],
--   i.e. on [[Category:Pages with VIAF identifiers]]
local function pages( frame, id )
	for _, conf in pairs( ac_conf ) do
		if conf.category == id or conf[1] == id then
			local link = conf[2] --not used locally yet
			local txCatMore = frame:expandTemplate{ title = 'Cat more', args = {'Wikipedia:Authority control'} }
			local txWPCat   = frame:expandTemplate{ title = 'Wikipedia category' }
			local pagesCat = 'Pages with authority control information'
			local outString = txCatMore..txWPCat..'\n'..
					'[[Category:'..pagesCat..'|'..id..']]'..redCatCheck(pagesCat)
			return outString
		end
	end
	return ''
end

--For use in [[Category:Miscellaneous pages with authority control information]],
--   i.e. on [[Category:Miscellaneous pages with VIAF identifiers]]
local function misc( frame, id )
	for _, conf in pairs( ac_conf ) do
		if conf.category == id or conf[1] == id then
			local link = conf[2]
			local txCatExplain = frame:expandTemplate{ title = 'Category explanation', 
					args = { 'pages, other than main user pages or Wikipedia articles, using {{[[Template:Authority control|Authority control]]}} with '..link..' identifiers.' } }
			local txCatMore  = frame:expandTemplate{ title = 'Cat more', args = {'Wikipedia:Authority control'} }
			local txEmptyCat = frame:expandTemplate{ title = 'Possibly empty category' }
			local txWPCat    = frame:expandTemplate{ title = 'Wikipedia category', args = { hidden = 'yes', tracking = 'yes' } }
			local txTOC = whichTOC( frame )
			local idCat = 'Pages with '..id..' identifiers'
			local miscCat = 'Miscellaneous pages with authority control information'
			local outString = txCatExplain..txCatMore..txEmptyCat..txWPCat..txTOC..'\n'..
					'Pages in this category should only be added by [[Module:Authority control]].'..
					'[[Category:'..idCat..']]'..redCatCheck(idCat)..
					'[[Category:'..miscCat..'|'..id..']]'..redCatCheck(miscCat)
			return outString
		end
	end
	return ''
end

--For use in [[Category:User pages with authority control information]],
--   i.e. on [[Category:User pages with VIAF identifiers]]
local function user( frame, id )
	for _, conf in pairs( ac_conf ) do
		if conf.category == id or conf[1] == id then
			local link = conf[2] --not used locally yet
			local txCatMore  = frame:expandTemplate{ title = 'Cat more', args = {'Wikipedia:Authority control'} }
			local txEmptyCat = frame:expandTemplate{ title = 'Possibly empty category' }
			local txWPCat    = frame:expandTemplate{ title = 'Wikipedia category', args = { hidden = 'yes', tracking = 'yes' } }
			local txTOC = whichTOC( frame )
			local idCat = 'Pages with '..id..' identifiers'
			local userCat = 'User pages with authority control information'
			local outString = txCatMore..txEmptyCat..txWPCat..txTOC..'\n'..
					'Pages in this category should only be added by [[Module:Authority control]].'..
					'[[Category:'..idCat..']]'..redCatCheck(idCat)..
					'[[Category:'..userCat..'|'..id..']]'..redCatCheck(userCat)
			return outString
		end
	end
	return ''
end

--For use in [[Category:Wikipedia articles with authority control information]],
--   i.e. on [[Category:Wikipedia articles with VIAF identifiers]]
local function wp( frame, id )
	for _, conf in pairs( ac_conf ) do
		if conf.category == id or conf[1] == id then
			local link = conf[2]
			local txCatExplain = frame:expandTemplate{ title = 'Category explanation', args = {'articles with '..link..' identifiers. Please do not add [[Wikipedia:Categorization#Subcategorization|subcategories]].'} }
			local txCatMore    = frame:expandTemplate{ title = 'Cat more', args = {'Wikipedia:Authority control'} }
			local txEmptyCat   = frame:expandTemplate{ title = 'Possibly empty category' }
			local txWPCat      = frame:expandTemplate{ title = 'Wikipedia category', args = { hidden = 'yes', tracking = 'yes' } }
			local txTOC = whichTOC( frame )
			local idCat = 'Pages with '..id..' identifiers'
			local wpCat = 'Wikipedia articles with authority control information'
			local outString = txCatExplain..txCatMore..txEmptyCat..txWPCat..txTOC..'\n'..
					'Pages in this category should only be added by [[Module:Authority control]].'..
					'[[Category:'..idCat..']]'..redCatCheck(idCat)..
					'[[Category:'..wpCat..'|'..id..']]'..redCatCheck(wpCat)
			return outString
		end
	end
	return ''
end

--For use in [[Category:Wikipedia articles with faulty authority control information]],
--   i.e. on [[Category:Wikipedia articles with faulty VIAF identifiers]]
local function wpfaulty( frame, id )
	for _, conf in pairs( ac_conf ) do
		if conf.category == id or conf[1] == id then
			local link = conf[2] --not used locally yet
			local param = conf[3]
			local txCatMore  = frame:expandTemplate{ title = 'Cat more', args = {'Wikipedia:Authority control', 'd:Property:P'..param} }
			local txEmptyCat = frame:expandTemplate{ title = 'Possibly empty category' }
			local txWPCat    = frame:expandTemplate{ title = 'Wikipedia category', args = { hidden = 'yes', tracking = 'yes' } }
			local txDirtyCat = frame:expandTemplate{ title = 'Polluted category' }
			local txTOC = whichTOC( frame )
			local idCat = 'Pages with '..id..' identifiers'
			local wpfCat = 'Wikipedia articles with faulty authority control information'
			local outString = txCatMore..txEmptyCat..txWPCat..txDirtyCat..txTOC..'\n'..
					'Pages in this category should only be added by [[Module:Authority control]].'..
					'[[Category:'..idCat..']]'..redCatCheck(idCat)..
					'[[Category:'..wpfCat..'|'..id..']]'..redCatCheck(wpfCat)
			return outString
		end
	end
	return ''
end

--[[==========================================================================]]
--[[                            Main/External Call                            ]]
--[[==========================================================================]]
function p.autoDetect( frame )
	if isCat then
		local pagesID    = mw.ustring.match(title, 'Pages with ([%w%.%- ]+) identifiers')
		local miscID     = mw.ustring.match(title, 'Miscellaneous pages with ([%w%.%- ]+) identifiers')
		local userID     = mw.ustring.match(title, 'User pages with ([%w%.%- ]+) identifiers')
		local wpfaultyID = mw.ustring.match(title, 'Wikipedia articles with faulty ([%w%.%- ]+) identifiers')
		local wpID       = mw.ustring.match(title, 'Wikipedia articles with ([%w%.%- ]+) identifiers')
		
		if     pagesID    then return pages( frame, pagesID )
		elseif miscID     then return misc( frame, miscID )
		elseif userID     then return user( frame, userID )
		elseif wpfaultyID then return wpfaulty( frame, wpfaultyID ) --must be before wpID check, in case they both match
		elseif wpID       then return wp( frame, wpID )             --to keep the regex simple
		else   return '[[Category:Pages with authority control identifiers unknown category]]'
		end
	end
	return ''
end

return p