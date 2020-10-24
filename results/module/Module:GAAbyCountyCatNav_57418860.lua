--[[ GAA v0, forked from v20

 each title consists of 3 parts
    * prefix
    * county name
    * suffix
 e.g. "Foo in Mayo"
    * prefix = "Foo in "
    * county name = Mayo"
    * suffix = ""
]]

-- config
local textSize = '90%'
local tableClass="toc"
local tableFallbackMaxWidth="auto"
local tableMaxWidth="calc(100% - 25em)" -- Template:GeoGroup has width: 23em<
-- local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; float:left; width:auto;"
local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; width:auto;"
local evenRowStyle = "vertical-align:top; background-color:#f3f3f3;"
local oddRowStyle = "vertical-align:top;"
local labelStyle = "text-align:right; font-weight: bold; padding: 0.25em 0.5em 0.25em 0.5em;"
local listStyle = "text-align:left; font-weight: normal; padding: 0.25em 0.5em 0.25em 0.5em;"
local greyLinkColor = "#888"

local callingTemplates = {
	'Template:GAAbyCountyCatNav'
}

-- globals for this module
local debugging = false
local debugmsg = ""
local tableRowNum = 0
local title_prefix = ""
local title_suffix = ""
local thisPageCounty
local greyLinkCount = 0
local blueLinkCount = 0
local parentname = ""
local templateName


local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local p = {}


local IrishGAACounties = {
	'Antrim',
	'Armagh',
	'Carlow',
	'Cavan',
	'Clare',
	'Cork',
	'Donegal',
	'Derry',
	'Down',
	'Dublin',
	'Fermanagh',
	'Galway',
	'Kerry',
	'Kildare',
	'Kilkenny',
	'Laois',
	'Leitrim',
	'Limerick',
	'Longford',
	'Louth',
	'Mayo',
	'Meath',
	'Monaghan',
	'Offaly',
	'Roscommon',
	'Sligo',
	'Tipperary',
	'Tyrone',
	'Waterford',
	'Westmeath',
	'Wexford',
	'Wicklow'
}

local OverseasGAACounties = {
	'London',
	'New York'
}

function trackingCategory()
	-- discount this page, which will always be coded as a blue link, but rendered as bold un-navigable
	blueLinkCount = blueLinkCount - 1
	if greyLinkCount == 0 then
		return "[[Category:" .. templateName .. " with no grey links]]"
	end
	if blueLinkCount == 0 then
		return "[[Category:" .. templateName .. " with all grey links]]"
	end
	if greyLinkCount > 25 then
		return "[[Category:" .. templateName .. " with over 25 grey links]]"
	elseif greyLinkCount > 15 then
		return "[[Category:" .. templateName .. " with over 15 grey links]]"
	elseif greyLinkCount > 5 then
		return "[[Category:" .. templateName .. " with over 5 grey links]]"
	end
	return ""
end


function makeTableRow(rowLabel, useCountyWord, countyList)
	debugLog(2, "makeTableRow, label: ")
	if (rowLabel == nil) then
		rowLabel = "By&nbsp;county"
		debugLog(nil, rowLabel)
	else
		rowLabel = mw.text.trim(rowLabel)
		debugLog(nil, " [" .. rowLabel .. "]")
	end
	tableRowNum = tableRowNum + 1
	local thisRow
	if (tableRowNum % 2) == 0 then
		debugLog(3, "Even-numbered")
		thisRow = '<tr style="' .. evenRowStyle .. '">\n'
	else
		debugLog(3, "Odd-numbered")
		thisRow = '<tr style="' .. oddRowStyle .. '">\n'
	end
	if not ((rowLabel == nil) or (rowLabel =="")) then
		thisRow = thisRow .. '<td style="' .. labelStyle .. '">' .. rowLabel .. ': </td>\n'
	end
	-- now begin making the row contents
	thisRow = thisRow .. '<td style="' .. listStyle .. ';"><div class="hlist">\n'
	local i, aCounty
		debugLog(3, "Process countyList")
	for i, aCounty in ipairs(countyList) do
		debugLog(4, "No. [" .. tostring(i) .. ": [" .. aCounty .. "]")
		myCatName = makeCatName(aCounty, title_prefix, title_suffix)
		thisRow = thisRow .. "* " .. makeCatLink(myCatName, aCounty) .. "\n"
	end
	thisRow = thisRow .. '</div></td>\n</tr>'
	return thisRow
