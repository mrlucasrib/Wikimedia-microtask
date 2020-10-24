local mHatnote = require('Module:Hatnote')
local mHatlist = require('Module:Hatnote list')
local mArguments --initialize lazily
local mTableTools = require('Module:TableTools')
local checkType = require('libraryUtil').checkType
local p = {}

function p.aboutDistinguish (frame)
	mArguments = require('Module:Arguments')
	local args = mArguments.getArgs(frame)
	return p._aboutDistinguish(args)
end

function p._aboutDistinguish(args, options)
	-- Type checks and defaults
	checkType('_aboutDistinguish', 1, args, 'table')
	if not args[1] then
		return mHatnote.makeWikitextError(
			'no about topic supplied',
			'Template:About-distinguish',
			args.category
		)
	end
	if not args[2] then
		return mHatnote.makeWikitextError(
			'no page to be distinguished supplied',
			'Template:About-distinguish',
			args.category
		)
	end
	checkType('_aboutDistinguish', 2, options, 'table', true)
	options = options or {}
	local defaultOptions = {
		defaultPageType = 'page',
		namespace = mw.title.getCurrentTitle().namespace,
		pageTypesByNamespace = {
			[0] = 'article',
			[14] = 'category'
		},
		sectionString = 'section'
	}
	for k, v in pairs(defaultOptions) do
		if options[k] == nil then options[k] = v end
	end

	-- Set pieces of initial "about" string
	local pageType = (args.section and options.sectionString) or
		options.pageTypesByNamespace[options.namespace] or
		options.defaultPageType
	args = mTableTools.compressSparseArray(args)
	local about = table.remove(args, 1)

	--Get pronoun from Wikidata. Really basic, but it should work.
	local pronouns = {
		['female'] = 'She is',
		['transgender female'] = "She is",
		['male'] = 'He is',
		['transgender male'] = 'He is',
		['default'] = 'They are'
	}
	local wde = mw.wikibase.getEntity()
	local p31 = (wde and wde:formatPropertyValues('P31').value) == 'human'
	local p21 = wde and wde:formatPropertyValues('P21').value
	local pronoun = p31 and (pronouns[p21] or pronouns['default']) or 'It is'

	--Assemble everything together and return
	local text = string.format(
		'This %s is about %s. %s not to be confused with %s.',
		pageType,
		about,
		pronoun,
		mHatlist.orList(args, true)
	)
	return mHatnote._hatnote(text)
end

return p