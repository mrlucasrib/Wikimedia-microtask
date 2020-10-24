--[[
  v 10
  subpages renamed
  testing
  - we have output
  - portal checking done, but output not working
  - full country-checking list is working
  - data moved to sub-modules
  
  Now working on fixing countries prefixed by "the"
  
  ToDo in further versions:
  * Tracking categories
  * error messages
  * Tidyup code
]]

-- config
local textSize = '90%'
local tableClass="toc"
local tableFallbackMaxWidth="auto"
local tableMaxWidth="calc(100% - 25em)" -- Template:GeoGroup has width: 23em<
local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; width:auto; font-weight:normal; "
local basicRowStyle="padding:0.3em 0.7em 0.3em 0.3em; vertical-align:top; text-align:left; border-top:1px solid darkgray; "
local headerRowStyle="font-weight:normal; text-align:center; background-color:#f3f3f3"
local headerCellStyle = "text-align:center; background-color:#f3f3f3;"
local evenRowStyle = "" --background-color:#f3f3f3;"
local oddRowStyle = ""
local footerRowStyle="text-align:center; background-color:#f3f3f3; border-top:1px solid darkgray; "
local footerCellStyle = "text-align:center; border-top:1px solid darkgray; background-color:#f3f3f3; "
local labelStyle = "text-align:right; font-weight: bold; padding: 0.25em 0.5em 0.25em 0.5em;"
local listStyle = "text-align:left; font-weight: normal; padding: 0.25em 0.5em 0.25em 0.5em;"
local greyLinkColor = "#888"
local defaultPortals = {
	"Human migration"
}

-- Behaviour switches
local portalsEnabled = true
local debuggingEnabled = false
-- local debuggingEnabled = true

-- globals for this module
local debugmsg = ""
local tableRowNum = 0
local greyLinkCount = 0
local blueLinkCount = 0
local parentname = ""
local templateName
local countryName1 = nil
local countryName2 = nil
local myTrackingCategories = "" 

local countryAdjectivesToNounsTable = {
}
local countryNounstoAdjectivesTable  = {
}

local countriesPrefixedByThe = {
}

-- if the country name is prefixed by "the" in running text,
-- then return that prefix
-- Otherwise just return an empty string
function countryPrefixThe(s)
	if (countriesPrefixedByThe[s] == true) then
		return "the "
	end
	return ""
end


-- other modules
local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local p = {}

-- converts first character of a string to uppercase
-- while leaving the rest unchanged
function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function makeTrackingCategory()
	-- discount this page, which will always be coded as a blue link, but rendered as bold un-navigable
	blueLinkCount = blueLinkCount - 1
	if greyLinkCount == 0 then
		return "[[Category:" .. templateName .. " with no grey links]]"
	end
	if blueLinkCount == 0 then
		return "[[Category:" .. templateName .. " with all grey links]]"
	end
	if greyLinkCount > 5 then
		return "[[Category:" .. templateName .. " with over 5 grey links]]"
	elseif greyLinkCount > 3 then
		return "[[Category:" .. templateName .. " with over 3 grey links]]"
	elseif greyLinkCount < 3 then
		return "[[Category:" .. templateName .. " with fewer than 3 grey links]]"
	end
	return ""
end

