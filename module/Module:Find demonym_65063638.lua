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
	'South African',
	'African',
	'Antarctican',
	'Central Asian',
	'South Asian',
	'South East Asian',
	'Southeast Asian',
	'Asian',
	'Caribbean',
	'Eurasian',
	'European',
	'Middle Eastern',
	'Central American',
	'North American',
	'South American',
	'Afghan',
	'Albanian',
	'Algerian',
	'American Samoan',
	'American',
	'Andorran',
	'Angolan',
	'Anguillan',
	'Antarctican',
	'Antigua and Barbuda',
	'Argentine',
	'Armenian',
	'Aruban',
	'Australian',
	'Austrian',
	'Azerbaijani',
	'Bahamian',
	'Bahraini',
	'Bangladeshi',
	'Barbadian',
	'Belarusian',
	'Belgian',
	'Belizean',
	'Beninese',
	'Bermudian',
	'Bhutanese',
	'Bissau-Guinean',
	'Bolivian',
	'Bosnia and Herzegovina',
	'Botswanan',
	'Bouvet Island',
	'Brazilian',
	'British Indian Ocean Territory',
	'British Virgin Islands',
	'British',
	'English',
	'Scottish',
	'Welsh',
	'Northern Irish',
	'Bruneian',
	'Bulgarian',
	'Burkinabé',
	'Burmese',
	'Burundian',
	'Cambodian',
	'Cameroonian',
	'Canadian',
	'Cape Verdean',
	'Caymanian Islands',
	'Caymanian',
	'Central African',
	'Chadian',
	'Chilean',
	'Chinese',
	'Christmas Island',
	'Cocos (Keeling) Islands',
	'Colombian',
	'Comorian',
	'Cook Islands',
	'Costa Rican',
	'Croatian',
	'Cuban',
	'Cypriot',
	'Czech',
	'Danish',
	'Democratic Republic of the Congo',
	'Djiboutian',
	'Dominica',
	'Dominican Republic',
	'Dutch',
	'East Timorese',
	'Ecuadorian',
	'Egyptian',
	'Emirati',
	'Equatoguinean',
	'Eritrean',
	'Estonian',
	'Ethiopian',
	'Falkland Islands',
	'Faroese',
	'Federated States of Micronesia',
	'Fijian',
	'Filipino',
	'Philippine',
	'Finnish',
	'French Polynesian',
	'French Southern Territories',
	'French',
	'Gabonese',
	'Gambian',
	'Georgian',
	'German',
	'Ghanaian',
	'Gibraltarian',
	'Greek',
	'Greenlandic',
	'Grenadian',
	'Guadeloupean',
	'Guam',
	'Guatemalan',
	'Guernsey',
	'Guianese',
	'Guinean',
	'Guyanese',
	'Haitian',
	'Heard Island and McDonald Islands',
	'Honduran',
	'Hong Kong',
	'Hungarian',
	'Icelandic',
	'Indian',
	'Indonesian',
	'Iranian',
	'Iraqi',
	'Irish',
	'Israeli',
	'Italian',
	'Ivorian',
	'Jamaican',
	'Japanese',
	'Jersey',
	'Jordanian',
	'Kazakh',
	'Kenyan',
	'Kiribati',
	'Kuwaiti',
	'Kosovan',
	'Kosovar',
	'Kyrgyz',
	'Lao',
	'Latvian',
	'Lebanese',
	'Lesothan',
	'Liberian',
	'Libyan',
	'Liechtensteiner',
	'Liechtenstein',
	'Lithuanian',
	'Luxembourg',
	'Macanese',
	'Macedonian',
	'Malagasy',
	'Malawian',
	'Malaysian',
	'Maldivian',
	'Malian',
	'Maltese',
	'Manx',
	'Marshallese',
	'Martiniquan',
	'Mauritanian',
	'Mauritian',
	'Mayotte',
	'Mexican',
	'Moldovan',
	'Mongolian',
	'Montenegrin',
	'Montserratian',
	'Monégasque',
	'Moroccan',
	'Mozambican',
	'Namibian',
	'Nauruan',
	'Nepalese',
	'Netherlands Antillean',
	'New Caledonian',
	'New Caledonia',
	'New Zealand',
	'Nicaraguan',
	'Nigerian',
	'Nigerien',
	'Niuean',
	'Norfolk Island',
	'North Korean',
	'Macedonian',
	'Northern Mariana Islands',
	'Norwegian',
	'Omani',
	'Pakistani',
	'Palauan',
	'Palestinian',
	'Panamanian',
	'Papua New Guinean',
	'Paraguayan',
	'Peruvian',
	'Pitcairn Islands',
	'Polish',
	'Portuguese',
	'Puerto Rican',
	'Qatari',
	'Republic of the Congo',
	'Romanian',
	'Russian',
	'Rwandan',
	'Réunionnais',
	'Sahrawi',
	'Saint Barthélemy',
	'Saint Helenian',
	'Saint Kitts and Nevis',
	'Saint Lucian',
	'Saint Martin',
	'Saint Pierre and Miquelon',
	'Saint Vincent and the Grenadines',
	'Salvadoran',
	'Sammarinese',
	'Samoan',
	'Saudi Arabian',
	'Senegalese',
	'Serbian',
	'Seychellois',
	'Sierra Leonean',
	'Singaporean',
	'Slovak',
	'Slovenian',
	'Solomon Islands',
	'Somalian',
	'South Georgia and the South Sandwich Islands',
	'South Korean',
	'Spanish',
	'Catalan',
	'Sri Lankan',
	'Sudanese',
	'Surinamese',
	'Svalbard and Jan Mayen',
	'Swazi',
	'Swedish',
	'Swiss',
	'Syrian',
	'São Tomé and Príncipe',
	'Taiwanese',
	'Tajik',
	'Tanzanian',
	'Thai',
	'Togolese',
	'Tokelauan',
	'Tongan',
	'Trinidad and Tobago',
	'Tunisian',
	'Turkish',
	'Turkmen',
	'Turks and Caicos Islands',
	'Tuvaluan',
	'Ugandan',
	'Ukrainian',
	'United States Minor Outlying Islands',
	'United States Virgin Islands',
	'Uruguayan',
	'Uzbek',
	'Vanuatuan',
	'Vatican City',
	'Venezuelan',
	'Vietnamese',
	'Wallis and Futuna',
	'Yemeni',
	'Zambian',
	'Zimbabwean',
	'Åland',
	'Find demonym/testcases'
}

-- returns the name of a country demonym that is found in the string
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