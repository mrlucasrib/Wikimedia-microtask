-- This module counts the number of times that various reference tags and cs1|2 templates appear.
-- {{#invoke:ref_info|ref_info}}
-- {{ref info}}
-- {{ref info|aristotle}}

require('Module:No globals');
local data = mw.loadData ('Module:Ref info/data');

--mw.logObject (data.cs12_stripped_list, 'data.cs12_stripped_list')
local collapsible_tables = {
	['cs1'] = '',																-- collapsible wiki-tables of names and counts
	['cs2'] = '',
	['cs1_like'] = '',
	['vcite'] = '',
	['sfn'] = '',
	['harv'] = '',
	}


--[[--------------------------< T E M P L A T E _ N A M E _ T A B L E _ M A K E >------------------------------

makes a collapsed html table that holds a list of cs1 or cs2 template used in an article.  The list occupies a
single row of the parent table.

]]

local function template_name_table_make (name_list, group)
	local name_table = {};

	local function comp (a, b)													-- used in following table.sort()
		return a:lower() < b:lower();											-- case-insensitive ascending alpha sort
	end

	table.insert (name_table, '\n|-\n|scope="row" colspan="2" style="vertical-align:top;text-align:left" |\n');	-- create a blank row in parent table for this table
	table.insert (name_table, '{| class="mw-collapsible mw-collapsed nowrap" style="margin: 0.2em auto auto; width:100%;"\n')	-- open the collapsed list table; style aligns show/hide toggle
	table.insert (name_table, '| List of ');									-- begin simple header row always displays
	table.insert (name_table, group);											-- template group (cs1, cs2 TODO: vcite? harv?)
	table.insert (name_table, ' templates \n');									-- end of simple heading
	table.insert (name_table, '|-\n|\n<hr /><ul>\n');							-- new row, row content begins with <hr />; open unordered list
	local t = {};
	for k, v in pairs (name_list) do											-- spin through the list
		table.insert (t, string.format ('<li>%s (%s)</li>', k, v))				-- make pretty unordered list of name with count
	end
	
	if not t[1] then
		return '';																-- nothing in the list so abandon
	end

	table.sort (t, comp);														-- case-insensitive ascending alpha sort
	table.insert (t, '</ul>\n');												-- close unordered list
	table.insert (name_table, table.concat (t, '\n'));							-- make a string and add to main table
	table.insert (name_table, '\n|}');											-- close the table
	return table.concat (name_table);											-- return html table as a string
end


--[[--------------------------< C O U N T _ P A T T E R N >----------------------------------------------------

this is a general purpose function used to count occurrences of <pattern> in <text>

]]

local function count_pattern (text, pattern)
	local _;
	local count;
	_, count = mw.ustring.gsub (text, pattern, '%1');
	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ L A S T >--------------------------------------------------

makes a count of those cs1|2 templates that use |last= or |last1= (or any of the selected aliases of these).

]]

local function count_cs1_last (template, count)
	local _, tally;

	for _, param in ipairs (data.last_param_patterns) do
		_, tally = mw.ustring.gsub (template, '|%s*' .. param .. '%s*=%s*[^}|]', '%1');		-- count occurences of that pattern
		count = count + tally;													-- accumulate a total
	end

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ A U T H O R >----------------------------------------------

makes a count of those cs1|2 templates that use |author= or |author1= (or any of the selected aliases of these).

]]

local function count_cs1_author (template, count)
	local _, tally;

	for _, param in ipairs (data.author_param_patterns) do
		_, tally = mw.ustring.gsub (template, '|%s*' .. param .. '%s*=%s*[^}|]', '%1');		-- count occurences of that pattern
		count = count + tally;													-- accumulate a total
	end

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ A U T H O R S >--------------------------------------------

makes a count of those cs1|2 templates that use |authors= (or any of the selected aliases).

]]

local function count_cs1_authors (template, count)
	local _, tally;

	for _, param in ipairs (data.authors_param_patterns) do
		_, tally = mw.ustring.gsub (template, '|%s*' .. param .. '%s*=%s*[^}|]', '%1');		-- count occurences of that pattern
		count = count + tally;													-- accumulate a total
	end

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ V A U T H O R S >------------------------------------------

makes a count of those cs1|2 templates that use |vauthors=.

]]

local function count_cs1_vauthors (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*vauthors%s*=%s*[^}|]', '%1');	-- count occurences of that pattern
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D A T E S _ D M Y >----------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |date=DD Month YYYY where
DD is one or two digits or a range DD-DD Month YYYY

]]

