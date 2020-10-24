local p = {}

local mainCategory = {name = "Category:{series}", link = "[[Category:{series}|{type}]]"}

local secondaryCategoryList = {
	{name = "Category:{series} {type}s", link = "[[Category:{series} {type}s|*]]"},
	{name = "Category:{series} redirects", link = "[[Category:{series} redirects|{type}]]"}
}

local TRACKING_CATEGORY = "[[Category:Fiction redirect categories with non-existent parent categories]]"
local ERROR_MESSAGE = "Valid titles are in the style of \"Category:series-name content-type redirects to lists\""

--[[
Local function which checks if the category exists.
--]]
local function doesCategoryExist(category)
	return mw.title.new(category).exists
end

--[[
Local function which "Module:Sort title" to retrieve a sortkey and set it as the default sortkey.
--]]
local function getDefaultSortKey(frame)
	local sortkeyModule = require('Module:Sort title')
	local sortkey = sortkeyModule._getSortKey()
	
	return frame:preprocess{text = "{{DEFAULTSORT:" .. sortkey .. "}}"} 
end

--[[
Local helper function which handles the gsub of the series name into the category name.
--]]
local function gsubSeriesName(category, articleTitle)
	return category:gsub("{series}", articleTitle)
end

--[[
Local helper function which sets the top level category.
--]]
local function getTopLevelCategory(categoryType, args)
	local mediaList = {}
	table.insert(mediaList, args.media)
	
	for i = 2, 10 do
		if (args["media" .. i]) then
			table.insert(mediaList, args["media" .. i])
		else
			break
		end
	end

	return categoryType:getTopLevelCategory(mediaList)
end

--[[
Local helper function which sets the main category.
--]]
local function getMainCategory(categoryType, articleTitle)
	local categoryLink = gsubSeriesName(mainCategory.link, articleTitle)
	local categoryName = gsubSeriesName(mainCategory.name, articleTitle)

	if (not doesCategoryExist(categoryName)) then
		return TRACKING_CATEGORY
	end
	
	return categoryType:getMainCategory(categoryLink)
end

--[[
Local helper function which sets the secondary categories.
--]]
local function getSecondaryCategories(categoryType, articleTitle)
	local categoryList = ""
	for i = 1, #secondaryCategoryList do
		local secondaryCategory = secondaryCategoryList[i]
		local category = gsubSeriesName(secondaryCategory.name, articleTitle)
		category = categoryType:getCategory(category)
		if (doesCategoryExist(category)) then
			category = gsubSeriesName(secondaryCategory.link, articleTitle)
			category = categoryType:getCategory(category)
			categoryList = categoryList .. category
		end
	end
	
	return categoryList
end

--[[
Local function which handles the categorization of the category.
--]]
local function getCategories(categoryType, articleTitle, args)
	
	if (args.main) then
		articleTitle = args.main
	end
	
	local categoryList = getSecondaryCategories(categoryType, articleTitle)
	
	-- Only if there are no secondary categories, add to main category.
	if (categoryList == "") then
		categoryList = getMainCategory(categoryType, articleTitle)
	end

	local topLevelCategory = getTopLevelCategory(categoryType, args)
	return categoryList .. topLevelCategory
end

--[[
Local function which handles the Redirect category code.
--]]
local function getRedirectCategoryTemplate(frame, categoryType, articleTitle, seriesNameModified, seriesParameter)
	local redirectArgs = {
		from = string.format("[[%s|%s]] %s", articleTitle, seriesNameModified, categoryType.from),
		template = categoryType.template,
		no_info = "yes",
		not_maintenance = "yes",
		fiction = "yes"
	}
	
	if (categoryType.isFranchise) then
		redirectArgs.parameters = -1
	else
		redirectArgs.parameters = "series_name=" .. seriesParameter
	end

	return frame:expandTemplate{title = 'Redirect category', args = redirectArgs}
end

