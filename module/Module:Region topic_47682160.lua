local p = {}

local redirectTarget = require("Module:Redirect").getTarget

local function blankToNil(s)
	--Replaces string consisting of only whitespace with nil
	return s and string.find(s, '%S') and s or nil
end

local function unlink(s)
	return s=="unlink"
end

local yn_map = {yes="y", y="y", ["true"]="y", ["1"]="y", no="n", n="n", ["false"]="n", ["0"]="n", [""]="e"}
local function yn(s,map)
	--Converts a "yes"/"no" string s to a boolean. map is a
	--table that specifies what each type of input should be
	--interpreted as; its defaults are consistent with {{yesno}}
	map = map or {}
	local fmap = {y = map.y or 1, --yes, y, true, 1
	              n = map.n or 0, --no, n, false, 0
	              o = map.o or map.y or 1, --other
	              e = map.e or map.n or 0, --empty string
	              u = map.u or map.n or 0} --unspecified (nil)
	local num = s and fmap[yn_map[s] or "o"] or fmap.u
	return num ~= 0
end

local function yn3(s,nrl)
	--Converts a "yes"/"no" string s to a number (1=yes, 0=no, 0.5=neither)
	local yn = yn_map[s or ""]
	return (yn=="y" and 1) or (nrl and unlink(s) and 1) or (yn=="n" and 0) or 0.5
end

local function xor(a,b)
	--A logical XOR function
	return not a ~= not b
end

local function fallthrough(t)
	local i = 1
	local r = 0.5
	while r==0.5 and t[i] do
		r = t[i]
		i = i + 1
	end
	return (r and r~=0) and 1 or 0
end

local function loadData(d)
	if type(d)=="table" then
		return d
	elseif type(d)=="string" and blankToNil(d) then
		return mw.loadData(d)
	else
		return error("No data page or table specified")
	end
end