local function count_cs1_dates_dmy (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*date%s*=%s*%d?%d%s+%a+%s+%d%d%d%d', '%1');			-- dd Month yyyy
	count = count + tally;														-- accumulate a total
	_, tally = mw.ustring.gsub (template, '|%s*date%s*=%s*%d?%d[%-–]%d?%d%s+%a+%s+%d%d%d%d', '%1');	-- dd-dd Month yyyy
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D A T E S _ M D Y >----------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |date=Month DD, YYYY where
DD is one or two digits or a range Month DD-DD, YYYY

]]

local function count_cs1_dates_mdy (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*date%s*=%s*%a+%s+%d?%d%s*,%s+%d%d%d%d', '%1');				-- Month dd, yyyy
	count = count + tally;														-- accumulate a total
	_, tally = mw.ustring.gsub (template, '|%s*date%s*=%s*%a+%s+%d?%d[%-–]%d?%d%s*,%s+%d%d%d%d', '%1');		-- Month dd-dd, yyyy
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D A T E S _ Y M D >----------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |date=YYYY-MM-DD

]]

local function count_cs1_dates_ymd (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*date%s*=%s*%d%d%d%d%-%d%d%-%d%d', '%1');		-- yyyy-mm-dd
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D F _ D M Y >----------------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |df=xxx (with a value)

]]

local function count_cs1_df_dmy (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*df%s*=%s*dmy%-?a?l?l?', '%1');	-- |df=dmy |df=dmy-all
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D F _ M D Y >----------------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |df=xxx (with a value)

]]

local function count_cs1_df_mdy (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*df%s*=%s*mdy%-?a?l?l?', '%1');	-- |df=mdy |df=mdy-all
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 _ D F _ Y M D >----------------------------------------------

Using the lists of cs1|2 templates, make a count of just those templates that have |df=xxx (with a value)

]]

local function count_cs1_df_ymd (template, count)
	local _, tally;

	_, tally = mw.ustring.gsub (template, '|%s*df%s*=%s*ymd%-?a?l?l?', '%1');	-- |df=ymd |df=ymd-all
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C O U N T _ C S 1 2 _ M O D E >--------------------------------------------------

make a count of those cs1|2 templates that have |mode=cs1 or |mode=cs2

]]

local function count_cs12_mode (template, count, mode)
	local _, tally;

	mode = 1 == mode and 'cs1' or 'cs2';
	
	_, tally = mw.ustring.gsub (template, '|%s*mode%s*=%s*' .. mode, '%1');		-- |mode=cs1 or |mode=cs2
	count = count + tally;														-- accumulate a total

	return count;
end


--[[--------------------------< C S 1 _ C S 2 _I N F O _ G E T >-----------------------------------------------

Using the list of cs1|2 templates, make a count of those templates.  Make lists of cs1|2 templates used.  Count
different author-name styles, date styles.

]]

local function cs1_cs2_info_get (Article_content, pattern, template_name_list, object)
	local tstart, tend = Article_content:find (pattern);						-- find the first cs1 template
	local total = 0;
	
	while tstart do																-- nil when cs1|2 template not found
		local template = Article_content:match ('%b{}', tstart);				-- get the whole template

		if template then														-- necessary?
			local name = template:match ('{{%s*([^|}]+)');						-- get template name
			name=mw.text.trim (name);											-- trim whitespace
			if not template_name_list[name] then								-- if not already saved
				template_name_list[name] = 1;									-- save it 
			else																-- here when this name already saved
				template_name_list[name] = template_name_list[name] + 1;		-- to indicate that there are multiple same name templates
			end
			total = total + 1;													-- tally total number of cs1 templates

																				-- count various date properties
			object['cs1_dmy_dates']['count'] = count_cs1_dates_dmy (template, object['cs1_dmy_dates']['count']);	-- count of |date=dmy
			object['cs1_mdy_dates']['count'] = count_cs1_dates_mdy (template, object['cs1_mdy_dates']['count']);	-- count of |date=mdy
			object['cs1_ymd_dates']['count'] = count_cs1_dates_ymd (template, object['cs1_ymd_dates']['count']);	-- count of |date=ymd

			object['cs1_dates_df_dmy']['count'] = count_cs1_df_dmy (template, object['cs1_dates_df_dmy']['count']);	-- count of |df=dmy
			object['cs1_dates_df_mdy']['count'] = count_cs1_df_mdy (template, object['cs1_dates_df_mdy']['count']);	-- count of |df=dmy
			object['cs1_dates_df_ymd']['count'] = count_cs1_df_ymd (template, object['cs1_dates_df_ymd']['count']);	-- count of |df=dmy

																				-- count various author-name properties
			object['cs1_last']['count'] = count_cs1_last (template, object['cs1_last']['count']);					-- count of |lastn=
			object['cs1_author']['count'] = count_cs1_author (template, object['cs1_author']['count']);				-- count of |authorn=
			object['cs1_authors']['count'] = count_cs1_authors (template, object['cs1_authors']['count']);			-- count of |authors=
			object['cs1_vauthors']['count'] = count_cs1_vauthors (template, object['cs1_vauthors']['count']);		-- count of |vauthors=
		
			object['cs1_mode']['count'] = count_cs12_mode (template, object['cs1_mode']['count'], 1);				-- count of |mode=cs1
			object['cs2_mode']['count'] = count_cs12_mode (template, object['cs2_mode']['count'], 2);				-- count of |mode=cs2
		end
		tstart = tend;															-- reset the search starting index
		tstart, tend = Article_content:find (pattern, tstart);					-- search for another cs1|2 template
	end

	return total;
