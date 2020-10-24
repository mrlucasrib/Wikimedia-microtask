--[[
	v01.18: fix handling of definite article (e.g. for 'the Northwest Territories') 

 each title consists of 3 parts
    * prefix
    * province name
    * suffix
 e.g. "Foo in Quebec"
    * prefix = "Foo in "
    * province name = "Quebec"
    * suffix = ""
 e.g. "Nunavut-related lists"
    * prefix = ""
    * province name = "Nunavut"
    * suffix = "-related lists"
]]

-- config
local textSize = '90%'
local tableClass="toc"
local evenRowStyle = "vertical-align:top; background-color:#f3f3f3;"
local oddRowStyle = "vertical-align:top;"
local labelStyle = "text-align:right; font-weight: bold; padding: 0.25em 0.5em 0.25em 0.5em;"
local listStyle = "text-align:left; font-weight: normal; padding: 0.25em 0.5em 0.25em 0.5em;"
local greyLinkColor = "#888"
--[[ Note that the table styles are designed to ensure that the navbox is as wide as possible, while still leaving
     enough enough space on the right for portal boxes, commons links, and GeoGroup templates.
     A lot of fiddling was needed to make it work, so please test any chnages very carfully in the sandbox.
]]
local tableFallbackMaxWidth="auto"
local tableMaxWidth="calc(100% - 25em)" -- Template:GeoGroup has width: 23em<
-- local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; float:left; width:auto;"
local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; width:auto;"

-- Templates which are allowed to call this module
local callingTemplates = {
	'Template:CanadaByProvinceCatNav',
}

-- globals for this module
local debugging = false
local debugmsg = ""
local tableRowNum = 0
local title_prefix = ""
local title_suffix = ""
local title_prefix
local title_suffix
local thisPageProvince
local greyLinkCount = 0
local blueLinkCount = 0
local parentname = ""
local templateName

local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local p = {}

--[[
	Plain text list of provinces and territories
	* Each entry exactly as it appears in running text in categoiry titles, with any prefix (e.g. "the")
	* Be sure to avoid hidden characters and duplicate spaces.  They break the pattern-matching on which this module relies
]]
local CanadaProvinces = {
	'Alberta',
	'British Columbia',
	'Manitoba',
	'New Brunswick',
	'Newfoundland and Labrador',
	'the Northwest Territories',
	'Nova Scotia',
	'Nunavut',
	'Ontario',
	'Prince Edward Island',
	'Quebec',
	'Saskatchewan',
	'Yukon'
}

-- If the page title matches any of these Lua patterns, treat it as a false positive 
local falsePositiveChecks = {
	"Northern Alberta",
	"Southern Alberta",
	"Quebec City",
	"Central Ontario",
	"Eastern Ontario",
	"Northern Ontario",
	"Southwestern Ontario"
}

function makeTrackingCategory()
	-- discount the current page, which will always be coded as a blue link, but rendered as bold un-navigable
	blueLinkCount = blueLinkCount - 1
	if greyLinkCount == 0 then
		return "[[Category:" .. templateName .. " with no grey links]]"
	end
	if blueLinkCount == 0 then
		return "[[Category:" .. templateName .. " with all grey links]]"
	end
	if  greyLinkCount <= 5 then
		return "[[Category:" .. templateName .. " with fewer than 5 grey links]]"
	end
	if  greyLinkCount >= 10 then
		return "[[Category:" .. templateName .. " with 10 or more grey links]]"
	end
	if  greyLinkCount > 5 then
		return "[[Category:" .. templateName .. " with over 5 grey links]]"
	end
	return ""
end

function makeTableRow(rowLabel, provinceList)
	debugLog(2, "makeTableRow, label: ")
	if (rowLabel == nil) then
		rowLabel = "By&nbsp;province<br />or territory"
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
	thisRow = thisRow .. '<td style="' .. listStyle .. ';"><div class="hlist">\n'
	local i, aProvince
		debugLog(3, "Process provinceList")
	for i, aProvince in ipairs(provinceList) do
		debugLog(4, "No. " .. tostring(i) .. ": [" .. aProvince .. "]")
		myCatName = makeCatName(aProvince, title_prefix, title_suffix)
		thisRow = thisRow .. "* " .. makeCatLink(myCatName, aProvince) .. "\n"
	end
	thisRow = thisRow .. '</div></td>\n</tr>'
	return thisRow
