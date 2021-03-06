-- Module to build results cross-tables for standings in Sports
-- See documentation for details

require('Module:No globals')

local p = {}

-- Main function
function p.main(frame)
	-- Get the args, stripping out blank values
	local getArgs = require('Module:Arguments').getArgs
	local Args = getArgs(frame, {parentFirst = true})

	-- Exit early if we are using section transclusion for a different section
	if (Args['transcludesection'] and Args['section'])
		and Args['transcludesection'] ~= Args['section'] then
		return ''
	end

	-- Declare locals
	local t = {}
	local t_footer = {}
	local t_return = {}
	local team_list = {}
	local notes_exist = false
	local ii, ii_fw, bg_col, team_name, team_code_ii, ii_start, ii_end
	-- Optional custom team header
	local team_header = Args['team_header'] or 'Home \\ Away'
	-- Number of legs
	local legs = tonumber(Args['legs']) or 1
	local multirowlegs = (Args['multirowlegs'] or 'no') ~= 'no'
	
	-- Edit links if requested
	local baselink = frame:getParent():getTitle()
	if mw.title.getCurrentTitle().text == baselink then	baselink = '' end
	local template_name = Args['template_name']
		or (baselink ~= '' and (':' .. baselink))
		or ''
	local edit_links = template_name == '' and ''
		or frame:expandTemplate{ title = 'navbar',
			args = { mini=1, style='float:right', template_name} }
		
	-- Get the custom start point for the table (most will start by default at 1)
	local top_pos = tonumber(Args['highest_pos']) or 1
	-- Get the custom end point for the table (unrestricted if bottom_pos is < top_pos)
	local bottom_pos = tonumber(Args['lowest_pos']) or 0
	local N_teams = top_pos - 1 -- Default to 0 at start, but higher number needed to skip certain entries

	-- Load some other modules
	local p_sub = require('Module:Sports table/sub')
	
	-- Alternative syntax for team list
	if Args['team_order'] and Args['team_order'] ~= '' then
		local tlist = mw.text.split(Args['team_order'], '%s*[;,]%s*')
		for k, tname in ipairs(tlist) do
			if tname ~= '' then
				Args['team' .. k] = tname
			end
		end
	end
	
	if Args['team_header_note'] then
		notes_exist=true
		local note_string = frame:expandTemplate{ title = 'efn',
								args = { group='lower-alpha', Args['team_header_note']} }
		team_header = team_header .. note_string
	end

	-- Read in number of consecutive teams (ignore entries after skipping a spot)
	ii_start = N_teams
	while Args['team'..N_teams+1] ~= nil and (bottom_pos < top_pos or N_teams < bottom_pos) do
		N_teams = N_teams+1
		-- Sneakily add it twice to the team_list parameter, once for the actual
		-- ranking, the second for position lookup in sub-tables
		-- This is possible because Lua allows both numbers and strings as indices.
		team_list[N_teams] = Args['team'..N_teams] -- i^th entry is team X
		team_list[Args['team'..N_teams]] = N_teams -- team X entry is position i
	end
	ii_end = N_teams
	-- Get team to show
	local ii_show = team_list[Args['showteam']] -- nil if non-existant

	-- Set the font size
	local font_size=Args['font_size'] or '100%'

	-- Create header
	-- Open table
	table.insert(t,'{|class="wikitable plainrowheaders" style="text-align:center;font-size:'..font_size..';"\n')
	-- Table title
	if Args['title'] then
		table.insert(t,'|+ ' .. Args['title'] .. '\n')
	end
	-- First column
	t_return.count = 0 			-- Dummy parameter, using subfunction call seems best at this point because both module are intertwined
	t_return.tab_text = t		-- Actual text
	t_return = p_sub.colhead(t_return,'auto', edit_links .. ' ' .. team_header)
	-- Other columns passed to subfunction
	t_return = p.header(t_return,Args,p_sub,N_teams,team_list,legs,multirowlegs)
	t = t_return.tab_text

	-- Random value used for uniqueness
	math.randomseed( os.clock() * 10^8 )
	local rand_val = math.random()

	local note_string, note_id
	local note_id_list = {}

	-- Now create individual rows
	ii_start = tonumber(Args['highest_row']) and (tonumber(Args['highest_row']) > top_pos) and tonumber(Args['highest_row']) or top_pos
	ii_end = tonumber(Args['lowest_row']) and (tonumber(Args['lowest_row']) < N_teams) and tonumber(Args['lowest_row']) or N_teams
	for ii=ii_start,ii_end do
		-- Get team info
		team_code_ii = team_list[ii]
		team_name = Args['name_'..team_code_ii] or team_code_ii
		local ii_style = 'text-align:' .. (Args['team_align'] or 'right') .. ';'
			.. (ii and ii == ii_show and 'font-weight:bold;' or '')
			.. (Args['team_nowrap'] and 'white-space:nowrap;' or '')
		local team_note = Args['note_'..team_code_ii]
		if team_note then
			notes_exist = true
			-- Only when it exist
			-- First check for existence of reference for note
			if not Args['note_'..team_note] then
				-- It's the entry
				-- Add random end for unique ID if more tables are present on article (which might otherwise share an ID)
				note_id = '"table_note_'..team_code_ii..rand_val..'"'
				note_id_list[team_code_ii] = note_id
				note_string = frame:expandTemplate{ title = 'efn',
					args = { group='lower-alpha', name=note_id,  team_note} }
			else
				-- Check for existence elsewhere
				local note_local_num = team_list[team_note] or ii_end + 1
				if note_id_list[team_note] or ((note_local_num >= ii_start) and (note_local_num <= ii_end)) then
					-- It exists
					note_id = '"table_note_'..team_note..rand_val..'"' -- Identifier
					note_string = frame:extensionTag{ name = 'ref',
						args = { group = 'lower-alpha', name = note_id} }
				else
					-- Now define the identifier for this
					-- Add random end for unique ID
					note_id = '"table_note_'..team_note..rand_val..'"'
					note_id_list[team_note] = note_id
					-- Call refn template
					note_string = frame:expandTemplate{ title = 'efn',
						args = { group='lower-alpha', name=note_id, Args['note_'..team_note]} }
				end
			end
			-- Now append this to the team_name string
			team_name = team_name..note_string
		end
		-- Team names
		table.insert(t,'|- \n')  -- New row
		table.insert(t,'! scope="row"'.. (multirowlegs and ' rowspan=' .. legs or '') 
			.. 'style="'.. ii_style ..'"| '..team_name..'\n')  -- Position number

		-- Now include note to match results if needed
		for jj=top_pos,N_teams do
			local team_code_jj = team_list[jj]
			if ii == jj then
				-- Nothing
			else
				for l=1,legs do
					local m = (legs == 1) and 'match_' or 'match' .. l .. '_'
					local match_note = Args[m ..team_code_ii..'_'..team_code_jj..'_note']
					if match_note then
						notes_exist = true
						-- Only when it exist
						-- First check for existence of reference for note
						if not (Args['note_'..match_note] or Args[m ..match_note..'_note']) then
							-- It's the entry
							-- Add random end for unique ID if more tables are present on article (which might otherwise share an ID)
							note_id = '"table_note_'..team_code_ii..'_'..team_code_jj..rand_val..'"'
							note_id_list[team_code_ii..'_'..team_code_jj] = note_id
							note_string = frame:expandTemplate{ title = 'efn',
								args = { group='lower-alpha', name=note_id,  match_note} }
						else
							-- Check for existence elsewhere
							local note_local_num = team_list[match_note] or ii_end + 1
							if note_id_list[match_note] or ((note_local_num >= ii_start) and (note_local_num <= ii_end)) then
								-- It exists
								note_id = '"table_note_'..match_note..rand_val..'"' -- Identifier
								note_string = frame:extensionTag{ name = 'ref',
									args = { group = 'lower-alpha', name = note_id} }
							else
								-- Now define the identifier for this
								-- Add random end for unique ID
								note_id = '"table_note_'..match_note..rand_val..'"'
								note_id_list[match_note] = note_id
								-- Call refn template
								note_string = frame:expandTemplate{ title = 'efn',
									args = { group='lower-alpha', name=note_id, Args['note_'..match_note]} }
							end
						end
						-- Now append this to the match result string
						Args[m..team_code_ii..'_'..team_code_jj] = (Args[m..team_code_ii..'_'..team_code_jj] or '–')..note_string
					end
				end
			end
		end
		-- Then individual results
		t = p.row(t,Args,N_teams,team_list,ii,ii_show,legs,multirowlegs)
	end

	-- Close table
	table.insert(t, '|}\n')

	-- Get info for footer
	local update = Args['update']
		or 'unknown'
	local start_date = Args['start_date']
		or 'unknown'
	local source = Args['source']
		or frame:expandTemplate{ title = 'citation needed',
			args = { reason='No source parameter defined', date=os.date('%B %Y') } }

	-- Create footer text
	-- Date updating
	if string.lower(update)=='complete' then
		-- Do nothing
	elseif update=='' then
		-- Empty parameter
		table.insert(t_footer,'Updated to match(es) played on unknown. ')
	elseif string.lower(update)=='future' then
		-- Future start date
		table.insert(t_footer,'First match(es) will be played on '..start_date..'. ')
	else
		table.insert(t_footer,'Updated to match(es) played on '..update..'. ')
	end
	table.insert(t_footer,'Source: '..source)
	if (Args['matches_style'] or '') == 'FBR' then
		table.insert(t_footer, Args['team_header']
			and '<br />Legend: Blue = left column team win; Yellow = draw; Red = top row team win.'
			or '<br />Legend: Blue = home team win; Yellow = draw; Red = away team win.')
	elseif (Args['matches_style'] or '') == 'BSR' then
		table.insert(t_footer, Args['team_header']
			and '<br />Legend: Blue = left column team win; Red = top row team win.'
			or '<br />Legend: Blue = home team win; Red = away team win.')
	end
	if Args['a_note'] then
		table.insert(t_footer, '<br />For upcoming matches, an "a" indicates there is an article about the rivalry between the two participants.')
	end
	if Args['ot_note'] then
		table.insert(t_footer, '<br />Matches with lighter background shading were decided after overtime.')
	end

	-- Add notes (if applicable)
	if notes_exist then
		table.insert(t_footer,'<br>Notes:')
		-- As reflist size text
		t_footer = '<div class="reflist">'..table.concat(t_footer)..'</div>'
		t_footer = t_footer..frame:expandTemplate{ title = 'notelist', args = { group='lower-alpha'} }
	else
		-- As reflist size text
		t_footer = '<div class="reflist">'..table.concat(t_footer)..'</div>'
	end

	-- Add footer to main text table
	table.insert(t,t_footer)
	
	-- Rewrite anchor links
	for k=1,#t do
		if t[k]:match('%[%[#[^%[%]]*%|') then
			t[k] = mw.ustring.gsub(t[k], '(%[%[)(#[^%[%]]*%|)', '%1' .. baselink .. '%2')
		end
	end
	
	return '<div style="overflow:hidden">'
		.. '<div class="noresize overflowbugx" style="overflow:auto">\n'
		.. table.concat(t) .. '</div></div>'