end


--[[--------------------------< C O U N T _ C S 1 >------------------------------------------------------------

Using the list of cs1 templates, make a count of just those templates as dictated by base_pattern.

makes a list of cs1 templates in the article

]]

local function count_cs1 (Article_content, base_pattern, object)
	local _;
	local pattern;
	local total = 0;
	local cs1_template_name_list = {};

	for i, cs1_template in ipairs (data.cs1_template_patterns) do
		pattern = string.format	(base_pattern, cs1_template);					-- make a pattern for the selected cs1 template

		total = total + cs1_cs2_info_get (Article_content, pattern, cs1_template_name_list, object);
	end

	collapsible_tables.cs1 = template_name_table_make (cs1_template_name_list, 'cs1');

--mw.logObject (cs1_template_name_list, 'cs1_template_name_list')
	return total;
end


--[[--------------------------< C O U N T _ C S 1 _ R E F S >--------------------------------------------------

Using the list of cs1 templates, make a count of just those references as dictated by base_pattern.

]]

local function count_cs1_refs (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	for i, template in ipairs (data.cs1_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cs1 template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ C S 1 _ L I K E _ T E M P L A T E S >------------------------------

make a count of cs1-like templates as dictated by <pattern>.

]]

local function count_cs1_like_templates (Article_content, pattern)
	local tstart, tend = Article_content:find (pattern);						-- find the first cs1-like template
	local total = 0;
	local template_name_list = {};

	while tstart do																-- nil when cs1-like template not found
		local template = Article_content:match ('%b{}', tstart);				-- get the template in the ref

		if template then														-- necessary?
			local name = template:match ('{{%s*([^|}]+)');						-- get template name
			name = mw.text.trim (name);											-- trim whitespace
			name = name:gsub (' +', ' ');										-- replace multiple space chars with a single char
			
			if not data.cs12_stripped_list[name] then							-- if not a cs1|2 template
				if not template_name_list[name] then							-- if not already saved
					template_name_list[name] = 1;								-- save it 
				else															-- here when this name already saved
					template_name_list[name] = template_name_list[name] + 1;	-- to indicate that there are multiple same name templates
				end
				total = total + 1;												-- tally total number of cs1-like templates
			end
		end
		tstart = tend;															-- reset the search starting index
		tstart, tend = Article_content:find (pattern, tstart);					-- search for another cs1|2 template
	end

	collapsible_tables.cs1_like = template_name_table_make (template_name_list, 'cs1-like');

	return total;
end


--[[--------------------------< C O U N T _ C S 1 _ L I K E _ R E F S >----------------------------------------

make a count of cs1-like references as dictated by <pattern>.

]]

local function count_cs1_like_refs (Article_content, pattern)
	local tstart, tend = Article_content:find (pattern);						-- find the first cs1-like template
	local total = 0;

	while tstart do																-- nil when cs1-like reference not found
		local template = Article_content:match ('%b{}', tstart);				-- get the template in the ref

		if template then														-- necessary?
			local name = template:match ('{{%s*([^|}]+)');						-- get template name
			name = mw.text.trim (name);											-- trim whitespace
			name = name:gsub (' +', ' ');										-- replace multiple space chars with a single char
			
			if not data.cs12_stripped_list[name] then							-- if not a cs1|2 template
				total = total + 1;												-- tally total number of cs1-like references
			end
		end
		tstart = tend;															-- reset the search starting index
		tstart, tend = Article_content:find (pattern, tstart);					-- search for another cs1|2 template
	end
	return total;
end


--[[--------------------------< C O U N T _ C S 2 >------------------------------------------------------------

Using the list of cs2 templates, make a count of those templates as dictated by base_pattern.

make a list of cs2 templates in the article

]]

