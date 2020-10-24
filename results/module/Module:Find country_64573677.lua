--[[ v1.00
     Test the string against the list of countries/continents.
     Return the first word which matches a country/continent name ...
     unless the "match=" parameter specifies a different match.
     If there is no match, then return an empty string ... unless
     the "nomatch" parameter specifies something different
]]

local getArgs = require('Module:Arguments').getArgs
local p = {}

-- config
local nomatch = ""
local matchnum = 1

local countryList = {
	'South Africa',
	'the Central African Republic',
	'Central African Republic',	
	'Africa',
	'Antarctica',
	'Central Asia',
	'South Asia',
	'South East Asia',
	'Southeast Asia',
	'Asia',
	'the Caribbean',
	'Caribbean',
	'Eurasia',
	'Europe',
	'the Middle East',
	'Middle East',
	'Central America',
	'North America',
	'South America',
	'the Americas',
	'Afghanistan',
	'Albania',
	'Algeria',
	'American Samoa',
	'Andorra',
	'Angola',
	'Anguilla',
	'Antigua and Barbuda',
	'Argentina',
	'Armenia',
	'Aruba',
	'Australia',
	'the Austrian Empire',
	'Austrian Empire',	
	'Austria-Hungary',
	'Austria',
	'Azerbaijan',
	'the Bahamas',
	'Bahamas',
	'Bahrain',
	'Bangladesh',
	'Barbados',
	'Belarus',
	'Belgium',
	'Belize',
	'Benin',
	'Bermuda',
	'Bhutan',
	'Bolivia',
	'Bosnia',
	'Botswana',
	'Brazil',
	'Brunei Darussalam',
	'Brunei',
	'Bulgaria',
	'Burkina Faso',
	'Burundi',
	'Cambodia',
	'Cameroon',
	'Canada',
	'Cape Verde',
	'the Cayman Islands',
	'Cayman Islands',
	'Chad',
	'Chile',
	"the People's Republic of China",
	"People's Republic of China",
	'China PR',
	'PR China',
	'China',
	'Colombia',
	'Comoros',
	'the Republic of the Congo',
	'the Democratic Republic of the Congo',
	'Democratic Republic of the Congo',
	'Congo DR',
	'DR Congo',
	'DRC',	
	'the Congo',
	'Congo',
	'Cook Islands',
	'Costa Rica',
	'Croatia',
	'Cuba',
	'Curaçao',
	'Curacao',
	'Cyprus',
	'the Czech Republic',
	'Czech Republic',
	'Czechia',
	'Denmark',
	'Djibouti',
	'the Dominican Republic',
	'Dominican Republic',
	'Dominica',
	'East Timor',
	'Timor-Leste',
	'Ecuador',
	'Egypt',
	'El Salvador',
	'England',
	'Eritrea',
	'Estonia',
	'Eswatini',	
	'Ethiopia',
	'the Falkland Islands',
	'Falkland Islands',
	'the Faroe Islands',
	'Faroe Islands',
	'Fiji',
	'Finland',
	'France',
	'Gabon',
	'the Gambia',
	'Gambia',
	'Georgia',
	'Germany',
	'Ghana',
	'Gibraltar',
	'Great Britain',
	'Britain',
	'Greece',
	'Grenada',
	'Guam',
	'Guatemala',
	'Papua New Guinea',	
	'Equatorial Guinea',	
	'Guinea-Bissau',
	'Guinea',
	'Guyana',
	'Haiti',
	'Honduras',
	'Hong Kong',
	'Hungary',
	'Iceland',
	'India',
	'Indonesia',
	'Iran',
	'Iraq',
	'Northern Ireland',	
	'the Republic of Ireland',
	'Republic of Ireland',
	'Ireland',
	'Israel',
	'Italy',
	'Ivory Coast',
	"Côte d'Ivoire",
	'Jamaica',
	'Japan',
	'Jordan',
	'Kazakhstan',
	'Kenya',
	'Kiribati',
	'Kosovo',
	'the Republic of Kosovo',
	'Republic of Kosovo',
	'Kuwait',
	'Kyrgyzstan',
	'the Kyrgyz Republic',
	'Kyrgyz Republic',
	"the Lao People's Democratic Republic",
	"Lao People's Democratic Republic",
	'Laos',
	'Latvia',
	'Lebanon',
	'Lesotho',
	'Liberia',
	'Libya',
	'Liechtenstein',
	'Lithuania',
	'Luxembourg',
	'Macau',
	'the Republic of Macedonia',
	'Republic of Macedonia',
	'North Macedonia',
	'Macedonia',
	'Madagascar',
	'Malawi',
	'Malaysia',
	'the Maldives',
	'Maldives',
	'Mali',
	'Malta',
	'the Marshall Islands',
	'Marshall Islands',
	'Mauritania',
	'Mauritius',
	'Mexico',
	'the Federated States of Micronesia',
	'Federated States of Micronesia',
	'Micronesia',
	'FSM',
	'Moldova',
	'Monaco',
	'Mongolia',
	'Montenegro',
	'Montserrat',
	'Morocco',
	'Mozambique',
	'Myanmar',
	'Namibia',
	'Nauru',
	'Nepal',
	'the Netherlands',
	'Netherlands',
	'New Caledonia',
	'New Zealand',
	'Nicaragua',
	'Nigeria',
	'Niger',
	'North Korea',
	"the People's Democratic Republic of Korea",
	"the Democratic People's Republic of Korea",
	"Democratic People's Republic of Korea",
	"People's Democratic Republic of Korea",
	'DPR Korea',
	'Korea DPR',
	'Norway',
	'Oman',
	'the Ottoman Empire',
	'Ottoman Empire',
	'Ottoman Egypt',	
	'Pakistan',
	'Palau',
	'Mandatory Palestine',
	'Palestine',
	'the Palestinian territories',
	'Palestinian territories',
	'Panama',
	'Paraguay',
	'Peru',
	'the Philippines',
	'Philippines',
	'Poland',
	'Portugal',
	'Puerto Rico',
	'the Spanish Virgin Islands',
	'Spanish Virgin Islands',
	'Qatar',
	'Romania',
	'the Russian Empire',
	'Russian Empire',
	'the Russian Federation',
	'Russian Federation',
	'Russia',
	'Rwanda',
	'Saint Kitts and Nevis',
	'Saint Lucia',
	'Saint Vincent and the Grenadines',
	'Western Samoa',
	'Samoa',
	'San Marino',
	'São Tomé and Príncipe',
	'São Tomé and Príncipe',
	'Sao Tome and Principe',
	'Saudi Arabia',
	'Scotland',
	'Senegal',
	'Serbia',
	'Seychelles',
	'Sierra Leone',
	'Singapore',
	'Slovakia',
	'Slovenia',
	'the Solomon Islands',
	'Solomon Islands',
	'Somalia',
	'South Korea',
	'the Republic of Korea',
	'Korea Republic',
	'South Sudan',
	'Sudan',
	'Spain',
	'Sri Lanka',
	'Suriname',
	'Swaziland',
	'Sweden',
	'Switzerland',
	'Syria',
	'Tahiti',
	'the Republic of China',
	'Republic of China',
	'Taiwan',
	'Tajikistan',
	'Tanzania',
	'Thailand',
	'Togo',
	'Tonga',
	'Trinidad and Tobago',
	'Trinidad',
	'Tobago',
	'Tunisia',
	'Turkey',
	'Turkmenistan',
	'Turks and Caicos Islands',
	'Tuvalu',
	'Uganda',
	'Ukraine',
	'the United Arab Emirates',
	'the UAE',
	'the U.A.E.',
	'United Arab Emirates',
	'UAE',
	'U.A.E.',
	'the United Kingdom',
	'United Kingdom',
	'the UK',
	'the U.K.',
	'UK',
	'U.K.',
	'the United States of America',
	'the United States',
	'the USA',
	'the U.S.A.',
	'United States of America',
	'United States',
	'USA',
	'U.S.A.',
	'America',
	'Uruguay',
	'Uzbekistan',
	'Vanuatu',
	'Venezuela',
	'Vietnam',
	'the British Virgin Islands',
	'British Virgin Islands',
	'UK Virgin Islands',
	'U.K. Virgin Islands',
	'the United States Virgin Islands',
	'the US Virgin Islands',
	'the U.S. Virgin Islands',
	'United States Virgin Islands',
	'US Virgin Islands',
	'U.S. Virgin Islands',
	'the Virgin Islands',
	'Virgin Islands',
	'Wales',
	'Yemen',
	'Zambia',
	'Zimbabwe',
	'Find country/testcases'
}

