require('Module:No globals');
local getArgs = require ('Module:Arguments').getArgs;

local cfg = mw.loadData ('Module:Citation/CS1/Configuration');					-- load the configuration module

local exclusion_lists = {														-- TODO: move these tables into a separate ~/data module and mw.loadData() it
	['cite book'] = {
		['agency'] = true,
		['air-date'] = true,
		['arxiv'] = true,
		['biorxiv'] = true,
		['citeseerx'] = true,
		['class'] = true,
		['conference'] = true,
		['conference-format'] = true,
		['conference-url'] = true,
		['degree'] = true,
		['department'] = true,
		['display-interviewers'] = true,
		['docket'] = true,
		['episode'] = true,
		['interviewer#'] = true,
		['interviewer-first#'] = true,
		['interviewer-link#'] = true,
		['interviewer-mask#'] = true,
		['ismn'] = true,
		['issn'] = true,
		['issue'] = true,
		['jfm'] = true,
		['journal'] = true,
		['jstor'] = true,
		['mailinglist'] = true,
		['message-id'] = true,
		['minutes'] = true,
		['MR'] = true,
		['network'] = true,
		['number'] = true,
		['RFC'] = true,
		['script-journal'] = true,
		['season'] = true,
		['section'] = true,
		['sections'] = true,
		['series-link'] = true,
		['series-number'] = true,
		['series-separator'] = true,
		['sheet'] = true,
		['sheets'] = true,
		['SSRN'] = true,
		['station'] = true,
		['time'] = true,
		['time-caption'] = true,
		['trans-article'] = true,
		['trans-journal'] = true,
		['transcript'] = true,
		['transcript-format'] = true,
		['transcript-url'] = true,
		['ZBL'] = true,
		},
	['cite journal'] = {
		['agency'] = true,
		['air-date'] = true,
		['book-title'] = true,
		['chapter'] = true,
		['chapter-format'] = true,
		['chapter-url'] = true,
		['chapter-url-access'] = true,
		['class'] = true,
		['conference'] = true,
		['conference-format'] = true,
		['conference-url'] = true,
		['contribution'] = true,
		['contributor#'] = true,
		['contributor-first#'] = true,
		['contributor-link#'] = true,
		['contributor-mask#'] = true,
		['degree'] = true,
		['department'] = true,
		['display-interviewers'] = true,
		['docket'] = true,
		['edition'] = true,
		['editor#'] = true,
		['editor-first#'] = true,
		['editor-link#'] = true,
		['editor-mask#'] = true,
		['editors'] = true,
		['encyclopedia'] = true,
		['episode'] = true,
		['ignore-isbn-error'] = true,
		['interviewer#'] = true,
		['interviewer-first#'] = true,
		['interviewer-link#'] = true,
		['interviewer-mask#'] = true,
		['isbn'] = true,
		['ismn'] = true,
		['LCCN'] = true,
		['mailinglist'] = true,
		['message-id'] = true,
		['minutes'] = true,
		['network'] = true,
		['script-chapter'] = true,
		['season'] = true,
		['section'] = true,
		['sections'] = true,
		['series-link'] = true,
		['series-number'] = true,
		['series-separator'] = true,
		['sheet'] = true,
		['sheets'] = true,
		['station'] = true,
		['time'] = true,
		['time-caption'] = true,
		['trans-article'] = true,
		['transcript'] = true,
		['transcript-format'] = true,
		['transcript-url'] = true,
		},
	}

--[[-------------------------< A D D _ T O _ L I S T >---------------------------------------------------------

adds code/name pair to code_list and name/code pair to name_list; code/name pairs in override_list replace those
taken from the MediaWiki list; these are marked with a superscripted dagger.

|script-<param>= lang codes always use override names so dagger is omitted

]]

local function add_to_list (code_list, name_list, override_list, code, name, dagger)
	if false == dagger then
		dagger = '';															-- no dagger for |script-<param>= codes and names
	else
		dagger = '<sup>†</sup>';												-- dagger for all other lists using override
	end

	if override_list[code] then													-- look in the override table for this code
		code_list[code] = override_list[code] .. dagger;						-- use the name from the override table; mark with dagger
		name_list[override_list[code]] = code .. dagger;
	else
		code_list[code] = name;													-- use the MediaWiki name and code
		name_list[name] = code;
	end