local function count_cs2 (Article_content, base_pattern, object)
	local _;
	local pattern;
	local count, total = 0, 0;
	local cs2_template_name_list = {};

	for i, cs2_template in ipairs (data.cs2_template_patterns) do
		pattern = string.format	(base_pattern, cs2_template);					-- make a pattern for the selected cs2 template

		total = total + cs1_cs2_info_get (Article_content, pattern, cs2_template_name_list, object);
	end

	collapsible_tables.cs2 = template_name_table_make (cs2_template_name_list, 'cs2');

--mw.logObject (cs2_template_name_list, 'cs2_template_name_list')
	return total;
end


--[[--------------------------< C O U N T _ C S 2 _ R E F S >--------------------------------------------------

Using the list of cs2 templates, make a count of those references as dictated by base_pattern.

]]

local function count_cs2_refs (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;

	for i, template in ipairs (data.cs2_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cs1 template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ V C I T E >--------------------------------------------------------

Using the list of vcite templates, make a count of just those templates as dictated by base_pattern.

makes a list of vcite templates in the article

]]

local function count_vcite (Article_content, base_pattern, object)
	local _;
	local pattern;
	local total = 0;
	local vcite_template_name_list = {};

	for i, vcite_template in ipairs (data.vcite_template_patterns) do
		pattern = string.format	(base_pattern, vcite_template);					-- make a pattern for the selected vcite template

		local tstart, tend = Article_content:find (pattern);						-- find the first vcite template

		while tstart do																-- nil when vcite template not found
			local template = Article_content:match ('%b{}', tstart);				-- get the whole template
	
			if template then														-- necessary?
				local name = template:match ('{{%s*([^|}]+)');						-- get template name
				name=mw.text.trim (name);											-- trim whitespace
				if not vcite_template_name_list[name] then								-- if not already saved
					vcite_template_name_list[name] = 1;									-- save it 
				else																-- here when this name already saved
					vcite_template_name_list[name] = vcite_template_name_list[name] + 1;		-- to indicate that there are multiple same name templates
				end
				total = total + 1;													-- tally total number of vcite templates
			end
			tstart = tend;															-- reset the search starting index
			tstart, tend = Article_content:find (pattern, tstart);					-- search for another vcite template
		end
	end

	collapsible_tables.vcite = template_name_table_make (vcite_template_name_list, 'vcite');

--mw.logObject (vcite_template_name_list, 'vcite_template_name_list')
	return total;
end


--[[--------------------------< C O U N T _ V C I T E _ R E F S >----------------------------------------------

Using the list of cs1 templates, make a count of just those references as dictated by base_pattern.

]]

local function count_vcite_refs (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	for i, template in ipairs (data.vcite_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected vcite template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< S F N _ H A R V _I N F O _ G E T >---------------------------------------------

Using the list of sfn and harv templates, make a count of those templates.  Make lists of sfn and harv templates
used.

]]

local function sfn_harv_info_get (Article_content, pattern, template_name_list, object)
	local tstart, tend = Article_content:find (pattern);						-- find the first cs1 template
	local total = 0;
	
	while tstart do																-- nil when the template not found
		local template = Article_content:match ('%b{}', tstart);				-- get the whole template

		if template then														-- necessary?
			local name = template:match ('{{%s*([^|}]+)');						-- get template name
			name=mw.text.trim (name);											-- trim whitespace
			if not template_name_list[name] then								-- if not already saved
				template_name_list[name] = 1;									-- save it 
			else																-- here when this name already saved
				template_name_list[name] = template_name_list[name] + 1;		-- to indicate that there are multiple same name templates
			end
			total = total + 1;													-- tally total number of templates
		end
		tstart = tend;															-- reset the search starting index
		tstart, tend = Article_content:find (pattern, tstart);					-- search for another template
	end

	return total;
end


--[[--------------------------< C O U N T _ S F N >------------------------------------------------------------

Using the list of sfn templates, make a count of just those templates as dictated by base_pattern.

makes a list of sfn templates in the article

]]

local function count_sfn (Article_content, base_pattern, object)
	local _;
	local pattern;
	local total = 0;
	local sfn_template_name_list = {};

	for i, sfn_template in ipairs (data.sfn_template_patterns) do
		pattern = string.format	(base_pattern, sfn_template);					-- make a pattern for the selected template

		total = total + sfn_harv_info_get (Article_content, pattern, sfn_template_name_list, object);
	end

	collapsible_tables.sfn = template_name_table_make (sfn_template_name_list, 'sfn');

--mw.logObject (sfn_template_name_list, 'sfn_template_name_list')
	return total;
end


--[[--------------------------< C O U N T _ H A R V >----------------------------------------------------------

Using the list of harv templates, make a count of just those templates as dictated by base_pattern.

makes a list of harv templates in the article

]]

