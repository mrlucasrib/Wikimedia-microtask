require('Module:No globals');

local getArgs = require ('Module:Arguments').getArgs;
local override_data = mw.loadData ('Module:Language/data/ISO 639 override');
--local override_data = mw.loadData ('Module:Language/data/ISO 639 override/sandbox');
local deprecated_data = mw.loadData ('Module:Language/data/ISO 639 deprecated');
local parts = {
	{'Module:Language/data/ISO 639-1', '1'},
	{'Module:Language/data/ISO 639-2', '2'},
	{'Module:Language/data/ISO 639-2B', '2B'},
	{'Module:Language/data/ISO 639-3', '3'},
	{'Module:Language/data/ISO 639-5', '5'},
	}


--[[--------------------------< E R R O R _ M E S S A G E S >--------------------------------------------------

]]

local error_messages = {
	['err_msg'] = '<span style="font-size:100%;" class="error show_639_err_msgs">error: $1 ([[Template:ISO 639 name|help]])</span>',
	['err_text'] = {															-- error messages used only in the code to name functions
		['ietf'] = '$1 is an IETF tag',											-- $1 is the ietf tag
		['required'] = 'ISO 639$1 code is required',							-- $1 is the 639 '-1', '-2', '-3', '-5' part suffix; may be empty string

																				-- code to name functions and iso_639_name_to_code()
		['not_found'] = '$1 not found in ISO 639-$2 list',						-- $1 is code or language name; $2 is 639 part suffix(es)

																				-- iso_639_name_to_code() only
		['name'] = 'language name required',
		['not_part'] = '$1 not an ISO 639 part',								-- $1 is invalid 639 suffix (without hyphen)

		['code_name'] = 'language code or name required',						-- iso_639() only
		}
	}

local error_cat = '[[Category:ISO 639 name template errors]]';


--[[--------------------------< S U B S T I T U T E >----------------------------------------------------------

Populates numbered arguments in a message string using an argument table.

]]

local function substitute (msg, args)
	return args and mw.message.newRawMessage (msg, args):plain() or msg;
end


--[[--------------------------< E R R O R _ M S G >------------------------------------------------------------

create an error message

]]

local function error_msg (msg, arg, hide, nocat)
	local retval = '';
	if not hide then
		retval = substitute (error_messages.err_msg, substitute (error_messages.err_text[msg], arg));
		retval = nocat and retval or (retval .. error_cat);
	end
	return retval
end


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Returns true if argument is set; false otherwise. Argument is 'set' when it exists (not nil) or when it is not an empty string.

]]

local function is_set (var)
	return not (var == nil or var == '');
end


--[=[-------------------------< M A K E _ W I K I L I N K >----------------------------------------------------

Makes a wikilink; when both link and display text is provided, returns a wikilink in the form [[L|D]]; if only
link is provided, returns a wikilink in the form [[L]]; if neither are provided or link is omitted, returns an
empty string.

]=]

local function make_wikilink (link, display)
	if is_set (link) then
		if is_set (display) then
			return table.concat ({'[[', link, '|', display, ']]'});
		else
			return table.concat ({'[[', link, ']]'});
		end
	else
		return '';
	end
end


--[[--------------------------< L A N G _ N A M E _ G E T >----------------------------------------------------

returns first listed language name for code from data{} table; strips parenthetical disambiguation; wikilinks to
the language article if link is true; returns nil else

]]

local function lang_name_get (code, data, link, label, raw)
	local name;
	if data[code] then
--		name = raw and data[code][1] or data[code][1]:gsub ('%s*%b()', '');		-- get the name; strip parenthetical disambiguators if any when <raw> is false
		if raw then
			name = data[code][1];
		else
			name = data[code][1]:gsub ('%s*%b()', '');							-- strip parenthetical disambiguators if any
			name = name:gsub ('([^,]-), +(.+)', '%2 %1');						-- if inverted, uninvert
		end
		if link then															-- make a link to the language article?
			if name:find ('languages') or name:find ('[Ll]anguage$') then
				name = make_wikilink (name, label);								-- simple wikilink for collective languages or langauges ending in 'Language' unless there is a label
			elseif override_data.article_name[code] then
				name = make_wikilink (override_data.article_name[code][1], label or name);	-- language name or label with wikilink from override data
			else
				name = make_wikilink (name .. ' language', label or name);		-- [[name language|name]] or [[name language|label]]
			end
		end
		return name;
	end
end


--[[--------------------------< A D D _ I E T F _ E R R O R _ M S G >------------------------------------------

assembles return-text (language code, language name, or error message) with IETF error message into properly
formatted readable text

|hide-err=yes suppresses error message and category
|cat=no supresses category

]]