function makeTableRow(rowLabel, countryA, countryB)
	tableRowNum = tableRowNum + 1
	debugLog(3, string.format("makeTableRow #%d", tableRowNum))
	local rowLabel = string.format("%s in %s%s", getAdjectiveFromCountry(countryA), countryPrefixThe(countryB), countryB)
	debugLog(4, "rowLabel=" .. rowLabel)
	local thisRow
	if (tableRowNum % 2) == 0 then
		debugLog(4, "Even-numbered")
		thisRow = '<tr style="' .. basicRowStyle .. evenRowStyle .. '">\n'
	else
		debugLog(4, "Odd-numbered")
		thisRow = '<tr style="' .. basicRowStyle .. oddRowStyle .. '">\n'
	end
	thisRow = thisRow .. '<td style="' .. labelStyle .. '">' .. rowLabel .. '</td>\n'
	thisRow = thisRow .. '<td style="' .. listStyle .. ';"><div class="hlist">\n'
	-- now begin making the row contents
	thisRow = thisRow .. '* ' .. makeCatLink(string.format("%s expatriates in %s%s", getAdjectiveFromCountry(countryA), countryPrefixThe(countryB), countryB), "Expatriates") .. '\n'
	thisRow = thisRow .. '* <small>' .. makeCatLink(string.format("%s expatriate sportspeople in %s%s", getAdjectiveFromCountry(countryA), countryPrefixThe(countryB), countryB), "(sportspeople)") .. '</small>\n'
	thisRow = thisRow .. '* ' .. makeCatLink(string.format("%s emigrants to %s%s", getAdjectiveFromCountry(countryA), countryPrefixThe(countryB), countryB), "Emigrants") .. '\n'
	thisRow = thisRow .. '* ' .. makeCatLink(string.format("%s people of %s descent", getAdjectiveFromCountry(countryB), getAdjectiveFromCountry(countryA)), "Descent") .. '\n'
	local diasporaCatName = string.format("%s diaspora in %s%s", getAdjectiveFromCountry(countryA), countryPrefixThe(countryB), countryB)
	if (doesPageExist(diasporaCatName, "Category")) then
			thisRow = thisRow .. '* ' .. makeCatLink(diasporaCatName, "Diaspora") .. '\n'
	end
	thisRow = thisRow .. '</div></td>\n</tr>'
	debugLog(4, "Made the row")
	return thisRow
end


function makeTable()
	debugLog(1, "makeTable")
	debugLog(2, "countryName1=")
	if (countryName1 == nil) then
		debugLog(nil, "nil")
	else
		debugLog(nil, countryName1)
	end
	debugLog(2, "countryName2=")
	if (countryName2 == nil) then
		debugLog(nil, "nil")
	else
		debugLog(nil, countryName2)
	end
	
	-- sort country names
	debugLog(2, "checking sort order: ")
	if (countryName1 <= countryName2) then
		debugLog(nil, "checking sort order: OK")
	else
		debugLog(nil, "checking sort order: need to be swapped")
		local swapSpace = countryName1
		countryName1 = countryName2
		countryName2 = swapSpace
		debugLog(3, "Swapped.: Now countryName1=[%s], and countryName2=[%s]", countryName1, countryName2)
	end

	tableRowNum = 0
	local myTable = '<table class="' .. tableClass .. '"'
	myTable = myTable .. ' style="' .. tableStyle .. '; font-size:' .. textSize .. '; max-width:' .. tableFallbackMaxWidth .. '; max-width:' .. tableMaxWidth ..'">\n'

	-- first make the header row
	tableRowNum = tableRowNum + 1
	myTable = myTable .. "<tr style = " .. basicRowStyle .. headerRowStyle .. ">\n"
	myTable = myTable .. "<td colspan='2' style='" .. headerCellStyle .. "'>"
	myTable = myTable .. "Categories for [[human migration]] between '''[[" .. countryName1 .. "]] and " .. countryPrefixThe(countryName2) .. " [[" .. countryName2.. "]]'''"
	myTable = myTable .. "</td>\n</tr>\n"

	myTable = myTable .. makeTableRow(rowLabel, countryName1, countryName2)
	myTable = myTable .. makeTableRow(rowLabel, countryName2, countryName1)

	-- make the footer row
	myTable = myTable .. "<tr style = /" .. basicRowStyle .. footerRowStyle .. "'>\n"
	myTable = myTable .. "<td colspan='2' style='" .. footerCellStyle .. "'>"
	local fooBarRelations = string.format("%s–%s relations", countryName1, countryName2)
	myTable = myTable .. "''See also'': " .. makeCatLink(fooBarRelations, fooBarRelations) .. '\n'
	myTable = myTable .. "</td>\n</tr>\n"
	
	myTable = myTable .. "</table>\n"
	return myTable
