require('Module:No globals');

local getArgs = require ('Module:Arguments').getArgs;
local mRedirect = require ('Module:Redirect')
	
local namespaces = {															-- includes namespace aliases - these are case insensitive
	['HELP'] = 'Help',															-- canonical namespaces
	['WIKIPEDIA'] = 'WP',

	['PROJECT'] = 'Project',													-- namespace aliases
	['WP'] = 'WP',
	['H'] = 'Help',
	['MOS'] = 'MOS',
	}


--[[--------------------------< E S C A P E _ L U A _ M A G I C _ C H A R S >----------------------------------

Returns a string where all of lua's magic characters have been escaped.  This is important because functions like
string.gsub() treat their pattern and replace strings as patterns, not literal strings.

]]

local function escape_lua_magic_chars (argument)
	argument = argument:gsub("%%", "%%%%");										-- replace % with %%
	argument = argument:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1");				-- replace all other lua magic pattern characters
	return argument;
end


--[[--------------------------< E R R >------------------------------------------------------------------------

returns formatted error message that is less strident than error() or standard MediaWiki error messages

TODO: add link to template page for help text

]]

local function err (error_msg)
	return '<span class="error" style="font-size:100%">' .. error_msg .. ' ([[Template:WP|help]])</span>';		-- tamer, less strident error messages
end


--[[--------------------------< G E T _ C O N T E N T >--------------------------------------------------------

get content from <title> page.  On error, use <label> in returned message to identify failing event in the process

returns:
	<content>, nil – expected returns
	nil, msg – <title> not a valid title
	nil, msg – <title> does not exist
	nil, msg – <title> is empty

]]

local function get_content (title, label)
	local content;
	local title_obj = mw.title.new (title);										-- get title object for <title>
	if not title_obj then														-- title object for non-existent valid <title> will have been created; nil else
		return nil, label .. ': invalid title: ' .. title;						-- return nil when <title> is malformed (not a valid title)
	end

	content = title_obj:getContent();											-- get content 
	if not content then
		return nil, label .. ': page does not exist: ' .. title;				-- return nil when <title> does not exist
	elseif '' == content then
		return nil, label .. ': page is empty: ' .. title;						-- return nil when <title> has no content
	end
	
	return content;
end


--[=[-------------------------< W I K I L I N K _ S T R I P >--------------------------------------------------

Wikilink markup does not belong in an anchor id and can / does confuse the code that parses apart citation and
harvc templates so here we remove any wiki markup:
	[[link|label]] -> label
	[[link]] -> link

]=]

local function wikilink_strip(text)
	for wikilink in text:gmatch('%[%b[]%]') do									-- get a wikilink
		text = text:gsub('%[%b[]%]', '__57r1P__', 1);							-- install a marker
		if wikilink:match ('^%[%[%s*[Ff]ile:') or wikilink:match ('^%[%[%s*[Ii]mage:') then	-- if this wikilink is an image
			wikilink = '[IMAGE]';												-- can't display it in a tooltip so use a word; TODO: parse out alt text or caption? worth the effort?
		elseif wikilink:match('%[%[.-|(.-)%]%]') then
			wikilink = wikilink:match('%[%[.-|(.-)%]%]');						-- extract label from complex [[link|label]] wikilink
		else
			wikilink = wikilink:match('%[%[(.-)%]%]');							-- extract link from simple [[link]] wikilinks
		end
		wikilink = escape_lua_magic_chars(wikilink);							-- in case there are lua magic characters in wikilink
		text = text:gsub('__57r1P__', wikilink, 1);								-- replace the marker with the appropriate text
	end

	return text;
end


