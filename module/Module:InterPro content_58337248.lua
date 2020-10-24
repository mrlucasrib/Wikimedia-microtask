local getArgs = require('Module:Arguments').getArgs

local beginText = 'This article incorporates text from the public domain [[Pfam]] and [[InterPro]]: '
local baseUrl = 'https://www.ebi.ac.uk/interpro/entry/'

local p = {}

local function interproLink(arg)
	-- text before first space, if any; otherwise, whole arg
	local accessionNumber = arg:match('^([^ ]*) ') or arg

	-- text after first space, if any; otherwise, accessionNumber
	local linkText = arg:match(' (.*)') or accessionNumber
	
	return '[' .. baseUrl .. accessionNumber .. ' ' .. linkText .. ']'
end

local function renderList(args)
	local listRoot = mw.html.create('ul')
		:addClass('hlist hlist-separated')
		:css('display', 'inline')
		:css('margin', 0)

    for _, a in ipairs(args) do
		listRoot
			:tag('li')
				:wikitext(interproLink(a))
    end

	return tostring(listRoot)
end

function p.main(frame)
	local args = getArgs(frame)

	if not args[1] then
		return '<div class="error">[[Module:InterPro content]]: required argument 1 is missing</div>'
    elseif not args[2] then
		return '<div role="note" style="font-style: italic;">' .. beginText .. interproLink(args[1]) .. '</div>'
	else
		return '<div role="note" style="font-style: italic;">' .. beginText .. renderList(args) .. '</div>'
	end
end

return p