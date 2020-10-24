require('Module:No globals');
local getArgs = require ('Module:Arguments').getArgs;


--[[--------------------------< I U C N _ I D E N T I F I E R S _ G E T >--------------------------------------

cs1|2 templates cite single sources;  when the identifiers in |doi=, |id=, and |page= are different from each other
then the template is attempting to cite multiple sources.  This function evaluates the identifier portions of these
parameters. returns seven values: identifyier parts (or nil when parameter not used) and a message (nil on success,
error message else)

the identifier portions of the several parameters must be properly formed

]]

local function iucn_identifiers_get (args)
	local doi_taxon_ID, doi_assesment_ID
	local page_taxon_ID, page_assesment_ID
	local id_taxon_ID, id_assesment_ID
	local url_taxon_ID, url_assesment_ID
	local msg
	
	if args.doi then
		doi_taxon_ID, doi_assesment_ID = args.doi:match ('[Tt](%d+)[Aa](%d+)%.en$')
		if not doi_taxon_ID then
			msg = 'malformed |doi= identifier'
		end
	end
	if args.page then
		page_taxon_ID, page_assesment_ID = args.page:match ('^[eE]%.[Tt](%d+)[Aa](%d+)$')
		if not page_taxon_ID then
			msg = 'malformed |page= identifier'
		end
	end
	if args.id then
		id_taxon_ID, id_assesment_ID = args.id:match ('^(%d+)/(%d+)$')
		if not id_taxon_ID then
			msg = 'malformed |id= identifier'
		end
	end
	if args.url then
		if args.url:match ('https://www.iucnredlist.org/species/') then			-- must be a 'new-form' url
			url_taxon_ID, url_assesment_ID = args.url:match ('/species/(%d+)/(%d+)')
			if not url_taxon_ID then
				msg = 'malformed |url= identifier'
			end
		end
	end

	if not msg then
		if doi_taxon_ID and page_taxon_ID then
			if not (doi_taxon_ID == page_taxon_ID and doi_assesment_ID == page_assesment_ID) then
				msg = '|doi= / |page= mismatch'
			end
		end
		if doi_taxon_ID and id_taxon_ID then
			if not (doi_taxon_ID == id_taxon_ID and doi_assesment_ID == id_assesment_ID) then
				msg = '|doi= / |id= mismatch'
			end
		end
		if doi_taxon_ID and url_taxon_ID then
			if not (doi_taxon_ID == url_taxon_ID and doi_assesment_ID == url_assesment_ID) then
				msg = '|doi= / |url= mismatch'
			end
		end
		
		if page_taxon_ID and id_taxon_ID then
			if not (page_taxon_ID == id_taxon_ID and page_assesment_ID == id_assesment_ID) then
				msg = '|page= / |id= mismatch'
			end
		end
		if page_taxon_ID and url_taxon_ID then
			if not (page_taxon_ID == url_taxon_ID and page_assesment_ID == url_assesment_ID) then
				msg = '|page= / |url= mismatch'
			end
		end

		if id_taxon_ID and url_taxon_ID then
			if not (id_taxon_ID == url_taxon_ID and id_assesment_ID == url_assesment_ID) then
				msg = '|id= / |url= mismatch'
			end
		end
	end

	if msg then
		msg = '<span class="error" style="font-size:100%">{{cite iucn}}: error: ' .. msg .. ' ([[Template:Cite iucn|help]])</span>'
	end
	
	return doi_taxon_ID, doi_assesment_ID, page_taxon_ID, page_assesment_ID, id_taxon_ID, id_assesment_ID, msg
end


--[[--------------------------< I U C N _ V O L U M E _ C H E C K >--------------------------------------------

compares volume in |volume= (if present) against year in |date= or |year= (if present) against volume in |doi= (if present)

returns nil if all that are present are correct; message else

]]

