local p = {}
local getArgs = require('Module:Arguments').getArgs

local validmonth = {
	["january"] = "OK",
	["february"] = "OK",
	["march"] = "OK",
	["april"] = "OK",
	["may"] = "OK",
	["june"] = "OK",
	["july"] = "OK",
	["august"] = "OK",
	["september"] = "OK",
	["october"] = "OK",
	["november"] = "OK",
	["december"] = "OK"
}

	
function isValidMonth(s)
	local mymonth = mw.ustring.gsub(s, "%s+%d%d%d%d%s*$", "")
	mymonth = mw.ustring.gsub(s, "^%s+", "")
	if (validmonth[string.lower(mymonth)] == "OK") then
		return true
	end
	return false
end

function p.main(frame)
	local rawcats = {}
	local nvalid = 0
	local args = getArgs(frame)
	
	local electionyear =args['electionyear'];
	
	if (electionyear == nil) then
		electionyear = ""
	end
	
	if ((electionyear == nil) or (mw.ustring.match(electionyear, "^%s*$") ~= nil)) then
		return "[[Category:CanElecResTopTest with nil value]]"
	elseif (mw.ustring.match(electionyear, "^%s*%d%d%d%d%s*$") ~= nil) then
		return "[[Category:CanElecResTopTest with bare year]]"
	elseif (mw.ustring.match(electionyear, "^.*%s+%d%d%d%d%s*$") ~= nil) then
		if (isValidMonth(electionyear)) then
			return "[[Category:CanElecResTopTest with month year]]"
		else
			return "[[Category:CanElecResTopTest with something before year]]"
		end
	else
		return "[[Category:CanElecResTopTest with unrecognised value]]"
	end
end

return p