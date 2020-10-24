-- This module implements {{tasks}}.

local itemHeadings = mw.loadData('Module:Tasks/headings')

local p = {}

function p.main(frame)
	local origArgs = frame:getParent().args
	local args = {}
	for k, v in pairs(origArgs) do
		if v ~= '' then
			args[k] = v
		end
	end
	return p.luaMain(args)
end

function p.luaMain(args)
	-- Make an array of list items.
	local items = {}
	for k, v in pairs(args) do
		local heading = itemHeadings[k]
		if heading then
			items[#items + 1] = {
				key = k,
				heading = heading,
				content = v
			}
		end
	end
	table.sort(items, function (t1, t2)
		local key1 = t1.key
		local key2 = t2.key
		if key1 == 'reason' then
			return true
		else
			return key1 < key2
		end
	end)

	-- Add the "other" argument to the list item array.
	if args.other then
		table.insert(items, {
			key = 'other',
			heading = args.othertext or 'Other',
			content = args.other
		})
	end

	-- Make the list wikitext.
	local list = mw.html.create('ul')
	list
		:css{
			['font-size'] = '100%',
			padding = '.3em 0 .3em 25px',
			margin = '0'
		}
	if args.listclass then
		list:addClass(args.listclass)
	end
	for i, t in ipairs(items) do
		list:tag('li'):wikitext(string.format(
			"'''''%s''''':\n%s",
			t.heading,
			t.content
		))
	end
	list = tostring(list)
		
	-- Make the surrounding div tags.
	local listDiv = mw.html.create('div')
	listDiv
		:css{
			position = 'relative',
			left = '0px',
			['margin-right'] = '-0px',
			['z-index'] = '15'
		}
		:wikitext(
			"Here are some "
			.. "'''[[Wikipedia:Community portal/Opentask|tasks you can do]]''':"
		)
		:newline()
		:wikitext(list)
	listDiv = tostring(listDiv)

	-- Construct the wikitable.
	local image
	if args.image == 'off' then
		image = ''
	else
		image = '[[File:Nuvola apps korganizer.svg|50px|<nowiki></nowiki>]]'
			.. '<br /><div style="width:65px;height:0px;"></div>'
	end
	local tableFormat = [[
{| style="background:none;width:auto;"
| style="vertical-align:top" |
%s
|
%s
|}]]
	return string.format(tableFormat, image, listDiv)
end

return p