end


-- Make a piped link to a category, if it exists
-- If it doesn't exist, just display the greyed the link title without linking
function makeCatLink(catname, disp)
	local displaytext
	if (disp ~= "") and (disp ~= nil) then
		-- use 'disp' parameter, but strip any trailing disambiguator
		displaytext = mw.ustring.gsub(disp, "%s+%(.+$", "");
	else
		displaytext = catname
	end
	local fmtlink
	if (doesPageExist(catname, "Category")) then
		fmtlink = "[[:Category:" .. catname .. "|" .. displaytext .. "]]"
		blueLinkCount = blueLinkCount + 1
	else
		fmtlink = '<span style="color:' .. greyLinkColor .. '">' .. displaytext .. "</span>"
		greyLinkCount = greyLinkCount + 1
	end

	return fmtlink
end

function doesPageExist(s, myNamespace)
	local myTestPage = mw.title.new(s, myNamespace)
	if (myTestPage.exists) then
		return true
	else
		return false
	end
end


--  ##################### New stuff starts here ################

function getCountryFromAdjective(s)
	return countryAdjectivesToNounsTable[s]
end


function getAdjectiveFromCountry(s)
	return countryNounstoAdjectivesTable[s]
end

function stripThe(s)
	if s == nil then
		debugLog(2, string.format("cannot strip a nil value"))
		return nil
	end
	if mw.ustring.match( s, "^[T]he Gambia") ~= nil then
		return "the Gambia"
	end
	debugLog(2, string.format("stripping [%s]", s))
	local stripped = mw.ustring.gsub(s, "^[tT]he ", "")
	if stripped == nil then
		debugLog(nil, " &rarr; nil")
	else
		debugLog(nil, string.format(" &rarr; [%s]", stripped))
	end
	return stripped
end

-- semi-patterns
-- add explanation
local categoryMasks = {
	["Fooian people of Barian descent"] = {false, "(.+) people of (.+) descent"}, 
	["Fooian emigrants to Bar"] = {true, "(.+) emigrants to (.+)"},
	["Fooian expatriates in Bar"] = {true, "(.+) expatriates in (.+)"},
	["Fooian expatriate sportspeople in Bar"] = {true, "(.+) expatriate sportspeople in (.+)"},
	["Fooian diaspora in Bar"] = {true, "(.+) diaspora in (.+)$"}
}


-- parse the pagename to find two countyName/countryAdjective pairs
-- looks for one of 5 different types of category,
-- as defined in categoryMasks{}
-- Each of the 5 formats is tested in turn, until a format is found which
-- matches the current pagename
-- The return value is a string:
--    "//success//" = matched a pattern, and built two countyName/countryAdjective pairs
--    "//nomatch//" = did not match any pattern
--    "//unknown//:sometext" = one of the countrynames or adjectives found in the title
--                              was not found in the lookup table
--    "//error//"
function parsePagename(pn)
	local splitResult = nil
local nmasks = 0
	 debugLog(1, "parsePagename")
	 debugLog(2, " pn = [" .. pn .."]")
	 for catDescription, maskData in pairs(categoryMasks) do
		nmasks = nmasks + 1
		debugLog(3, string.format("Mask #%d: catDescription=[%s], isNoun=[%s] &nbsp; pattern=[%s]" , nmasks, catDescription, tostring(maskData[1]), maskData[2]))
		splitResult = splitPagename(pn, maskData[1], "^" .. maskData[2] .. "$")
		if splitResult == "//success//" then
			return splitResult
		elseif splitResult == "//nomatch//" then
			-- do nothing. We'l just loop again and try the next mask
		elseif mw.ustring.match(splitResult, "^//unknown//") then
			return splitResult
		else
			return "//error//unexpected result from splitPagename"
		end
	end
	debugLog(2, "nmasks = ", tonumber(nmasks))
	if splitResult == nil then splitResult = "splitResult=nil.  Why????" end
	return splitResult
