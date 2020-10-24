--[[ v00.1

 each title consists of 3 parts
    * prefix
    * province name
    * suffix
 e.g. "Foo in Ulster"
    * prefix = "Foo in "
    * province name = "Ulster"
    * suffix = ""
 e.g. "Connacht-related lists"
    * prefix = ""
    * province name = "Connacht"
    * suffix = "-related lists"
]]

-- config
local textSize = '90%'
local tableClass="toc"
local tableFallbackMaxWidth="auto"
local tableMaxWidth="calc(100% - 25em)" -- Template:GeoGroup has width: 23em<
-- local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; float:left; width:auto;"
local tableStyle="margin-left:0; margin-right:auto; clear:left !important; margin-top:0 !important; width:auto;"
local tableRowStyle = "vertical-align:top; background-color:#f3f3f3;"
-- local labelStyle = "text-align:right; font-weight: bold; padding: 0.25em 0.5em 0.25em 0.5em;"
local labelStyle = "text-align:right; font-weight: normal; font-style: italic; padding: 0.25em 0.5em 0.25em 0.5em;"
local listStyle = "text-align:left; font-weight: normal; padding: 0.25em 0.5em 0.25em 0.5em;"
local greyLinkColor = "#888"

local callingTemplates = {
	'Template:IrelandByProvinceCatNav'
}

-- globals for this module
local debugging = false
local debugmsg = ""
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

local IrelandProvinces = {
	'Connacht',
	'Leinster',
	'Munster',
	'Ulster'
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
	if greyLinkCount == 1 then
		return "[[Category:" .. templateName .. " with 1 grey link]]"
	elseif greyLinkCount == 2 then
		return "[[Category:" .. templateName .. " with 2 grey links]]"
	end
	return ""
end

function makeTableRow(rowLabel, provinceList)
	debugLog(2, "makeTableRow, label: ")
	if (rowLabel == nil) then
		rowLabel = "By&nbsp;province"
		debugLog(nil, rowLabel)
	else
		rowLabel = mw.text.trim(rowLabel)
		debugLog(nil, " [" .. rowLabel .. "]")
	end
	local thisRow
	thisRow = '<tr style="' .. tableRowStyle .. '">\n'
	if not ((rowLabel == nil) or (rowLabel =="")) then
		thisRow = thisRow .. '<td style="' .. labelStyle .. '">' .. rowLabel .. '</td>\n'
	end
	-- now begin making the row contents
	thisRow = thisRow .. '<td style="' .. listStyle .. ';"><div class="hlist">\n'
	local i, aProvince
		debugLog(3, "Process provinceList")
	for i, aProvince in ipairs(provinceList) do
		debugLog(4, "No. [" .. tostring(i) .. ": [" .. aProvince .. "]")
		myCatName = makeCatName(aProvince, title_prefix, title_suffix)
		thisRow = thisRow .. "* " .. makeCatLink(myCatName, aProvince) .. "\n"
	end
	thisRow = thisRow .. '</div></td>\n</tr>'
	return thisRow
end


function makeTable()
	debugLog(1, "makeTable")
	local myTable = '<table class="' .. tableClass .. '"'
	myTable = myTable .. ' style="' .. tableStyle .. '; font-size:' .. textSize .. '; max-width:' .. tableFallbackMaxWidth .. '; max-width:' .. tableMaxWidth ..'">\n'

	myTable = myTable .. makeTableRow(nil, IrelandProvinces)
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


function makeCatName(provinceName, prefix, suffix)
	local this_cat_name = '';
	this_cat_name = this_cat_name .. prefix
	this_cat_name = this_cat_name .. provinceName
	this_cat_name = this_cat_name .. suffix
	return this_cat_name
end


function patternSearchEncode(s)
	return mw.ustring.gsub(s, "([%W])", "%%%1")
end

-- Does the pagename include a province name?
function findProvinceNameInPagename(pn)
	local i, aProvince
	debugLog(2, "checking [" .. pn .."] for a province name")
	for i, aProvince in ipairs(IrelandProvinces) do
		debugLog(3, "testing: ["  .. aProvince .. "]")
		if (string.find(pn, aProvince, 1, true) == nil) then
			debugLog(nil, "Fail")
		else
			debugLog(nil, "Success")

			debugLog(4, "match whole name? ")
			if (pn == aProvince) then
				debugLog(nil, "Yes")
				return aProvince
			end
			debugLog(nil, "No")

			debugLog(4, "match at start, followed by separator? ")
			if mw.ustring.match(pn, "^" .. aProvince .. "[^%w]") then
				debugLog(nil, "Yes")
				return aProvince
			end
			debugLog(nil, "No")
			
			debugLog(4, "match at end, preceded by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. aProvince .. "$") then
				debugLog(nil, "Yes")
				return aProvince
			end
			debugLog(nil, "No")

			debugLog(4, "match anywhere, preceded and followed by separator? ")
			if mw.ustring.match(pn, "[^%w]" .. aProvince .. "[^%w]") then
				debugLog(nil, "Yes")
				return aProvince
			end
			debugLog(nil, "No")
		end
	end
	return nil
end


-- parse the pagename to find 3 parts: prefix, province name, suffix
function parsePagename(pn)
	debugLog(1, "parsePagename: [" .. pn .. "]")
	local validProvinceName
	validProvinceName = findProvinceNameInPagename(pn)

	if validProvinceName == nil then
		return false
	end
	
	-- if we get here, the page name "pn" includes a validProvinceName
	-- so now we need to split the string
	
	debugLog(2, "split pagename around [" .. validProvinceName .. "]")
	match_prefix, match_province, match_suffix = mw.ustring.match(pn, "^(.*)(" .. validProvinceName .. ")(.*)$")
	
	title_prefix = match_prefix
	title_suffix = match_suffix
	thisPageProvince = match_province
	debugLog(2, "parse successful")
	debugLog(3, "title_prefix = [" .. title_prefix .. "]")
	debugLog(3, "thisPageProvince = [" .. thisPageProvince .. "]")
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
		return makeErrorMsg('the name of this category does not include a valid Irish province') .. publishDebugLog() .. trackingCatInvalid
	end
	
	debugLog(1, "all parse done")
	debugLog(2, "title_prefix = [" .. title_prefix .. "]")
	debugLog(2, "title_suffix = [" .. title_suffix .. "]")

	return publishDebugLog() .. makeTable() .. trackingCategory()

end

return p