end


function makeTable()
	debugLog(1, "makeTable")
	tableRowNum = 0
	local myTable = '<table class="' .. tableClass .. '"'
	myTable = myTable .. ' style="' .. tableStyle .. '; font-size:' .. textSize .. '; max-width:' .. tableFallbackMaxWidth .. '; max-width:' .. tableMaxWidth ..'">\n'
	myTable = myTable .. makeTableRow("Irish&nbsp;GAA&nbsp;Counties", useCountyWord, IrishGAACounties)
	myTable = myTable .. makeTableRow("Overseas&nbsp;GAA&nbsp;Counties", useCountyWord, OverseasGAACounties)
	myTable = myTable .. "</table>\n"
	return myTable
end



-- Make a piped link to a category, if it exists
-- If it doesn't exist, just display the greyed the link title without linking
function makeCatLink(catname, disp)
	local displaytext
	if (disp ~= "") and (disp ~= nil) then
		-- use 'disp' parameter, but strip any trailing disambiguator
		displaytext = mw.ustring.gsub(disp, "%s+%(.+$", "")
	else
		displaytext = catname
	end
	local fmtlink
	local catPage = mw.title.new( catname, "Category" )
	if (catPage.exists) then
		fmtlink = "[[:Category:" .. catname .. "|" .. displaytext .. "]]"
		blueLinkCount = blueLinkCount + 1
	else
		fmtlink = '<span style="color:' .. greyLinkColor .. '">' .. displaytext .. "</span>"
		greyLinkCount = greyLinkCount + 1
	end

	return fmtlink
end


function makeCatName(countyName, prefix, suffix)
	local this_cat_name = '';
	this_cat_name = this_cat_name .. prefix
	this_cat_name = this_cat_name .. countyName
	this_cat_name = this_cat_name .. suffix
	return this_cat_name
end


function patternSearchEncode(s)
	return mw.ustring.gsub(s, "([%W])", "%%%1")
end

