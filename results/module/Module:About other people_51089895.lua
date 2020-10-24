local mAbout = require('Module:About')
local mHatnote = require('Module:Hatnote')
local mArguments = require('Module:Arguments')
local p = {}

local s = { --strings
	emptySubject = 'no page subject specified',
	templateName = 'Template:About other people',
	andKeyword = 'and',
	otherPeopleNamedForm = 'other people %s %s',
	named = 'named',
	otherPeopleSame = 'other people with the same name',
}

function p.aboutOtherPeople (frame)
	local args = mArguments.getArgs(frame)
	--if not args[1], a different template would be better!
	if not args[1] then
		return mHatnote.makeWikitextError(
			s.emptySubject,
			s.templateName,
			args.category
		)
	end
	--get pages from arguments if applicable, with attempted default to args[2]
	local pages = {}
	for k, v in pairs(args) do
		if type(k) == 'number' and k > 2 then
			if pages[1] then table.insert(pages, s.andKeyword) end
			table.insert(pages, v)
		end
	end
	if #pages == 0 then pages = {args[2] and mHatnote.disambiguate(args[2])} end
	--translate args into args for _about(). [2] is nil to force otherText.
	local returnArgs = {text = args.text, args[1], nil, unpack(pages)}
	local options = {
		otherText = (args[2] and
			string.format(
					s.otherPeopleNamedForm,
					args.named or s.named,
					args[2]
				)
			) or s.otherPeopleSame
	}
	return mAbout._about(returnArgs, options)
end

return p