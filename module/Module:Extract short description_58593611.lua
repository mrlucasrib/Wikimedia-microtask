require('Module:No globals');

--[[--------------------------< E X T R A C T _ F R O M _ T E M P L A T E >------------------------------------

no direct template access

extracts short description text from a named template in the named article when that template is found in article
wiki source

requires three arguments:
	frame: frame object required to preprocess template_name
	article_title: the name of the article to inspect - correct spelling and captialization is required
	template_names_tbl: a single template name (a string) or a table of one or more template names all without
		namespace to be inspected - correct spelling and captialization is required

returns two values:
	on success, returns the short description text and true
	on failure, returns error message and nil

]]

local function extract_from_template (frame, article_title, template_names_tbl)
	local content = mw.title.new (article_title):getContent();					-- read the unparsed article source
	if not content then
		return '<span style="font-size:100%;" class="error">error: no article: ' .. article_title .. '</span>';
	end

	local template_name_pattern;
	local start;
	
	if 'string' == type (template_names_tbl) then								-- when single template name passed in as a string
		template_names_tbl = {template_names_tbl};								-- convert to a table
	end
	
	local templateName
	for _, template_name in ipairs (template_names_tbl) do						-- loop through the name in the table
		template_name_pattern = template_name:gsub ('^%a', string.lower):gsub ('^%a', '%[%1%1%]'):gsub ('%[%a', string.upper);	-- make lua pattern for initial letter upper or lower case: A -> [Aa]
		start = content:find ('{{%s*' .. template_name_pattern);				-- find the start of {{template name ...;
		if start then
			templateName = template_name
			break;																-- found a matching template
		end
	end

	if not start then															-- no templates found: return name of first template in template_names_tbl in error message
		return '<span style="font-size:100%;" class="error">error: no template: ' .. template_names_tbl[1] .. ' in: ' .. article_title .. '</span>';
	end

	local text = string.match (content, '%b{}', start);							-- start points to first { of the templateName
	if not text then
		return '<span style="font-size:100%;" class="error">error: failed to extract template: ' .. templateName .. '</span>';
	end

	text = text:gsub ('<ref[^>]->[^<]-</ref>', '');								-- delete references before preprocessing; they do not belong in shortdesc text
	text = text:gsub ('<ref[^>]-/ *>', '');										-- also delete self-closed named references
	text = text:gsub ('{{%s*sfn[^}]-}}', '');									-- delete sfn template which make references using {{#tag:}} parser functions
	text = text:gsub ('{{#tag:ref[^}]-}}', '');									-- and delete these too

	text = frame:preprocess (text):match ('<div[^>]-class="shortdescription.->(.-)</div>');		-- preprocess and extract shortdescription text
	if not text then
		return '<span style="font-size:100%;" class="error">error: no short description text in: ' .. templateName .. ' in '.. article_title .. '</span>';
	end

	return mw.text.trim (text), true;											-- trim whitespace and done
																				-- preprocess the template then apply syntax highlighting
																				-- this will display the preprocessed template; not usable here
																				-- for much other than debugging because syntaxhighlight returns a stripmarker
--	return template_name .. frame:callParserFunction ('#tag:syntaxhighlight', frame:preprocess (text));
end


--[[--------------------------< E X T R A C T _ F R O M _ A R T I C L E >--------------------------------------

no direct template access

extracts short description text from {{short description}} template when that template is found in article wiki
source; searches for both the long name (short description) and the short-name redirect (SHD); if both are present
long name controls; if multiples of the same name are present, the first-found controls.

requires one argument: article_title is the name of the article to be inspected

on success, returns the short description text; error message else

]]

local function extract_from_article (article_title)
	local content = mw.title.new (article_title):getContent();					-- read the unparsed article source
	if not content then
		return '<span style="font-size:100%;" class="error">error: no article: ' .. article_title .. '</span>';
	end

	local text, start;
	
	start = string.find (content, '{{%s*[Ss]hort description') or				-- find the start of {{Short description}} template
		string.find (content, '{{%s*SHD');										-- not full name, try the {{SHD}} redirect

	if not start then
		return '<span style="font-size:100%;" class="error">error: no short description in: ' .. article_title .. '</span>';
	end

	text = content:match ('%b{}', start);										-- get the short description template; start points to first { of the template
	if not text then
		return '<span style="font-size:100%;" class="error">error: failed to extract short description template from ' .. article_title .. '</span>';
	end

	text = text:match ('^[^|}]+|%s*(.+)%s*}}$');								-- strip '{{template name|' and '}}'; trim leading and trailing whitespace
	
	return text and text or '<span style="font-size:100%;" class="error">error: no short description text in: ' .. article_title .. '</span>';
end


--[[--------------------------< E X T R A C T _ S H O R T _ D E S C R I P T I O N >----------------------------

template entry point:
	{{#invoke:extract short description|extract_short_description}}

search for and return text that is used by the {{short description}} template.  {{Short description}}, also {{SHD}}
may be located in article wikisource or embedded in a template (commonly an infobox template).  When neither of
|template= and {{{2|}}} are set, this code will look in the article wiki source; when set, this code look inside the
named template.

This template entry takes two parameters:
	{{{1}}} or |article=: required; name of wiki article from which to extract the short description
	{{{2}}} or |template=; optional; name of template that holds the {{short description}} template

on success, returns the short description text; error message else

]]

local function extract_short_description (frame)
	local getArgs = require('Module:Arguments').getArgs;
	local args = getArgs(frame);
	
	if args[1] and args.article then											-- both assigned, fail with an error message
		return '<span style="font-size:100%;" class="error">error: conflicting |{{{1}}} and |article= parameters</span>';
	end
	
	local article_title = args[1] or args.article;								-- the required parameter
	
	if not article_title then													-- not supplied, fail with an error message
		return '<span style="font-size:100%;" class="error">error: article title required</span>';
	end
	
	local template_name = args[2] or args.template;								-- optional
	
	if template_name then
		local text, _ = extract_from_template (frame, article_title, template_name);	-- ignore second return value
		return text;
	else
		return extract_from_article (article_title);
	end
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	extract_short_description = extract_short_description,
	extract_from_template = extract_from_template,
	extract_from_article = extract_from_article,
	}