-- Does the pagename include a county name?
function findCountyNameInPagename(pn, countylist, description)
	local i, aCounty
	debugLog(2, "checking [" .. pn .."] for a county name in county set: " .. description)
	for i, aCounty in ipairs(countylist) do
		debugLog(3, "testing: ["  .. aCounty .. "]")
		local testCountyEncoded = patternSearchEncode(aCounty)
		-- For efficiency, the first test is a simple match as a a screening test
		-- If the bare county name is nowhere in the pagename, then no need for
		-- more precise checks
		-- This check would be one line in regex, but Lua pattern matching is cruder,
		--so we need several passes to ensure that any match is of a complete word
		debugLog(4, "simple match? ")
		if (not mw.ustring.match(pn, testCountyEncoded)) then
			debugLog(nil, "Fail")
		else
			debugLog(nil, "Success")

			debugLog(4, "match at start, followed by separator? ")
			if mw.ustring.match(pn, "^" .. testCountyEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return aCounty
			end
			debugLog(nil, "No")
			
			debugLog(4, "match at end, preceded by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testCountyEncoded .. "$") then
				debugLog(nil, "Yes")
				return aCounty
			end
			debugLog(nil, "No")

			debugLog(4, "match anywhere, preceded and followed by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testCountyEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return aCounty
			end
			debugLog(nil, "No")
		end
	end
	return nil
end


-- parse the pagename to find 3 parts: prefix, county name, suffix
function parsePagename(pn)
	debugLog(1, "parsePagename: [" .. pn .. "]")
	if mw.ustring.match(pn, "^County%s+") ~= nil then
		debugLog(2, 'Invalid. [' .. pn .. '] includes word "County"')
		return false
	end

	local validCountyName
	validCountyName = findCountyNameInPagename(pn, IrishGAACounties, "Irish GAA Counties")
	if (validCountyName == nil) then
		validCountyName = findCountyNameInPagename(pn, OverseasGAACounties, "Overseas GAA Counties")
	end
	if validCountyName == nil then
		return false
	end
	
	-- if we get here, the page name "pn" includes a validCountyName
	-- so now we need to split the string
	
	debugLog(2, "split pagename around [" .. validCountyName .. "]")
	local validCountyEncoded = mw.ustring.gsub(validCountyName, "([%W])", "%%%1")
	match_prefix, match_county, match_suffix = mw.ustring.match(pn, "^(.*)(" .. validCountyEncoded .. ")(.*)$")
	
	title_prefix = match_prefix
	title_suffix = match_suffix
	thisPageCounty = match_county
	debugLog(2, "parse successful")
	debugLog(3, "title_prefix = [" .. title_prefix .. "]")
	debugLog(3, "thisPageCounty = [" .. thisPageCounty .. "]")
	debugLog(3, "title_suffix = [" .. title_suffix .. "]")
	return true
end


function publishDebugLog()
	if not debugging then
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
	local returnValue
	debugLog(2, "Evaluate yes/no parameter: [" .. thisParamName .. "] = [" .. (((args[thisParamName] == nil) and "") or args[thisParamName]) .. "]")
	debugLog(3, "default = " .. ((defaultVal and "Yes") or "No"))
	debugLog(3, "Evaluate as: ")
	returnValue = yesno(args[thisParamName], defaultVal)
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

function isValidParent(p)
	local i, aParent
	for i, aParent in ipairs(callingTemplates) do
		if p == aParent then
			return true
		end
	end
	return false
end


function p.main(frame)
	local parent = frame:getParent()
	if parent then
		 parentname = parent:getTitle():gsub('/sandbox$', '')
	end

	if (parentname == nil) or not isValidParent(parentname) then
		local errormsg = '<p class="error"> Error: ' .. parentname .. ' is not a valid wrapper for [[' .. frame:getTitle() .. ']]\n'
		errormsg = errormsg .. '<br><br>Valid wrappers: '
		local i, aParent
		for i, aParent in ipairs(callingTemplates) do
			errormsg = errormsg .. '[[' .. aParent  .. ']]'
		end
		errormsg = errormsg .. '</p>'
		return errormsg
	end
	templateName = mw.ustring.gsub(parentname, "^Template:", "")

	debugLog(1, "Check parameters")
	debugging = getYesNoParam(frame.args, "debug", false)

	-- get the page title
	thispage = mw.title.getCurrentTitle()
	thispagename = thispage.text;
	
	debugLog(1, "mw.title.getCurrentTitle()")
	debugLog(2, "thispage.text = [" .. thispage.text .."]")
	debugLog(2, "thispage.namespace = [" .. thispage.namespace .."]")
	debugLog(2, "thispage.nsText = [" .. thispage.nsText .."]")
	debugLog(2, "is it a cat? using (thispage:inNamespace(14)): ")
	if not (thispage:inNamespace(14)) then
		debugLog(nil, "No, this is not a category")
		debugLog(1, "Not a category, so no output")
		return publishDebugLog()
	end
	debugLog(nil, "Yes, this is a category")

	if not parsePagename(thispagename) then
		-- some error parsing the title, so don't proceed to output
		return publishDebugLog()
	end
	
	debugLog(1, "all parse done")
	debugLog(2, "title_prefix = [" .. title_prefix .. "]")
	debugLog(2, "title_suffix = [" .. title_suffix .. "]")

	return publishDebugLog() .. makeTable() .. trackingCategory()

end

return p