--[[ v02

 each title consists of 3 parts
    * prefix
    * county name
    * suffix
 e.g. "Foo in County Mayo"
    * prefix = "Foo in "
    * county name = "County Mayo"
    * suffix = ""
 e.g. "County Sligo-related lists"
    * prefix = ""
    * county name = "County Sligo"
    * suffix = "-related lists"
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
	'Template:AllIrelandByCountyCatNav',
	'Template:RepublicOfIrelandOnlyByCountyCatNav',
	'Template:NorthernIrelandOnlyByCountyCatNav',
	'Template:PrePartitionIrelandByCountyCatNav'
}

-- globals for this module
local debugging = false
local debugmsg = ""
local tableRowNum = 0
local includeNewCounties = true
local useCountyWord = true
local title_prefix = ""
local title_suffix = ""
local countySet = nil
local title_prefix
local title_suffix
local thisPageCounty
local isNorniron = false
local greyLinkCount = 0
local blueLinkCount = 0
local parentname = ""
local templateName

local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local p = {}

local TwentySixCounties = {
	'Carlow',
	'Cavan',
	'Clare',
	'Cork',
	'Donegal',
	'Dublin',
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
	'Waterford',
	'Westmeath',
	'Wexford',
	'Wicklow'
}

local SixCounties = {
	'Antrim',
	'Armagh',
	'Down',
	'Fermanagh',
	'Londonderry',
	'Tyrone'
}

local newCounties = {
	'Dún Laoghaire–Rathdown',
	'Fingal',
	'South Dublin (county)',
	'Dublin (city)'
}

local Traditional32Counties = {
	'County Antrim',
	'County Armagh',
	'County Carlow',
	'County Cavan',
	'County Clare',
	'County Cork',
	'County Donegal',
	'County Down',
	'County Dublin',
	'County Fermanagh',
	'County Galway',
	'County Kerry',
	'County Kildare',
	'County Kilkenny',
	'County Leitrim',
	'County Limerick',
	'County Londonderry',
	'County Longford',
	'County Louth',
	'County Mayo',
	'County Meath',
	'County Monaghan',
	'County Roscommon',
	'County Sligo',
	'County Tipperary',
	'County Tyrone',
	'County Waterford',
	'County Westmeath',
	'County Wexford',
	'County Wicklow',
	"King's County",
	"Queen's County"
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
		thisRow = thisRow .. '<td style="' .. labelStyle .. '">' .. rowLabel .. '</td>\n'
	end
	-- now begin making the row contents
	local countyWord = ""
	if useCountyWord then
		debugLog(3, "Using countyWord")
		countyWord = "County "
	else
		debugLog(3, "Not using countyWord")
	end
	thisRow = thisRow .. '<td style="' .. listStyle .. ';"><div class="hlist">\n'
	local i, aCounty
		debugLog(3, "Process countyList")
	for i, aCounty in ipairs(countyList) do
		debugLog(4, "No. [" .. tostring(i) .. ": [" .. aCounty .. "]")
		myCatName = makeCatName(countyWord .. aCounty, title_prefix, title_suffix)
		thisRow = thisRow .. "* " .. makeCatLink(myCatName, aCounty) .. "\n"
		local j, nuCounty
		if (includeNewCounties and (aCounty == "Dublin")) then
			-- make a sub-list for the newCounties
			local subCatName
			for j, nuCounty in ipairs(newCounties) do
				subCatName = makeCatName(nuCounty, title_prefix, title_suffix)
				displayname = nuCounty
				if displayname == "Dublin (city)" then
					displayname = "City"
				end
				thisRow = thisRow .. "** " .. makeCatLink(subCatName, displayname) .. "\n"
			end
		end
	end
	thisRow = thisRow .. '</div></td>\n</tr>'
	return thisRow
end


function makeTable()
	debugLog(1, "makeTable")
	tableRowNum = 0
	local myTable = '<table class="' .. tableClass .. '"'
	myTable = myTable .. ' style="' .. tableStyle .. '; font-size:' .. textSize .. '; max-width:' .. tableFallbackMaxWidth .. '; max-width:' .. tableMaxWidth ..'">\n'

	if (countySet == "thirtytwo") then
		useCountyWord = false
		myTable = myTable .. makeTableRow(nil, useCountyWord, Traditional32Counties)
	elseif (countySet == "twentysix") then
		myTable = myTable .. makeTableRow(nil, useCountyWord, TwentySixCounties)
	elseif (countySet == "six") then
		myTable = myTable .. makeTableRow(nil, useCountyWord, SixCounties)
	else -- default to 26 plus 6
		if isNorniron then
			myTable = myTable .. makeTableRow("Northern&nbsp;Ireland", useCountyWord, SixCounties)
			myTable = myTable .. makeTableRow("Republic of Ireland", useCountyWord, TwentySixCounties)
		else
			myTable = myTable .. makeTableRow("Republic of Ireland", useCountyWord, TwentySixCounties)
			myTable = myTable .. makeTableRow("Northern&nbsp;Ireland", useCountyWord, SixCounties)
		end
	end
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
-- with or without the prefix "County", depending on value of useCountyWord
function findCountyNameInPagename(pn, countylist, description, prefixCountyWord)
	local i, aCounty, testCounty
	debugLog(2, "checking [" .. pn .."] for a county name in county set: " .. description)
	for i, aCounty in ipairs(countylist) do
		if prefixCountyWord then
			testCounty = "County " .. aCounty
		else
			testCounty = aCounty
		end
		debugLog(3, "testing: ["  .. testCounty .. "]")
		local testCountyEncoded = patternSearchEncode(testCounty)
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

			debugLog(4, "match whole name? ")
			if (pn == testCounty) then
				debugLog(nil, "Yes")
				return testCounty
			end
			debugLog(nil, "No")

			debugLog(4, "match at start, followed by separator? ")
			if mw.ustring.match(pn, "^" .. testCountyEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return testCounty
			end
			debugLog(nil, "No")
			
			debugLog(4, "match at end, preceded by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testCountyEncoded .. "$") then
				debugLog(nil, "Yes")
				return testCounty
			end
			debugLog(nil, "No")

			debugLog(4, "match anywhere, preceded and followed by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testCountyEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return testCounty
			end
			debugLog(nil, "No")
		end
	end
	return nil
end

-- check whether a given county name is in a particular set
function isCountyInSet(s, aSet, description)
	local thisCounty = mw.ustring.gsub(s, "^County +", "")
	debugLog(4, "Checking [" .. thisCounty .. "] in set: " .. description)
	local aValidCounty
	for i, aValidCounty in ipairs(aSet) do
		debugLog(4, "Compare with [" .. aValidCounty .. "]: ")
		if mw.ustring.match(thisCounty, "^" .. aValidCounty .. "$") then
			debugLog(nil, " match")
			return true
		end
		debugLog(nil, " not matched")
	end
	return false
end


-- parse the pagename to find 3 parts: prefix, county name, suffix
function parsePagename(pn)
	debugLog(1, "parsePagename: [" .. pn .. "]")
	isNorniron = false
	local validCountyName
	if (countySet == "twentysix") then
		validCountyName = findCountyNameInPagename(pn, TwentySixCounties, "twentysix", useCountyWord)
		if (validCountyName == nil and includeNewCounties) then 
			validCountyName = findCountyNameInPagename(pn, newCounties, "new counties", false)
		end
	elseif (countySet == "thirtytwo")  then
		useCountyWord = false
		validCountyName = findCountyNameInPagename(pn, Traditional32Counties, "thirtytwo", useCountyWord)
		if (validCountyName == nil and includeNewCounties) then 
			validCountyName = findCountyNameInPagename(pn, newCounties, "new counties", false)
		end
	elseif (countySet == "six") then
		validCountyName = findCountyNameInPagename(pn, SixCounties, "six", useCountyWord, false)
		if validCountyName ~= nil then
			isNorniron = true
		end
	elseif (countySet == "gaa") then
		validCountyName = findCountyNameInPagename(pn, GAACounties, "gaa", useCountyWord, false)
	else -- default: treat as (countySet == "twentysixplussix")
		validCountyName = findCountyNameInPagename(pn, TwentySixCounties, "twentysix", useCountyWord)
		if validCountyName == nil then
			validCountyName = findCountyNameInPagename(pn, SixCounties, "six", useCountyWord)
			if validCountyName ~= nil then
				isNorniron = true
			end
		end
		if (validCountyName == nil and includeNewCounties) then 
			validCountyName = findCountyNameInPagename(pn, newCounties, "new counties", false)
		end

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
	thisPageCounty = mw.ustring.gsub(match_county, "^County%s+", "")
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
	useCountyWord = getYesNoParam(frame.args, "usecountyword", true)
	includeNewCounties = getYesNoParam(frame.args, "newcounties", true)

	countySetParam = "twentysixplussix" -- default
	debugLog(2, "countySet")
	if ((frame.args['countyset'] == nil) or (frame.args['countyset'] == "")) then
		debugLog(3, "not set")
		countySet = nil
	else
		debugLog(3, "countyset=[" .. frame.args['countyset'] .. "]")
		local countySetParam = mw.text.trim(mw.ustring.lower(frame.args['countyset']))
		debugLog(4, "Evaluate as: ")
		if (countySetParam == "twentysix") or
			(countySetParam == "six") or
			(countySetParam == "thirtytwo") or
			(countySetParam == "twentysixplussix")
		then
			countySet = countySetParam
			debugLog(nil, "[" .. countySetParam .. "]")
			if (countySetParam == "gaa") then
				useCountyWord = false
				includeNewCounties = false
				debugLog(5, "Yes/no parameter [newcounties] reset to [no]")
				debugLog(5, "Yes/no parameter [usecountyword] reset to [no]")
			end
		else
			countySet = nil
			debugLog(nil, "not a valid set")
		end
	end

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
		return makeErrorMsg("only for use on a category page") .. publishDebugLog()
	end
	debugLog(nil, "Yes, this is a category")

	if not parsePagename(thispagename) then
		-- some error parsing the title, so don't proceed to output
		local trackingCatInvalid = "[[Category:" .. templateName .. " on invalid category]]"
		return makeErrorMsg('the name of this category does not include a valid Irish county') .. publishDebugLog() .. trackingCatInvalid
	end
	
	debugLog(1, "all parse done")
	debugLog(2, "title_prefix = [" .. title_prefix .. "]")
	debugLog(2, "title_suffix = [" .. title_suffix .. "]")

	return publishDebugLog() .. makeTable() .. trackingCategory()

end

return p