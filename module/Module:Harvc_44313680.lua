require('Module:No globals')
local anchor_id_list = mw.loadData ('Module:Footnotes/anchor_id_list').anchor_id_list;

local code_open_tag = '<code class="cs1-code">';								-- cs1-code class defined in Module:Citation/CS1/styles.css
local lock_icons = {															--icon classes are defined in Module:Citation/CS1/styles.css
	['registration'] = {'cs1-lock-registration', 'Free registration required'},
	['limited'] = {'cs1-lock-limited', 'Free access subject to limited trial, subscription normally required'},
	['subscription'] = {'cs1-lock-subscription', 'Paid subscription required'},
	}


--[[--------------------------< T A R G E T _ C H E C K >------------------------------------------------------

look for anchor_id (CITEREF name-list and year or text from |ref=) in anchor_id_list

the 'no target' error may be suppressed with |ignore-err=yes when target cannot be found because target is inside
a template that wraps another template; 'multiple targets' error may not be suppressed

]]

local function target_check (anchor_id, ignore)
	local number = anchor_id_list[anchor_id];									-- nil when anchor_id not in list; else a number
	local msg;
	local category;

	if not number then
		if ignore then
			return '';															-- if ignore is true then no message, no category
		end
		msg = 'no target: ' .. anchor_id;										-- anchor_id not found in this article
	elseif 1 < number then
		msg = 'multiple targets (' .. number .. '×): ' .. anchor_id;			-- more than one anchor_id in this article
	end

	category = 0 == mw.title.getCurrentTitle().namespace and '[[Category:Harv and Sfn template errors]]' or '';	-- only categorize in article space

--use this version to show error messages
	return msg and ' <span class="error harv-error" style="display: inline; font-size:100%">Harvc error: ' .. msg .. ' ([[:Category:Harv and Sfn template errors|help]])</span>' .. category or '';
--use this version to hide error messages
--	return msg and ' <span class="error harv-error" style="display: none; font-size:100%">Harvc error: ' .. msg .. ' ([[:Category:Harv and Sfn template errors|help]])</span>' .. category or '';
end


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not.  A varable is set when it is not nil and not empty.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[[--------------------------< C H E C K _ Y E A R S >--------------------------------------------------------

evaluates params to see if they are one of these forms with or without lowercase letter disambiguator (same as in
Module:Footnotes):
	YYYY
	n.d.
	nd	
	c. YYYY
	YYYY–YYYY	(separator is endash)
	YYYY–YY		(separator is endash)

when anchor_year present, year portion must be same as year param and must have disambiguator

returns empty string when params have correct form; error message else

]]

local function check_years (year, anchor_year)
	local y, ay;
	
	if not is_set (year) then													-- year is required so return error message when not set
		return ' missing ' .. code_open_tag .. '|year=</code>.';
	end
	
	local patterns = {															-- allowed year patterns from Module:Footnotes (captures added here)
		'^(%d%d%d%d?)%l?$',														-- YYY or YYYY
		'^(n%.d%.)%l?$',														-- n.d.
		'^(nd)%l?$',															-- nd
		'^(c%. %d%d%d%d?)%l?$',													-- c. YYY or c. YYYY
		'^(%d%d%d%d–%d%d%d%d)%l?$',												-- YYYY–YYYY
		'^(%d%d%d%d–%d%d)%l?$'													-- YYYY–YY
		}

	for _, pattern in ipairs (patterns) do										-- spin through the patterns
		y = year:match (pattern);												-- y is the year portion
		if y then
			break;																-- when y is set, we found a match so done
		end
	end

	if not y then
		return ' invalid ' .. code_open_tag .. '|year=</code>.';												-- y not set, so year is malformed
	end
	
	if is_set (anchor_year) then												-- anchor_year is optional
		for _, pattern in ipairs (patterns) do									-- spin through the patterns
			ay = anchor_year:match (pattern);									-- ay is the year portion
			if ay then
				break;															-- when ay is set, we found a match so done
			end
		end

		if not ay then
			return ' invalid ' .. code_open_tag .. '|anchor-year</code>.';		-- ay not set, so anchor_year is malformed
		end
		
--		if not anchor_year:match ('%l$') then
--			return ' ' .. code_open_tag .. '|anchor-year=</code> missing dab.';	-- anchor_year must end with a disambiguator letter
--		end
	
		if y ~= ay then
			return ' ' .. code_open_tag .. '|year=</code> / ' .. code_open_tag .. '|anchor-year=</code> mismatch.';	-- 'year' portions of year and anchor_year must be the same
		end
	end
	
	return '';																	-- both years are good; empty string for concatenation