local function add_ietf_error_msg (text, ietf_err, hide, nocat)
	if hide then
		ietf_err = '';
	end

	if not nocat then															-- |cat= empty or omitted -> nocat=false
		nocat = '' == ietf_err;													-- spoof; don't add cat when no error
	end

	return table.concat ({														-- tack on ietf error message if one exists
		text,																	-- code name, language name, or error message
		'' ~= ietf_err and ' ' or '',											-- needs a space when ietf_err is not empty
		ietf_err,
		nocat and '' or error_cat,												-- add error category when |cat=<aynthing but 'no'>
		});
end


--[[--------------------------< G E T _ P A R T _ I N D E X >--------------------------------------------------

gets index suitable for parts{} table from ISO 639-<part> (usually args[2])

return valid index [1] - [5]; nil else
	1   <- part ['1']
	2   <- part ['2']															-- this is part 2T
	3   <- part ['2B']
	4   <- part ['3']
	nil <- part ['4']															-- there is no part 4
	5   <- part ['5']

]]

local function get_part_index (part)
	return ({['1']=1, ['2']=2, ['2B']=3, ['3']=4, ['4']=nil, ['5']=5})[part]
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ T O _ N A M E _ C O M M O N >------------------------

this is code that is common to all of the iso_639_code_n_to_name() functions which serve only as template entry
points to provide the frame, the name of the appropriate data source, and to identify which 639 part applies.

this function returns a language name or an error message.  data is searched in this order:
	part-specific override data -> standard part data -> part-specific deprecated data

a second retval used by _iso_639_code_to_name() is true when a code is found; nil else

]]

local function iso_639_code_to_name_common (args, source, part)
	local hide = 'yes' == args['hide-err'];										-- suppress error messages and error categorization
	local nocat = 'no' == args.cat;												-- suppress error categorization (primarily for demo use)
	local raw = 'yes' == args.raw;												-- disable override and dab removal
	local data;																	-- one of the override or part tables
	local name;																	-- holds language name from data

	if not args[1] then															-- if code not provided in the template call
		return error_msg ('required', '-' .. part, hide, nocat);						-- abandon
	end

	local code;																	-- used for error messaging
	local ietf_err;																-- holds an error message when args[1] (language code) is in IETF tag form (may or may not be a valid IETF tag)
	code, ietf_err = args[1]:gsub('(.-)%-.*', '%1');							-- strip ietf subtags; ietf_err is non-zero when subtags are stripped
	ietf_err = (0 ~= ietf_err) and error_msg ('ietf', args[1], hide, nocat) or '';		-- when tags are stripped create an error message; empty string for concatenation else

	if not raw then																-- when raw is true, fetch name as is from part data; ignore override
		data = override_data['override_' .. part];								-- get override data for this part
		name = lang_name_get (code:lower(), data, args.link, args.label, raw);	-- get override language name if there is one
	end
	
	if not name then
		data = mw.loadData (source);											-- get the data for this ISO 639 part
		name = lang_name_get (code:lower(), data, args.link, args.label, raw);	-- get language name if there is one
	end

	if not name then															-- TODO: do something special to indicate when a name is fetched from deprecated data?
		data = deprecated_data['deprecated_' .. part];							-- get deprecated data for this part
		name = lang_name_get (code:lower(), data, args.link, args.label, raw);	-- get deprecated language name if there is one

		if not name then
			return error_msg ('not_found', {code, part}, hide, nocat);			-- code not found, return error message
		end
	end		
	return add_ietf_error_msg (name, ietf_err, hide, nocat), true;				-- return language name with ietf error message if any; true because we found a code
end


--[[--------------------------< _ I S O _ 6 3 9 _ C O D E _ T O _ N A M E >------------------------------------

searches through the ISO 639 language tables for a name that matches the supplied code.  on success returns first
language name that matches code from template frame perhaps with an error message and a second return value of true;
on failure returns an error message and a second return value of nil.  The second return value is a return value
used by iso_639_code_exists()

looks first in the override data and then sequentially in the 639-1, -2, -3, and -5 data

]]

local function _iso_639_code_to_name (frame)
	local args = getArgs(frame);
	local hide = 'yes' == args['hide-err'];										-- suppress error messages and error categorization
	local nocat = 'no' == args.cat;												-- suppress error categorization (primarily for demo use)
	
	if not args[1] then															-- if code not provided in the template call
		return error_msg ('required', '', hide, nocat);							-- abandon
	end

	local name;																	-- the retrieved language name and / or error message
	local found;																-- set to true when language name is found

	for _, part in ipairs (parts) do
		name, found = iso_639_code_to_name_common (args, part[1],  part[2]);
		if found then
			return name, true;													-- second retval for iso_639_name_exists()
		end
	end

	return error_msg ('not_found', {args[1], '1, -2, -2B, -3, -5'}, hide, nocat);	-- here when code (args[1]) is not found in the data tables
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ T O _ N A M E >--------------------------------------