end

-- Other functions
local function get_short_name(s, t, n, ss)
	-- return short name if defined
	if s and s ~= '' then
		return s
	end
	-- deflag if necessary
	if ss and n then
		if ss == 'noflag' then
			n = mw.ustring.gsub(n, '%[%[[Ff][Ii][Ll][Ee]:[^%[%]]*%]%]', '')
		elseif ss == 'flag' then
			n = mw.ustring.gsub(n, '(<span class="flagicon">%s*%[%[[Ff][Ii][Ll][Ee]:[^%[%]]*link=)[^%|%[%]]*(%]%][^<>]*</span>)%s*%[%[([^%[%]%|]*)%|[^%[%]]*%]%]', '%1%3%2')
			n = mw.ustring.gsub(n, '.*(<span class="flagicon">%s*%[%[[Ff][Ii][Ll][Ee]:[^%[%]]*%]%][^<>]*</span>).*', '%1')
			n = mw.ustring.gsub(n, '&nbsp;(</span>)', '%1')
		end
	end
	
	-- replace link text in name with team abbr if possible
	if n and t and n:match('(%[%[[^%[%]]*%]%])') then
		n = mw.ustring.gsub(n, '(%[%[[^%|%]]*%|)[^%|%]]*(%]%])', '%1' .. t .. '%2')
		n = mw.ustring.gsub(n, '(%[%[[^%|%]]*)(%]%])', '%1|' .. t .. '%2')
		n = mw.ustring.gsub(n, '(%[%[[^%|%]]*%|)([A-Z][A-Z][A-Z])(%]%])&nbsp;<span[^<>]*>%([A-Z][A-Z][A-Z]%)</span>', '%1%2%3')
		return n
	end
	-- nothing worked, so just return the unlinked team abbr
	return t or ''
