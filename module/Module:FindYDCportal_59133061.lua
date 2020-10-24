--[[
   For a given 3- or 4-digit year or decade, find the most specific portal
   which actually exists.
   Takes one parameter, which must be either a year (e.g. "1879", "1123")
   or a decade (e.g. "1940s", "790s").
   If a portal is found, return its name without the namespace prefix
   (e.g. for "Portal:1980s" return "1980s"); otherwise return an empty string.
   If the parameter is missing, empty, or does not fit the required format,
   an empty string is returned"
]]

local p = {}

-- This table of existing decade portals is the first check of whether a portal
-- exists for a given decade.
-- If the decade is listed in this table, then a system call is made to verify its existence
-- This approach has two advantages:
-- 1/ It reduces server load by reducing the number of expensive system calls
-- 2/ It avoids creating backlinks to non-existing portals, because a each .exists check
--    generates a backlink
local existingDecadePortals = {
	["1920s"] = true,
	["1950s"] = true,
	["1960s"] = true,
	["1980s"] = true,
	["1990s"] = true
}

-- check for the existence of a portal with the given name
-- if it exists, returns the name
-- otherwise returns nil
function doesPortalExist(portalName)
	local portalPage = mw.title.new( portalName, "Portal" )
	if (portalPage.exists) then
		return portalName
	end
	return nil
end


-- check for the existence of a portal with the name of that year
-- if it exists, returns the year
-- otherwise calls decadeCheck, and returns that result
-- otherwise returns nil
function checkYear(yearParam)
--[[
the year portals have all been deleted, so comment out this section
	if doesPortalExist(yearParam) then
		return yearParam
	end
]]--
-- myDecade = the year, with the last digit stripped
	--            e.g. "1694" → "1690"
	--            Note that a decade is written as usul=ally written "YYY0s"
	local myDecade = mw.ustring.gsub(yearParam, "%d$", "")
	return checkDecade(myDecade)
end

-- check for the existence of a portal with the name of that decade
-- if it exists, returns the year
-- otherwise calls decadeCheck, and returns that result
-- otherwise returns nil
function checkDecade(decadeParam)
	local mydecade = decadeParam .. "0s"
	if (existingDecadePortals[mydecade] == true) then
		if doesPortalExist(mydecade) then
			return mydecade
		end
	end
	-- We don't have a portal for the decade, so now try the century.
--[[
the century portals have all been deleted, so comment out this section

	local myCenturyString = mw.ustring.gsub(decadeParam, "%d$", "")
	local myCenturyNum = tonumber(myCenturyString)
	local myCenturyNum = tonumber(myCenturyString)
	-- increment by one, because we have now conveted e.g. "1870s" to "18"
	-- but that's the 19th century
	myCenturyNum = myCenturyNum + 1
	-- the century portals have all been deleted, so disable the centeury checking
	-- return checkCentury(tostring(myCenturyNum))
]]--	return ""
end

-- check for the existence of a portal with the name of that century
-- if it exists, returns the century
-- otherwise returns an empty string
function checkCentury(centuryParam)
	local myCenturyString = ordinal_numbers(centuryParam) .. " century"
	if doesPortalExist(myCenturyString) then
		return myCenturyString
	end
	return ""
end


-- converts a string number to an string ordinal
-- e.g. 21 → 21st
--      17 → 17th
-- code copied from https://stackoverflow.com/questions/20694133/how-to-to-add-th-or-rd-to-the-date (license:CC BY-SA 3.0 )
function ordinal_numbers(n)
  local ordinal, digit = {"st", "nd", "rd"}, string.sub(n, -1)
  if tonumber(digit) > 0 and tonumber(digit) <= 3 and string.sub(n,-2) ~= 11 and string.sub(n,-2) ~= 12 and string.sub(n,-2) ~= 13 then
    return n .. ordinal[tonumber(digit)]
  else
    return n .. "th"
  end
end

function trim(s)
   return s:match "^%s*(.-)%s*$"
end

function p.findydcportal(frame)
	-- Expects one parameter
	-- {{{1}}} = a 3- or 4-digit year or deacde
	--    e.g. 1916
	--         1504
	--         1630s
	--         920s
	local arg1 = frame.args[1]
	if arg1 == nil then
		return ""
	end
	arg1 = trim(arg1) -- strip leading and trailing spaces
	if (mw.ustring.match(arg1, "^%d%d%d%d?$")) then
		-- it's a 3- or 4-digit-year
		return checkYear(arg1)
	elseif (mw.ustring.match(arg1, "^%d%d%d?0s$")) then
		-- it's a 3- or 4-digit decade
		-- so strip the trailing "0s"
		local decadeArg = mw.ustring.gsub(arg1, "0s$", "")
		return checkDecade(decadeArg)
	end
	-- If we get here, then arg1 was neither a year nor a decade
	-- This is going to be a helper template, and diagnostics woud be intrusive
	-- So just return an empty string
	return ""
end

return p