--[[--------------------------< T I T L E _ M A K E >----------------------------------------------------------

makes a prefix for the tooltip from {{nutshell}} |title= parameter value, if present, pagename else

Because we are evaluating the content of pagename, we set the frag_flag here when the pagename
has an anchor fragment (<namespace>:<pagename>#<anchor>)

]]

local function title_make (title_param, pagename)
	local frag_flag;
	local c;
	local namespace;
	
	pagename, c = pagename:gsub ('#.*$', '');									-- remove section fragment if any
	if 0 < c then
		frag_flag = true;														-- when fragment removed, set the flag
	end

	namespace = pagename:match ('^%a+'):upper();								-- extract canonical namespace; convert to upper case for indexing
	pagename = pagename:gsub ('^%a+', namespaces[namespace]);					-- replace with abbreviation

	if '' == title_param then
		title_param = '&quot;' .. pagename .. '&quot;';							-- use name of shortcut's target page when |title= missing or empty
	end

	return title_param, frag_flag;
end


--[[--------------------------< T O O L T I P _ M A K E >------------------------------------------------------

assemble the tooltip (title= attribute value)

]]

local function tooltip_make (title_param, nutshell, frag_flag)
	return table.concat ({
		title_param,															-- the tooltip prefix (usually WP: article name)
		('' ~= nutshell and ' in a nutshell: ' or ''),							-- when there is nutshell text
		nutshell,
		(frag_flag and ' (subsection link)' or ''),								-- when WP: article name has a fragment
		});
end


--[[--------------------------< N U T S H E L L _ T E X T _ G E T >--------------------------------------------

gets text from {{nutshell}} (or redirect) template in shortcut's target page; frame included as argument here
so that this function has access to frame:preprocess()

shortcut is shortcut name with a namespace prefix (WP:BOLD, MOS:MED, H:CS1, etc)

]]

local function nutshell_text_get (shortcut, frame)
	local content;																-- content of shortcut page then content of target
	local target;																-- name of shortcut's redirect target
	local msg;																	-- error messages go here
	local c;																	-- general purpose var holds the tally of gsub() replacements made when needed
	local title_param;															-- {{nutshell}} |title= parameter contents and value used in tooltip rendering
	local frag_flag;															-- boolean set true when normalized page name has a fragment (WP:<page title>#<anchor name>)

	content, msg = get_content (shortcut, 'shortcut');							-- get content of shortcut redirect page
	if msg then
		return nil, msg;
	end
	
	target = mRedirect.getTargetFromText (content);								-- get redirect <target title> (page name) from content of redirect page: (#Redirect [[<target title>]]) or nil
	if not target then
		return nil, 'shortcut: ' .. shortcut .. ' is not a redirect';
	end
	
	content, msg = get_content (target, 'target');								-- get content of redirect target
	if msg then
		return nil, msg;
	end

	local templatePatterns = {
		"{{%s*[Nn]utshell%s*|",
		"{{%s*[Pp]olicy in a nutshell%s*|",
		"{{%s*[Pp]olicy proposal in a nutshell%s*|",
		"{{%s*[Ii]n a nutshell%s*|",
		"{{%s*[Ii]nanutshell%s*|",
		"{{%s*[Gg]uideline in a nutshell%s*|",
		"{{%s*[Gg]uideline one liner%s*|",
		"{{%s*[Nn]aming convention in a nutshell%s*|",
		"{{%s*[Nn]utshell2%s*|",
		"{{%s*[Pp]roposal in a nutshell%s*|",
		"{{%s*[Ee]ssay in a nutshell%s*|"
		}
	
	local nutshell
	for i, pattern in ipairs (templatePatterns) do
		local pos = mw.ustring.find (content, pattern)
		
		if pos then
			nutshell = mw.ustring.match (content, '%b{}', pos)
			break
		end
	end
	
	if not nutshell then														-- nil when there is no recognized nutshell template
		title_param, frag_flag = title_make ('', target);
		return tooltip_make (title_param, '', frag_flag);						-- nutshell doesn't exist so empty string for concatenation
	end
																				-- begin template disassembly - order is important here - rare case where |title= holds a template
	nutshell = nutshell:gsub ('^{{[%w%s]*|', ''):gsub ('}}$', '');				-- remove opening {{ and template name then remove closing }}

	for t in nutshell:gmatch('%b{}') do											-- get an embedded template
		nutshell = nutshell:gsub('%b{}', '__57r1P__', 1)						-- install a marker
		local replacement = frame:preprocess (t);								-- get the template's rendering
		replacement = escape_lua_magic_chars(replacement);						-- in case there are lua magic characters in replacement
		nutshell = nutshell:gsub('__57r1P__', replacement, 1)					-- replace the marker with the appropriate text
	end

	nutshell = wikilink_strip (nutshell);										-- remove wikilinks
	
	title_param = nutshell:match ('|%s*title%s*=%s*([^|]+)') or '';				-- get title text or an empty string
	title_param = mw.text.trim (title_param);									-- remove extraneous leading / trailing whitespace

	title_param, frag_flag = title_make (title_param, target);					-- get content from {{nutshell}} |title= param if present, else concot a title

	nutshell = nutshell:gsub ('|%s*title%s*=%s*[^|]*', '');						-- remove title parameter and value; TODO: these two can be made one?
	nutshell = nutshell:gsub ('|%s*shortcut%d*%s*[^|]*', '');					-- remove all shortcut parameters and their values

	nutshell, c = nutshell:gsub ('%s*|%s*', ' *');								-- replace pipes and get a tally
	if 0 < c then
		nutshell = '*' .. nutshell;												-- if any pipes were replaced, prefix with a splat
	end

	nutshell = nutshell:gsub ('"', '&quot;'):gsub ('%b<>', '');					-- convert double quote characters to html entities then remove html-like tags
																				-- end template disassembly
	return tooltip_make (title_param, nutshell, frag_flag);
end


--[[--------------------------< M A I N >----------------------------------------------------------------------

template entry point

{{#invoke:Nutshell|main|<shortcut>}} where <shortcut> is shortcut name with or without namespace prefix; BOLD or WP:BOLD

]]

local function main (frame)
	local args = getArgs (frame);												-- get a table of arguments
	local out = {};
	local shortcut = args[1];													-- TODO: error check this; no point in continuing without properly formed shortcut

	if not shortcut or '' == shortcut then
		return err ('no shortcut name given');
	end

	local namespace, rest = shortcut:match ('^(%a+)(:%w+)');
	if namespace then
		namespace = namespace:upper();
		if not namespaces[namespace] then
			return err ('namespace \'' .. namespace .. '\' not recognized in shortcut: ' .. shortcut);
		else
			shortcut = namespaces[namespace] .. rest;
		end
	else
		shortcut = 'WP:' .. shortcut;											-- add WP: namespace
	end

	local nutshell, error_msg = nutshell_text_get (shortcut, frame);			-- pass frame so that nutshell_text_get() has access to frame:preprocess()
	if error_msg then
		return err (error_msg);
	end
	
	table.insert (out, '[[');													-- open wikilink
	table.insert (out, shortcut);												-- add shortcut
	if nutshell then
		table.insert (out, '|<span title="');									-- pipe, then start the opening span
		table.insert (out, nutshell);											-- add nutshell text
		table.insert (out, '" class="rt-commentedText" style="border-bottom:1px dotted">');	--finish the opening span
		table.insert (out, shortcut);											-- add shortcut
		table.insert (out, '</span>');											-- close the span
	end
	table.insert (out, ']]');													-- close the wikilink

	return table.concat (out);													-- concatenate and done
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	main = main,
	}