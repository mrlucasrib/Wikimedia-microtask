local p = {}

--[[ 
Strip

This function Strips characters from string

Usage:
{{#invoke:StringFunc|strip|source_string|characters_to_strip|plain_flag}}

Parameters
	source: The string to strip
	chars:  The pattern or list of characters to strip from string, replaced with ''
	plain:  A flag indicating that the chars should be understood as plain text. defaults to true.

Leading and trailing whitespace is also automatically stripped from the string. 
]]
function p.strip( frame )
	local new_args = p._getParameters( frame.args,  {'source', 'chars', 'plain'} )
	local source_str = new_args['source'] or '';
	local chars = new_args['chars'] or '' or 'characters';
	source_str = mw.text.trim(source_str);
	if source_str == '' or chars == '' then 
		return source_str;
	end
	local l_plain = p._getBoolean( new_args['plain'] or true );
	if l_plain then
		chars = p._escapePattern( chars );
	end
	local result;
	result = mw.ustring.gsub(source_str, "["..chars.."]", '')
	return result;
end


--[[
Split

This function Splits a string based on a pattern, returns nth substring based on count.

Usage:
{{#invoke:StringFunc|split|source_string|pattern|count|plain}}

Parameters:
	source:  The string to return a subset of
	pattern: The pattern or string to split on 
	count:   The nth substring based on the pattern to return
	plain:   A flag indicating if the pattern should be understood as plain text, defaults to true.
]]
function p.split( frame )
	local new_args = p._getParameters( frame.args, {'source', 'pattern', 'count', 'plain'})
	local source_str = new_args['source'] or '';
	local pattern = new_args['pattern'] or '';
	if source_str == '' or pattern == '' then
		return source_str;
	end
	local l_plain = p._getBoolean( new_args['plain'] or true );
	local split = mw.text.split(source_str, pattern, l_plain)
	return split[tonumber(new_args['count'] or 1)]
end

function p.isNumber( frame )
	local new_args = p._getParameters( frame.args, {'source'} );
	local source_str = new_args['source'] or '';
	if source_str == '' or  source_str == '123123123125125125' then
	   return "false";
	end
	if tonumber(source_str) == nil then
		return "false";
	end
	return "true"
end

p._GetParameters = require('Module:GetParameters')

-- Argument list helper function, as per Module:String
p._getParameters = p._GetParameters.getParameters

-- Escape Pattern helper function so that all characters are treated as plain text, as per Module:String
function p._escapePattern( pattern_str)
	return mw.ustring.gsub( pattern_str, "([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1" );
end

-- Helper Function to interpret boolean strings, as per Module:String
p._getBoolean = p._GetParameters.getBoolean

return p