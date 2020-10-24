-- This module implements {{Episode table}} and {{Episode table/part}}.

local HTMLcolor = mw.loadData( 'Module:Color contrast/colors' )

--------------------------------------------------------------------------------
-- EpisodeTable class
-- The main class.
--------------------------------------------------------------------------------

local contrast_ratio = require('Module:Color contrast')._ratio
local EpisodeTable = {}

function EpisodeTable.cell(background, width, text, reference)
	local cell = mw.html.create('th')
	
	-- Width
	local cell_width
	if width == 'auto' then
		cell_width = 'auto'
	elseif tonumber(width) ~= nil then
		cell_width = width .. '%'
	else
		cell_width = nil
	end
	
	-- Cell
	cell:attr('scope','col')
		:css('background',background or '#CCCCFF')
		:css('width',cell_width)
		:wikitext(text)
	
	-- Reference
	if reference and reference ~= '' then
		cell:wikitext("&#8202;" .. EpisodeTable.reference(reference, background))
	end
	
	return cell
end

function EpisodeTable.reference(reference, background)
	local link1_cr = contrast_ratio{'#0645AD', background or '#CCCCFF', ['error'] = 0}
	local link2_cr = contrast_ratio{'#0B0080', background or '#CCCCFF', ['error'] = 0}
	
	local refspan = mw.html.create('span')
		:wikitext(reference)
	
	if link1_cr < 7 or link2_cr < 7 then
		refspan
			:css('background-color','white')
			:css('padding','1px')
			:css('display','inline-block')
			:css('line-height','50%')
	end
	
	return tostring(refspan)
end

function EpisodeTable.abbr(text,title)
	local abbr = mw.html.create('abbr')
		:attr('title',title)
		:wikitext(text)
	return tostring(abbr)
end

function EpisodeTable.part(frame,args)
	local row = mw.html.create('tr')
	
	local black_cr = contrast_ratio{args.c, 'black', ['error'] = 0}
	local white_cr = contrast_ratio{'white', args.c, ['error'] = 0}
	
	local displaytext = (not args.nopart and 'Part ' or '') .. (args.p or '')
	
	local plainText = require('Module:Plain text')._main
	local displayTextAnchor = plainText(displaytext)
	
	row:tag('td')
		:attr('colspan', 13)
		:attr('id', displayTextAnchor)
		:css('text-align', 'center')
		:css('background-color', args.c)
		:css('color', black_cr > white_cr and 'black' or 'white')
		:wikitext("'''" .. displaytext .. "'''" .. (args.r and "&#8202;" .. EpisodeTable.reference(args.r, args.c) or ''))
	
	return tostring(row)
end

