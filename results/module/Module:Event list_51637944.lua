-- this module implements [[Template:Event list]]
local p = {}

local mArguments = require('Module:Arguments')

function p.main(frame)
	local args = mArguments.getArgs(frame)
	
	local title = args['title'] or 'Chronology of events for ' .. mw.title.getCurrentTitle().text
	local cols = tonumber(args['columns'] or '2') or 2
	local datewidth = args['datewidth'] or '-1'
	local datealign = args['datealign'] or ''
	local collapse = args['collapse'] or 'collapsed'

	-- append the suffix to the date width or set to auto
	if (tonumber(datewidth) or -1) >= 0 then
		datewidth = tonumber(datewidth) .. '%'
	else
		datewidth = 'auto'
	end
	
	-- build a list of event parameter numbers
	eventnums = {}
	for k,v in pairs(args) do
		local i = tonumber(tostring(k):match( '^%s*date([%d]+)%s*$' ) or '-1')
		if i ~= -1 then
			table.insert(eventnums, i)
		else
			i = tonumber(tostring(k):match( '^%s*event([%d]+)%s*$' ) or '-1')
			if i ~= -1 then
				table.insert(eventnums, i)
			else
				i = tonumber(k) or -1
				if i ~= -1 then
					table.insert(eventnums, math.floor((i+1)/2) )
				end
			end
		end
	end

	-- sort to process in order
	table.sort( eventnums )
	
	-- remove duplicates
	for k = 2,#eventnums do
		if eventnums[k] == eventnums[k-1] then
			table.remove(eventnums, k)
		end
	end

	-- create the root table
	local root = mw.html.create('table')
	root:addClass('wikitable')
		:addClass('collapsible')
		:addClass(collapse)
		:css('width', '100%')
	-- Add the title
	root:tag('tr'):tag('th'):attr('colspan', cols):wikitext(title)
	-- Create the row to hold the columns
	local outerrow = root:tag('tr'):css('vertical-align', 'top')
	local percol = math.ceil((#eventnums) / cols)
	k = 0
	for i = 1,cols do
		local outercell = outerrow:tag('td'):css('width', (math.floor(10/cols)/10) .. '%')
		local innertable = outercell:tag('table')
			:css('width', '100%')
			:css('border', 'none')
			:css('cellspacing', '-1px')
			:css('cellpadding', '0px')
			:css('margin', '-1px')
			:css('font-size', '88%')
			:css('line-height', '100%')
		local tr = innertable:tag('tr'):css('vertical-align', 'top')
		tr:tag('th')
			:attr('scope', 'col')
			:css('width', datewidth)
			:css('text-align', (datealign ~= '') and datealign or 'left')
			:css('border-bottom', '1px #aaa solid')
			:wikitext('Date')
		tr:tag('th')
			:attr('scope', 'col')
			:css('text-align', 'left')
			:css('border-bottom', '1px #aaa solid')
			:wikitext('Event description')
		for j=1,percol do
			k = k + 1
			if k <= #eventnums then
				local n = tonumber(eventnums[k])
				local d = (args['date' .. n] or '') .. (args[2*(n-1)+1] or '')
				local e = (args['event' .. n] or '') .. (args[2*(n-1)+2] or '')
				if d ~= '' or e ~= '' then
					tr = innertable:tag('tr'):css('vertical-align', 'top')
					tr:tag('td'):css('text-align',(datealign ~= '') and datealign or nil):wikitext(d)
					tr:tag('td'):wikitext(e)
				end
			end
		end
	end

	return tostring(root)
end

return p