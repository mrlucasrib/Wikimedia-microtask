--[[--------------------------< N I H O N G O _ E R R O R >----------------------------------------------------

creates an error message for {{nihongo}}, {{nihongo3}}, and nihongo foot}} when these template are missing <japanese>
or <romaji> inputs; names the offending template, links to template page, and adds article to Category:Nihongo template errors

]]

local function nihongo_error (template)
	local msg = {'<span class="error" style="font-size:100%">error: {{'};
	table.insert (msg, template);
	table.insert (msg, '}}: Japanese or romaji text required ([[Template:');
	table.insert (msg, template);
	table.insert (msg, '|help]])</span>');
	if 0 == mw.title.getCurrentTitle().namespace then
		table.insert (msg, '[[Category:Nihongo template errors]]');
	end

	return table.concat (msg);	
end


--[[--------------------------< N I H O N G O _ R E N D E R E R >----------------------------------------------

shared support function for nihingo(), nihongo3(), and nihongo_foot().  Calculates an index into formatting{}
from set/unset parameters:
	args[1] (english) has a value of 8 (set) or 0 (unset)
	args[2] (japanese) has a value of 4
	args[3] (romaji) has a value of 2
	args[4] (extra) has a value of 1
index, the sum of these values, gets the appropriate format string from formatting{} table with associated values
from the formatting[index][2] table

]]

local function nihongo_renderer (args, formatting, extra2)
	local output;
	local index = 0;															-- index into formatting{}
	local param_weight = {8, 4, 2, 1};											-- binary parameter weights: [1] = english (8), [2] = japanese (4), [3] = romaji (2), [4] = extra (1)

	for i=1, 5 do																-- spin through args[1] – args[4]
		index = index + (args[i] and param_weight[i] or 0);						-- calculate an index into formatting{}
	end

	output = (0 ~= index) and string.format (formatting[index][1] and formatting[index][1], formatting[index][2][1], formatting[index][2][2], formatting[index][2][3], formatting[index][2][4]) or nil;

	if extra2 then																-- always just attached to the end (if there is an end) so not part of formatting{}
		output = output and (output .. ' ' .. extra2) or '<5p4n>' .. extra2;	-- <5p4n> and </5p4n>: place holders for font-weight style spans; akin to stripmarkers, to be replaced
	end																			-- (nihongo and nihongo3) or removed (nihongo foot)

	return output and (output .. '</5p4n>') or '';								-- where there is output, add secret tag close
end


--[=[-------------------------< N I H O N G O >----------------------------------------------------------------

An experiment to see how to implement {{nihongo}} using Module:Lang for language and transliteration markup

{{Nihongo|<English>|<japanese>|<romaji>|<extra>|<extra2>|lead=yes}}

<English>, <japanese>, and <romaji> are positional parameters
	<English>: rendered as presented; purports to be English translation of <kanji/kana>
	<japanese>: Japanese language text using Japanese script; TODO: require?
	<romaji>: Hepburn romanization (transliteration); TODO: in Module:Lang/data change tooltip text to 'Hepburn romanization'?
<extra> and <extra2> are positional or named: |extra= and |extra2=; mixing can be problematic
	<extra> is rendered as presented preceeded with <comma><space>
	<extra2> is rendered as presented preceeded with <space>
|lead=: takes one value 'yes'; renders language name same as {{lang-ja}} but also adds [[Hepburn romanization|Hepburn]]:<space> ahead of the romanization; TODO: in Module:Lang, turnoff tooltip for transl when |lead=yes

]=]