function EpisodeTable.new(frame,args)
	args = args or {}
	local categories = ''
	local background = (args.background and args.background ~= '' and args.background ~= '#') and args.background or nil
	
	-- Add # to background if necessary
	if background ~= nil and HTMLcolor[background] == nil then
		background = '#'..(mw.ustring.match(background, '^[%s#]*([a-fA-F0-9]*)[%s]*$') or '')
	end
	
	-- Default widths noted by local consensus
	local defaultwidths = {};
	defaultwidths.overall = 5;
	defaultwidths.season = 5;
	defaultwidths.series = 5;
	defaultwidths.prodcode = 7;
	defaultwidths.viewers = 10;
	
	-- Create episode table
	local root = mw.html.create('table')
	
	-- Table width
	local table_width = string.gsub(args.total_width or '','%%','')
	if args.total_width == 'auto' or args.total_width == '' then
		table_width = 'auto'
	elseif tonumber(table_width) ~= nil then
		table_width = table_width .. '%'
	else
		table_width = '100%'
	end
	
	root
		:addClass('wikitable')
		:addClass('plainrowheaders')
		:addClass('wikiepisodetable')
		:css('width', table_width)
	
	-- Caption
	if args.show_caption then
		-- Visible caption option, with a tracking category
		root:tag('caption'):wikitext(args.caption)
		categories = categories .. '[[Category:Articles using Template:Episode table with a visible caption]]'
	elseif args.caption then
		-- If a visible caption isn't defined, then default to the screenreader-only caption
		root:tag('caption'):wikitext(frame:expandTemplate{title='sronly',args={args.caption}})
	end
	
	-- Colour contrast; add to category only if it's in the mainspace
	local title = mw.title.getCurrentTitle()
	local black_cr = contrast_ratio{background, 'black', ['error'] = 0}
	local white_cr = contrast_ratio{'white', background, ['error'] = 0}
	
	if title.namespace == 0 and (args.background and args.background ~= '' and args.background ~= '#') and black_cr < 7 and white_cr < 7 then
		categories = categories .. '[[Category:Articles using Template:Episode table with invalid colour combination]]' 
	end
	
	-- Main row
	local mainRow = root:tag('tr')
	mainRow
		:css('color', background and (black_cr > white_cr and 'black' or 'white') or 'black')
		:css('text-align', 'center')
	
	-- Cells
	do
		local used_season = false
		local country = args.country ~= '' and args.country ~= nil
		local viewers = (country and args.country or '') .. ' ' .. (country and 'v' or 'V') .. 'iewers' ..
			((not args.viewers_type or args.viewers_type ~= '') and '<br />(' .. (args.viewers_type or 'millions') .. ')' or '')
		
		local cellNames = {
			{'overall','EpisodeNumber',EpisodeTable.abbr('No.','Number') ..
				((args.season or args.series or args.EpisodeNumber2 or args.EpisodeNumber2Series or args.forceoverall) and '<br />overall' or '')},
			{'season','EpisodeNumber2',EpisodeTable.abbr('No.','Number') .. ' in<br />season'},
			{'series','EpisodeNumber2Series',EpisodeTable.abbr('No.','Number') .. ' in<br />series'},
			{'title','Title','Title'},
			{'aux1','Aux1',''},
			{'director','DirectedBy','Directed by'},
			{'writer','WrittenBy','Written by'},
			{'aux2','Aux2',''},
			{'aux3','Aux3',''},
			{'airdate','OriginalAirDate','Original ' .. (args.released and 'release' or 'air') .. ' date'},
			{'altdate','AltDate',''},
			{'guests','Guests','Guest(s)'},
			{'musicalguests','MusicalGuests','Musical/entertainment guest(s)'},
			{'prodcode','ProdCode',EpisodeTable.abbr('Prod.','Production') .. '<br />code'},
			{'viewers','Viewers',viewers},
			{'aux4','Aux4',''}
		}
	
		for k,v in pairs(cellNames) do
			local thisCell = args[v[1]] or args[v[2]]
			if thisCell and (v[1] ~= 'series' or (v[1] == 'series' and used_season == false)) then
				if v[1] == 'season' then used_season = true end
				if (k <= 3 and thisCell == '') then thisCell = '5' end
				if (thisCell == '' and defaultwidths[v[1]]) then thisCell = defaultwidths[v[1]] end
				
				local thisCellT = args[v[1] .. 'T'] or args[v[2] .. 'T']
				local thisCellR = args[v[1] .. 'R'] or args[v[2] .. 'R']
				mainRow:node(EpisodeTable.cell(background, thisCell, thisCellT or v[3], thisCellR))
			end
		end
	
		-- Episodes
		if args.episodes then
			if args.anchor then 
				args.episodes = string.gsub(args.episodes, "(id=\")(ep%w+\")", "%1" .. args.anchor .. "%2")
			end
			
			root:node(args.episodes)
		end
	end
	
	return (args.dontclose and mw.ustring.gsub(tostring(root), "</table>", "") or tostring(root)) .. categories
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		removeBlanks = false,
		wrappers = 'Template:Episode table'
	})
	return EpisodeTable.new(frame,args)
end

function p.part(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		removeBlanks = false,
		wrappers = 'Template:Episode table/part'
	})
	return EpisodeTable.part(frame,args)
end

function p.ref(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		removeBlanks = false,
	})
	return EpisodeTable.reference(args.r,args.b)
end

return p