end


--[[--------------------------< M A K E _ N A M E >------------------------------------------------------------

Assembles last, first, link, or mask into a displayable contributor name.

]]

local function make_name (last, first, link, mask)
	local name = last;
	
	if is_set (first) then
		name = name .. ', ' .. first;											-- concatenate first onto last
	end
	
	if is_set (link) then
		name = '[[' .. link .. '|' .. name .. ']]';								-- form a wikilink around the name
	end
	
	if is_set (mask) then														-- mask this author
		if tonumber(mask) then
			name = string.rep ('—', mask)										-- make a string that number length of mdashes
		else
			name = mask;														-- mask is not a number so use the mask text
		end
	end
	
	return name;
end


--[[--------------------------< C O R E >----------------------------------------------------------------------

Assembles the various parts provided by the template into a properly formatted bridging citation.  Adds punctuation
and text; encloses the whole within a span with id and class attributes.

This creates a CITEREF anchor from |last1= through |last4= and |year=.  It also creates a CITEREF link from |in1= through
|in4= and |year=.  It is presumed that the dates of contributions are the same as the date of the enclosing work.

Even though not displayed, a year parameter is still required for the CITEREF anchor

]]

local function core( args )
	local span_open_tag;														-- holds CITEREF and css
	local contributors = '';													-- chapter or contribution authors
	local source = '';															-- editor/author date list that forms a CITEREF link to a full citation
	local in_text = ' In ';
	local result;																-- the assemby of the above output

-- form the CITEREF anchor
	if is_set (args.id) then
		args.id = mw.uri.anchorEncode (args.id)
		span_open_tag = '<span id="' .. args.id .. '" class="citation">';		-- for use when contributor name is same as source name
	else
		local citeref = 'CITEREF' .. table.concat (args.citeref) .. (is_set (args['anchor-year']) and args['anchor-year'] or args.year);
		citeref = mw.uri.anchorEncode (citeref);
		span_open_tag = '<span id="' .. citeref .. '" class="citation">';
	end
 
--[[
form the contributors display list:
	if |name-list-format=harv, display is similar to {{sfn}} and {{harv}}, 1 to 4 last names;
	if |display-authors= is empty or omitted, display is similar to cs1|2: display all names in last, first order 
	if |display-authors=etal then displays all author names in last, first order and append et al.
	if value assigned to |display-authors= is less than the number of author last names, displays the specified number of author names in last, first order followed by et al.
]]
	if 'harv' ~= args.name_list_format then										-- default cs1|2 style contributor list
		local i = 1;
		local count;
		local etal = false;														-- when |display-authors= is same as number of authors in contributor list
		
		if is_set (args.display_authors) then
			if 'etal' == args.display_authors:lower():gsub("[ '%.]", '') then	-- the :gsub() portion makes 'etal' from a variety of 'et al.' spellings and stylings
				count = #args.last;												-- display all authors and ...
				etal = true;													-- ... append 'et al.'
			else
				count = tonumber (args.display_authors) or 0;					-- 0 if can't be converted to a number
				if 0 >= count then
					args.err_msg = args.err_msg .. ' invalid ' .. code_open_tag .. '|display-authors=</code>';	-- if zero, then emit error message
				end
			end
			if count > #args.last then
				count = #args.last;												-- when |display-authors= is more than the number of authors, use the number of authors
			end
			if count < #args.last then											-- when |display-authors= is less than the number of authors
				etal = true;													-- append 'et al.'
			end
		else
			count = #args.last;													-- set count to display all of the authors
		end
		
		while i <= count do
			if is_set (contributors) then
				contributors = contributors .. '; ' .. make_name (args.last[i], args.first[i], args.link[i], args.mask[i]);			-- the rest of the contributors
			else
				contributors = make_name (args.last[i], args.first[i], args.link[i], args.mask[i]);			-- first contributor's name
			end
			i = i+1;															-- bump the index
		end
		if true == etal then
			contributors = contributors .. ' et al.';							-- append et al.
		elseif 'yes' == args.last_author_amp then
			contributors = contributors:gsub('; ([^;]+)$', ' & %1')				-- replace last separator with ' & '
		end
	else																		-- do default harv- or sfn-style contributor display
		if 4 <= #args.last then													-- four or more contributors (first followed by et al.)
			contributors = args.last[1] .. ' et al.';
		elseif 3 == #args.last then												-- three (display them all)
			contributors = args.last[1] .. ', ' .. args.last[2] .. ' &amp; ' .. args.last[3];
		elseif 2 == #args.last then												-- two (first & second)
			contributors = args.last[1] .. ' &amp; ' .. args.last[2];
		elseif 1 == #args.last then												-- just one (first)
			contributors = args.last[1];
		else
			args.err_msg = args.err_msg .. ' no authors in contributor list.';	-- this code used to find holes in the list; no more
		end
	end