end

local function get_score_background(s, c)
	local s1, s2
	-- Define the colouring
	local wc, lc, tc
	if c == 'level2' then
	wc, lc, tc = '#CCF9FF', '#FCC', '#FFC' -- blue2, red2, yellow2
	elseif c == 'level3' then
	wc, lc, tc = '#DDFCFF', '#FDD', '#FFD' -- blue3, red3, yellow3
	elseif c == 'level4' then
	wc, lc, tc = '#EEFFFF', '#FEE', '#FFE' -- blue4, red4, yellow4
	else
	wc, lc, tc = '#BBF3FF', '#FBB', '#FFB' -- blue1, red1, yellow1
	end

	-- check for override
	if s:match('^%s*<span%s%s*style%s*=["\'%s]*background[%-colr]*%s*:([^\'";<>]*).-$') then
		local c = mw.ustring.gsub(s,'^%s*<span%s%s*style%s*=["\'%s]*background[%-colr]*%s*:([^\'";<>]*).-$', '%1')
		return c
	end
	
	-- delink if necessary
	if s:match('^%s*%[%[[^%[%]]*%|([^%[%]]*)%]%]') then
		s = s:match('^%s*%[%[[^%[%]]*%|([^%[%]]*)%]%]')
	end
	if s:match('^%s*%[[^%[%]%s]*%s([^%[%]]*)%]') then
		s = s:match('^%s*%[[^%[%]%s]*%s([^%[%]]*)%]')
	end
	if s:match('<span[^<>]*>(.-)</span>') then
		s = s:match('<span[^<>]*>(.-)</span>')
	end

	-- get the scores
	s1 = tonumber(mw.ustring.gsub( s or '',
		'^%s*([%d%.][%d%.]*)%s*–%s*([%d%.][%d%.]*).*', '%1' ) or '') or ''
	s2 = tonumber(mw.ustring.gsub( s or '',
		'^%s*([%d%.][%d%.]*)%s*–%s*([%d%.][%d%.]*).*', '%2' ) or '') or ''

	-- return colouring if possible
	if s1 ~= '' and s2 ~= '' then
		return (s1 > s2) and wc or ((s2 > s1) and lc or tc)
	else
		return 'transparent'
	end
