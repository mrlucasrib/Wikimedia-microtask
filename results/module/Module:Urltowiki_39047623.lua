-- This module takes a URL from a Wikimedia project and returns the equivalent wikitext. 
-- Any actions such as edit, history, etc., are stripped, and percent-encoded characters 
-- are converted to normal text.

local p = {}
local current_lang = mw.language.getContentLanguage()

local interwiki_table = mw.loadData("Module:InterwikiTable")

local function getHostId(host)
	if type(host) ~= "string" then return end
	for id, t in pairs(interwiki_table) do
		if mw.ustring.match(host, t.domain) and t.domain_primary then -- Match partial domains (e.g. "www.foo.org" and "foo.org") but don't match non-primary domains.
			return id
		end
	end
end

local function getInterwiki(host)
	-- This function returns a table with information about the interwiki prefix of the specified host.
	local ret = {}

	-- Return a blank table for invalid input.
	if type(host) ~= "string" then
		return ret
	end

	-- Get the host ID.
	host = mw.ustring.lower(host)
	local host_id = getHostId(host)
	if not host_id then
		return ret
	end
	ret.host_id = host_id

	-- Find the language in the interwiki prefix, if applicable.
	local lang = mw.ustring.match(host, "^(.-)%.") -- Find the text before the first period.
	if not lang or not mw.language.isSupportedLanguage(lang) then -- Check if lang is a valid language code.
		lang = false
	end
	-- A language prefix is not necessary if there is already a language prefix for the host in the interwiki table.
	local domain_lang = mw.ustring.match(interwiki_table[host_id].domain, "^(.-)%.") -- Find the text before the first period.
	if  mw.language.isSupportedLanguage(domain_lang) then
		lang = false
	end
	ret.lang = lang

	-- No need for an interwiki link if we are on the same site as the URL.
	local current_host = mw.uri.new(mw.title.getCurrentTitle():fullUrl()).host -- Get the host portion of the current page URL.
	if host == current_host then
		return ret
	end

	-- Check if the URL language is the same as the current language.
	local same_lang
	if lang and lang == mw.ustring.match(current_host, "^(.-)%.") then
		same_lang = true
	end

	-- Check if the project is the same as the current project (but a different language).
	local current_host_id = getHostId(current_host)
	local same_project
	if current_host_id == host_id then
		same_project = true
	end

	-- Find the interwiki prefix.
	local interwiki
	local project = interwiki_table[host_id].iw_prefix[1]
	if same_lang or ( not lang and interwiki_table[host_id].takes_lang_prefix == false ) then
		interwiki = project
	elseif same_project then
		interwiki = lang
	elseif not lang then -- If the language code is bad but the rest of the host name is ok.
		interwiki = nil
	else
		interwiki = project .. ":" .. lang
	end   
	ret.interwiki = interwiki

	return ret
end