--[[
Local function which handles the italicization of the category title.
--]]
local function getItalicTitle(frame, seriesName, noItalic, test)
	local seriesNameModified = "''" .. seriesName .. "''"
	if (test) then
		if (noItalic) then
			return seriesName, seriesName
		else
			return seriesNameModified, seriesNameModified
		end
	else
		if (noItalic) then
			return "", seriesName
		else
			local italicTitleModule = require("Module:Italic title")._main
			local italicTitleArg = {string = seriesName}
			local italicText = italicTitleModule(italicTitleArg)
			return frame:preprocess{text = italicText}, seriesNameModified
		end
	end
end

--[[
Local function which extracts the series article name
and the category type from the category name.
--]]
local function getCategoryTitleParts(currentTitle, typeList)
	for _, categoryType in ipairs(typeList) do
		local _, _, articleTitle = string.find(currentTitle, "^(.*) " .. categoryType.redirectType .. " " .. categoryType.suffix)
		if (articleTitle) then
			return articleTitle, categoryType
		end
	end
	return nil, -1
end

--[[
Local function which is used to handle the actual main process.
--]]
local function _main(frame, args, title, namespace)
	local redirectType = require('Module:Fiction-based redirects to list entries category handler/RedirectType')
	local typeList = redirectType.getRedirectTypes()
	local articleTitle, categoryType = getCategoryTitleParts(title, typeList)

	-- A call from a documentation page; Show only the Redirect category header.
	if ((namespace ~= 'Category') and (not args.test)) then
		categoryType = redirectType.getDefaultType(typeList)
		local redirectCategoryTemplate = getRedirectCategoryTemplate(frame, categoryType, "Series name", "Series name", "Series name")
		return redirectCategoryTemplate
	end

	if (articleTitle) then
		local seriesParameter = articleTitle
		local franchiseSeriesParameter = categoryType:isCategorySpecialFranchise(articleTitle)
		if (franchiseSeriesParameter) then
			seriesParameter = franchiseSeriesParameter
		end
		
		local seriesName = mw.ustring.gsub(articleTitle, "%s+%b()$", "")
		
		local italicTitle, seriesNameModified = getItalicTitle(frame, seriesName, args.no_italic, args.test)
					
		local redirectCategoryTemplate = getRedirectCategoryTemplate(frame, categoryType, articleTitle, seriesNameModified, seriesParameter)
		local categoryToc = frame:expandTemplate{title = "CatAutoTOC"}
		local categories = getCategories(categoryType, articleTitle, args)
		local defaultSortKey = getDefaultSortKey(frame)
		
		if (args.test) then
			return italicTitle, articleTitle, categoryType.template, categories
		else
			return italicTitle .. "\n" .. redirectCategoryTemplate .. "\n" .. categoryToc .. "\n\n" .. defaultSortKey .. "\n" .. categories
		end
	else
		return error(ERROR_MESSAGE, 0)
	end
end

--[[
Public function which is used to handle the logic for fiction-based redirects to lists categories.

Parameters:
	-- |media=			— optional and suggested; The type of media the fiction belongs to.
							Types include, but not limited to: Film, Television and Video game. If unsure, check the high level category,
							such as "Category:Fictional character redirects", and see what sub-categories that category has.
	-- |media2...4=		— optional; Additional types of media the fiction belongs to.
	-- |main=			— optional; Use when the main series category is not written or disambiguated the same as the series article.
							Value will be used for the series category title.
	-- |no_italic=		— optional; Disables the italicizing of the series title.
--]]
function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	local currentTitle = mw.title.getCurrentTitle()
	return _main(frame, args, currentTitle.text, currentTitle.nsText)
end

--[[
Public function which is used for the testcases.

Parameters:
	-- |test=			— required; The series article name.
--]]
function p.test(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	
	local seriesName, articleTitle, template, categories = _main(frame, args, args.test, "Module")
	local testString = "Series name: %s\n\nArticle title: %s\n\nTemplate: %s\n\nCategories: <nowiki>%s</nowiki>"
	testString = string.format(testString, seriesName, articleTitle, template, categories)
	return testString
end

return p