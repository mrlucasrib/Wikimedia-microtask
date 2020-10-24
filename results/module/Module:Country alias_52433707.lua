-- This module returns the country name or the flag name for a country,
-- based on the three-letter IOC/CGA/FINA alias.

--[[
The following country code is used for multiple countries:
    ANG (workaround: added ANG_CGF for use with Commonwealth Games)

The following names have different names/flags based on sport/year
    Great Britain (and N.I.)         GBR, GBR_WCA (latter added to add text in parens)
    Hong Kong                        HKG, HKG_CGF (latter added to keep colonial flag)
    Individual Olympic Athletes      IOA, IOA_2000 (IOA changed to Independent Olympic Athletes in 2012)
    SWZ                              Swaziland became Eswatini after the 2018 Commonwealth Games
    MKD								 Macedonia became North Macedonia in 2019
    ART								 No "Athlete" before Refugee Team @ 2017 AIMAG

The following countries have multiple aliases due to CGF/IOC/FINA/IAAF/etc differences, or deprecated uses
    Anguilla                         AIA, ANG_CGF
    Antigua and Barbuda              ANT, ATG
    Bahrain                          BHN, BHR, BRN
    Curaçao                          CUR, CUW
    East Timor						 TLS, TMP
    Faroe Islands                    FAR, FRO
    Guernsey                         GGY, GUE
    Iran                             IRI, IRN
    Ireland                          IRE, IRL - IRE is *only* for CGF apps
    Jersey                           JER, JEY
    Lebanon                          LBN, LIB
    Montserrat                       MNT, MSR
    Nicaragua                        NCA, NIC
    Norfolk Island                   NFI, NFK
    Oman                             OMA, OMN
    Refugee Olympic Team             ROA, ROT
    Romania                          ROM, ROU
    Saint Helena                     SHE, SHN
    Saint Vincent and the Grenadines SVG, VIN
    Sarawak                          SAR, SWK
    Singapore                        SGP, SIN
    South Africa                     RSA, SAF
    Tonga                            TGA, TON
    Trinidad and Tobago              TRI, TTO
    Turks and Caicos Islands         TCA, TCI, TKS

Oddity that needs to be revisited
    French Polynesia                 PYF, TAH - TAH has been converted to Tahiti per SILENCE
]]

local function stripToNil(text)
	-- If text is a string, return its trimmed content, or nil if empty.
	-- Otherwise return text (which may, for example, be nil).
	if type(text) == 'string' then
		text = text:match('(%S.-)%s*$')
	end
	return text
end

local function yes(parameter)
	-- Return true if parameter should be interpreted as "yes".
	return ({ y = true, yes = true, on = true, [true] = true })[parameter]
end

local function getAlias(args)
	-- Return alias parameter, possibly modified for exceptional cases.
	local alias = stripToNil(args.alias)
	local games = stripToNil(args.games)
	local year = tonumber(args.year)
	local fullName = stripToNil(args.fullName)
	if fullName then
		year = tonumber(fullName:match('^%d+'))  -- ignore args.year
	end
	if alias == 'ANG' then
		if games == 'Commonwealth Games' then
			alias = 'ANG_CGF'
		end
	elseif alias == 'ART' then
		if games == 'Asian Indoor and Martial Arts Games' then
			alias = 'ART_AIMAG'
		end
	elseif alias == 'GBR' then
		if games == 'World Championships in Athletics' or games == 'European Athletics Championships' then
			alias = 'GBR_WCA'
		elseif games == 'European Championships' then
			if year == 2018 then
				alias = 'GBR_WCA'
			end
		end
	elseif alias == 'HKG' then
		if games == 'Commonwealth Games' then
			alias = 'HKG_CGF'
		end
	elseif alias == 'IOA' then
		if year == 2000 then
			alias = 'IOA_2000'
		end
	elseif alias == 'MAL' then
		if year and year > 1963 then
			alias = 'MAS'
		end
	elseif alias == 'SWZ' then
		if fullName then
			if year and year >= 2018 and fullName ~= '2018 Commonwealth Games' then
				alias = 'SWZ_YO2018'
			end
		elseif year and year >= 2018 and games ~= 'Commonwealth Games' then
			alias = 'SWZ_YO2018'
		end
	elseif alias == 'MKD' then
		if year and year >= 2019 then
			alias = 'MKD_2019'
		end
	elseif alias == 'VNM' then
		if year and year <= 1954 then
			alias = 'VIE'
		end
	end
	return alias
end

local function getFlag(args, country)
	-- Return name of flag selected from country data (nil if none defined).
	local year = tonumber(args.year)
	local games = stripToNil(args.games)
	if games then
		local gdata = country[games]
		if gdata then
			if type(gdata) == 'string' then
				return gdata
			end
			if gdata[year] then
				return gdata[year]
			end
		end
	end
	for _, item in ipairs(country) do
		if type(item) == 'string' then
			return item
		end
		if year and year <= item[1] then
			return item[2]
		end
	end