local function count_harv (Article_content, base_pattern, object)
	local _;
	local pattern;
	local total = 0;
	local harv_template_name_list = {};

	for i, harv_template in ipairs (data.harv_template_patterns) do
		pattern = string.format	(base_pattern, harv_template);					-- make a pattern for the selected template

		total = total + sfn_harv_info_get (Article_content, pattern, harv_template_name_list, object);
	end

	collapsible_tables.harv = template_name_table_make (harv_template_name_list, 'harv');

--mw.logObject (harv_template_name_list, 'harv_template_name_list')
	return total;
end


--[[--------------------------< C O U N T _ H A R V _ R E F S >------------------------------------------------

Using the list of harv templates, make a count of those references as dictated by base_pattern.

]]

local function count_harv_refs (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;

	for i, template in ipairs (data.harv_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cs1 template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ R E F B E G I N >--------------------------------------------------

Using the list of cleanup templates, make a count of those templates as dictated by base_pattern.

]]

local function count_refbegin (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	
	for i, template in ipairs (data.refbegin_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cleanup template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ R P >--------------------------------------------------------------

Using the list of cleanup templates, make a count of those templates as dictated by base_pattern.

]]

local function count_rp (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	
	for i, template in ipairs (data.rp_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cleanup template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ C L E A N U P >----------------------------------------------------

Using the list of cleanup templates, make a count of those templates as dictated by base_pattern.

]]

local function count_cleanup (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	
	for i, template in ipairs (data.cleanup_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cleanup template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ D E A D _ L I N K S >----------------------------------------------

Using the list of dead link templates, make a count of those templates as dictated by base_pattern.

]]

local function count_dead_links (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	
	for i, template in ipairs (data.dead_link_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected cleanup template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< C O U N T _ W E B A R C H I V E >----------------------------------------------

Using the list of webarchive aliases, make a count of those templates as dictated by base_pattern.

]]

local function count_webarchive (text, base_pattern)
	local _;
	local pattern;
	local count, total = 0, 0;
	
	for i, template in ipairs (data.webarchive_template_patterns) do
		pattern = string.format	(base_pattern, template);						-- make a pattern for the selected webarchive template
		_, count = mw.ustring.gsub (text, pattern, '%1');						-- count occurences of that pattern
		total = total + count;													-- accumulate a total
	end
	return total;
end


--[[--------------------------< H A S _ L D R >----------------------------------------------------------------

returns a string set to 'yes' if the article uses list defined references.  ldr uses {{reflist |refs=...}} or
<references>...</references>.  Here we do simple 'find's to make the determination.

It is also possible to do ldr with {{refbegin}} ... {{refend}} 

the pattern value is passed to this function but ignored
]]

local function has_ldr (text)
	local pattern;

	for i, template in ipairs (data.reflist_template_patterns) do
		pattern = string.format	('{{%%s*%s[^}]*|%%s*refs%%s*=%%s*[^}|]+', template);	-- make a pattern using the selected reflist template

		if mw.ustring.find (text, '{{%s*[Rr]eflist[^}]*|%s*refs%s*=%s*[^}|]+') then	-- does page use {{Reflist |refs=...}}?
			return 'yes'
		end
	end

	if mw.ustring.find (text, '<references>[^<]+') then							-- no reflist template, does page use <references>...</references>?
		return 'yes'
	else
		return 'no';
	end
end


--[[--------------------------< H A S _ U S E _ X X X _ D A T E S >--------------------------------------------

returns string set to either of 'dmy' or 'mdy'

TODO: needs companion |cs1-dates= support somehow ... 2 separate tests? one detects {{use xxx dates |cs1-dates=xx}} the other detects {{use xxx dates}}?
Also, detect conflicting |df= parameters?

]]

local global_df;

