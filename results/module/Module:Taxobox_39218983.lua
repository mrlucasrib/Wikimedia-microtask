local p={}

function wikidataAuthor()
    entity = mw.wikibase.getEntity()
    if not entity or not entity.claims then return end
    local property = entity.claims[ 'p405' ]
    if not property then return end--no such property for this item
    
    authorsNames = {}
    for i,author in pairs( property ) do
        local propValue = author.mainsnak and author.mainsnak.datavalue
        local linkTarget = mw.wikibase.sitelink( "Q" .. propValue.value['numeric-id'] )
        local linkTitle = mw.wikibase.label( "Q" ..propValue.value['numeric-id'] )
        local name = mw.ustring.gsub( linkTitle or linkTarget , '.+ (.*)', "%1")
        local link = (linkTarget and '[['..linkTarget..'|'..name..']]') or name
        table.insert(authorsNames, link)
    end
    return table.concat( authorsNames, ", ")
end

function conservation(convStatus,system, extinct, statusText, statusRef)
    convStatus=string.upper(convStatus)
    system = string.upper(system)
    local statusCategory ={
        ['EX'] = '[[Category:IUCN Red List extinct species]]',
        ['EW'] = '[[Category:IUCN Red List extinct in the wild species]]',
        ['CR'] = '[[Category:IUCN Red List critically endangered species]]',
        ['EN'] = '[[Category:IUCN Red List endangered species]]',
        ['VU'] = '[[Category:IUCN Red List vulnerable species]]',
        ['LR'] = '[[Category:Invalid conservation status]]',
        ['LR/CD'] = '[[Category:IUCN Red List conservation dependent species]]',
        ['LR/NT'] = '[[Category:IUCN Red List near threatened species]]',
        ['LR/LC'] = '[[Category:IUCN Red List least concern species]]',
        ['LC'] = '[[Category:IUCN Red List least concern species]]',
        ['DD'] = '[[Category:IUCN Red List data deficient species]]',
        ['PE'] = '[[Category:IUCN Red List critically endangered species]]',
        ['PEW'] = '[[Category:IUCN Red List critically endangered species]]'
    }
    local ebpcCategory = {
        ['EX'] = '[[Category:EPBC Act extinct biota]]',
        ['EW'] = '[[Category:EPBC Act extinct in the wild biota]]',
        ['CR'] = '[[Category:EPBC Act critically endangered biota]]',
        ['EN'] = '[[Category:EPBC Act endangered biota]]',
        ['VU'] = '[[Category:EPBC Act vulnerable biota]]',
        ['CD'] = '[[Category:EPBC Act conservation dependent biota]]',
        ['DL'] = '',
        ['Delisted'] =''
    }
    local conservation23={
        ['EX'] = '[[file:Status iucn2.3 EX.svg|frameless|link=|alt=]]<br />[[Extinction|Extinct]]' .. ((extinct and '&nbsp;('..extinct..')') or ''),
        ['EW'] = '[[file:Status iucn2.3 EW.svg|frameless|link=|alt=]]<br />[[Extinct in the Wild]]',
        ['CR'] = '[[file:Status iucn2.3 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered species|Critically Endangered]]',
        ['EN'] = '[[file:Status iucn2.3 EN.svg|frameless|link=|alt=]]<br />[[Endangered species|Endangered]]',
        ['VU'] = '[[file:Status iucn2.3 VU.svg|frameless|link=|alt=]]<br />[[Vulnerable species|Vulnerable]]',
        ['LR'] ='[[file:Status iucn2.3 blank.svg|link = |alt = ]]<br />Lower risk',
        ['LR/CD'] = '[[file:Status iucn2.3 CD.svg|frameless|link=|alt=]]<br />[[Conservation Dependent]]',
        ['LR/NT'] = '[[file:Status iucn2.3 NT.svg|frameless|link=|alt=]]<br />[[Near Threatened]]',
        ['LC'] = '[[file:Status iucn2.3 LC.svg|frameless|link=|alt=]]<br />[[Least Concern]]',
        ['LR/LC'] = '[[file:Status iucn2.3 LC.svg|frameless|link=|alt=]]<br />[[Least Concern]]',
        ['DD'] = '[[file:Status iucn2.3 blank.svg|frameless|link=|alt=]]<br />[[Data Deficient]]',
        ['NE'] = "''Not evaluated''",
        ['NR'] = "''Not recognized''",
        ['PE'] = '[[file:Status iucn2.3 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct',
        ['PEW'] = '[[file:Status iucn2.3 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct in the wild'
    }
    
    local conservation31={
        ['EX'] = '[[file:Status iucn3.1 EX.svg|frameless|link=|alt=]]<br />[[Extinction|Extinct]]' .. ((extinct and '&nbsp;('..extinct..')') or ''),
        ['EW'] = '[[file:Status iucn3.1 EW.svg|frameless|link=|alt=]]<br />[[Extinct in the Wild]]',
        ['CR'] = '[[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered species|Critically Endangered]]',
        ['EN'] = '[[file:Status iucn3.1 EN.svg|frameless|link=|alt=]]<br />[[Endangered species|Endangered]]',
        ['VU'] = '[[file:Status iucn3.1 VU.svg|frameless|link=|alt=]]<br />[[Vulnerable species|Vulnerable]]',
        ['LC'] = '[[file:Status iucn3.1 LC.svg|frameless|link=|alt=]]<br />[[Least Concern]]',
        ['DD'] = '[[file:Status iucn3.1 blank.svg|frameless|link=|alt=]]<br />[[Data Deficient]]',
        ['NE'] = "''Not evaluated''",
        ['NR'] = "''Not recognized''",
        ['PE'] = '[[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct',
        ['PEW'] = '[[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct in the wild'
    }
    local EPBC = {
         ['EX'] = '[[file:Status EPBC EX.svg|frameless|link=|alt=]]<br />[[Extinction|Extinct]]' .. ((extinct and '&nbsp;('..extinct..')') or ''),
         ['EW'] = '[[file:Status EPBC EW.svg|frameless|link=|alt=]]<br />[[Extinct in the Wild]]',
         ['CR'] = '[[file:Status EPBC CR.svg|frameless|link=|alt=]]<br />[[Critically endangered species|Critically endangered]]',
         ['EN'] = '[[file:Status EPBC EN.svg|frameless|link=|alt=]]<br />[[Endangered species|Endangered]]',
         ['VU'] = '[[file:Status EPBC VU.svg|frameless|link=|alt=]]<br />[[Vulnerable species|Vulnerable]]',
         ['CD'] = '[[file:Status EPBC CD.svg|frameless|link=|alt=]]<br />[[Conservation Dependent]]',
         ['DL'] = '[[file:Status EPBC DL.svg|frameless|link=|alt=]]<br />Delisted',
         ['Delisted'] = '[[file:Status EPBC DL.svg|frameless|link=|alt=]]<br />Delisted'
     }
     
    
    local result = ''
    if system=='IUCN2.3' then
         result = conservation23[convStatus] or "'''''Invalid status'''''[[Category:Invalid conservation status]]"
         result = '<small>&nbsp;('..((statusText and '[['..statusText..'|See text]]') or ('[[IUCN Red List|IUCN 2.3]]'))..')'..statusRef..'</small></div>'
    end
    if system=='IUCN3.1' then
         result = conservation31[convStatus] or "'''''Invalid status'''''[[Category:Invalid conservation status]]"
         result = '<small>&nbsp;('..((statusText and '[['..statusText..'|See text]]') or ('[[IUCN Red List|IUCN 3.1]]'))..')'..statusRef..'</small></div>'
     end
     if system=='EBPC' then
         result = EPBC[convStatus] or "'''''Invalid status'''''[[Category:Invalid conservation status]]"
         result = '<small>&nbsp;('..((statusText and '[['..statusText..'|See text]]') or ('[[Environment Protection and Biodiversity Conservation Act 1999|EPBC Act]]'))..')'..statusRef..'</small></div>'
    end
    if extinct and mw.title.getCurrentTitle().namespace==0 then
        return result..(( system=='EBPC' and ebpcCategory[convStatus]) or statusCategory[convStatus] or '')
    end
    return result
    