template entry point; returns first language name that matches code from template frame or an error message
looks first in the override data and then sequentially in the 639-1, -2, -3, and -5 data

]]

local function iso_639_code_to_name (frame)
	local ret_val = _iso_639_code_to_name (frame);								-- ignore second return value
	return ret_val;																-- return language name and / or error message
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ E X I S T S >----------------------------------------

template entry point; returns true if language code maps to a language name; intended as a replacement for:
	{{#exist:Template:ISO 639 name <code>|<exists>|<doesn't exist>}}
Instead of that expensive parser function call use this function:
	{{#if:{{#invoke:ISO 639 name|iso_639_code_exists|<code>}}|<exists>|<doesn't exist>}}
on success, returns true; nil else

]]

local function iso_639_code_exists (frame)
	local _, exists;
	 _, exists = _iso_639_code_to_name (frame);									-- ignore name/error message return; <exists> is true when name found for code; nil else
	 return exists;
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ 1 _ T O _ N A M E >----------------------------------

template entry point; returns first language name that matches ISO 639-1 code from template frame or an error message

]]

local function iso_639_code_1_to_name (frame)
	local args = getArgs (frame);
	local retval = iso_639_code_to_name_common (args, parts[1][1],  parts[1][2]);	-- suppress second return value
	return retval;
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ 2 _ T O _ N A M E >----------------------------------

template entry point; returns first language name that matches ISO 639-2 code from template frame or an error message

]]

local function iso_639_code_2_to_name (frame)
	local args = getArgs (frame);
	local retval = iso_639_code_to_name_common (args, parts[2][1],  parts[2][2]);	-- suppress second return value
	return retval;
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ 2 B _ T O _ N A M E >--------------------------------

template entry point; returns first language name that matches ISO 639-2 code from template frame or an error message

]]

local function iso_639_code_2B_to_name (frame)
	local args = getArgs (frame);
	local retval = iso_639_code_to_name_common (args, parts[3][1],  parts[3][2]);	-- suppress second return value
	return retval;
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ 3 _ T O _ N A M E >----------------------------------

template entry point; returns first language name that matches ISO 639-3 code from template frame or an error message

]]

local function iso_639_code_3_to_name (frame)
	local args = getArgs (frame);
	local retval = iso_639_code_to_name_common (args, parts[4][1],  parts[4][2]);	-- suppress second return value
	return retval;
end


--[[--------------------------< I S O _ 6 3 9 _ C O D E _ 5 _ T O _ N A M E >----------------------------------

template entry point; returns first language name that matches ISO 639-5 code from template frame or an error message

]]

local function iso_639_code_5_to_name (frame)
	local args = getArgs (frame);
	local retval = iso_639_code_to_name_common (args, parts[5][1],  parts[5][2]);	-- index [4] -> part 5 because there is no part 4; suppress second return value
	return retval;
end


--[[--------------------------< N A M E _ I N _ P A R T _ C O D E _ G E T >------------------------------------

indexes into the <name_data> using <name> and extracts the language code assigned to <part> (1, 2, 2B, 3, 5).
attempts to index override data first; returns code on success, nil else

]]

local function name_in_part_code_get (name, part, part_idx, name_data)
	return name_data[name] and (
		name_data[name][part_idx+5]	or											-- see if the name exists in the part's override table
		name_data[name][part_idx] or											-- see if the name exists in the part's main table
		name_data[name][part_idx+10]											-- see if the name exists in the part's deprecated table
		);
end


--[[--------------------------< _ I S O _ 6 3 9 _ N A M E _ T O _ C O D E >------------------------------------

module entry point; returns ISO 639-1, -2, -2B, -3, or -5 code associated with language name according to part
(1, 2, 2B, 3, 5) argument; when part is not provided scans 1, 2, 2B, 3, 5 and returns first code

override data are examined first

<args> is frame arguments from getArgs(frame)

]]

local function _iso_639_name_to_code (args)
	local hide = 'yes' == args['hide-err'];										-- suppress error messages and error categorization
	local nocat = 'no' == args.cat;												-- suppress error categorization (primarily for demo use)

	if not args[1] then
		return error_msg ('name', '', hide, nocat);								-- abandon when language name missing
	end
	
	local name = args[1];														-- used in error messaging
	local lc_name = name:gsub(' +', ' '):lower();								-- lowercase version of name for indexing into the data table; strip extraneous space characters

	local part_idx;
	local part = args[2];
	if part then
		part_idx = get_part_index (part);
		if not part_idx then
			return error_msg ('not_part', part, hide, nocat);					-- abandon; args[2] is not a valid ISO 639 part
		end
	end

	local name_data = mw.loadData ('Module:Language/data/ISO 639 name to code');	-- ISO 639 language names to code table
