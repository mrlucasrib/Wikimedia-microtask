require('Module:No globals')

local p = {}
local data = {}         
local templateArgs = {}  -- contains arguments passed to cite web
local target = {}        -- short cut to target table, e.g. fishbase, cof, etc

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
-- define citation template and custom parameters for various sources

--####################### Default functions ##########################
data.default = {}
-- currently being tested on Avibase, but Fossilworks, Tropicos, FNA and a few others are candidates
data.default.id = function (id, source)
	local title = id
	local url = source.customArgs['baseURL'] .. source.customArgs['searchStr'] .. id
	return title, url
end
data.default.error = function()
	return "Minimal requirement is two of id, url and title parameters"
end
data.default.search = function (search, source)
	local title = "Search for " .. search
	local url = source.customArgs['baseURL'] .. source.customArgs['searchString'] .. search .. source.customArgs['searchSuffix'] 
	return title, url
end

--[[ handling for ID only (unused, original concept) 
p.genericIdCitation = function(frame, title, url)

    if not templateArgs['id'] then return "no id parameter detected" end
 
    templateArgs['url']= target.CustomArgs['baseURL'] .. target.CustomArgs['searchStr'] .. templateArgs['id']
    
    return p.citeWeb(frame, title, url)
end]]
--####################### FISH #####################################
--======================== Fishbase =================================
data.fishbase = {
	citationArgs = {
	['editor1-last']="Froese",  ['editor1-first']="Rainer", ['editor1-link']="Rainer Froese",
	['editor2-last']="Pauly",  ['editor2-first']="Daniel",   
	--['last-author-amp'] ="yes",
    ['website'] = "[[Fishbase]]",
	--['publisher'] = ""
	},
	customArgs = { exclude= "order, family,genus, species, subspecies, 1, 2, 3, 4",
	               baseURL = "http://www.fishbase.org/",
	               defaultTitle = "Search FishBase"
	},
}
data.fishbase.species = function(genus, species, subspecies)

		local title = genus .. " " .. species
		local url = data.fishbase.customArgs['baseURL'] 
		            .. "summary/SpeciesSummary.php?genusname=" .. genus .. "&speciesname=" .. species
		if subspecies then 
			url = url .. "+" .. subspecies
			title = title .. " " .. subspecies
		end               
		title =  "''" .. title  .. "''"
		return title, url
end
data.fishbase.genus = function(genus)
		local title = "Species in genus ''" .. firstToUpper(genus) .. "''"
		local url = data.fishbase.customArgs['baseURL'] ..  "identification/SpeciesList.php?genus=" .. genus   
		return title, url
end
data.fishbase.order = function(order) 
		local title =  "Order " .. firstToUpper(order)
		local url = data.fishbase.customArgs['baseURL'] ..  "Summary/OrdersSummary.php?order=" .. order
		return title, url
end
data.fishbase.family = function(family) 
		local title = "Family " .. firstToUpper(family)
		local url = data.fishbase.customArgs['baseURL'] ..  "Summary/FamilySummary.php?family=" .. family
		return title, url
end
data.fishbase.error = function()   
	return "No recognised taxon options: order, family, genus, species, subspecies."
end
data.fishbase.custom = function()    
    --TODO decide what to do with default date
    local version = "April 2006 version"  -- Should we have a default (probably not)
    if templateArgs['month'] then version = templateArgs['month'] end
    if templateArgs['year'] then version = templateArgs['year'] .. " version" end
    if templateArgs['month'] then version = templateArgs['month'] .. " " .. version end
    templateArgs['version'] = version
end
--================================ Catalog of Fishes ================================================
data.cof = {
	citationArgs = {
		--baseURL = "http://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?",
		['editor1-last']="Eschmeyer",  ['editor1-first']="William N.", ['editor1-link']="William N. Eschmeyer",
		['editor2-last']="Fricke",  ['editor2-first']="Ron",   
		['editor3-last']="van der Laan",  ['editor3-first']="Richard", 
		['name-list-style'] ="amp",
	    ['website'] = "[[Catalog of Fishes]]",
		['publisher'] = "[[California Academy of Sciences]]"
	},
	customArgs = { exclude= "family,genus,species,genid,spid,id,list,1,2,3",
	               baseURL = "http://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?",
	               defaultTitle = "CAS - Eschmeyer's Catalog of Fishes"
	}
}
data.cof.species = function(genus, species, subspecies)
		local taxon = genus .. " " .. species
	    local url = data.cof.customArgs['baseURL'] ..  'tbl=species&genus=' .. genus .. '&species=' .. species
	    local title = "Species related to " .. "''" .. firstToUpper(taxon) .. "''"        -- .. "" species synonyms"
	    return title, url
end
data.cof.genus  = function(genus)
	    local url = data.cof.customArgs['baseURL'] .. 'tbl=species&genus=' .. genus
	    local title = 'Species in the genus ' .. firstToUpper(genus) 
	    return title, url
end
       -- note the family works with subfamilies using &family=SUBFAMILY
data.cof.family  = function(family)
	    local list = templateArgs['list'] or "genus"
	    local url = data.cof.customArgs['baseURL'] .. 'tbl=' .. list .. '&family=' .. family
        local title = "Species"
        if list == "genus" then  title = "Genera" end 
        title = title .. ' in the family ' .. firstToUpper(family)  
        return title, url
end
data.cof.genid = function(genid)
   	    local searchStr =  "genid" .. '=' .. genid
        local title =  searchStr
        local url = data.cof.customArgs['baseURL'] .. searchStr
        return title, url
end
data.cof.spid = function(spid)
   	    local searchStr =  "spid" .. '=' .. spid
        local title =  searchStr
        local url = data.cof.customArgs['baseURL'] .. searchStr
        return title, url
end
data.cof.error = function()
    	return "Error. No recognised option set by template (need one of family, genus, species (also requires genus), spid, or genid"
end
--======================Fishes of the World 5===============================	
data.fotw5 = {
	citeTemplate = "Cite book",
	citationArgs = {
	    --['website'] = "[[]]",
		first1 = "Joseph S.", last1 = "Nelson",
		first2="Terry C.", last2="Grande",
		first3="Mark V. H.", last3="Wilson", 
		--work = "Fishes of the World (work)",
		title = "Fishes of the World", edition="5th", year = 2016,
		publisher ="John Wiley and Sons", location="Hoboken",
		isbn = "978-1-118-34233-6", doi="10.1002/9781119174844" ,
	},
	customArgs = {exclude="gb-page,q,dq,1",
	              baseURL = "https://onlinelibrary.wiley.com/doi/book/10.1002/9781119174844", -- online library
	              defaultTitle = "Fishes of the World",
	              altTitle = "[[Fishes of the World]]",               -- wikilinked for when using chapter/section title
	              altURL = "https://sites.google.com/site/fotw5th/",  -- classification
	},
	GoogleBooks = { baseURL = "https://books.google.co.uk/books?id=",
		            id = "E-MLDAAAQBAJ",
		            defaultPage = "&pg=PP1"
	}
}
data.fotw5.default2 = function(targs)
     local title = data.fotw5.citationArgs['work']
     local url = data.fotw5.customArgs['baseURL']
     local chapterParams =  { title      = title,
     	                    ['chapter-url']= data.fotw5.customArgs['googleBooks']
     }
     --return title, url, chapterParams
end


data.BentonVP4 = {
	citeTemplate = "Cite book",
	citationArgs = {
		first1 = "Michael J.", last1 = "Benton",
		title = "Vertebrate Palaeontology", edition="4th", year = 2014,
		publisher ="John Wiley & Sons", 
		isbn = "978-1-118-40764-6", 
	},
	customArgs = {exclude="gb-page,q,dq,1",
	              --baseURL = "",
	              defaultTitle = "Vertebrate Palaeontology",
	              altTitle = "[[Vertebrate Palaeontology]]"  -- wikilinked for when using chapter/section title
	},
	GoogleBooks = { baseURL = "https://books.google.co.uk/books?id=",
		            id = "qak-BAAAQBAJ",
		            defaultPage = "&pg=PP1",
	}
}


