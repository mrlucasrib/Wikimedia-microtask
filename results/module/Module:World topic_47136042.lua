local p = {}

local Navbox = require("Module:Navbox")
local country = {
	Afghanistan = {""},
	Albania = {""},
	Algeria = {""},
	Andorra = {""},
	Angola = {""},
	["Antigua and Barbuda"] = {""},
	Argentina = {""},
	Armenia = {""},
	Australia = {""},
	Austria = {""},
	Azerbaijan = {""},
	Bahamas = {"the Bahamas"},
	Bahrain = {""},
	Bangladesh = {""},
	Barbados = {""},
	Belarus = {""},
	Belgium = {""},
	Belize = {""},
	Benin = {""},
	Bhutan = {""},
	Bolivia = {""},
	["Bosnia and Herzegovina"] = {""},
	Botswana = {""},
	Brazil = {""},
	Brunei = {""},
	Bulgaria = {""},
	["Burkina Faso"] = {""},
	Burundi = {""},
	Cambodia = {""},
	Cameroon = {""},
	Canada = {""},
	["Cape Verde"] = {""},
	["Central African Republic"] = {"the Central African Republic"},
	Chad = {""},
	Chile = {""},
	China = {""},
	Colombia = {""},
	Comoros = {""},
	["Democratic Republic of the Congo"] = {"the Democratic Republic of the Congo"},
	["Republic of the Congo"] = {"the Republic of the Congo"},
	["Costa Rica"] = {""},
	Croatia = {""},
	Cuba = {""},
	Cyprus = {""},
	["Czech Republic"] = {"the Czech Republic"},
	Denmark = {""},
	Djibouti = {""},
	Dominica = {""},
	["East Timor"] = {""},
	["Dominican Republic"] = {"the Dominican Republic"},
	Ecuador = {""},
	Egypt = {""},
	["El Salvador"] = {""},
	["Equatorial Guinea"] = {""},
	Eritrea = {""},
	Estonia = {""},
	Eswatini = {""},
	Ethiopia = {""},
	Fiji = {""},
	Finland = {""},
	France = {""},
	Gabon = {""},
	Gambia = {"the Gambia"},
	Georgia = {"Georgia (country)"},
	Germany = {""},
	Ghana = {""},
	Greece = {""},
	Grenada = {""},
	Guatemala = {""},
	Guinea = {""},
	["Guinea-Bissau"] = {""},
	Guyana = {""},
	Haiti = {""},
	Honduras = {""},
	Hungary = {""},
	Iceland = {""},
	India = {""},
	Indonesia = {""},
	Iran = {""},
	Iraq = {""},
	Ireland = {"the Republic of Ireland"},
	Israel = {""},
	Italy = {""},
	["Ivory Coast"] = {""},
	Jamaica = {""},
	Japan = {""},
	Jordan = {""},
	Kazakhstan = {""},
	Kenya = {""},
	Kiribati = {""},
	Kosovo = {""},
	["North Korea"] = {""},
	["South Korea"] = {""},
	Kuwait = {""},
	Kyrgyzstan = {""},
	Laos = {""},
	Latvia = {""},
	Lebanon = {""},
	Lesotho = {""},
	Liberia = {""},
	Libya = {""},
	Liechtenstein = {""},
	Lithuania = {""},
	Luxembourg = {""},
	Madagascar = {""},
	Malawi = {""},
	Malaysia = {""},
	Maldives = {""},
	Mali = {""},
	Malta = {""},
	["Marshall Islands"] = {"the Marshall Islands"},
	Mauritania = {""},
	Mauritius = {""},
	Mexico = {""},
	["Federated States of Micronesia"] = {"the Federated States of Micronesia"},
	Moldova = {""},
	Monaco = {""},
	Mongolia = {""},
	Montenegro = {""},
	Morocco = {""},
	Mozambique = {""},
	Myanmar = {""},
	Namibia = {""},
	Nauru = {""},
	Nepal = {""},
	Netherlands = {"the Netherlands"},
	["New Zealand"] = {""},
	Nicaragua = {""},
	Niger = {""},
	Nigeria = {""},
	["North Macedonia"] = {""},
	Norway = {""},
	Oman = {""},
	Pakistan = {""},
	Palestine = {"State of Palestine"},
	Palau = {""},
	Panama = {""},
	["Papua New Guinea"] = {""},
	Paraguay = {""},
	Peru = {""},
	Philippines = {"the Philippines"},
	Poland = {""},
	Portugal = {""},
	Qatar = {""},
	Romania = {""},
	Russia = {""},
	Rwanda = {""},
	["Saint Kitts and Nevis"] = {""},
	["Saint Lucia"] = {""},
	["Saint Vincent and the Grenadines"] = {""},
	Samoa = {""},
	["San Marino"] = {""},
	["São Tomé and Príncipe"] = {""},
	["Saudi Arabia"] = {""},
	Senegal = {""},
	Serbia = {""},
	Seychelles = {""},
	["Sierra Leone"] = {""},
	Singapore = {""},
	Slovakia = {""},
	Slovenia = {""},
	["Solomon Islands"] = {"the Solomon Islands"},
	Somalia = {""},
	["South Africa"] = {""},
	["South Sudan"] = {""},
	Spain = {""},
	["Sri Lanka"] = {""},
	Sudan = {""},
	Suriname = {""},
	Sweden = {""},
	Switzerland = {""},
	Syria = {""},
	Taiwan = {""},
	Tajikistan = {""},
	Tanzania = {""},
	Thailand = {""},
	Togo = {""},
	Tonga = {""},
	["Trinidad and Tobago"] = {""},
	Tunisia = {""},
	Turkey = {""},
	Turkmenistan = {""},
	Tuvalu = {""},
	Uganda = {""},
	Ukraine = {""},
	["United Arab Emirates"] = {"the United Arab Emirates"},
	["United Kingdom"] = {"the United Kingdom"},
	["United States"] = {"the United States"},
	Uruguay = {""},
	Uzbekistan = {""},
	Vanuatu = {""},
	["Vatican City"] = {""},
	Venezuela = {""},
	Vietnam = {""},
	["Western Sahara"] = {""},
	Yemen = {""},
	Zambia = {""},
	Zimbabwe = {""},
}

