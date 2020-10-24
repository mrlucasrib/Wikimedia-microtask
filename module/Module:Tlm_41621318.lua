local export = {}

local variables_nullary = {
	["CURRENTYEAR"] = "mw:Help:Magic words#Date and time";
	["CURRENTMONTH"] = "mw:Help:Magic words#Date and time";
	["CURRENTMONTH1"] = "mw:Help:Magic words#Date and time"; -- undocumented
	["CURRENTMONTH2"] = "mw:Help:Magic words#Date and time"; -- undocumented
	["CURRENTMONTHNAME"] = "mw:Help:Magic words#Date and time";
	["CURRENTMONTHNAMEGEN"] = "mw:Help:Magic words#Date and time";
	["CURRENTMONTHABBREV"] = "mw:Help:Magic words#Date and time";
	["CURRENTDAY"] = "mw:Help:Magic words#Date and time";
	["CURRENTDAY2"] = "mw:Help:Magic words#Date and time";
	["CURRENTDOW"] = "mw:Help:Magic words#Date and time";
	["CURRENTDAYNAME"] = "mw:Help:Magic words#Date and time";
	["CURRENTTIME"] = "mw:Help:Magic words#Date and time";
	["CURRENTHOUR"] = "mw:Help:Magic words#Date and time";
	["CURRENTWEEK"] = "mw:Help:Magic words#Date and time";
	["CURRENTTIMESTAMP"] = "mw:Help:Magic words#Date and time";

	["LOCALYEAR"] = "mw:Help:Magic words#Date and time";
	["LOCALMONTH"] = "mw:Help:Magic words#Date and time";
	["LOCALMONTH1"] = "mw:Help:Magic words#Date and time"; -- undocumented
	["LOCALMONTH2"] = "mw:Help:Magic words#Date and time"; -- undocumented
	["LOCALMONTHNAME"] = "mw:Help:Magic words#Date and time";
	["LOCALMONTHNAMEGEN"] = "mw:Help:Magic words#Date and time";
	["LOCALMONTHABBREV"] = "mw:Help:Magic words#Date and time";
	["LOCALDAY"] = "mw:Help:Magic words#Date and time";
	["LOCALDAY2"] = "mw:Help:Magic words#Date and time";
	["LOCALDOW"] = "mw:Help:Magic words#Date and time";
	["LOCALDAYNAME"] = "mw:Help:Magic words#Date and time";
	["LOCALTIME"] = "mw:Help:Magic words#Date and time";
	["LOCALHOUR"] = "mw:Help:Magic words#Date and time";
	["LOCALWEEK"] = "mw:Help:Magic words#Date and time";
	["LOCALTIMESTAMP"] = "mw:Help:Magic words#Date and time";

	["SITENAME"] = "mw:Help:Magic words#Technical metadata";
	["SERVER"] = "mw:Help:Magic words#Technical metadata";
	["SERVERNAME"] = "mw:Help:Magic words#Technical metadata";
	["DIRMARK"] = "mw:Help:Magic words#Technical metadata";
	["DIRECTIONMARK"] = "mw:Help:Magic words#Technical metadata";
	["ARTICLEPATH"] = "mw:Help:Magic words#Technical metadata"; -- undocumented
	["SCRIPTPATH"] = "mw:Help:Magic words#Technical metadata";
	["STYLEPATH"] = "mw:Help:Magic words#Technical metadata";
	["CURRENTVERSION"] = "mw:Help:Magic words#Technical metadata";
	["CONTENTLANGUAGE"] = "mw:Help:Magic words#Technical metadata";
	["CONTENTLANG"] = "mw:Help:Magic words#Technical metadata";

	["PAGEID"] = "mw:Help:Magic words#Technical metadata";
	["CASCADINGSOURCES"] = "mw:Help:Magic words#Technical metadata";
	
	["REVISIONID"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONDAY"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONDAY2"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONMONTH"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONMONTH1"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONYEAR"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONTIMESTAMP"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONUSER"] = "mw:Help:Magic words#Technical metadata";
	["REVISIONSIZE"] = "mw:Help:Magic words#Technical metadata";
	
	["NUMBEROFPAGES"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFARTICLES"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFFILES"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFEDITS"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFVIEWS"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFUSERS"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFADMINS"] = "mw:Help:Magic words#Technical metadata";
	["NUMBEROFACTIVEUSERS"] = "mw:Help:Magic words#Technical metadata";
	
	["FULLPAGENAME"] = "mw:Help:Magic words#Page names";
	["PAGENAME"] = "mw:Help:Magic words#Page names";
	["BASEPAGENAME"] = "mw:Help:Magic words#Page names";
	["SUBPAGENAME"] = "mw:Help:Magic words#Page names";
	["SUBJECTPAGENAME"] = "mw:Help:Magic words#Page names";
	["ARTICLEPAGENAME"] = "mw:Help:Magic words#Page names";
	["TALKPAGENAME"] = "mw:Help:Magic words#Page names";
	["ROOTPAGENAME"] = "mw:Help:Magic words#Page names"; -- undocumented

	["FULLPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["PAGENAMEE"] = "mw:Help:Magic words#Page names";
	["BASEPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["SUBPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["SUBJECTPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["ARTICLEPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["TALKPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["ROOTPAGENAMEE"] = "mw:Help:Magic words#Page names"; -- undocumented

	["NAMESPACE"] = "mw:Help:Magic words#Namespaces";
	["NAMESPACENUMBER"] = "mw:Help:Magic words#Namespaces";
	["SUBJECTSPACE"] = "mw:Help:Magic words#Namespaces";
	["ARTICLESPACE"] = "mw:Help:Magic words#Namespaces";
	["TALKSPACE"] = "mw:Help:Magic words#Namespaces";

	["NAMESPACEE"] = "mw:Help:Magic words#Namespaces";
	["SUBJECTSPACEE"] = "mw:Help:Magic words#Namespaces";
	["TALKSPACEE"] = "mw:Help:Magic words#Namespaces";

	["!"] = "mw:Help:Magic words#Other";
	
	-- case-insensitive!
	["noexternallanglinks"] = "mw:Extension:Wikibase Client";
 	["pendingchangelevel"] = "mw:Extension:FlaggedRevs"; -- not documented yet
}

local variables_nonnullary = {
	["PROTECTIONLEVEL"] = "mw:Help:Magic words#Technical metadata";

	["DISPLAYTITLE"] = "mw:Help:Magic words#Technical metadata";
	["DEFAULTSORT"] = "mw:Help:Magic words#Technical metadata";

	["PAGESINCATEGORY"] = "mw:Help:Magic words#Technical metadata";
	["PAGESINCAT"] = "mw:Help:Magic words#Technical metadata";
	
	["NUMBERINGROUP"] = "mw:Help:Magic words#Technical metadata";
	["PAGESINNS"] = "mw:Help:Magic words#Technical metadata";
	["PAGESINNAMESPACE"] = "mw:Help:Magic words#Technical metadata";

	["FULLPAGENAME"] = "mw:Help:Magic words#Page names";
	["PAGENAME"] = "mw:Help:Magic words#Page names";
	["BASEPAGENAME"] = "mw:Help:Magic words#Page names";
	["SUBPAGENAME"] = "mw:Help:Magic words#Page names";
	["SUBJECTPAGENAME"] = "mw:Help:Magic words#Page names";
	["ARTICLEPAGENAME"] = "mw:Help:Magic words#Page names";
	["TALKPAGENAME"] = "mw:Help:Magic words#Page names";
	["ROOTPAGENAME"] = "mw:Help:Magic words#Page names"; -- undocumented

	["FULLPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["PAGENAMEE"] = "mw:Help:Magic words#Page names";
	["BASEPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["SUBPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["SUBJECTPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["ARTICLEPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["TALKPAGENAMEE"] = "mw:Help:Magic words#Page names";
	["ROOTPAGENAMEE"] = "mw:Help:Magic words#Page names"; -- undocumented

	["NAMESPACE"] = "mw:Help:Magic words#Namespaces";
	["NAMESPACENUMBER"] = "mw:Help:Magic words#Namespaces";
	["SUBJECTSPACE"] = "mw:Help:Magic words#Namespaces";
	["ARTICLESPACE"] = "mw:Help:Magic words#Namespaces";
	["TALKSPACE"] = "mw:Help:Magic words#Namespaces";

	["NAMESPACEE"] = "mw:Help:Magic words#Namespaces";
	["SUBJECTSPACEE"] = "mw:Help:Magic words#Namespaces";
	["TALKSPACEE"] = "mw:Help:Magic words#Namespaces";

	["PAGEID"] = "mw:Help:Magic words#Technical metadata of another page";
	["PAGESIZE"] = "mw:Help:Magic words#Technical metadata of another page";
	["PROTECTIONLEVEL"] = "mw:Help:Magic words#Technical metadata of another page";
	["CASCADINGSOURCES"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONID"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONDAY"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONDAY2"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONMONTH"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONMONTH1"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONYEAR"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONTIMESTAMP"] = "mw:Help:Magic words#Technical metadata of another page";
	["REVISIONUSER"] = "mw:Help:Magic words#Technical metadata of another page";
}

local parser_functions = {
	-- built-ins
	["localurl"] = "mw:Help:Magic words#URL data";
	["localurle"] = "mw:Help:Magic words#URL data";
	["fullurl"] = "mw:Help:Magic words#URL data";
	["fullurle"] = "mw:Help:Magic words#URL data";
	["canonicalurl"] = "mw:Help:Magic words#URL data";
	["canonicalurle"] = "mw:Help:Magic words#URL data";
	["filepath"] = "mw:Help:Magic words#URL data";
	["urlencode"] = "mw:Help:Magic words#URL data";
	["urldecode"] = "mw:Help:Magic words#URL data";
	["anchorencode"] = "mw:Help:Magic words#URL data";
	
	["ns"] = "mw:Help:Magic words#Namespaces";
	["nse"] = "mw:Help:Magic words#Namespaces";

	["formatnum"] = "mw:Help:Magic words#Formatting";
	["#dateformat"] = "mw:Help:Magic words#Formatting";
	["#formatdate"] = "mw:Help:Magic words#Formatting";
	["lc"] = "mw:Help:Magic words#Formatting";
	["lcfirst"] = "mw:Help:Magic words#Formatting";
	["uc"] = "mw:Help:Magic words#Formatting";
	["ucfirst"] = "mw:Help:Magic words#Formatting";
	["padleft"] = "mw:Help:Magic words#Formatting";
	["padright"] = "mw:Help:Magic words#Formatting";

	["plural"] = "mw:Help:Magic words#Localization";
	["grammar"] = "mw:Help:Magic words#Localization";
	["gender"] = "mw:Help:Magic words#Localization";
	["int"] = "mw:Help:Magic words#Localization";
	
	["#language"] = "mw:Help:Magic words#Miscellaneous";
	["#special"] = "mw:Help:Magic words#Miscellaneous";
	["#speciale"] = "mw:Help:Magic words#Miscellaneous";
	["#tag"] = "mw:Help:Magic words#Miscellaneous";
	
	-- [[mw:Extension:ParserFunctions]]
	["#expr"] = "mw:Help:Extension:ParserFunctions##expr";
	["#if"] = "mw:Help:Extension:ParserFunctions##if";
	["#ifeq"] = "mw:Help:Extension:ParserFunctions##ifeq";
	["#iferror"] = "mw:Help:Extension:ParserFunctions##iferror";
	["#ifexpr"] = "mw:Help:Extension:ParserFunctions##ifexpr";
	["#ifexist"] = "mw:Help:Extension:ParserFunctions##ifexist";
	["#rel2abs"] = "mw:Help:Extension:ParserFunctions##rel2abs";
	["#switch"] = "mw:Help:Extension:ParserFunctions##switch";
	["#time"] = "mw:Help:Extension:ParserFunctions##time";
	["#timel"] = "mw:Help:Extension:ParserFunctions##timel";
	["#titleparts"] = "mw:Help:Extension:ParserFunctions##titleparts";
	
	-- other extensions
 	["#babel"] = "mw:Extension:Babel#Usage";
 	["#categorytree"] = "mw:Extension:CategoryTree#The {{#categorytree}} parser function";
 	["#coordinates"] = "mw:Extension:GeoData#Parser function";
	["#invoke"] = "mw:Extension:Scribunto#Usage";
 	["#lst"] = "mw:Extension:Labeled Section Transclusion#How it works";
 	["#lsth"] = "mw:Extension:Labeled Section Transclusion#How it works"; -- not available, it seems
 	["#lstx"] = "mw:Extension:Labeled Section Transclusion#How it works";
	["noexternallanglinks"] = "mw:Extension:Wikibase Client#noexternallanglinks";
 	["#pagesusingpendingchanges"] = "mw:Extension:FlaggedRevs"; -- not documented yet
 	["pendingchangelevel"] = "mw:Extension:FlaggedRevs"; -- not documented yet
 	["#property"] = "mw:Extension:Wikibase Client#Data transclusion";
	["#target"] = "mw:Extension:MassMessage"; -- not documented yet
}

-- rudimentary
local function is_valid_pagename(pagename)
	if (pagename == "") or pagename:match("[%[%]%|%{%}#\127<>]") then
		return false
	end
	return true
end

local function hook_special(page)
	if is_valid_pagename(page) then
		return "[[Special:" .. page .. "|" .. page .. "]]"
	else
		return page
	end
end

local parser_function_hooks = {
	["#special"] = hook_special;
	["#speciale"] = hook_special;
	
	["int"] = function (mesg)
		if is_valid_pagename(mesg) then
			return ("[[:MediaWiki:" .. mesg .. "|" .. mesg .. "]]")
		else
			return mesg
		end
	end;
	
	["#categorytree"] = function (cat)
		if is_valid_pagename(cat) and not (mw.title.getCurrentTitle().fullText == ("Category:" .. cat)) then
			return ("[[:Category:" .. cat .. "|" .. cat .. "]]")
		else
			return cat
		end
	end;
	
	["#invoke"] = function (mod)
		if is_valid_pagename(mod) and not (mw.title.getCurrentTitle().fullText == ("Module:" .. mod)) then
			return ("[[Module:%s|%s]]"):format(mod, mod)
		else
			return mod
		end
	end;
	
	-- ["#tag"] = function (tag)
	-- 	local doc_table = require('Module:wikitag link').doc_table
	-- 	if doc_table[tag] then
	-- 		return ("[[%s|%s]]"):format(doc_table[tag], tag)
	-- 	else
	-- 		return tag
	-- 	end
	-- end;
	
	["#property"] = function (name)
		if is_valid_pagename(name) then
			return ("[[:d:Property:%s|%s]]"):format(name, name)
		else
			return name
		end	
	end;
}

function export.format_link(frame)
	local args = frame:getParent().args
	local output = { frame.args.nested and "&#123;&#123;" or "<code>&#123;&#123;" }
	
	local templ = args[1]
	local noargs = true
	
	if not templ then
		if mw.title.getCurrentTitle().fullText == frame:getParent():getTitle() then
			-- demo mode
			return "<code>{{<var>{{{1}}}</var>|<var>{{{2}}}</var>|...}}</code>"
		else
			error("The template name must be given.")
		end
	end

	for key, value in pairs(args) do
		if key ~= 1 then
			noargs = false
			break
		end
	end

	local function render_title(templ)
		local marker, rest

		marker, rest = templ:match("^([Ss][Uu][Bb][Ss][Tt]):(.*)")
		if not marker then
			marker, rest = templ:match("^([Ss][Aa][Ff][Ee][Ss][Uu][Bb][Ss][Tt]):(.*)")
		end
		if marker then
			templ = rest
			table.insert(output, ("[[mw:Manual:Substitution|%s]]:"):format(marker))
		end
	
		if noargs and variables_nullary[templ] then
			table.insert(output, ("[[%s|%s]]"):format(variables_nullary[templ], templ))
			return
		end
		
		marker, rest = templ:match("^([Mm][Ss][Gg][Nn][Ww]):(.*)")
		if marker then
			templ = rest
			-- not the most accurate documentation ever
			table.insert(output, ("[[m:Help:Magic words#Template modifiers|%s]]:"):format(marker))
		else
			marker, rest = templ:match("^([Mm][Ss][Gg]):(.*)")
			if marker then
				templ = rest	
				table.insert(output, ("[[m:Help:Magic words#Template modifiers|%s]]:"):format(marker)) -- ditto
			end
		end
	
		marker, rest = templ:match("^([Rr][Aa][Ww]):(.*)")
		if marker then
			table.insert(output, ("[[m:Help:Magic words#Template modifiers|%s]]:"):format(marker)) -- missingno.
			templ = rest	
		end
		
		if templ:match("^%s*/") then
			table.insert(output, ("[[%s]]"):format(templ))
			return	
		end
		
		marker, rest = templ:match("^(.-):(.*)")
		if marker then
			local lcmarker = marker:lower()
			if parser_functions[lcmarker] then
				if parser_function_hooks[lcmarker] then
					rest = parser_function_hooks[lcmarker](rest)
				end
				table.insert(output, ("[[%s|%s]]:%s"):format(mw.uri.encode(parser_functions[lcmarker], "WIKI"), marker, rest))
				return
			elseif variables_nonnullary[marker] then
				table.insert(output, ("[[%s|%s]]:%s"):format(variables_nonnullary[marker], marker, rest))
				return
			end
		end
	
		if templ:match("[%[%]%|%{%}#\127<>]") then
			table.insert(output, templ)
			return
		end

		if marker then
			if mw.site.namespaces[marker] then
				if (title == "") or (mw.title.getCurrentTitle().fullText == templ) then
					table.insert(output, templ)
				else
					table.insert(output, ("[[:%s|%s]]"):format(templ, templ))
				end
				return
			elseif mw.site.interwikiMap()[marker:lower()] then
				-- XXX: not sure what to do now…
				table.insert(output, ("[[:%s:|%s]]:%s"):format(marker, marker, rest))
				return
			end
		end

		if (templ == "") or (mw.title.getCurrentTitle().fullText == ("Template:" .. templ)) then
			table.insert(output, templ)
		else
			table.insert(output, ("[[Template:%s|%s]]"):format(templ, templ))
		end
	end

	render_title(templ)

	local i = 2
	while args[i] do
		table.insert(output, "&#124;" .. args[i])
		i = i + 1
	end
	
	for key, value in pairs(args) do
		if type(key) == "string" then
			table.insert(output, "&#124;" .. key .. "=" .. value)
		end
	end
	
	table.insert(output, frame.args.nested and "&#125;&#125;" or "&#125;&#125;</code>")
	return table.concat(output)
end

return export