local function nihongo (frame)
	local lang_module = require ('Module:Lang' .. (frame:getTitle():match ('/sandbox') or ''));	-- if this module is the sandbox, use Module:lang/sandbox; Module:Lang else

	local args = require ('Module:Arguments').getArgs (frame);
	
	local english, japanese, romaji, extra, extra2 = args[1], args[2], args[3], args.extra or args[4], args.extra2 or args[5];	-- meaningful names
	args[4] = extra or args[4];													-- ensure that extra is 'positional' for use by nihongo_renderer()

	local lead = 'yes' == args.lead;											-- make boolean

	if not (japanese or romaji) then											-- not present, return an error message
		return nihongo_error ('nihongo');
	end
	if japanese then
		japanese = lead and lang_module._lang_xx_inherit ({['code']='ja', japanese, ['template']='nihongo'}) or lang_module._lang ({'ja', japanese, ['template']='nihongo'});	-- add ja script with/without language prefix
	end
	if romaji then
		romaji = (lead and english and '[[Hepburn romanization|Hepburn]]: ' or '') .. lang_module._transl ({'ja', 'hepburn', romaji}) or nil;
	end
	
	local formatting = {														-- <5p4n> and </5p4n>: place holders for font-weight style spans; akin to stripmarkers, replaced  before function returns
		{'<5p4n>(%s)', {extra}}, 												-- 1 - (extra)
		{'%s<5p4n>', {romaji}},													-- 2 - romaji
		{'%s<5p4n> (%s)', {romaji, extra}},										-- 3 - romaji (extra)
		{'<5p4n>(%s)', {japanese}},												-- 4 - japanese
		{'<5p4n>(%s, %s)', {japanese, extra}},									-- 5 - (japanese, extra)
		{'%s<5p4n> (%s)', {romaji, japanese}},									-- 6 - romaji (japanese)
		{'%s<5p4n> (%s, %s)', {romaji, japanese, extra}},						-- 7 - romaji (japanese, extra)
		{'%s<5p4n>', {english}},												-- 8 - english
		{'%s<5p4n> (%s)', {english, extra}},									-- 9 - english (extra)
		{'%s<5p4n> (%s)', {english, romaji}},									-- 10 - english (romaji)
		{'%s<5p4n> (%s, %s)', {english, romaji, extra}},						-- 11 - english (romaji, extra)
		{'%s<5p4n> (%s)', {english, japanese}},									-- 12 - english (japanese)
		{'%s<5p4n> (%s, %s)', {english, japanese, extra}},						-- 13 - english (japanese, extra)
		{'%s<5p4n> (%s, %s)', {english, japanese, romaji}},						-- 14 - english (japanese, romaji)
		{'%s<5p4n> (%s, %s, %s)', {english, japanese, romaji, extra}},			-- 15 - english (japanese, romaji, extra)
		}

	local ret_string = nihongo_renderer (args, formatting, extra2)
	ret_string = ret_string:gsub ('<5p4n>', '<span style="font-weight: normal">'):gsub ('</5p4n>', '</span>');	-- replace 'secret' tags with proper tags
	return ret_string;															-- because gsub returns the number of replacements made as second return value
end


--[=[-------------------------< N I H O N G O 3 >--------------------------------------------------------------

An experiment to see how to implement {{nihongo3}} using Module:Lang for language and transliteration markup

Similar to {{nihongo}} but changes rendered order and does not support |lead=

{{Nihongo3|<English>|<japanese>|<romaji>|<extra>|<extra2>}}

<English>, <japanese>, and <romaji> are positional parameters
	<English>: rendered as presented; purports to be English translation of <kanji/kana>
	<japanese>: Japanese language text using Japanese script; TODO: require?
	<romaji>: Hepburn romanization (transliteration); TODO: in Module:Lang/data change tooltip text to 'Hepburn romanization'?
<extra> and <extra2> are positional or named: |extra= and |extra2=; mixing can be problematic
	<extra> is rendered as presented preceeded with <comma><space>
	<extra2> is rendered as presented preceeded with <space>

]=]

local function nihongo3 (frame)
	local lang_module = require ('Module:Lang' .. (frame:getTitle():match ('/sandbox') or ''));	-- if this module is the sandbox, use Module:lang/sandbox; Module:Lang else
	local args = require ('Module:Arguments').getArgs (frame);
	
	local english, japanese, romaji, extra, extra2 = args[1], args[2], args[3], args.extra or args[4], args.extra2 or args[5];	-- meaningful names
	args[4] = extra or args[4];													-- ensure that extra is 'positional' for use by nihongo_renderer()

	if not (japanese or romaji) then											-- not present, return an error message
		return nihongo_error ('nihongo3');
	end
	japanese = japanese and lang_module._lang ({'ja', japanese}) or nil;
	romaji = romaji and lang_module._transl ({'ja', 'hepburn', romaji}) or nil;
	
	local formatting = {														-- <5p4n> and </5p4n>: place holders for font-weight style spans; akin to stripmarkers, replaced  before function returns
		{'<5p4n>(%s)', {extra}}, 												-- 1 - (extra)
		{'%s<5p4n>', {romaji}},													-- 2 - romaji
		{'%s<5p4n> (%s)', {romaji, extra}},										-- 3 - romaji (extra)
		{'<5p4n>(%s)', {japanese}},												-- 4 - japanese
		{'<5p4n>(%s, %s)', {japanese, extra}},									-- 5 - (japanese, extra)
		{'%s<5p4n> (%s)', {romaji, japanese}},									-- 6 - romaji (japanese)
		{'%s<5p4n> (%s, %s)', {romaji, japanese, extra}},						-- 7 - romaji (japanese, extra)
		{'%s<5p4n>', {english}},												-- 8 - english
		{'%s<5p4n> (%s)', {english, extra}},									-- 9 - english (extra)
		{'%s<5p4n> (%s)', {romaji, english}},									-- 10 - romaji (english)
		{'%s<5p4n> (%s, %s)', {romaji, english, extra}},						-- 11 - romaji (english, extra)
		{'%s<5p4n> (%s)', {english, japanese}},									-- 12 - english (japanese)
		{'%s<5p4n> (%s, %s)', {english, japanese, extra}},						-- 13 - english (japanese, extra)
		{'%s<5p4n> (%s, %s)', {romaji, japanese, english}},						-- 14 - romaji (japanese, english)
		{'%s<5p4n> (%s, %s, %s)', {romaji, japanese, english, extra}},			-- 15 - romaji (japanese, english, extra)
		}

	local ret_string = nihongo_renderer (args, formatting, extra2)
	ret_string = ret_string:gsub ('<5p4n>', '<span style="font-weight: normal">'):gsub ('</5p4n>', '</span>');	-- replace 'secret' tags with proper tags
	return ret_string;															-- because gsub returns the number of replacements made as second return value
