-- this module is created to support {{London Gazette}}

require('Module:No globals')
local getArgs = require('Module:Arguments').getArgs

local span_open = '<span style="font-size:100%; font-weight:normal" class="error">';
local code_open = '<code style="color:inherit; border:inherit; padding:inherit;">';
local help_link = ' ([[Template:London Gazette#Error messages|help]])';

local supp_error = mw.ustring.format ('%sinvalid %s&#124;supp=</code>%s</span>', span_open, code_open, help_link);
local duplicate_page_error = mw.ustring.format (' %smore than one of %s&#124;page=</code> and %s&#124;pages=</code>%s</span>', span_open, code_open, code_open, help_link);

local p = {}


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not.  A variable is set when it is not nil and not empty.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[[--------------------------< O R D I N A L _ S U F F I X >--------------------------------------------------

render a numerical text string in ordinal form suitable for English language use.  In this module, num_str is
limited by calling functions to the integer values 1-99.  The argument num_str must be known to be set before
this function is called.

]]

local function ordinal_suffix (num_str)
	local lsd;																	-- least significant digit
	local suffixes = {['1'] = 'st', ['2'] = 'nd', ['3'] = 'rd'};				-- table of suffixes except 'th'

	if num_str:match ('^1[1-3]$') then											-- check the 11-13 odd balls first to get them out of the way
		return num_str .. 'th';													-- 11th, 12th, 13th
	end
	
	lsd = num_str:match ('^%d?(%d)$');											-- all other numbers: get the least significant digit
	return num_str .. (suffixes[lsd] or 'th');									-- append the suffix from the suffixes table or default to 'th'
end