--form the source author-date list
	if is_set (args.in4) and is_set (args.in3) and is_set (args.in2) and is_set (args.in1) then
		source = args.in1 .. ' et al.';
	elseif not is_set (args.in4) and is_set (args.in3) and is_set (args.in2) and is_set (args.in1) then
		source = args.in1 .. ', ' .. args.in2 .. ' &amp; ' .. args.in3;
	elseif not is_set (args.in4) and not is_set (args.in3) and is_set (args.in2) and is_set (args.in1) then
		source = args.in1 .. ' &amp; ' .. args.in2;
	elseif not is_set (args.in4) and not is_set (args.in3) and not is_set (args.in2) and is_set (args.in1) then
		source = args.in1;
	else
		args.err_msg = args.err_msg .. ' author missing from source list.'
	end

	source = source .. ' ' .. args.open .. args.year .. args.close;				-- add the year with or without brackets

--assemble CITEREF wikilink
	local anchor_id;
	local target_err_msg;
	
	if '' ~= args.ref then
		anchor_id = mw.uri.anchorEncode (args.ref)
	else
		anchor_id = mw.uri.anchorEncode(table.concat ({'CITEREF', args.in1, args.in2, args.in3, args.in4, args.year}));
	end
	
	target_err_msg = target_check (anchor_id, args.ignore);						-- see if there is a target for this anchor_id
	source = '[[#' .. anchor_id .. "|" .. source .. "]]";

--combine contribution with url to make external link
	if args.url ~= '' then
		args.contribution = '[' .. args.url .. ' ' .. args.contribution .. ']';	-- format external link

		if args['url-access'] then
			if lock_icons[args['url-access']] then
			args.contribution = table.concat ({									-- add access icon markup to this item
				'<span class="',												-- open the opening span tag; icon classes are defined in Module:Citation/CS1/styles.css
				lock_icons[args['url-access']][1],								-- add the appropriate lock icon class
				'" title="',													-- and the title attribute
				lock_icons[args['url-access']][2],								-- for an appropriate tool tip
				'">',															-- close the opening span tag
				args.contribution,
				'</span>',														-- and close the span
				});
			end
		end	
	end

	if is_set (args['anchor-year']) then
		contributors = contributors .. ' (' .. args['anchor-year'] .. ')' .. args.sepc;
	elseif args.sepc ~= contributors:sub(-1) and args.sepc .. ']]' ~= contributors:sub(-3) then
		contributors = contributors .. args.sepc;								-- add separator if not same as last character in name list (|first=John S. or et al.)
	end

-- pages and other insource location
	if args.p ~= '' then
		args.p = args.page_sep .. args.p;
	elseif args.pp ~= '' then
		args.p = args.pages_sep .. args.pp;										-- args.p not set so use it to hold common insource location info
	end      
 
	if args.loc ~= '' then
		args.p = args.p .. ', ' .. args.loc;									-- add arg.loc to args.p
	end

--wrap error messages in span and add help link
	if is_set (args.err_msg) then
		args.err_msg = '<span style="font-size:100%" class="error"> harvc:' .. args.err_msg .. ' ([[Template:Harvc|help]])</span>';
	end

	if ',' == args.sepc then
		in_text = in_text:lower();												-- CS2 style use lower case
	end

-- and put it all together
	result = span_open_tag .. contributors .. ' "' .. args.contribution .. '"' .. args.sepc .. in_text .. source .. args.p .. args.ps .. args.err_msg .. target_err_msg .. '</span>';

	return result;
end


--[[--------------------------< H A R V C >--------------------------------------------------------------------

Entry point from {{harvc}} template.  Fetches parent frame parameters, does a bit of simple error checking

]]