end


--[=[-------------------------< N I H O N G O _ F O O T >------------------------------------------------------

An experiment to see how to implement {{nihongo_foot}} using Module:Lang for language and transliteration markup

{{Nihongo foot|<English>|<japanese>|<romaji>|<extra>|<extra2>|<post>|lead=yes|group}}

<English>, <japanese>, and <romaji> are positional parameters
	<English>: rendered as presented; purports to be English translation of <kanji/kana>
	<japanese>: Japanese language text using Japanese script; TODO: require?
	<romaji>: Hepburn romanization (transliteration); TODO: in Module:Lang/data change tooltip text to 'Hepburn romanization'?
<extra> and <extra2> are positional or named: |extra= and |extra2=; mixing can be problematic
	<extra> is rendered as presented preceeded with <comma><space>
	<extra2> is rendered as presented preceeded with <space>
<post> is positional or named: |post= is a postscript character preceding the <ref>..</ref> tag (after <English>)
|lead=: takes one value 'yes'; renders language name same as {{lang-ja}} but also adds [[Hepburn romanization|Hepburn]]:<space> ahead of the romanization;
	TODO: in Module:Lang, turnoff tooltip for transl when |lead=yes
	in the live template |lead= also adds the Help:Installing Japanese character sets link; this is not supported in this code (nihongo nor nihongo3 have this support)
|group=: the group attribute in <ref group="..."> and in {{reflist}}

]=]

local function nihongo_foot (frame)
	local lang_module = require ('Module:Lang' .. (frame:getTitle():match ('/sandbox') or ''));	-- if this module is the sandbox, use Module:lang/sandbox; Module:Lang else
	local args = require ('Module:Arguments').getArgs (frame);
	
	local english, japanese, romaji, extra, extra2 = args[1], args[2], args[3], args.extra or args[4], args.extra2 or args[5];	-- meaningful names
	args[4] = extra or args[4];													-- ensure that extra is 'positional' for use by nihongo_renderer()
	local post = args[6] or args.post;
	local group = args.group;
	local lead = 'yes' == args.lead;											-- make boolean

	if not (japanese or romaji) then											-- not present, return an error message
		return nihongo_error ('nihongo foot');
	end
	if japanese then
		japanese = lead and lang_module._lang_xx_inherit ({['code']='ja', japanese}) or lang_module._lang ({'ja', japanese});	-- add ja script with/without language prefix
	end
	if romaji then
		romaji = (lead and '[[Hepburn romanization|Hepburn]]: ' or '') .. lang_module._transl ({'ja', 'hepburn', romaji}) or nil;
	end
	
	local formatting = {
		{'%s', {extra}}, 														-- 1 - extra
		{'%s', {romaji}},														-- 2 - romaji
		{'%s, %s', {romaji, extra}},											-- 3 - romaji, extra
		{'%s', {japanese}},														-- 4 - japanese
		{'%s, %s', {japanese, extra}},											-- 5 - japanese, extra
		{'%s %s', {japanese, romaji}},											-- 6 - japanese romaji
		{'%s %s, %s', {japanese, romaji, extra}},								-- 7 - japanese romaji, extra
																				-- from here english is used in the mapping but not rendered by nihongo_renderer so not included in the table
		{'', {''}},																-- 8 - english
		{'%s', {extra}},														-- 9 - extra
		{'%s', {romaji}},														-- 10 - romaji
		{'%s, %s', {romaji, extra}},											-- 11 - romaji, extra
		{'%s', {japanese}},														-- 12 - japanese
		{'%s, %s', {japanese, extra}},											-- 13 - japanese, extra
		{'%s %s', {japanese, romaji}},											-- 14 - japanese romaji
		{'%s %s, %s', {japanese, romaji, extra}},								-- 15 - japanese romaji, extra
		}

	if english and post then													-- rewrite english to include |post=
		english = english .. post;												-- if english has a value append post else just post
	elseif post then
		english = post;															-- english not set, use post
	elseif not english then														-- neither are set
		english = '';															-- make english an empty string for concatenation
	end

	if japanese or romaji or extra or extra2 then								-- no ref tag when none of these are set (it would be empty)
		local content = nihongo_renderer (args, formatting, extra2);
		content = content:gsub ('<5p4n>', ''):gsub ('</5p4n>$', '', 1);			-- strip secret <5p4n> and </5p4n> tags added by nihongo_renderer(); spans not used by this template

		return english .. frame:extensionTag ({name='ref', args={group=group}, content=content});	-- english with attached reference tag
	else
		return english;															-- nothing to be inside ref tag so just return english
	end
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	nihongo = nihongo,
	nihongo3 = nihongo3,
	nihongo_foot = nihongo_foot,
	}