end

local data = mw.loadData('Module:Country alias/data')
local function countryAlias(args)
	local alias = getAlias(args)
	local country = data.countries[alias] or data.countries[data.countryAliases[alias]]
	local function quit(message)
		return args.error or error(message)
	end
	if not country then
		return quit('Invalid country alias: ' .. tostring(alias))
	end
	if yes(args.flag) then
		return getFlag(args, country) or quit('No flag defined for ' .. alias)
	else
		return country.name or quit('No name defined for ' .. alias)
	end
end

local function flagIOC(frame)
	-- Implement {{flagIOC}} which previously called this module three times.
	-- Returns <flag> <country link> <athletes>, with the third value optional
	local args = frame:getParent().args
	local code = stripToNil(args[1]) or error('flagIOC parameter 1 should be a country code')
	local games = stripToNil(args[2])
	local athletes = stripToNil(args[3])
	games = games and (games .. ' Olympics') or 'Olympics'
	local parms = {
		alias = code,
		fullName = games,
		year = games:match('^%d+'),
		games = games:gsub('^%d+ ?', ''),
	}
	local fullName = countryAlias(parms)
	parms.flag = true
	return (('[[File:{flag}|22x20px|border|alt=|link=]]&nbsp;[[{name} at the {games}|{name}]]{athletes}')
		:gsub('{(%w+)}', {
			athletes = athletes and
				('&nbsp;<span style="font-size:90%;">(' .. athletes .. ')</span>') or
				'',
			flag = countryAlias(parms),
			games = games,
			name = fullName,
		}))
end

local function flagXYZ(frame)
	-- Implement {{flagIOC2}} and its variants which previously called this module three times.
	-- Returns one of four possible outputs:
	--	from flagIOC2:			<flag> <country link> <athletes>, with the third value optional
	--	from flagIOC2team:		<flag> <country link> <country alias>
	--	from flagIOC2athlete:	<flag> <athlete(s)> <country alias/link>
	--	from flagIOC2medalist:	<athlete(s)><br><flag> <country link>
	local args = frame:getParent().args
	local dispType = stripToNil(frame.args['type'])
	local code=''
	local games=''
	local athletes=''
	if dispType == 'name' or dispType == 'team' then
		code = stripToNil(args[1]) or error('Parameter 1 should be a country code')
		games = stripToNil(args[2]) or error('Parameter 2 should be a competition name')
		athletes = stripToNil(args[3])
	elseif dispType == 'athlete' or dispType == 'medalist' then
		athletes = stripToNil(args[1]) or error('Parameter 1 should be the name(s) of the athlete(s)')
		code = stripToNil(args[2]) or error('Parameter 2 should be a country code')
		games = stripToNil(args[3]) or error('Parameter 3 should be a competition name')
	end
	local dispName = stripToNil(args.name)
	
	local parms = {
		alias = code,
		fullName = games,
		year = games:match('^%d+'),
		games = games:gsub('^%d+ ?', ''),
	}
	local fullName = countryAlias(parms)
	parms.flag = true
	
	if dispType == 'name' then
		return (('[[File:{flag}|22x20px|border|alt=|link=]]&nbsp;[[{name} at the {games}|{dispName}]]{athletes}')
			:gsub('{(%w+)}', {
				athletes = athletes and
					('&nbsp;<span style="font-size:90%;">(' .. athletes .. ')</span>') or
					'',
				flag = countryAlias(parms),
				games = games,
				name = fullName,
				dispName = dispName or fullName,
			}))
	elseif dispType == 'team' then
		return (('[[File:{flag}|22x20px|border|alt=|link=]]&nbsp;[[{name} at the {games}|{dispName}]]{alias}')
			:gsub('{(%w+)}', {
				alias = ('&nbsp;<span style="font-size:90%;">(' .. code .. ')</span>'),
				flag = countryAlias(parms),
				games = games,
				name = fullName,
				dispName = dispName or fullName,
			}))
	elseif dispType == 'athlete' then
		return (('[[File:{flag}|22x20px|border|alt=|link=]]&nbsp;{athletes}&nbsp;<span style="font-size:90%;">([[{name} at the {games}|{dispName}]])</span>')
			:gsub('{(%w+)}', {
				athletes = athletes,
				flag = countryAlias(parms),
				games = games,
				name = fullName,
				dispName = code,
			}))
	elseif dispType == 'medalist' then
		return (('{athletes}<br>[[File:{flag}|23x15px|border|alt=|link=]]&nbsp;[[{name} at the {games}|{dispName}]]')
			:gsub('{(%w+)}', {
				athletes = athletes,
				flag = countryAlias(parms),
				games = games,
				name = fullName,
				dispName = dispName or fullName,
			}))
	end
end
local function main(frame)
	return countryAlias(frame.args)
end

return {
	flagIOC = flagIOC,
	flagXYZ = flagXYZ,
	main = main,
}