local function harvc (frame)
	local args = {
		err_msg = '',
		page_sep = ", p.&nbsp;",
		pages_sep = ", pp.&nbsp;",
		sepc = '.',
		ps = '.',
		open = '(',																-- year brackets for source year
		close = ')',
		last = {},
		first = {},
		link = {},
		mask = {},
		citeref = {}
		}

	local pframe = frame:getParent();
 
	args.contribution =  pframe.args.c or										-- chapter or contribution
				pframe.args.chapter or
				pframe.args.contribution or '';

	args.id = pframe.args.id or '';

	args.in1 = pframe.args['in'] or pframe.args.in1 or '';						-- source editor surnames; 'in' is a Lua reserved keyword
	args.in2 = pframe.args.in2 or '';
	args.in3 = pframe.args.in3 or '';
	args.in4 = pframe.args.in4 or '';

	args.display_authors = pframe.args['display-authors'];						-- the number of contributor names to display; cs1|2 format includes first names
	args.name_list_format = pframe.args['name-list-format'];					-- when set to 'harv' display contributor list in sfn or harv style
	args.last_author_amp = pframe.args['last-author-amp'] or					-- yes only; |last-author-amp=no does not work (though it does in cs1|2)
				pframe.args['lastauthoramp'] or '';
	args.last_author_amp = args.last_author_amp:lower();						-- make it case agnostic
	
	if is_set (pframe.args.last) or is_set (pframe.args.last1) or
		is_set (pframe.args.author) or is_set (pframe.args.author1) then		-- must have at least this to continue
			args.last[1] = pframe.args.last or pframe.args.last1 or pframe.args.author or pframe.args.author1;		-- get first contributor's last name
			args.citeref[1] = args.last[1];										-- add it to the citeref
			args.first[1] = pframe.args.first or pframe.args.first1;			-- get first contributor's first name
			args.link[1] = pframe.args['author-link'] or pframe.args['author-link1'];	-- get first contributor's article link
			args.mask[1] = pframe.args['author-mask'] or pframe.args['author-mask1'];	-- get first contributor's article link
		
			local i = 2;														-- index for the rest of the names
			while is_set (pframe.args['last'..i]) or is_set (pframe.args['author'..i]) do	-- loop through pframe.args and get the rest of the names
				args.last[i] = pframe.args['last'..i] or pframe.args['author'..i];	-- last names
				args.first[i] = pframe.args['first'..i];						-- first names
				args.link[i] = pframe.args['author-link'..i];					-- links
				args.mask[i] = pframe.args['author-mask'..i];					-- masks
				if 5 > i then
					args.citeref[i] = args.last[i];								-- collect first four last names for CITEREF anchor
				end
				i = i + 1														-- bump the index
			end
	end

	args.p = pframe.args.p or '';												-- source page number(s) or location
	args.pp = pframe.args.pp or '';
	args.loc = pframe.args.loc or '';
	args.ref = pframe.args.ref or pframe.args.Ref or '';						-- used to match |ref=<text> in cs1|2 source template
	args.ignore = 'yes' == pframe.args['ignore-err'];							-- suppress false-positive 'no target' errors

	if 'cs2' == pframe.args.mode then
		args.ps = '';															-- set postscript character to empty string, cs2 mode
		args.sepc = ',';														-- set seperator character to comma, cs2 mode
	end
	do																			-- to limit scope of local temp
		local temp = pframe.args.ps or pframe.args.postscript;
		
		if is_set (temp) then
			if 'none' == temp:lower() then										-- if |ps=none or |postscript=none then
				args.ps = '';													-- no postscript
			else
				args.ps = temp;													-- override default postscript
			end
		end
	end																			-- end of scope limit

	if 'yes' == pframe.args.nb then												-- if no brackets around year in link to cs1|2 template
		args.open = '';															-- unset these
		args.close = '';
	end
	
	args.url = pframe.args.url or												-- url for chapter or contribution
			pframe.args['chapter-url'] or
			pframe.args['contribution-url'] or '';
	
	args['url-access'] = pframe.args['url-access'];
	
	args.year = pframe.args.year or '';											-- required
	args['anchor-year'] = pframe.args['anchor-year'] or '';
	args.err_msg = args.err_msg .. check_years (args.year, args['anchor-year']);

	if not is_set (args.contribution) then
		args.err_msg = args.err_msg .. ' required contribution is missing.';	-- error message if source not provided
		args.contribution = args.url;											-- if set it will give us linkable text
	end
	
	if args.last[1] == args.in1 and
		args.last[2] == args.in2 and
		args.last[3] == args.in3 and
		args.last[4] == args.in4 and
		not is_set (args.id) then
			args.err_msg = args.err_msg .. ' required ' .. code_open_tag .. '|id=</code> parameter missing.';		-- error message if contributor and source are the same
	end

	return table.concat ({core (args), frame:extensionTag ('templatestyles', '', {src='Module:Citation/CS1/styles.css'})});
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	harvc = harvc
	};