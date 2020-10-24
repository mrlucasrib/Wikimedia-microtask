-- This module requires the use of the following modules.
local getArgs = require('Module:Arguments').getArgs
local validateDisambiguation = require('Module:Television infoboxes disambiguation check')

local p = {}

local validDisambiguationTypeList = {
	"TV series",
	"TV programme",
	"TV program",
	"TV film",
	"film",
	"miniseries",
	"serial",
	"game show",
	"talk show",
	"web series"
}

local validDisambiguationPatternList  = {
	validateDisambiguation.DisambiguationPattern{pattern = "^(%d+) (%D+)", type = 1}, --"VALIDATION_TYPE_YEAR_COUNTRY"
	validateDisambiguation.DisambiguationPattern{pattern = "^%d+$", type = 2}, --"VALIDATION_TYPE_YEAR"
	validateDisambiguation.DisambiguationPattern{pattern = "^%D+$", type = 3} --"VALIDATION_TYPE_COUNTRY"
}

local exceptionList = {
	"The (206)",
	"Bigg Boss (Hindi TV series)",
	"Bigg Boss (Malayalam TV series)",
	"Bigg Boss (Telugu TV series)",
	"Cinderella (Apakah Cinta Hanyalah Mimpi?)",
	"Deal or No Deal Malaysia (English-language game show)",
	"Deal or No Deal Malaysia (Mandarin-language game show)",
	"How to Live with Your Parents (For the Rest of Your Life)",
	"How to Sell Drugs Online (Fast)",
	"I (Almost) Got Away With It",
	"Kevin (Probably) Saves the World",
	"M.R.S. (Most Requested Show)",
	"Monty Python: Almost the Truth (Lawyers Cut)",
	"Off Sides (Pigs vs. Freaks)",
	"Randall and Hopkirk (Deceased)",
	"Who the (Bleep)...",
	"Who the (Bleep) Did I Marry?",
}

local otherInfoboxList = {
	["franchise"] = "[[Category:Television articles using incorrect infobox|FRANCHISE]]",
	["radio"] = "[[Category:Television articles using incorrect infobox|R]]",
	["season"] = "[[Category:Television articles using incorrect infobox|S]]",
	["series %d*"] = "[[Category:Television articles using incorrect infobox|S]]",
	["TV programming block"] = "[[Category:Television articles using incorrect infobox|P]]",
	["film series"] = "[[Category:Television articles using incorrect infobox|FILM]]"
}

-- Empty for now.
local invalidTitleStyleList = {}

local function _main(args)
	local title = args[1]
	return validateDisambiguation.main(title, "infobox television", validDisambiguationTypeList, validDisambiguationPatternList, exceptionList, otherInfoboxList, invalidTitleStyleList)
end

function p.main(frame)
	local args = getArgs(frame)
	local category, debugString = _main(args)
	return category
end

local function removeFromArray(t, delete)
    local j = 1
    local n = #t

    for i = 1, n do
        if (t[i] ~= delete) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1 -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil
        end
    end

    return t
end

function p.getDisambiguationTypeList()
	return removeFromArray(validDisambiguationTypeList, "TV series")
end

function p.test(frame)
	local args = getArgs(frame)
	local category, debugString = _main(args)
	return debugString
end

return p