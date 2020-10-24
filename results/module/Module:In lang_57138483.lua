require ('Module:No globals');


--[[--------------------------< _ I N _ L A N G >--------------------------------------------------------------

implements {{in lang}}

Module entry point from another module

|link=yes - creates wikilinked language names
|template=<template name> - customizes error messages created by Module:lang
|list-cats=yes - documentation tool returns language-category names of cats populated by this template

<span class="languageicon">(in <language>)</span>

]]

local function _in_lang (args)
	local synonym_table = mw.loadData ('Module:Lang/ISO 639 synonyms');			-- ISO 639-2/639-2T code translation to 639-1 code
	local list_cats = 'yes' == args['list-cats'];								-- make a boolean
	local list = {};
	local cats = {};
	local maint_msgs = {};
	
	if not args[1] then
		local template = (args['template'] and table.concat ({'{{', args['template'], '}}: '})) or '';	-- make template name (if provided by the template)
		return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: ', template, 'missing language tag</span>'});
	end

	local module = 'Module:Lang' .. (mw.getCurrentFrame():getTitle():match ('/sandbox') or '');	-- if this module is the sandbox,

	local name_from_tag = require (module)._name_from_tag;						-- use Module:Lang/sandbox; Module:Lang else

	local namespace = mw.title.getCurrentTitle().namespace;						-- used for categorization
	local this_wiki_lang = mw.language.getContentLanguage().code;				-- get this wiki's language code

	for i, lang in ipairs (args) do
		local code = args[i]:lower();
		local t = {code, ['link'] = args['link'], ['template'] = args['template']};	-- build an 'args' table
		lang = name_from_tag (t)												-- get the language name
		table.insert (list, lang)												-- add this language or error message to the list

		if 'ca-valencia' ~= code then											-- except for valencian
			code = code:match ('^%a%a%a?%f[^%a]');								-- strip off region, script, and variant tags so that they aren't used to make category names
		end
		if synonym_table[code] then												-- if 639-2/639-2T code has a 639-1 synonym
			if (0 == namespace) and not list_cats then							-- when listing cats don't include this cat; TODO: right choice?
				table.insert (cats, table.concat ({'[[Category:Lang and lang-xx code promoted to ISO 639-1|', code ..']]'}));
			end
			table.insert (maint_msgs, ' <span class="lang-comment" style="font-style:normal; display:none; color:#33aa33; margin-left:0.3em">')
			table.insert (maint_msgs, table.concat ({'code: ', code, ' promoted to code: ', synonym_table[code]}));
			table.insert (maint_msgs, '</span>;');
			code = synonym_table[code];											-- use the synonym
		end

		if (0 == namespace) or list_cats then												-- when in article space
			if lang:find ('error') then											-- add error category (message provided by Module:Lang)
				if not list_cats then											-- don't include this cat when listin cats; TODO: right choice?
					table.insert (cats, '[[Category:in lang template errors]]');
				end
			elseif this_wiki_lang ~= code then									-- categorize article only when code is not this wiki's language code
				if lang:match ('%[%[.-|.-%]%]') then							-- wikilinked individual language name
					lang = lang:match ('%[%[.-|(.-)%]%]');
				elseif lang:match ('%[%[.-%]%]') then							-- wikilinked collective languages name
					lang = lang:match ('%[%[(.-)%]%]');
				end																-- neither of these then plain-text language name

				if lang:find ('languages') then									-- add appropriate language-name category
					table.insert (cats, table.concat ({'[[Category:Articles with ', lang, '-collective sources (', code, ')]]'}));
				else
					table.insert (cats, table.concat ({'[[Category:Articles with ', lang, '-language sources (', code, ')]]'}));
				end
			end
		end
	end
	
	if list_cats then
		local cats = table.concat (cats, ', '):gsub ('[%[%]]', '');				-- make a string of categories and then strip wikilink markup
		return cats
	end

	local result = {'<span class="languageicon">('};							-- opening span and (
	table.insert (result, 'yes' == args['cap'] and 'In ' or 'in ');				-- add capitalized or uncapitalized 'in'
	table.insert (result, mw.text.listToText (list, ', ', (2 < #list) and ', and ' or ' and ' ));	-- and concatenate the language list

	table.insert (result, ')</span>');											-- add closing ) and closing span
	table.insert (result, table.concat (maint_msgs) or '');				-- add maint messages, if any
	table.insert (result, table.concat (cats));									-- add categories
	return table.concat (result);												-- make a big string and done
end


--[[--------------------------< I N _ L A N G >----------------------------------------------------------------

implements {{in lang}}

Module entry point from an {{#invoke:lang/utilities/sanbox|in_lang|<code>|<code2>|<code3>|<code...>|link=yes|template=in lang|list-cats=yes}}

]]

local function in_lang (frame)
	local args = require ('Module:Arguments').getArgs (frame);
	return _in_lang (args);
	end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	in_lang = in_lang,															-- module entry from {{#invoke:}}

	_in_lang = _in_lang,														-- module entry from another module
	}