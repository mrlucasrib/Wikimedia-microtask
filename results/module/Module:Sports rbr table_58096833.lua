-- This module implements {{Sports rbr table}}
local p = {}

-- Internationalisation
local labels = {
	teamround = 'Team ╲ Round',
	source = 'Source:',
	notes = 'Notes:',
	matches = 'match(es)',
	updatedto = 'Updated to <matches> played on <date>.',
	firstplayed = 'First <matches> will be played on <date>.',
	futuredate = '?',
	complete = 'complete',
	future = 'future'
}

local modname = 'Module:Sports rbr table'
local templatestyles = 'Module:Sports rbr table/styles.css'

local args = nil

local preview, tracking = '', ''
local hasnotes = false

local colorlist = {}
local textlist = {}

local color_map = {
		green1='#BBF3BB', green2='#CCF9CC', green3='#DDFCDD', green4='#EEFFEE',
		blue1='#BBF3FF', blue2='#CCF9FF', blue3='#DDFCFF', blue4='#EEFFFF',
		yellow1='#FFFFBB', yellow2='#FFFFCC', yellow3='#FFFFDD', yellow4='#FFFFEE',
		red1='#FFBBBB', red2='#FFCCCC', red3='#FFDDDD', red4='#FFEEEE',
		black1='#BBBBBB', black2='#CCCCCC', black3='#DDDDDD', black4='#EEEEEE',
		['1st']='#FFD700', ['2nd']='#C0C0C0', ['3rd']='#CC9966'
	}

local legend_symbols = {O='W/O'}

local legend_order_default = {'A', 'H', 'N', 'B', 'W', 'D', 'L', 'Ab', 'P', 'O'}

