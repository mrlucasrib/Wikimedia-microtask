--[[

	This module is an update to already existing templates:
		{{Template:period start}}
		{{Template:period end}}
		{{Template:period color}}
		{{Template:Phanerozoic 220px}}
		{{Template:All time 250px}}
		{{Template:Geological range}}
		{{Template:Fossil range/bar}}
		{{Template:Fossil range/marker}}
		{{Template:Long fossil range}}
		{{Template:Long fossil range/bar 250}}
		{{Template:Long fossil range/marker}}
	And now it takes just one module to export all the data above,
	so we need only one template to just show a geological range.
	That template would be {{Template:Geological range}}, no need
	for any other templates.
	
	Done by HastaLaVi2.

]]

local periods = {
	-- Some other notable dates
	{"burgess shale", 508, aliases={"middle middle cambrian"}},   --[[Middle middle is approximate; cf. Burgess Shale ]]
	{"chengjiang", 518},
	{"sirius passet", 518},
	{"doushantou", 570},
	--[[ Data from ICS chart
	The names from the ICS chart are always first on the line.
	]]
	{"precambrian", 4600,
		{"hadean"},
		{"archean", 4000,
			{"eoarchean", aliases={"isuan"}},
			{"paleoarchean", 3600},
			{"mesoarchean", 3200},
			{"neoarchean", 2800},
		},
		{"proterozoic", 2500,
			{"paleoproterozoic",
				{"siderian"},
				{"rhyacian", 2300},
				{"orosirian", 2050},
				{"statherian", 1800},
			},
			{"mesoproterozoic", 1600,
				{"calymmian"},
				{"ectasian", 1400, aliases={"riphean"}},
				{"stenian", 1200,
					{"mayanian", 1100},
					{"sinian", 1050, aliases={"sturtian"}},
				},
			},
			{"neoproterozoic", 1000,
				{"tonian",
					{"baikalian", 850},
				},
				{"cryogenian", 720},
				{"ediacaran", 635, aliases={"vendian"}},
			},
		},
	},
	{"phanerozoic", 541.0,
		{"paleozoic",
			{"cambrian",
				{"lower cambrian", -- group of two epochs, not in ICS chart
					{"terreneuvian",
						aliases= {"lowest cambrian", "earliest cambrian"},
						{"fortunian",
							{"manykaian", aliases= {"nemakit daldynian"}},
							{"caerfai", 530, aliases= {"tommotian"}},
						},
						{"cambrian stage 2", 529},
					},
					{"cambrian series 2", 521,
						{"cambrian stage 3",
							aliases= {"middle lower cambrian"},
							{"atdabanian"},
							{"botomian", 522},
							{"toyonian", 516, aliases= {"upper lower cambrian"}},
						},
						{"cambrian stage 4", 514},
					},
				},
				{"cambrian series 3", 509,
					aliases= {"middle cambrian", "miaolingian"},
					{"cambrian stage 5", aliases= {"lower middle cambrian", "st davids", "wuliuan"}},
					{"drumian", 504.5},
					{"guzhangian", 500.5, aliases= {"nganasanian", "mindyallan"}},
				},
				{"furongian", 497,
					aliases= {"upper cambrian", "merioneth"},
					{"paibian", aliases= {"franconian"}},  -- unofficial and approximate
					{"jiangshanian",
						494,
						{"upper upper cambrian", 489.5, aliases= {"mansian"}},
					},
					{"cambrian stage 10"},
				},
			},
			{"ordovician", 485.4,
				{"lower ordovician",
					{"tremadocian",
						{"upper lower ordovician", 479},
					},
					{"floian", 477.7, aliases={"arenig"}},
				},
				{"middle ordovician", 470.0,
					{"dapingian", aliases={"ordovician iii", "lower middle ordovician"}},
					{"darriwilian", 467.3},
				},
				{"upper ordovician", 458.4,
					{"sandbian",
						aliases= {"ordovician v", "lower upper ordovician"},
						{"middle upper ordovician", 455},
					},
					{"katian", 453.0, aliases={"ordovician vi"}},
					{"hirnantian", 445.2},
				},
			},
			{"silurian", 443.8,
				{"llandovery",
					aliases= {"lower silurian"},
					{"rhuddanian"},
					{"aeronian", 440.8},
					{"telychian", 438.5},
				},
				{"wenlock", 433.4,
					{"sheinwoodian"},
					{"homerian", 430.5},
				},
				{"ludlow", 427.4,
					aliases= {"upper silurian"},
					{"gorstian"},
					{"ludfordian", 425.6},
				},
				{"pridoli", 423.0,
					{"unnamed pridoli stage"},
				},
			},
			{"devonian", 419.2,
				{"lower devonian",
					{"lochkovian", aliases={"downtonian"}}, -- approx
					{"pragian", 410.8, aliases={"praghian"}},
					{"emsian", 407.6},
				},
				{"middle devonian", 393.3,
					{"eifelian"},
					{"givetian", 387.7},
				},
				{"upper devonian", 382.7,
					{"frasnian"},
					{"famennian", 372.2},
				},
			},
			{"carboniferous", 358.9,
				{"mississippian", -- Subperiod from ICS chart
					aliases= {"lower carboniferous"},
					{"lower mississippian",
						{"tournaisian"},
					},
					{"middle mississippian", 346.7,
						{"visean"},
					},
					{"upper pennsylvanian", 330.9,
						{"serpukhovian",
							{"namurian", 326},
						},
					},
				},
				{"pennsylvanian", 323.2, -- Subperiod from ICS chart
					aliases= {"upper carboniferous"},
					{"lower pennsylvanian",
						{"bashkirian",
							{"westphalian", 313},
						},
					},
					{"middle pennsylvanian", 315.2,
						{"moscovian"},
					},
					{"upper pennsylvanian", 307.0,
						{"kasimovian",
							{"stephanian", 304},
						},
						{"gzhelian", 303.7},
					},
				},
			},
			{"permian", 298.9,
				{"cisuralian",
					aliases= {"lower permian"},
					{"asselian"},
					{"sakmarian", 295.0},
					{"artinskian", 290.1},
					{"kungurian", 283.5},
				},
				{"guadalupian", 272.95,
					aliases= {"middle permian"},
					{"roadian", aliases={"ufimian"}},
					{"wordian", 268.8},
					{"capitanian", 265.1},
				},
				{"lopingian", 259.1,
					aliases= {"upper permian"},
					{"wuchiapingian", aliases={"longtanian"}},
					{"changhsingian", 254.14},
				},
			},
		},
		{"mesozoic", 251.902,
			{"triassic",
				{"lower triassic",
					{"induan"},
					{"olenekian", 251.2, aliases={"spathian"}},
				},
				{"middle triassic", 247.2,
					{"anisian"},
					{"ladinian", 242},
				},
				{"upper triassic", 237,
					{"carnian"},
					{"norian", 227},
					{"rhaetian", 208.5},
				},
			},
			{"jurassic", 201.3,
				{"lower jurassic",
					{"hettangian"},
					{"sinemurian", 199.3},
					{"pliensbachian", 190.8},
					{"toarcian", 182.7},
				},
				{"middle jurassic", 174.1,
					{"aalenian"},
					{"bajocian", 170.3},
					{"bathonian", 168.3},
					{"callovian", 166.1},
				},
				{"upper jurassic", 163.5,
					{"oxfordian"},
					{"kimmeridgian", 157.3},
					{"tithonian", 152.1},
				},
			},
			{"cretaceous", 145.0,
				{"lower cretaceous",
					{"berriasian", aliases={"neocomian"}},
					{"valanginian", 139.8},
					{"hauterivian", 132.9},
					{"barremian", 129.4, aliases={"gallic"}},
					{"aptian", 125.0},
					{"albian", 113.0},
				},
				{"upper cretaceous", 100.5,
					{"cenomanian"},
					{"turonian", 93.9},
					{"coniacian", 89.8, aliases={"senonian"}},
					{"santonian", 86.3},
					{"campanian", 83.6},
					{"maastrichtian", 72.1},
				},
			},
		},
		{"cenozoic", 66.0,
			{"tertiary",   -- Group of 2 periods, former term
				{"paleogene",
					{"paleocene",
						{"danian",
							aliases= {"lower paleocene"},
							{"puercan", 65},
							{"torrejonian", 63.3},
						},
						{"selandian", 61.6,
							aliases= {"middle paleocene"},
							{"tiffanian", 60.2},
						},
						{"thanetian", 59.2,
							aliases= {"upper paleocene"},
							{"clarkforkian", 56.8},
						},
					},
					{"eocene", 56.0,
						{"ypresian",
							aliases= {"lower eocene", "mp 10"},
							{"wasatchian", 55.4},
							{"bridgerian", 50.3},
						},
						{"middle eocene", 47.8,
							{"lutetian",
								aliases= {"mp 11"},
								{"uintan", 46.2},
								{"duchesnean", 42},
							},
							{"bartonian", 41.2,
								{"chadronian", 38},
							},
						},
						{"priabonian", aliases={37.8, "upper eocene"}},
					},
					{"oligocene", 33.9,
						{"rupelian",
							aliases= {"lower oligocene"},
							{"orellan"},
							{"whitneyan", 33.3},
							{"arikeean", 30.6},
						},
						{"chattian", 28.1, aliases={"upper oligocene"}},
					},
				},
				{"neogene", 23.03,
					{"miocene",
						{"lower miocene",   -- Group of 2 stages, not in ICS chart
							{"aquitanian",
								{"hemingfordian", 20.6},
							},
							{"burdigalian", 20.44,
								{"barstovian", 16.3},
							},
						},
						{"middle miocene", 15.97,   -- Group of 2 stages, not in ICS chart
							{"langhian"},
							{"serravallian", 13.82,
								{"clarendonian", 13.6},
							},
						},
						{"upper miocene", 11.63,   -- Group of 2 stages, not in ICS chart
							{"tortonian",
								{"hemphillian", 10.3},
							},
							{"messinian", 7.246},
						},
					},
					{"pliocene", 5.333,
						{"zanclean",
							aliases= {"lower pliocene"},
							{"blancan", 4.75},
						},
						{"piacenzian", 3.600, aliases={"upper pliocene"}},
					},
				},
			},
			{"quaternary", 2.58,
				{"pleistocene",
					{"lower pleistocene",   -- Group of 2 stages, implied from ICS chart
						{"gelasian"},
						{"calabrian", 1.80,
							{"irvingtonian", 1.8},
						},
					},
					{"middle pleistocene", 0.774, -- this date has been redefined by the ICS.
						aliases= {"ionian", "chibanian"},
						--[[the name "Chibanian" was formally adopted
							for this stage by the ICS in January 2020.
							The term "Ionian" was a proposed term for
							this same span of time. ]]
						{"rancholabrean", 0.24}, -- this date has been redefined by the ICS.
					},
					{"upper pleistocene", aliases={0.129, "tarantian"}}, -- proposed name for this as-yet formally undefined stage
				},
				{"holocene", 0.0117,
					{"greenlandian", aliases={"lower holocene"}},
					{"northgrippian", 0.0082, aliases={"middle holocene"}},
					{"meghalayan", 0.0042, aliases={"upper holocene"}},
				},
			},
		},
	},
	{"present", 0, aliases={"now", "recent", "current"}},
}