function p.luaMain(frame,args)
	--Produces the navbox (for other Lua scripts)

	--Pass through navbox style parameters
	local navboxArgs = {
		name = args.name or error("No name parameter"),
		state = args.state or "autocollapse",
		titlestyle = args.titlestyle,
		bodystyle = args.bodystyle,
		abovestyle = args.abovestyle,
		belowstyle = args.belowstyle,
		groupstyle = args.groupstyle,
		liststyle = args.liststyle,
		listclass = "hlist",
		image = args.image,
		above = args.above,
		border = args.border,
		navbar = args.navbar
	}

	--Load data page
	local data = loadData(args.data)

	--Prefix/suffix parameters
	local prefix = blankToNil(args.prefix or args[1])
	local suffix = blankToNil(args.suffix or args[2])
	prefix = (prefix or "")..(not yn(args.noprefixspace) and prefix and " " or "")
	suffix = (not yn(args.nosuffixspace) and suffix and " " or "")..(suffix or "")
	--Switch to include the definite article "the" where necessary
	local article
	if args.article then
		article = yn(args.article)
	else
		article = (prefix~="" and suffix=="")
	end
	--Switch to omit nonexisting articles (0.5 if not specified)
	local noRedLinks = yn3(args.noredlinks,1)
	local unlinkRedLinks = unlink(args.noredlinks)
	--Switch to automatically follow redirects
	local noRedirs = yn3(args.noredirects)

	--Create navbox title
	if args.title then
		navboxArgs.title = args.title
	else
		local linkName = data.region or error("No region parameter in data page")
		local linkArticle = (article and data.region_the) and (prefix=="" and "The " or "the ") or ""
		local fullLink = prefix..linkArticle..linkName..suffix
		if noRedLinks==0 or mw.title.new(fullLink).exists then
			navboxArgs.title = "[["..fullLink.."]]"
		else
			navboxArgs.title = fullLink
		end
	end

	--Loop over groups
	local nthGroup = 1
	local nthShownGroup = 1
	while data["group"..nthGroup] do
		--If group is not hidden or excluded
		if not data["group"..nthGroup].switch
		  or not args[data["group"..nthGroup].switch] and not data["group"..nthGroup].hidden
		  or args[data["group"..nthGroup].switch]
		    and xor(yn(args[data["group"..nthGroup].switch],{o=0}),data["group"..nthGroup].negate_switch)
		then
			--Create list & loop over entries
			local list = {}
			local listSortMap = {}
			for nthCountry,countryData in ipairs(data["group"..nthGroup].data) do
				local code = countryData[1]
				local countryName = blankToNil(args[code.."_name"]) or countryData[2] or countryData[1]
				local listItem
				--Determine if country should be included or not
				if yn(args[code],{u=1})
				  and (args[code]
				       or not (countryData.switch and args[countryData.switch]) and not countryData.hidden
				       or countryData.switch and args[countryData.switch]
				         and xor(yn(args[countryData.switch],{o=0}),countryData.negate_switch))
				then
					--Determine link target
					local linkName = countryData.link or countryData[2] or countryData[1]
					local linkArticle = (article and countryData.the) and "the " or ""
					local fullLink = not yn(args[code],{o=0}) and args[code] or (prefix..linkArticle..linkName..suffix)
					--Create list item if not nonexisting
					local noRedLink = fallthrough({yn3(args[code.."_noredlink"],1),noRedLinks,countryData.noredlink or 0})
					if (args[code] or noRedLink~=1 or mw.title.new(fullLink).exists) and not unlink(args[code]) then
						local noRedir = fallthrough({yn3(args[code.."_noredirect"]),noRedirs,countryData.noredirect or 0})
						listItem = "[["..(noRedir==1 and redirectTarget(fullLink) or fullLink).."|"..countryName.."]]"
					elseif unlink(args[code]) or unlink(args[code.."_noredlink"])
					       or unlinkRedLinks or unlink(countryData.noredlink)
					then
						listItem = countryName
					end
				end
				--Create sub-list if present
				if countryData.subgroup then
					local subGroup = countryData.subgroup
					local subList = {}
					local subListSortMap = {}
					for nthSubCountry,subCountryData in ipairs(subGroup) do
						--Similar to main item code
						local subCode = subCountryData[1]
						local subCountryName = blankToNil(args[subCode.."_name"])
						                       or subCountryData[2] or subCountryData[1]
						local subLinkName = subCountryData.link or subCountryData[2] or subCountryData[1]
						local subLinkArticle = (article and subCountryData.the) and "the " or ""
						local subFullLink = not yn(args[subCode],{o=0}) and args[subCode]
						                    or (prefix..subLinkArticle..subLinkName..suffix)
						local noRedLink = fallthrough({yn3(args[subCode.."_noredlink"],1),
						                               noRedLinks,subCountryData.noredlink or 0})
						if yn(args[subCode],{u=1})
						   and (args[subCode]
						        or (not (subGroup.switch and args[subGroup.switch]) and not subGroup.hidden
						            or subGroup.switch and args[subGroup.switch]
						              and xor(yn(args[subGroup.switch],{o=0}),subGroup.negate_switch))
						          and not (subCountryData.switch and args[subCountryData.switch])
						          and not subCountryData.hidden
						        or subCountryData.switch and args[subCountryData.switch]
						          and xor(yn(args[subCountryData.switch],{o=0}),subCountryData.negate_switch))
						then
							if (args[subCode] or noRedLink~=1 or mw.title.new(subFullLink).exists) and not unlink(args[subCode]) then
								local noRedir = fallthrough({yn3(args[subCode.."_noredirect"]),
								                             noRedirs,subCountryData.noredirect or 0})
								subList[#subList+1] = "<li>[["..(noRedir==1 and redirectTarget(subFullLink) or subFullLink)
								                      .."|"..subCountryName.."]]</li>"
								subListSortMap[#subListSortMap+1] = {args[subCode.."_sort"] or args[subCode.."_name"]
								                                     or subCountryData[2] or subCountryData[1],#subListSortMap+1}
							elseif unlink(args[subCode]) or unlink(args[subCode.."_noredlink"])
							       or unlinkRedLinks or unlink(subCountryData.noredlink)
							then
								subList[#subList+1] = "<li>"..subCountryName.."</li>"
								subListSortMap[#subListSortMap+1] = {args[subCode.."_sort"] or args[subCode.."_name"]
								                                     or subCountryData[2] or subCountryData[1],#subListSortMap+1}
							end
						end
					end
					--If non-empty sub-list, add it to country item
					if #subList>0 then
						table.sort(subListSortMap, function(t1,t2) return t1[1]<t2[1] end)
						local subListSorted = {}
						for sortListPosition,sortListEntry in ipairs(subListSortMap) do
							subListSorted[sortListPosition] = subList[sortListEntry[2]]
						end
						listItem = (listItem or countryName).."\n<ul>\n"..table.concat(subListSorted,"\n").."\n</ul>"
					end
				end
				if listItem then
					list[#list+1] = "<li>"..listItem.."</li>"
					listSortMap[#listSortMap+1] = {args[code.."_sort"] or countryName, #listSortMap+1}
				end
			end
			--Add group name and data to navbox args
			if data["group"..nthGroup].name then
				if string.match(data["group"..nthGroup].name,"%{%{") then
					navboxArgs["group"..nthShownGroup] = frame:preprocess(data["group"..nthGroup].name)
				else
					navboxArgs["group"..nthShownGroup] = data["group"..nthGroup].name
				end
			end
			--Sort list and move to navbox parameters if not empty
			if #list>0 or yn(args.showemptygroups) then
				table.sort(listSortMap, function(t1,t2) return t1[1]<t2[1] end)
				local listSorted = {}
				for sortListPosition,sortListEntry in ipairs(listSortMap) do
					listSorted[sortListPosition] = list[sortListEntry[2]]
				end
				navboxArgs["list"..nthShownGroup] = "<ul>\n"..table.concat(listSorted,"\n").."\n</ul>"
				nthShownGroup = nthShownGroup + 1
			end
		end
		nthGroup = nthGroup + 1
	end

	--Invoke navbox module
	return require("Module:Navbox")._navbox(navboxArgs)
end

function p.main(frame)
	--Produces the navbox (for wikitext usage)
	local args = require("Module:Arguments").getArgs(frame, {removeBlanks = false})
	return p.luaMain(frame,args)
end

function p.luaList(frame,dataPage)
	--Produces a list of entities and associated parameters, for
	--use in template documentation (for other Lua scripts)

	--Load data page
	local data = loadData(dataPage)

	--Create table and header row
	local table = mw.html.create("table"):addClass("wikitable collapsible"):css("color","#000")
	local tableHead = table:tag("tr"):css("font-weight","bold")
	tableHead:tag("th"):css("background-color","#e8e8e8"):wikitext("Code")
	tableHead:tag("th"):css("background-color","#e8e8e8"):wikitext("Display name [link name]")
	tableHead:tag("th"):css("background-color","#e8e8e8"):wikitext("Switch")
	tableHead:tag("th"):css("background-color","#e8e8e8"):wikitext("Hidden?")

	--Loop over groups
	local nthGroup = 1
	while data["group"..nthGroup] do
		--Add group data
		local groupHead = table:tag("tr"):css("background-color","#eaf1fe")
		groupHead:tag("td")
		if data["group"..nthGroup].name and string.match(data["group"..nthGroup].name,"%{%{") then
			groupHead:tag("td"):css("font-weight","bold"):wikitext(frame:preprocess(data["group"..nthGroup].name))
		else
			groupHead:tag("td"):css("font-weight","bold"):wikitext(data["group"..nthGroup].name or "<i>Unnamed group</i>")
		end
		groupHead:tag("td"):cssText(data["group"..nthGroup].negate_switch and "text-decoration:overline;" or "")
		         :wikitext(data["group"..nthGroup].switch or "")
		groupHead:tag("td"):wikitext(data["group"..nthGroup].hidden and "Yes" or "")
		--Loop over group entries
		for nthCountry,countryData in ipairs(data["group"..nthGroup].data) do
			--Add single entry data
			local countryRow = table:tag("tr"):css("background-color","#f8f8f8")
			countryRow:tag("td"):wikitext(countryData[1])
			local countryName = countryRow:tag("td"):css("padding-left","1em"):wikitext(countryData[2] or countryData[1])
			if countryData.the or countryData.link then
				countryName:wikitext(" ["..(countryData.the and "the" or "")
				                         ..(countryData.the and countryData.link and " " or "")
				                         ..(countryData.link or "").."]")
			end
			countryRow:tag("td"):cssText(countryData.negate_switch and "text-decoration:overline;" or ""):wikitext(countryData.switch or "")
			countryRow:tag("td"):wikitext(countryData.hidden and "Yes" or (countryData.noredlink and "Depends on existence" or ""))
			--Add subgroup data if exists
			if countryData.subgroup then
				local subListHead = table:tag("tr"):css("background-color","#fefce2")
				subListHead:tag("td")
				subListHead:tag("td"):css("padding-left","2em"):css("font-weight","bold"):wikitext("Subgroup")
				subListHead:tag("td"):cssText(countryData.subgroup.negate_switch and "text-decoration:overline;" or "")
				                     :wikitext(countryData.subgroup.switch or "")
				subListHead:tag("td"):wikitext(countryData.subgroup.hidden and "Yes" or "")
				for nthSubCountry,subCountryData in ipairs(countryData.subgroup) do
					local subCountryRow = table:tag("tr"):css("background-color","#fdfcf4")
					subCountryRow:tag("td"):wikitext(subCountryData[1])
					local subCountryName = subCountryRow:tag("td"):css("padding-left","2em"):css("font-style","italic")
					                                              :wikitext(subCountryData[2] or subCountryData[1])
					if subCountryData.the or subCountryData.link then
						subCountryName:wikitext(" ["..(subCountryData.the and "the" or "")
						                            ..(subCountryData.the and subCountryData.link and " " or "")
						                            ..(subCountryData.link or "").."]")
					end
					subCountryRow:tag("td"):cssText(subCountryData.negate_switch and "text-decoration:overline;" or "")
					                       :wikitext(subCountryData.switch or "")
					subCountryRow:tag("td"):wikitext(subCountryData.hidden
					                                 and "Yes" or (subCountryData.noredlink and "Depends on existence" or ""))
				end
			end
		end
		nthGroup = nthGroup + 1
	end
	return tostring(table)
end

function p.list(frame)
	--Produces a list of entities and associated parameters, for
	--use in template documentation (for wikitext usage)
	local args = require("Module:Arguments").getArgs(frame)
	return p.luaList(frame,args.data)
end

return p