end

function splitPagename(pname, isNoun, pattern)
	debugLog(4, string.format("splitPagename: pname=[%s], isNoun=[%s], pattern=[%s]" , pname, tostring(isNoun), pattern))

	if not mw.ustring.match(pname, pattern) then
		debugLog(5, "no match")
		return "//nomatch//"
	end
	local v1 = mw.ustring.gsub(pname, pattern, "%1") -- extract the "Fooian" athe start of the cat name
	local v2 = mw.ustring.gsub(pname, pattern, "%2") -- extract the "Foo" or "Fooian" athe start of the cat name
	debugLog(5, string.format("v1=[%s], v2=[%s]", v1, v2))
	countryName1 = getCountryFromAdjective(v1)
	if countryName1 == nil then
		return "//unknown//adjective: " .. v1
	end
	if isNoun then
		countryName2 = v2
		countryName2 = stripThe(countryName2)
		if getAdjectiveFromCountry(countryName2) == nil then
			return "//unknown//noun: " .. v2
		end
	else
		countryName2 = getCountryFromAdjective(v2)
		if countryName2 == nil then
			return "//unknown//adjective:" .. v2
		end
	end
	return "//success//"
end

-- ###################### END NEWSTUFF ###############################################
function publishDebugLog()
	if not debuggingEnabled then
		return ""
	end
	return "==Debugging ==\n\n" .. debugmsg .. "\n== Output ==\n"
end


-- debugLog builds a log which can be output if debuging is enabled
-- each log entry is given a level, so that the output is not simply a flat list
-- a debug msg may be appended to the previous msg by setting the level to nil
function debugLog(level, msg)

	if (debugmsg == nil) then
		debugmsg = ""
	end

	if (level ~= nil) then
		-- not appending, so make a new line
		debugmsg = debugmsg .. "\n"
		-- then add the level
		local i
		for i = 1, level do
			if (i % 2) == 1 then
				debugmsg = debugmsg .. "#"
			else
				debugmsg = debugmsg .. "*"
			end
		end 
	end
	debugmsg = debugmsg .. " " .. msg
	return true
end


function getYesNoParam(args, thisParamName, defaultVal)
	local paramVal = args[thisParamName]
	if paramVal == nil then
		paramVal = ""
	end

	debugLog(2, "Evaluate yes/no parameter: [" .. thisParamName .. "] = [" .. paramVal .. "]")
	debugLog(3, "default = " .. ((defaultVal and "Yes") or "No"))
	debugLog(3, "Evaluate as: ")
	local returnValue
	if paramVal == "" then
		returnValue = defaultVal
	else
		returnValue = yesno(args[thisParamName], defaultVal)
	end
	if (returnValue) then
		debugLog(nil, "Yes")
	else
		debugLog(nil, "No")
	end
	return returnValue
end

function makeErrorMsg(s)
	return '<p class="error">[[' .. parentname .. ']] Error: ' .. s .. '</p>\n'
end


