local CountryAdjectiveDemonym = { }

local CountryAdjectiveDemonymDataLoaded = false

local countryAdjectivesToNounsTable = { }
local countryNounsToAdjectivesTable  = { }

local countryDemonymsToNounsTable = { }
local countryNounsToDemonymsTable  = { }

local countriesPrefixedByTheTable = { }

function CountryAdjectiveDemonymDoLoadData()
	countriesPrefixedByTheTable = mw.loadData( 'Module:CountryAdjectiveDemonym/The' )
	countryNounsToAdjectivesTable = mw.loadData( 'Module:CountryAdjectiveDemonym/Adjectives' )
	countryNounsToDemonymsTable = mw.loadData( 'Module:CountryAdjectiveDemonym/Demonyms' )
	local myNoun, myAdjective
	
	-- first, load the adjectives table
	for myNoun, myAdjective in pairs(countryNounsToAdjectivesTable) do
		countryAdjectivesToNounsTable[myAdjective] = myNoun
	end

	-- Now load the denomyms table
	local myDemonym
	for myNoun, myDemonym in pairs(countryNounsToDemonymsTable) do
		countryDemonymsToNounsTable[myDemonym] = myNoun
	end
	CountryAdjectiveDemonymDataLoaded = true
	return
end


-- ############### Publicly accesible functions #######################

-- if the country name is prefixed by "the" in running text,
-- then return that prefix
-- Otherwise just return an empty string
function CountryAdjectiveDemonym.countryPrefixThe(frame)
	local s = frame.args[1]
	if not CountryAdjectiveDemonymDataLoaded then
		CountryAdjectiveDemonymDoLoadData()
	end
	if (countriesPrefixedByTheTable[s] == true) then
		return "the "
	end
	return ""
end


function CountryAdjectiveDemonym.getCountryFromAdjective(frame)
	local s = frame.args[1]
	if not CountryAdjectiveDemonymDataLoaded then
		CountryAdjectiveDemonymDoLoadData()
	end
	local retval = countryAdjectivesToNounsTable[s]
	if retval == nil then
		return ""
	end
	return retval
end


function CountryAdjectiveDemonym.getCountryFromDemonym(frame)
	local s = frame.args[1]
	if not CountryAdjectiveDemonymDataLoaded then
		CountryAdjectiveDemonymDoLoadData()
	end
	local retval = countryDemonymsToNounsTable[s]
	if retval == nil then 
		retval = countryAdjectivesToNounsTable[s]
	end
	if retval == nil then
		return ""
	end
	return retval
end


function CountryAdjectiveDemonym.getAdjectiveFromCountry(frame)
	local s = frame.args[1]
	if not CountryAdjectiveDemonymDataLoaded then
		CountryAdjectiveDemonymDoLoadData()
	end
	local retval = countryNounsToAdjectivesTable[s]
	if retval == nil then
		return ""
	end
	return retval
end


function CountryAdjectiveDemonym.getDemonymFromCountry(frame)
	local s = frame.args[1]
	if not CountryAdjectiveDemonymDataLoaded then
		CountryAdjectiveDemonymDoLoadData()
	end
	local retval
	retval = countryNounsToDemonymsTable[s]
	if retval == nil then
		retval = countryNounsToAdjectivesTable[s]
	end
	if retval == nil then
		return ""
	end
	return retval
end


function CountryAdjectiveDemonym.stripThe(frame)
	local s = frame.args[1]
	if s == nil then
		return ""
	end
	if mw.ustring.match( s, "^[T]he Gambia$") ~= nil then
		return s
	end
	local stripped = mw.ustring.gsub(s, "^[tT]he ", "")
	return stripped
end


return CountryAdjectiveDemonym