end

function p.header( kingdom, title )
     if not p.color then
        local colors = {
            [ "Bacteria" ] = "#D3D3D3",
            [ "Archea" ] = "#ECD2D2",
            [ "Animalia"]="#D3D3A4",
            [ "Animal"]="#D3D3A4",
            [ "Metazoa"]="#D3D3A4",
            [ "Fungi"]="lightblue",
            [ "Eukaryota"]="#E0D2B0",
            [ "Eukarya"]="#E0D2B0",
            [ "Plantae" ] = "lightgreen"
        }        
        local colorKingdom = colors[kingdom]
        if not colorKingdom and kingdom then --pattern search - usefull for links...
            for k,v in pairs( colors ) do
                if string.find( kingdom,k ) then
                    colorKingdom = v
                    break
                end
            end
        end
        p.color = colorKingdom or "#CE9EF2"
    end
    return "! colspan=\"2\" style=\"text-align: center; background-color: " .. p.color .. ";\" | " .. title
end

function translateFromLatin( latin )
    local latinDict = {
        ['virus_group'] = 'Group',
        ['superregnum'] = 'Superkingdom',
        ['divisio'] = 'Division',
        ['zoodivisio'] = 'Division',
        ['regnum'] = 'Kingdom',
        ['subregnum'] = 'Subkingdom',
        ['zoosectio'] = 'Section',
        ['zoosubsectio'] = 'Subsection',
        ['superclassis'] = 'Superclass',
        ['subclassis'] = 'Subclass',
        ['infraclassis'] = 'Infraclass',
        ['classis'] = 'Class',
        ['magnordo'] = 'Magnorder',
        ['superordo'] = 'Superorder',
        ['grandordo'] = 'Grandorder',
        ['ordo'] = 'Order',
        ['subordo'] = 'Suborder',
        ['infraordo'] = 'Infraorder',
        ['infraordo'] = 'Microrder',
        ['parvordo'] = 'Parvorder',
        ['superfamilia'] = 'Superfamily',
        ['familia'] = 'Family',
        ['subfamilia'] = 'Subfamily',
        ['supertribus'] = 'Supertribe',
        ['tribus'] = 'Tribe',
        ['subtribus'] = 'Subtribe',
        ['infratribus'] = 'Infratribe',
        ['species_group'] = 'Species group',
        ['species_subgroup'] = 'Species subgroup',
        ['species_complex'] = 'Species complex',
        ['cladus'] = 'Clade',
        ['ichnostem-group'] = 'Ichnostem-Group',
        ['ichnosuperclassis'] = 'Ichnosuperclass',
        ['ichnoclassis'] = 'Ichnoclass',
        ['ichnosubclassis'] = 'Ichnosubclass',
        ['ichnoinfraclassis'] = 'Ichnoinfraclass',
        ['ichnodivisio'] = 'Ichnodivision',
        ['ichnosubdivisio'] = 'Ichnosubdivision',
        ['ichnoinfradivisio'] = 'Ichnoinfradivision',
        ['ichnomagnordo'] = 'Ichnomagnorder',
        ['ichnosuperordo'] = 'Ichnosuperorder',
        ['ichnograndordo'] = 'Ichnograndorder',
        ['ichnomicrordo'] = 'Ichnomicrorder',
        ['ichnoordo'] = 'Ichnoorder',
        ['ichnosubordo'] = 'Ichnosuborder',
        ['ichnoinfraordo'] = 'Ichnoinfraorder',
        ['ichnoparvordo'] = 'Ichnoparvorder',
        ['ichnosuperfamilia'] = 'Ichnosuperfamily',
        ['ichnofamilia'] = 'Ichnofamily',
        ['ichnosubfamilia'] = 'Ichnosubfamily',
        ['ooclassis'] = 'Ooclass',
        ['oosubclassis'] = 'Oosubclass',
        ['oosupercohort'] = 'Oosupercohort',
        ['oocohort'] = 'Oocohort',
        ['oomagnordo'] = 'Oomagnorder',
        ['oosuperordo'] = 'Oosuperorder',
        ['oordo'] = 'Oorder',
        ['morphotype'] = 'Morphotype',
        ['oofamilia'] = 'Oofamily',
        ['oogenus'] = 'Oogenus',
        ['oosubgenus'] = 'Oogenus',
        ['oospecies'] = 'Oospecies',
        ['oosubspecies'] = 'Oosubspecies',
        ['sectio'] = 'Section',
        ['subsectio'] = 'Subsection',
        ['superdivisio'] = 'Superdivision'
    }
    latin = string.gsub( latin, '(.*) .*', '%1' ) --only the first word
    local lang = mw.language.getContentLanguage()
    return latinDict[ latin ] or lang:ucfirst( latin )
