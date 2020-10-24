-- Do not add a style which is not supported by the [[WP:NCTV]] guidelines.

-- This module requires the use of Module:Extract short description.
local extract = require('Module:Extract short description')

-- Release version template list.
local releaseTemplates = {
	'Infobox television episode',
	'Infobox Television episode',
	'Television episode short description',
	'Short description',
	'Television episode redirect handler'
}

local p = {}

-- Local function used to create the stylized article disambiguation.
local function getStylizedDisambiguation(disambiguation)
	local isDisambiguationExtended = string.find(disambiguation, "episode")				-- Search for the word "episode" in the article name disambiguation (disambiguation is extended).
	
	if (not isDisambiguationExtended) then												-- Check if the article name has extended disambiguation.
		return "(''" .. disambiguation .. "'')"											-- Article does not have extended disambiguation; 
																						-- Add italics to the disambiguation which should only be the TV series name per [[MOS:ITALICTITLE]] and [[WP:NCTV]].
	else																				-- Articles has extended disambiguation;
		local tvSeries = string.gsub(disambiguation, "episode", "", 1, true)			-- Get the TV series name without the extended disambiguation.
		tvSeries = mw.text.trim(tvSeries)												-- Remove trailing whitespaces.
		return "(''" .. tvSeries .. "'' episode)"										-- Add italics to the disambiguation which should only be the TV series name per [[MOS:ITALICTITLE]] and [[WP:NCTV]]; 
	end																					-- and add back the extended disambiguation.

end

-- Local function used to create the stylized article title.
local function getStylizedArticleTitle(articleName)
	local articleTitle = string.gsub(articleName, "%s+%b()$", "", 1, false)				-- Get the article title without the disambiguation.
	return "\"" .. articleTitle .. "\""													-- Add quotation marks to the title per [[MOS:QUOTETITLE]].
end

-- Local function used to get the disambiguated formatted episode link.
local function getDisambiguatedFormattedLink(articleName)
	local disambiguation = string.match(articleName, "%s%((.-)%)")						-- Get the text inside the disambiguation parentheses.

	if (not disambiguation) then														-- Check if the article name does not have disambiguation parentheses.
		return "\"[[" .. articleName .. "]]\""											-- Article does not have disambiguation parentheses; Add quotation marks to the title per [[MOS:QUOTETITLE]] and return it.
	else																				-- Article has disambiguation parentheses;
		local stylizedArticleTitle = getStylizedArticleTitle(articleName)				-- Call getStylizedArticleTitle() to get the stylized article title.
		local stylizedDisambiguation = getStylizedDisambiguation(disambiguation)		-- Call getStylizedDisambiguation() to get the stylized disambiguation.
		local stylizedName = stylizedArticleTitle .. " " .. stylizedDisambiguation		-- Recreate the article name from the title and disambiguation.
		return "[[" .. articleName .. "|" .. stylizedName .. "]]"						-- Create a pipped link and return it.
	end
	
	return 
end

-- Local function used to create a formatted episode link.
local function getFormmatedArticleLink(articleName, parenthesesPartOfTitle)
	local formattedLink																	-- Variable to save the formatted link.

	if (parenthesesPartOfTitle ~= nil) then												-- Check if the parentheses is part of the episode title.
		formattedLink = "\"[[" .. articleName .. "]]\""									-- Parentheses is part of the title; Add quotation marks to the title per [[MOS:QUOTETITLE]].
	else																				-- Parentheses is not part of the title; 
		formattedLink = getDisambiguatedFormattedLink(articleName)						-- Call getDisambiguatedFormmatedLink() to get the disambiguated formatted episode link.
	end

    return formattedLink																-- Return the formatted link.
end

-- Local function used to retrieve the short description
-- from an episode article's template - either Template:Infobox television episode or Template:Short description.
-- See the table list for the complete template list.
local function getShortDescription(frame, articleName)
	local templatesTable = releaseTemplates												-- Get the release version template list by default.

	local shortDescription																-- Create a variable to store the short description.
	local descriptionFound																-- Create a variable to store the success result.
	shortDescription, descriptionFound = 
	extract.extract_from_template(frame, articleName, templatesTable)					-- Call extract_from_template() from Module:Extract short description to get the short description.
		
	-- Currently this is redundant as it always returns the same item,
	-- however this is in place for future possibilities.
	if (descriptionFound) then															-- Check if a short description was found.
		shortDescription = shortDescription:gsub("^%a", string.lower)                   -- The description should start with a lowercase letter.
		return shortDescription															-- A short description was found; Return it.
	else
		return shortDescription															-- A short description was not found; Return the error message.
	end
end

-- Local function that does the actual main process.
local function _main(frame, articleName, parenthesesPartOfTitle, formattedLinkOnly, shortDescriptionOnly)
	local formattedLink = getFormmatedArticleLink(articleName, parenthesesPartOfTitle)	-- Call getFormmatedArticleLink() and return a formatted link.
	if (formattedLinkOnly) then															-- Check if only a formatted link is needed.
		return formattedLink															-- Only a formatted link is needed; Call getFormmatedArticleLink() and return a formatted link.
	end

	local shortDescription = getShortDescription(frame, articleName)					-- Call getShortDescription() and return the episode's short description.
	if shortDescriptionOnly then
		return shortDescription
	end

	return	formattedLink .. ", " .. shortDescription									-- Return a complete entry.
end

-- Local function used to create an error message.
local function getErrorMsg(errorMsg)
	return '<span style="font-size:100%;" class="error">error: ' .. errorMsg .. '.</span>'
end

--[[
Public function used to create an entry for a television episode 
in a disambiguation page.
The entry is in the form of: "<article name>", <short description>
If set to "link_only", only a formatted episode link will be returned.
See documentation for examples.

Parameters:
	--	{{{1}}} or |article=	— required; The name of the episode's article name.
	--	|not_disambiguated=		— optional; Set if the parentheses is part of the episode name.
	--	|link_only=				— optional; Set if only a formatted article link should return.
	--	|dab_only=				— optional; Set if only a short description should return.
--]]
function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs									-- Use Module:Arguments to access module arguments.
	local args = getArgs(frame)															-- Get the arguments sent via the template.

	local articleName = args["name"]													-- Get the article name.
	
	if (articleName == nil) then														-- Check if the article name was entered.
		return getErrorMsg("an article title is required")								-- No article name was entered; Call getErrorMsg() to create an error message and return it.
	end

	local parenthesesPartOfTitle = args["not_disambiguated"]
	local formattedLinkOnly = args["link_only"]
	local shortDescriptionOnly = args["dab_only"]

	return _main(frame, articleName, parenthesesPartOfTitle, formattedLinkOnly, shortDescriptionOnly)	-- Call _main() to perform the actual process.

end	

return p