--[[--------------------------< M A K E _ P A G E _ P A R A M >------------------------------------------------

Determine the value to be assigned to the specified cs1|2 |page= or |pages= parameter in {{London Gazette}}.
The arguments |param=page and |param=pages specify which of the cs1|2 parameters |page= or |pages= for which this
function is to create a value.

This function inspects the content of the |page= and |pages= parameters, along with the |param= specifier.  From
this information it creates a value appropriate for the specified |page= or |pages= parameter.  Only one will
have a value, the other will get an empty string.

This function is called twice from {{London Gazette}}; once for each of cs1 |page= and |pages= parameters:
	|page={{#invoke:Gazette util|make_page_param|param=page|page={{{page|}}}|pages={{{pages|}}}}}
	|pages={{#invoke:Gazette util|make_page_param|param=pages|page={{{page|}}}|pages={{{pages|}}}}}

except for the lvalue and the rvalue assigned to |param=, the two calls must be identical else odd results.

|page= or |pages= without a comma, hyphen, or en dash separator → cs1 |page=
|page= or |pages= with a separator → cs1 |pages=

Hyphen separator characters are converted to en dash characters.  Any white space around hyphen and en dash
separators is removed.

If both |page= and |pages= are set, this function mimics cs1|2 and chooses |page=.

Another function, page_error() is required for error messaging because we don't want to dump css markup into a
parameter value that will be included in the cs1|2 metadata.

]]

function p.make_page_param (frame)
	local args = getArgs(frame);
	local page_or_pages;

	page_or_pages = args.page or args.unnamed or args.pages;					-- only one; prefer |page=
	
	if is_set (page_or_pages) then
		if 'pages' == args.param then
			if page_or_pages:match ('[,%-–]') then								-- only for |pages= parameter
				page_or_pages = mw.ustring.gsub (page_or_pages, '%s*[%-–]%s*', '–');	-- hyphen to en dash; remove spaces
				return page_or_pages;											-- has separator character so make the parameter |pages=
			else
				return '';														-- no separator so value will be assigned to |page=
			end
		elseif 'page' == args.param then
			if page_or_pages:match ('[,%-–]') then								-- only for |pages= parameter
				return '';														-- has separator so value will be assigned to |pages=
			else
				return page_or_pages;											-- no separator character so make the parameter |page=
			end
		else
			return '';															-- |param= something else
		end
	end

	return '';																	-- if here no pagination or not correct |page= or |pages= parameter
end


--[[--------------------------< P A G E _ E R R O R >----------------------------------------------------------

Inspect page number parameters and return an error message that will be appended to the end of the {{cite magazine}}
template rendering.  Error messages are handled this way so that the error message is not made part of the cs1|2
citation's metadata.

{{#invoke:Gazette util|page_error|page={{{page|}}}|pages={{{pages|}}}}}

]]

function p.page_error (frame)
	local args = getArgs(frame);

	if is_set (args.page) and is_set (args.pages) then
		return duplicate_page_error;											-- both of |page= and |pages= are set
	else
		return '';
	end
end


--[[--------------------------< T Y P E _ P A R A M >----------------------------------------------------------

set the value that is assigned to the cite magazine |type= parameter using the values of the London Gazette
|supp= and |display-supp= parameters

Only limited |supp= values will set the type value.  These are: 'y' or a number 1-99.

row numbers in comments apply to the table in Template_talk:London_Gazette#Rewrite_as_wrapper_around_template:cite_news

]]

function p.type_param (frame)
	local args = getArgs(frame);
	
	if not is_set (args['display-supp']) and not is_set (args.supp) then		-- when both |display-supp= and |supp= are not set
		return '';																-- [row 1] not a supplement so no display
	end
	
	args.supp = args.supp and args.supp:lower();								-- make text values lower case

	if not is_set (args['display-supp']) and is_set (args.supp) then			-- when only |supp= is set
		if 'y' == args.supp then
			return 'Supplement';												-- [row 2] the first or only supplement
		elseif args.supp:match ('^%d%d?$') then									-- one or two digits
				return ordinal_suffix (args.supp) .. ' supplement';				-- [row 3] for the 1st-99th supplement
		else
			return supp_error;													-- [row 4] any other text not supported show an error message
		end
	end

	if is_set (args['display-supp']) and not is_set (args.supp) then			-- when only |display-supp= is set
		if args['display-supp']:match ('^%d%d?$') then							-- one or two digits
			return ordinal_suffix (args['display-supp']) .. ' supplement';		-- [row 7] for the 1st-99th supplement
		elseif 'y' == args['display-supp'] then
			return 'Supplement';												-- [row 6] unnumbered supplement in /page/ space
		else
			return args['display-supp'];										-- [row 11] user specified text; supplement is not in supplement space (a Gazette website error)
		end
	end
																				-- here when both |display-supp= and |supp= are set
	if args['display-supp']:match ('^%d%d?$') then								-- supplement number
		if 'y' == args.supp or (args['display-supp'] == args.supp) then
			return ordinal_suffix (args['display-supp']) .. ' supplement';		-- [rows 8, 9]
		else																	-- |supp= is not a number or number isn't same as number in |display-supp=
			return supp_error;													-- [row 10] different values are ambiguous
		end
	else																		-- not a supplement number
		if ('y' == args.supp) and ('none' == args['display-supp']) then
			return '';															-- [row 5] for the case when a /page/ is in /supplement/ space 
		elseif ('y' == args.supp) or args.supp:match ('^%d%d?$') or not is_set (args.supp) then
			return args['display-supp'];										-- [rows 12, 13] user specified text
		else
			return supp_error;													-- [row 14] any other |supp= value not supported show an error message
		end
	end
end


--[[--------------------------< U R L _ C I T Y >--------------------------------------------------------------

sets the city element of the url path according to |city= value; defaults to London

]]

local function url_city (city_param)
	local city_names = {['b'] = 'Belfast', ['belfast'] = 'Belfast', ['e'] = 'Edinburgh', ['edinburgh'] = 'Edinburgh'};
	
	city_param = city_param and city_param:lower();								-- lower() to index into the city_names table

	return city_names[city_param] or 'London';									-- the city, or default to London
end

	
--[[--------------------------< U R L _ P A G E >--------------------------------------------------------------

sets the page number element of the url path according to |page= or |pages=, and the value assigned to |supp=
parameter.  This function assumes that supplements may have page numbering that are digits prefixed with one or
two letters: B1, B41, RH2, etc; also assumes that regular issues have digit-only page numbers.

Only limited |supp= values will set the page number path element.  These are: 'y' or a number 1-99.

]]

local function url_page (page, supp)
	if is_set (supp) then
		if ('y' == supp) or supp:match ('^%d%d?$') then
			page = page:match ('^%a?%a?%d+');									-- one or two letters followed by digits or just digits (supplement to issue 61608)
		else
			page = page:match ('^%d+');											-- |supp= set to an unexpected value, so one or more digits only
		end
	else
		page = page:match ('^%d+');												-- |supp= not set, so one or more digits only
	end
	
	return page or '';															-- at minimum return empty string for concatenation
end


--[[--------------------------< U R L _ P A G E _ O R _ S U P P L E M E N T >----------------------------------

sets the page/supplement element of the url path according to |supp= value; defaults to page

Only limited |supp= values will set the page/supplement path element to /supplement/.  These are: 'y' or a number 1-99

]]

local function url_page_or_supplement (supp_param)
	supp_param = (supp_param and supp_param:lower()) or '';						--make sure lower case for comparisons
	
	if ('y' == supp_param) or supp_param:match ('^%d%d?$') then
		return 'supplement';
	else
		return 'page';															-- anything else
	end
end

	
--[[--------------------------< U R L _ P A R A M >------------------------------------------------------------

Build a url given |city=, |issue=, |supp=, and one of |page= or |pages=; result is assigned to |url=

|url={{#invoke:Gazette util|url_param|city={{{city|}}}|issue={{{issue}}}|supp={{{supp|}}}|page={{{page|}}}|pages={{{pages|}}}}}

]]

function p.url_param (frame)
	local args = getArgs(frame);
	local pg = args.page or args.pages or '';									-- first set parameter or empty string

	local url_table = {															-- a table of the various url parts
		'https://www.thegazette.co.uk',											-- static domain name
		url_city (args.city),													-- default to London
		'issue',																-- static path text
		args.issue,																-- issue number
		url_page_or_supplement (args.supp),										-- either of /page/ or /supplement/ according to the state of |supp=
		url_page (pg, args.supp)												-- pages: digits only; supplements: optional letter followed by 1 or more digits
		};
	
	return table.concat (url_table, '/');										-- concatenate all of the parts together and done
end


return p;