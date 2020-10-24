
require('Module:No globals');

--[=[-------------------------< R E M O V E _ W I K I _ L I N K >----------------------------------------------

Gets the display text from a wikilink like [[A|B]] or [[B]] gives B

The str:gsub() returns either A|B froma [[A|B]] or B from [[B]] or B from B (no wikilink markup).

In l(), l:gsub() removes the link and pipe (if they exist); the second :gsub() trims white space from the label
if str was wrapped in wikilink markup.  Presumably, this is because without wikimarkup in str, there is no match
in the initial gsub, the replacement function l() doesn't get called.

]=]

local function remove_wiki_link (str)
	return (str:gsub( "%[%[([^%[%]]*)%]%]", function(l)
		return l:gsub( "^[^|]*|(.*)$", "%1" ):gsub("^%s*(.-)%s*$", "%1");
	end));
end


--[=[-------------------------< M A K E _ W I K I L I N K >----------------------------------------------------

Makes a wikilink; when both link and display text is provided, returns a wikilink in the form [[L|D]]; if only
link is provided, returns a wikilink in the form [[L]]; if neither are provided or link is omitted, returns an
empty string.

]=]

local function make_wikilink (link, display)
	if link and ('' ~= link) then
		if display and ('' ~= display) then
			return table.concat ({'[[', link, '|', display, ']]'});
		else
			return table.concat ({'[[', link, ']]'});
		end
	end
	return display or '';													-- link not set so return the display text
end


--[[--------------------------< S I Z E >----------------------------------------------------------------------

module entry point

create a wikilinked list of <article name>'s sections and their size in bytes in a sortable wikitable

{{#invoke:Sandbox/trappist the monk/section|size|<article name>}}

]]

local function size (frame)
	local A = {};																-- table to hold section names and sizes
	local section_name_list = {}												-- an interim list that holds just the section names
	local section_content;														-- section content used for counting
	local section = '_LEAD_';													-- lead section doen't have a heading
	local count;																-- number of bytes in a section including the header text
	local total;																-- sum of all byte counts
	local max;																	-- largest section so far encountered
	local _;																	-- dummy for using gsub to count bytes
	local lang = mw.language.getContentLanguage();								-- language object for number formatting appropriate to local language
	local s;																	-- start position of found heading (returned from string.find())
	local e = 1;																-- end position of found heading (returned from string.find())
	local section_name;															-- captured heading name (returned from string.find())
	local level;																-- number of leading '=' in heading markup; used for indenting subsections in the rendered list
	local wl_name;																-- anchor and display portion for wikilinks in rendered list

	local content = mw.title.new (frame.args[1]):getContent();					-- get unparsed wikitext from the article
	if not content then
		return '<span style="font-size:100%;" class="error">error: no article:' .. frame.args[1] .. '</span>';
	end

	if content:find ('#REDIRECT') then											-- redirects don't have sections
		return '<span style="font-size:100%;" class="error">error: ' .. frame.args[1] .. ' is a redirect</span>';
	end

	section_content = content:match ('(.-)===*');								-- get the lead section
	if section_content then
		_, count = section_content:gsub ('.', '%1');							-- count the size of the lead section
	else
		return '<span style="font-size:100%;" class="error">error: no sections found in: ' .. frame.args[1] .. '</span>';
	end
	total = count;
	max = count;
	
	table.insert (A, make_wikilink (frame.args[1], section) .. '|| style="text-align:right"|' .. lang:formatNum (count));

	while (1) do																-- done this way because some articles reuse section names
		s, e, section_name = string.find (content, '\n==+ *(.-) *==+', e);		-- get start, end, and section name beginning a end of last find; newline must precede '==' heading markup
		if s then
			table.insert (section_name_list, {section_name, s});				-- save section name and start location of this find
		else
			break;
		end
	end
	
	for i, section_name in ipairs (section_name_list) do
		local escaped_section_name = string.gsub (section_name[1], '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1');	-- escape lua patterns in section name
		local pattern = '(==+ *' .. escaped_section_name .. ' *==+.-)==+';		-- make a pattern to get the content of a section
		section_content = string.match (content, pattern, section_name[2]);		-- get the content beginning at the string.find() start location
		if section_content then
			_, count = section_content:gsub ('.', '%1');						-- count the bytes in the section
			total = total + count;
			max = max < count and count or max;									-- keep track of largest count
		else																	-- probably the last section (no proper header follows this section name)
			pattern = '(==+ *' .. escaped_section_name .. ' *==+.+)';			-- make a new pattern
			section_content = string.match (content, pattern, section_name[2]);	-- try to get content
			if section_content then
				_, count = section_content:gsub ('.', '%1');					-- count the bytes in the section
				total = total + count;
				max = max < count and count or max;								-- keep track of largest count
			else
				count = '—';													-- no content so show that
			end
		end

		_, level = section_content:find ('^=+');								-- should always be the first n characters of section content
		level = (2 < level) and ((level-2) * 1.6) or nil;						-- remove offset and mult by 1.6em (same indent as ':' markup which doesn't work in a table)

		wl_name = remove_wiki_link (section_name[1]):gsub ('%b{}', '');			-- remove wikilinks and templates from section headings so that we can link to the section
		wl_name = wl_name:gsub ('[%[%]]', {['[']='&#91;', [']']='&#93;'});		-- replace '[' and ']' characters with html entities so that wikilinked section names work
		wl_name = mw.text.trim (wl_name);										-- trim leading/trailing white space if any because white space buggers up url anchor links
		
		table.insert (A, table.concat ({										-- build most of a table row here because here we have heading information that we won't have later
			level and '<span style="margin-left:' .. level .. 'em">' or '';		-- indent per heading level (number of '=' in heading markup)
			make_wikilink (frame.args[1] .. '#' .. wl_name, wl_name),			-- section link
			level and '</span>' or '',											-- close the span if opened
			'||',																-- table column separator
			'style="text-align:right"|',										-- the byte count column is right aligned
			lang:formatNum (count)}));											-- commafied byte count for section
	end

	local out = {};																-- make a sortable wikitable for output
	table.insert (out, string.format ('{| class="wikitable sortable" style="%s"\n|+Section size for [[%s]] (%d sections)', frame.args.style or '', frame.args[1], #A));	-- output table header
	table.insert (out, '\n!Section name!!Byte count\n|-\n|');					-- column headers, and first row pipe
	table.insert (out, table.concat (A, '\n|-\n|'));							-- section rows with leading pipes (except first row already done)
	table.insert (out, '\n|-\n!Total!!style="text-align:right"|' .. lang:formatNum (total));	-- total number of bytes counted as column headers so that sorting doesn't move this row from the bottom to top
	table.insert (out, '\n|}');													-- close the wikitable
	
	max = lang:formatNum (max);													-- commafy so that the commafied value in the table can be found
	local result = table.concat (out, ''):gsub (max, '<span style="color:red">' .. max .. '</span>');	-- make a big string, make largest count(s) red, and done
	return result;																-- because gsub returns string and number of replacements
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return
	{
	size = size,
	}