end


function makeTable()
	debugLog(1, "makeTable")
	tableRowNum = 0
	local myTable = '<table class="' .. tableClass .. '"'
	myTable = myTable .. ' style="' .. tableStyle .. '; font-size:' .. textSize .. '; max-width:' .. tableFallbackMaxWidth .. '; max-width:' .. tableMaxWidth ..'">\n'

	myTable = myTable .. makeTableRow(nil, CanadaProvinces)
	myTable = myTable .. "</table>\n"
	return myTable
end


-- Make a piped link to a category, if it exists
-- If it doesn't exist, just display the greyed the link title without linking
function makeCatLink(catname, disp)
	local displaytext
	if (disp ~= "") and (disp ~= nil) then
		-- use 'disp' parameter, but strip any leading word "the"
		displaytext = mw.ustring.gsub(disp, "^[tT]he%s+", "");
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


function makeCatName(provinceName, prefix, suffix)
	local thisCatName = prefix .. provinceName .. suffix
	debugLog(5, "thisCatName = [" .. thisCatName .. "]")
	--[[
		Now check whether the all following conditions are true
			1/ the provinceName begins with "the"
			2/ the category does NOT exist if we use "the "
			3/ the category does exist if we strip "the "
		 If those conditions are all true, them strip "the" 
	]] 
	if (mw.ustring.match(provinceName, "^[tT]he ") ~= nil) then
		debugLog(6, "ProvinceName begins with 'the'")
		local provinceNameStripped = mw.ustring.gsub(provinceName, "^[tT]he ", "", 1)
		local thisCatNameStripped = prefix .. provinceNameStripped .. suffix
		debugLog(6, "thisCatNameStripped = [" .. thisCatNameStripped .. "]")
		local testCatPage = mw.title.new(thisCatName, "Category" )
		local testCatPageStripped = mw.title.new(thisCatNameStripped, "Category" )
		if not testCatPage.exists then
			debugLog(7, "[" .. testCatPage.fullText .. "] .. does not exist") 
			if (testCatPageStripped.exists) then
				debugLog(7, "[" .. testCatPageStripped.fullText .. "] .. DOES exist, so use that") 
				return thisCatNameStripped
			end
		end
	end
	return thisCatName
end


function patternSearchEncode(s)
	return mw.ustring.gsub(s, "([%W])", "%%%1")
end

