local p = {}

local getArgs

local function showUserbox(frame, v, nocat)
	local maybeNocat = ''
	if nocat then
		maybeNocat = '|nocat=yes'
	end
	return frame:preprocess('{{User '..v..maybeNocat..'}}')
end

function p.main(frame)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end
	local args = getArgs(frame, {wrappers = 'Template:Babel'})

	local ret = mw.html.create('table')
				:addClass('userboxes')
				:css( {
						float = args.align or 'right',
						['margin-left'] = (args.left or '1') .. 'em',
						['margin-bottom'] = (args.bottom or '0') .. 'em',
						width = (args.width or '248') .. 'px',
						clear = args.align or 'right',
						color = args.textcolor or '#000000',
						border = (args.bordercolor or '#99B3FF') .. ' solid ' .. (args.solid or 1)..'px'
					} )

	local nocat = args.nocat and string.lower(args.nocat) == 'yes'

	if args.shadow and string.lower(args.shadow) == 'yes' then
		ret:css({ ['box-shadow'] = '0 2px 4px rgb(0,0,0,0.2)',
						['-mox-box-shadow'] = '0 2px 4px rgb(0,0,0,0.2)',
						['-webkit-box-shadow'] = '0 2px 4px rgb(0,0,0,0.2)' })
	end

	ret:cssText( args['extra-css'] or '' )

	local color = args.color or 'inherit'
	local row1 = ret:tag('tr')
	local row2 = ret:tag('tr')
	local row3 = ret:tag('tr')

	local body_cells = row2:tag('td')
				:css('vertical-align', 'middle !important')

	local userboxes
	-- Special message for when first argument is blank; otherwise treat it as normal
	if args[1] and args[1]:find('%S') then
		userboxes = showUserbox(frame, args[1], nocat)
	else
		userboxes = args.noboxestext or "''You haven't set up any languages. Please see [[Template:Babel/doc]] for help.''"
	end

	body_cells:wikitext(userboxes)

	-- "remove" args[1] so it isn't looked at in the loop
	-- table.remove(args,1) doesn't produce desired result
	args[1] = ''

	-- Keep track of how many columns are in this table
	local col_span = 1
	for _, v in ipairs( args ) do
		-- ! indicates a new cell should be created
		if v:find('%S') and v ~= '!' then
			body_cells:wikitext( showUserbox(frame, v, nocat) )
		-- Recycling body_cells for <td>
		elseif v and v == '!' then
			col_span = col_span + 1
			body_cells:done()
			body_cells = row2:tag('td')
		end
	end

	row1:tag('th')
			:css({ ['background-color'] = color,
					['text-align'] = 'center' })
			:attr('colspan',col_span)
			:wikitext( args.header or '[[Wikipedia:Babel]]' )
			:done()

	row3:tag('td')
			:css({ ['background-color'] = color,
					['text-align'] = 'center' })
			:attr('colspan',col_span)
			:wikitext( args.footer or '[[:Category:Wikipedians by language|Search user languages]]' )
			:done()

	if args['special-boxes'] then
		body_cells:wikitext(args['special-boxes'])
	end

	body_cells:done()

	return tostring(ret)
end

return p