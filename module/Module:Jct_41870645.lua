local p = {}

local SANDBOX = false
local SANDBOX_SUFFIX = SANDBOX and '/sandbox' or ''

local concat = table.concat
local insert = table.insert
local getArgs = require('Module:Arguments').getArgs -- Import module function to work with passed arguments
local parserModule = require("Module:Road data/parser" .. SANDBOX_SUFFIX)
local parser = parserModule.parser

-- Shields
local rdt

local function size(args)
	local country = args.country
	local state = args.state or args.province or ''
	local type = args.type
	if rdt then
		return 'x17'
	elseif state == 'FL' then
		if type == 'Toll' or type == 'FLTP' or type == 'HEFT' then
			return '20'
		elseif type == 'Both' then
			return '20', 'x20'
		end
	elseif state == 'NY' then
		if type == 'NY 1927' or type == 'NY 1948' or (type == 'Parkway' and args.route == "Robert Moses") or (type == 'CR' and args.county == 'Erie') then
			return '20'
		end
	elseif state == 'AB' then
		if type == 'AB' or type == 'Hwy' or type == '2ndHwy' or type == 'TCH' then
			return '18'
		end
	elseif state == 'NS' and type == 'Hwy' or type == 'TCH' then
		return '18'
	elseif state == 'ON' then
		if type == 'ON' or type == 'Hwy' or type == 'Highway' or type == 'QEW' then
			return '24x22'
		elseif type == 'KLR' then
			return '21'
		else
			local countyTypes = {CH = true, RH = true, District = true, Regional = true, County = true, Municipal = true}
			if countyTypes[type] then
				return '19'
			end
		end
	elseif state == 'QC' then
		if type == 'QC' or type == 'Route' or type == 'A' or type == 'Autoroute' or type == 'TCH' or type == 'ON' then
			return '18'
		end
	elseif state == 'SK' then
		if type == 'Hwy' or type == 'SK' then
			return 'x25'
		end
	elseif country == 'MEX' then
		return 'x25'
	elseif country == 'FRA' then
		return 'x18'
	elseif country == 'TUR' then
		return 'x15'
	end
	
	return 'x20'
end
 
local function shield(args, frame)
	if args.noshield then return '' end
	local firstSize, secondSize = size(args)
	local shield, second = parser(args, 'shield')
	if not shield or shield == '' then
		return ''
	elseif type(shield) == 'table' then
		shield, second = shield[1], shield[2]
	end
	local function render(shield, size)
		if frame:callParserFunction('#ifexist', 'Media:' .. shield, '1') ~= '' then
			return string.format("[[File:%s|%spx|link=|alt=]]", shield, size)
		else
			args.shielderr = true
			local page = mw.title.getCurrentTitle().prefixedText -- Get transcluding page's title
			return mw.ustring.format("[[Category:Jct template errors|1 %s]]", page)
		end
	end
	local rendered = render(shield, firstSize)
	if second and type(second) == 'string' then
		local size = secondSize or firstSize
		rendered = rendered .. render(second, size)
	end
	return rendered
end

-- Links/abbreviations
local function link(args)
	local nolink = args.nolink
	local abbr = parser(args, 'abbr')
	if nolink then
		return abbr
	else
		local link = parser(args, 'link')
		if not link or link == '' then
			return abbr
		else
			return mw.ustring.format("<span class=\"nowrap\">[[%s|%s]]</span>", link, abbr)
		end
	end
end

local function completeLink(args, num)
	local actualLink = link(args)
	if not actualLink then
		local page = mw.title.getCurrentTitle().prefixedText -- Get transcluding page's title
		actualLink = string.format("<span class=\"error\">Invalid type: %s</span>[[Category:Jct template errors|2 %s]]", args.type, page)
	end
	local isTo = args.to
	local prefix
	if num == 1 then
		if isTo then
			prefix = "To "
		else
			prefix = ''
		end
	else
		if isTo then
			prefix = " to "
		else
			prefix = " / "
		end
	end
	local suffix = {}
	local dir = args.dir
	if dir then
		insert(suffix, ' ' .. string.lower(dir))
	end
	local name = args.name
	if name then
		insert(suffix, mw.ustring.format(' (%s)', name))
	end
	return prefix .. actualLink .. concat(suffix)
end