local function has_use_xxx_dates (text, pattern)
	local ret_val = 'no';														-- presume not found
	local df_template_patterns = {												-- table of redirects to {{Use dmy dates}} and {{Use mdy dates}}
		'{{ *[Uu]se (dmy) dates *[|}]',		-- 915k								-- sorted by approximate transclusion count
		'{{ *[Uu]se *(mdy) *dates *[|}]',	-- 161k
		'{{ *[Uu]se (DMY) dates *[|}]',		-- 2929
		'{{ *[Uu]se *(dmy) *[|}]',			-- 250 + 34
		'{{ *([Dd]my) *[|}]',				-- 272
		'{{ *[Uu]se (MDY) dates *[|}]',		-- 173
		'{{ *[Uu]se *(mdy) *[|}]',			-- 59 + 12
		'{{ *([Mm]dy) *[|}]',				-- 9
		'{{ *[Uu]se (MDY) *[|}]',			-- 3
		'{{ *([Dd]MY) *[|}]',				-- 2
		'{{ *([Mm]DY) *[|}]',				-- 0
--		'{{ *[Uu]se(mdy) *[|}]',
--		'{{ *[Uu]se(mdy)dates *[|}]',
--		'{{ *[Uu]se(dmy) *[|}]',
		}

	for _, pattern in ipairs (df_template_patterns) do							-- loop through the patterns looking for {{Use dmy dates}} or {{Use mdy dates}} or any of their redirects
		local start, _, match = text:find(pattern);								-- match is the three letters indicating desired date format

		if match then
			ret_val = match;													-- set return value to the global date format
			global_df = match;													-- save for |df= tests
			text = text:match ('%b{}', start);									-- get the whole use xxx dates template
			if text:match ('| *cs1%-dates *= *[lsy][sy]?') then					-- look for |cs1-dates=publication date length access-/archive-date length
				ret_val = ret_val .. ' [' .. text:match ('| *cs1%-dates *= *([lsy][sy]?)') .. ']';
			end
			break;																-- loop escape
		end
	end

	return ret_val;
end


--[[--------------------------< O B J E C T S   T A B L E >----------------------------------------------------

Here we define various properties and values necessary to the counting of referencing objects

]]

