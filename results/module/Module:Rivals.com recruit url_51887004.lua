-- This module forms a rivals.com URL for [[Template:College athlete recruit end]]
local p = {}

-- Known schools with dedicated URLs
local webname = {
	['alabama'] = 1,
	['arizona'] = 1,
	['arizonastate'] = 1,
	['arkansas'] = 1,
	['arkansasstate'] = 1,
	['auburn'] = 1,
	['baylor'] = 1,
	['boisestate'] = 1,
	['bostoncollege'] = 1,
	['bwi'] = 1,
	['byu'] = 1,
	['cal'] = 1,
	['centralmichigan'] = 1,
	['charlotte'] = 1,
	['clemson'] = 1,
	['colorado'] = 1,
	['coloradostate'] = 1,
	['connecticut'] = 1,
	['depaul'] = 1,
	['duke'] = 1,
	['duquesne'] = 1,
	['eastcarolina'] = 1,
	['florida'] = 1,
	['floridastate'] = 1,
	['fresnostate'] = 1,
	['georgetown'] = 1,
	['georgiatech'] = 1,
	['houston'] = 1,
	['illinois'] = 1,
	['indiana'] = 1,
	['iowa'] = 1,
	['iowastate'] = 1,
	['kansas'] = 1,
	['kansasstate'] = 1,
	['kentstate'] = 1,
	['kentucky'] = 1,
	['louisville'] = 1,
	['lsu'] = 1,
	['maryland'] = 1,
	['memphis'] = 1,
	['miami'] = 1,
	['michigan'] = 1,
	['michiganstate'] = 1,
	['minnesota'] = 1,
	['mississippistate'] = 1,
	['missouri'] = 1,
	['ncstate'] = 1,
	['nebraska'] = 1,
	['nevada'] = 1,
	['newmexico'] = 1,
	['northcarolina'] = 1,
	['northtexas'] = 1,
	['northwestern'] = 1,
	['notredame'] = 1,
	['ohiostate'] = 1,
	['oklahoma'] = 1,
	['oklahomastate'] = 1,
	['olemiss'] = 1,
	['oregon'] = 1,
	['oregonstate'] = 1,
	['pittsburgh'] = 1,
	['purdue'] = 1,
	['richmond'] = 1,
	['rutgers'] = 1,
	['sandiegostate'] = 1,
	['smu'] = 1,
	['southcarolina'] = 1,
	['stanford'] = 1,
	['syracuse'] = 1,
	['tamu'] = 1,
	['tcu'] = 1,
	['temple'] = 1,
	['tennessee'] = 1,
	['texas'] = 1,
	['texasstate'] = 1,
	['texastech'] = 1,
	['toledo'] = 1,
	['tulane'] = 1,
	['tulsa'] = 1,
	['ucf'] = 1,
	['ucla'] = 1,
	['uga'] = 1,
	['unlv'] = 1,
	['usc'] = 1,
	['usf'] = 1,
	['utah'] = 1,
	['utsa'] = 1,
	['vanderbilt'] = 1,
	['villanova'] = 1,
	['virginia'] = 1,
	['virginiatech'] = 1,
	['wakeforest'] = 1,
	['washington'] = 1,
	['washingtonstate'] = 1,
	['westernmichigan'] = 1,
	['westvirginia'] = 1,
	['wisconsin'] = 1,
	['wku'] = 1,
	['wyoming'] = 1
}

-- Known schools without dedicated urls or simple search strings
local searchname = {
	['airforce'] = 'Air%2520Force',
	['bowlinggreen'] = 'Bowling%2520Green',
	['calpoly'] = 'Cal%2520Poly',
	['easternmichigan'] = 'Eastern%2520Michigan',
	['floridagulfcoast'] = 'Florida%2520Gulf%2520Coast',
	['louisianalafayette'] = 'Louisiana-Lafayette',
	['louisianatech'] = 'Louisiana%2520Tech',
	['loyolamarymount'] = 'Loyola%2520Marymount',
	['miamioh'] = 'Miami%2520(OH)',
	['northernillinois'] = 'Northern%2520Illinois',
	['saintmarys'] = 'Saint%2520Mary\'s',
	['sandiego'] = 'San%2520Diego',
	['sanfrancisco'] = 'San%2520Francisco',
	['sanjosestate'] = 'San%2520Jose%2520State',
	['santaclara'] = 'Santa%2520Clara',
	['southernillinois'] = 'Southern%2520Illinois',
	['stephenfaustin'] = 'Stephen%2520F.%2520Austin',
	['stfrancisbrooklyn'] = 'St.%2520Francis%2520(NY)',
	['vcu'] = 'Virginia%2520Commonwealth'
}

local function ucfirst(ta)
    local t1 = mw.ustring.gsub( ta, '^(%w)(.*)$', '%1' ) or ''
    local t2 = mw.ustring.gsub( ta, '^(%w)(.*)$', '%2' ) or ta
    return t1:upper() .. t2
end

function p.url(frame)
	local t = (frame.args['team'] or ''):lower()
	local y = tonumber(frame.args['year'] or '') or ''
	local sport = frame.args['sport'] or 'football'

	if webname[t] then
		return 'http://' .. t .. '.rivals.com/commitments/' .. sport .. '/' .. y
	else
		local sn = searchname[t] or ucfirst(t)
		sn = mw.ustring.gsub( sn, '([a-z])state$', '%1%%2520State')
		return 'https://n.rivals.com/search#?formValues=%257B%2522sport%2522:%2522' .. (sport == 'basketball' and 'Basketball' or 'Football')
			.. '%2522,%2522recruit_year%2522:' .. y 
			.. ',%2522college.common_name%2522:%255B%2522' .. sn 
			.. '%2522%255D,%2522page_number%2522:1,%2522position_group.abbreviation%2522:%2522%2522,%2522'
			.. 'position.abbreviation%2522:%2522%2522,%2522'
			.. 'status%2522:%255B%2522signed%2522,%2522verbal%2522%255D%257D'
	end
end

return p