local colors = {
	{"rgb(154,217,221)", "phanerozoic"},
	{"rgb(242,249,29)", "cenozoic"},
	{"rgb(249,249,127)", "quaternary"},
	{"rgb(242,249,2)", "tertiary"},
	{"rgb(255,230,25)", "neogene"},
	{"rgb(254,242,224)", "holocene"},
	{"rgb(255,242,174)", "pleistocene"},
	{"rgb(244,249,173)", "pliocene"},
	{"rgb(255,255,0)", "miocene"},
	{"rgb(253,154,82)", "paleogene", "palæogene", "palaeogene"},
	{"rgb(253,192,122)", "oligocene"},
	{"rgb(253,180,108)", "eocene"},
	{"rgb(253,167,95)", "paleocene", "palæocene", "palaeocene"},
	
	{"rgb(98,197,202)", "mesozoic"},
	{"rgb(127,198,78)", "cretaceous"},
	{"rgb(188,209,94)", "late cretaceous", "upper cretaceous", "maastrichtian", "campanian", "santonian", "coniacian", "turonian", "cenomanian"},
	{"rgb(161,200,167)", "early cretaceous", "lower cretaceous", "albian", "aptian", "barremian", "hauterivian", "valanginian", "berriasian"},
	
	{"rgb(52,178,201)", "jurassic"},
	{"rgb(189,228,247)", "late jurassic", "upper jurassic", "hettangian", "sinemurian", "pliensbachian", "toarcian"},
	{"rgb(132,207,232)", "mid jurassic", "middle jurassic", "aalenian", "bajocian", "bathonian", "callovian"},
	{"rgb(0,176,227)", "early jurassic", "lower jurassic", "oxfordian", "kimmeridgian", "tithonian"},
	
	{"rgb(129,43,146)", "triassic"},
	{"rgb(198,167,203)", "late triassic", "upper triassic", "carnian", "norian", "rhaetian"},
	{"rgb(187,135,182)", "mid triassic", "middle triassic", "anisian", "ladinian"},
	{"rgb(152,57,153)", "lower triassic", "early triassic", "induan", "olenekian"},
	
	{"rgb(153,192,141)", "palæozoic", "paleozoic", "palaeozoic"},
	{"rgb(240,64,60)", "permian"},
	{"rgb(247,188,169)", "late permian", "upper permian", "lopingian"},
	{"rgb(241,143,116)", "middle permian", "mid permian", "guadalupian"},
	{"rgb(228,117,92)", "early permian", "lower permian", "cisuralian"},
	
	{"rgb(103,165,153)", "carboniferous"},
	{"rgb(153,194,181)", "upper carboniferous", "pennsylvanian"},
	{"rgb(202,204,205)", "upper pennsylvanian", "gzhelian", "kasimovian"},
	{"rgb(180,206,203)", "middle pennsylvanian", "mid pennsylvanian", "moscovian"},
	{"rgb(153,197,200)", "lower pennsylvanian", "bashkirian"},
	{"rgb(103,143,102)", "lower carboniferous", "mississippian"},
	{"rgb(205,197,134)", "upper mississippian", "serpukhovian"},
	{"rgb(171,188,133)", "middle mississippian", "visean"},
	{"rgb(145,179,132)", "lower mississippian", "tournaisian"},
	
	{"rgb(203,140,55)", "devonian"},
	{"rgb(245,228,181)", "upper devonian", "late devonian", "frasnian", "famennian"},
	{"rgb(244,207,132)", "middle devonian", "mid devonian", "givetian", "eifelian"},
	{"rgb(229,180,110)", "lower devonian", "early devonian", "emsian", "pragian", "praghian", "lochkovian"},
	
	{"rgb(179,225,182)", "silurian"},
	{"rgb(230,245,225)", "latest silurian", "pridoli"},
	{"rgb(191,230,207)", "late silurian", "upper silurian", "ludlow"},
	{"rgb(179,225,194)", "middle silurian", "mid silurian", "wenlock"},
	{"rgb(153,215,179)", "lower silurian", "early silurian", "llandovery"},
	
	{"rgb(0,146,112)", "ordovician"},
	{"rgb(141,200,170)", "upper ordovician", "late ordovician"},
	{"rgb(166,219,171)", "hirnantian"},
	{"rgb(153,214,159)", "katian"},
	{"rgb(140,208,148)", "sandbian"},
	{"rgb(71,179,147)", "middle ordovician", "mid ordovician"},
	{"rgb(116,198,156)", "dariwillian"},
	{"rgb(102,192,146)", "dapingian"},
	{"rgb(0,158,126)", "lower ordovician", "early ordovician", "tremadoc", "ashgill"},
	{"rgb(65,176,135)", "floian"},
	{"rgb(51,169,126)", "tremadocian"},
	
	{"rgb(127,160,86)", "cambrian"},
	{"rgb(179,224,149)", "furongian", "cambrian series 4", "series 4"},
	{"rgb(230,245,201)", "cambrian stage 10", "stage 10"},
	{"rgb(217,240,187)", "cambrian stage 9", "stage 9"},
	{"rgb(204,235,174)", "paibian"},
	{"rgb(166,207,134)", "cambrian series 3", "series 3", "middle cambrian", "mid cambrian"},
	{"rgb(204,223,170)", "guzhangian"},
	{"rgb(191,217,157)", "drumian"},
	{"rgb(179,212,146)", "cambrian stage 5", "stage 5"},
	{"rgb(153,192,120)", "cambrian series 2", "lower cambrian", "series 2"},
	{"rgb(179,202,142)", "cambrian stage 4", "stage 4"},
	{"rgb(166,197,131)", "cambrian stage 3", "stage 3"},
	{"rgb(140,176,108)", "terreneuvean", "cambrian series 1", "series 1"},
	{"rgb(166,186,128)", "cambrian stage 2", "stage 2"},
	{"rgb(153,181,117)", "fortunian", "cambrian stage 1", "stage 1"},
	
	{"rgb(159,184,133)", "early cambrian"}, -- Unofficial!
	
	{"rgb(247,67,112)", "precambrian"},
	{"rgb(247,53,99)", "proterozoic"},
	{"rgb(250,191,93)", "neoproterozoic"},
	{"rgb(254,217,106)", "ediacaran"},
	{"rgb(254,204,92)", "cryogenian"},
	{"rgb(254,191,78)", "tonian"},
	{"rgb(253,180,98)", "mesoproterozoic"},
	
	{"rgb(253,224,178)", "stenian"},
	{"rgb(252,214,164)", "ectasian"},
	{"rgb(251,204,150)", "calymmian"},
	{"rgb(247,67,112)", "paleoproterozoic", "palaeoproterozoic", "palæoproterozoic"},
	{"rgb(239,147,174)", "statherian"},
	{"rgb(238,134,160)", "orosirian"},
	{"rgb(236,122,147)", "rhyacian"},
	{"rgb(235,110,136)", "siderian"},
	{"rgb(240,4,127)", "archean"},
	{"rgb(2449,155,193)", "neoarchean"},
	{"rgb(247,104,169)", "mesoarchean"},
	{"rgb(244,68,159)", "paleoarchean", "palæoarchean", "palaeoarchean"},
	{"rgb(218,3,127)", "eoarchean"},
	{"rgb(174,2,126)", "hadean"},
}