end


--[[-------------------------< L I S T _ F O R M A T >---------------------------------------------------------

formats key/value pair into a string for rendering
	['k'] = 'v'	→ k: v

]]

local function list_format (result, list)
	for k, v in pairs (list)	do
		table.insert (result, k .. ': ' .. v);
	end
end


--[[-------------------------< L A N G _ L I S T E R >---------------------------------------------------------

Module entry point

Crude documentation tool that returns one of several lists of language codes and names.

Used in Template:Citation Style documentation/language/doc

{{#invoke:cs1 documentation support|lang_lister|list=<selector>|lang=<code>}}

where <selector> is one of the values:
	2char – list of ISO 639-1 codes and names sorted by code
	3char – list of ISO 639-2, -3 codes and names sorted by code
	ietf – list of IETF language tags and names sorted by tag -- partial support for these by cs1|2 |language= parameter
	name – list of language names and codes sorted by name -- IETF tags omitted because not supported by cs1|2 |language= parameter
	all - list all language codes/tags and names sorted by code/tag

where <code> is a MediaWiki supported 2, 3, or ietf-like language code; because of fall-back, language names may
be the English-language names.


]]

local function lang_lister (frame)
	local lang = (frame.args.lang and '' ~= frame.args.lang) and frame.args.lang or mw.getContentLanguage():getCode()
	local source_list = mw.language.fetchLanguageNames(lang, 'all');
	local override = cfg.lang_code_remap;
	local code_1_list={};
	local code_2_list={};
	local ietf_list={};
	local name_list={};
	
	if not ({['2char']=true, ['3char']=true, ['ietf']=true, ['name']=true, ['all']=true})[frame.args.list] then
		return '<span style="font-size:100%" class="error">unknown list selector: ' .. frame.args.list .. '</span>';
	end

	for code, name in pairs (source_list) do
		if 'all' == frame.args.list then
			add_to_list (code_1_list, name_list, override, code, name);			-- use the code_1_list because why not?
		elseif 2 == code:len() then
			add_to_list (code_1_list, name_list, override, code, name);
		elseif 3 == code:len() then
			add_to_list (code_2_list, name_list, override, code, name);
		else																	-- ietf codes only partically supported by cs1|2 |language= parameter
			add_to_list (ietf_list, name_list, override, code, name);
		end
	end
	
	local result = {};
	local out = {};

	if '2char' == frame.args.list or 'all' == frame.args.list then
		list_format (result, code_1_list);
	elseif '3char' == frame.args.list then
		list_format (result, code_2_list);
	elseif 'ietf' == frame.args.list then
		list_format (result, ietf_list);
	else																		--must be 'name'
		list_format (result, name_list);
	end
	
	table.sort (result);
	table.insert (result, 1, '<div class="div-col columns column-width" style="column-width:20em">');
	table.insert (out, table.concat (result, '\n*'));
	table.insert (out, '</div>');
	
	return table.concat (out, '\n');
end


--[[--------------------------< S C R I P T _ L A N G _ L I S T E R >------------------------------------------

Module entry point

Crude documentation tool that returns list of language codes and names supported by the various |script-<param>= parameters.

used in Help:CS1 errors

{{#invoke:cs1 documentation support|script_lang_lister}}

]]

local function script_lang_lister ()
	local lang_code_src = cfg.script_lang_codes ;								-- get list of allowed script language codes
	local override = cfg.lang_code_remap;
	local this_wiki_lang = mw.language.getContentLanguage().code;				-- get this wiki's language

	local code_list = {};														-- interim list of aliases
	local name_list={};															-- not used; defined here so that we can reuse add_to_list() 
	local out = {};																-- final output (for now an unordered list)
	
	for _, code in ipairs (lang_code_src) do									-- loop through the list of codes
		local name = mw.language.fetchLanguageName (code, this_wiki_lang);		-- get the language name associated with this code
		add_to_list (code_list, name_list, override, code, name, false);		-- name_list{} not used but provided so that we can reuse add_to_list(); don't add superscript dagger
	end
	
	local result = {};
	local out = {};

	list_format (result, code_list);

	table.sort (result);
	table.insert (result, 1, '<div class="div-col columns column-width" style="column-width:20em">');
	table.insert (out, table.concat (result, '\n*'));
	table.insert (out, '</div>');
	
	return table.concat (out, '\n');
end


--[[--------------------------< A L I A S _ L I S T E R >------------------------------------------------------

experimental code that lists parameters and their aliases.  Perhaps basis for some sort of documentation?

{{#invoke:cs1 documentation support|alias_lister}}

]]

local function alias_lister ()
	local alias_src = cfg.aliases;												-- get master list of aliases
	local key;																	-- key for k/v in a new table
	local list = {};															-- interim list of aliases
	local out = {};																-- final output (for now an unordered list)
	
	for _, aliases in pairs (alias_src) do										-- loop throu the master list of aliases
		if 'table' == type (aliases) then										-- table only when there are aliases
			for i, alias in ipairs (aliases) do									-- loop through all of the aliases
				if 1 == i then													-- first 'alias' is the canonical parameter name
					key = alias;												-- so it becomes the key in list
				else
					list[key] = list[key] and (list[key] .. ', ' .. alias) or alias;	-- make comma-separated list of aliases
					list[alias] = 'see ' .. key;								-- make a back reference from this alias to the canonical parameter
				end
			end
		end
	end
	
	for k, v in pairs (list) do													-- loop through the list to make a simple unordered list
		table.insert (out, table.concat ({'*', k, ': ', v}));
	end
	
	table.sort (out);															-- sort it
	return table.concat (out, '\010');											-- concatenate with \n
--	return (mw.dumpObject (list))
end


--[[--------------------------< C A N O N I C A L _ P A R A M _ L I S T E R >----------------------------------

experimental code that lists canonical parameter names.  Perhaps basis for some sort of documentation?

returns a comma separated, alpha sorted, list of the canonical parameters.  If given a template name, excludes
parameters listed in that template's exclusion_list[<template>]{} table (if a table has been defined).

{{#invoke:cs1 documentation support|canonical_param_lister|<template>}}

]]

local function canonical_param_lister (frame)
	local template = frame.args[1];
	if '' == template then
		template = nil;
	end

	if template then
		template = mw.text.trim (template:lower());
	end

	local alias_src = cfg.aliases;												-- get master list of aliases
	local id_src = cfg.id_handlers;												-- get master list of identifiers
	
	local list = {};															-- interim list of aliases
	local out = {};																-- final output (for now an unordered list)
	
	for _, aliases in pairs (alias_src) do										-- loop through the master list of aliases
		local name;
		if 'table' == type (aliases) then										-- table only when there are aliases
			name = aliases[1];													-- first member of an aliases table is declared canonical
		else
			name = aliases;														-- for those parameters that do not have any aliases, the parameter is declared canonical
		end

		if not template then													-- no template name, add this parameter
			table.insert (list, name);
		elseif not exclusion_lists[template] then								-- template name but no exclusion list
			table.insert (list, name);
		elseif not exclusion_lists[template][name] then							-- template name and exclusion list but name not in list
			table.insert (list, name);
		end
	end
	
	for k, ids in pairs (id_src) do												-- spin through the list of identifiers
		local name = id_src[k].parameters[1];									-- get the first (left-most) parameter name
		local access = id_src[k].custom_access;									-- get the access-icon parameter if it exists for this identifier
		if not template then													-- no template name
			table.insert (list, name);											-- add this parameter
			if access then
				table.insert (list, access);									-- add this access-icon parameter
			end
		elseif not exclusion_lists[template] then								-- template name but no exclusion list
			table.insert (list, name);
			if access then
				table.insert (list, access);
			end
		elseif not exclusion_lists[template][name] then							-- template name and exclusion list but name not in list
			table.insert (list, name);
			if access then
				table.insert (list, access);
			end
		end
	end
	
	for _, param in ipairs (list) do											-- loop through the list to make a simple unordered list
		table.insert (out, table.concat ({'*', param}));
	end
	
	local function comp( a, b )													-- used in following table.sort()
		return a:lower() < b:lower();
	end
	
	table.sort (out, comp);														-- sort the list
	return table.concat (out, '\010');											-- concatenate with \n
--	return (mw.dumpObject (list))
end


--[[--------------------------< C A N O N I C A L _ N A M E _ G E T >------------------------------------------

returns first (canonical) name when metaparameter is assigned a table of names
returns name when metaparameter is assigned a single name
returns empty string when metaparameter name not found in alias_src{}, id_src{}, or id_src[meta].custom_access

metaparameter <metaparam> is the key in Module:Citation/CS1 aliases{} table or id_handlers{} table.  Because access-icon
don't have <metaparam> keys, per se, we create pseudo <metaparam> keys by appending 'access' to the identifier <metaparam>:
	the <metaparam> for |doi-access= is, for the purposes of this function, DOIaccess, etc

Some lists of aliases might be better served when a particular alias is identified as the canonical alias for a 
particular use case.  If, for example, <metaparam> Perodical lists:
	'journal', 'magazine', 'newspaper', 'periodical', 'website', 'work'
that order works fine for {{cite journal}} documentation but doesn't work so well for {{cite magazine}}, {{cite news}},
or {{cite web}}.  So, for using this function to document {{cite magazine}} the returned value should be the
parameter best suited for that template so we can specify magazine in the override (frame.args[2])

While for this function, it would be just as simple to not use the function, this mechanism is implemented here 
to match similar functionality in alias_names_get() (there are slight differences)
	<override> must exist in the alias list
	does not apply to the access icon parameters (ignored - these have no aliases)

(and which would be best for {{cite news}}? |newspaper= or |work=? can't solve all of the worlds problems at once).

output format is controlled by |format=
	plain - renders in plain text in a <span> tag; may have id attribute
	para - renders as it would in {{para|<param>}}

{{#invoke:cs1 documentation support|canonical_name_get|<metaparam>|<override>|id=<attribute>|format=[plain|para]}}

]]

local function canonical_name_get (frame)
	local alias_src = cfg.aliases;												-- get master list of aliases
	local id_src = cfg.id_handlers;												-- get master list of identifiers
	local args = getArgs (frame);

	local name;
	local meta = args[1]
	local override = args[2];

	local access;																-- for id-access parameters
	if meta:match ('^(%u+)access') then											-- the metaparameter (which is not used in ~/Configuration) is id_handlers key concatenated with access: BIBCODEaccess
		meta, access = meta:gsub ('^(%u+)access', '%1');						-- strip 'access' text from meta and use returned count value as a flag
	end

	if alias_src[meta] then
		name = alias_src[meta];													-- name is a string or a table
		if 'table' == type (name) then											-- table only when there are aliases
			if not override then
				name = name[1];													-- first member of an aliases table is declared canonical
			else
				for _, v in ipairs (name) do									-- here when override is set; spin throu the aliases to make sure override matches alias in table
					if v == override then
						name = v;												-- declare override to be the canonical param for this use case
						break;
					end
				end
			end
		end

	elseif id_src[meta]then														-- if there is an id handler
		if access then															-- and if this is a request for the handler's custom access parameter
			if id_src[meta].custom_access then									-- if there is a custom access parameter
				name = id_src[meta].custom_access;								-- use it
			else
				return '';														-- nope, return empty string
			end
		else
			if not override then
				name = id_src[meta].parameters[1];								-- get canonical id handler parameter
			else
				for _, v in ipairs (id_src[meta].parameters) do					-- here when override is set; spin throu the aliases to make sure override matches alias in table
					if v == override then
						name = v;												-- declare override to be the canonical param for this use case
						break;
					end
				end
			end
		end
	else
		return '';																-- metaparameter not specified, or no such metaparameter
	end
	
	if 'plain' == args.format then												-- format and return the output
		if args.id then
			return string.format ('<span id="%s">%s</span>', args.id, name);	-- plain text with id attribute
		else
			return name;														-- plain text
		end
	elseif 'para' == args.format then
		return string.format ('<code class="nowrap">|%s=</code>', name);		-- same as {{para|<param>}}
	end

	return string.format ('<b id="%s">%s</b>', args.id or '', name);			-- because {{csdoc}} bolds param names
end


--[[--------------------------< A L I A S _ N A M E S _ G E T >------------------------------------------------

returns list of aliases for metaparameter <metaparam>
returns empty string when there are no aliases
returns empty string when <metaparam> name not found in alias_src{} or id_src{}; access icon parameters have no aliases so ignored

metaparameter <metaparam> is the key in Module:Citation/CS1 aliases{} table or id_handlers{} table.

Some lists of aliases might be better served when a particular alias is identified as the canonical alias for a 
particular use case.  If, for example, <metaparam> Perodical lists:
	'journal', 'magazine', 'newspaper', 'periodical', 'website', 'work'
that order works fine for {{cite journal}} documentation but doesn't work so well for {{cite magazine}}, {{cite news}},
or {{cite web}}.  So, for using this function to document {{cite magazine}} the returned value should be the
aliases that are not best suited for that template so we can specify magazine in the override (frame.args[2])
to be the canonical parameter so it won't be listed with the rest of the aliases (normal canonical journal will be)

	<override> must exist in the alias list except:
		when <override> value is 'all', returns the canonical parameter plus all of the aliases

output format is controlled by |format=
	plain - renders in plain text in a <span> tag; may have id attribute
	para - renders as it would in {{para|<param>}}
	when not specified, refurns the default bold format used for {{csdoc}}

{{#invoke:cs1 documentation support|alias_name_get|<metaparam>|<override>|format=[plain|para]}}

]]

local function alias_names_get (frame)
	local alias_src = cfg.aliases;												-- get master list of aliases
	local id_src = cfg.id_handlers;												-- get master list of identifiers
	local args = getArgs (frame);
	
	local meta = args[1];
	local override = args[2];

	local out = {};
	local source;																-- selected parameter or id aliases list
	local aliases;

	source = alias_src[meta] or (id_src[meta] and id_src[meta].parameters);
	if not source then
		if meta:match ('%u+access') then
			return 'no' == args.none and '' or 'none';							-- custom access parameters don't have aliases
		else
			return '';															-- no such meta
		end
	elseif not source[2] then													-- id_source[meta] is always a table; if no second member, no aliases
		return 'no' == args.none and '' or 'none';
	end
	
	if not override then
		aliases = source;														-- normal skip-canonical param case
	else
		local flag = 'all' == override and true or nil;							-- so that we know that <override> parameter is a valid alias; spoof when override == 'all'
		aliases = {[1] = ''};													-- spoof to push alias_src[meta][1] and id_src[meta][1] into aliases[2]
		for _, v in ipairs (source) do											-- here when override is set; spin through the aliases to make sure override matches alias in table
			if v ~= override then
				table.insert (aliases, v);										-- add all but overridden param to the the aliases list for this use case
			else
				flag = true;													-- set the flag so we know that <override> is a valid alias
			end
		end
		if not flag then
			aliases = {}														-- unset the table as error indicator
		end
	end

	if 'table' == type (aliases) then											-- table only when there are aliases
		for i, alias in ipairs (aliases) do
			if 1 ~= i then														-- aliases[1] is the canonical name; don't include it
				if 'plain' == args.format then									-- format and return the output
					table.insert (out, alias);									-- plain text
				elseif 'para' == args.format then
					table.insert (out, string.format ('<code class="nowrap">|%s=</code>', alias));	-- same as {{para|<param>}}
				else
					table.insert (out, string.format ("'''%s'''", alias));		-- because csdoc bolds param names
				end
			end
		end
		
		return table.concat (out, ', ');										-- make pretty list and quit
	end

	return 'no' == args.none and '' or 'none';									-- no metaparameter with that name or no aliases
end


--[[--------------------------< I S _ B O O K _ C I T E _ T E M P L A T E >------------------------------------

fetch the title of the current page; if it is a preprint template, return true; empty string else

]]

local book_cite_templates = {
	['citation'] = true,
	['cite book'] = true,
	}

local function is_book_cite_template ()
	local title = mw.title.getCurrentTitle().rootText;							-- get title of current page without namespace and without sub-pages; from Template:Cite book/new -> Cite book
	
	title = title and title:lower() or '';
	return book_cite_templates[title] or '';
end


--[[--------------------------< I S _ L I M I T E D _ P A R A M _ T E M P L A T E >----------------------------

fetch the title of the current page; if it is a preprint template, return true; empty string else

]]

local limited_param_templates = {												-- if ever there is a need to fetch info from ~/Whitelist then
	['cite arxiv'] = true,														-- this list could also be fetched from there
	['cite biorxiv'] = true,
	['citeseerx'] = true,
	['ssrn'] = true,
	}

local function is_limited_param_template ()
	local title = mw.title.getCurrentTitle().rootText;							-- get title of current page without namespace and without sub-pages; from Template:Cite book/new -> Cite book
	
	title = title and title:lower() or '';
	return limited_param_templates[title] or '';
end


--[[--------------------------< H E A D E R _ M A K E >--------------------------------------------------------

makes a section header from <header_text> and <level>; <level> defaults to 2; cannot be less than 2

]]

local function _header_make (args)
	if not args[1] then
		return '';																-- no header text
	end
	
	local level = args[2] and tonumber (args[2]) or 2;
	
	level = string.rep ('=', level);
	return level .. args[1] .. level;
end


--[[--------------------------< H E A D E R _ M A K E >--------------------------------------------------------

Entry from an {{#invoke:}}
makes a section header from <header_text> and <level>; <level> defaults to 2; cannot be less than 2

]]

local function header_make (frame)
	local args = getArgs (frame);
	return _header_make (args);
end


--[[--------------------------< I D _ L I M I T S _ G E T >----------------------------------------------------

return the limit values for named identifier parameters that have <id> limits (pmc, pmid, ssrn, s2cid); the return
value used in template documentation and error message help-text

{{#invoke:Cs1 documentation support|id_limits_get|<id>}}

]]

local function id_limits_get (frame)
	local args = getArgs (frame);
	local handlers = cfg.id_handlers;											-- get id_handlers {} table from ~/Configuration

	return args[1] and handlers[args[1]:upper()].id_limit or '';
end


--[[--------------------------< C A T _ L I N K _ M A K E >----------------------------------------------------
]]

local function cat_link_make (cat)
	return table.concat ({'[[:Category:', cat, ']]'});
end


--[[--------------------------< C S 1 _ C A T _ L I S T E R >--------------------------------------------------

This is a crude tool that reads the category names from Module:Citation/CS1/Configuration, makes links of them,
and then lists them in sorted lists.  A couple of parameters control the rendering of the output:
	|select=	-- (required) takes one of three values: error, maint, prop
	|sandbox=	-- takes one value: no
	|hdr-lvl=	-- base header level (number of == that make a header); default:2 min:2

This tool will automatically attempt to load a sandbox version of ~/Configuration if one exists.
Setting |sandbox=no will defeat this.

{{#invoke:cs1 documentation support|cat_lister|select=<error|maint|prop>|sandbox=<no>}}

]]

local function cat_lister (frame)
	local args = getArgs (frame);

	local list_live_cats = {};													-- list of live categories
	local list_sbox_cats = {};													-- list of sandbox categories
	
	local live_sbox_out = {}													-- list of categories that are common to live and sandbox modules
	local live_not_in_sbox_out = {}												-- list of categories in live but not sandbox
	local sbox_not_in_live_out = {}												-- list of categories in sandbox but not live
	
	local out = {};																-- final output assembled here
	
	local sandbox;																-- boolean; true: evaluate the sandbox module
	local hdr_lvl;																-- 
	
	local sb_cfg;
	local sandbox, sb_cfg = pcall (mw.loadData, 'Module:Citation/CS1/Configuration/sandbox');	-- get sandbox configuration

	local cat;

	local select = args.select;
	if 'no' == args.sandbox then												-- list sandbox?
		sandbox = false;														-- no, live only
	end
	if hdr_lvl then																-- if set and
		if tonumber (hdr_lvl) then												-- can be converted to number
			if 2 > tonumber (hdr_lvl) then										-- min is 2
				hdr_lvl = 2;													-- so set to min
			end
		else																	-- can't be converted
			hdr_lvl = 2;														-- so default to min
		end
	else
		hdr_lvl = 2;															-- not set so default to min
	end

	if 'error' == select or 'maint' == select then								-- error and main categorys handling different from poperties cats
		for _, t in pairs (cfg.error_conditions) do								-- get the live module's categories
			if ('error' == select and t.message) or ('maint' == select and not t.message) then
				cat = t.category:gsub ('|(.*)$', '');							-- strip sort key if any
				list_live_cats[cat] = 1;										-- add to the list
			end
		end
		
		if sandbox then															-- if ~/sandbox module exists and |sandbox= not set to 'no'
			for _, t in pairs (sb_cfg.error_conditions) do						-- get the sandbox module's categories
				if ('error' == select and t.message) or ('maint' == select and not t.message) then
					cat = t.category:gsub ('|(.*)$', '');						-- strip sort key if any
					list_sbox_cats[cat] = 1;									-- add to the list
				end
			end
		end
		
	elseif 'prop' == select then												-- prop cats
		for _, cat in pairs (cfg.prop_cats) do									-- get the live module's categories
			cat = cat:gsub ('|(.*)$', '');										-- strip sort key if any
			list_live_cats[cat] = 1;											-- add to the list
		end

		if sandbox then															-- if ~/sandbox module exists and |sandbox= not set to 'no'
			for _, cat in pairs (sb_cfg.prop_cats) do							-- get the live module's categories
				cat = cat:gsub ('|(.*)$', '');									-- strip sort key if any
				list_sbox_cats[cat] = 1;										-- add to the list
			end
		end
	else
		return '<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: unknown selector: ' .. select .. '</span>'
	end	

	for k, _ in pairs (list_live_cats) do										-- separate live/sbox common cats from cats not in sbox
		if not list_sbox_cats[k] and sandbox then
			table.insert (live_not_in_sbox_out, cat_link_make (k));				-- in live but not in sbox
		else
			table.insert (live_sbox_out, cat_link_make (k));					-- in both live and sbox
		end
	end

	for k, _ in pairs (list_sbox_cats) do										-- separate sbox/live common cats from cats not in live
		if not list_live_cats[k] then
			table.insert (sbox_not_in_live_out, cat_link_make (k));				-- in sbox but not in live
		end
	end

	local function comp (a, b)													-- local function for case-agnostic category name sorting
		return a:lower() < b:lower();
	end

	local header;																-- initialize section header with name of selected category list
	if 'error' == select then
		header = 'error';
	elseif 'maint' == select then
		header = 'maintenance';
	else
		header = 'properties';
	end
	
	header = table.concat ({													-- build the main header
		'Live ',																-- always include this
		((sandbox and 'and sandbox ') or ''),									-- if sandbox evaluated, mention that
		header,																	-- add the list name
		' categories (',														-- finish the name and add
		#live_sbox_out,															-- count of categories listed
		')'																		-- close
	})

	header = table.concat ({													-- make a useable header
		_header_make ({header, hdr_lvl}),
		'\n<div class="div-col columns column-width" style="column-width:30em">'	-- opening <div> for columns
		});

	table.sort (live_sbox_out, comp);											-- sort case agnostic acsending
	table.insert (live_sbox_out, 1, header);									-- insert the header at the top
	table.insert (out, table.concat (live_sbox_out, '\n*'));					-- make a big string of unordered list markup
	table.insert (out, '</div>\n');												-- close the </div> and add new line so the next header works

	if 0 ~= #live_not_in_sbox_out then											-- when there is something in the table
		header = table.concat ({												-- build header for subsection
			'In live but not in sandbox (',
			#live_not_in_sbox_out,
			')'
			});
	
		header = table.concat ({												-- make a useable header
			_header_make ({header, hdr_lvl+1}),
			'\n<div class="div-col columns column-width" style="column-width:30em">'
			});
	
		table.sort (live_not_in_sbox_out, comp);
		table.insert (live_not_in_sbox_out, 1, header);
		table.insert (out, table.concat (live_not_in_sbox_out, '\n*'));
		table.insert (out, '</div>\n');
	end
	
	if 0 ~= #sbox_not_in_live_out then											-- when there is something in the table
		header = table.concat ({												-- build header for subsection
			'In sandbox but not in live (',
			#sbox_not_in_live_out,
			')'
			});
	
		header = table.concat ({												-- make a useable header
			_header_make ({header, hdr_lvl+1}),
			'\n<div class="div-col columns column-width" style="column-width:30em">'
			});
	
		table.sort (sbox_not_in_live_out, comp);
		table.insert (sbox_not_in_live_out, 1, header);
		table.insert (out, table.concat (sbox_not_in_live_out, '\n*'));
		table.insert (out, '</div>\n');
	end

	return table.concat (out);													-- concat into a huge string and done
end


--[[-------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	alias_lister = alias_lister,
	alias_names_get = alias_names_get,
	canonical_param_lister = canonical_param_lister,
	canonical_name_get = canonical_name_get,
	cat_lister = cat_lister,
	header_make = header_make,
	id_limits_get = id_limits_get,
	is_book_cite_template = is_book_cite_template,
	is_limited_param_template = is_limited_param_template,
	lang_lister = lang_lister,
	script_lang_lister = script_lang_lister,
	};