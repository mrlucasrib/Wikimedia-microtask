require('Module:No globals');

--[[--------------------------< B I B C O D E >--------------------------------------------------------------------

Validates (sort of) a bibcode id.

Format for bibcodes is specified here: http://adsabs.harvard.edu/abs_doc/help_pages/data.html#bibcodes

But, this: 2015arXiv151206696F is apparently valid so apparently, the only things that really matter are length, 19 characters
and first four digits must be a year.  This function makes these tests:
	length must be 19 characters
	characters in position
		1–4 must be digits and must represent a year in the range of 1000 – next year
		5 must be a letter
		6–8 must be letter, digit, ampersand, or dot (ampersand cannot directly precede a dot; &. )
		9–18 must be letter, digit, or dot
		19 must be a letter or dot

]]

local function bibcode (id)
	local err_type;
	local year;

	if 19 ~= id:len() then
		err_type = 'length';
	else
		year = id:match ("^(%d%d%d%d)[%a][%w&%.][%w&%.][%w&%.][%w.]+[%a%.]$")	-- 
		if not year then														-- if nil then no pattern match
			err_type = 'value';													-- so value error
		else
			local next_year = tonumber(os.date ('%Y'))+1;						-- get the current year as a number and add one for next year
			year = tonumber (year);												-- convert year portion of bibcode to a number
			if (1000 > year) or (year > next_year) then
				err_type = 'year';												-- year out of bounds
			end
			if id:find('&%.') then
				err_type = 'journal';											-- journal abbreviation must not have '&.' (if it does its missing a letter)
			end
		end
	end

	return err_type;
end


--[=[-------------------------< E N T R Y   P O I N T S >------------------------------------------------------

This module is mostly a copy of the bibcode validation used in [[Module:Citation/CS1]]

call this module with:
	{{#invoke:check bibcode|check_bibcode|{{{1|}}}}}
where {{{1|}}} is the bibcode

]=]

local function check_bibcode (frame)
	local err_type = bibcode (mw.text.trim (frame.args[1]));					-- trim leading and trailing white space before evaluation
	if err_type then
		return '<span style="font-size:100%" class="error citation-comment">Check bibcode: ' .. err_type .. ' ([[Template:Bibcode#Error_messages|help]])</span>';
	end
	return '';																	-- return empty string when bibcode appears to be valid
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	check_bibcode = check_bibcode,
	}