--====================TODO FishWisePro==================================================	
data.fishwisepro = {
	citationArgs = {
	    ['website'] = "[[FishWisePro]]",

	},
	customArgs = {exclude="family,genus,species,1",
	              baseURL = ""
	}
}

-- #################### AMPHIBIA and REPTILES ###############################
-- ================= Amphibian Species of the World (ASW6)
--[[Recommended citation: Frost, Darrel R. 2019. Amphibian Species of the World: an Online Reference. Version 6.0 (Date of access). Electronic Database accessible at http://research.amnh.org/herpetology/amphibia/index.html. American Museum of Natural History, New York, USA.
    URL for family page: http://research.amnh.org/vz/herpetology/amphibia/Amphibia/Anura/Allophrynidae
           baseURL      = http://research.amnh.org/vz/herpetology/amphibia/
           suffix       = Amphibia/Anura/Allophrynidae
           note: needs the whole hierarchy (except the superfamily which is optional)
    Template for main taxonomic listing: {{BioRef|ASW6 |title=Amphibia |year=2019 |url=http://research.amnh.org/herpetology/amphibia/index.html |access-date=27 September 2019}}
    SEARCH http://research.amnh.org/vz/herpetology/amphibia/amphib/basic_search?basic_query=Atelopus&stree=&stree_id=
           searchSuffix = amphib/basic_search?basic_query=Atelopus&stree=&stree_id=
    SEARCH http://research.amnh.org/vz/herpetology/amphibia/content/search?taxon=Allophryn*&subtree=&subtree_id=&english_name=&author=&year=&country=
           searchSuffix = /content/search?taxon=Allophryn*&subtree=&subtree_id=&english_name=&author=&year=&country=
           minimul      = /content/search?taxon=Allophryn*&subtree
    ]]
data.ASW6 ={
	citationArgs = {
		website  ="Amphibian Species of the World, an Online Reference.",
		version  = "Version 6.0",
		publisher = "American Museum of Natural History, New York",
		['last1']="Frost",  ['first1']="Darrel R.", ['author1-link']="Darrel R. Frost",
	},
	customArgs = { exclude = "taxon,species,genus,family, superfamily,1,2,3",
	               baseURL = "http://research.amnh.org/herpetology/amphibia/",
	               defaultSuffix = "index.html",
	               defaultTitle = "ASW Home"  
	}
}

data.ASW6.species = function(genus, species, subspecies)

		-- search for genus+species  ()
	    local title = "Search for taxon: " .. "''" .. genus .. " " .. species .. "''"
	
		 	--local search = ""?action=names&taxon="" -- old version (pre ASW6)
		 	--local search =  "amphib/basic_search?basic_query="  -- basic search
	 	local search = "content/search?taxon="              -- guided search for taxon name
		 	
		local url = data.ASW6.customArgs['baseURL'] .. search  -- .. genus .. '+AND+' .. species
		 	            .. '&quot;' .. genus .. '+' .. species .. '&quot;'
		return title, url
end
data.ASW6.genus = function(genus)
	return data.ASW6.taxon(genus)  -- use genus as alias of taxon
end
data.ASW6.taxon = function(taxon)		
	    local title = "Search for Taxon: " .. taxon
	    local url= data.ASW6.customArgs['baseURL'] .. "content/search?taxon=" .. taxon
	    return title, url
end
data.ASW6.family = function(family) 
		local order = data.ASW6.checkOrder(family)
		local url= data.ASW6.customArgs['baseURL'] .. "Amphibia/" .. order .. "/" .. firstToUpper(family)
		local title = firstToUpper(family) 
		return title, url
end
data.ASW6.checkOrder = function(family)

	local gymnophiona={ "Caeciliidae", "Chikilidae", "Dermophiidae", "Herpelidae", "Ichthyophiidae", "Indotyphlidae", "Rhinatrematidae", "Scolecomorphidae", "Siphonopidae", "Typhlonectidae" }
    local caudata = { "Ambystomatidae", "Amphiumidae", "Cryptobranchidae", "Hynobiidae", "Plethodontidae", "Proteidae", "Rhyacotritonidae", "Salamandridae", "Sirenidae" }
   
    for k,v in pairs(caudata) do
    	if v == family then return "Caudata" end
    end
    for k,v in pairs(gymnophiona) do
    	if v == family then return "Gymnophiona" end
    end
    
    return "Anura"
end   

--============================= AmphibiaWeb ===================================
--[[   Citation: AmphibiaWeb. 2019. <https://amphibiaweb.org> University of California, Berkeley, CA, USA. Accessed 27 Sep 2019.
       Code:     {{BioRef|amphibiaweb |title=Amphibia |year=2019 |url=https://amphibiaweb.org/taxonomy/AW_FamilyPhylogeny.html |access-date=27 September 2019}}
--]]
data.amphibiaweb = {
	citationArgs = {
		website  = "AmphibiaWeb",
		publisher = "University of California, Berkeley",
		--['editor1-last']="",  ['editor1-first']="", ['editor1-link']="",
	},
    customArgs = { exclude = "taxon,species,genus,family,1,2,3",
	               baseURL = "https://amphibiaweb.org/",
	               defaultSuffix = "taxonomy/AW_FamilyPhylogeny.html",
	               defaultTitle = "AmphibiaWeb Family Taxonomy"
	}
}
data.amphibiaweb.species = function (genus, species, subspecies)
		local title = "''" .. genus .. " " .. species .. "''"
		 	--https://amphibiaweb.org/cgi/amphib_query?where-genus=Altiphrynoides&where-species=malcolmi
		local url = data.amphibiaweb.customArgs['baseURL'] .. "cgi/amphib_query?rel-genus=equals&where-genus="
		 	                   .. genus .. "&rel-species=equals&where-species=" .. species
		return title, url
end
data.amphibiaweb.genus = function (genus)
		local title = "''" .. genus ..  "''"
		 	--https://amphibiaweb.org/cgi/amphib_query?where-genus=Altiphrynoides&where-species=malcolmi
		local url = data.amphibiaweb.customArgs['baseURL'] .. "cgi/amphib_query?rel-genus=equals&where-genus=" 
		 	                .. genus .. "&include_synonymies=Yes&show_photos=Yes"
		return title, url
end	
data.amphibiaweb.family = function (family)		-- if family use standardised url
		 local url = data.amphibiaweb.customArgs['baseURL'] .. "lists/" .. firstToUpper(templateArgs['family']) .. ".shtml"
		 local title = templateArgs['family']
		 return title, url
end
	


--=========================== The Reptile Database
data.reptileDB = {
	-- http://reptile-database.reptarium.cz/species?genus=Epacrophis&species=boulengeri
	-- recommended citation: Uetz, P., Freed, P. & Hošek, J. (eds.) (2019) The Reptile Database, http://www.reptile-database.org, accessed [insert date here]
	citationArgs = {
		--website="reptile-database.org",
		website="[[The Reptile Database]]",
		['editor1-last']="Uetz",  ['editor1-first']="P.", --['editor1-link']="Peter Uetz",
		['editor2-last']="Freed",  ['editor2-first']="P.", 
		['editor3-last']="Hošek",  ['editor3-first']="J.", 
		--year=2019
		
	},
	customArgs = { exclude = "taxon,species,genus,family,1,2,3",
	               baseURL = "http://reptile-database.reptarium.cz/"
	}
}

data.reptileDB.species = function(genus, species)
	    local title = "''" .. genus .. " " .. species .. "''"
	    --http://reptile-database.reptarium.cz/species?genus=Loxocemus&species=bicolor
		local url = data.reptileDB.customArgs['baseURL'] .. "species?genus=" .. genus .. "&species=" .. species
		return  title, url
end
data.reptileDB.genus = function(genus)
	    local title = "''" .. genus .. "''" 
	    --http://reptile-database.reptarium.cz/advanced_search?genus=Malayopython&submit=Search
	    local url = data.reptileDB.customArgs['baseURL'] .. "advanced_search?genus=" .. genus .. "&exact%5B0%5D=taxon&submit=search"
		return  title, url
end
data.reptileDB.taxon = function(taxon)
	    local title = templateArgs['taxon'] 
		--http://reptile-database.reptarium.cz/advanced_search?taxon=Viperidae&exact%5B0%5D=taxon&submit=Search
		local url = data.reptileDB.customArgs['baseURL'] .. "advanced_search?taxon=" .. templateArgs['taxon'] .. "&exact%5B0%5D=taxon&submit=search"
		return  title, url
end
	

   

--################################### BIRDS ########################################
--====================Handbook of the Birds of the World Alive (HBW Alive)==============
data.HBWalive = {         
	citationArgs = {
		website="[[Handbook of the Birds of the World|Handbook of the Birds of the World Alive]]", 
		publisher="Lynx Edicions"
	},
	customArgs = { exclude="order,family,genus,species,taxon,id,1",
	               baseURL = "https://www.hbw.com/",
	               defaultSuffix = "family/home",
	               defaultTitle = "Family | HBW Alive"
	               
	}
}
--############################## HBW ALIVE #########################################
   -- family and species entries have mix of common name and taxon name so cannot be prempted; 
   -- must use title + url (which uses default functions in this module)
data.HBWalive.order = function(order)
    	local title = "Order " .. firstToUpper(order)
    	--https://www.hbw.com/order/struthioniformes
    	local url = target.customArgs['baseURL'] .. "order/" .. order
    	return title, url
end
 

--[[======================IOC World Bird List==========================
	        Gill, F & D Donsker (Eds). 2019. IOC World Bird List (v9.2). doi :  10.14344/IOC.ML.9.2.
	        Gill F, D Donsker & P Rasmussen  (Eds). 2020. IOC World Bird List (v10.2). doi :  10.14344/IOC.ML.10.1.
]]
data.IOC = {         
	citationArgs = {
		website="[[IOC World Bird List]]", 
	--	version="Version 9.2",                               -- shouldn't default; should be hardcode so it doesn't change
		['editor1-last']="Gill",  ['editor1-first']="F.",  ['editor1-link']="Frank Gill (ornithologist)",
		['editor2-last']="Donsker",  ['editor2-first']="D.",
		['editor3-last']="Rasmussen",  ['editor3-first']="P.",  -- TODO only show from version 10.1 onwards
	--	doi = "10.14344/IOC.ML.9.2",                          -- this changes by version number and is not a useful part of the cictation
		publisher="International Ornithological Congress"
	},
	customArgs = { exclude="order,family,genus,species,taxon,id,1",
	               baseURL = "https://www.worldbirdnames.org/",
	               defaultSuffix = "",
	               defaultTitle = "IOC World Bird List: Welcome"
	               
	},
}
data.IOC.version = function()
	local version =  templateArgs['version'] 
	local old = false
	if version then
		version = string.gsub( version, "[Vv]ersion ", "")
     	local versionNumber = tonumber(version)
    	if versionNumber < 10.1 then
	    	old = true
		end
	else
		local Date = require('Module:Date')._Date
		if Date(templateArgs['access-date']) < Date('1 January 2020') then
			old = true
		end
	end
	
	if old then
	    	data.IOC.citationArgs['editor3-last'] = nil
		    data.IOC.citationArgs['editor3-first'] = nil
	end
end
data.IOC.order = function(order) 
	    data.IOC.version()
        local IOCorders = {Struthioniformes='ratites',Rheiformes='ratites',Apterygiformes='ratites',Casuariiformes='ratites',Tinamiformes='ratites',Galliformes='megapodes',Anseriformes='waterfowl',Caprimulgiformes='nightjars',Apodiformes='swifts',Musophagiformes='turacos',Otidiformes='turacos',Cuculiformes='turacos',Mesitornithiformes='turacos',Pterocliformes='turacos',Columbiformes='pigeons',Gruiformes='flufftails',Podicipediformes='grebes',Phoenicopteriformes='grebes',Charadriiformes='sandpipers',Eurypygiformes='loons',Phaethontiformes='loons',Gaviiformes='loons',Sphenisciformes='loons',Procellariiformes='loons',Ciconiiformes='storks',Suliformes='storks',Pelecaniformes='pelicans',Opisthocomiformes='raptors',Accipitriformes='raptors',Strigiformes='owls',Coliiformes='mousebirds',Leptosomiformes='mousebirds',Trogoniformes='mousebirds',Bucerotiformes='mousebirds',Coraciiformes='rollers',Piciformes='woodpeckers',Cariamiformes='falcons',Falconiformes='falcons',Psittaciformes='parrots',
	               Passeriformes='nz_wrens'} -- passeriformes link not very useful

    	local title = "Order " .. firstToUpper(order)
    	local url = data.IOC.customArgs['baseURL'] .. "/bow/" .. IOCorders[order]
    	return title, url    	
end
data.IOC.family = function(family)
	    data.IOC.version()
    	local title = "Family " .. firstToUpper(family)
    	--https://www.worldbirdnames.org/Family/Struthionidae
    	local url = data.IOC.customArgs['baseURL'] .. "Family/" .. family
    	return title, url
end    
data.IOC.default = function( title, url) 
	    data.IOC.version()
	    return title, url
end

data.BOW = {         
	citationArgs = {
		website="Birds of the World Online", 
	--	doi = "",                          
	--	['last1']="Winkler",  ['first1']="David W.",              -- are these always the authors in version 1? no, perhaps for family page
	--	['last2']="Billerman",  ['first2']="Shawn M.",
	--	['last3']="Lovette",  ['first3']="Irby J.",  
	--	['editor1-last']="Billerman",  ['editor1-first']="S. M.",  --['editor1-link']="",
	--	['editor2-last']="Keeney",  ['editor2-first']="B. K.",
	--	['editor3-last']="Rodewald",  ['editor3-first']="P. G.",  
	--    ['editor4-last']="Schulenberg",  ['editor4-first']="T. S.",
	--    ['version'] = 1,   ['year'] = 2020,                                             -- may not want to default
		publisher="[[Cornell Lab of Ornithology]], Ithaca, NY."
	},
	customArgs = { exclude="citation,make,order,family,genus,species,taxon,id,1",
	               baseURL = "https://birdsoftheworld.org/bow/species",
	               defaultSuffix = "",
	               defaultTitle = "Explore Taxonomy"
	               
	},
}

data.BOW.default =  function( title, url)  
	 --data.BOW.citationArgs['version'] = "Version 1"
	 return title, url
end

--[[ make BOW to parse standard citation, {{BioRef|BOW|citation=CITATION}}
    vesrion 1 (family): Winkler, D. W., S. M. Billerman, and I.J. Lovette (2020). Bulbuls (Pycnonotidae), version 1.0. In Birds of the World 
                        (S. M. Billerman, B. K. Keeney, P. G. Rodewald, and T. S. Schulenberg, Editors). Cornell Lab of Ornithology, Ithaca, NY, USA. 
                        https://doi.org/10.2173/bow.pycnon4.01
    version 2 (species): Limparungpatthanakij , W. L., L. Fishpool, and J. Tobias (2020). Buff-vented Bulbul (Iole crypta), version 2.0. In Birds of the World 
                        (S. M. Billerman and B. K. Keeney, Editors). Cornell Lab of Ornithology, Ithaca, NY, USA. 
                        https://doi.org/10.2173/bow.buvbul1.02
]]
data.BOW.citation =  function( value)  
	local citation  = templateArgs['citation'] 

    data.BOW.citationArgs['year']  = citation:match ('^%D+(%d%d%d%d)')
    data.BOW.citationArgs['doi']  = citation:match ('10%.2173/bow%..+')                           -- https://doi.org/10.2173/bow.pycnon4.01
    --data.BOW.citationArgs['version']  = citation:match ('version %d%.%d')                       -- version applies to page, not whole BOW
    local title = citation:match ('%d%d%d%d%)%.(.*, version %d%.%d)');                            -- include version number in title
    local suffix = citation:match ('10%.2173/bow%.(.+%d)%.');                                     -- https://doi.org/10.2173/bow.pycnon4.01
    local version = "/cur/"                                                                       -- for the current version
    version = citation:match ('version (%d%.%d)')                                                 -- for the cited version
    local url = data.BOW.customArgs['baseURL'] .. '/' .. suffix .. '/'  .. version .. '/' 
    
    title = title:gsub( '%((%D+) (%D+)%)' , "(''%1 %2'')")
    
    local authors = citation:match ('^(%D+) %(%d%d%d%d%)')
    --data.BOW.citationArgs['authors'] = citation:match ('^(%D+)%(%d%d%d%d%)')
    --data.BOW.citationArgs['editors'] = citation:match ('In Birds of the World %((.-)Editors%)' ) -- omit editors as cite web psoitioning is weird
    if authors then           -- split authors with modified code from make cite iucn
    	local list = {}
    	authors = authors:gsub(", and ", ", ")
    	--local names = author_names:gsub ('%.?,?%s+&%s+', '.|'):gsub ('%.,%s+', '.|');	-- replace 'separators' (<dot><comma><space> and <opt. dot><opt. comma><space><ampersand><space>) with <dot><pipe>
    	local names = authors:gsub (',%s+', '|');       -- replace any comma
    	                 --    :gsub ('%.?,?%s+and%s+', '|') -- replace 'separators' <opt. dot><opt. comma><space>and<space>) with <dot><pipe>
    	                 --    :gsub ('%.,%s+', '.|');       -- replace 'separators' <dot><comma><space> with <dot><pipe>
      	list = mw.text.split (names, '|');											-- split the string on the pipes into entries in list
		if #list == 0 then
			data.BOW.citationArgs['authors'] = authors 					        	-- no 'names' of the proper form; return the original as a single |author= parameter
		else
			for i, name in ipairs (list) do											-- for each author in list 
		      	data.BOW.citationArgs['author'..i-1] = name 					    -- add |authorn= parameter names
				--	list[i] = table.concat ({'|author', (i == 1) and '' or i, '=', name});	-- add |authorn= parameter names; create |author= instead of |author1=
			end
			data.BOW.citationArgs['author1'] = data.BOW.citationArgs['author0'] .. ', ' .. data.BOW.citationArgs['author1']
		end   
    
    end

	 --if not url then url = data.BOW.customArgs['baseURL']  end
	 --if not title then title = "Title parameter required" end
	 
	 return title, url
end

-- basic handling for Taxonomy in Flux website
data.tif = {         
	citationArgs = {
		website="Taxonomy in Flux", 
		['editor1-last']="Boyd III",  ['editor1-first']="John H.",    --['editor1-link']="",
	},
	customArgs = { exclude="order,family,genus,species,taxon,id,1",
	               baseURL = "http://jboyd.net/Taxo/",
	               defaultSuffix = "List.html",
	               defaultTitle = "Taxonomy in Flux"
	               
	},
}
--[[ ------------- Avibase
                   e.g. https://avibase.bsc-eoc.org/species.jsp?avibaseid=9144EF4017F2D8B1
]]
data.avibase = {
		citationArgs = {
		website="Avibase", 
		['editor1-last']="Lepage",  ['editor1-first']="Denis",    --['editor1-link']="",
	},
	customArgs = { exclude="order,family,genus,species,taxon,id,1",
	               baseURL = "https://avibase.bsc-eoc.org/",
	               searchStr = "species.jsp?avibaseid=",
	               defaultTitle = "Avibase - The World Bird Database"
	}
}
--[[ use default function
data.avibase.id = function (id)
    
    local title = "Avibase id: " .. id
	local url = data.avibase.customArgs['baseURL'] .. data.avibase.customArgs['searchStr'] .. id
	return title, url
end
--]]

-- ============================= IUCN =================================================
-- for species in taxon; for species assessments, us {{cite iucn}}
-- https://www.iucnredlist.org/search?query=Murexia&searchType=species 
-- https://www.iucnredlist.org/search?query=aonyx&searchType=species
data.iucn = {
	citationArgs = {
		website="[[IUCN Red List of Threatened Species]]", 
		--publisher="[[IUCN]]"
	},
	customArgs = { exclude="family,genus,species,taxon,id,1",
	               baseURL = "https://www.iucnredlist.org",
	               searchString = "/search?query=",
	               searchSuffix = "&searchType=species",
	               defaultSuffix = "",
	               defaultTitle="IUCN Red List of Threatened Species"
	}	
}
data.iucn.genus  = function(genus)  return data.iucn.taxon(genus, "TITLE_ITALICS") end
data.iucn.family = function(family) return data.iucn.taxon(family) end
data.iucn.order  = function(order)  return data.iucn.taxon(order) end
data.iucn.taxon  = function(taxon, titleItalics)
    local title = firstToUpper(taxon)
    if titleItalics then title = "''" .. title .. "''" end
    local url = data.iucn.customArgs['baseURL'] .. data.iucn.customArgs['searchString'] .. taxon .. data.iucn.customArgs['searchSuffix']
    return title, url
end   

-- ============================= ASM Mammal Diversity Database ========================
data.asm = {
	citationArgs = {
		website="ASM Mammal Diversity Database", 
		publisher="[[American Society of Mammalogists]]"
	},
	customArgs = { exclude="family,genus,species,taxon,id,1,2,3",
	               baseURL = "https://mammaldiversity.org/",
	               defaultTitle="ASM Mammal Diversity Database"
	               
	}
}

data.asm.species = function(genus, species)
    local title = "''" .. genus .. " " .. species .. "''"
		--https://mammaldiversity.org/species-account.php?genus=ursus&species=arctos
	local url = data.asm.customArgs['baseURL'] .. "species-account.php?genus=" .. genus .. "&species=" .. species
	return title, url
end	    
data.asm.id = function(id)
    	local url = data.asm.customArgs['baseURL'] .. "species-account/species-id=" .. templateArgs['id']
    	local title = "Species-id=" .. id
    	return title, url
end
data.asm.genus  = function(genus)  return data.asm.taxon(genus, "TITLE_ITALICS") end
data.asm.family = function(family) return data.asm.taxon(family) end
data.asm.order  = function(order)  return data.asm.taxon(order) end
data.asm.taxon  = function(taxon, titleItalics)
    	--https://mammaldiversity.org/#ZmVsaWRhZSZnbG9iYWxfc2VhcmNoPXRydWUmbG9vc2U9dHJ1ZQ
    	--                             Base64.encode(felidae&global_search=true&loose=true)
    local title = firstToUpper(taxon)
    if titleItalics then title = "''" .. title .. "''" end
    local url = data.asm.customArgs['baseURL'] 
              .. '#' .. data.asm.Base64.encode(taxon.."&global_search=true&loose=false")
    return title, url
end   
--############################## Base64 encode and decode (used for ASM#####################
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
-- encoding
data.asm.Base64 = {}
data.asm.Base64.encode = function(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
-- decoding
data.asm.Base64.decode=function(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end
--######################## Misc ##################################
--[[ 3 approaches to handling DB: 
                 1) use DB as website and use via to append WoRMS
                 2) use DB as website and use postscript to append WoRMS
                 3) use WoRMSa as website and designate DB as author (recommended by WoRMS) CURRENT
]]
data.WoRMS = {
	citationArgs = {
	    author = "WoRMS",
	    website = "[[World Register of Marine Species]]",
	    --['via'] = "[[World Register of Marine Species]]",
	    --postscript = '&#32;from the [[World Register of Marine Species]].'

	},
	customArgs = {exclude="id,db,1",
	              baseURL = "http://www.marinespecies.org/aphia.php?",
	              searchStr = "p=taxdetails&id=",
	              defaultTitle="World Register of Marine Species"
	}
}
data.WoRMS.id = function(id)
    --[[ Two styles
         1. http://www.marinespecies.org/aphia.php?p=taxdetails&id=14712
            >  WoRMS (2018). Heterobranchia. Accessed at: http://marinespecies.org/aphia.php?p=taxdetails&id=14712 on 2018-11-28 
         2. http://www.marinespecies.org/aphia.php?p=taxdetails&id=1057249
            > MolluscaBase (2018). Ringipleura. Accessed through: World Register of Marine Species at: http://www.marinespecies.org/aphia.php?p=taxdetails&id=1057249 on 2018-11-28 
    ]]
    if not templateArgs['id'] then return "no id parameter detected" end
    local searchStr = "p=taxdetails&id=" .. templateArgs['id']
    
    if templateArgs['db'] then -- if database hosted by WoRMS
    	templateArgs['author'] = templateArgs['db']  -- this is recommended by WoRMS
    	--templateArgs['website'] = templateArgs['db']  -- alternative (and use |postscript)
    	--templateArgs['publisher'] = templateArgs['via']
    --[[else -- WoRMS is primary source
    	 templateArgs['via'] = nil
    	 templateArgs['postscript'] = nil]]
    end
    --page <title>WoRMS - World Register of Marine Species - Heterobranchia</title>
    local title = "WoRMS taxon details: AphiaID " .. id
    local url = data.WoRMS.customArgs['baseURL'] .. data.WoRMS.customArgs['searchStr'] .. id
    return title, url    

end
   	
--======================  Fossilworks =======================================

data.fossilworks = {
	citationArgs = {
		website="[[Fossilworks]]",
		--publisher="Paleobiology Database",
		--postscript = 'none',
		postscript = "&#32;from the [[Paleobiology Database]].",
		--via="''fossilworks.org''"   -- an alternative format to using |website=
	},
	customArgs = { exclude = "id,date,1",
	               baseURL = "http://fossilworks.org/cgi-bin/",
	               searchStr ="bridge.pl?a=taxonInfo&taxon_no=",
	               defaultTitle = "Fossilworks: Gateway to the Paleobiology Database"
	}
	--id = function(id) return p.genericIdCitation (frame, title, url)
}
data.fossilworks.id = function(id)
--[[ http://fossilworks.org/cgi-bin/bridge.pl?a=taxonInfo&taxon_no=83087	
    if not templateArgs['id'] then return "no id parameter detected" end
    local searchStr = "bridge.pl?a=taxonInfo&taxon_no=" .. templateArgs['id']
    templateArgs['url']= target.CustomArgs['baseURL'] .. searchStr
    ]]
    local title = "PaleoDB taxon number: " .. id
    local url = data.fossilworks.customArgs['baseURL'] .. data.fossilworks.customArgs['searchStr'] .. id
    return title, url  
end
data.fossilworks.error = function()
	return "Requires id and title parameters"
end
--======================================= PLANTS =========================
--[[ Hassler, Michael (2004 - 2020): World Plants. Synonymic Checklist and Distribution of the World Flora. 
       Version x.xx; last update xx.xx.xxxx. - www.worldplants.de. Last accessed dd/mm/yyyy.
       https://www.worldplants.de/world-plants-complete-list/complete-plant-list#1599996425
     Hassler, Michael (2004 - 2020): World Ferns. Synonymic Checklist and Distribution of Ferns and Lycophytes of the World. 
       Version x.xx; last update xx.xx.xxxx. - www.worldplants.de/ferns/. Last accessed dd/mm/yyyy.
       https://www.worldplants.de/world-ferns/ferns-and-lycophytes-list#1599997555
--]]
data.worldplants = {
	citationArgs = {
		last1 = "Hassler", first1 = "Michael",
		website="World Plants. Synonymic Checklist and Distribution of the World Flora.",
		--publisher=""
	},
	customArgs = { exclude = "id,authority,family,genus,species,1",
	               baseURL = "https://www.worldplants.de/",
	               searchStr ="world-plants-complete-list/complete-plant-list#",
	               defaultSuffix = "",
	               defaultTitle = "World Plants"
	}
}
data.worldferns = {
	citationArgs = {
		last1 = "Hassler", first1 = "Michael",
		website="World Ferns. Synonymic Checklist and Distribution of the World Flora.",
		--publisher=""
	},
	customArgs = { exclude = "id,authority,family,genus,species,1",
	               baseURL = "https://www.worldplants.de/",
	               searchStr ="world-ferns/ferns-and-lycophytes-list#",
	               defaultSuffix = "",
	               defaultTitle = "World Ferns"
	}
}


--[[Plants of the World online
	   http://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:30003057-2  -- use id
	   http://powo.science.kew.org/?q=Selaginellaceae                        -- use search
	   http://powo.science.kew.org/?family=Selaginellaceae                   -- can also use family= [gets same result as q=]
	   http://powo.science.kew.org/?genus=Selago                             -- or genus
	   http://powo.science.kew.org/?genus=Selago&species=abietina            -- or genus + species
	   http://powo.science.kew.org/?genus=Selago&f=accepted_names            -- filter for accepted names
	   http://powo.science.kew.org/?genus=Selago&f=genus_f                   -- filter for genus (no species selected)
	   http://powo.science.kew.org/?genus=Selago&f=genus_f%2Caccepted_names  -- filter for genus and accepted names
	   http://powo.science.kew.org/?page.size=480&f=family_f%2Caccepted_names -- list of accepted families
	   -- all these searches get the search result (no apparent way to target the article when unique)
]]
data.POWO = {
	citationArgs = {
		website="[[Plants of the World Online]]",
		publisher="Royal Botanic Gardens, Kew",
		--postscript = 'none',
	},
	customArgs = { exclude = "id,authority,family,genus,species,1",
	               baseURL = "http://powo.science.kew.org/taxon/",
	               searchStr ="urn:lsid:ipni.org:names:",
	               defaultSuffix = "",
	               defaultTitle = "Plants of the World Online"
	}
	--id = function(id) return p.genericIdCitation (frame, title, url)
}
data.POWO.id = function(id)
--[[ http://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:30003057-2	
    ]]
    local title = string.gsub( id, "urn:lsid:ipni.org:names:", "") -- don't want this twice
    
    local url = data.POWO.customArgs['baseURL'] .. data.POWO.customArgs['searchStr'] .. id
    return title, url  
end
data.POWO.family = function(family)
	local title = family .. ' ' .. templateArgs['authority']
	local url = data.POWO.customArgs['baseURL'] .. data.POWO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.POWO.genus = function(genus)
	local title = "''" .. genus .. "'' " .. templateArgs['authority']
	local url = data.POWO.customArgs['baseURL'] .. data.POWO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.POWO.species = function(genus,species)
	local title = "''" .. genus .. " " .. species .. "'' " .. templateArgs['authority']
	local url = data.POWO.customArgs['baseURL'] .. data.POWO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.POWO.error = function()
	return "Requires id and title parameters"
end
--[[World Flora Online 
    	http://www.worldfloraonline.org/taxon/wfo-4000012284  -- id
]]

data.WFO = {
	citationArgs = {
		website="[[World Flora Online]]",
		--publisher="Missouri Botanical Gardens",
		--postscript = 'none',
	},
	customArgs = { exclude = "id,family,genus,species,authority,1",
	               baseURL = "http://www.worldfloraonline.org/taxon/",
	               searchStr ="wfo-",                                       -- not strictly search string
	               defaultSuffix = "",
	               defaultTitle = "World Flora Online"
	}

}
data.WFO.id = function(id)
--[[ http://www.worldfloraonline.org/taxon/wfo-4000012284	
    ]]
    local title = id
    local url = data.WFO.customArgs['baseURL'] .. data.WFO.customArgs['searchStr'] .. id
    return title, url  
end
data.WFO.family = function(family)
	local title = family .. ' ' .. templateArgs['authority']
	local url = data.WFO.customArgs['baseURL'] .. data.WFO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.WFO.genus = function(genus)
	local title = "''" .. genus .. "'' " .. templateArgs['authority']
	local url = data.WFO.customArgs['baseURL'] .. data.WFO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.WFO.species = function(genus,species)
	local title = "''" .. genus .. " " .. species .. "'' " .. templateArgs['authority']
	local url = data.WFO.customArgs['baseURL'] .. data.WFO.customArgs['searchStr'] .. templateArgs['id']
    return title, url  
end
data.WFO.error = function()
	return "Requires id and title parameters"
end

data.Tropicos = {
	citationArgs = {
		website="[[Tropicos]]",
		--publisher="Missouri Botanical Gardens",
		--postscript = 'none',
	},
	customArgs = { exclude = "id,1",
	               baseURL = "http://legacy.tropicos.org/Name/",
	               searchStr ="",
	               defaultSuffix = "",
	               defaultTitle = "Tropicos"
	}

}
data.Tropicos.id = function(id)
--[[ hhttp://legacy.tropicos.org/Name/100444532	
    ]]
    local title = id
    local url = data.Tropicos.customArgs['baseURL'] .. data.Tropicos.customArgs['searchStr'] .. id
    return title, url  
end
data.Tropicos.error = function()
	return "Requires id and title parameters"
end


data.FNA = {
	citationArgs = {
		            website="[[Flora of North America]]",
		            --publisher="http://www.efloras.org",
		            --postscript = 'none',
	},
	customArgs = { exclude = "id,1",
	               baseURL = "http://www.efloras.org/florataxon.aspx",
	               searchStr ="?flora_id=1&taxon_id=",
	               defaultSuffix = "",
	               defaultTitle = "Flora of North America"
	}
	--id = function(id) return p.genericIdCitation (frame, title, url)
}
data.FNA.id = function(id)
--[[ http://www.efloras.org/florataxon.aspx?flora_id=1&taxon_id=125683
    ]]
    local title = id
    local url = data.FNA.customArgs['baseURL'] .. data.FNA.customArgs['searchStr'] .. id
    return title, url  
end
data.FNA.error = function()
	return "Requires id and title parameters"
end

-- ============================= Mosses (Goffinet's site) =================================================-- for species in taxon; for species assessments, us {{cite iucn}}
-- https://bryology.uconn.edu/classification/#Hypnanae
-- https://bryology.uconn.edu/classification/#Bryales
data.goffinet = {
	citationArgs = {
		first1="B.", last1="Goffinet", 
		first2="W.R.", last2="Buck",
		website="Classification of extant moss genera"
		--publisher="[[xxx]]"
	},
	customArgs = { exclude="family,genus,species,taxon,id,1",
	               baseURL = "https://bryology.uconn.edu/classification/",
	               searchString = "#",
	               searchSuffix = "",
	               defaultSuffix = "",
	               defaultTitle="Classification of the Bryophyta"
	}	
}
data.goffinet.genus  = function(genus)  return data.goffinet.taxon(genus, "GENUS") end
data.goffinet.family = function(family) return data.goffinet.taxon(family, "FAMILY") end
data.goffinet.order  = function(order)  return data.goffinet.taxon(order, "ORDER") end
data.goffinet.taxon  = function(taxon, rank)
    local title = firstToUpper(taxon)
    if rank == "GENUS" then title = "''" .. title .. "''" end
    if not (rank == "GENUS" or rank == "FAMILY") then  -- upper case anchors for orders and above
    	if taxon ~= "Bryanae" and taxon ~= "Hypnanae" and taxon ~= "Bryales" and taxon ~= "Bryidae" then -- check for exceptions (inconsistencies at website)
    		taxon = taxon:upper()
    	end
    end
    local url = data.goffinet.customArgs['baseURL'] .. data.goffinet.customArgs['searchString'] .. taxon .. data.goffinet.customArgs['searchSuffix']
    return title, url
end 

--[[ AlgaeBase
    taxonomy browser url (Volvox) = https://www.algaebase.org/browse/taxonomy/?id=6898
    genus article url (Volvox) =  https://www.algaebase.org/search/genus/detail/?genus_id=43497 (different id)
    genus article url (Torodinium)= https://www.algaebase.org/search/genus/detail/?genus_id=44698
    Please cite this record as:   M.D. Guiry in Guiry, M.D. & Guiry, G.M. 2020. AlgaeBase. 
                                  World-wide electronic publication, National University of Ireland, Galway. 
                                  http://www.algaebase.org; searched on 10 May 2020.              
]]
data.AlgaeBase = {
	citationArgs = {
		           website="[[AlgaeBase]]",
	               ['editor1-last']="Guiry", ['editor1-first']="M.D.",
	               ['editor2-last']="Guiry", ['editor2-first']="G.M.",
		           publisher="National University of Ireland, Galway",
	},
	customArgs = { exclude = "id,1,genus_id,species_id,spid,genid",
	               baseURL = "https://www.algaebase.org/",
	               searchStr ="browse/taxonomy/?id=",
	               defaultSuffix = "",
	               defaultTitle = "AlgaeBase"
	}
}
data.AlgaeBase.id = function(id)
--[[ https://www.algaebase.org/browse/taxonomy/?id=6898 (id for taxonomy page)
    ]]
    local title = id
    local url = data.AlgaeBase.customArgs['baseURL'] .. data.AlgaeBase.customArgs['searchStr'] .. id
    return title, url  
end
data.AlgaeBase.genid = function(genid)
--[[ https://www.algaebase.org/search/genus/detail/?genus_id=43497 (different id for genus page)
    ]]
    local title = genid
    local url = data.AlgaeBase.customArgs['baseURL'] .. "search/genus/detail/?genus_id=" .. genid
    return title, url  
end
data.AlgaeBase.spid = function(spid)
--[[ https://www.algaebase.org/search/species/detail/?species_id=52713 (id for species page)
    ]]
    local title = spid
    local url = data.AlgaeBase.customArgs['baseURL'] .. "search/species/detail/?species_id=" .. spid
    return title, url  
end
data.AlgaeBase.error = function()
	return "Requires id and title parameters"
end
--############################## General Functions ########################################


local function getArgs (frame, args)
	local parents = mw.getCurrentFrame():getParent()
		
	for k,v in pairs(parents.args) do
		--check content
		if v and v ~= "" then
			args[k]=v --parents.args[k]
		end
	end
	for k,v in pairs(frame.args) do
		--check content
		if v and v ~= "" then
			args[k]=v 
		end
	end
end
local function initialise(frame, sourceDB)
	
	target=sourceDB
	templateArgs = sourceDB.citationArgs -- get custom arguments for target (fishbase, cof etc
    
	getArgs(frame, templateArgs) -- get template arguments from parent frame and frane
	
	
	local url = (target.customArgs['baseURL'] or "") .. (target.customArgs['defaultSuffix'] or "")
	local title = target.customArgs['defaultTitle'] or ""
	return title, url
end 
-- moved up top for scope
local function firstToUpper2(str)
    return (str:gsub("^%l", string.upper))
end
-- clear template arguments that won't be recognised by {{cite web}}
local function clearCustomArgs()
	
	local excludeTable = { 'genus', 'species', 'subspecies', 'family', 'order', 'taxon', 
		                   'id', 'search' , 'citation', 1, 2, 3, 4 }                          -- add defaults ?
	
	if target.customArgs['exclude'] then
		local customTable = mw.text.split (target.customArgs['exclude'] , "%s*,%s*");	
		for k,v in pairs(customTable) do
	    	table.insert (excludeTable, v )
		end
	end	
		for k,v in pairs(excludeTable) do
	    	if tonumber (v) then
	    		v = tonumber (v)  --convert positional parameters (numbers as string) to a number
			end
			templateArgs[v]=nil --clear content
		end
end

-- function handling the cite web template
p.citeWeb = function(frame, title, url)
    
    -- set url and title if not provided (template parameters override above)
    if not templateArgs['url'] and url then
    		templateArgs['url']= url
    end
    if not templateArgs['title'] and title then
	    	templateArgs['title'] = title
	end

    clearCustomArgs()--blank template parameters not for cite web
	
	local citeTemplate = 'cite web'          -- use Template:Cite web unless specified
	--if target.citeTemplate then citeTemplate = target.citeTemplate end
	return frame:expandTemplate{ title = citeTemplate, args = templateArgs  }

end
-- p.CiteBook
-- for reasons of consisitency within BioRef/FishRef the title parameter is the section-title of {{cite book}}
p.citeBook = function(frame, title, url, chapterParams) -- very much a msw3 function
    
    
    --if (1==1) then return templateArgs['title']  end
    
    -- set url and title if not provided (template parameters override above)
    if not templateArgs['url'] and url then
    		templateArgs['url']= url
    		if target.GoogleBooks then
    			templateArgs['url'] = target.GoogleBooks['baseURL'] .. target.GoogleBooks['id']
		                   	.. (target.GoogleBooks['defaultPage'] or "&pg=PP1")
    			
    		end
    end
    if not templateArgs['title'] and title then
	--    	templateArgs['title'] = title 
	end
	if templateArgs['title'] ~= title or templateArgs['taxon-title'] then -- do we have a section title provided
		templateArgs['section'] = templateArgs['title']  -- chapter/section title passed as title parameter
		templateArgs['title']   = title -- the work is the book title given in the source data
		if target.GoogleBooks then
			
			templateArgs['section-url'] = target.GoogleBooks['baseURL'] .. target.GoogleBooks['id']
			local pageSuffix = target.GoogleBooks['defaultPage'] or ""
			if templateArgs['page'] or templateArgs['gb-page'] then
				pageSuffix = "&pg=PT" .. (templateArgs['gb-page'] or templateArgs['page'] )
			end
			local searchStr = ""
		    -- quoted search {{#if:{{{text|{{{dq|}}}}}}|&dq={{urlencode:{{{text|{{{dq|}}}}}}}}}}
		    if templateArgs['q'] then searchStr = "&q=" .. mw.text.encode( templateArgs['q'] ) end
		    -- search #if:{{{keywords|{{{q|}}}}}}|&q={{urlencode:{{{keywords|{{{q|}}}}}}}}}}
		    if templateArgs['dq'] then searchStr = "&dq=" .. mw.text.encode( templateArgs['dq'] ) end
		    
		    
		    templateArgs['section-url'] = templateArgs['section-url'] .. pageSuffix ..  searchStr
            templateArgs['url'] = nil   -- no need for second link to google books
		end

	    -- if the chapter/section is linked, we can link the main book chapter differently 
	    if target.customArgs['altTitle'] then -- if we are using a chapter/section, we can wikilink the book title 
	    	templateArgs['title'] = target.customArgs['altTitle']  -- alternative to allow wikilink
	    elseif target.customArgs['altURL'] then
	    	templateArgs['url'] = target.customArgs['altURL']
	    end

	end -- end if using supplied title for chapter/section

    clearCustomArgs()--blank template parameters not for cite web
	
	local citeTemplate = 'cite book'          -- use Template:Cite web unless specified
	--if target.citeTemplate then citeTemplate = target.citeTemplate end
	return frame:expandTemplate{ title = citeTemplate, args = templateArgs  }

end

-- common function for genus and species
local function getGenusSpecies()
	--TODO standardise genus species handling
	local genus, species, subspecies
	if (templateArgs['genus']  or templateArgs[2] ) then 
	    genus = templateArgs['genus'] or templateArgs[2]
        genus = firstToUpper(mw.text.trim(genus))
	end
	if (templateArgs['species']  or templateArgs[3] ) then 
	    species = templateArgs['species'] or templateArgs[3]
	    species = 	mw.text.trim(species)
	end
	if (templateArgs['subspecies']  or templateArgs[4] ) then 
	    subspecies = templateArgs['subspecies'] or templateArgs[4]
	    subspecies = 	mw.text.trim(subspecies)
	end
	return genus, species, subspecies
end

--#################### MSW3   -- uses cite book
p.MSW3 = function(frame) 
	local msw = require('Module:FishRef/MSW')
	initialise(frame, msw.MSW3)
	return msw.MSW3.main(frame,templateArgs)
end
p.MSW3merged = function(frame) 
	local data = require('Module:FishRef/MSW')
	return p._main(frame, data.MSW3)
end
p.MSW3_standalone = function(frame) 
	
	local data = require('Module:FishRef/MSW')
	initialise(frame, data.MSW3)
    local url = target.CustomArgs['baseURL'] 
    
    
    if templateArgs['title'] and templateArgs['id'] then
    	templateArgs['chapter-url']= url .. target.CustomArgs['searchStr']  ..  templateArgs['id']
    	templateArgs['chapter'] = templateArgs['title']
      
    	templateArgs['title'] = target.CustomArgs['bookTitle']
    	if templateArgs['page'] then
    		templateArgs['url'] = target.CustomArgs['googleBooksURL'] .. templateArgs['page'] 
		else
   	        --return "Page number for google books required"
    	end
    elseif templateArgs['order'] then
    	templateArgs['chapter'] =  "Order " .. templateArgs['order']
    	local chapter = target.chapters[templateArgs['order']]
    	for k,v in pairs(chapter) do   -- add chapter specific parameters
    		templateArgs[k] = v 
    	end
    	templateArgs['chapter-url']= url .. target.CustomArgs['searchStr']  ..  templateArgs['id']
    	templateArgs['url']= target.CustomArgs['googleBooksURL']  ..  templateArgs['page']
    	if templateArgs['pages'] and templateArgs['page'] then templateArgs['page'] = nil end
    else -- default output
    	templateArgs['url']= target.CustomArgs['googleBooksURL']  .. "1" -- default to book
    	templateArgs['url']= url 
    end
    -- using cite book
	clearCustomArgs()--blank template parameters not for cite web
	return frame:expandTemplate{ title = 'cite book', args = templateArgs  }
end






--########################### Functions for access ##############################################


--================ Fishbase, Catalog of Fishes (cof) ================
p.fishbase    = function(frame) return p._main(frame, data.fishbase) end
p.cof         = function(frame) return p._main(frame, data.cof) end 
p.fotw5       = function(frame) return p._main(frame, data.fotw5) end 
--=================== ASW6, AmphibiaWeb, ReptileDB
p.reptileDB   = function(frame) return p._main(frame, data.reptileDB) end
p.ASW6        = function(frame) return p._main(frame, data.ASW6) end
p.amphibiaweb = function(frame) return p._main(frame, data.amphibiaweb) end
--=========== Birds
p.HBWa        = function(frame) return p._main(frame, data.HBWalive) end
p.HBWalive    = function(frame) return p._main(frame, data.HBWalive)  end
p.IOC         = function(frame) return p._main(frame, data.IOC) end
--======= Mammals
p.asm         = function(frame) return p._main(frame, data.asm) end
-- MSW3 has custom handling (see above)
--=========== Other
p.fossilworks = function(frame) return p._main(frame, data.fossilworks) end
p.worms       = function(frame) return p._main(frame, data.WoRMS) end
p.WoRMS       = function(frame) return p._main(frame, data.WoRMS) end

--fallback = function() return "hello" end
--#########################################################
p.main = function(frame) 
	local source = mw.text.trim(frame.args[1])
	
	if source == "MSW3" then return p.MSW3(frame) end
	
	if source == "ref" or source == "reference" then source = "Reference" end   -- aliases
	if source == "Reference" then return p.Reference(frame) end
    
    if source == "HBWa" then source = "HBWalive" end   -- aliases
    if source == "powo" then source = "POWO" end   -- aliases
	--return p[source]['test']
	if source == "fishbase" 
		or source == "cof" 
		or source == "fotw5" or source == "Fotw5" 
		or source == "reptileDB" 
		or source == "amphibiaweb" 
		or source == "ASW6" 
		or source == "asm" 
		or source == "HBWalive" or source == "HBWa" 
		or source == "fossilworks" 
		or source == "WoRMS" or source == "worms" 
		or source == "POWO" or source == "powo" 
		or source == "WFO" 
		or source == "AlgaeBase"
		-- and so on
	    then return p._main(frame,data[source])
	else
		-- 
		-- is there a point in the default if it needs the named object/table?
		return p._main(frame,data[source])
	end
end
p._main = function(frame, source) 

    --TODO in modular version source will be provided in frame arguments 
    --local source = mw.getCurrentFrame():getParent().args[1]
    local chapterParams = {} -- used for cite book (only MSW3 at moment)
    
    if not source then return "Error: unrecognised source." end
    
    local title, url = initialise(frame, source)
    
    --taxon related parameters
    local genus, species, subspecies = getGenusSpecies()              --name related parameters
    local family = templateArgs['family']
    local order = templateArgs['order']
    local taxon = templateArgs['taxon']
	
	local id = templateArgs['id']                                       --id related parameters
	local spid = templateArgs['spid'] or templateArgs['species_id']
	local genid = templateArgs['genid'] or templateArgs['genus_id']
	local citation = templateArgs['citation'] 
	local search = templateArgs['search']
    local mode, value
    
    -- the functions
    if genus and species and source.species then
    	title, url = source.species(genus,species,subspecies)
    else -- functions with just their own name as parameter
    	
    	if genus then mode = "genus"; value = genus 
    	elseif family then mode = "family"; value = family
    	elseif order then mode = "order"; value = order
    	elseif taxon then mode = "taxon"; value = taxon
    	elseif id then mode = "id"; value = id
    	elseif spid then mode = "spid"; value = spid
    	elseif genid then mode = "genid"; value = genid	
        elseif search then mode = "search"; value = search	
        elseif citation then mode = "citation"; value = citation	
    	else
    		-- no suitable parameter (use default page)
    		if source.default then
    			title, url, chapterParams = source.default(title, url)
    		end
    	end
    end
    if mode then
    	if source[mode] then
    		title, url, chapterParams = source[mode](value)  
    	elseif data.default[mode] then
    		title, url, chapterParams = data.default[mode](value, source)
    	else
    		if source.error then return source.error() end             -- custom error message
    	    return "Error: parameter not supported for this source"
    	end
    else 
    	-- if no mode then use the default title and url set by initialize()
    end

    if source.citeTemplate == "Cite book" then
    	return p.citeBook(frame, title, url, chapterParams)
    end
	return p.citeWeb(frame, title, url)
	
end  -- End the function.



local refs ={}
refs['Frost-2006']= '{{cite journal | last1 = Frost | first1 = Darrel R. | title = The Amphibian Tree of Life | hdl = 2246/5781 | journal = Bulletin of the American Museum of Natural History | volume = 297 | pages = 1–291 | year = 2006 | last2 = Grant | first2 = Taran | last3 = Faivovich | first3 = Julián | last4 = Bain | first4 = Raoul H. | last5 = Haas | first5 = Alexander | last6 = Haddad |first6 = Célio F.B. | last7 = De Sá | first7 = Rafael O. | last8 = Channing | first8 = Alan | last9 = Wilkinson | first9 = Mark | last10 = Donnellan | first10 = Stephen C. | last11 = Raxworthy | first11 = Christopher J. | last12 = Campbell | first12 = Jonathan A. | last13 = Blotto | first13 = Boris L. | last14 = Moler | first14 = Paul | last15 = Drewes | first15 = Robert C. | last16 = Nussbaum |first16 = Ronald A. | last17 = Lynch | first17 = John D. | last18 = Green | first18 = David M. | last19 = Wheeler | first19 = Ward C. | doi = 10.1206/0003-0090(2006)297[0001:TATOL]2.0.CO;2 | url = https://www.researchgate.net/publication/213771051 }}' 
refs['Nelson-2016'] = '{{cite book| last = Nelson| first = Joseph S.|first2=Terry C. |last2=Grande |first3=Mark V. H. |last3=Wilson | title = Fishes of the World |edition=5th|year = 2016| publisher =John Wiley and Sons |location=Hoboken |isbn = 978-1-118-34233-6 |doi=10.1002/9781119174844 |url=https://sites.google.com/site/fotw5th/}}'
refs['Benton-2014'] = '{{cite book| last = Benton| first = Michael J. | title = [[Vertebrate Palaeontology]] |edition=4th|year = 2014| publisher =John Wiley & Sons  |isbn = 978-1-118-40764-6  }}'
refs['CatSG'] = '{{cite journal |last1=Kitchener |first1=A. C. |last2=Breitenmoser-Würsten |first2=C. |last3=Eizirik |first3=E. |last4=Gentry |first4=A. |last5=Werdelin |first5=L. |last6=Wilting |first6=A. |last7=Yamaguchi |first7=N. |last8=Abramov |first8=A. V. |last9=Christiansen |first9=P. |last10=Driscoll |first10=C. |last11=Duckworth |first11=J. W. |last12=Johnson |first12=W. |last13=Luo |first13=S.-J. |last14=Meijaard |first14=E. |last15=O’Donoghue |first15=P. |last16=Sanderson |first16=J. |last17=Seymour |first17=K. |last18=Bruford |first18=M. |last19=Groves |first19=C. |last20=Hoffmann |first20=M. |last21=Nowell |first21=K. |last22=Timmons |first22=Z. |last23=Tobe |first23=S. |name-list-style=amp |date=2017 |title=A revised taxonomy of the Felidae: The final report of the Cat Classification Task Force of the IUCN Cat Specialist Group |journal=Cat News |issue=Special Issue 11 |pages=1-79 |url=https://repository.si.edu/bitstream/handle/10088/32616/A_revised_Felidae_Taxonomy_CatNews.pdf }}'
refs['Goffinet-2008'] = '{{cite book |last1=Goffinet |first1=B. |first2=W. R. |last2=Buck |first3=A. J. |last3=Shaw |year=2008 |chapter=Morphology and Classification of the Bryophyta |pages=55–138 |editor-last1=Goffinet |editor-first1=B. |editor-first2=J. |editor-last2=Shaw |title=Bryophyte Biology |edition=2nd |location=New York |publisher=Cambridge University Press |isbn=978-0-521-87225-6 |chapter-url=https://books.google.com/books?id=te0fAwAAQBAJ&pg=PT108}}'
p.Reference = function(frame)
	getArgs(frame, templateArgs)
	
	if templateArgs[2] then
		local reference = mw.text.trim(templateArgs[2])
		if reference ~= "" and refs[reference] then 
			if templateArgs['pages'] then 
				refs[reference] = refs[reference]:gsub("}}", "|pages="..templateArgs['pages'].."}}")
				refs[reference] = refs[reference]:gsub("|pages=[^|{}%[%]]*(|[^|{}}%[%]]*|pages=)", "%1")
			end
   			if templateArgs['expand'] and templateArgs['expand']=='no' then
   				return refs[reference]
   			else
   				return frame:preprocess(refs[reference])
   			end
   		else
   			return 'Reference not found: "'	.. templateArgs[2] .. '"'
		end
	end
	return "Reference parameter missing."
end -- End the function.




-- All modules end by returning the variable containing its functions to Wikipedia.
return p