local function iucn_volume_check (args)
	local vol = args.volume;
	local date = args.date or args.year;
	local doi = args.doi and args.doi:match ('[Ii][Uu][Cc][Nn]%.[Uu][Kk]%.(%d%d%d%d)')
	local msg
	
	if vol and date then
		msg = (vol ~= date) and '|volume= / |date= mismatch' or msg
	end
	if vol and doi then
		msg = (vol ~= doi) and '|volume= / |doi= mismatch' or msg
	end
	if date and doi then
		msg = (doi ~= date) and '|date= / |doi= mismatch' or msg
	end
	
	return msg
end


--[[--------------------------< C I T E >----------------------------------------------------------------------

Wraps {{cite journal}}:
     takes cite journal parameters but updates old style url using electronic page number
     page should be in format e.T13922A45199653
     the url uses                13922/45199653
     so we need to extract the number between T and A (taxon ID) and the number after A (assessment ID)
     the target url is https://www.iucnredlist.org/species/13922/45199653
     usage: {{#invoke:iucn|cite}}
     template: {{Template:Cite iucn}}

]]

local function cite (frame)
	local error_msgs = {};														-- holds error messages for rendering
	local maint_msgs = {};														-- holds hidden maint messages for rendering
	local namespace = mw.title.getCurrentTitle().namespace;						-- used for categorization
	local args = getArgs (frame);												-- local copy of template arguments

	local missing_title = not args.title										-- special case that results from script writing {{cite iucn}} template from bare iucn url
																				-- don't duplicate cs1|2 error message; don't duplicate {{cite iucn}} error cat
																				-- TODO: remove this when the error category has been cleared of missing title errors

	local doi_taxon_ID, doi_assesment_ID										-- all of these contain the same identifying info in slightly
	local page_taxon_ID, page_assesment_ID										-- different forms. when any combination of these is present,
	local id_taxon_ID, id_assesment_ID											-- they must all agree
	local msg																	-- this holds error messages; nil on success

	doi_taxon_ID, doi_assesment_ID, page_taxon_ID, page_assesment_ID, id_taxon_ID, id_assesment_ID, msg = iucn_identifiers_get (args);
	if msg then
		table.insert (error_msgs, msg);											-- malformed or mismatched identifiers
	end
	args.id = nil																-- unset; no longer needed if it was set

	local url_taxon_ID = page_taxon_ID or id_taxon_ID or doi_taxon_ID;			-- select for use in url that we will create
	local url_assesment_ID = page_assesment_ID or id_assesment_ID or doi_assesment_ID
	
	local url = args.url
	if url then
		if url:find ('iucnredlist.org/details/', 1, true) then					-- old-form url
			if url_taxon_ID then												-- when there is an identifier
				url = nil														-- unset; we'll create new url below
			else																-- here when old-form but no identifier that we can use to create new url
				args.url = args.url:gsub ("http:", "https:")					-- sometimes works with redirect on iucn site
			end
			table.insert (maint_msgs, 'old-form url')							-- announce that this template has has an old-form url
		elseif url:find ('iucnredlist.org/species/', 1, true) then				-- new-form url
--			table.insert (maint_msgs, 'new-form url')				--TODO: restore this line when most new-form urls have been removed from article space		-- announce that this template has has an new-form url
		else
			table.insert (maint_msgs, 'unknown url')							-- announce that this template has has some sort of url we don't recognize
		end
	end

	if not url then																-- when no url or unset old-form url
		if url_taxon_ID then
			args.url = "https://www.iucnredlist.org/species/" .. url_taxon_ID .. '/' .. url_assesment_ID
		else
			table.insert (maint_msgs, 'no identifier')							-- TODO: raise this to  error status?
		end
	end

	-- add journal if not provided (TODO decide if this should override provided value)
	if not args['journal'] and not args['work'] then
		args['journal'] = "[[IUCN Red List|IUCN Red List of Threatened Species]]"
	end
	
	msg = iucn_volume_check (args);												-- |volume=, |year= (|date=), |doi= must all refer to the same volume
	if msg then
		table.insert (maint_msgs, msg);
	end

	if not args.volume and (args.year or args.date) then
		args.volume = args.year or args.date
	end
																				-- add free-to-read icon to mark a correctly formed doi
	args['doi-access'] = args.doi and args.doi:match ('10%.2305/[Ii][Uu][Cc][Nn].+[Tt]%d+[Aa]%d+%.[Ee][Nn]') and 'free' or nil
		
	return frame:expandTemplate{ title = 'cite journal', args = args } ..							-- the template
		(((0 == #error_msgs) and missing_title) and ('[[Category:cite iucn errors]]') or '') ..		-- special case to not duplicate cs1|2 err msg or cite iucn error cat
		((0 < #error_msgs) and table.concat (error_msgs, ', ') or '') ..							-- the error messages
		(((0 < #error_msgs) and (0 == namespace)) and ('[[Category:cite iucn errors]]') or '') ..	-- error category when in mainspace
		((0 < #maint_msgs) and ('<span class="citation-comment" style="display: none; color: #33aa33; margin-left: 0.3em;">' .. table.concat (maint_msgs, ', ') .. '</span>') or '') ..	-- the maint messages
		(((0 < #maint_msgs) and (0 == namespace)) and ('[[Category:cite iucn maint]]') or '')		-- maint category when in mainspace
end


--[[--------------------------< A U T H O R _ L I S T _ M A K E >----------------------------------------------

creates a list of individual |authorn= parameters from the list of names provided in the raw iucn citation.  names
must have the form: Surname, I. (more than one 'I.' pair allowed but no spaces between I. pairs)

assumes that parenthetical text at the end of the author-name-list is a collaboration
	Name, I.I., & Name, I.I. (Colaboration name)

]]

local function author_names_get (raw_iucn_cite)
	local list = {};															-- table that holds name list parts
	local author_names = raw_iucn_cite:match ('^([^%d]-)%s+%d%d%d%d');			-- extract author name-list from raw iucn citation
	local collaboration = author_names:match ('%s*(%b())$');					-- get collaboration name if it exists

	if collaboration then														-- when there is a colaboration
		collaboration = collaboration:gsub ('[%(%)]', '');						-- remove bounding parentheses
		author_names = author_names:gsub ('%s*(%b())$', '');					-- and remove collaboration from author-name-list
	end
	
	local names = author_names:gsub ('%.?,?%s+&%s+', '.|'):gsub ('%.,%s+', '.|');	-- replace 'separators' (<dot><comma><space> and <opt. dot><opt. comma><space><ampersand><space>) with <dot><pipe>
	list = mw.text.split (names, '|');											-- split the string on the pipes into entries in list{}
	
	if 0 == #list then
		return table.concat ({'|author=', author_names})						-- no 'names' of the proper form; return the original as a single |author= parameter
	else
		for i, name in ipairs (list) do											-- spin through the list and 
--			list[i] = table.concat ({'|author', i, '=', name});					-- add |authorn= parameter names
			list[i] = table.concat ({'|author', (i == 1) and '' or i, '=', name});	-- add |authorn= parameter names; create |author= instead of |author1=
		end
		if collaboration then
			table.insert (list, table.concat ({'|collaboration', '=', collaboration}));	-- add |collaboration= parameter
		end
		return table.concat (list, ' ');										-- make a big string and return that
	end
end


--[[--------------------------< T I T L E _ G E T >------------------------------------------------------------

extract and format citation title; attempts to get the italic right

''binomen'' (amended or errata title)
''binomen''
''binomen'' ssp. ''subspecies''
''binomen'' subsp. ''subspecies''
''binomen'' var. ''variety''
''binomen'' subvar. ''subvariety''

all of the above may have trailing amended or errata text in parentheses

TODO: are there others?

]]

local function title_get (raw_iucn_cite)
	local title = raw_iucn_cite:match ('%d%d%d%d%.%s+(.-)%s*%. The IUCN Red List of Threatened Species');

	local patterns = {															-- tables of string.match patterns [1] and string.gsub patterns [2]
		{'(.-)%sssp%.%s+(.-)%s(%b())$', "''%1'' ssp. ''%2'' %3"},				-- binomen ssp. subspecies (zoology) with errata or amended text
		{'(.-)%sssp%.%s+(.+)', "''%1'' ssp. ''%2''"},							-- binomen ssp. subspecies (zoology)
		{'(.-)%ssubsp%.%s+(.-)%s(%b())$', "''%1'' subsp. ''%2'' %3"},			-- binomen subsp. subspecies (botany) with errata or amended text
		{'(.-)%ssubsp%.%s+(.+)', "''%1'' subsp. ''%2''"},						-- binomen subsp. subspecies (botany)
		{'(.-)%svar%.%s+(.-)%s+(%b())$', "''%1'' var. ''%2'' %3"},				-- binomen var. variety (botany) with errata or amended text
		{'(.-)%svar%.%s+(.+)', "''%1'' var. ''%2''"},							-- binomen var. variety (botany)
		{'(.-)%ssubvar%.%s+(.-)%s(%b())$', "''%1'' subvar. ''%2'' %3"},			-- binomen subvar. subvariety (botany) with errata or amended text
		{'(.-)%ssubvar%.%s+(.+)', "''%1'' subvar. ''%2''"},						-- binomen subvar. subvariety (botany)
		{'(.-)%s*(%b())$', "''%1'' %2"},										-- binomen with errata or amended text
		{'(.+)', "''%1''"},														-- binomen
		}
	
	for i, v in ipairs (patterns) do											-- spin through the patterns
		if title:match (v[1]) then												-- when a match
			title = title:gsub (v[1], v[2]);									-- add italics 
			break;																-- and done
		end
	end

	return table.concat ({' |title=', title});									-- return the |title= parameter
end


--[[--------------------------< M A K E _ C I T E _ I U C N >--------------------------------------------------

parses apart an iucn-format citation copied from their webpage and reformats that into a {{cite iucn}} template for substing

automatic substing by User:AnomieBOT/docs/TemplateSubster

]]

local function make_cite_iucn (frame)
	local args = getArgs (frame);
	local raw_iucn_cite = args[1];
	
	local template = {'{{cite iucn '};											-- table that holds the {{cite iucn}} template as it is being assembled
	local year, volume, page, doi, accessdate;

	year = raw_iucn_cite:match ('^%D+(%d%d%d%d)');
	volume, page = raw_iucn_cite:match ('(%d%d%d%d):%s+(e%.T%d+A+%d+)%.%s');
	doi = raw_iucn_cite:match ('10%.2305/IUCN%.UK%.[%d%-]+%.RLTS%.T%d+A%d+%.en');

	accessdate = raw_iucn_cite:match ('Downloaded on (.-)%.?$'):gsub ('^0', '');	-- strips leading 0 in day 01 January 2020 -> 1 January 2020

	table.insert (template, author_names_get (raw_iucn_cite));					-- add string of author name parameters
	table.insert (template, table.concat ({' |year=', year}));					-- add formatted year
	table.insert (template, title_get (raw_iucn_cite));							-- add formatted title
	table.insert (template, table.concat ({' |volume=', volume}));				-- add formatted volume
	table.insert (template, table.concat ({' |page=', page}));					-- add formatted page
	table.insert (template, table.concat ({' |doi=', doi}));					-- add formatted doi
	table.insert (template, table.concat ({' |access-date=', accessdate}));		-- add formatted access-date
	table.insert (template, '}}');												-- close the template

	if args[2] then																-- if anything in args[2], write a nowiki'd version that editors can copy into <ref> tags
		return table.concat ({'<code>', frame:callParserFunction ('#tag:nowiki', table.concat (template)), '</code>'})
	end
	if args['ref'] then                                                         -- enable subst of ref tags with name
		return '<ref name=' .. args['ref'] .. '>' .. table.concat (template) .. '</ref>'
	end
	return table.concat (template);												-- the subst'd version
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	cite = cite,
	make_cite_iucn = make_cite_iucn,
	}