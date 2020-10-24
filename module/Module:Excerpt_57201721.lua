local Transcluder = require('Module:Transcluder')

local yesno = require('Module:Yesno')

local ok, config = pcall(require, 'Module:Excerpt/config')
if not ok then config = {} end

local p = {}

-- Helper function to get arguments
local args
function getArg(key, default)
	value = args[key]
	if value and mw.text.trim(value) ~= '' then
		return value
	end
	return default
end

-- Helper function to handle errors
function getError(message, value)
	if type(message) == 'string' then
		message = Transcluder.getError(message, value)
	end
	if config.categories and config.categories.errors and mw.title.getCurrentTitle().isContentPage then
		message:node('[[Category:' .. config.categories.errors .. ']]')
	end
	return message
end

-- Helper function to get localized messages
function getMessage(key)
	local ok, TNT = pcall(require, 'Module:TNT')
	if not ok then return key end
	return TNT.format('I18n/Module:Excerpt.tab', key)
end

function p.main(frame)
	args = Transcluder.parseArgs(frame)

	-- Make sure the requested page exists
	local page = getArg(1)
	if not page then return getError('no-page') end
	local title = mw.title.new(page)
	if not title then return getError('no-page') end
	if title.isRedirect then title = title.redirectTarget end
	if not title.exists then return getError('page-not-found', page) end
	page = title.prefixedText

	-- Set variables
	local fragment = getArg('fragment')
	local section = fragment or getArg(2, getArg('section', mw.ustring.match(getArg(1), '[^#]+#([^#]+)') ) )
	local hat = yesno( getArg('hat', true) )
	local edit = yesno( getArg('edit', true) )
	local this = getArg('this')
	local only = getArg('only')
	local files = getArg('files', getArg('file', ( only == 'file' and 1 ) ) )
	local lists = getArg('lists', getArg('list', ( only == 'list' and 1 ) ) )
	local tables = getArg('tables', getArg('table', ( only == 'table' and 1 ) ) )
	local templates = getArg('templates', getArg('template', ( only == 'template' and 1 ) ) )
	local paragraphs = getArg('paragraphs', getArg('paragraph', ( only == 'paragraph' and 1 ) ) )
	local references = getArg('references', getArg('reference', ( only == 'reference' and 1 ) ) )
	local sections = not yesno( getArg('sections') )
	local noBold = not yesno( getArg('bold') )
	local inline = yesno( getArg('inline') )
	local quote = yesno( getArg('quote') )
	local more = yesno( getArg('more') )
	local class = getArg('class')
	local blacklist = table.concat((config.templates or {}), ',')

	-- Build the hatnote
	if hat and not inline then
		if this then
			hat = this
		elseif quote then
			hat = getMessage('this')
		elseif only then
			hat = getMessage(only)
		else
			hat = getMessage('section')
		end
		hat = hat .. ' ' .. getMessage('excerpt') .. ' '
		if section and not fragment then
			hat = hat .. '[[:' .. page .. '#' .. mw.uri.anchorEncode(section) .. '|' .. page
				.. ' § ' .. mw.ustring.gsub(section, '%[%[([^]|]+)|?[^]]*%]%]', '%1') .. ']]' -- remove nested links
		else
			hat = hat .. '[[:' .. page .. '|' .. page .. ']]'
		end
		if edit then
			hat = hat .. "''" .. '<span class="mw-editsection-like plainlinks"><span class="mw-editsection-bracket">[</span>['
			hat = hat .. title:fullUrl('action=edit') .. ' ' .. mw.message.new('editsection'):plain()
			hat = hat .. ']<span class="mw-editsection-bracket">]</span></span>' .. "''"
		end
		if config.hat then
			hat = config.hat .. hat .. '}}'
			hat = frame:preprocess(hat)
		end
		hat = mw.html.create('div'):addClass('dablink excerpt-hat'):wikitext(hat)
	else
		hat = nil
	end

	-- Build the "Read more" link
	if more and not inline then
		more = "'''[[" .. page .. '#' .. (section or '') .. "|" .. getMessage('more') .. "]]'''"
		more = mw.html.create('div'):addClass('noprint excerpt-more'):wikitext(more)
	else
		more = nil
	end

	-- Build the options for Module:Transcluder out of the template arguments and the desired defaults
	local options = {
		files = files,
		lists = lists,
		tables = tables,
		paragraphs = paragraphs,
		templates = templates or '-' .. blacklist,
		sections = sections,
		categories = 0,
		references = references,
		only = only and mw.text.trim(only, 's') .. 's',
		noBold = noBold,
		noSelfLinks = true,
		noNonFreeFiles = true,
		noBehaviorSwitches = true,
		fixReferences = true,
		linkBold = true,
	}

	-- Get the excerpt itself
	local title = page .. '#' .. (section or '')
	local ok, excerpt = pcall(Transcluder.get, title, options)
	if not ok then return getError(excerpt) end
	if mw.text.trim(excerpt) == '' then
		if section then return getError('section-empty', section) else return getError('lead-empty') end
	end

	-- Add a line break in case the excerpt starts with a table or list
	excerpt = '\n' .. excerpt

	-- If no file was found, try to excerpt one from the removed infoboxes
	local fileNamespaces = Transcluder.getNamespaces('File')
	if not only and (files ~= '0' or not files) and not Transcluder.matchAny(excerpt, '%[%[', fileNamespaces, ':') and config.captions then
		local templates = Transcluder.get(title, { only = 'templates', templates = blacklist, fixReferences = true } )
		local parameters = Transcluder.getParameters(templates)
		local file, captions, caption
		for _, pair in pairs(config.captions) do
			file = pair[1]
			file = parameters[file]
			if file and Transcluder.matchAny(file, '^.*%.', {'[Jj][Pp][Ee]?[Gg]','[Pp][Nn][Gg]','[Gg][Ii][Ff]','[Ss][Vv][Gg]'}, '.*') then
				file = mw.ustring.match(file, '%[?%[?.-:([^{|]+)%]?%]?') or file -- [[File:Example.jpg{{!}}upright=1.5]] to Example.jpg
				captions = pair[2]
				for _, p in pairs(captions) do
					if parameters[p] then caption = parameters[p] break end
				end
				excerpt = '[[File:' .. file .. '|thumb|' .. (caption or '') .. ']]' .. excerpt
				excerpt = Transcluder.removeNonFreeFiles(excerpt)
				break
			end
		end
	end

	-- Remove nested categories
	excerpt = frame:preprocess(excerpt)
	local categories, excerpt = Transcluder.getCategories(excerpt, options.categories)

	-- Add tracking categories
	if config.categories then
		local contentCategory = config.categories.content
		if contentCategory and mw.title.getCurrentTitle().isContentPage then
			excerpt = excerpt .. '[[Category:' .. contentCategory .. ']]'
		end
		local namespaceCategory = config.categories[ mw.title.getCurrentTitle().namespace ]
		if namespaceCategory then
			excerpt = excerpt .. '[[Category:' .. namespaceCategory .. ']]'
		end
	end

	-- Load the styles
	local styles
	if config.styles then
		styles = frame:extensionTag( 'templatestyles', '', { src = config.styles } )
	end

	-- Combine and return the elements
	local tag1 = 'div'
	local tag2 = 'div'
	if inline then
		tag1 = 'span'
		tag2 = 'span'
	elseif quote then
		tag2 = 'blockquote'
	end
	excerpt = mw.html.create(tag1):addClass('excerpt'):wikitext(excerpt)
	local block = mw.html.create(tag2):addClass('excerpt-block'):addClass(class)
	return block:node(styles):node(hat):node(excerpt):node(more)
end

-- Entry points for backwards compatibility
function p.lead(frame) return p.main(frame) end
function p.excerpt(frame) return p.main(frame) end

return p