local function isnotempty(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function zeropad(n)
	if n>=0 and n < 10 then
		return '00' .. n
	end
	if n>=0 and n < 100 then
		return '0' .. n
	end
	return '' .. n
end

local function pad_key(k)
	-- Zero pad, fix ranges and dashes
	if k then
		k = k .. ' '
		k = mw.ustring.gsub(k, '–', '-')
		k = mw.ustring.gsub(k, '_([%d][^%d])', '_0%1')
		k = mw.ustring.gsub(k, '%-([%d][^%d])', '-0%1')
		k = mw.ustring.gsub(k, '_([%d][%d][^%d])', '_0%1')
		k = mw.ustring.gsub(k, '%-([%d][%d][^%d])', '-0%1')
		k = mw.ustring.gsub(k, '([^%d])%-([%d])', '%1000-%2')
		k = mw.ustring.gsub(k, '([%d])%-%s*$', '%1-999')
		k = mw.ustring.gsub(k, '^%s*(.-)%s*$', '%1')
	end

	return k
end

local function matches_date(text, m, d)
	return mw.ustring.gsub(mw.ustring.gsub(text .. '', '<matches>', m), '<date>', d)
end

local function escapetag(text)
	return mw.ustring.gsub(text, '</', '<FORWARDSLASH')
end

local function unescapetag(text)
	return mw.ustring.gsub(text, '<FORWARDSLASH', '</')
end

local function get_color(p)
	if p then
		p = mw.ustring.gsub(p, '</?[Aa][Bb][Bb][Rr][^<>]*>', '')
		p = mw.ustring.gsub(p, '<[Ss][Uu][Pp]>[^<>]*</[Ss][Uu][Pp]>', '')
		p = mw.ustring.gsub(p, '</?[Ss][^<>]*>', '')
		p = mw.ustring.gsub(p, '†%s*$', '')
		p = mw.ustring.gsub(p, '=%s*$', '')
		p = mw.ustring.gsub(p, '%[%[[^%[%]|]*|([^%[%]|]*)%]%]', '%1')
		if p:match('^%a%a*$') then
			if args['text_' .. p] == nil then
				tracking = tracking .. '[[Category:Pages using sports rbr table with an undescribed result|' 
					.. p:match('^(%a).*$') .. ']]'
			end
		end
	end
	local c = colorlist[p] or colorlist[zeropad(tonumber(p) or -1)]
	if c then
		return color_map[c] or c
	end
	p = tonumber(p or '0') or 0
	if p <= 0 then
		return nil
	end
	-- ranges in order of specificity
	local offset1, offset2 = 999, 999
	for k,v in pairs( colorlist ) do
		local r1 = tostring(k):match( '^%s*([%d]+)%-[%d]+%s*$' )
		local r2 = tostring(k):match( '^%s*[%d]+%-([%d]+)%s*$' )
		if r1 and r2 then
			r1 = tonumber(r1)
			r2 = tonumber(r2)
			if (r1 <= p) and (r2 >= p) then
				if (c == nil) or ((p - r1) <= offset1 and (r2 - p) <= offset2) then
					c = color_map[v] or v
					offset1 = p - r1
					offset2 = r2 - p
				end
			end
		end
	end
	return c
end

local function check_arg(k, st)
	k = tostring(k) or ''
	if k == 'firstround' or k == 'sortable' or k == 'updated' or k == 'update'
		or k =='source' or k =='notes' or k == 'legendpos' or k == 'date' 
		or k == 'header' or k == 'title' or k == 'start_date' or k == 'labelnowrap'
		or k == 'labelalign' or k == 'toptext' or st.addtl_args(k) then
	elseif k == 'legendorder' then
		tracking = tracking .. '[[Category:Pages using sports rbr table with legendorder]]'
	elseif tostring(k):match( '^%s*text_?(.-)%s*$' ) then
	elseif tostring(k):match( '^%s*colou?r_?(.-)%s*$' ) then
	elseif tostring(k):match( '^%s*team[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*label[%d]+%s*$' ) then
		if args['header'] then
		else
			tracking = tracking .. '[[Category:Pages using sports rbr table with unsupported parameters|ψ]]'
		end
	elseif tostring(k):match( '^%s*opp[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*pos[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*grnd[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*res[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*posc[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*grndc[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*resc[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*split[%d]+%s*$' ) then
	elseif k == 'rnd1' then
		tracking = tracking .. '[[Category:Pages using sports rbr table with rnd parameters]]'
	elseif tostring(k):match( '^%s*rnd[%d]+%s*$' ) then
	elseif tostring(k):match( '^%s*opp_' ) then
	elseif tostring(k):match( '^%s*pos_' ) then
	elseif tostring(k):match( '^%s*grnd_' ) then
	elseif tostring(k):match( '^%s*res_' ) then
	elseif tostring(k):match( '^%s*posc_' ) then
	elseif tostring(k):match( '^%s*grndc_' ) then
	elseif tostring(k):match( '^%s*resc_' ) then
	elseif tostring(k):match( '^%s*name_' ) then
	elseif tostring(k):match( '^%s*note_' ) then
	elseif tostring(k):match( '^%s*pos[%d]+_rnd[%d]+_colou?r%s*$' ) then
		tracking = tracking .. '[[Category:Pages using sports rbr table with per team and round coloring]]'
	elseif tostring(k):match( '^%s*res[%d]+_rnd[%d]+_colou?r%s*$' ) then
		tracking = tracking .. '[[Category:Pages using sports rbr table with per team and round coloring]]'
	elseif tostring(k):match( '^%s*pos[%d]+_rnd[%d]+_note%s*$' ) then
	elseif tostring(k):match( '^%s*res[%d]+_rnd[%d]+_note%s*$' ) then
	else
		local vlen = mw.ustring.len(k)
		k = mw.ustring.sub(k, 1, (vlen < 25) and vlen or 25) 
		k = mw.ustring.gsub(k, '[^%w\-_ ]', '?')
		preview = preview .. 'Unknown: "' .. k .. '"<br>'
		tracking = tracking .. '[[Category:Pages using sports rbr table with unsupported parameters|' .. k .. ']]'
	end
end

function p.table(frame)
	local getArgs = require('Module:Arguments').getArgs
	local yesno = require('Module:Yesno')
	args = getArgs(frame, {wrappers = {'Template:Sports rbr table'}})
	
	local style_def = args['style']
	local p_style = require(modname)
	if style_def ~= nil then p_style = require(modname .. '/' .. style_def) end
	
	args = p_style.defaults(args,yesno,color_map)
	
	local rounds = tonumber(args['rounds'] or '0') or 0
	local firstround = tonumber(args['firstround'] or 1) or 1
	local sortable = yesno(args['sortable'] or 'no')
	local updated = args['updated'] or args['update']
	local source = args['source']
	local notes = args['notes']
	local delimiter = args['delimiter'] or '/'
	local addlegend = nil
	local legendpos = (args['legendpos'] or 'tr'):lower()
	local header, footer, prenotes  = '', '', ''
	
	-- Lowercase two labels --
	labels['complete'] = string.lower(labels['complete'])
	labels['future'] = string.lower(labels['future'])

	-- Adjust rounds
	rounds = rounds - (firstround - 1)
	
	-- Tracking
	if updated and updated:match(' %d%d%d%d$') then
		local YY = mw.ustring.gsub(updated, '^.*(%d%d)$', '%1')
		local pn = frame:getParent():getTitle() or ''
		if pn:match('^User:') or pn:match('^User talk:') or pn:match('^Draft:') or pn:match('^Talk:') then
		else
			if pn:match('%d%d' .. YY) or pn:match('[–%-]' .. YY) then
			else
				tracking = tracking .. '[[Category:Pages using sports rbr table with dubious updated parameter]]'
			end
		end
    end
	-- Require a source
	if source == nil then
		source = frame:expandTemplate{ title = 'citation needed', args = { reason='No source parameter defined', date=args['date'] or os.date('%B %Y') } }
	elseif source and source:match('[^%[]#') then 
		if source:match('eason#') or source:match('%d%d#') then
			tracking = tracking .. '[[Category:Pages using sports rbr table with an unusual source]]'
		elseif source:match('^[Hh][Tt][Tt][Pp]') then
			tracking = tracking .. '[[Category:Pages using sports rbr table with an unusual source|Φ]]'
		end
	end
	
	-- Process team, pos, and color args
	local team_list = {}
	local maxrounds = 0
	local rowlength = {}
	for k, v in pairs( args ) do
		check_arg(k, p_style)
		-- Preprocess ranges
		if tostring(k):match( '^%s*text_?(.-)%s*$' ) then
			k = pad_key(k)
		end
		if tostring(k):match( '^%s*colou?r_?(.-)%s*$' ) then
			k = pad_key(k)
		end

		-- Create the list of teams and count rounds
		local i = tonumber(
				tostring(k):match( '^%s*team([%d]+)%s*$' ) or
				tostring(k):match( '^%s*label([%d]+)%s*$' ) or '0'
				)
		if ( i > 0 and isnotempty(v) ) then
			table.insert(team_list, i)
			local p = p_style.get_argvalues_for_maxround(args,i)
			if args['name_' .. v] then
				local t = args['team' .. i] or args['label' .. i] or ''
				p = p_style.get_argvalues_for_maxround(args,t,'_')
			end
			local pos = mw.text.split(escapetag(p), '%s*' .. delimiter .. '%s*')
			table.insert(rowlength, #pos)
			maxrounds = (#pos > maxrounds) and #pos or maxrounds
			-- maxrounds = p_style.get_maxrounds(args,team_list,i,v,rowlength,maxrounds,delimiter)
		end
		-- Create the list of colors
		local s = tostring(k):match( '^%s*colou?r_?(.-)%s*$' )
		if ( s and isnotempty(v) ) then
			colorlist[s] = v:lower()
		end
		-- Check if we are adding a legend
		s = tostring(k):match( '^%s*text_?(.-)%s*$' )
		if ( s and isnotempty(v) ) then
			textlist[s] = v
			addlegend = 1
		end
	end
	
	maxrounds = p_style.get_rounds_or_maxrounds(rounds,maxrounds,args,team_list)
	
	table.sort(rowlength)
	for k=2,#rowlength do
		if rowlength[k] ~= rowlength[k-1] then
			tracking = tracking .. '[[Category:Pages using sports rbr table with unequal row lengths|k]]'
		end
	end

	-- sort the teams
	table.sort(team_list)

	local fs = 95
	if ((maxrounds - firstround) > 37 ) then
		fs = fs - 2*(maxrounds - firstround - 37)
		fs = (fs < 80) and 80 or fs
	end

	-- Build the table
	local root = mw.html.create('table')
	root:addClass('wikitable')
	root:addClass(sortable and 'sortable' or nil)
	root:addClass('sportsrbrtable')
	root:css('font-size', fs .. '%')

	if args['title'] then
		root:tag('caption'):wikitext(args['title'])
	end

	local navbar = ''
	if args['template_name'] then
		navbar = '<br />' .. frame:expandTemplate{ title = 'navbar', args = { mini=1, style='', brackets=1, args['template_name']}}
		-- remove the next part if https://en.wikipedia.org/w/index.php?oldid=832717047#Sortable_link_disables_navbar_links?
		-- is ever fixed
		if sortable then
			navbar = mw.ustring.gsub(navbar, '<%/?abbr[^<>]*>', ' ')
		end
	end
	
	-- Heading row
	local row = p_style.header(root,args,labels,maxrounds,navbar,team_list,firstround)

	-- Team positions
	local prefixes = {'pos', 'res', 'grnd'}
	for k=1,#team_list do
		local i = team_list[k]
		local t = args['team' .. i] or args['label' .. i] or ''
		local o = args['opp' .. i] or ''
		local n = args['note' .. i] or ''
		local efnname = 'note' .. i
		local suf = i
		if args['name_' .. t] then
			o = args['opp_' .. t] or ''
			n = args['note_' .. t] or ''
			efnname = 'note' .. t
			suf = '_' .. t
			t = args['name_' .. t]
		end

		if n ~= '' then
			if args['note_' .. n] then 
				n = frame:expandTemplate{ title = 'efn', args = { name='note' .. n, ''} }
			else
				n = frame:expandTemplate{ title = 'efn', args = { name=efnname, n} }
			end
			hasnotes = true
		end
		
		local resfound = (args['grnd' .. i] and 1 or 0) + (args['pos' .. i] and 1 or 0) + (args['res' .. i] and 1 or 0)
		if args['name_' .. t] then
			resfound = (args['grnd_' .. t] and 1 or 0) + (args['pos_' .. t] and 1 or 0) + (args['res_' .. t] and 1 or 0)
		end
		if (resfound > 1) then
			tracking = tracking .. '[[Category:Pages using sports rbr table with conflicting parameters]]'
		end
		local rowsdisp = 0
		for subrow,lbl in ipairs(prefixes) do
			local p = args[lbl .. suf] or ''
			local pc = args[lbl .. 'c' .. suf] or ''
			if p ~= '' or (rowsdisp == 0 and subrow == 3) then
				rowsdisp = rowsdisp + 1
				row = root:tag('tr')
				row:tag('th')
					:addClass(args['team' .. i] and 'sportsrbrtable-team' or 'sportsrbrtable-lbl')
					:css('text-align', args['labelalign'])
					:css('white-space', args['labelnowrap'] and 'nowrap' or nil)
					:attr('scope', 'row')
					:wikitext(mw.ustring.gsub(t,'^%s*%-%s*$', '&nbsp;') .. n)
				if t:match('<%s*[Cc][Ee][Nn][Tt][Ee][Rr]%s*>') then
					tracking = tracking .. '[[Category:Pages using sports rbr table with unsupported parameters|χ]]'
				end
				local opp = mw.text.split(escapetag(o), '%s*' .. delimiter .. '%s*')
				local pos = mw.text.split(escapetag(p), '%s*' .. delimiter .. '%s*')
				local clr = mw.text.split(escapetag(pc), '%s*' .. delimiter .. '%s*')
				for r=1,maxrounds do
					local s = args['team' .. i .. '_rnd' .. r .. '_' .. 'color'] or
						args['team' .. i .. '_rnd' .. r .. '_' .. 'colour'] or
						args[lbl .. i .. '_rnd' .. r .. '_' .. 'color'] or
						args[lbl .. i .. '_rnd' .. r .. '_' .. 'colour'] or nil
					local n = args['team' .. i .. '_rnd' .. r .. '_' .. 'note'] or
						args[lbl .. i .. '_rnd' .. r .. '_' .. 'note'] or nil
					if s then s = color_map[s] or s end
					local opprt, posrt = unescapetag(opp[r] or ''), unescapetag(pos[r] or '')
					local posrc = isnotempty(clr[r]) and clr[r] or posrt

					if posrt:match('^%s*<[Uu]>[%d–]+[A-Za-z][A-Za-z0-9]*') then
						posrc = posrc:match('^%s*<[Uu]>[%d–]+([A-Za-z][A-Za-z0-9]*)')
						posrt = mw.ustring.gsub(posrt, '^%s*(<[Uu]>[%d–]+)[A-Za-z][A-Za-z0-9]*', '%1')
					elseif posrt:match('^%s*[%d–]+[A-Za-z][A-Za-z0-9]*') then
						posrc = posrc:match('^%s*[%d–]+([A-Za-z][A-Za-z0-9]*)')
						posrt = mw.ustring.gsub(posrt, '^%s*([%d–]+)[A-Za-z][A-Za-z0-9]*', '%1')
					end
			
					local ds
					if args['sortable'] and (opprt or posrt):match('^%s*[%d]+[^%d%s]') then
						ds = mw.ustring.gsub(opprt or posrt, '^%s*([%d]+)[^%d%s].*$', '%1')
					end

					if n then
						if args['note_' .. n] then
							n = frame:expandTemplate{ title = 'efn', args = { name='note' .. n, args['note_' .. n]} }
						else
							n = frame:expandTemplate{ title = 'efn', args = { name='note' .. i .. '_rnd_' .. r, n} }
						end
						hasnotes = true
					end
		
					row:tag('td')
						:attr('data-sort-value', ds)
						:css('background-color', s or get_color(p_style.rowbg(posrc, opprt)))
						:wikitext(p_style.rowtext(frame,args,legend_symbols,posrt,opprt) .. (n or ''))
				end
				if args['split' .. i] and k ~= #team_list then
					row = root:tag('tr')
						:css('background-color', '#BBBBBB')
						:css('line-height', '3pt')
					row:tag('td')
						:attr('colspan', maxrounds + 1)
				end
			end
		end
	end

	-- build the legend
	if addlegend then
		-- Sort the keys for the legend
		local legendkeys = {}
		for k,v in pairs( textlist ) do
			table.insert(legendkeys, k)
		end
		table.sort(legendkeys)

		if args['legendorder'] then
			legendkeys = mw.text.split(args['legendorder'] .. delimiter ..
				table.concat(legend_order_default, delimiter) .. delimiter ..
				table.concat(legendkeys, delimiter), '%s*' .. delimiter .. '%s*')
		else
			legendkeys = mw.text.split(
				table.concat(legend_order_default, delimiter) .. delimiter ..
				table.concat(legendkeys, delimiter), '%s*' .. delimiter .. '%s*')
		end
		local lroot
		if (legendpos == 't' or legendpos == 'b') then
			lroot = mw.html.create('')
			local firsttag = true
			for k,v in pairs( legendkeys ) do
				if v and textlist[v] then
					if firsttag == false then lroot:wikitext('; ') end
					local c = colorlist[v] or ''
					local l = lroot:tag('span')
						:css('margin', '0')
						:css('white-space', 'nowrap')
						:tag('span')
							:addClass('legend-text')
							:css('border', 'none')
							:css('padding', '1px .3em')
							:css('background-color', color_map[c] or c)
							:css('font-size', '95%')
							:css('border', '1px solid #BBB')
							:css('line-height', '1.25')
							:css('text-align', 'center')
							:wikitext(p_style.legendtext(legend_symbols,v))
							:done()
						:wikitext(' = ' .. textlist[v])
					textlist[v] = nil
					firsttag = false
				end
			end
		else
			lroot = mw.html.create('table')
			if legendpos == 'tl' or legendpos == 'bl' then
				lroot:addClass('wikitable')
				lroot:css('font-size', '88%')
			else
				lroot:addClass('infobox')
				lroot:addClass('bordered')
				-- lroot:css('width', 'auto')
			end
			for k,v in pairs( legendkeys ) do
				if v and textlist[v] then
					local c = colorlist[v] or ''
					local row = (legendpos == 'tl' or legendpos == 'bl') and lroot or lroot:tag('tr')
					local l = row:tag('th'):css('background-color', color_map[c] or c)
					if legend_symbols[v] then
						l:css('font-weight', 'normal')
							:css('padding', '1px 3px')
							:wikitext(legend_symbols[v])
					else
						l:css('width', '10px')
					end
					row:tag('td')
						:css('padding', '1px 3px')
						:wikitext(textlist[v])
					textlist[v] = nil
				end
			end
		end
		if (legendpos == 'bl' or legendpos == 'br') then
			footer = footer .. tostring(lroot)
		elseif (legendpos == 'b') then
			prenotes = prenotes .. tostring(lroot)
		elseif (legendpos == 't') then
			args['toptext'] = (args['toptext'] or '')
				.. frame:expandTemplate{ title = 'refbegin' }
				.. tostring(lroot)
				.. frame:expandTemplate{ title = 'refend' }

		else
			header = header .. tostring(lroot)
		end
	end

	-- simplify updated == complete case
	local lupdated = updated and string.lower(updated) or ''
	if lupdated == labels['complete'] or lupdated == 'complete' then
		lupdated = ''
	end

	-- add note list
	if hasnotes then
		footer = footer .. frame:expandTemplate{ title = 'notelist' }
	end
	
	-- build the footer	
	if prenotes ~= '' or notes or source or lupdated ~= '' then
		footer = footer .. frame:expandTemplate{ title = 'refbegin' }
		if lupdated ~= '' then
			local mtext = args['matches_text'] or labels['matches']
			if lupdated == labels['future'] or lupdated == 'future' then
				footer = footer .. matches_date(labels['firstplayed'] .. ' ',
					mtext, args['start_date'] or labels['futuredate'])
			else
				footer = footer .. matches_date(labels['updatedto'] .. ' ',
					mtext, updated)
			end
		end
		if source then
			footer = footer .. labels['source'] .. ' ' .. source
		end
		if prenotes ~= '' then
			if lupdated ~= '' or source then
				footer = footer .. '<br>'
			end
			footer = footer .. prenotes
		end
		if notes then
			if prenotes ~= '' or lupdated ~= '' or source then
				footer = footer .. '<br>'
			end
			footer = footer .. labels['notes'] .. ' ' .. notes
		end
		footer = footer .. frame:expandTemplate{ title = 'refend' }
	end
	-- add clear right for the legend if necessary
	footer = footer .. ((addlegend and (legendpos == 'bl' or legendpos == 'br'))
		and '<div style="clear:right"></div>' or '')
	if tracking ~= '' then
		if frame:preprocess( "{{REVISIONID}}" ) == "" then
			tracking = preview
		end
	end
	return frame:extensionTag{ name = 'templatestyles', args = { src = templatestyles} }
		.. header .. (args['toptext'] or '') .. '<div style="overflow:hidden">'
		.. '<div class="noresize overflowbugx" style="overflow:auto">'
		.. tostring(root) .. '</div></div>' .. footer .. tracking
end

function p.get_argvalues_for_maxround(args, x, del)
	del = del or ''
	return args['pos' .. del .. x] or args['res' .. del .. x] or ''
end

function p.get_rounds_or_maxrounds(rounds, maxrounds)
	return (rounds > maxrounds) and rounds or maxrounds
end

function p.addtl_args(k)
	-- just return 'true', no additional args
	return true
end

function p.defaults(args)
	-- set nothing
	return args
end

function p.header(root,args,labels,maxrounds,navbar,team_list,firstround)
	local row = root:tag('tr')
	row:tag('th')
		:attr('rowspan', args['sortable'] and 2 or nil)
		:wikitext((args['header'] or labels['teamround']) .. navbar)
	for r=1,maxrounds do
		row:tag('th')
			:addClass(args['sortable'] and 'sportsrbrtable-rnd-sort' or 'sportsrbrtable-rnd')
			:attr('scope', 'col')
			:wikitext(args['rnd' .. (r + (firstround - 1))]
				or (r + (firstround - 1)))
	end
	if args['sortable'] then
		row = root:tag('tr')
		for r=1,maxrounds do
			row:tag('th')
				:addClass('sportsrbrtable-rnd-toggle')
		end
	end
	return row
end

function p.rowtext(frame,args,legend_symbols,posrt,postrc,opprt,opprc)
	return legend_symbols[posrt] or posrt
end

function p.rowbg(posrc)
	return posrc
end

function p.legendtext(legend_symbols,v)
	return legend_symbols[v] or (v:match('^[^%d][^%d]?$') and v) or '&nbsp;'
end

return p