-- returns the name of a country that is found in the string
-- ... or an empty string if there is no match
function findcountryinstring(str)

	nMatches = 0
	myMatches ={}
	str=" " .. str:gsub("^%s*(.-)%s*$", "%1") .. " "

		-- check agaist each country
		-- if there is a match, then return that country
		for i, thiscountry in ipairs(countryList) do
			if mw.ustring.find(str, thiscountry) then
				nMatches = nMatches + 1
				myMatches[nMatches] = thiscountry
			end
		end


	if (nMatches == 0) then
		-- none of the title words matches a whole country
		return nomatch
	end
	
	if ((matchnum >= 1) and (matchnum <= nMatches)) then
		return myMatches[matchnum]
	end

	if (matchnum < 0) then
		matchnum = matchnum + 1 -- so that -1 is the last match etc
		if ((matchnum + nMatches) >= 1) then
			return myMatches[matchnum + nMatches]
		end
	end
	
	-- if we get here, we have not found a match at the position specified by "matchnum"
	return nomatch
end

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	if (args['nomatch'] ~= nil) then
		nomatch = args['nomatch']
	end
	
	-- by default, we return the first match
	-- but the optional "C" paarmeter sets the "matchnum" variable, which
	-- * for a positive matchnum "n", returns the nth match if it exists
	-- * for a positive matchnum "n", returns (if it exists) the nth match
	--   counting backwards from the end.
	--   So "match=-1" returns the last match
	--   and "match=-3" returns the 3rd-last match
	if (args['match'] ~= nil) then
		matchnum = tonumber(args['match'])
		if ((matchnum == nil) or (matchnum == 0)) then
			matchnum = 1
		end
	end
	
	-- by default, we use the current page
	-- but if the "string=" parameters is supplied, we use that
	-- so we try the parameter first
	thispagename = nil
	if ((args['string'] ~= nil) and (args['string'] ~= "")) then
		-- we have a non-empty "string" parameter, so we use it
		thisstring = args['string']
	else
		-- get the page title
		thispage = mw.title.getCurrentTitle()
		thisstring = thispage.text;
	end
	
	-- now check the pagename to try to find a country
	result = findcountryinstring(thisstring)
	if (result == "") then
		return nomatch
	end
	return result
end

return p