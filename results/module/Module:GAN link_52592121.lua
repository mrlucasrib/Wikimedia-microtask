-- This module implements {{GAN link}}.

local p = {}

local function getGANIcon()
	return require('Module:Icon')._main{'GAN'}
end

local function makeWikilink(page, display)
	if display and display ~= page then
		return string.format('[[%s|%s]]', page, display)
	else
		return string.format('[[%s]]', page)
	end
end

local function getNominationPage(article, number)
	return string.format('Talk:%s/GA%d', article, number)
end

local function makeArticleLink(options)
	assert(options.article, 'options.article not specified')
	assert(options.formattedArticle, 'options.formattedArticle not specified')
	local display
	if options.isItalic then
		display = string.format('<i>%s</i>', options.article)
	elseif options.display then
		display = options.display
	else
		display = options.formattedArticle
	end
	return makeWikilink(options.article, display)
end

local function makeExistingNominationLink(nominationPage)
	return makeWikilink(nominationPage, 'nom')
end

local function makeNewNominationLink(nominationPage)
	local url = mw.uri.fullUrl(nominationPage, {
		action    = 'edit',
		editintro = 'Template:GAN/editintro',
		preload   = 'Template:GAN/preload',
	})
	return string.format(
		"'''<span class='plainlinks'>[%s start]</span>'''",
		tostring(url)
	)
end

local function makeNominationLink(nominationPage)
	assert(nominationPage, 'no nominationPage argument given to makeNominationLink')
	local title = mw.title.new(nominationPage)
	if not title then
		error(string.format('%s is not a valid title', nominationPage), 2)
	elseif title.exists then
		return makeExistingNominationLink(nominationPage)
	else
		return makeNewNominationLink(nominationPage)
	end
end

function p._main(args)
	-- Link parameters
	local formattedArticle = args[1]
	if not formattedArticle then
		error('No article specified', 2)
	end
	local article = formattedArticle:gsub("'''", ""):gsub("''", "")
	local display = args[2]

	-- Number
	local number
	if args['#'] then
		number = tonumber(args['#'])
		if not number then
			error("'%s' is not a valid number", args['#'])
		end
	else
		number = 1
	end

	-- Formatting parameters
	local hasIcon = not not args.icon
	local isItalic = not not args.i

	-- Output
	local ret = {}
	if hasIcon then
		ret[#ret + 1] = getGANIcon()
	end
	ret[#ret + 1] = makeArticleLink{
		article = article,
		formattedArticle = formattedArticle,
		display = display,
		isItalic = isItalic,
	}
	ret[#ret + 1] = string.format(
		'(%s)',
		makeNominationLink(getNominationPage(article, number))
	)
	return table.concat(ret, ' ')
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:GAN link'
	})
	return p._main(args)
end

return p