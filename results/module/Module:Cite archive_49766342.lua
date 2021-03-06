require('Module:No globals')
local f = {};
local code_style="color:inherit; border:inherit; padding:inherit;";				-- used in styling error messages

--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not.  A variable is set when it is not nil and not empty.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[[--------------------------< S E L E C T _ O N E >----------------------------------------------------------

Choose one parameter value from a list of parameter values.  If more than one is set, emit error message.

]]

local function select_one (list, args)
	local selected_param;
	local selected_val='';

	for param, value in pairs (list) do										-- loop through the list
		if not is_set (selected_param) then										-- if we have not yet selected a parameter value
			if is_set (value) then												-- is this value set?
				selected_val = value;											-- select it
				selected_param = param;											-- remember the name for possible error message
			end
		else
			if is_set (value) then												-- error message if we have selected and found another set parameter
				args.err_msg = string.format (' more than one of <code style="%s">|%s=</code> and <code style="%s">|%s=</code>', code_style, selected_param, code_style, param)
				break;
			end
		end
	end
	return selected_val or '';															-- return selected value or empty string if none set
end


--[[--------------------------< M A K E _ N A M E >------------------------------------------------------------

Assembles last, first, link, or mask into a displayable author name.

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
		mask = tonumber (mask);													-- because the value provided might not be a number
		if is_set (mask) then
			name = string.rep ('—', mask)										-- make a string that number length of mdashes
		end
	end
	
	return name;
end


--[[-------------------------< M A K E _ A U T H O R _ L I S T >----------------------------------------------

form the authors display list:
	if |display-authors= is empty or omitted, display is similar to cs1|2: display all names in last, first order 
	if |display-authors=etal then displays all author names in last, first order and append et al.
	if value assigned to |display-authors= is less than the number of author last names, displays the specified number of author names in last, first order followed by et al.

]]
local function make_author_list (args, number_of_authors)
	local authors = '';
	local i = 1;
	local count;
	local etal = false;															-- when |display-authors= is same as number of authors in contributor list
	
	if is_set (args.display_authors) then
		if 'etal' == args.display_authors:lower():gsub("[ '%.]", '') then		-- the :gsub() portion makes 'etal' from a variety of 'et al.' spellings and stylings
			count = number_of_authors;											-- display all authors and ...
			etal = true;														-- ... append 'et al.'
		else
			count = tonumber (args.display_authors) or 0;						-- 0 if can't be converted to a number
			if 0 >= count then
				args.err_msg = string.format ('%s invalid <code style="%s">|display-authors=</code>; ', args.err_msg, code_style);
--				args.err_msg = args.err_msg .. ' invalid |display-authors=';	-- if zero, then emit error message
				count = number_of_authors;										-- and display all authors
			end
		end
		if count > number_of_authors then
			count = number_of_authors;											-- when |display-authors= is more than the number of authors, use the number of authors
		end
		if count < number_of_authors then										-- when |display-authors= is less than the number of authors
			etal = true;														-- append 'et al.'
		end
	else
		count = number_of_authors;												-- set count to display all of the authors
	end
	
	while i <= count do
		if is_set (authors) then
			authors = authors .. '; ' .. make_name (args.last[i], args.first[i], args.link[i], args.mask[i]);	-- the rest of the authors
		else
			authors = make_name (args.last[i], args.first[i], args.link[i], args.mask[i]);	-- first author's name
		end
		i = i+1;																-- bump the index
	end
	if true == etal then
		authors = authors .. '; et al.';										-- append et al.
	elseif 'yes' == args.last_author_amp then
		authors = authors:gsub('; ([^;]+)$', ' & %1')							-- replace last separator with ' & '
	end

--	if args.sepc ~= authors:sub(-1) and args.sepc .. ']]' ~= authors:sub(-3) then
--		authors = authors;											-- add separator if not same as last character in name list (|first=John S. or et al.)
--	end
																				-- TODO: better way to handle wikilink case?
	authors = authors:gsub ('%' .. args.sepc .. '$', '', 1);					-- remove trailing separator character
	authors = authors:gsub ('%' .. args.sepc .. ']]$', ']]', 1);				-- remove trailing separator character inside wikilink

	return authors;
end


--[[--------------------------< M A K E _ I T E M >------------------------------------------------------------

This function formats |item= and, if present, |item-url= into the linked part and if present appends |date= and
|type= with appropriate markup to complete the item portion of the citation.  This function assumes that item
has a value when it is called.

]]

local function make_item (item, url, item_date, item_type)
	local output = {};															-- table of item bits
	if is_set (url) then
		item = string.format ('[%s %s]', url, item);							-- make item into an external wikilink
	end
	table.insert (output, string.format ('"%s"', item));						-- enclose in quotes and add to table
	if is_set (item_date) then
		table.insert (output, string.format ('(%s)', item_date));				-- enclose in parentheses and add to table
	end
	if is_set (item_type) then
		table.insert (output, string.format ('[%s]', item_type));				-- enclose in square brackets and add to table
	end
	
	return table.concat (output, ' ');											-- concatenate with space as separator
end


--[[--------------------------< M A K E _ C O L L E C T I O N >------------------------------------------------

This function formats |collection= and, if present, |collection-url= into the linked part and if present, appends
the values from |fonds=, |series=, |box=, |file=, |itemid=, and |page= or |pages= to complete the collection
portion of the citation.  This function assumes that collection has a value when it is called (because that is one
of the two required parameters)

]]

local function make_collection (args)
	local output = {};															-- table of collections bits
	local collection = args.collection;
	if is_set (args.collectionURL) then
		collection = string.format ('[%s %s]', args.collectionURL, collection);				-- make collection into an external wikilink
	end
	table.insert (output, string.format ('%s', collection));					-- enclose in quotes and add to table
	if is_set (args.fonds) then
		table.insert (output, string.format ('Fonds: %s', args.fonds));			-- format and add to table
	end
	if is_set (args.series) then
		table.insert (output, string.format ('Series: %s', args.series));		-- format and add to table
	end
	if is_set (args.box) then
		table.insert (output, string.format ('Box: %s', args.box));				-- format and add to table
	end
	if is_set (args.file) then
		table.insert (output, string.format ('File: %s', args.file));			-- format and add to table
	end
	if is_set (args.itemID) then
		table.insert (output, string.format ('ID: %s', args.itemID));				-- format and add to table
	end
	
	if is_set (args.p) then
		table.insert (output, string.format ('%s%s', args.page_sep, args.p));
	elseif is_set (args.pp) then
		table.insert (output, string.format ('%s%s', args.pages_sep, args.pp));
	end      
 
 	if is_set (args.p) and is_set (args.pp) then
		args.err_msg = string.format ('%s more than one of <code style="%s">|page=</code> and <code style="%s">|pages=</code>; ', args.err_msg, code_style, code_style);
	end
 
	return table.concat (output, ', ');											-- concatenate with comma space as separator
end


--[[--------------------------< M A K E _ L O C A T I O N >----------------------------------------------------

This function formats |location=, |repository, and |institution= into the location portion of the citation.
This function assumes that |institution= (a required parameter) has a value when it is called.

Unlike other groups of parameters, the required parameter is the 'last' and separator characters are not all the same.

]]

local function make_location (location, repository, institution)
	local output = {};															-- table of location bits
	if is_set (location) then
		location = string.format ('%s: ', location);							-- format
	end
	if is_set (repository) then
		table.insert (output, repository);										-- and add to table
	end
	table.insert (output, institution);											-- and add to table
	
	return string.format ('%s%s', location, table.concat (output, ', '));		-- concatenate with comma space separators
end


--[[--------------------------< M A K E _ I D E N T I F I E R S >----------------------------------------------

This function formats |oclc= and |accession into the identifiers portion of the citation.  Neither of these
parameters are required.

]]

local function make_identifiers (args)
	local output = {};															-- table ofidentifier bits
	if is_set (args.oclc) then
		table.insert (output, string.format ('[[OCLC]]&nbsp;[https://www.worldcat.org/oclc/ %s]', args.oclc));
	end
	if is_set (args.accession) then
		table.insert (output, args.accession);
	end
	return table.concat (output, args.sepc .. ' ');								-- concatenate with sepc space as separator
end


--[[--------------------------< _ C I T E _ A R C H I V E >----------------------------------------------------

Assembles the various parts provided by the template into a properly formatted citation.  Adds punctuation
and text; encloses the whole within a cite tag with id and class attributes.

This creates a CITEREF anchor from |last1= through |last4= and the year portion of |date= when |ref=harv.

]]

local function _cite_archive (args)
	local cite_open_tag;														-- holds CITEREF and css
	local authors = '';															-- list of authors
	local identifiers = '';														-- OCLC and accession identifiers list
	local result = {};															-- the assembly of the citation's output

-- form the CITEREF anchor
	if 'harv' == args.ref then
		cite_open_tag = '<cite id="CITEREF' .. table.concat (args.citeref) .. args.year .. '" class="citation archive">';
	elseif is_set (args.ref) then
		cite_open_tag = '<cite id="' .. args.ref .. '" class="citation archive">';
	else
		cite_open_tag = '<cite class="citation archive">';
	end

	if 0 ~= #args.last then														-- if there are author names
		table.insert (result, make_author_list (args, #args.last));				-- assemble author name list and add to result table
	end
	
	if is_set (args.item) then													-- if there is an item
		table.insert (result, make_item (args.item, args.itemURL, args.date, args.type));	-- build the item portion of the citation
	end

	table.insert (result, make_collection (args));								-- build the collection portion of the citation (|collection= is required)

	table.insert (result, make_location (args.location, args.repository, args.institution));	-- build the location portion of the citation (institution= is required)

	identifiers = make_identifiers (args);										-- build the identifiers (oclc and accession) portion of the citation
	if is_set (identifiers) then
		table.insert (result, identifiers);
	end

	if is_set (args.accessdate) then
		table.insert (result, args.retrieved .. args.accessdate);
	end

--	wrap error messages in span and add help link
	if is_set (args.err_msg) then
		args.err_msg = '<span style="font-size:100%" class="error"> cite archive:' .. args.err_msg .. ' ([[Template:cite archive|help]])</span>';
	end

-- and put it all together and be done
	return string.format ('%s%s%s</cite>%s', cite_open_tag, table.concat (result, args.sepc .. ' '), args.ps, args.err_msg);
end


--[[--------------------------< F . C I T E _ A R C H I V E >--------------------------------------------------

Entry point from {{cite archive}} template.  Fetches parent frame parameters, does a bit of simple error checking
and calls _cite_archive() if required parameters are present.

]]
function f.cite_archive (frame)
	local args = {
		err_msg = '',
		page_sep = "p.&nbsp;",													-- cs1|2 style page(s) prefixes
		pages_sep = "pp.&nbsp;",
		retrieved = 'Retrieved ',												-- cs1 style access date static text
		sepc = '.',																-- default to cs1 stylre
		ps = '.',																-- default to cs1 stylre
		last = {},																-- table of author last name values
		first = {},																-- table of author first name values
		link = {},																-- table of author link values
		mask = {},																-- table of author mask values
		citeref = {}															-- table of last names that will be used in making the CITEREF anchor
		}

	local pframe = frame:getParent();											-- get template's parameters

	args.item = pframe.args.item or '';											-- these are the 'item' group
	args.itemURL = pframe.args['item-url'] or '';
	args.type = pframe.args.type or '';
	args.date = pframe.args.date or '';

	args.year = args.date:match ('%d%d%d%d') or '';								-- used in creation of the CITEREF anchor

	args.collection = pframe.args.collection or '';								-- these are the collection group
	args.collectionURL = pframe.args['collection-url'] or '';
	args.fonds = pframe.args.fonds or '';
	args.series = pframe.args.series or '';
	args.file = pframe.args.file or '';
	args.box = pframe.args.box or '';
	args.itemID = pframe.args['item-id'] or '';
	args.p = pframe.args.page or pframe.args.p or '';							-- if both are set, the singular is rendered
	args.pp = pframe.args.pages or pframe.args.pp or '';

	args.repository = pframe.args.repository or '';								-- these are the location group
	args.location = pframe.args.location or '';
	args.institution = pframe.args.institution or '';							-- required parameter

	args.oclc = pframe.args.oclc or '';											-- these are the identifiers group
	args.accession = pframe.args.accession or '';
	
	if not is_set (args.collection) then										-- check for required parameters
		args.err_msg = string.format (' <code style="%s">|collection=</code> required; ', code_style);
	end
	if not is_set (args.institution) then
		args.err_msg = string.format ('%s <code style="%s">|institution=</code> required; ', args.err_msg, code_style);
	end
	
	if is_set (args.err_msg) then												-- if set here, then we are missing one or both required parameters so quit
		return '<span style="font-size:100%" class="error">cite archive:' .. args.err_msg .. ' ([[Template:cite archive|help]])</span>';	-- with an error message
	end

																				-- standard cs1|2 parameters
	args.accessdate = pframe.args['access-date'] or pframe.args.accessdate or '';

	args.ref = pframe.args.ref or '';
		
	args.display_authors = pframe.args['display-authors'];						-- the number of author names to display
	args.last_author_amp = pframe.args['last-author-amp'] or					-- yes only; |last-author-amp=no does not work
				pframe.args['lastauthoramp'] or '';
	args.last_author_amp:lower();												-- make it case agnostic
	
	if is_set (pframe.args['last1']) or is_set (pframe.args['last']) or
		is_set (pframe.args['author1']) or is_set (pframe.args['author']) then	-- must have at least this to continue
		
		args.last[1] = select_one ({											-- get first author's last name
			['last']=pframe.args.last,
			['last1'] = pframe.args.last1,
			['author'] = pframe.args.author,
			['author1'] = pframe.args.author1}, args);
		args.citeref[1] = args.last[1];											-- add it to the citeref

		args.first[1] = select_one ({											-- get first author's first name
			['first'] = pframe.args.first,
			['first1'] = pframe.args.first1}, args);
		args.link[1] = select_one ({											-- get first author's article link
			['author-link'] = pframe.args['author-link'],
			['author-link1'] = pframe.args['author-link1']}, args);
		args.mask[1] = select_one ({											-- get first author's mask
			['author-mask'] = pframe.args['author-mask'],
			['author-mask1'] = pframe.args['author-mask1']}, args);
	
		local i = 2;															-- index for the rest of the names
		while is_set (pframe.args['last'..i]) or is_set (pframe.args['author'..i]) do		-- loop through pframe.args and get the rest of the names
			args.last[i] = pframe.args['last'..i] or pframe.args['author'..i];				-- last names
			args.first[i] = pframe.args['first'..i];							-- first names
			args.link[i] = pframe.args['author-link'..i];						-- author-links
			args.mask[i] = pframe.args['author-mask'..i];						-- author-masks
			if 5 > i then
				args.citeref[i] = args.last[i];									-- collect first four last names for CITEREF anchor
			end
			i = i + 1															-- bump the index
		end
	end

	if 'cs2' == pframe.args.mode then
		args.ps = '';															-- set postscript character to empty string, cs2 mode
		args.sepc = ',';														-- set separator character to comma, cs2 mode
		if not is_set (args.ref) then											-- if not already set to something
			args.ref= 'harv';													-- for cs2, set to harv
		end
		args.retrieved = args.retrieved:lower();
	end

	return _cite_archive (args);											-- go render the citation
end

return f;