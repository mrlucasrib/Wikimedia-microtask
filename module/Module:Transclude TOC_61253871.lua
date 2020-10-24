require('Module:No globals');

--[=[-------------------------< R E M O V E _ W I K I _ L I N K >----------------------------------------------

Gets the display text from a wikilink like [[A|B]] or [[B]] gives B

The str:gsub() returns either A|B froma [[A|B]] or B from [[B]] or B from B (no wikilink markup).

In l(), l:gsub() removes the link and pipe (if they exist); the second :gsub() trims white space from the label
if str was wrapped in wikilink markup.  Presumably, this is because without wikimarkup in str, there is no match
in the initial gsub, the replacement function l() doesn't get called.

]=]

local function remove_wiki_link (str)
	return (str:gsub( "%[%[:?([^%[%]]*)%]%]", function(l)
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


--[[--------------------------< T O C >----------------------------------------------------------------------

module entry point

create a wikilinked list of <page name>'s sections

{{#invoke:Sandbox/DannyS712/TOC|TOC|<article name>}}

]]

local function TOC (frame)
	local A = {};																-- table to hold section names and sizes
	local section_name_list = {}												-- an interim list that holds just the section names
	local section_content;														-- section content used for counting
	local section = '_LEAD_';													-- lead section doen't have a heading
	local count;																-- number of bytes in a section including the header text
	local _;																	-- dummy for using gsub to count bytes
	local lang = mw.language.getContentLanguage();								-- language object for number formatting appropriate to local language
	local s;																	-- start position of found heading (returned from string.find())
	local e = 1;																-- end position of found heading (returned from string.find())
	local section_name;															-- captured heading name (returned from string.find())
	local level;																-- number of leading '=' in heading markup; used for indenting subsections in the rendered list
	local wl_name;																-- anchor and display portion for wikilinks in rendered list

	local title = mw.title.new (frame.args[1]);									-- page title
	local content = title:getContent();											-- get unparsed wikitext from the article
	if not content then
		return '<span style="font-size:100%;" class="error">error: no article:' .. frame.args[1] .. '</span>';
	end

	if title.isRedirect then													-- redirects don't have sections
		return '<span style="font-size:100%;" class="error">error: ' .. frame.args[1] .. ' is a redirect</span>';
	end

	section_content = content:match ('(.-)===*');								-- get the lead section
	if section_content then
		_, count = section_content:gsub ('.', '%1');							-- count the size of the lead section
	else
		return '<span style="font-size:100%;" class="error">error: no sections found in: ' .. frame.args[1] .. '</span>';
	end
	
	table.insert (A, make_wikilink (frame.args[1], section));

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
		else																	-- probably the last section (no proper header follows this section name)
			pattern = '(==+ *' .. escaped_section_name .. ' *==+.+)';			-- make a new pattern
			section_content = string.match (content, pattern, section_name[2]);	-- try to get content
			if section_content then
				_, count = section_content:gsub ('.', '%1');					-- count the bytes in the section
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
			level and '</span>' or ''}));										-- close the span if opened
	end

	local out = {};																-- make a sortable wikitable for output
	table.insert (out, string.format ('{| class="wikitable" style="%s"\n|+Full table of contents for [[%s]] (%d sections)', frame.args.style or '', frame.args[1], #A));	-- output table header
	table.insert (out, '\n!Sections\n|-\n|');									-- column headers, and first row pipe
	table.insert (out, table.concat (A, '\n|-\n|'));							-- section rows with leading pipes (except first row already done)
	table.insert (out, '\n|}');													-- close the wikitable
	return table.concat (out, '');
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return
	{
	TOC = TOC,
	}