local function namedLink(args, num)
	local actualLink = link(args)
	local name = args.name or ''
	local isTo = args.to
	local prefix
	if num == 1 then
		if isTo then
			prefix = "To "
		else
			prefix = ''
		end
	else
		if isTo then
			prefix = " to "
		else
			prefix = " / "
		end
	end
	local suffix = {}
	local dir = args.dir
	if name ~= '' then
		if dir then
			insert(suffix, mw.ustring.format(' (%s %s)', actualLink, dir))
		else
			insert(suffix, mw.ustring.format(' (%s)', actualLink))
		end
	else
		insert(suffix, actualLink)
		if dir then insert(suffix, ' ' .. string.lower(dir)) end
	end
	return prefix .. name .. concat(suffix)
end

local function banners(routes)
	local format = string.format
	local firstRun = {}
	local hasBanner = false
	for k,v in ipairs(routes) do
		local banner
		if v.shield == '' or v.shielderr then
			banner = false
		else
			banner = parser(v, 'banner') or ''
			if banner and banner ~= '' then
				hasBanner = true
			end
		end
		insert(firstRun, banner)
	end
	if not hasBanner then return '' end
	local secondRun = {}
	for k,v in ipairs(routes) do
		local bannerFile = firstRun[k]
		if not bannerFile then
			
		elseif bannerFile == '' then
			local widthCode = parser(v, 'width') or 'square'
			if type(widthCode) == 'number' then
				insert(secondRun, "[[File:No image wide.svg|" .. tostring(widthCode) .. "px|link=|alt=]]")
			elseif widthCode == 'square' then
				insert(secondRun, "[[File:No image wide.svg|20px|link=|alt=]]")
			elseif widthCode == 'expand' then
				local route = v.route
				local width = (#route >= 3) and '25' or '20'
				insert(secondRun, format("[[File:No image wide.svg|%spx|link=|alt=]]", width))
			elseif widthCode == 'wide' then
				insert(secondRun, "[[File:No image wide.svg|25px|link=|alt=]]")
			elseif widthCode == 'US1926' then
				insert(secondRun, "[[File:No image wide.svg|21px|link=|alt=]]")
			elseif widthCode == 'SD' then
				local route = v.route
				local width = (#route >= 3) and '23' or '20'
				insert(secondRun, format("[[File:No image wide.svg|%spx|link=|alt=]]", width))
			elseif (v.state == 'CA') or (v.type == 'CA') then
				local route = v.route
				local widths = {default = {'20', '25'}, I = {'20', '24'}, US = {'20', '23'}, SR = {'19', '22'}}
				local width = widths[widthCode] or widths.default
				local pixels = (#route >= 3) and width[2] or width[1]
				insert(secondRun, format("[[File:No image wide.svg|%spx|link=|alt=]]", pixels))
			end
		else
			local widthCode = parser(v, 'width') or 'square'
			if widthCode == 'square' then
				insert(secondRun, format("[[File:%s|20px|link=|alt=]]", bannerFile))
			elseif widthCode == 'expand' then
				local route = v.route
				if #route >= 3 then
					insert(secondRun, format("[[File:No image.svg|2px|link=|alt=]][[File:%s|20px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile))
				else
					insert(secondRun, format("[[File:%s|20px|link=|alt=]]", bannerFile))
				end
			elseif widthCode == 'wide' then
				insert(secondRun, format("[[File:No image.svg|2px|link=|alt=]][[File:%s|20px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile))
			elseif widthCode == 'SD' then
				local route = v.route
				if #route >= 3 then
					insert(secondRun, format("[[File:No image.svg|1px|link=|alt=]][[File:%s|20px|link=|alt=]][[File:No image.svg|2px|link=|alt=]]", bannerFile))
				else
					insert(secondRun, format("[[File:%s|20px|link=|alt=]]", bannerFile))
				end
			elseif widthCode == 'MOSupp' then
				local route = v.route
				if #route >= 2 then
					insert(secondRun, format("[[File:No image.svg|2px|link=|alt=]][[File:%s|20px|link=|alt=]][[File:No image.svg|3px|link=|alt=]]", bannerFile))
				else
					insert(secondRun, format("[[File:%s|20px|link=|alt=]]", bannerFile))
				end
			elseif widthCode == 'US1926' then
				insert(secondRun, format("[[File:%s|20px|link=|alt=]][[File:No image.svg|1px|link=|alt=]]", bannerFile))
			elseif v.state == 'CA' then
				local route = v.route
				local type = v.type
				if type == 'US-Bus' then
					if #route >= 3 then
						insert(secondRun, format("[[File:No image.svg|1px|link=|alt=]][[File:%s|20px|link=|alt=]][[File:No image.svg|2px|link=|alt=]]", bannerFile))
					else
						insert(secondRun, format("[[File:%s|20px|link=|alt=]]", bannerFile))
					end
				elseif type == 'CA-Bus' or type == 'SR-Bus' then
					if #route >= 3 then
						insert(secondRun, format("[[File:No image.svg|1px|link=|alt=]][[File:%s|19px|link=|alt=]][[File:No image.svg|2px|link=|alt=]]", bannerFile))
					else
						insert(secondRun, format("[[File:%s|19px|link=|alt=]]", bannerFile))
					end
				end
			end
		end
	end
	return concat(secondRun) .. '<br>'
end

local function extra(args)
	local extraTypes = {rail = {default = "[[File:Rail Sign.svg|20px|alt=|link=]]",
	                            CAN = {default = "[[File:Ontario M509.svg|20px|alt=|link=]]",
                                           QC = "[[File:Québec I-310.svg|20px|alt=|link=]]"},
	                            CHL = "[[File:Chile IS-13b.svg|20px|alt=|link=]]",
	                            IDN = "[[File:Indonesia New Road Sign Info 5A2.png|20px|alt=|link=]]",
	                            JPN = "[[File:Japanese Road sign 125-C.svg|20px|alt=|link=]]",
	                            MEX = "[[File:Mexico road sign estacion de ferrocarril.svg|20px|alt=|link=]]"},
	                    ["light-rail"] = "[[File:Light Rail Sign.svg|20px|alt=|link=]]",
	                    bus = {default = "[[File:Bus Sign.svg|20px|alt=|link=]]",
	                           CAN = {default = "[[File:Ontario M506.svg|20px|alt=|link=]]",
                                          QC = "[[File:Québec I-315.svg|20px|alt=|link=]]"},
	                           FRA = "[[File:France road sign C6.svg|20px|alt=|link=]]",
	                           HRV = "[[File:Croatia road sign C44.svg|20px|alt=|link=]]",
	                           HUN = "[[File:Hungary road sign E-039.svg|20px|alt=|link=]]",
	                           ITA = "[[File:Italian traffic sign - fermata autobus.svg|20px|alt=|link=]]",
	                           JPN = "[[File:Japanese Road sign 124-C.svg|20px|alt=|link=]]",
	                           MEX = "[[File:Mexico road sign parada de autobus.svg|20px|alt=|link=]]",
	                           NOR = "[[File:Norwegian-road-sign-508.1.svg|20px|alt=|link=]]",
	                           URY = "[[File:Uruguay Road Sign I24.svg|20px|alt=|link=]]"},
	                    ferry = {default = "[[File:Ferry Sign.svg|20px|alt=|link=]]",
	                             CAN = "[[File:Ontario M508.svg|20px|alt=|link=]]",
	                             CHL = "[[File:Chile IS-14b.svg|20px|alt=|link=]]",
	                             FRA = "[[File:France road sign CE10.svg|20px|alt=|link=]]",
	                             HRV = "[[File:Croatia road sign C49.svg|20px|alt=|link=]]",
	                             ITA = "[[File:Italian traffic signs - auto su nave.svg|20px|alt=|link=]]"},
	                    hospital = {default = "[[File:Hospital sign.svg|20px|alt=|link=]]",
	                                AUS = "[[File:Western Australia MR-SM-1.svg|20px|alt=|link=]]",
	                                AUT = "[[File:Hinweiszeichen 2.svg|20px|alt=|link=]]",
	                                CAN = {default = "[[File:Québec I-280-1.svg|20px|alt=|link=]]",
	                                       ON = "[[File:Ontario M401.svg|20px|alt=|link=]]"},
	                                CHE = "[[File:CH-Hinweissignal-Spital.svg|20px|alt=|link=]]",
	                                CHL = "[[File:Chile IS-1b.svg|20px|alt=|link=]]",
	                                CZE = "[[File:IJ02cr.jpg|20px|alt=|link=]]",
	                                ESP = "[[File:Spain traffic signal s23.svg|20px|alt=|link=]]",
	                                FRA = "[[File:France road sign ID3.svg|20px|alt=|link=]]",
	                                GBR = "[[File:UK traffic sign 827.2.svg|20px|alt=|link=]]",
	                                GRC = "[[File:Traffic Sign GR - KOK 2009 - P-22.svg|20px|alt=|link=]]",
	                                HUN = "[[File:Hungary road sign E-045.svg|20px|alt=|link=]]",
	                                IDN = "[[File:Indonesian Road Sign d9a.png|20px|alt=|link=]]",
	                                ISL = "[[File:Iceland road sign E01.12.svg|20px|alt=|link=]]",
	                                ITA = "[[File:Italian traffic signs - ospedale.svg|20px|alt=|link=]]",
	                                MEX = "[[File:Mexico road sign medico.svg|20px|alt=|link=]]",
	                                POL = "[[File:Znak D-21.svg|20px|alt=|link=]]",
	                                RUS = "[[File:7.2 Russian road sign.svg|20px|alt=|link=]]",
	                                SVK = "[[File:Dopravná značka II5.svg|20px|alt=|link=]]",
	                                TUR = "[[File:Turkish road sign 84.jpg|20px|alt=|link=]]",
	                                UKR = "[[File:Ukraine road sign 6.2.gif|20px|alt=|link=]]",
	                                URY = "[[File:Uruguay Road Sign I16.svg|20px|alt=|link=]]"},
	                    airport = {default = "[[File:Airport Sign.svg|20px|alt=|link=]]",
	                               AUS = "[[File:Western Australia MR-SM-11.svg|20px|alt=|link=]]",
	                               CAN = {default = "[[File:Ontario M502.svg|20px|alt=|link=]]",
                                             QC = "[[File:Québec I-300-1.svg |20px|alt=|link=]]"},
	                               CHL = "[[File:Chile IS-11b.svg|20px|alt=|link=]]",
	                               GBR = "[[File:Aircraft Airport ecomo.svg|20px|alt=|link=]]",
	                               HRV = "[[File:Croatia road sign C47.svg|20px|alt=|link=]]",
	                               IDN = "[[File:Indonesia New Road Sign Info 5a4.png|20px|alt=|link=]]",
	                               MEX = "[[File:Mexico road sign aeropuerto.svg|20px|alt=|link=]]",
	                               NOR = "[[File:Norwegian-road-sign-771.0.svg|20px|alt=|link=]]",
	                               TWN = "[[File:Legenda lotnisko.svg|20px|alt=|link=]]",
	                               UKR = "[[File:Ukraine road sign 5.65.png|20px|alt=|link=]]",
	                               URY = "[[File:Uruguay Road Sign I21.svg|20px|alt=|link=]]"},
						toll = {default = "",
									ESP = "[[File:Spain traffic signal r200.svg|18px|alt=|link=]]"}}
	
	local extraIcon = extraTypes[string.lower(args.extra or '')]
	if not extraIcon then
		return ''
	elseif type(extraIcon) == 'table' then
		local extraIconT = extraIcon[args.country] or extraIcon.default
		if type(extraIconT) == 'table' then
			return extraIconT[args.state] or extraIconT[args.province] or extraIconT.default
		else
			return extraIconT
		end
	else
		return extraIcon
	end
end

local function parseArgs(args)
	local state = args.state or args.province
	local country
	if args.country then
		country = string.upper(args.country)
		args.country = country
	else
		local countryModule = mw.loadData("Module:Road data/countrymask")
		country = countryModule[state] or 'UNK'
		args.country = country
	end
	local params = {'denom', 'county', 'township', 'dab', 'nolink', 'noshield', 'to', 'dir', 'name'}
	local routeArgs = {}
	local routeCount = 1
	while true do
		local routeType = args[routeCount * 2 - 1]
		if not routeType then break end
		local route = {type = routeType, route = args[routeCount * 2]}
		for _,v in pairs(params) do
			route[v] = args[v .. routeCount]
		end
		if args.nolink then
			route.nolink = args.nolink
		end
		route.country = country
		route.state = state
		insert(routeArgs, route)
		routeCount = routeCount + 1
	end
	return routeArgs
end

function p._jct(args, frame)
	rdt = args.rdt
	local routes = parseArgs(args)
	local extra = extra(args)
	local shields = {}
	local links = {}
	frame = frame or mw.getCurrentFrame()
	for num,route in ipairs(routes) do
		local routeShield = shield(route, frame)
		insert(shields, routeShield)
		route.shield = routeShield
		if args.jctname then
			insert(links, namedLink(route, num))
		else
			insert(links, completeLink(route, num))
		end
	end
	local bannerText = banners(routes)
	local shieldText = concat(shields)
	local linkText = concat(links)
	local graphics = (not(args.noshield) and (bannerText .. shieldText) or '') .. extra .. ' '
	
	local cities = ''
	if args.city1 or args.location1 then
		local cityModule = require("Module:Jct/city" .. SANDBOX_SUFFIX)
		cities = cityModule.city(args)
	end
	
	local roadStr = ''
	local road = args.road
	if road then
		if args.toroad then
			roadStr = ' to ' .. road
		else
			roadStr = ' / ' .. road
		end
	end
	
	local output = graphics .. linkText .. roadStr .. cities
	return mw.text.trim(output)
end

function p.jct(frame)
	local args = getArgs(frame)
	return p._jct(args, frame)
end

return p