-- Does the pagename include a province name?
function findprovinceNameInPagename(pn, provinceList, description)
	local i, aProvince, testProvince
	debugLog(2, "checking [" .. pn .."] for a province name in province set: " .. description)
	for i, aProvince in ipairs(provinceList) do
		testProvince = aProvince
		debugLog(3, "testing: ["  .. testProvince .. "]")
		local testProvinceEncoded = patternSearchEncode(testProvince)
		-- For efficiency, the first test is a simple match as a a screening test
		-- If the bare county name is nowhere in the pagename, then no need for
		-- more precise checks
		-- This check would be one line in regex, but Lua pattern matching is cruder,
		--so we need several passes to ensure that any match is of a complete word
		debugLog(4, "simple match? ")
		if (not mw.ustring.match(pn, testProvinceEncoded)) then
			debugLog(nil, "Fail")
		else
			debugLog(nil, "Success")

			-- test for false positives
			local j, aFalsePositiveTest
			for j, aFalsePositiveTest in ipairs(falsePositiveChecks) do
				debugLog(5, "false positive test pattern '" .. aFalsePositiveTest .. "' ? ")
				if (mw.ustring.match(pn, aFalsePositiveTest)) then
					debugLog(nil, "Match, so fail")
					return nil
				end
				debugLog(nil, "No match, so OK")
			end

			debugLog(4, "match whole name? ")
			if (pn == testProvince) then
				debugLog(nil, "Yes")
				return testProvince
			end
			debugLog(nil, "No")

			debugLog(4, "match at start, followed by separator? ")
			if mw.ustring.match(pn, "^" .. testProvinceEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return testProvince
			end
			debugLog(nil, "No")
			
			debugLog(4, "match at end, preceded by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testProvinceEncoded .. "$") then
				debugLog(nil, "Yes")
				return testProvince
			end
			debugLog(nil, "No")

			debugLog(4, "match anywhere, preceded and followed by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. testProvinceEncoded .. "[^%w]") then
				debugLog(nil, "Yes")
				return testProvince
			end
			debugLog(nil, "No")

		end
		-- Special case: if the province name we are testing begins with a prefixed "the"
		debugLog(4, "does testProvince begin with 'the' ? ")
		if (mw.ustring.match(testProvince, "^[tT]he ") == nil) then
			debugLog(nil, "No")
		else
			debugLog(nil, "Yes")
		end
		if (mw.ustring.match(testProvince, "^[tT]he ") ~= nil) then
			local testProvinceStripped = mw.ustring.gsub(testProvince, "^[tT]he ", "", 1)
			local testProvinceStrippedEncoded = patternSearchEncode(testProvinceStripped)
			debugLog(4, "test pattern without leading definite article, i.e. '" .. testProvinceStrippedEncoded .. "' ? ")
			if (mw.ustring.match(pn, "[^%w]" .. testProvinceStrippedEncoded .. "[^%w]")  ~= nil)
			or (mw.ustring.match(pn, "^" .. testProvinceStrippedEncoded .. "[^%w]")  ~= nil)
			or (mw.ustring.match(pn, "[^%w]" .. testProvinceStrippedEncoded .. "$")  ~= nil)
			or (mw.ustring.match(pn, "^" .. testProvinceStrippedEncoded .. "$")  ~= nil) then
				debugLog(nil, "Yes")
				return testProvinceStripped
			end
			debugLog(nil, "No")
		end
	end
	return nil
end

-- parse the pagename to find 3 parts: prefix, province name, suffix
function parsePagename(pn)
	debugLog(1, "parsePagename: [" .. pn .. "]")
	local validprovinceName
	validprovinceName = findprovinceNameInPagename(pn, CanadaProvinces, "provincelst")
	if validprovinceName == nil then
		return false
	end
	
	-- if we get here, the page name "pn" includes a validprovinceName
	-- so now we need to split the string
	
	debugLog(2, "split pagename around [" .. validprovinceName .. "]")
	local validProvinceEncoded = mw.ustring.gsub(validprovinceName, "([%W])", "%%%1")
	match_prefix, match_province, match_suffix = mw.ustring.match(pn, "^(.*)(" .. validProvinceEncoded .. ")(.*)$")
	
	title_prefix = match_prefix
	title_suffix = match_suffix
	debugLog(2, "parse successful")
	debugLog(3, "title_prefix = [" .. title_prefix .. "]")
	debugLog(3, "thisPageProvince = [" .. match_province .. "]")
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
		return makeErrorMsg('the name of this category does not include a valid Candian province or territory') .. publishDebugLog() .. trackingCatInvalid
	end
	
	debugLog(1, "all parse done")
	debugLog(2, "title_prefix = [" .. title_prefix .. "]")
	debugLog(2, "title_suffix = [" .. title_suffix .. "]")
	
	local myNavTable = makeTable()
	debugLog(2, "blueLinkCount = [" .. blueLinkCount .. "]. &nbsp; (NB The current page is always counted as a bluelink, but will not be navigable)")
	debugLog(2, "greyLinkCount = [" .. greyLinkCount .. "]")
	
	if (blueLinkCount <= 1) then
		-- This is a navbar to nowhere, so suppress display
		myNavTable = ""
		debugLog(1, "Zero bluelinks (other than the current page) makes this a navbox to nowhere, so do not display the navbox")
	end
	
	local myTrackingCat = makeTrackingCategory()

	return publishDebugLog() .. myNavTable .. myTrackingCat

end

return p