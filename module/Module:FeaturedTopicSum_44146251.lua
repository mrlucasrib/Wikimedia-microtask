-- This module implements {{FeaturedTopicSum}}.

local p = {}

local function pagesInCategory(category)
	-- Gets the number of pages in a category. Counting pages in a category is
	-- expensive, so use pcall in case we are being used on pages with lots of
	-- expensive function calls.
	local success, noPages = pcall(
		mw.site.stats.pagesInCategory,
		category,
		'pages'
	)
	return success and noPages or 0
end

function p.status(topic)
	if not topic then
		error('no topic specified', 2)
	end
	local baseCategory = 'Wikipedia featured topics ' .. topic
	local noGood = pagesInCategory(baseCategory .. ' good content')
	local noFeatured = pagesInCategory(baseCategory .. ' featured content')
	local noOther = pagesInCategory(baseCategory)

	-- For a topic to be featured:
	-- 1) it must contain at least two featured articles, and
	-- 2) 50% or more of its articles must be featured.
	-- If either of these criteria are not met, the topic is assumed to be a
	-- good topic.
	if noFeatured >= 2 and noFeatured >= (noGood + noOther) then
		return 'FT'
	else
		return 'GT'
	end
end

function p._main(args)
	local status = p.status(args[1])
	if status == 'FT' then
		return args[2]
	else
		return args[3]
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:FeaturedTopicSum'
	})
	return p._main(args)
end

return p