local objects = {
	['unnamed_refs'] = {														-- count unnamed ref tags
		['func'] = count_pattern,												-- the function that does the work for this object
		['pattern'] = '(<ref>)',												-- a pattern that the function uses to find and count this object
		['count'] = 0,															-- the returned result (called count because that is the most common but can be 'yes' or 'no' etc
		['label'] = 'unnamed refs'												-- a label and markup for displaying the result; used with string.format()
		},
	['named_refs'] = {															-- count named ref tags
		['func'] = count_pattern,
		['pattern'] = '(<ref%s+name%s*=%s*[%a%d%p ]+>)',
		['count'] = 0,
		['label'] = 'named refs'
		},
	['self_closed_refs'] = {													-- count self closed ref tags
		['func'] = count_pattern,
		['pattern'] = '(<ref%s*name%s*=%s*["%a%d%p ]+/>)',
		['count'] = 0,
		['label'] = 'self closed'
		},
	['r_templates'] = {															-- count R templates (wrapper for self closed refs)
		['func'] = count_pattern,
		['pattern'] = '({{%s*[Rr]%s*|)',
		['count'] = 0,
		['label'] = 'R templates'
		},
	['refn_templates'] = {														-- count Refn templates
		['func'] = count_pattern,
		['pattern'] = '({{%s*[Rr]efn%s*|)',
		['count'] = 0,
		['label'] = 'Refn templates'
		},
	['bare_url_refs'] = {														-- count bare url refs
		['func'] = count_pattern,												-- TODO: separate function to detect protocol relative urls?
		['pattern'] = '(<ref[^>]*>%s*http[^<%s]+%s*</ref>)',
		['count'] = 0,
		['label'] = '<span style="font-size:inherit" class="error">bare url refs</span>'
		},
	['ext_link_refs'] = {														-- count unlabeled external link refs
		['func'] = count_pattern,												-- TODO: separate function to detect protocol relative urls?
		['pattern'] = '(<ref[^>]*>%[%s*http[^%]<%s]+%][^<]*</ref>)',
		['count'] = 0,
		['label'] = '<span style="font-size:inherit" class="error">bare ext link refs</span>'
		},
	['cs1_like_refs'] = {														-- count cs1 refs and refs that look like cs1 (cite something)
		['func'] = count_cs1_like_refs,
		['pattern'] = '(<ref[^>]*>[^<{]*{{%s*[Cc]ite%s+[^|]+)',
		['count'] = 0,
		['label'] = 'cs1-like refs'
		},
	['cs1_refs'] = {															-- count cs1 refs only
		['func'] = count_cs1_refs,
		['pattern'] = '(<ref[^>]*>[^<{]*{{%%s*%s%%s*|)',						-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'cs1 refs'
		},
	['cs1_like_templates'] = {													-- count templates that look like cs1
		['func'] = count_cs1_like_templates,
		['pattern'] = '({{%s*[Cc]ite%s+[^|]+)',
		['count'] = 0,
		['label'] = 'cs1-like templates'
		},
	['cs1_templates'] = {														-- count cs1 templates only
		['func'] = count_cs1,
		['pattern'] = '({{%%s*%s%%s*|)',										-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'cs1 templates'
		},
	['cs2_refs'] = {															-- count cs2 refs
		['func'] = count_cs2_refs,
		['pattern'] = '(<ref[^>]*>[^<{]*{{%%s*%s%%s*|)',						-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'cs2 refs'
		},
	['cs2_templates'] = {														-- count cs2 templates
		['func'] = count_cs2,
		['pattern'] = '{{%%s*%s%%s*|',
		['count'] = 0,
		['label'] = 'cs2 templates'
		},
	['vcite_refs'] = {															-- count vancite, vcite, and vcite2 refs
--		['func'] = count_pattern,
--		['pattern'] = '(<ref[^>]*>[^<{]*{{%s*[Vv]a?n?cite2?%s+[^|]+)',
		['func'] = count_vcite_refs,
		['pattern'] = '(<ref[^>]*>[^<{]*{{%%s*%s%%s*|)',
		['count'] = 0,
		['label'] = 'vcite refs'
		},
	['vcite_templates'] = {														-- count vancite templates
		['func'] = count_vcite,
		['pattern'] = '{{%%s*%s%%s*|',
--		['func'] = count_pattern,
--		['pattern'] = '({{%s*[Vv]a?n?cite2?%s+[^|]+)',
		['count'] = 0,
		['label'] = 'vcite templates'
		},
	['wikicite_templates'] = {													-- count wikicite templates
		['func'] = count_pattern,
		['pattern'] = '({{%s*[Ww]ikicite%s*|)',
		['count'] = 0,
		['label'] = 'wikicite templates'
		},
	['harv_refs'] = {															-- count harv refs
		['func'] = count_harv_refs,
		['pattern'] = '(<ref[^>]*>[^<{]*{{%%s*%s%%s*|)',						-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'harv refs'
		},
	['harv_templates'] = {														-- count harv templates
		['func'] = count_harv,
		['pattern'] = '({{%%s*%s%%s*|)',
		['count'] = 0,
		['label'] = 'harv templates'
		},
	['sfn_templates'] = {														-- count sfn templates
		['func'] = count_sfn,
		['pattern'] = '({{%%s*%s%%s*|)',
		['count'] = 15,
		['label'] = 'sfn templates'
		},
	['rp_templates'] = {														-- count rp templates
		['func'] = count_rp,
		['pattern'] = '({{%%s*%s%%s*[|}])',
		['count'] = 0,
		['label'] = 'rp templates'
		},
	['ldr'] = {																	-- does this article use list defined references?
		['func'] = has_ldr,
		['pattern'] = '',														-- uses multiple patterns which are defined in the function
		['count'] = 'no',
		['label'] = 'uses ldr'
		},
	['refbegin_templates'] = {													-- count refbegin templates - bibliography lists
		['func'] = count_refbegin,
		['pattern'] = '({{%%s*%s%%s*[|}])',
		['count'] = 0,
		['label'] = 'refbegin templates'
		},
	['cleanup_templates'] = {													-- count cleanup templates
		['func'] = count_cleanup,
		['pattern'] = '({{%%s*%s%%s*[|}])',										-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'cleanup templates'
		},
	['dead_link_templates'] = {													-- count deadlink templates (includes redirects)
		['func'] = count_dead_links,
		['pattern'] = '({{%%s*%s%%s*[|}])',										-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'dead link templates'
		},
	['webarchive_templates'] = {												-- count webarchive templates (includes redirects)
		['func'] = count_webarchive,
		['pattern'] = '({{%%s*%s%%s*|)',										-- will be modified in the func by string.format()
		['count'] = 0,
		['label'] = 'webarchive templates'
		},
	['use_xxx_dates'] = {														-- does this article use list defined references?
		['func'] = has_use_xxx_dates,
		['pattern'] = nil,														-- uses multiple patterns that are defined in the function
		['count'] = 'no',
		['label'] = 'use xxx dates'
		},

	['cs1_dates_df_dmy'] = {													-- count 
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 df dmy'
		},
	['cs1_dates_df_mdy'] = {													-- count 
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 df mdy'
		},
	['cs1_dates_df_ymd'] = {													-- count 
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 df ymd'
		},

	['cs1_dmy_dates'] = {														-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 dmy dates'
		},
	['cs1_mdy_dates'] = {														-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 mdy dates'
		},
	['cs1_ymd_dates'] = {														-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 ymd dates'
		},
	['cs1_last'] = {															-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 last/first'
		},
	['cs1_author'] = {															-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 author'
		},
	['cs1_authors'] = {															-- count cs1 templates only
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 authors'
		},
	['cs1_vauthors'] = {
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1|2 vauthors'
		},
	['cs1_mode'] = {
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs1 mode'
		},
	['cs2_mode'] = {
		['func'] = nil,															-- handled by cs1_cs2_info_get()
		['pattern'] = nil,
		['count'] = 0,
		['label'] = 'cs2 mode'
		},
	}
																				-- here we set the order in which the objects are processed
local order = {'unnamed_refs', 'named_refs', 'self_closed_refs',				-- these three are always output
	'r_templates',																-- this and the others only produce output when ...
	'refn_templates',															-- ... their count is not 0 or not 'no'
	'bare_url_refs',
	'ext_link_refs',
	'cs1_refs',
	'cs1_templates',
	'cs1_like_refs',
	'cs1_like_templates',
	'cs2_refs',
	'cs2_templates',
	'vcite_refs', 'vcite_templates',
	'wikicite_templates',
	'harv_refs', 'harv_templates',
	'sfn_templates',
	'rp_templates',
	'ldr',
	'refbegin_templates',
	'cleanup_templates',
	'dead_link_templates',
	'webarchive_templates',
	'use_xxx_dates',
	'cs1_dates_df_dmy',
	'cs1_dates_df_mdy',
	'cs1_dates_df_ymd',
	'cs1_dmy_dates',
	'cs1_mdy_dates',
	'cs1_ymd_dates',
	'cs1_last',
	'cs1_author',
	'cs1_authors',
	'cs1_vauthors',
	'cs1_mode',
	'cs2_mode',
	};


--[[--------------------------< R E F _ I N F O >--------------------------------------------------------------

the working part of Template:Ref info

]]


local function ref_info (frame)
	local text;																	-- unparsed page content
	local title;																-- page title without namespace or interwiki references
	local nstitle;																-- page title with namespace and interwiki references
	local page_title_object;													-- 
	local output = {};
	local i=1;
	local style = frame.args.style or '';										-- styling css for output table
	
	if frame.args[1] then
		page_title_object = mw.title.new(frame.args[1]);						-- title object for the page specified in the template call
	else
		page_title_object = mw.title.getCurrentTitle();							-- title object for the current page
	end

	text = page_title_object:getContent();										-- the unparsed content of the selected page
	text = text:gsub ('<nowiki>.-</nowiki>', '');								-- remove nowiki tags and their content; less constrained
	text = text:gsub ('<!%-%-.-%-%->', '');										-- remove html comments and their content
	text = text:gsub ('<pre>.-</pre>', '');										-- remove pre tags and their content

	nstitle = page_title_object.prefixedText;									-- the title of the page (with namespace)
	title = page_title_object.text;												-- the title of the page (without namespace)

	if nil == text then
		return string.format ('<span style="font-size:100%%" class="error">{{ref info}} – page is empty or does not exist: %s</span>', frame.args[1] or 'no page');
	end

	for i, object in ipairs (order) do											-- loop through order and search for the related objects
		if objects[object].func then
			objects[object].count = objects[object].func (text, objects[object].pattern, objects)	-- do the search and store the result
		end
	end
																				-- for those that count duplicates remove the duplicates from the counts
	objects['named_refs'].count = objects['named_refs'].count - objects['self_closed_refs'].count;

	table.insert (output, string.format ('{| class="wikitable" style="text-align:right; %s"\n|+reference info for [[%s|%s]]', style, nstitle, title));	-- output table header

	for i, object in ipairs (order) do											-- loop through order and search for the related objects
		if i<=3 then															-- first three (reference tags) are always output
			table.insert (output, string.format ('%s\n|%s', objects[object].label, objects[object].count));
		elseif 'string' == type (objects[object].count) then					-- objects[object].count can be a string or a number
			if 'no' ~= objects[object].count then								-- if a string and not 'no' ...
				table.insert (output, string.format ('%s\n|%s', objects[object].label, objects[object].count));	-- output the result
			end
		elseif 'number' == type (objects[object].count) then					-- if a number ...
		 	if 0 < objects[object].count then									-- ... and count is greater than zero ...
				table.insert (output, string.format ('%s\n|%s', objects[object].label, objects[object].count));	-- ... output the result
			end
		end
	end

	output = {table.concat (output,'\n|-\n! scope="row" | ')};					-- concat an intermediate result
	table.insert (output, collapsible_tables.cs1);								-- add the collapsible tables
	table.insert (output, collapsible_tables.cs2);
	table.insert (output, collapsible_tables.cs1_like);
	table.insert (output, collapsible_tables.vcite);
	table.insert (output, collapsible_tables.sfn);
	table.insert (output, collapsible_tables.harv);
	table.insert (output, '\n|-\n|scope="row" colspan="2" style="text-align:center"|[[Template:Ref_info#Output_meanings|explanations]]\n|-\n|}');

	return table.concat (output);
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	ref_info = ref_info,
	}