local nameToYear = {}
local yearToName = {}
local startToEnd = {{},{},{},{},{},{},{},{}}

local function nStep(t, year, i)
	if type(t) == "table" then
		for _,x in ipairs(t) do
			local preYear = year
			if type(x) == "table" then
				table.insert(startToEnd[i], {x[1]})
				year = tonumber(x[2]) and x[2] or year
				if year == preYear then
					table.insert(yearToName[#yearToName], x[1])
				else
					table.insert(yearToName, {year, x[1]})
				end
				nameToYear[x[1]] = year
				if x.aliases then
					for _,alias in ipairs(x.aliases) do
						nameToYear[alias] = year
						table.insert(startToEnd[i][#startToEnd[i]], alias)
						table.insert(yearToName[#yearToName], alias)
					end
				end
			end
			nStep(x, year, i+1)
		end
	end
end

nStep(periods, "", 1)

for _,nextP in ipairs(startToEnd) do
	for k,period in ipairs(nextP) do
		for _,name in ipairs(period) do
			startToEnd[name] = nextP[k+1] and nextP[k+1][1] or "present"
		end
	end
end

local function findandrep(text, one, two)
	return mw.ustring.sub( mw.ustring.gsub(tostring(text), one, two), 1, -1 )
end

local function round(num, rou)
  return num and tonumber(string.format("%." .. (rou or 0) .. "f", num))
end

local function getByTable(text, t)
	text = mw.getContentLanguage():lc(text)
	for _,inside in pairs(t) do
		for i=2,30 do
			if inside[i] and inside[i] == text then return inside[1] end
		end
	end
end

local function linearGradient(color1, color2)
	return "background-image: -moz-linear-gradient("..color1..", "..color2.."); background-image: -ms-linear-gradient("..color1..", "..color2.."); background-image: -o-linear-gradient("..color1..", "..color2.."); background-image: -webkit-linear-gradient("..color1..", "..color2.."); background-image: linear-gradient("..color1..", "..color2..");"
end

local function periodID(id)
	local text = mw.getContentLanguage():lc(tostring(id))
	local found = {
		["series 2"] = "cambrian series 2",
		["series 3"] = "cambrian series 3",
		["stage 2"]  = "cambrian stage 2",
		["stage 3"]  = "cambrian stage 3",
		["stage 4"]  = "cambrian stage 4",
		["stage 5"]  = "cambrian stage 5",
		["stage 10"] = "cambrian stage 10"
	}
	if found[text] then
		text = found[text]
	else
		text = findandrep(text, "-", "")
		text = findandrep(text, "%f[%w]palaeo", "paleo")
		text = findandrep(text, "%f[%w]early%f[%W]", "lower")
		text = findandrep(text, "%f[%w]mid%f[%W]", "middle")
		text = findandrep(text, "%f[%w]late%f[%W]", "upper")
	end
	
	return text
end

local function periodStart(period, rou)
	return period and round(nameToYear[periodID(period)], rou or 5)
end

local function periodEnd(period, rou)
	return period and periodStart(startToEnd[periodID(period)], rou or 5)
end

local function periodColor(period)
	return getByTable(mw.getContentLanguage():lc(period), colors)
end

local function mark(typ, num1, num2, num3)
	local g, h = typ.width, typ.all
	local result
	if (num1-num2)>5 then
		result = "<div style='position:absolute; height:8px; left:"..((h-num1)/h*g).."px;"
			.."width:"..((num1-num2)*g/h).."px; background-color:#360; opacity:"
			..(num3 and tonumber("0."..tostring(num3)) or 1).."; '><!--range-border--></div>"
		if num3 then else
			result = result .. "<div style='position:absolute; height:6px; top:1px; left:" .. (((h-num1)/h*g)+1)
			.."px; width:" .. (((num1-num2)*g/h)-2) .. "px; background-color:#6c3;'><!--range-marker--></div>"
		end
	else
		if num3 then else
			result = "<div style='position:absolute; left:" .. ((h-num1)/h*g) .."px;"
			.. "font-size:50%'><!--contains arrow--><div style='position:relative; left:-0.42em'>"
			.. "<!--nudges back left-->&darr;</div></div>"
		end
	end
	
	return result
end

local function bar(typ, val1, val2, val3)
	local g, h = typ.width, typ.all
	local gen = g == 250 and (val3 and "6" or "12px; top:6").."px" or "100%"
	return "<div style='position:absolute; height:"..gen.."; text-align:center; background-color:".. periodColor(val1)
		.. ";left:" .. ((h-periodStart(val1))/h*g) .. "px; width:"
		.. ((periodStart(val1)-periodEnd(val1))/h*g) .. "px;'>"..(val2 and "[["..val1.."|"..val2.."]]" or "").."</div>"
end

local function compare(year, num)
	local period
	
	for k,inside in pairs(yearToName) do
		if num == 1 then
			if year <= inside[1] then
				period = inside[2]
			end
		elseif num == 2 then
			if year >= inside[1] and (yearToName[k-1] and year <= yearToName[k-1][1]) then
				if year == yearToName[k-1][1] then
					period = yearToName[k-1][2]
				else
					period = inside[2]
				end
			end
		end
	end
	
	return "[[" .. (period == "present" and "Holocene|" or "") .. mw.getContentLanguage():ucfirst(period) .. "]]"
end

local function _show(veri)
	local result = {}
	
	local year1 = tonumber(veri[1]) or periodStart(veri[1])
	local year2 = tonumber(veri[2]) or periodEnd(veri[2]) or periodEnd(veri[1]) or tonumber(veri[1])
		
	local year1_e = tonumber(veri["earliest"]) or periodStart(veri["earliest"]) or year1
	local year2_e = tonumber(veri["latest"]) or periodEnd(veri["latest"]) or year2
	
	local typ = year1 >= 650 and {width=250,all=4600} or {width=220,all=650}
	
	table.insert(result, "<span>")
	if veri["prefix"] then
		table.insert(result, veri["prefix"])
	end
	
	table.insert(result, ((veri[3] or veri["text"]) or
			(tostring(year1) .. (year2 and "-"..tostring(year2) or "") .. "&nbsp;[[Megaannum|Ma]]"))
		.. (veri[1] and "<br>" or "") .. (tonumber(veri[1]) and compare(year1, 1) or veri[1])
		.. (veri[2] and "-" or "") .. ((tonumber(veri[2])) and  compare(year2, 2) or (veri[2] or ""))
		)

	local ref = veri["ref"] or veri["reference"] or veri["refs"] or veri["references"]
	if ref then table.insert(result, ref) end
	table.insert(result, "&nbsp;")
	local ps = veri["PS"] or veri["ps"]
	if ps then table.insert(result, ps) end
	table.insert(result, "</span>")
	
	table.insert(result, "<div id='Timeline-row' style='margin: 4px auto 0; clear:both;"
		.."width:"..tostring(typ.width).."px; padding:0px; height:18px; overflow:visible; border:1px #666;"
		.."border-style:solid none; position:relative; z-index:0; font-size:13px;'>")
	
	if typ.all == 4600 then
		table.insert(result, bar(typ, "Hadean"))
		table.insert(result, bar(typ, "Hadean", "<span style='color:white'>''Had'n''</span>", 1))
		table.insert(result, bar(typ, "eoarchean"))
		table.insert(result, bar(typ, "Paleoarchean"))
		table.insert(result, bar(typ, "Mesoarchean"))
		table.insert(result, bar(typ, "neoarchean"))
		table.insert(result, bar(typ, "archean", "Archean", 1))
		table.insert(result, bar(typ, "paleoproterozoic"))
		table.insert(result, bar(typ, "mesoproterozoic"))
		table.insert(result, bar(typ, "neoproterozoic"))
		table.insert(result, bar(typ, "proterozoic", "Proterozoic", 1))
		table.insert(result, bar(typ, "Paleozoic"))
		table.insert(result, bar(typ, "Mesozoic"))
		table.insert(result, bar(typ, "Cenozoic"))
		table.insert(result, bar(typ, "phanerozoic", "Pha.", 1))
	else
		table.insert(result, 
			"<div style='position:absolute; height:100%; left:0px; width:"..(periodStart("cambrian")/650*250).."px;"
			.."padding-left:5px; text-align:left; background-color:".. periodColor("ediacaran") ..";"
			..linearGradient("left", "rgba(255,255,255,1), rgba(254,217,106,1) 15%, rgba(254,217,106,1)") .. "'>"
			.."[[Precambrian|PreЄ]]</div>")
		table.insert(result, bar(typ, "cambrian", "Є"))
		table.insert(result, bar(typ, "ordovician", "O"))
		table.insert(result, bar(typ, "silurian", "S"))
		table.insert(result, bar(typ, "devonian", "D"))
		table.insert(result, bar(typ, "carboniferous", "C"))
		table.insert(result, bar(typ, "permian", "P"))
		table.insert(result, bar(typ, "triassic", "T"))
		table.insert(result, bar(typ, "jurassic", "J"))
		table.insert(result, bar(typ, "cretaceous", "K"))
		table.insert(result, bar(typ, "paleogene", "<small>Pg</small>"))
		table.insert(result, bar(typ, "neogene", "<small>N</small>"))
	end

	table.insert(result, "<div name=Range style='margin:0 auto; line-height:0; clear:both; width:"..tostring(typ.width).."px; padding:0px; height:8px; overflow:visible; background-color:transparent; position:relative; top:-4px; z-index:100;'>")
	
	if year1 and year2 then table.insert(result, mark(typ, year1_e, year2_e, 42)) end
	table.insert(result, mark(typ, year1, year2))
	
	table.insert(result, "</div Range>\n</div Timeline-row>")
	
	return table.concat(result)
end

local function show(frame)
	return _show(frame:getParent().args)
end

return {_show = _show, show = show}