function p.main(frame)
	local pframe = frame:getParent()
	local config = frame.args
	local args = pframe.args
	
	return p._main(args)
end

function p._main(args)
	if mw.title.getCurrentTitle() == "Template:World topic" then
		state = "autocollapse"
	else
		state = args.state
	end
	if args[1] ~= nil or args.prefix ~= nil and (args[2] == nil or ags.suffix == nil) then
		titlemid = " the"
	end
	if args.title ~= nil then
		title = args.title
	else
		title = "[["..(args[1] or args.prefix or "")..(titlemid or "").." World"..(args.suffix or "").."]]"
	end
	if args.group1 ~= nil and args.group1 ~= "" then
		group1 = args.group1
	end
	local sorter = {}
	for n in pairs(country) do
		table.insert(sorter, n)
	end
	table.sort(sorter)

	if args.noredlinks ~= nil then
		list1 = table.concat(noredlinks(args[1], args[2], args.prefix, args.suffix, sorter) )
	else
		list1 = table.concat(redlinks(args[1], args[2], args.prefix, args.suffix, sorter) )
	end
	local navarguments = {
		name = args.name or "World topic",
		state = state,
		navbar = args.navbar or "Tnavbar",
		border = args.border,
		title = title,
		image = args.image,
		titlestyle = args.titlestyle,
		bodystyle = args.bodystyle,
		abovestyle = args.abovestyle,
		belowstyle = args.belowstyle,
		groupstyle = args.groupstyle,
		liststyle = args.liststyle,
		listclass  = "hlist",
		above = args.above,
		group1 = group1,
		list1 = list1
	}
	return Navbox._navbox(navarguments)
end

function noredlinks(args1, args2, argsprefix, argssuffix, sorter)
	local list = {}
	for x, y in pairs(sorter) do
		if mw.title.new((args1 or argsprefix or "").." "..linktarget(y, country[y][1])..(args2 or argssuffix or "")).exists == true then
			table.insert(list, li("[["..(args1 or argsprefix or "").." "..linktarget(y, country[y][1])..(args2 or
				argssuffix or "").."|"..y.."]]"))
		elseif y == "Georgia" or y == "Palestine" then
			if mw.title.new((args1 or argsprefix or "").." "..y..(args2 or argssuffix or "")).exists == true then
				table.insert(list, li("[["..(args1 or argsprefix or "").." "..y..(args2 or
				argssuffix or "").."|"..y.."]]" ) )
			end
		end
	end
	return list
end

function redlinks(args1, args2, argsprefix, argssuffix, sorter)
	local list = {}
	for x, y in pairs(sorter) do
		if y == "Georgia" or y == "Palestine" then
			if mw.title.new((args1 or argsprefix or "").." "..country[y][1]..(args2 or argssuffix or "")).exists == true then
				table.insert(list, li("[["..(args1 or argsprefix or "").." "..country[y][1]..(args2 or
				argssuffix or "").."|"..y.."]]" ))
			else
				table.insert(list, li("[["..(args1 or argsprefix or "").." "..y..(args2 or
				argssuffix or "").."|"..y.."]]" ))
			end
		else
			table.insert(list, li("[["..(args1 or argsprefix or "").." " .. linktarget(y, country[y][1]) .. (args2 or 
				argssuffix or "").."|".. y .. "]]"))
		end
	end
	return list
end

function li(text)
	local li = mw.html.create("li")
	li
		:wikitext(text)
		:done()
	return tostring(li)
end

function linktarget(x, y)
	if y ~= nil and y == "" then
		return x
	else
		return y
	end
end

return p