end

local function format_score(s)
	s = mw.ustring.gsub(s or '', '^%s*([%d%.]+)%s*[–−—%-]%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*([%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[%[[^%[%]]*%|[%d%.]+)%s*%-%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[[^%[%]%s]*%s+[%d%.]+)%s*%-%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[%[[^%[%]]*%|[%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	s = mw.ustring.gsub(s, '^%s*(%[[^%[%]%s]*%s+[%d%.]+)%s*&[MmNn][Dd][Aa][Ss][Hh];%s*([%d%.]+)', '%1–%2')
	return s
end

function p.header(tt,Args,p_sub,N_teams,team_list,legs,multirowlegs)
	local ii, team_code_ii, short_name
	legs = legs or 1

	-- Set match column width
	local col_width = Args['match_col_width'] or '28'

	-- Get some default values in case it doesn't start at 1
	local top_pos = tonumber(Args['highest_pos']) or 1

	for l=1,legs do
		if multirowlegs and l > 1 then
			break
		end
		for ii=top_pos,N_teams do
			team_code_ii = team_list[ii]
			short_name = get_short_name(Args['short_'..team_code_ii],
				team_code_ii, Args['name_'..team_code_ii], Args['short_style'] or '')
			local bl = legs > 1 and ii == top_pos and ' style="border-left:2px solid #aaa;"' or ''
			tt = p_sub.colhead(tt,col_width .. bl,short_name)
		end
	end
	return tt
end

function p.row(tt,Args,N_teams,team_list,ii,ii_show,legs,multirowlegs)
	-- Note ii is the row number being shown
	local jj, fw, bg, result, result_extra, team_code_ii, team_code_jj
	legs = legs or 1

	-- Set score cell style
	local matches_style = Args['matches_style'] or ''

	team_code_ii = team_list[ii]

	-- Get some default values in case it doesn't start at 1
	local top_pos = tonumber(Args['highest_pos']) or 1
	for l=1,legs do
		if multirowlegs and l > 1 then
			table.insert(tt,'|- \n')  -- New row
		end
		for jj=top_pos,N_teams do
			team_code_jj = team_list[jj]
			local m = (legs == 1) and 'match_' or 'match' .. l .. '_'
			result = Args[m..team_code_ii..'_'..team_code_jj] or ''
			result_extra = Args['result_'..team_code_ii..'_'..team_code_jj] or ''
			local bl = legs > 1 and jj == top_pos and 'border-left:2px solid #aaa;' or ''

			if ii == jj or result == 'null' then
				-- Solid cell
				fw = 'font-weight:' .. (ii==ii_show and 'bold' or 'normal') .. ';'
				bg = 'background:transparent;'

				-- Grey background color for solid cell
				if Args['solid_cell'] == 'grey' then
					table.insert(tt,'| style="'..fw..bl..'background:#bbb;" |\n')
				else
					table.insert(tt,'| style="'..fw..bl..bg..'" | &mdash;\n')
				end
			else
				-- Content cell
				-- Set bolding and background
				fw = 'font-weight:' .. ((ii==ii_show or jj == ii_show) and 'bold' or 'normal') .. ';'
				bg = 'background:transparent;'

				-- Reformat dashes
				if result ~= '' then
					result = format_score(result)
				end
				-- Background coloring if enabled
				if matches_style == 'FBR' and result ~= '' then
					if result_extra == 'OT' then
						bg = 'background:' .. get_score_background(result,'level2') .. ';'
					elseif result_extra == 'PK' then
						bg = 'background:' .. get_score_background(result,'level3') .. ';'
					else
						bg = 'background:' .. get_score_background(result,'') .. ';'
					end
				elseif matches_style == 'BSR' and result ~= '' then
					if result_extra == 'OT' then
						bg = 'background:' .. get_score_background(result,'level3') .. ';'
					elseif result_extra == 'OTL' then
						bg = 'background:' .. get_score_background('0–1','level3') .. ';'
					elseif result_extra == 'OTW' then
						bg = 'background:' .. get_score_background('1–0','level3') .. ';'
					elseif result_extra == 'L' then
						bg = 'background:' .. get_score_background('0–1','') .. ';'
					elseif result_extra == 'W' then
						bg = 'background:' .. get_score_background('1–0','') .. ';'
					else
						bg = 'background:' .. get_score_background(result,'') .. ';'
					end
				end
				table.insert(tt,'| style="white-space:nowrap;'..fw..bl..bg..'" |'..result..'\n')
			end
		end
	end
	
	return tt
end

return p