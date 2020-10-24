require('Module:No globals')

local citeq = {}

--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Returns true if argument is set; false otherwise. Argument is 'set' when it exists (not nil) or when it is not an empty string.

]]
local function is_set( var )
	return not (var == nil or var == '');
end


--[=[-------------------------< G E T _ N A M E _ L I S T >----------------------------------------------------

get_name_list -- adapted from getAuthors code taken from [[Module:RexxS]]
arguments:
	nl_type - type of name list to fetch: nl_type = 'author' for authors; 'editor' for editors
	args - pointer to the parameter arguments table from the template call
	qid - value from |qid= parameter; the Q-id of the source (book, etc.) in qid
	wdl - value from the |wdlinks= parameter; a boolean passed to enable links to Wikidata when no article exists

returns nothing; modifies the args table

]=]

local function get_name_list (nl_type, args, qid, wdl)
	local propertyID = "P50"
	local fallbackID = "P2093" -- author name string
	
	if 'author' == nl_type then
		propertyID = 'P50';														-- for authors
		fallbackID = 'P2093';
	elseif 'editor' == nl_type then
		propertyID = 'P98';														-- for editors
		fallbackID = nil;
	else
		return;																	-- not specified so return
	end
	
	-- wdlinks is a boolean passed to enable links to Wikidata when no article exists
	-- if "false" or "no" or "0" is passed set it false
	-- if nothing or an empty string is passed set it false
	if wdl and (#wdl > 0) then
		wdl = wdl:lower()
		wdl = (wdl == "false") or (wdl == "no") or (wdl == "0")
	else
		-- wdl is empty, so
		wdl = false
	end
	
	local entity = mw.wikibase.getEntity(qid)
	local props = nil
	local fallback = nil
	if entity and entity.claims then
		props = entity.claims[propertyID]
		if fallbackID then
			fallback = entity.claims[fallbackID]
		end
	end
	
	-- Make sure it actually has at least one of the properties requested
	if not (props and props[1]) and not (fallback and fallback[1]) then 
		return nil
	end
	
	-- So now we have something to return:
	-- table 'out' is going to store the names(s):
	-- and table 'link' will store any links to the name's article
	local out = {}
	local link = {}
	local maxpos = 0
	if props and props[1] then
		for k, v in pairs(props) do
			local qnumber = "Q" .. v.mainsnak.datavalue.value["numeric-id"]
			local sitelink = mw.wikibase.sitelink(qnumber)
			local label = mw.wikibase.label(qnumber)
			if label then
				label = mw.text.nowiki(label)
			else
				label = qnumber
			end
			local position = maxpos + 1 -- Default to 'next' author.
			-- use P1545 (series ordinal) instead of default position.
			if v["qualifiers"] and v.qualifiers["P1545"] and v.qualifiers["P1545"][1] then
				position = tonumber(v.qualifiers["P1545"][1].datavalue.value)
			end
			maxpos = math.max(maxpos, position)
			if sitelink then
				-- just the plain name,
				-- but keep a record of the links, using the same index
				out[position] = label
				link[position] = sitelink
			else
				-- no sitelink, so check first for a redirect with that label
				-- this code works, but causes the article to appear in WhatLinksHere for the possible destination, so remove
				-- local artitle = mw.title.new(label, 0)
				-- if artitle.id > 0 then
				--	if artitle.isRedirect then
						-- no sitelink,
						-- but there's a redirect with the same title as the label;
						-- so store the link to that
				--		out[position] = label
				--		link[position] = label
				--	else
						-- no sitelink and not a redirect but an article exists with the same title as the label
						-- that's probably a dab page, so output the plain label
				--		out[position] = label
				--	end
				--else
				-- no article or redirect with the same title as the label
				if wdl then
					-- show that there's a Wikidata entry available
					out[position] = "[[:d:Q" .. v.mainsnak.datavalue.value["numeric-id"] .. "|" .. label .. "]]&nbsp;<span title='" .. i18n["errors"]["local-article-not-found"] .. "'>[[File:Wikidata-logo.svg|16px|alt=|link=]]</span>"
				else
					-- no wikidata links wanted, so just give the plain label
					out[position] = label
				end
				-- end
			end
		end
	end
	if fallback and fallback[1] then
		-- Fallback to name-only authors / editors
		for k, v in pairs(fallback) do
			local label = v.mainsnak.datavalue["value"]
			local position = maxpos + 1 -- Default to 'next' author.
			-- use P1545 (series ordinal) instead of default position.
			if v["qualifiers"] and v.qualifiers["P1545"] and v.qualifiers["P1545"][1] then
				position = tonumber(v.qualifiers["P1545"][1].datavalue.value)
			end
			maxpos = math.max(maxpos, position)
			out[position] = label
		end
	end

	-- if there's anything to return, then insert the additions in the template arguments table
	-- in the form |author1=firstname secondname |author2= ...
	-- Renumber, in case we have inconsistent numbering
	local keys = {}
	for k,v in pairs(out) do
		keys[#keys+1] = k
	end
	table.sort(keys) -- as they might be out of order
	for i, k in ipairs(keys) do
		mw.log(i.." "..k.." "..out[k])
		args[nl_type .. i] = out[k]												-- author-n or editor-n
		if link[k] then
			args[nl_type .. '-link' .. i] = link[k]								-- author-linkn or editor-linkn
		end
	end
end


--[[-------------------------< C I T E _ Q >------------------------------------------------------------------

Takes standard cs1|2 template parameters and passes all to {{citation}}.  If neither of |author= and |author1=
are set, calls get_authors() to try to get an author name-list from wikidata.  The result is passed to 
{{citation}} for rendering.

]]

function citeq.cite_q (frame)
local citeq_args = {};
local qid;
local wdl;

local pframe = frame:getParent()
local args = pframe.args;														-- first get parent frame arguments - these from the template call

	for k, v in pairs (args) do													-- copy named parameters and their values into citeq_args
		if type( k ) == 'string' then											-- numbered parameters ignored
			if 'unset' == v then
				citeq_args[k] = '';												-- set the parameter to empty string; this may be used later to unset authors and editors
			else
				citeq_args[k] = v;
			end
		end
	end
	
	args = frame.args;															-- now get frame arguments (from the template wikisource) 

	for k, v in pairs (args) do													-- copy args into citeq_args
		if 'qid' == k then														-- don't copy qid
			qid = v;															-- save its value
		elseif 'wdlinks' == k then												-- don't copy wdlinks
			wdl = v;															-- save its value
		else
			citeq_args[k] = v													-- but copy everything else
		end
	end

	if is_set (qid) then
		if not is_set (citeq_args.author) and not is_set (citeq_args.author1) then	-- if neither are set, try to get authors from wikidata
			get_name_list ('author', citeq_args, qid, wdl);						-- modify citeq_args table with authors from wikidata
		end

		if not is_set (citeq_args.editor) and not is_set (citeq_args.editor1) then	-- if neither are set, try to get editors from wikidata
			get_name_list ('editor', citeq_args, qid, wdl);						-- modify citeq_args table with editors from wikidata
		end
	end

	return frame:expandTemplate{title = 'citation', args = citeq_args};			-- render the citation
end

return citeq