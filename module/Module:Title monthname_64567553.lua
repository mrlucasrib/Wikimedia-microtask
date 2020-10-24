--[[ v1.00
     Split the page title into words then test each of them against
     the list of months.
     Optionally, an alternative page name may be supplied as a parameter.
     Return the first word which matches a months name ...
     unless the "match=" parameter specifies a diffreent match.
     If there is no match, then return an empty string ... unles
     the "nomatch" parameter specifies something different
]]

local getArgs = require('Module:Arguments').getArgs
local p = {}

-- config
local nomatch = ""
local matchnum = 1

local monthList = {
	'January',
	'February',
	'March',
	'April',
	'May',
	'June',
	'July',
	'August',
	'September',
	'October',
	'November',
	'December'
}

-- splits a string into "words"
-- a "word" is a set of characters delineated at each end by one 
--    or more whitespace characters or punctaution charaters
function splitIntoWords(str)
	result = {}
	index = 1
	s = mw.ustring.gsub(str, "^[%s%p]+", "") -- strip leading whitespace or punctuation
	for s2 in mw.ustring.gmatch(s, "[^%s%p]+[%s%p]*") do
		s3 = mw.ustring.gsub(s2, "[%s%p]+$", "") -- strip trailing separators
		result[index] = s3
		index = index + 1
	end
return result
end

-- returns the first word is the pagename which matches the name of a month
-- ... or an empty string if there is no match
function checkPagename(pn)
	-- split the pagename into sparate words
	titleWords = splitIntoWords(pn)
	
	nMatches = 0
	myMatches ={}
	
	-- check each words in turn, to see if it matches a month
	for w, thisWord in ipairs(titleWords) do
		-- check agaist each month
		-- if there is a match, then return that monthname
		for i, thisMonth in ipairs(monthList) do
			if (thisMonth == thisWord) then
				nMatches = nMatches + 1
				myMatches[nMatches] = thisMonth
			end
		end
	end

	if (nMatches == 0) then
		-- none of the title words matches a whole month
		return nomatch
	end
	
	if ((matchnum >= 1) and (matchnum <= nMatches)) then
		return myMatches[matchnum]
	end

	if (matchnum < 0) then
		matchnum = matchnum + 1 -- so that -1 is the last match etc
		if ((matchnum + nMatches) >= 1) then
			return myMatches[matchnum + nMatches]
		end
	end
	
	-- if we get here, we have not found a match at the position specified by "matchnum"
	return nomatch
end

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	if (args['nomatch'] ~= nil) then
		nomatch = args['nomatch']
	end
	
	-- by default, we return the first match
	-- but the optional "C" paarmeter sets the "matchnum" variable, which
	-- * for a positive matchnum "n", returns the nth match if it exists
	-- * for a positive matchnum "n", returns (if it exists) the nth match
	--   counting backwards from the end.
	--   So "match=-1" returns the last match
	--   and "match=-3" returns the 3rd-last match
	if (args['match'] ~= nil) then
		matchnum = tonumber(args['match'])
		if ((matchnum == nil) or (matchnum == 0)) then
			matchnum = 1
		end
	end
	
	-- by default, we use the current page
	-- but if the "page=" parameters is supplied, we use that
	-- so we try the parameter first
	thispagename = nil
	if ((args['page'] ~= nil) and (args['page'] ~= "")) then
		-- we have a non-empty "page" parameter, so we use it
		thispagename = args['page']
	else
		-- get the page title
		thispage = mw.title.getCurrentTitle()
		thispagename = thispage.text;
	end
	
	-- now check the pagename to try to find a month ananme
	result = checkPagename(thispagename)
	if (result == "") then
		return nomatch
	end
	return result
end

return p