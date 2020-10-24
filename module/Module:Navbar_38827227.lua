local p = {}

local getArgs
local ul

function p.addItem (mini, full, link, descrip, args, url)
	local l
	if url then
		l = {'[', '', ']'}
	else
		l = {'[[', '|', ']]'}
	end
	ul:tag('li')
		:addClass('nv-'..full)
		:wikitext(l[1] .. link .. l[2])
		:tag(args.mini and 'abbr' or 'span')
			:attr('title', descrip..' this template')
			:cssText(args.fontstyle)
			:wikitext(args.mini and mini or full)
			:done()
		:wikitext(l[3])
end

function p.brackets (position, c, args, div)
	if args.brackets then
		div
			:tag('span')
				:css('margin-'..position, '-0.125em')
				:cssText(args.fontstyle)
				:wikitext(c)
	end
end

function p._navbar(args)
	local show = {true, true, true, false, false, false}
	local titleArg = 1
	
	if args.collapsible then
		titleArg = 2
		if not args.plain then args.mini = 1 end
		if args.fontcolor then
			args.fontstyle = 'color:' .. args.fontcolor .. ';'
		end
		args.style = 'float:left; text-align:left'
	end
	
	if args.template then
		titleArg = 'template'
		show = {true, false, false, false, false, false}
		local index = {t = 2, d = 2, e = 3, h = 4, m = 5, w = 6, talk = 2, edit = 3, hist = 4, move = 5, watch = 6}
		for k,v in ipairs(require ('Module:TableTools').compressSparseArray(args)) do
			local num = index[v]
			if num then show[num] = true end
		end
	end
	
	if args.noedit then show[3] = false end
	
	local titleText = args[titleArg] or (':' .. mw.getCurrentFrame():getParent():getTitle())
	local title = mw.title.new(mw.text.trim(titleText), 'Template')
	if not title then
		error('Invalid title ' .. titleText)
	end
	local talkpage = title.talkPageTitle and title.talkPageTitle.fullText or ''
	
	local div = mw.html.create():tag('div')
	div
		:addClass('plainlinks')
		:addClass('hlist')
		:addClass('navbar')
		:cssText(args.style)

	if args.mini then div:addClass('mini') end

	if not (args.mini or args.plain) then
		div
			:tag('span')
				:css('word-spacing', 0)
				:cssText(args.fontstyle)
				:wikitext(args.text or 'This box:')
				:wikitext(' ')
	end
	
	p.brackets('right', '&#91; ', args, div)
	
	ul = div:tag('ul')
	if show[1] then p.addItem('v', 'view', title.fullText, 'View', args) end
	if show[2] then p.addItem('t', 'talk', talkpage, 'Discuss', args) end
	if show[3] then p.addItem('e', 'edit', title:fullUrl('action=edit'), 'Edit', args, true) end
	if show[4] then p.addItem('h', 'hist', title:fullUrl('action=history'), 'History of', args, true) end
	if show[5] then
		local move = mw.title.new ('Special:Movepage')
		p.addItem('m', 'move', move:fullUrl('target='..title.fullText), 'Move', args, true) end
	if show[6] then p.addItem('w', 'watch', title:fullUrl('action=watch'), 'Watch', args, true) end
	
	p.brackets('left', ' &#93;', args, div)
	
	if args.collapsible then
		div
			:done()
		:tag('div')
			:css('font-size', '114%')
			:css('margin', args.mini and '0 4em' or '0 7em')
			:cssText(args.fontstyle)
			:wikitext(args[1])
	end

	return tostring(div:done())
end

function p.navbar(frame)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end
	return p._navbar(getArgs(frame))
end

return p