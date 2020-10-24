require('Module:No globals');
local getArgs = require('Module:Arguments').getArgs


--[[--------------------------< E R R _ M S G _ M A K E >------------------------------------------------------
]]

local function err_msg_make (msg)
	return '<span class="error" style="font-size:100%">error: ' .. msg .. ' not recognized</span>'
end


--[[--------------------------< _ I S _ C O D E >--------------------------------------------------------------

local or require()d entry point

return true if <code> is a mediawiki recognized code; false else

<code> - language code to validate; expected to be lowercase without leading/trailing whitespace
<target_lang_code> - language code for target language; expected to be valid; expected to be lowercase without leading/trailing whitespace

specifying <target_lang_code> may be a pointless exercise because of cldr fallback.  For example,
	mw.language.fetchLanguageName (crh, sq) -> Crimean Turkish
because the Albanian language definitions do not have an Albanian-language version of the language name

]]

local function _is_code (code, target_lang_code)
	code = mw.language.fetchLanguageName (code, target_lang_code);
	return '' ~= code;
end


--[[--------------------------< _ _ V A L I D A T E _ T A R G E T _ L A N G _ C O D E >------------------------

validates target_lang_code as a know language code; returns two values
	when target_lang_code is valid, first return value holds target_lang_code; second return value is nil
	when target_lang_code is invalid, first retrun value is nil; second return value has error message

if target_lang_code argument is nil, (missing or empty in the invoke) use local wiki's language code

]]

local function __validate_target_lang_code (target_lang_code)
	local msg;
	
	if target_lang_code then													-- not missing or empty
		if not _is_code (target_lang_code) then									-- validate target_lang_code
			msg = err_msg_make ('target language code: ' .. target_lang_code);
			target_lang_code = nil;												-- unset as invalid
		end
	end
	if not target_lang_code then												-- if nil because missing or empty or because invlaid and we set it nil
		target_lang_code = mw.getContentLanguage():getCode();					-- use local wiki's language code
	end

	return target_lang_code, msg;												-- target_lang_code is valid or nil; msg is nil or has an error message
end


--[[--------------------------< I S _ C O D E >----------------------------------------------------------------

module entry point

args[1]: language code -> <code>
args[2]: optional target language code; same as <target lang code> in {{#language:<code>|<target lang code>}}; defaults to the local wiki language

return true if <code> is a mediawiki recognized code; nil else

]]

local function is_code (frame)
	local args = getArgs (frame, {
		valueFunc = function (key, value)
			return (value and '' ~= value) and value:lower():gsub ('^%s*(.-)%s*$', '%1') or nil;
		end
		});
	local code = args[1];
	local target_lang_code = __validate_target_lang_code (args[2]);

	return code and _is_code (code, target_lang_code) and true or nil;
end


--[[--------------------------< N A M E _ F R O M _ C O D E >--------------------------------------------------

module entry point

args[1]: language code
args[2]: optional target language code; same as <target lang code> in {{#language:<code>|<target lang code>}}; defaults to the local wiki language

return language-name if language-code is a mediawiki recognized code; error message string else

returned language name not guarenteed to be in target_lang_code (if specified), because mw language lists are incomplete

]]

local function name_from_code (frame)
	local args = getArgs (frame, {
		valueFunc = function (key, value)
			return (value and '' ~= value) and value:lower():gsub ('%s*(.-)%s*', '%1') or nil;
		end
		});
	local code = args[1];
	if not code then
		return err_msg_make ('code: (empty)');
	end
	
	local target_lang_code, msg = __validate_target_lang_code (args[2]);
	if msg then
		return msg;
	end

	local name = mw.language.fetchLanguageName (code, target_lang_code);		-- returns empty string if code not found
	return '' ~= name and name or err_msg_make ('language code: ' .. code);		-- return language name or error message
end


--[[--------------------------< C O D E _ F R O M _ N A M E >--------------------------------------------------

local entry point

args[1]: language name
args[2]: optional target language code; instruct this function to fetch language name list in 'this' language

return language-code if language-name is a mediawiki recognized name and target language code is valid; error message string else

second return value is a boolean used by is_name(); true when name is found; false else

]]

local function _code_from_name (args)
	local name = args[1];
	if not name then
		return err_msg_make ('name: (empty)');
	end

	local target_lang_code, msg =  __validate_target_lang_code (args[2]);

	if msg then
		return msg;
	end

	local code_name_list = mw.language.fetchLanguageNames (target_lang_code, 'all');	-- get language code / name list in target_lang_code language indexed by language code
	local name_code_list = {};													-- to hold language name / code list indexed by name

	for k, v in pairs (code_name_list) do										-- spin through the code / name list and
		name_code_list[v:lower()] = k;											-- make a name / code list
	end

	if name_code_list[name] then
		return name_code_list[name], true;										-- returns code when name is found and true for is_name()
	else
		return err_msg_make ('language name: ' .. name), false;					-- return error message when name not found and false for is_name()
	end
end


--[[--------------------------< C O D E _ F R O M _ N A M E >--------------------------------------------------

module entry point

args[1]: language name
args[2]: optional target language code; instruct this function to fetch language name list in 'this' language

return language-code if language-name is a mediawiki recognized name and target language code is valid; error message string else

]]

local function code_from_name (frame)
	local args = getArgs (frame, {
		valueFunc = function (key, value)
			return (value and '' ~= value) and value:lower():gsub ('^%s*(.-)%s*$', '%1') or nil;
		end
		});
	
	local result, _ = _code_from_name (args);									-- suppress true/false return used by is_name()
	return result;
end


--[[--------------------------< I S _ N A M E >----------------------------------------------------------------

return true if <name> is a mediawiki recognized language name; false else

args[1]: language name
args[2]: optional target language code; instructs _code_from_name to fetch language name list in 'this' language
			defaults to local wiki's language;  when this parameter not valid, language name is assumed to be not valid

]]

local function is_name (frame)
	local args = getArgs (frame, {
		valueFunc = function (key, value)
			return (value and '' ~= value) and value:lower():gsub ('%s*(.-)%s*', '%1') or nil;
		end
		});
	
	local _, result = _code_from_name (args);									-- suppress code return used by code_from_name()
	return result and true or nil;
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	code_from_name = code_from_name,
	is_code = is_code,
	is_name = is_name,
	name_from_code = name_from_code,

	_is_code = _is_code,														-- entry point from another module
	}