function p.main(frame)
	local parent = frame:getParent()
	if parent then
		 parentname = parent:getTitle():gsub('/sandbox$', '')
	end
	templateName = mw.ustring.gsub(parentname, "^Template:", "")

	-- get the page title
	debugLog(1, "mw.title.getCurrentTitle()")
	thispage = mw.title.getCurrentTitle()
	thispagename = thispage.text;
	
	debugLog(2, "thispage.text = [" .. thispage.text .."]")
	debugLog(2, "thispage.namespace = [" .. thispage.namespace .."]")
	debugLog(2, "thispage.nsText = [" .. thispage.nsText .."]")
	debugLog(2, "is it a cat? using (thispage:inNamespace(14)): ")
	if not (thispage:inNamespace(14)) then
		debugLog(nil, "No, this is not a category")
		debugLog(1, "Not a category, so no output")
		return makeErrorMsg("only for use on a category page") .. publishDebugLog()
	end
	debugLog(nil, "Yes, this is a category")
	debugLog(2, "list categoryMasks")
	for x, y in ipairs(categoryMasks) do
		debugLog(3, "[" .. x .. "] = [" .. y .."]")
	end

	debugLog(1, "makeAdjectivesToNounsTable()")
	local nMade = makeAdjectivesToNounsTable()
	debugLog(2, string.format("makeAdjectivesToNounsTable() done: %d", nMade))
	debugLog(1, "next call parsePagename()")

	local parseResult = parsePagename(thispagename)
	debugLog(1, "Parsed");
	debugLog(2, string.format("parseResult=%s", parseResult))
	debugLog(2, "countries found:")
	debugLog(3, "countryName1=")
	if (countryName1 == nil) then
		debugLog(nil, "nil")
		parseResult = parseResult .. " but countryName1 is nil" 
	else
		debugLog(nil, string.format("[%s] .. and adjective = [%s]", countryName1, getAdjectiveFromCountry(countryName1)))
	end
	debugLog(3, "countryName2=")
	if countryName2 == nil then
		debugLog(nil, "nil")
		parseResult = parseResult .. " but countryName2 is nil"
	else
		debugLog(nil, string.format("[%s] .. and adjective = [%s]", countryName2, getAdjectiveFromCountry(countryName2)))
	end
	local myNavTable = "";
	local myPortalsBox = ""
	if (parseResult ~= "//success//") then
		debugLog(1, "Not a success, so no makeTable()")
	else
		debugLog(1, "Calling makeTable")
		myNavTable = makeTable()
		debugLog(1, "Table made")
		debugLog(2, string.format("Greylinks: %d", greyLinkCount))
		debugLog(1, "Making portals")
--		myPortalsBox = makePortalBox()
		myPortalsBox = frame:expandTemplate{ title = 'Portal', args = {countryName1, countryName2} }
		debugLog(2, "Portals done")
		myTrackingCategories = makeTrackingCategory()
	end
	
	return publishDebugLog() .. myPortalsBox  .. myNavTable .. myTrackingCategories
end

function makePortalBox()
	local myPortalsList = ""
--[[
	local myPortalsArray = {}
	if (doesPageExist(countryName1, "Portal")) then
		myPortalsList = myPortalsList .. "|" .. countryName1
		myPortalsArray[#myPortalsArray + 1] = countryName1
	end
	if (doesPageExist(countryName2, "Portal")) then
		myPortalsList = myPortalsList .. "|" .. countryName2
		myPortalsArray[#myPortalsArray + 1] = countryName2
	end
	local i, v
	for i, v in ipairs(defaultPortals) do
		if (doesPageExist(v, "Portal")) then
			myPortalsList = myPortalsList .. "|" .. v
			myPortalsArray[#myPortalsArray + 1] = countryName1
		end
	end
	debugLog(2, string.format("Portal made.<br>myPortalsList = [%s]", myPortalsList))
	-- showMyPortals(countryName1, countryName2)
	-- showMyPortals(myPortalsArray)
	
]]
	myPortalsList = frame:expandTemplate{ title = 'Portal', args = {countryName1, countryName2} }
	return myPortalsList
end

function makeAdjectivesToNounsTable()
	countriesPrefixedByThe = mw.loadData( 'Module:CountryNameDemonym/the' )
	countryNounstoAdjectivesTable = mw.loadData( 'Module:CountryNameDemonym/adjectives' )
	local myCounter = 0
	local myNoun, myAdj
	for myNoun, myAdj in pairs(countryNounstoAdjectivesTable) do
		countryAdjectivesToNounsTable[myAdj] = myNoun
		myCounter = myCounter + 1
	end
	return myCounter
end

return p