function p._urlToWiki(args)
	-- Check the input is valid.

	local input = args[1] or args.url
	if type(input) ~= "string" then
		if args.error ~= "no" then
			if type(input) == "nil" then
				error("No URL specified", 2)
			else
				error("The URL must be a string value", 2)
			end
		else
			return ""
		end
	end
	input = mw.text.trim(input)

	-- Get the URI object.
	url = mw.uri.new(input)
	local host = url.host

	-- Get the interwiki prefix.
	local interwiki, lang, host_id
	if host then
		local iw_data = getInterwiki(host)
		interwiki, lang, host_id = iw_data.interwiki, iw_data.lang, iw_data.host_id
	end
	local link = true -- This decides whether the resulting wikitext will be linked or not. Default is yes.
	if args.link == "no" then
		link = false
	end

	-- Get the page title.
	local pagetitle, title_prefix
	if host_id and not ( interwiki_table[host_id].takes_lang_prefix == true and not lang ) then
		title_prefix = interwiki_table[host_id].title_prefix
	end
	-- If the URL path starts with the title prefix in the interwiki table, use that to get the title.
	if title_prefix and mw.ustring.sub(url.path, 1, mw.ustring.len(title_prefix)) == title_prefix then
		pagetitle = mw.ustring.sub(url.path, mw.ustring.len(title_prefix) + 1, -1)
		-- Else, if the URL is a history "index.php", use url.query.title. Check for host_id
		-- in case the URL isn't of a Wikimedia site.
	elseif host_id and mw.ustring.match(url.path, "index%.php") and url.query.title then
		pagetitle = url.query.title
		-- Special case for Bugzilla.
	elseif host_id == "bugzilla" and url.query.id then
		pagetitle = url.query.id
	elseif host_id == "bugzilla" and not url.query.id then
		interwiki = false -- disable the interwiki prefix as we are returning a full URL.
		link = false -- don't use double square brackets for URLs.
		pagetitle = tostring(url)
		-- If the URL is valid but not a recognised interwiki, use the URL and don't link it.
	elseif host and not host_id then
		link = false -- Don't use double square brackets for URLs.
		pagetitle = tostring(url)
		-- Otherwise, use our original input minus any fragment
	else
		pagetitle = mw.ustring.match(input, "^(.-)#") or input
	end

	-- Get the fragment and pre-process percent-encoded characters.
	local fragment = url.fragment -- This also works for non-urls like "Foo#Bar".
	if fragment then
		fragment = mw.ustring.gsub(fragment, "%.([0-9A-F][0-9A-F])", "%%%1")
	end

	-- Assemble the wikilink.
	local wikitext = pagetitle
	if interwiki then
		wikitext = interwiki .. ":" .. wikitext
	end
	if fragment and not (args.section == "no") then
		wikitext = wikitext .. "#" .. fragment
	end

	-- Decode percent-encoded characters and convert underscores to spaces.
	wikitext = mw.uri.decode(wikitext, "WIKI")
	-- If the wikitext is to be linked, re-encode illegal characters. Don't re-encode 
	-- characters from invalid URLs to make the default [[{{{1}}}]] display correctly.
	if link and host then
		wikitext = mw.ustring.gsub(wikitext, "[<>%[%]|{}%c\n]", mw.uri.encode)
	end

	-- Find the display value
	local display
	if link then
		display = args[2] or args.display -- The display text in piped links.
		if (display and type(display) ~= "string") then
			if args.error ~= "no" then
				error("Non-string display value detected")
			else
				display = nil
			end
		end
		if display then
			display = mw.text.trim(display) -- Trim whitespace.
			-- If the page name is the same as the display value, don't pipe
			-- the link.
			if current_lang:lcfirst(wikitext) == display then
				wikitext = display
				display = nil
			elseif wikitext == display then
				display = nil
			end
		end
	end

	-- Use the [[Help:Colon trick]] with categories, interwikis, and files.
	local colon_prefix = mw.ustring.match(wikitext, "^(.-):.*$") or "" -- Get the text before the first colon.
	local ns = mw.site.namespaces
	local need_colon_trick
	if mw.language.isSupportedLanguage(colon_prefix) -- Check for interwiki links.
		or current_lang:lc(ns[6].name) == current_lang:lc(colon_prefix) -- Check for files.
		or current_lang:lc(ns[14].name) == current_lang:lc(colon_prefix) then -- Check for categories.
		need_colon_trick = true
	end
	for i,v in ipairs(ns[6].aliases) do -- Check for file namespace aliases.
		if current_lang:lc(v) == current_lang:lc(colon_prefix) then
			need_colon_trick = true
			break
		end
	end
	for i,v in ipairs(ns[14].aliases) do -- Check for category namespace aliases.
		if current_lang:lc(v) == current_lang:lc(colon_prefix) then
			need_colon_trick = true
			break
		end
	end
	-- Don't use the colon trick if the user says so or if we are not linking
	-- (due to [[bugzilla:12974]]).
	if need_colon_trick and link and args.colontrick ~= "no" then
		wikitext = ":" .. wikitext
	end

	-- Make the link
	if link then
		if display then
			wikitext = wikitext .. '|' .. display
		end
		wikitext = "[[" .. wikitext .. "]]"
	end

	return wikitext
end

function p.urlToWiki(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = {'Template:Urltowiki','Template:Urltowiki/sandbox'}
	})
	return p._urlToWiki(args)
end

return p