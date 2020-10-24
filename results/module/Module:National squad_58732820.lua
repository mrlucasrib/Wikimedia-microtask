-- This module implements [[Template:National squad]] and 
-- [[Template:National squad no numbers]] to avoid articles being added to 
-- [[:Category:Pages where template include size is exceeded]]
-- when the template is used many times.
local p = {}

function p.main(frame)
	local nonumbers = frame.args['nonumbers']
	local args = frame:getParent().args
	local country = args.country or '{{{country}}}'
	local coach_label = args.coach_type or 'Coach'
	local comp = args.comp or '{{{comp}}}'
	local name = args.name or ''
	local sport = args.sport or 'football'
	local gender = (args.gender or '') == 'female' and ' women\'s' or ''
	local titlestyle = 'background-color:' .. (args.bg or 'transparent') .. ';'
		.. 'color:' .. (args.fg or 'inherit') .. ';' 
		.. 'border: 1px solid ' .. (args.bordercolor or '#aaa') .. ';'
	local image = frame:expandTemplate{
		title = 'flagicon', 
		args = {args.country or 'none', args.flagvar or '', size = '50px'}
	}

	local ospan = '<span style="color:' .. (args.fg or 'inherit') .. '">'
	local cspan = '</span>'	
	local title = string.format('[[%s|%s%s%s]] – [[%s|%s%s%s]]', 
		args['team link'] or (country .. gender .. ' national ' .. sport .. ' team'), 
		ospan, args.title or country .. ' squad', cspan, 
		args['comp link'] or comp, ospan, comp, cspan)
	
	local haspos = false
	
	-- Tracking and preview warnings
	local knownargs = {['bg']=1, ['fg']=1, ['bordercolor']=1, ['coach']=1, ['coach_type']=1,
		['comp']=1, ['comp link']=1, ['country']=1, ['flagvar']=1, ['gender']=1, 
		['list']=1, ['name']=1, ['note']=1, ['sport']=1, ['team link']=1, ['title']=1}
	local badargs = {}
	for k, v in pairs(args) do
		if knownargs[k] then
		elseif type(k) == 'string' then
			local n = tonumber(k:match('^p(%d+)$') or k:match('pos(%d+)') or '0')
			if k:match('^p%d+$') and n >= 1 and n <= 40 then
			elseif nonumbers and (k:match('^pos%d+$') and n >= 1 and n <= 40) then
				if v and v ~= '' then haspos = true end
			elseif v and v ~= '' then
				table.insert(badargs, k)
			end
		elseif v and v ~= '' then
			table.insert(badargs, k)
		end
	end
	local preview, tracking = '', ''
	if #badargs > 0 then
		for k, v in pairs(badargs) do
			if v == '' then	v = ' '	end
			v = mw.ustring.gsub(v, '[^%w\-_ ]', '?')
			preview = preview .. '<div class="hatnote" style="color:red"><strong>Warning:</strong> '
				.. 'Page using national squad with unknown parameter "' .. v 
				.. '" (this message is shown only in preview).</div>'
			tracking = tracking .. '[[Category:Pages using national squad with unknown parameters|' .. v .. ']]'
		end
		if frame:preprocess( "{{REVISIONID}}" ) ~= "" then
			preview = ''
		end
	end
	if (args['title'] == nil and args['team link'] == nil and args.country == nil) or args.comp == nil then
		tracking = tracking .. '[[Category:Pages using national squad with unknown parameters|!]]'
	end
	if not args['comp link'] or (args['comp link'] == '') then
		tracking = tracking .. '[[Category:Pages using national squad without comp link]]'
	end
	if not args['sport'] or (args['sport'] == '') then
		if not args['team link'] or (args['team link'] == '') then
			tracking = tracking .. '[[Category:Pages using national squad without sport or team link]]'
		end
	end
	-- if tracking ~= '' and mw.title.getCurrentTitle().namespace > 0 then tracking = '' end
	
	local list1 = args.list or ''
	if list1 == '' then
		for k = 1,40 do
			if args['p' .. k] and args['p' .. k] ~= '' then
				local n = nonumbers and (args['pos' .. k] or '') or tostring(k)
				if n ~= '' or haspos == true then
					list1 = list1 .. string.format(
						'*<small>%s</small>&nbsp;<span class="vcard agent"><span class="fn">%s</span></span>\n',
						n, args['p' .. k])
				else
					list1 = list1 .. string.format(
						'*<span class="vcard agent"><span class="fn">%s</span></span>\n', args['p' .. k])
				end
			end
		end
		if args['coach'] and args['coach'] ~= '' then
			list1 = list1 .. string.format(
				'*<span class="vcard agent"><small class="role nowrap">%s:</small>&nbsp;<span class="fn">%s</span></span>',
				coach_label, args['coach'])
		end
	end
	local list3 = args.note and ('<small>' .. args.note .. '</small>') or nil
	
	return require('Module:Navbox')._navbox({
		name = name ~= '' and name or nil,
		titlestyle = titlestyle, 
		listclass = 'hlist', bodyclass = 'vcard', titleclass = 'fn org',
		image = image, title = title, list1 = list1, list3 = list3
	}) .. tracking .. preview
end

return p