--	local name_data = mw.loadData ('Module:Language/data/ISO 639 name to code/sandbox');	-- ISO 639 language names to code table

	local code;
	
	if part then
		code = name_in_part_code_get (lc_name, part, part_idx, name_data);		-- search the specified override table + part table
	else
		for part_idx, part_tag in ipairs ({'1', '2', '2B', '3', '5'}) do		-- no part provided, spin through all parts override first and get the first available code
			code = name_in_part_code_get (lc_name, part_tag, part_idx, name_data);
			if code then														-- nil when specified <part> does not have code for specified language <name>
				break;															-- when code is not nil, done
			end
		end
	end
	
	if code then
		return code, true;
	end
	return error_msg ('not_found', {name, part or '1, -2, -2B, -3, -5'}, hide, nocat), false;
end


--[[--------------------------< I S O _ 6 3 9 _ N A M E _ T O _ C O D E >--------------------------------------

template entry point; returns ISO 639-1, -2, -2B, -3, or -5 code associated with language name according to part
(1, 2, 2B, 3, 5) argument; when part is not provided scans 1, 2, 2B, 3, 5 and returns first code

override data are examined first

args[1] is language name
args[2] is ISO 639 part

]]

local function iso_639_name_to_code (frame)
	local args = getArgs(frame);
	local result, _ = _iso_639_name_to_code (args);								-- suppress true/false return used by iso_639_name_exists()
	return result;
end


--[[--------------------------< I S O _ 6 3 9 _ N A M E _ E X I S T S >----------------------------------------

template entry point; returns ISO 639-1, -2, -3, or -5 code associated with language name according to part (1, 2, 3, 5) argument;
when part is not provided scans 1, 2, 3 , 5 and returns first code

override data are examined first

args[1] is language name
args[2] is ISO 639 part

]]

local function iso_639_name_exists (frame)
	local args = getArgs(frame);
	local _, result = _iso_639_name_to_code (args);								-- suppress code return used by iso_639_name_to_code()
	return result and true or nil;
end


--[[--------------------------< I S O _ 6 3 9 >----------------------------------------------------------------

template entry point.
returns:
	language name if args[1] is valid language code
	language code if args[1] is valid language name

this function is constrained to the ISO 639 part specified in args[2] which must be 1, 2, 2B, 3, or 5.  When not provided
all parts are tested. The first match is found

]]

local function iso_639 (frame)
	local args = getArgs (frame);
	local hide = 'yes' == args['hide-err'];										-- suppress error messages and error categorization
	local nocat = 'no' == args.cat;												-- suppress error categorization (primarily for demo use)
	local result;
	local found;																-- set to true when language name is found

	if not args[1] then
		return error_msg ('code_name', '', hide, nocat);
	end

	local part = args[2];
	if part then																-- if ISO 639 part supplied
		local part_idx = get_part_index (part);									-- map index from <part>; anything else nil

		if not part_idx then
			return error_msg ('not_part', part, hide, nocat);					-- abandon; args[2] is not a valid ISO 639 part
		end

		result, found = iso_639_code_to_name_common (args, parts[part_idx][1], parts[part_idx][2]);		-- attempt to find a code match
		if found then
			return result;														-- found the code so return the language name
		end

		result = _iso_639_name_to_code (args);									-- might be a language name; return code if it is; error message or empty string else
		return result;															-- this way to suppress second return

	else		
		for _, part in ipairs (parts) do										-- for each of the iso 639 parts
			result, found = iso_639_code_to_name_common (args, part[1], part[2]);	-- attempt to find a code match
			if found then
				return result;													-- found the code so return the language name
			end
		end
	end	

	result = _iso_639_name_to_code (args);										-- might be a language name; return code if it is; error message or empty string else
	return result;																-- this way to suppress second return
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	iso_639 = iso_639,															-- returns code when given name; returns name when given code

	iso_639_code_exists = iso_639_code_exists,
	iso_639_name_exists = iso_639_name_exists,

	iso_639_code_to_name = iso_639_code_to_name,
	iso_639_code_1_to_name = iso_639_code_1_to_name,
	iso_639_code_2_to_name = iso_639_code_2_to_name,
	iso_639_code_2B_to_name = iso_639_code_2B_to_name,
	iso_639_code_3_to_name = iso_639_code_3_to_name,
	iso_639_code_5_to_name = iso_639_code_5_to_name,

	iso_639_name_to_code = iso_639_name_to_code,
	};