end

function p.taxbox( frame )
    local realParams={}
    
    for i,j in pairs( frame.args ) do
        if string.len(j)>0 then
            realParams[i]=j
        end
    end
    frame.args=realParams

    local wikidataProp = require("Module:PropertyLink")
    local classificationParam = {
        "unranked_superdomain",
        "superdomain",
        "unranked_domain",
        "domain",
        "unranked_superregnum",
        "superregnum",
        "unranked_regnum",
        "regnum",
        "unranked_subregnum",
        "subregnum",
        "unranked_superdivisio",
        "superdivisio",
        "unranked_superphylum",
        "superphylum",
        "unranked_divisio",
        "divisio",
        "unranked_phylum",
        "phylum",
        "unranked_subdivisio",
        "subdivisio",
        "unranked_subphylum",
        "subphylum",
        "unranked_infraphylum",
        "infraphylum",
        "unranked_microphylum",
        "microphylum",
        "unranked_nanophylum",
        "nanophylum",
        "unranked_superclassis",
        "superclassis",
        "unranked_classis",
        "classis",
        "unranked_subclassis",
        "subclassis",
        "unranked_infraclassis",
        "infraclassis",
        "unranked_magnordo",
        "magnordo",
        "unranked_superordo",
        "superordo",
        "unranked_ordo",
        "ordo",
        "unranked_subordo",
        "subordo",
        "unranked_infraordo",
        "infraordo",
        "unranked_parvordo",
        "parvordo",
        "unranked_zoodivisio",
        "zoodivisio",
        "unranked_zoosectio",
        "zoosectio",
        "unranked_zoosubsectio",
        "zoosubsectio",
        "unranked_superfamilia",
        "superfamilia",
        "unranked_familia",
        "familia",
        "unranked_subfamilia",
        "subfamilia",
        "unranked_supertribus",
        "supertribus",
        "unranked_tribus",
        "tribus",
        "unranked_subtribus",
        "subtribus",
        "unranked_alliance",
        "alliance",
        "unranked_genus",
        "genus",
        "unranked_subgenus",
        "subgenus",
        "unranked_sectio",
        "sectio",
        "unranked_subsectio",
        "subsectio",
        "unranked_series",
        "series",
        "unranked_subseries",
        "subseries",
        "unranked_species_group",
        "species_group",
        "unranked_species_subgroup",
        "species_subgroup",
        "unranked_species_complex",
        "species_complex",
        "unranked_species",
        "species",
        "unranked_subspecies",
        "subspecies"
    }
    local wikidataTaxonProperties = {
        [ "regnum"] = 'p75',
        [ "phylum"] = 'p76',
        [ "classis"] = 'p77',
        [ "ordo"] = 'p70',
        [ "familia"] = 'p71',
        [ "genus"] = 'p74',
        [ "species"] = 'p89',
        [ "binomial"] = 'p225',
        [ "binomial_authority"] = 'p405',
        [ "status"] = 'p141',
        [ "range_map"] = 'p181'
    }
    local classifiedUnderParams = {
        "Phyla",
        "Classes",
        "Subclasses",
        "Orders",
        "Families",
        "Genera",
    }
    local currTitle = tostring( mw.title.getCurrentTitle() )
    local title = frame.args[ "name" ] or currTitle
    if frame.args["temporal_range"] or frame.args['fossil_range'] then
        title = title ..'<br /><small>Temporal range: '..(frame.args["temporal_range"] or frame.args['fossil_range'])..'</small>'
    end
    
    local headerKingdom = frame.args[ "regnum"] or frame.args[ "domain"] or wikidataProp.getProperty( wikidataTaxonProperties[ "regnum" ] )
    local mainHeader = p.header( headerKingdom,  title )
    local wikidataEntity = mw.wikibase.getEntity()
    local wikidataEdit = '[[File:Gnome-edit-clear.svg|20px|edit|link=' ..((wikidataEntity and 'd:' .. wikidataEntity.id) or '//www.wikidata.org/wiki/Special:NewItem?label='..mw.uri.encode( currTitle )) .. ']]'
    
    local imageArea =  (frame.args[ 'image' ] and '[['..string.format('file:%s|%s|alt=%s', frame.args[ 'image' ], frame.args['image_width'] or 'frameless', frame.args['image_alt'] or '')..']]') or wikidataProp.getImageLink() 
    imageArea = imageArea and string.format([[
    |-
    | colspan="2" style="text-align: center; font-size: 88%%" | %s
    ]], imageArea )
    if frame.args['image_caption'] then
        imageArea = imageArea .. '<div style="clear: both;"></div>' .. frame.args['image_caption']
    end

    
    local distributionMap = frame.args['range_map'] or wikidataProp.getImageLink( wikidataTaxonProperties["range_map"] ) 
    distributionMap = distributionMap and string.format([[
        |-
        %s
        |-
        | colspan="2" | %s
        ]],p.header( headerKingdom,'[[Species distribution|Distribution]]'), distributionMap )
    
    if frame.args['range_map_caption'] and distributionMap then  
        distributionMap = distributionMap .. '<br />'..frame.args['range_map_caption'] 
    end
    
    local synoyms = frame.args[ "synonyms"]
    synoyms = synoyms and string.format([[
    |-
    %s
    |-
    colspan="2" style="font-size:90%;" | %s
    ]],p.header( headerKingdom,'Synonyms'), synoyms )
    

    
    local iucnStatus = frame.args[ "status" ]
    statusFile = {
        ['Least Concern'] = 'LC',
        ['Near Threatened'] = 'NT',
        ['endangered species'] = 'EN',
        ['vulnerable species'] = 'VU',
        ['Critically Endangered'] = 'CR',
        ['extinct in the wild'] = 'EW',
        ['Extinct'] = 'EX',
        ['Data Deficient'] = 'DD'
    }
    statusDescription = {
        ['EX'] = '[[Extinction|Extinct]]',
        ['EW'] = '[[Extinct in the Wild]]',
        ['CR'] = '[[Critically endangered species|Critically Endangered]]',
        ['EN'] = '[[Endangered species|Endangered]]',
        ['VU'] = '[[Vulnerable species|Vulnerable]]',
        ['LC'] = '[[Least Concern]]',
        ['CD'] ='[[Conservation Dependent]]',
        ['NT'] = '[[Near Threatened]]'
    }
    wikidataStatus=wikidataProp.getLabel( wikidataTaxonProperties[ "status"] )
    iucnStatus = (iucnStatus and string.upper(iucnStatus)) or (wikidataStatus and statusFile [wikidataStatus])
    
    if iucnStatus then
        iucnStatus = '[[file:Status iucn2.3 ' .. iucnStatus ..'.svg|frameless|link=|alt=]]'..'<br>'..statusDescription[iucnStatus]
        if frame.args["extinct"] and iucnStatus=='EX' then
            iucnStatus = iucnStatus..'&nbsp;('..frame.args["extinct"]..')'
        end
        
    end
    
    iucnStatus = iucnStatus and string.format([[
        |-
        %s
        |-
        | colspan="2" style="text-align:center;" | %s
        ]],p.header( headerKingdom,'[[Conservation status]]'), iucnStatus )
    
    local classifictionSection = ''
    local taxonRank
    local usesWikidataParam = false
    local underGenus = false
    for i,j in ipairs( classificationParam ) do
        --_authority
        local taxonVal = frame.args[j]
        if not taxonVal then
            taxonVal = ( wikidataTaxonProperties[j] and wikidataProp.getProperty( wikidataTaxonProperties[j] ) )
            if taxonVal then
                usesWikidataParam = true
            end
        end
        if taxonVal then
            if j=='genus' then
                underGenus = true
            end
            
            local taxonHeader = translateFromLatin(j)
            taxonRank = j
            --italics for genus, species
            taxonVal = ((not string.find(taxonVal,"''")) and underGenus and "''"..taxonVal.."''" ) or taxonVal
            --to do maybe translate latin to english if we want to add latin parameters
            classifictionSection = classifictionSection..'\n|-\n|'..taxonHeader..': ||'..((currTitle==taxonVal and "'''"..taxonVal.."'''") or taxonVal)
            if frame.args[j..'_authority'] then 
                classifictionSection = classifictionSection .. '<br /><small>'..frame.args[j..'_authority']..'</small>'
            end
            
        end
    end

    local classificationSectionHeader = (usesWikidataParam and '[[Biological classification|Scientific classification]]'..'<span class="editsection">'..wikidataEdit..'</span>' ) or '[[Biological classification|Scientific classification]]'
    classifictionSection = ('|-\n' .. p.header( headerKingdom, classificationSectionHeader ).. classifictionSection)
 
    local underClassification
    for i,j in ipairs( classifiedUnderParams ) do
        if frame.args[j] then
            underClassification='|-\n'..p.header( headerKingdom,j )..'\n|-\n| colspan="2" |'..frame.args[j]
            break
        end
    end
    
    local taxonomicName = frame.args[ "binomial" ] or wikidataProp.getProperty( wikidataTaxonProperties[ "binomial" ])  
    if taxonomicName then
        local taxonomicDisplay = (( taxonRank=="Species" or taxonRank=="Genus") and "''"..taxonomicName.."''" ) or taxonomicName
        local taxonom = frame.args[ "binomial_authority"]  or wikidataAuthor()
        taxonomicName = '|-\n'..p.header( headerKingdom,"[[Binomial nomenclature|Binomial name]]")..'\n|-\n| colspan="2" style="text-align: center;" | '..taxonomicDisplay
        if taxonom then
            taxonom = '<br /><small>'..taxonom..'</small>'
            taxonomicName = taxonomicName..taxonom
        end
    end
    
    local taxonSections = { imageArea or "" ,iucnStatus or "", classifictionSection or "", underClassification or "", taxonomicName or "", distributionMap or "", synoyms or "" }
    local realSections = {}
    for i,j in ipairs( taxonSections ) do
        if string.len( j )>0 then table.insert( realSections,j ) end
    end
    
    taxonSections = table.concat( realSections, "\n")
    result = string.format([[
    {| class="infobox biota" style="text-align: left; width: 200px; font-size: 100%%"
    |-
    %s
    %s
    |}
    ]], mainHeader,taxonSections )

    return result
end

return p