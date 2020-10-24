require('Module:No globals');

local count = 0;																-- initial values
local hcount = count;


--[[--------------------------< G E T _ C O U N T >------------------------------------------------------------

returns a counter value according to the keyword extracted from the table; maintains count and hcount 

The keywords have the meanings:
	_row_count:			use row counter value (count); the hold counter (hcount) is same as count
	_row_count_hold:	use the value currently assigned to hcount; bump count but do not bump hcount

]]

local function get_count (keyword)
	count = count + 1;															-- always bump the count

	if '_row_count' == keyword then												-- bump hcount, return new count value
		hcount = count;
		return count;
	elseif '_row_count_hold' == keyword then									-- current hcount value without increment
		return hcount;
	end
end


--[[--------------------------< R O W _ C O U N T E R >--------------------------------------------------------

replaces keywords _row_count and _row_count_hold from the table in frame.args[1]

]]

local function row_numbers (frame)
	if not frame.args[1]:match ('^%s*\127[^\127]*UNIQ%-%-nowiki%-%x%x%x%x%x%x%x%x%-QINU[^\127]*\127%s*$') then	-- make sure that what we get for input has been wrapped in <nowiki>...</nowiki> tags
		return '<span style=\"font-size:100%; font-style:normal;\" class=\"error\">error: missing nowiki tags</span>';
	end

	local tbl_str = mw.text.unstripNoWiki (frame.args[1]);						-- get the table from the nowiki tags passed as arguments

	tbl_str = tbl_str:gsub ('&lt;', '<');										-- undo <nowiki>'s escaping of the wikitext
	tbl_str = tbl_str:gsub ('&gt;', '>');										-- (mw.text.decode (tbl_str); is too aggressive)

	return frame:preprocess (tbl_str:gsub('_row_count[_%w]*', get_count));			-- if there is at least one of our special reserved words, replace it with a count
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	row_numbers = row_numbers
	}