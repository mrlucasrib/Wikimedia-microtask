local p = { }

local navbar = require('Module:Navbar')._navbar
local infobox = require('Module:Infobox3cols').infobox
local infoboxImage = require('Module:InfoboxImage').InfoboxImage

-- wrapped "protected call", return "value error" with error info on error
local function check_values(f,args)
	    --local u= table.upack(args)
		local exist, val = pcall(f, unpack(args))
		if exist and val ~= nil then
			return(val)
		else
			-- Leaking some debugging info won't hurt....
			return("'''VALUE_ERROR''' (" .. tostring(val) .. ")")
		end
end
--texts relevant to localization are tagged with --**lclz** and/or *lclz*
--on a page {{#invoke:Sandbox/genewiki/alllua|getTemplateData|QID=Q14865053}}
--in debug window 
--frame = mw.getCurrentFrame()
--frame.args = {QID="Q14865053"} Q18031325
--print(p.getTemplateData(frame))
p.getTemplateData = function(frame)

	--make some guesses about whether the provided QID is a good one
	--could expand here if we had some kind of error handling framework
	--did we get it from the page
	local root_qid = mw.text.trim(frame.args['QID']  or "") --try to get it from the args
	local mm_qid = ""
	--pull all the entity objects that we will need
	local	entity = {} 
	local	entity_protein = {}
	local	entity_mouse = {}
	local	entity_mouse_protein = {}
	local	checkOrtholog = "" --flag used to see if mouse data avaliable
	
	local mouse_propertyID = "P684" --actually ortholog property additional orthologs can exist
	local protein_propertyID = "P688" 

	--get root gene entity
	if root_qid == "" then
		entity = mw.wikibase.getEntityObject()
		if entity then root_qid = entity.id else root_qid = "" end
			
	else
		--assuming we think its good make one call to retrieve and store its wikidata representation
		entity = mw.wikibase.getEntity(root_qid)
	end
	
  	--need to figure out if it is protein or gene here
	local subclass = p.getValue(entity, "P31") or ""
	if string.find(subclass, 'protein') then --if protein switch entity to gene
		if entity.claims then
	 		claims = entity.claims["P702"] --encoded by
	 	end
		if claims then
			--go through each index and reassign entity
			entity = {}
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				for k, v in pairs(claims) do --this would be problematic if multiple genes for the protein
					local itemID = "Q" .. claims[#entity + 1].mainsnak.datavalue.value["numeric-id"]
					entity[#entity + 1] = mw.wikibase.getEntity(itemID)
					root_qid = itemID
				end
				
			end --will return nothing if no claims are found
		end
		 entity = mw.wikibase.getEntity(root_qid) 	
	 end
	
	
	--get the other related entities
	if entity then
		local claims = ""
	 	--get protein entity object
	 	if entity.claims then
	 		claims = entity.claims[protein_propertyID]
	 	end
		if claims then
			--go through each index and then make entity_protein indexed
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				for k, v in pairs(claims) do
					local protein_itemID = "Q" .. claims[#entity_protein + 1].mainsnak.datavalue.value["numeric-id"]
					entity_protein[#entity_protein + 1] = mw.wikibase.getEntity(protein_itemID)
				end
				
			end --will return nothing if no claims are found
		end
	
	 	--get mouse entity object
	 	if entity.claims then
			claims = entity.claims[mouse_propertyID]
		end
		local qualifierID = "P703" --found in taxon
		local mouse_qual = "Q83310"
		if claims then
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				for k, v in pairs(claims) do
					if checkOrtholog == 1 then -- Don't have to go on if we already got it
						break
					end

				  	local mouse_itemID = "Q" .. v.mainsnak.datavalue.value["numeric-id"]
					local quals 
					if v.qualifiers then
						quals = v.qualifiers.P703
					end
					if quals then
						for qk, qv in pairs(quals) do
							--get the taxon qualifier id
							local qual_obj_id = "Q"..qv.datavalue.value["numeric-id"]
							if qual_obj_id == mouse_qual then --check if this is mouse or other
								mm_qid = mouse_itemID 
								entity_mouse = mw.wikibase.getEntity(mouse_itemID)
								checkOrtholog = 1
								break
							end
						end
					end
				end
			end --will return nothing if no claims are found
		else
			checkOrtholog = 0
		end
	
	 	--get mouse protein entity object
	 	if entity_mouse and entity_mouse.claims then
			claims = entity_mouse.claims[protein_propertyID]
		end
	 	if claims then
	 		if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				for k, v in pairs(claims) do
					local protein_itemID = "Q" .. claims[#entity_mouse_protein + 1].mainsnak.datavalue.value["numeric-id"]
					entity_mouse_protein[#entity_mouse_protein + 1] = mw.wikibase.getEntity(protein_itemID)
				end
			end --will return nothing if no claims are found
	 	end	
	
	end
	
	
	if entity then --only require the main gene entity
		--a list variables of all the data in the info box
		local name = check_values(p.getLabel,{entity})
		local entrez_gene = check_values(p.getValue, {entity, "P351", "n/a"} )
		local entrez_gene_mm = check_values(p.getValue, {entity_mouse, "P351", "n/a"})
		local image = check_values( p.getImage, {entity, "P18", " ", "250px"}) --need to set size
		local uniprotID_hs = check_values(p.getValueProtein, {entity_protein, "P352", "n/a"})
	    local uniprotID_mm = check_values(p.getValueProtein, {entity_mouse_protein, "P352", "n/a"})
	    local pdbIDs = check_values(p.getPDB, {entity_protein}) --makes a list with links to RCSB
	    local aliases = check_values(p.getAliases, {entity})
	    local gene_symbol = check_values(p.getValue, {entity, "P353"})
	    local hgnc_id = check_values(p.getValue, {entity, "P354"})
	    local homologene_id = check_values(p.getValue, {entity, "P593"})
	    local omim_id = check_values(p.getValue, {entity, "P492"})
	    local mgi_id = check_values(p.getValue, {entity_mouse, "P671"})
	    local ChEMBL_id = check_values(p.getValue, {entity_protein, "P592"}) 
	    local IUPHAR_id = check_values(p.getValue, {entity_protein, "P595"})
	    local ec_no = check_values(p.getValueProtein, {entity_protein, "P591"})
	    local mol_funct = check_values(p.getGO, {entity_protein, "P680"})
	    local cell_comp = check_values(p.getGO, {entity_protein, "P681"}) 
	    local bio_process = check_values(p.getGO, {entity_protein, "P682"})
	    local expression_images = check_values(p.getImage, {entity,"P692","<br><br>","250px"})
	    local ensembl = check_values(p.getValue, {entity, "P594", "n/a"})
	    local ensembl_mm = check_values(p.getValue, {entity_mouse, "P594", "n/a"})
	    local refseq_mRNA = check_values(p.getRefseq_mRNA, {entity, "P639", "n/a"})
	    local refseq_mRNA_mm = check_values(p.getRefseq_mRNA, {entity_mouse, "P639", "n/a"}) 
	    local refseq_prot = check_values(p.getRefseq_protein, {entity_protein, "P637", "n/a"})
	    local refseq_prot_mm = check_values(p.getRefseq_protein, {entity_mouse_protein, "P637", "n/a"})
		local gstart = check_values(p.getChromosomeLoc, {entity, "P644", "hg"})
		local gend = check_values(p.getChromosomeLoc, {entity, "P645", "hg"})
		local chr = check_values(p.trimChromosome, {entity})
	    local cytoband = check_values(p.getValue, {entity, "P4196", "n/a"})
		local db = check_values(p.getAliasFromGenomeAssembly, {entity,"hg"}) 
		local gstart_mm = check_values(p.getChromosomeLoc, {entity_mouse, "P644", "mm"})
		local gend_mm =  check_values(p.getChromosomeLoc, {entity_mouse, "P645", "mm"})
		local chr_mm = check_values( p.trimChromosome, {entity_mouse})
		local db_mm = check_values(p.getAliasFromGenomeAssembly, {entity_mouse,"mm"})
	    local cytoband_mm = check_values(p.getValue, {entity_mouse, "P4196", "n/a"})
		local disease, dis_ref = ''
		if p.getDisease(entity, "P2293") then disease, dis_ref = p.getDisease(entity, "P2293") else disease, dis_ref = {"'''VALUE_ERROR'''","'''VALUE_ERROR'''" } end
		if p.getDrug(entity_protein, "P129") then drug, drug_ref, drug_pqid, drug_pname = p.getDrug(entity_protein, "P129") else drug, drug_ref, drug_pqid, drug_pname = {"'''VALUE_ERROR'''","'''VALUE_ERROR'''" } end
		--local drug = check_values(p.getDrug, {entity_protein, "P129"})
		
		--define Global Color Scheme
		rowBGcolor = '#eee'
		titleBGcolor = '#ddd'
		sideTitleBGcolor = '#c3fdb8'

		p.createTable()
    	p.renderUpperTitle(name)
    	--p.renderCaption()
    	p.renderImage(image)
    	p.renderAvailableStructures(uniprotID_hs, uniprotID_mm, checkOrtholog, pdbIDs) --PDB info
		p.renderIdentifiers(aliases, hgnc_id, gene_symbol, homologene_id, omim_id, mgi_id, ChEMBL_id, IUPHAR_id, ec_no, entrez_gene)
		--uncomment here to add a section of the infobox about genetically related diseases, with references
		--if (disease ~= "" and dis_ref ~= "") then --removes section from those items without disease info
		--	p.renderDiseases(frame, disease, dis_ref, name, root_qid)
		--end
        
        --uncomment here to add a section of the infobox about drugs that target the protein product of this gene, with references
		--if (drug ~= "" ) then --removes section from those items without drug info
		--	p.renderDrug(frame,drug, drug_ref, drug_pqid, drug_pname)
    	--end
		
		if (chr ~= "" and gstart ~= "" and gend ~= "") or (chr_mm ~= "" and gstart_mm ~= "" and gend_mm ~= "") then
			p.renderGeneLocation(frame, chr, gstart, gend, db, cytoband, ensembl, chr_mm, gstart_mm, gend_mm, db_mm, cytoband_mm, ensembl_mm, name)
		end
		if expression_images ~= ""  then
			p.renderRNAexpression(expression_images, entrez_gene)
		end
		if (mol_funct ~= "" and cell_comp ~= "" and bio_process ~= "") then
			p.renderGeneOntology(mol_funct, cell_comp, bio_process, uniprotID_hs)
		end
		p.renderOrthologs(frame, entrez_gene, entrez_gene_mm, ensembl, ensembl_mm, uniprotID_hs, uniprotID_mm, refseq_mRNA, refseq_mRNA_mm, refseq_prot, refseq_prot_mm, db, chr, gstart, gend, db_mm, chr_mm, gstart_mm, gend_mm)
		p.renderFooter(root_qid, mm_qid)        
		
		return tostring(root)
        --return table.concat(drug_pqid)
        
	else return "An Error has occurred retrieving Wikidata item for infobox"
	end	
end

p.createTable = function(subbox)

    if subbox == 'sub' then --doesn't work 
    	 root
        	:tag('table') 
            :css('padding', '0')
            :css('border', 'none')
            :css('margin', '0')
            :css('width', 'auto')
            :css('min-width', '100%')
            :css('font-size', '100%')
            :css('clear', 'none')
            :css('float', 'none')
            :css('background-color', 'transparent')
           
    else
    	root = mw.html.create('table')
    	root
	    	-- *lclz*: Some projects, like zhwiki (again), use inline styles on 
	    	-- infobox modules in addition to the class. Be sure to check them out.
    		:addClass('infobox')
        	:css('width', '26.4em')
    end

end

--Title above image
p.renderUpperTitle = function(name)
	local title = name
    if not title then return "error: failed to get label"; end
    
    root
        :tag('tr')
            :tag('th')
                :attr('colspan', 4)
                :css('text-align', 'center')
                :css('font-size', '125%')
                :css('font-weight', 'bold')
                :wikitext(title)
                :done() --end th
            :done() --end tr
end

--This is a place holder for the image caption, which is stored in wikicommons comments unsure how to access 
p.renderCaption = function(entity)
	--caption
end

--gets default image
p.renderImage = function(image)

	root
			:tag('tr')
        		:tag('td')
   					:attr('colspan', 4)
            		:css('text-align', 'center')
            		:wikitext(image)
         			:done() --end td
         		:done() --end tr
         		
end



p.renderAvailableStructures = function(uniprotID_hs, uniprotID_mm, checkOrtholog, pdbIDs)

    local title = 'Available structures' --**lclz**
    local pdb_link = "[[Protein_Data_Bank|PDB]]" --**lclz**
    local searchTitle = "" 
    local listTitle = "List of PDB id codes" --**lclz**
    local PDBe_base = 'https://www.ebi.ac.uk/pdbe/searchResults.html?display=both&amp;term='
    local RCSB_base = 'http://www.rcsb.org/pdb/search/smartSubquery.do?smartSearchSubtype=UpAccessionIdQuery&amp;accessionIdList='
    local url_uniprot = " " 
    
    
    if checkOrtholog == 1 and uniprotID_mm ~= 'n/a' then
    	searchTitle = 'Ortholog search: '
    	url_uniprot = uniprotID_mm..','..uniprotID_hs
    else
    	searchTitle = 'Human UniProt search: '
    	url_uniprot = uniprotID_hs
    end
    local PDBe_list = " " --create a list with " or " if there is more than one uniprot
    --get first uniprot in a list
	if url_uniprot:match("([^,]+),") then--first check if there is a list if not just assume one value
		PDBe_list = string.gsub(url_uniprot, ",", "%%20or%%20") --add or's inststead of commas
	else
		PDBe_list = url_uniprot
	end
    
    local PDBe = "["..PDBe_base..PDBe_list.." PDBe] "
    local RCSB = "["..RCSB_base..url_uniprot.." RCSB] "
    
    if string.match(pdbIDs, '%w+') then --if there aren't any PDB_ID don't display this part of the infobox
    	--p.formatRow(title)---how to not close the tags is a mystery and I could condense code once I figure out
    	root
	 		:tag('tr')
        		:tag('td')
   					:attr('colspan', 4)
            		:css('text-align', 'center')
            		:css('background-color', rowBGcolor)
            		:tag('table') 
            			:css('padding', '0')
            			:css('border', 'none')
            			:css('margin', '0')
            			:css('width', '100%')
            			:css('text-align', 'left')
            			:tag('tr')    --create title header
            				:tag('th')
            					:attr('colspan', '4')
            					:css('text-align', 'center')
            					:css('background-color',titleBGcolor)
            					:wikitext(title)
            					:done() --end th
            				:done() --end tr
            			
    					:tag('tr')
        					:tag('th')
        						:attr('rowspan', '2')
        						:css('background-color', sideTitleBGcolor)
        						:css('width', '43px')
         						:wikitext(pdb_link)
        						:done() --end th
            				:tag('td')
            					:attr('colspan', '2')
            					:css('background-color', rowBGcolor)
            					:wikitext(searchTitle)
            					:tag('span')
            						:attr('class', 'plainlinks')
            						:wikitext(PDBe)
            						:wikitext(RCSB)
            						:done() --end span
            					:done() --end td
            				:done() --end tr
           		
            			:tag('tr') --new row for collapsible list of PDB codes
            				:tag('td')
            					:tag('table')
            						:attr('class', 'collapsible collapsed')
            						:css('padding', '0')
            						:css('border', 'none')
            						:css('margin', '0')
            						:css('width', '100%')
            						:css('text-align', 'left')
            						:tag('tr')
            							:css('background-color',titleBGcolor)
            							:css('text-align', 'center')
            							:tag('th')
            								:attr('colspan', '2')
            								:wikitext(listTitle)
            								:done() --end th
            							:done() --end tr
            						:tag('tr')
            							:tag('td')
            								:attr('colspan', '2')
            								:css('background-color', rowBGcolor)
            								:tag('p')
            									:tag('span')
            										:attr('class', 'plainlinks')
            										:wikitext(pdbIDs)
            										:done() --end span
            									:done() --end p
            								:done() --end td
            							:done() --end tr
            						:done() --end table
            					:done() --end td
            				:done() --end tr
            			:done() --end table
            		:done() --end td
            	:done() --end tr
    else
    	return ""
	end

end

p.renderIdentifiers = function(aliases, hgnc_id, gene_symbol, homologene_id, omim_id, mgi_id, ChEMBL_id, IUPHAR_id, ec_no, entrez_gene)
	local title = "Identifiers" --**lclz**
	local label_aliases = "[[Gene nomenclature|Aliases]]" --**lclz**
	local symbol_url 
	if gene_symbol == "" or gene_symbol == nil  then
		symbol_url = ""
	else
		if hgnc_id == "" or hgnc_id == nil  then
			symbol_url = gene_symbol
			
		else
			symbol_url = "[https://www.genenames.org/data/gene-symbol-report/#!/hgnc_id/"..hgnc_id.." "..gene_symbol.."]"
		end
    end

	-- *lclz*: see getAliases. You can, say, use another punctuation for your language.
    aliases = string.gsub(aliases, ', '..gene_symbol..'$', '') --get rid of gene name if last in alias list
    aliases = string.gsub(aliases, gene_symbol..', ', '') --get rid of gene name if first in aliases list
    aliases = string.gsub(aliases, ', '..gene_symbol..',', ',') --get rid of gene name if in aliases list
    aliases = string.gsub(aliases, ", ,", ",") --remove comma from middle
    aliases = string.gsub(aliases, ", $", "") --remove comma from end
	local label_ext_id = "External IDs" --**lclz**
	
	omim_id = string.gsub(omim_id, "%s", "")
	local omim_list = mw.text.split(omim_id, ",")
	local omim = ""
	if (omim_id ~= nil and omim_id ~= "") then
		omim = "[[Mendelian_Inheritance_in_Man|OMIM:]]".." " --**lclz**
	end
	for i, v in ipairs(omim_list) do
		if string.match(v, '%w+') then
			omim = omim.."[https://omim.org/entry/"..v.." "..v.."], "
		end
	end
	omim = string.gsub(omim, ", $"," ")	--remove comma from end
	
	homologene_id = string.gsub(homologene_id, "%s", "")
	local homolo_list = mw.text.split(homologene_id, ",")
	local homolo =""
	if (homologene_id ~= nil and homologene_id ~= "") then
		homolo = "[[HomoloGene|HomoloGene:]]".." "
	end
	for i, v in ipairs(homolo_list) do
		if string.match(v, '%w+') then
			homolo = homolo.."[https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=homologene&dopt=HomoloGene&list_uids="..v.." "..v.."] "
		end
	end
	homolo = string.gsub(homolo, ", $"," ")	--remove comma from end

	
	local genecards = "[[GeneCards|GeneCards:]]".." "
	genecards = genecards.."[https://www.genecards.org/cgi-bin/carddisp.pl?gene="..gene_symbol.." "..gene_symbol.."] "

	mgi_id = string.gsub(mgi_id, "%s", "")
	local mgi_list = mw.text.split(mgi_id, ",")
	local mgi = "" 
	if (mgi_id ~= nil and mgi_id ~= "") then
		mgi = "[[Mouse_Genome_Informatics|MGI:]]".." " --**lclz**
	end
	for i, v in ipairs(mgi_list) do
		if string.match(v, '%w+') then
			local mgi_number = string.sub(mgi_id, 5)
			mgi = mgi.."[http://www.informatics.jax.org/marker/"..mgi_id.." "..mgi_number.."] "
		end
	end
	mgi = string.gsub(mgi, ", $"," ")--remove comma from end

	local ChEMBL = ""
	if string.match(ChEMBL_id, '%w+') then
		ChEMBL = "[[ChEMBL|ChEMBL:]]".." ".."[https://www.ebi.ac.uk/chembldb/index.php/target/inspect/CHEMBL"..ChEMBL_id.." "..ChEMBL_id.."] "
	end
	local IUPHAR = ""
	if string.match(IUPHAR_id, '%w+') then 
		IUPHAR = "[[International_Union_of_Basic_and_Clinical_Pharmacology|IUPHAR:]]".." ".."[http://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId="..IUPHAR_id.." "..IUPHAR_id.."] " --**lclz**
	end -- *lclz*
	local label_EC = "[[Enzyme_Commission_number|EC number]]" --**lclz**
	ec_no = string.gsub(ec_no, "%d%.%d+%.%d+%.%-,", "")--remove those with"-" in list
	ec_no = string.gsub(ec_no, "%d%.%d+%.%d+%.%-", "")--remove those with"-" not in list
	local link_ec_no = string.gsub(ec_no, "," ,"+") --create format for link

	local EC = "[https://www.genome.jp/dbget-bin/www_bget?enzyme+" .. link_ec_no .. " " .. ec_no .. "]"
	
	root
		:tag('tr')
        	:tag('th')
        		:attr('colspan', '4')
        		:css('text-align', 'center')
        		:css('background-color', titleBGcolor)
         		:wikitext(title)
        		:done() --end th
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(label_aliases)
        			:done() --end span
        		:done() --end th
   
        		:tag('td')
        			:attr('colspan','3')
        			:css('background', rowBGcolor)
        			:tag('span')
            		 	:attr('class', 'plainlinks')
        			 	:wikitext(symbol_url)
        				:done() --end span
        			:wikitext(aliases)
        			:done() --end td
        		:done() --end tr		
         	:done() --end tr
         	
        :tag('tr')
         	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
         		:wikitext(label_ext_id)
    			:done() --end th
        	:tag('td')
        		:attr('colspan', '3')
        		:css('background-color', rowBGcolor)
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(omim)
        			:wikitext(mgi)
        			:wikitext(homolo)
        			:wikitext(ChEMBL)
        			:wikitext(IUPHAR)
        			:wikitext(genecards)
        			:done() --end span
        		 :done() --end td
        	:done() --end tr

	if ec_no ~= ""  then
	  root
      	:tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
         		:wikitext(label_EC)
        		:done() --end th
        	:tag('td')
        		:attr('colspan', '3')
        		:css('background-color', rowBGcolor)
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(EC)
        			:done() --end span
				:done() --end td
			:done() --end tr
    end
end

p.renderDiseases = function(frame, disease, dis_ref, name, qid) 
	local title = "Genetically Related Diseases" --**lclz**

	--check first to see if any of the diseases have references
	local ref_flag_all = false --check if any disease have references if not then don't render the headers
	local disease_name = '' --local disease_name = table.concat(disease, ", ")
	for index,value in ipairs(disease) do
		if (dis_ref[index] ~= nil and dis_ref[index] ~= '') then
			if disease_name == '' then
				disease_name = value
			else
				disease_name = disease_name..", "..value -- *lclz*: punctuation
			end
			ref_flag_all = true
		end		
	end
    if ref_flag_all then
    	root
			:tag('tr')
				:tag('td')
   					:attr('colspan', 4)
            		:css('text-align', 'center')
            		:css('background-color', rowBGcolor)
					:tag('tr') --create title bar
						:tag('th')
							:attr('colspan', '3')
							:css('text-align', 'center')
							:css('background-color', titleBGcolor)
							:wikitext(title)
							:done() --end th
						:done() --end tr
					:done() --end td
				:done() --end tr

	
			    
		local ref_url =   "https://www.wikidata.org/wiki/"..qid.."#P2293" --direct page to property genetically associated disease
		local title = "Diseases that are genetically associated with "..name.." view/edit references on wikidata"
		local ref_link = disease_name..frame:extensionTag("ref",frame:expandTemplate{ title = 'cite_web', args = { title = title, url = ref_url} })

		root
			:tag('tr')
	   			:attr('colspan', 4)
	            :css('text-align', 'center')
	            :css('background-color', rowBGcolor)
				:tag('td')
					:css('background-color', rowBGcolor)
					:attr('scope', 'row')
					:attr('colspan', '3')
					:wikitext(ref_link)
					:done() --end td 
	        	:done() --end tr
    end			
    
end

 
p.renderDrug = function(frame,drug, drug_ref, drug_pqid, drug_pname) 
	local title = "Targeted by Drug" --**lclz**

    --check first to see if any of the drugs have references
	local ref_flag_all = false --check if any drugs have references if not then don't render the headers
	drug_list_per_protein = {} -- a list of lists of drugs to put in reference string each protein will have a list 
	--for i,v in ipairs(drug_pqid) do -- set all lists keys to empty so can append without key errors 
		
	--end
	for index,value in ipairs(drug) do
		if (drug_ref[index] ~= nil and drug_ref[index] ~= '') then
			protein_qid = drug_pqid[index]
			if drug_list_per_protein[protein_qid] == '' or drug_list_per_protein[protein_qid] == nil then
				drug_list_per_protein[protein_qid] = value
			else
				-- *lclz*: comma
			    drug_list_per_protein[protein_qid] = drug_list_per_protein[protein_qid]..', '..value --each list of drugs keyed on protein qid 
			end
			ref_flag_all = true
		end		
	end

    if ref_flag_all then
    	root
			:tag('tr')
				:tag('td')
   					:attr('colspan', 4)
            		:css('text-align', 'center')
            		:css('background-color', rowBGcolor)
					:tag('tr') --create title bar
						:tag('th')
							:attr('colspan', '3')
							:css('text-align', 'center')
							:css('background-color', titleBGcolor)
							:wikitext(title)
							:done() --end th
						:done() --end tr
					:done() --end td
				:done() --end tr

    	--loop to create reference links from drug lists
    	for k,v in pairs(drug_list_per_protein) do
        	local drug_name = v
	    	local ref_url =   "https://www.wikidata.org/wiki/"..k.."#P129" --direct page to property genetically associated disease
        	local title = "Drugs that physically interact with "..drug_pname[k].." view/edit references on wikidata"
	    	local ref_link = drug_name..frame:extensionTag("ref",frame:expandTemplate{ title = 'cite_web', args = { title = title, url = ref_url} })
				
		  	root
		    	:tag('tr')
   					:attr('colspan', 4)
            		:css('text-align', 'center')
            		:css('background-color', rowBGcolor)
					:tag('td')
						:css('background-color', rowBGcolor)
						:attr('scope', 'row')
						:attr('colspan', '3')
						:wikitext(ref_link)
						:done() --end td
	        		:done() --end tr
        end
    end
    
end

p.renderGeneLocation = function(frame, chr, gstart, gend, db, cytoband, ensembl, chr_mm, gstart_mm, gend_mm, db_mm, cytoband_mm, ensembl_mm, name)
		local titleHuman = "Gene location (Human)" --**lclz**
		local titleMouse = "Gene location (Mouse)" --**lclz**
        local label_chr = "[[Chromosome|Chr.]]" --**lclz**
        local label_locus = "[[Locus (genetics)|Band]]" --**lclz**
        local label_gstart = "Start" --**lclz**
        local label_gend = "End" --**lclz**
		local tooltip_arrowSign = "Genomic location for "..name --**lclz**
        local arrowSign_width = 14
		
	if chr ~= "" and gstart ~= "" and gend ~= "" then
		--Chromosome lengths are from GRCh38.p10 https://www.ncbi.nlm.nih.gov/grc/human/data?asm=GRCh38.p10
		--This table is used only for calculating "Where should red-rectangle put?"
		--Curretly, Aug 2017, it seems all gene data, which are stored in Wikidata, have start/end positions based on GRCh38.
		local chrLengthTable = {}
				chrLengthTable["1"] = 248956422
				chrLengthTable["2"] = 242193529 
				chrLengthTable["3"] = 198295559 
				chrLengthTable["4"] = 190214555 
				chrLengthTable["5"] = 181538259 
				chrLengthTable["6"] = 170805979 
				chrLengthTable["7"] = 159345973 
				chrLengthTable["8"] = 145138636 
				chrLengthTable["9"] = 138394717 
				chrLengthTable["10"] = 133797422 
				chrLengthTable["11"] = 135086622 
				chrLengthTable["12"] = 133275309 
				chrLengthTable["13"] = 114364328 
				chrLengthTable["14"] = 107043718 
				chrLengthTable["15"] = 101991189 
				chrLengthTable["16"] = 90338345 
				chrLengthTable["17"] = 83257441 
				chrLengthTable["18"] = 80373285 
				chrLengthTable["19"] = 58617616 
				chrLengthTable["20"] = 64444167 
				chrLengthTable["21"] = 46709983 
				chrLengthTable["22"] = 50818468 
				chrLengthTable["X"] = 156040895 
				chrLengthTable["Y"] = 57227415
				chrLengthTable["MT"] = 16569
		local chrLength = chrLengthTable[chr]
		
		--Different languages have different word order.
		local chrTextTable = {}--**lclz**
				chrTextTable["1"] = "Chromosome 1 (human)"
				chrTextTable["2"] = "Chromosome 2 (human)"
				chrTextTable["3"] = "Chromosome 3 (human)"
				chrTextTable["4"] = "Chromosome 4 (human)"
				chrTextTable["5"] = "Chromosome 5 (human)"
				chrTextTable["6"] = "Chromosome 6 (human)"
				chrTextTable["7"] = "Chromosome 7 (human)"
				chrTextTable["8"] = "Chromosome 8 (human)"
				chrTextTable["9"] = "Chromosome 9 (human)"
				chrTextTable["10"] = "Chromosome 10 (human)"
				chrTextTable["11"] = "Chromosome 11 (human)"
				chrTextTable["12"] = "Chromosome 12 (human)"
				chrTextTable["13"] = "Chromosome 13 (human)"
				chrTextTable["14"] = "Chromosome 14 (human)"
				chrTextTable["15"] = "Chromosome 15 (human)"
				chrTextTable["16"] = "Chromosome 16 (human)"
				chrTextTable["17"] = "Chromosome 17 (human)"
				chrTextTable["18"] = "Chromosome 18 (human)"
				chrTextTable["19"] = "Chromosome 19 (human)" 
				chrTextTable["20"] = "Chromosome 20 (human)"
				chrTextTable["21"] = "Chromosome 21 (human)"
				chrTextTable["22"] = "Chromosome 22 (human)"
				chrTextTable["X"] = "X chromosome (human)"
				chrTextTable["Y"] = "Y chromosome (human)"
				chrTextTable["MT"] = "Mitochondrial DNA (human)"
		local chrText = chrTextTable[chr]
		
		--about the calculation below, see https://en.wikipedia.org/wiki/User:Was_a_bee/Gene#3._Calculation_detail
		local markerWidth = ((gend - gstart) * 294.133 )/ chrLength
		if markerWidth < 2 then
			markerWidth = 2
		else
			markerWidth = math.ceil(markerWidth)
		end
		local markerLocation =  (147.0666 * (gstart + gend) / chrLength ) + 1.6 -  (markerWidth / 2)
		local arrowSignLocation =  markerLocation + (markerWidth / 2) - (arrowSign_width / 2)
		markerLocation = math.floor( markerLocation * 10 + 0.5 ) / 10
		
		
		local source_link_chr = ""
		local source_link_gstart = ""
		local source_link_gend = ""
		if( db == "hg38" ) then
			source_link_chr = frame:extensionTag("ref", "[http://May2017.archive.ensembl.org/Homo_sapiens/Gene/Summary?db=core;g="..ensembl.." GRCh38: Ensembl release 89: "..ensembl.."] - [[Ensembl genome database project|Ensembl]], May 2017", {name = "refGRCh38Ensembl"}) --**lclz**
			source_link_gstart = frame:extensionTag("ref", "", {name = "refGRCh38Ensembl"})
			source_link_gend = frame:extensionTag("ref", "", {name = "refGRCh38Ensembl"})
			elseif( db == "hg37") then			
			source_link_chr = frame:extensionTag("ref", "[http://grch37.ensembl.org/Homo_sapiens/Gene/Summary?db=core;&g="..ensembl.." GRCh37: Ensembl release 89: "..ensembl.."] - [[Ensembl genome database project|Ensembl]], May 2017", {name = "refGRCh37Ensembl"}) --**lclz**	
			source_link_gstart = frame:extensionTag("ref", "", {name = "refGRCh37Ensembl"})
			source_link_gend = frame:extensionTag("ref", "", {name = "refGRCh37Ensembl"})
			else
			source_link = ""
			source_link_gstart = ""
			source_link_gend = ""
		end
		
		local wikitext_for_ideogram_image = "" --wikitext used for showing gene location
		if chr == "MT" then -- wikitext for mitochondrial DNA
			--wikitext_for_ideogram_image  = wikitext_for_ideogram_image.."<div align=\"center\">"
			--wikitext_for_ideogram_image  = wikitext_for_ideogram_image.."<div style=\"position\: relative\; width\: 300px\;\">"
			--wikitext_for_ideogram_image  = wikitext_for_ideogram_image.."[[File:Map of the human mitochondrial genome.svg|300px|"..chrText.."]]"
			--wikitext_for_ideogram_image  = wikitext_for_ideogram_image.."</div>"
			--wikitext_for_ideogram_image  = wikitext_for_ideogram_image.."</div>"
		
		else -- wikitext for autosome and sex chromosome
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."<div align=\"center\">"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."<div style=\"position\: relative\; width\: 300px\;\">"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."[[File:Human chromosome "..chr.." ideogram.svg|300px|"..chrText.."]]"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."<div style=\"position\: absolute\; left\: "..arrowSignLocation.."px\; top\: 2px\; padding\: 0\;\">"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."[[File:HSR 1996 II 3.5e.svg|"..arrowSign_width.."px|"..tooltip_arrowSign.."]]</div>"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."<div style=\"position\: absolute\; left\: "..markerLocation.."px\; top\: 19px\; padding\: 0\;\">[[File:Red rectangle "..markerWidth.."x18.png|"..markerWidth.."px|"..tooltip_arrowSign.."]]</div>"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."</div>"
			wikitext_for_ideogram_image = wikitext_for_ideogram_image.."</div>"
		end
		
	root
		:tag('tr')
        	:tag('td')
   				:attr('colspan', 4)
            	:css('text-align', 'center')
            	:css('background-color', rowBGcolor)
            	:tag('table')
            		:attr('class', 'collapsible expand')
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'left')
					:tag('tr')
						:tag('th')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', titleBGcolor)
							:wikitext(titleHuman)
							:done() --end th
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:wikitext("[[File:Ideogram human chromosome "..chr..".svg|300px|"..chrText.."]]")
							:done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:attr('width', '15%')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_chr)
							:done() --end th
						:tag('td')
							:attr('colspan', '3')
							:attr('width', '85%')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext("[["..chrText.."]]"..source_link_chr)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:wikitext(wikitext_for_ideogram_image)
							:done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:attr('rowspan', '2')
							:attr('width', '15%')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_locus)
							:done() --end th
						:tag('td')
							:attr('rowspan', '2')
							:attr('width', '35%')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(cytoband)
								:done() --end span
							 :done() --end td
						:tag('th')
							:attr('scope', 'row')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_gstart)
							:done() --end th
						:tag('td')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(p.separateWithComma(gstart).." [[Base pair|bp]]"..source_link_gstart)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_gend)
							:done() --end th
						:tag('td')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(p.separateWithComma(gend).." [[Base pair|bp]]"..source_link_gend)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:done() --end table
				 :done() --end td
			:done() --end tr
	end
	
	if chr_mm ~= "" and gstart_mm ~= "" and gend_mm ~= "" then
		--Chromosome lengths are from GRCm38.p5 https://www.ncbi.nlm.nih.gov/grc/mouse/data?asm=GRCm38.p5
		local chrLengthTable_mm = {}
				chrLengthTable_mm["1"] = 195471971
				chrLengthTable_mm["2"] = 182113224
				chrLengthTable_mm["3"] = 160039680
				chrLengthTable_mm["4"] = 156508116
				chrLengthTable_mm["5"] = 151834684
				chrLengthTable_mm["6"] = 149736546 
				chrLengthTable_mm["7"] = 145441459 
				chrLengthTable_mm["8"] = 129401213 
				chrLengthTable_mm["9"] = 124595110 
				chrLengthTable_mm["10"] = 130694993 
				chrLengthTable_mm["11"] = 122082543 
				chrLengthTable_mm["12"] = 120129022
				chrLengthTable_mm["13"] = 120421639 
				chrLengthTable_mm["14"] = 124902244
				chrLengthTable_mm["15"] = 104043685
				chrLengthTable_mm["16"] = 98207768
				chrLengthTable_mm["17"] = 94987271 
				chrLengthTable_mm["18"] = 90702639 
				chrLengthTable_mm["19"] = 61431566 
				chrLengthTable_mm["X"] = 171031299
				chrLengthTable_mm["Y"] = 91744698
				chrLengthTable_mm["MT"] = 16299
		local chrLength_mm = chrLengthTable_mm[chr_mm]
			
		--Different languages have different word order.
		local chrTextTable_mm = {}--**lclz**
				chrTextTable_mm["1"] = "Chromosome 1 (mouse)"
				chrTextTable_mm["2"] = "Chromosome 2 (mouse)"
				chrTextTable_mm["3"] = "Chromosome 3 (mouse)"
				chrTextTable_mm["4"] = "Chromosome 4 (mouse)"
				chrTextTable_mm["5"] = "Chromosome 5 (mouse)"
				chrTextTable_mm["6"] = "Chromosome 6 (mouse)"
				chrTextTable_mm["7"] = "Chromosome 7 (mouse)"
				chrTextTable_mm["8"] = "Chromosome 8 (mouse)"
				chrTextTable_mm["9"] = "Chromosome 9 (mouse)"
				chrTextTable_mm["10"] = "Chromosome 10 (mouse)"
				chrTextTable_mm["11"] = "Chromosome 11 (mouse)"
				chrTextTable_mm["12"] = "Chromosome 12 (mouse)"
				chrTextTable_mm["13"] = "Chromosome 13 (mouse)"
				chrTextTable_mm["14"] = "Chromosome 14 (mouse)"
				chrTextTable_mm["15"] = "Chromosome 15 (mouse)"
				chrTextTable_mm["16"] = "Chromosome 16 (mouse)"
				chrTextTable_mm["17"] = "Chromosome 17 (mouse)"
				chrTextTable_mm["18"] = "Chromosome 18 (mouse)"
				chrTextTable_mm["19"] = "Chromosome 19 (mouse)" 
				chrTextTable_mm["X"] = "X chromosome (mouse)"
				chrTextTable_mm["Y"] = "Y chromosome (mouse)" 
				chrTextTable_mm["MT"] = "Mitochondrial DNA (mouse)" 
		local chrText_mm = chrTextTable_mm[chr_mm]
		
		--about the calculation below, see https://en.wikipedia.org/wiki/User:Was_a_bee/Gene#3._Calculation_detail
		local markerWidth_mm = ((gend_mm - gstart_mm) * 294.133 )/ chrLength_mm
		if markerWidth_mm < 2 then
			markerWidth_mm = 2
		else
			markerWidth_mm = math.ceil(markerWidth_mm)
		end
		local markerLocation_mm =  (147.0666 * (gstart_mm + gend_mm) / chrLength_mm ) + 1.6 -  (markerWidth_mm / 2)
		local arrowSignLocation_mm =  markerLocation_mm + (markerWidth_mm / 2) - (arrowSign_width / 2)
		markerLocation_mm = math.floor( markerLocation_mm * 10 + 0.5 ) / 10
		local source_link_chr_mm = ""
		local source_link_gstart_mm = ""
		local source_link_gend_mm = ""
		if( db_mm == "mm10" or db_mm == "mm0") then
			--"mm0" happens because of function "getAliasFromGenomeAssembly()" is not prepared for mouse data.
			--But as of now, Aug. 2017, it seems that all data which is stored in Wikidata are based on GRCm38/mm10.
			--So treating mouse genomic data as GRCm38/mm10 if not specified.
			source_link_chr_mm = frame:extensionTag("ref", "[http://May2017.archive.ensembl.org/Mus_musculus/Gene/Summary?db=core;g="..ensembl_mm.." GRCm38: Ensembl release 89: "..ensembl_mm.."] - [[Ensembl genome database project|Ensembl]], May 2017", {name = "refGRCm38Ensembl"}) --**lclz**	
			source_link_gstart_mm = frame:extensionTag("ref", "", {name = "refGRCm38Ensembl"}) 
			source_link_gend_mm = frame:extensionTag("ref", "", {name = "refGRCm38Ensembl"}) 
			else
			source_link_chr_mm = ""
			source_link_gstart_mm = ""
			source_link_gend_mm = ""
		end
		local wikitext_for_ideogram_image_mm = "" --wikitext used for showing gene location
		if chr_mm == "MT" then -- wikitext for mitochondrial DNA
			--wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div align=\"center\">"
			--wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div style=\"position\: relative\; width\: 300px\;\">"
			--wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."[[File:Map of the human mitochondrial genome.svg|300px|"..chrText_mm.."]]"
			--wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."</div>"
			--wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."</div>"
		
		else -- wikitext for autosome and sex chromosome
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div align=\"center\">"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div style=\"position\: relative\; width\: 300px\;\">"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."[[File:Ideogram of house mouse chromosome "..chr_mm..".svg|300px|"..chrText_mm.."]]"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div style=\"position\: absolute\; left\: "..arrowSignLocation_mm.."px\; top\: 2px\; padding\: 0\;\">"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."[[File:HSR 1996 II 3.5e.svg|"..arrowSign_width.."px|"..tooltip_arrowSign.."]]</div>"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."<div style=\"position\: absolute\; left\: "..markerLocation_mm.."px\; top\: 19px\; padding\: 0\;\">[[File:Red rectangle "..markerWidth_mm.."x18.png|"..markerWidth_mm.."px|"..tooltip_arrowSign.."]]</div>"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."</div>"
			wikitext_for_ideogram_image_mm = wikitext_for_ideogram_image_mm.."</div>"
		end
		
	root	
		:tag('tr')
        	:tag('td')
   				:attr('colspan', 4)
            	:css('text-align', 'center')
            	:css('background-color', rowBGcolor)
            	:tag('table')
            		:attr('class', 'collapsible collapsed')
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'left')
					:tag('tr')
						:tag('th')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', titleBGcolor)
							:wikitext(titleMouse)
							:done() --end th
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:wikitext("[[File:Ideogram house mouse chromosome "..chr_mm..".svg|260px|"..chrText_mm.."]]")
							:done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:attr('width', '15%')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_chr)
							:done() --end th
						:tag('td')
							:attr('colspan', '3')
							:attr('width', '85%')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(chrText_mm..source_link_chr_mm)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:wikitext(wikitext_for_ideogram_image_mm)
							:done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:attr('rowspan', '2')
							:attr('width', '15%')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_locus)
							:done() --end th
						:tag('td')
							:attr('rowspan', '2')
							:attr('width', '35%')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(cytoband_mm)
								:done() --end span
							:done() --end td
						:tag('th')
							:attr('scope', 'row')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_gstart)
							:done() --end th
						:tag('td')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(p.separateWithComma(gstart_mm).." [[Base pair|bp]]"..source_link_gstart_mm)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:tag('tr')
						:tag('th')
							:attr('scope', 'row')
							:css('background-color', sideTitleBGcolor)
							:wikitext(label_gend)
							:done() --end th
						:tag('td')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(p.separateWithComma(gend_mm).." [[Base pair|bp]]"..source_link_gend_mm)
								:done() --end span
							 :done() --end td
						:done() --end tr
					:done() --end table
				 :done() --end td
			:done() --end tr
	end
end

p.renderRNAexpression = function(expression_images, entrez_gene)
	local title = "[[Gene expression|RNA expression]] pattern" --**lclz**
	local biogps_link = "[http://biogps.org/gene/"..entrez_gene.."/ More reference expression data]" --**lclz**
	root
		:tag('tr')
        	:tag('td')
   				:attr('colspan', 4)
            	:css('text-align', 'center')
            	:css('background-color', rowBGcolor)
            	:tag('table')
            		:attr('class', 'collapsible expand')
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'left')
					:tag('tr')
						:tag('th')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', titleBGcolor)
							:wikitext(title)
							:done() --end th
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:wikitext(expression_images)
							:done() --end td
						:done() --end tr
					:tag('tr')
						:tag('td')
							:attr('colspan', '4')
							:css('text-align', 'center')
							:css('background-color', rowBGcolor)
							:tag('span')
								:attr('class', 'plainlinks')
								:wikitext(biogps_link)
								:done() --end span
							:done() --end td
						:done() --end tr
					:done() --end table
				:done() --end td
			:done() --end tr
end

p.renderGeneOntology = function(mol_funct, cell_comp, bio_process, uniprotID)
	local title = "[[Gene_ontology|Gene ontology]]" --**lclz**
	local mol_funct_title = "Molecular function" --**lclz**
	local cell_comp_title = "Cellular component" --**lclz**
	local bio_process_title = "Biological process" --**lclz**
	local amigo_link = "[http://amigo.geneontology.org/" .. " Amigo]"
	local quickGO_link = "[https://www.ebi.ac.uk/QuickGO/" .. " QuickGO]"


	root
		:tag('tr')
        	:tag('td')
   				:attr('colspan', 4)
            	:css('text-align', 'center')
            	:css('background-color', rowBGcolor)
            	:tag('table')
            		:attr('class', 'collapsible collapsed')
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'left')
            		:tag('tr') --create title bar
        				:tag('th')
        					:attr('colspan', '4')
        					:css('text-align', 'center')
        					:css('background-color', titleBGcolor)
         					:wikitext(title)
        					:done() --end th
        				:done() --end tr
        			:tag('tr')
            			:tag('th')
            				:css('background-color', sideTitleBGcolor)
            				:wikitext(mol_funct_title)
            				:done() --end th
            			:tag('td')
            				:css('background-color', rowBGcolor)
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(mol_funct)
            					:done() --end span
            				:done() --end td
           				:done() --end tr
        			:tag('tr')
        				:tag('th')
            				:css('background-color', sideTitleBGcolor)
            				:wikitext(cell_comp_title)
            				:done() --end th
            			:tag('td')
            				:css('background-color', rowBGcolor)
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(cell_comp)
            					:done() --end span
            				:done() --end td
            			:done() --end tr
        			:tag('tr')
        				:tag('th')
            				:css('background-color', sideTitleBGcolor)
            				:wikitext(bio_process_title)
            				:done() --end th
            			:tag('td')
            				:css('background-color', rowBGcolor)
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(bio_process)
            					:done() --end span
            				:done() --end td
            			:done() --end tr
					
        			:tag('tr')
            			:tag('td')
            				:css('background-color', rowBGcolor)
            				:css('text-align', 'center')
            				:attr('colspan', '4')
            				:wikitext("Sources:")
            				:wikitext(amigo_link)
            				:wikitext(" / ")
            				:wikitext(quickGO_link)
            				:done() --end td
       					:done() --end tr
					:done() --end table
				:done() --end td
			:done() --end tr
end 

p.renderOrthologs = function(frame, entrez_gene, entrez_gene_mm, ensembl, ensembl_mm, uniprot, uniprot_mm, refseq_mRNA, refseq_mRNA_mm, refseq_prot, refseq_prot_mm, db, chr, gstart, gend,  db_mm, chr_mm,gstart_mm, gend_mm) 
	local title = "[[Ortholog|Orthologs]]" --**lclz**
	--to do make the list creation a function
	--create list for entrez ids
	
	
	local category_chromosome = '[[Category:Genes on human chromosome '..chr..']]'-- *lclz*: Category name
	if chr == "MT" then
		category_chromosome = '[[Category:Human mitochondrial genes]]'-- *lclz*: Category name for mtDNA genes
	end
	if mw.title.getCurrentTitle().namespace ~= 0 then
		category_chromosome = ""
	end
	local entrezTitle = "[[Entrez|Entrez]]"
	entrez_gene = string.gsub(entrez_gene, "%s", "")
	local entrez_link = "n/a"
	local entrez_collapse 
	local entrez_default = ""
	local split_entrez = mw.text.split(entrez_gene, ",")
	local entrez_link_list = {}
	for k,v in ipairs(split_entrez) do 
		if string.match(v, '%w+') and v ~= "n/a" then
			entrez_link_list[#entrez_link_list+1] = "[https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&amp;cmd=retrieve&amp;dopt=default&amp;list_uids="..entrez_gene.."&amp;rn=1 "..entrez_gene.."]"
		end
	end
	--if less than 5 don't create collapsible list
	if  table.getn(entrez_link_list) < 5 then
		entrez_collapse = "none"
		if entrez_default == nil and table.getn(entrez_link_list) == 0 then entrez_link = "n/a" end
	else	
		entrez_collapse = "collapsible collapsed"
		entrez_default = table.remove(entrez_link_list, 1) .. '<br>' .. table.remove(entrez_link_list, 1) .. '<br>' ..table.remove(entrez_link_list, 1) .. '<br>' .. table.remove(entrez_link_list, 1) .. '<br>' .. table.remove(entrez_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	if entrez_link_list[#entrez_link_list] then
		entrez_link = table.concat(entrez_link_list, "<br>")
	end
	
	--create list for mouse Entrez id
	entrez_gene_mm = string.gsub(entrez_gene_mm, "%s", "")
	local entrez_mm_link = "n/a"
	local entrez_mm_collapse 
	local entrez_mm_default = ""
	local split_entrez_mm = mw.text.split(entrez_gene_mm, ",")
	local entrez_mm_link_list = {}
	for k,v in ipairs(split_entrez_mm) do 
		if string.match(v, '%w+') and v ~= "n/a" then
			entrez_mm_link_list[#entrez_mm_link_list+1] = "[https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&amp;cmd=retrieve&amp;dopt=default&amp;list_uids="..v.."&amp;rn=1 "..v.."]"
		end
	end
	--if less than 5 don't create collapsible list
	if  table.getn(entrez_mm_link_list) < 5 then
		entrez_mm_collapse = "none"
		if entrez_mm_default == nil and table.getn(entrez_mm_link_list) == 0 then entrez_mm_link = "n/a" end
	else	
		entrez_mm_collapse = "collapsible collapsed"
		entrez_mm_default = table.remove(entrez_mm_link_list, 1) .. '<br>' .. table.remove(entrez_mm_link_list, 1) .. '<br>' ..table.remove(entrez_mm_link_list, 1) .. '<br>' .. table.remove(entrez_mm_link_list, 1) .. '<br>' .. table.remove(entrez_mm_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	if entrez_mm_link_list[#entrez_mm_link_list] then
		entrez_mm_link = table.concat(entrez_mm_link_list, "<br>")
	end
	
	--create list of ensembl id
	local ensemblTitle = "[[Ensembl|Ensembl]]"
	ensembl = string.gsub(ensembl, "%s", "")
	local ensembl_link = "n/a"
	local ensembl_collapse 
	local ensembl_default = ""
	local split_ensembl = mw.text.split(ensembl, ",")
	local ensembl_link_list = {}
	for k,v in ipairs(split_ensembl) do 
		if string.match(v, '%w+') and v ~= "n/a" then
			ensembl_link_list[#ensembl_link_list+1] = "[http://www.ensembl.org/Homo_sapiens/geneview?gene="..v..";db=core".." "..v.."]"
		end
	end
	--if less than 5 don't create collapsible list
	if  table.getn(ensembl_link_list) < 5 then
		ensembl_collapse = "none"
		if ensembl_default == nil and table.getn(ensembl_link_list) == 0 then ensembl_link = "n/a" end
	else	
		ensembl_collapse = "collapsible collapsed"
		ensembl_default = table.remove(ensembl_link_list, 1) .. '<br>' .. table.remove(ensembl_link_list, 1) .. '<br>' ..table.remove(ensembl_link_list, 1) .. '<br>' .. table.remove(ensembl_link_list, 1) .. '<br>' .. table.remove(ensembl_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	if ensembl_link_list[#ensembl_link_list] then
		ensembl_link = table.concat(ensembl_link_list, "<br>")
	end
	
	--create list of mouse ensembl id
	local ensemblTitle = "[[Ensembl|Ensembl]]"
	ensembl_mm = string.gsub(ensembl_mm, "%s", "")
	local ensembl_mm_link = "n/a"
	local ensembl_mm_collapse 
	local ensembl_mm_default = ""
	local split_ensembl_mm = mw.text.split(ensembl_mm, ",")
	local ensembl_mm_link_list = {}
	for k,v in ipairs(split_ensembl_mm) do 
		if string.match(v, '%w+') and v ~= "n/a" then
			ensembl_mm_link_list[#ensembl_mm_link_list+1] = "[http://www.ensembl.org/Mus_musculus/geneview?gene="..v..";db=core".." "..v.."]"
		end
	end
	--if less than 5 don't create collapsible list
	if  table.getn(ensembl_mm_link_list) < 5 then
		ensembl_mm_collapse = "none"
		if ensembl_mm_default == nil and table.getn(ensembl_mm_link_list) == 0 then ensembl_mm_link = "n/a" end
	else	
		ensembl_mm_collapse = "collapsible collapsed"
		ensembl_mm_default = table.remove(ensembl_mm_link_list, 1) .. '<br>' .. table.remove(ensembl_mm_link_list, 1) .. '<br>' ..table.remove(ensembl_mm_link_list, 1) .. '<br>' .. table.remove(ensembl_mm_link_list, 1) .. '<br>' .. table.remove(ensembl_mm_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	if ensembl_mm_link_list[#ensembl_mm_link_list] then
		ensembl_mm_link = table.concat(ensembl_mm_link_list, "<br>")
	end


	--create lists of uniprot ID
	local uniprotTitle = "[[UniProt|UniProt]]"
	local uniprot_url = "https://www.uniprot.org/uniprot/"
	
	local uniprot_link = "n/a"
	local uniprot_collapse
	local uniprot_default = ""
	--split string and loop through concatenate by <br>
	local split_uniprot = mw.text.split(uniprot, ",")
	local uniprot_link_list = {}
	local uniprot_first = {} --preferred values only display [O,P,Q] prefixed entries if they exist
	local uniprot_alternate = {} --[A-N,R-Z] entries
	local hash = {} --storage to look for duplicated values 
	for k,v in ipairs(split_uniprot) do 
		if not hash[v] then --only add if not found previously..some encodes uniprotID dup in different encodes
			local label = mw.text.trim(v)
			local concat_uniprot_link = uniprot_url .. label
			if string.match(v, '%w+') and v ~= "n/a" then
				if string.match(v, '^O') or string.match(v,'^P') or string.match(v, '^Q') then
				    uniprot_first[#uniprot_first+1] = "[" .. concat_uniprot_link .. " " ..label .. "]"
				else
					uniprot_alternate[#uniprot_alternate+1] = "[" .. concat_uniprot_link .. " " ..label .. "]"
				end
			end
			hash[v] = true
		end
	end
    if table.getn(uniprot_first)>0 then --if there is something in the preferred values display else display anything else
		uniprot_link_list  = uniprot_first
	else
		uniprot_link_list  = uniprot_alternate
	end
	
	--if less than 5 don't create collapsible list
	if  table.getn(uniprot_link_list) < 5 then
		uniprot_collapse = "none"
		if uniprot_default == nil and table.getn(uniprot_link_list) == 0 then uniprot_link = "n/a" end
	else	
		uniprot_collapse = "collapsible collapsed"
		uniprot_default = table.remove(uniprot_link_list, 1) .. '<br>' .. table.remove(uniprot_link_list, 1) .. '<br>' ..table.remove(uniprot_link_list, 1) .. '<br>' .. table.remove(uniprot_link_list, 1) .. '<br>' .. table.remove(uniprot_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	
	if uniprot_link_list[#uniprot_link_list] then
		uniprot_link = table.concat(uniprot_link_list, "<br>")
	end
	
    --mouse uniprot lists
	local uniprot_mm_link = "n/a"
	local uniprot_mm_collapse
	local uniprot_mm_default = ""
	--split string and loop through concatenate by <br>
	local split_uniprot_mm = mw.text.split(uniprot_mm, ",")
    local uniprot_mm_link_list = {}	
    local uniprot_mm_first = {} --preferred values only display [O,P,Q] prefixed entries if they exist
    local uniprot_mm_alternate = {} --[A-N,R-Z] entries
    local hash = {} --storage to look for duplicated values
	for k,v in ipairs(split_uniprot_mm) do 
	    if not hash[v] then --only add if not found previously..some encodes uniprotID dup in different encodes
		    local label = mw.text.trim(v)
		    local concat_uniprot_link = uniprot_url .. label
		    if string.match(v, '%w+') and v ~= "n/a" then
			    if string.match(v, '^O') or string.match(v,'^P') or string.match(v, '^Q') then 
					uniprot_mm_first[#uniprot_mm_first+1] = "[" .. concat_uniprot_link .. " " ..label .. "]"
				else
					uniprot_mm_alternate[#uniprot_mm_alternate+1] = "[" .. concat_uniprot_link .. " " ..label .. "]"
				end
		    end
			hash[v] = true
		end
	end
	if table.getn(uniprot_mm_first)>0 then --if there is something in the preferred values display else display anything else
		uniprot_mm_link_list  = uniprot_mm_first
	else
		uniprot_mm_link_list  = uniprot_mm_alternate
	end

	--if less than 5 don't create collapsible list
	if  table.getn(uniprot_mm_link_list) < 5 then
		uniprot__mm_collapse = "none"
		if uniprot_mm_default == nil and table.getn(uniprot_mm_link_list) == 0 then uniprot_mm_link = "n/a" end
	else	
		uniprot_mm_collapse = "collapsible collapsed"
		uniprot_mm_default = table.remove(uniprot_mm_link_list, 1) .. '<br>' .. table.remove(uniprot_mm_link_list, 1) .. '<br>' ..table.remove(uniprot_mm_link_list, 1) .. '<br>' .. table.remove(uniprot_mm_link_list, 1) .. '<br>' .. table.remove(uniprot_mm_link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	
	if uniprot_mm_link_list[#uniprot_mm_link_list] then
		uniprot_mm_link = table.concat(uniprot_mm_link_list, "<br>")
	end
	
	
	
	local ncbi_link = "https://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val="
	local refseq_mRNATitle = "RefSeq (mRNA)" -- *lclz*: sometimes
	
	--create list of links for refSeq mRNA
	local refseq_mRNA_link = "n/a"
	local refseq_mRNA_collapse
	local refseq_mRNA_default = ""
	--split string and loop through concatenate by <br>
	local split_refseq_mRNA = mw.text.split(refseq_mRNA, ",")
	local link_list_first = {} --hold those the have NM or NP values
	local link_list_alternate = {} --hold those that are XM or XP values
	local link_list = {} --if NM,NP display if not display XM, XP values 
	for k,v in ipairs(split_refseq_mRNA) do
		local label = mw.text.trim(v)
		local concat_ncbi_link = ncbi_link .. label
		if string.match(v, '%w+') and v ~= "n/a" then
			if string.match(v, 'NM') or string.match(v, 'NP') then
			    link_list_first[#link_list_first+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			elseif string.match(v, 'XM') or string.match(v, 'XP') then
				link_list_alternate[#link_list_alternate+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			end
		end
   end
   	if table.getn(link_list_first)>0 then
		link_list = link_list_first
	else
		link_list = link_list_alternate
	end
	
	--if less than 5 don't create collapsible list
	if  table.getn(link_list) < 6 then
		refseq_mRNA_collapse = "none"
		if refseq_mRNA_default == nil and table.getn(link_list) == 0 then refseq_mRNA_link = "n/a" end
	else	
		refseq_mRNA_collapse = "collapsible collapsed"
		refseq_mRNA_default  = table.remove(link_list, 1) .. '<br>' .. table.remove(link_list, 1) .. '<br>' ..table.remove(link_list, 1) .. '<br>' .. table.remove(link_list, 1) .. '<br>' .. table.remove(link_list, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	
	if link_list[#link_list] then
		refseq_mRNA_link = table.concat(link_list, "<br>")
	end
	
	
	--create list of links for refSeq mRNA for mouse
	local refseq_mRNA_mm_link = "n/a"
	local refseq_mRNA_mm_collapse
	local refseq_mRNA_mm_default = ""
	local split_refseq_mRNA_mm = mw.text.split(refseq_mRNA_mm, ",")
	local link_list_mm = {} --if NM,NP display if not display XM, XP values
	local link_list_first = {} --hold those the have NM or NP values
	local link_list_alternate = {} --hold those that are XM or XP values
  
	for k,v in ipairs(split_refseq_mRNA_mm) do
		local label = mw.text.trim(v)
		local concat_ncbi_link = ncbi_link .. label
		if string.match(v, '%w+') and v ~= "n/a" then
			if string.match(v, 'NM') or string.match(v, 'NP') then
			    link_list_first[#link_list_first+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			elseif string.match(v, 'XM') or string.match(v, 'XP') then
				link_list_alternate[#link_list_alternate+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			end
		end
    end
	if table.getn(link_list_first)>0 then
		link_list_mm = link_list_first
	else
		link_list_mm = link_list_alternate
	end
	--if less than 5 don't create collapsible list
	if  table.getn(link_list_mm) < 6 then
		refseq_mRNA_mm_collapse = "none"
		if refseq_mRNA_mm_default == nil and table.getn(link_list_mm) == 0 then refseq_mRNA_mm_link = "n/a" end
	else	
		refseq_mRNA_mm_collapse = "collapsible collapsed"
		refseq_mRNA_mm_default = table.remove(link_list_mm, 1) .. '<br>' .. table.remove(link_list_mm, 1) .. '<br>' ..table.remove(link_list_mm, 1) .. '<br>' .. table.remove(link_list_mm, 1) .. '<br>' .. table.remove(link_list_mm, 1) .. '<br>'--get first 5 elements in table and use for display
	end

	if link_list_mm[#link_list_mm] then
		refseq_mRNA_mm_link = table.concat(link_list_mm, "<br>")
	end
	
    -- *lclz*: sometimes
	local refseq_protTitle = "RefSeq (protein)"
	--create list of links for human refseq protein
	local refseq_prot_link = "n/a"
	local refseq_prot_collapse 
	local refseq_prot_default = ""
	local split_refseq_prot = mw.text.split(refseq_prot, ",")
	local link_list_prot = {}
    local link_list_first = {} --hold those the have NM or NP values
	local link_list_alternate = {} --hold those that are XM or XP values
	for k,v in ipairs(split_refseq_prot) do
		local label = mw.text.trim(v)
		local concat_ncbi_link = ncbi_link .. label
		if string.match(v, '%w+') and v ~= "n/a" then
			if string.match(v, 'NM') or string.match(v, 'NP') then
			    link_list_first[#link_list_first+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			elseif string.match(v, 'XM') or string.match(v, 'XP') then
				link_list_alternate[#link_list_alternate+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			end
		end
	end
	if table.getn(link_list_first)>0 then
		link_list_prot  = link_list_first
	else
		link_list_prot  = link_list_alternate
	end
	--if less than 5 don't create collapsible list
	if  table.getn(link_list_prot) < 6 then
		refseq_prot_collapse  = "none"
		if refseq_prot_default == nil and table.getn(link_list_prot) == 0 then refseq_prot_link = "n/a" end
	else	
		refseq_prot_collapse = "collapsible collapsed"
		refseq_prot_default = table.remove(link_list_prot, 1) .. '<br>' .. table.remove(link_list_prot, 1) .. '<br>' ..table.remove(link_list_prot, 1) .. '<br>' .. table.remove(link_list_prot, 1) .. '<br>' .. table.remove(link_list_prot, 1) .. '<br>'--get first 5 elements in table and use for display
	end

   
	if link_list_prot[#link_list_prot] then
		refseq_prot_link = table.concat(link_list_prot, "<br>")
	end
	
	
	--create list of links for mouse refseq protein
	local refseq_prot_mm_link = "n/a"
	local refseq_prot_mm_collapse
	local refseq_prot_mm_default = ""
	local split_refseq_prot_mm = mw.text.split(refseq_prot_mm, ",")
	local link_list_prot_mm = {}
	local link_list_first = {} --hold those the have NM or NP values
	local link_list_alternate = {} --hold those that are XM or XP values
  
	for k,v in ipairs(split_refseq_prot_mm) do
		local label = mw.text.trim(v)
		local concat_ncbi_link = ncbi_link .. label
		if string.match(v, '%w+') and v ~= "n/a" then
			if string.match(v, 'NM') or string.match(v, 'NP') then
			    link_list_first[#link_list_first+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			elseif string.match(v, 'XM') or string.match(v, 'XP') then
				link_list_alternate[#link_list_alternate+1] = "[" .. concat_ncbi_link .. " " ..label .. "]"
			end
		end
	end
	if table.getn(link_list_first)>0 then
		link_list_prot_mm  = link_list_first
	else
		link_list_prot_mm  = link_list_alternate
	end
	--if less than 5 don't create collapsible list
	if  table.getn(link_list_prot_mm) < 6 then
		refseq_prot_mm_collapse  = "none"
		if refseq_prot_mm_default == nil and table.getn(link_list_prot_mm) == 0 then refseq_prot_mm_link = "n/a" end
	else	
		refseq_prot_mm_collapse = "collapsible collapsed"
		refseq_prot_mm_default = table.remove(link_list_prot_mm, 1) .. '<br>' .. table.remove(link_list_prot_mm, 1) .. '<br>' ..table.remove(link_list_prot_mm, 1) .. '<br>' .. table.remove(link_list_prot_mm, 1) .. '<br>' .. table.remove(link_list_prot_mm, 1) .. '<br>'--get first 5 elements in table and use for display
	end
	if link_list_prot_mm[#link_list_prot_mm] then
		refseq_prot_mm_link = table.concat(link_list_prot_mm, "<br>")
	end
	

	local locTitle = "Location (UCSC)" -- *lclz*
	local gstart_mb = p.locToMb(gstart, 2)
	local gend_mb = p.locToMb(gend, 2)
	local chr_loc_link =  ""
	if (string.match(db, '%w+') and string.match(chr, '%w+') and string.match(gstart, '%w+') and string.match(gend, '%w+') )then
		local chr_ucsc 
		if chr == "MT" then  
			chr_ucsc = "M" --UCSC uses "M" (not "MT") in URL for mitochondrial DNA
		else
			chr_ucsc = chr
		end	
		chr_loc_link = "[https://genome.ucsc.edu/cgi-bin/hgTracks?org=Human&db="..db.."&position=chr"..chr_ucsc..":"..gstart.."-"..gend.." ".."Chr "..chr_ucsc..": "..gstart_mb.." – "..gend_mb.." Mb]" 
	else
		chr_loc_link = "n/a"	
	end
	local gstart_mm_mb = p.locToMb(gstart_mm, 2)
	local gend_mm_mb = p.locToMb(gend_mm, 2)
	local chr_loc_mm_link = ""
	if (string.match(db_mm, '%w+') and string.match(chr_mm, '%w+') and string.match(gstart_mm, '%w+') and string.match(gend_mm, '%w+') )then
		local chr_mm_ucsc 
		if chr_mm == "MT" then  
			chr_mm_ucsc = "M" --UCSC uses "M" (not "MT") in URL for mitochondrial DNA
		else
			chr_mm_ucsc = chr_mm
		end
		chr_loc_mm_link =  "[https://genome.ucsc.edu/cgi-bin/hgTracks?org=Mouse&db="..db_mm.."&position=chr"..chr_mm_ucsc..":"..gstart_mm.."-"..gend_mm.." ".."Chr "..chr_mm_ucsc..": "..gstart_mm_mb.." – "..gend_mm_mb.." Mb]"
	else
		chr_loc_mm_link = "n/a"	
	end

	local pubmedTitle = "[[PubMed|PubMed]] search" -- *lclz*
	local pubmed_link = entrez_gene
	if string.match(entrez_gene, '%w+') and entrez_gene ~= "n/a" then
		pubmed_link = frame:extensionTag("ref",frame:expandTemplate{ title = 'cite_web', args = { title ="Human PubMed Reference:" , url = "https://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=Link&LinkName=gene_pubmed&from_uid="..entrez_gene, website = "National Center for Biotechnology Information, U.S. National Library of Medicine" } } )--expandTemplate creates cite web template {{cite web|title=value|url=ref_link..ect}} 
	end
	local pubmed_mm_link = entrez_gene_mm
	if string.match(entrez_gene_mm, '%w+') and entrez_gene_mm ~= "n/a" then
		pubmed_mm_link = frame:extensionTag("ref",frame:expandTemplate{ title = 'cite_web', args = { title ="Mouse PubMed Reference:" , url ="https://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=Link&LinkName=gene_pubmed&from_uid="..entrez_gene_mm, website = "National Center for Biotechnology Information, U.S. National Library of Medicine" } } )--expandTemplate creates cite web template {{cite web|title=value|url=ref_link..ect}}
	end
	
	root
		:tag('tr')
        	:tag('th')
        		:attr('colspan', '4')
        		:css('text-align', 'center')
        		:css('background-color', titleBGcolor)
         		:wikitext(title)
        		:done() --end th
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext("Species") --**lclz**
        		:done() --end th
        	:tag('td')
        		:wikitext("'''Human'''") --**lclz**
        		:done() --end td
        	:tag('td')
        		:wikitext("'''Mouse'''") --**lclz**
        		:done() --end td
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(entrezTitle)
        		:done() --end th
        	:tag('td')
        		:tag('table')
            		:attr('class', entrez_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(entrez_default)
            					:done() --end span
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(entrez_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
			:tag('td')
        		:tag('table')
            		:attr('class', entrez_mm_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(entrez_mm_default)
            					:done() --end span
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(entrez_mm_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
            :done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(ensemblTitle)
        		:done() --end th
        	:tag('td')
        		:tag('table')
            		:attr('class', ensembl_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(ensembl_default)
            					:done() --end span
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(ensembl_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
			:tag('td')
        		:tag('table')
            		:attr('class', ensembl_mm_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(ensembl_mm_default)
            					:done() --end span
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(ensembl_mm_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
            :done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(uniprotTitle)
        		:done() --end th
        	:tag('td')
        		:tag('table')
            		:attr('class', uniprot_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(uniprot_default)
            					:done() --end span
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(uniprot_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
        	:tag('td')
        		:tag('table')
            		:attr('class', uniprot_mm_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:tag('span')
            					:attr('class', 'plainlinks')
            					:wikitext(uniprot_mm_default)
            					:done() --end span
            				:done() --end th
            			:done() --end th
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:attr('class', 'plainlinks')
            					:wikitext(uniprot_mm_link)
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
        		:done() --end td
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(refseq_mRNATitle)
        		:done() --end th
        	:tag('td') --RNASeq mRNA collapsible table 
        		:tag('table')
            		:attr('class', refseq_mRNA_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:attr('class', 'plainlinks')
            				:wikitext(refseq_mRNA_default)
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:tag('span')
            						:attr('class', 'plainlinks')
            						:wikitext(refseq_mRNA_link)
            						:done() --end span
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td	
        	:tag('td') --RNASeq mRNA collapsible table for mouse 
        		:tag('table')
            		:attr('class', refseq_mRNA_mm_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:attr('class', 'plainlinks')
            				:wikitext(refseq_mRNA_mm_default)
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:tag('span')
            						:attr('class', 'plainlinks')
            						:wikitext(refseq_mRNA_mm_link)
            						:done() --end span
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table	
        		:done() --end td
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(refseq_protTitle)
        		:done() --end th
        	:tag('td') --RNASeq protein collapsible table 
        		:tag('table')
            		:attr('class', refseq_prot_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:attr('class', 'plainlinks')
            				:wikitext(refseq_prot_default)
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:tag('span')
            						:attr('class', 'plainlinks')
            						:wikitext(refseq_prot_link)
            						:done() --end span
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td	
			:tag('td') --RNASeq protein collapsible table for mouse
        		:tag('table')
            		:attr('class', refseq_prot_mm_collapse)
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'right')
            		:tag('tr')
            			:tag('th')
            				:attr('colspan', '1')
            				:attr('class', 'plainlinks')
            				:wikitext(refseq_prot_mm_default)
            				:done() --end th
            			:done() --end tr
            		:tag('tr')
            			:tag('td')
            				:attr('colspan', '1')
            				:tag('p')
            					:tag('span')
            						:attr('class', 'plainlinks')
            						:wikitext(refseq_prot_mm_link)
            						:done() --end span
            					:done() --end p
            				:done() --end td
            			:done() --end tr
            		:done() --end table
            	:done() --end td
    		:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(locTitle)
        		:done() --end th
        	:tag('td')
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(chr_loc_link)
        			:done() --end span
        		:done() --end td
        	:tag('td')
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(chr_loc_mm_link)
        			:done() --end span
        		:done() --end td
        	:done() --end tr
        :tag('tr')
        	:tag('th')
        		:attr('scope', 'row')
        		:css('background-color', sideTitleBGcolor)
        		:wikitext(pubmedTitle)
        		:done() --end th
        	:tag('td')
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(pubmed_link)
        			:done() --end span
        		:done() --end td
        	:tag('td')
        		:tag('span')
            		:attr('class', 'plainlinks')
        			:wikitext(pubmed_mm_link)
        			:done() --end span
        		:wikitext(category_chromosome)
        		:done() --end td
    		:done() --end tr
end

p.formatRow = function(title)
	 root
	 	:tag('tr')
        	:tag('td')
   				:attr('colspan', '4')
            	:css('text-align', 'center')
            	:css('background-color', rowBGcolor)
            	:tag('table') 
            		:css('padding', '0')
            		:css('border', 'none')
            		:css('margin', '0')
            		:css('width', '100%')
            		:css('text-align', 'left')
            		:tag('tr')    --create title header
            			:css('background-color',titleBGcolor)
            			:css('text-align', 'center')
            			:tag('th')
            				:attr('colspan',"2")
            				:wikitext(title)
            				:done() --end th
            			:done() --end tr
            		:done() --end table
            	:done() --end td
            :done() --end tr
end

p.renderFooter = function(Qid, Qid_mm)
 local text = "[[Wikidata|Wikidata]]" --**lclz**
 local hs_link = "[[d:"..Qid.."|View/Edit Human]]" --**lclz**
 local mm_link = ""
 local link_no_hs
 local link_no_mm
 
 if Qid_mm == "" then
 	link_no_mm = 0
 	link_no_hs = 4
 else 
 	link_no_mm = 2
 	link_no_hs = 2
 	mm_link = "[[d:"..Qid_mm.."|View/Edit Mouse]]" --**lclz**
 end
 
 root
 	:tag('tr')
 		:tag('td')
 			:attr('colspan', '4')
 			:css('text-align', 'center')
 			:css('font-size','x-small')
 			:css('background-color', rowBGcolor)
 			:wikitext(text)
 			:done() --end td
       :tag('tr')
 		:tag('td')
 			:attr('colspan', '4')
 			:css('text-align', 'center')
 			:css('font-size','x-small')
 			:css('background-color', rowBGcolor)
 		:tag('table')
          	:css('padding', '0')
          	:css('border', 'none')
          	:css('margin', '0')
          	:css('width', '100%')
          	:css('text-align', 'center')
 			:tag('tr')
 				:tag('td')
 					:attr('colspan', link_no_hs)
 					:css('background-color', rowBGcolor)
 					:css('text-align', 'center')
					:css('font-size','x-small')
					:wikitext(hs_link)
					:done() --end td
				:tag('td')
 					:attr('colspan', link_no_mm)
 					:css('background-color', rowBGcolor)
 					:css('text-align', 'center')
					:css('font-size','x-small')
					:wikitext(mm_link)
					:done() --end td
				:done() --end tr
			:done() --end table
		:done() --end tr
	root:done() --end root table
end


--this code isn't used was hoping could do some generalization of rows
p.rowLabel=function(label)
	root
	    :tag('tr')
        :tag('th')
        	:attr('rowspan', '2')
        	:css('background-color', sideTitleBGcolor)
        	:css('width', '43px')
         	:wikitext(label)
        	--:done()
end

-- look into entity object
p.getLabel = function(entity)
	local data = entity

	local f = {'labels','en','value'}

	local i = 1
	while true do
		local index = f[i]
		if not index then
			if type(data) == "table" then
				return mw.text.jsonEncode(data, mw.text.JSON_PRESERVE_KEYS + mw.text.JSON_PRETTY)
			else
				return tostring(data)
			end
		end
		
		data = data[index] or data[tonumber(index)]
		if not data then
			return
		end
		
		i = i + 1
	end
end



--general function to get value given an entity and property
p.getValue = function(entity, propertyID, return_val)

	local claims
	if return_val == nil then return_val = "" end
    local sep = " " --could ad as input parameter if need be
	if entity and entity.claims then
		claims = entity.claims[propertyID]
	end
	if claims then
		-- if wiki-linked value output as link if possible
		if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
			local out = {}
			for k, v in pairs(claims) do
				local datav = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				if datav == nil then datav = " " end 
				out[#out + 1] = datav			
			end
			return table.concat(out, sep)
		else
		-- just return best values
			return entity:formatPropertyValues(propertyID).value
		end
	else
		return return_val
	end
end

p.getValueProtein = function(protein_entities, propertyID, return_val)
	if return_val == nil then return_val = "" end
	local sep = ","
    local overall_results = {} --should return empty if nothing assigned
	for key, val in pairs(protein_entities) do --in cases where there are multiple encodes we loop through each and return concatenated data as a whole
		local claims
		local entity = val --each protein in encodes
		if entity and entity.claims then
			claims = entity.claims[propertyID]
		end
		if claims then
			local results
			-- if wiki-linked value output as link if possible
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				local out = {}
				for k, v in pairs(claims) do
					local datav = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
					if datav == nil then datav = " " end 
					out[#out + 1] = datav			
				end
				results = table.concat(out, sep)
			else
				results = entity:formatPropertyValues(propertyID).value
			end
			overall_results[#overall_results+1] = results --individual propertyID value stored in this index	
		end
	end

	local str_overall_results = table.concat(overall_results, sep) --weirdness happens when add a sep = " " otherwise each value represented one time
	if string.match(str_overall_results, '%w+') then
		return str_overall_results 
	else
		return return_val
	end
end


--general function to get value given an entity and property
p.getQid = function(entity)
	local Qid
	if entity and entity.id then
		Qid = entity.id
		return Qid
	else
		return ""
	end
end

--get random value that is preferred ranked 
-- *lclz*: Sometimes Wikibase returns punctuations other than "," depending on
--         your site's language. Consider adding a gsub here.
p.getRefseq_mRNA = function(entity, propertyID, return_val)
	if return_val == nil then return_val = "" end
	local input_rank = "RANK_PREFERRED" ---this is mostly like won't do anything because ranking isn't maintained in wikidata 
	local claims
	
	if entity.claims then
		claims = entity.claims[propertyID]
	end
	if claims then
		-- if wiki-linked value output as link if possible
		if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid" ) then
			local out = {}
			for k, v in pairs(claims) do
				local sitelink = mw.wikibase.sitelink("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				local label = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				if label == nil then label = "Q" .. v.mainsnak.datavalue.value["numeric-id"] end
							
				if sitelink then
					out[#out + 1] = "[[" .. sitelink .. "|" .. label .. "]]"
				else
					out[#out + 1] = "[[:d:Q" .. v.mainsnak.datavalue.value["numeric-id"] .. "|" .. label .. "]]"
				end
			end
			return table.concat(out, ", ")
		else
			local results = entity:formatPropertyValues(propertyID, mw.wikibase.entity.claimRanks).value 
			
			--loop through results until get a NP or NM or just return whatever is in first element
			--[[local results_split = mw.text.split(results, ",")
			
			local preffered_results = " "
			if results_split[1] then
				preferred_result = mw.text.trim(results_split[1]) --return first element if desired prefix not found and remove whitespace
			end
			local id --refseq id in question
			for i, id in ipairs(results_split) do
				local trim_id = mw.text.trim(id)
  				if string.match( trim_id, '^NM_%d+') then 
  					preferred_result = trim_id --overwrite each time found only need one to display
  				end
			end
			if preferred_result then
				return preferred_result --return a id starting with NP or NM
			else
				return return_val --return first element because desired prefix not found and remove whitespaces
			end
			--]]
			return results
		end
	else
		return return_val
	end
end

-- *lclz*: same as getRefseq_mRNA
p.getRefseq_protein = function(protein_entities, propertyID, return_val)
local sep = ","
local overall_results = {} --should return empty if nothing assigned

	for key, val in pairs(protein_entities) do --in cases where there are multiple encodes we loop through each and return concatenated data as a whole
	
		local claims
		local entity = val --each protein in encodes
		if entity.claims then
			claims = entity.claims["P637"]
		end
		if claims then
			local results
			-- if wiki-linked value output as link if possible
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid" ) then
				local out = {}
				for k, v in pairs(claims) do
					local datav = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
					if datav == nil then datav = " " end 
					out[#out + 1] = datav			
				end
				results = table.concat(out, sep)
			else
				results = entity:formatPropertyValues("P637", mw.wikibase.entity.claimRanks).value 
			end
			overall_results[#overall_results+1] = results --a list is in each index 
		end	
		
	end
	--why are there duplicate results here
	local str_overall_results = table.concat(overall_results, sep)
	return str_overall_results

end
	--[[
	local results_split = mw.text.split(str_overall_results, sep) --split complete list so can loop through..probably a more direct way to do this
				--loop through results until get a NP or NM or just return whatever is in first element
	

	local preffered_result = results_split[1] or ""

	for i, id in ipairs(results_split) do
		local trim_id = mw.text.trim(id)
		--check of id starts with NP or NM
		if string.match( trim_id, '^NP_%d+') then 
			preferred_result = trim_id --overwrite each time found only need one to display
		end
	end
	--check if something in preffered_result if not get first element in result_split
	if p.isempty(preffered_result) then
		return return_val
	else
		return preferred_result --return a id starting with NP or NM
	end

end --]]

--gets an image
p.getImage = function(entity, propertyID, sep, imgsize)
  
 	local claims
  
 	if entity and entity.claims then  
 		claims = entity.claims[propertyID]  
 	end
  
 	if claims then
 		if (claims[1] and claims[1].mainsnak.datatype == "commonsMedia") then  
 			local out = {}  
 			for k, v in pairs(claims) do  
 				local filename = v.mainsnak.datavalue.value  
 				out[#out + 1] = "[[File:" .. filename .. "|" .. imgsize .. "]]" 
 			end   
 				return table.concat(out, sep)   
 		else   
 			return ""   
 		end   
	else   
 		return ""   
 	end   
end

p.getPDB = function(protein_entities)
	local pdb_propertyID = "P638"
	local overall_results = {}
	for key, val in pairs(protein_entities) do --in cases where there are multiple encodes we loop through each and return concatenated data as a whole
		local claims
		local entity = val
		if entity and entity.claims then
			claims = entity.claims[pdb_propertyID]
		end
		local sitelink = "https://www.rcsb.org/structure/"
		if claims then
			local results
			if (claims[1] and claims[1].mainsnak.snaktype == "value") then
			
			
				local out = {}
				for k, v in pairs(claims) do
					local label = mw.wikibase.label(v.mainsnak.datavalue.value)
					if label == nil then label = v.mainsnak.datavalue.value end
				
					if sitelink then
						out[#out + 1] = "[" .. sitelink .. label .. " " ..label .. "]"
					else
						out[#out + 1] = "[[:d:Q" .. v.mainsnak.datavalue.value .. "|" .. label .. "]]"
					end
				end
				results = table.concat(out, ", ") -- *lclz*: punctuation (CJK comma, etc.)
			else
				results = entity:formatPropertyValues(propertyID, mw.wikibase.entity.claimRanks).value
			end
			overall_results[#overall_results+1] = results --individual propertyID values stored in this index
		end
	end
	return table.concat(overall_results, ",%%s")
end

function p.getAliases(entity)
	a = ''
	if entity['aliases'] ~= nil then
		-- *lclz*: You will need a different language here.
		--         If you are aiming for an "en" fallback, consider a set data structure.
		
		-- zhwp went a bit further here: they moved this call after "gene_symbol",
		-- so that this function can perform the deduplication here instead of
		-- in renderIdentifiers. That way they skip messing with commas and spaces.
        local test = entity['aliases']['en']
        if test then
			for key, value in ipairs(test) do
				a = a .. ', ' ..  value['value']
			end
			return a
		else
			return ""
		end
	else
		return ""
	end
	
end


--get a geneome start P644 or end P645
p.getChromosomeLoc = function(entity, propertyID, prefix)
	-- will contain the numeric value for the requested coordinate
	local output = ""
	local sep = " "
	-- can only be P644 (genomic start) or P645 (genomic end) for this to work
	-- should probably try to catch that.  Might also increase legibility to use specific variable names when possible
--	local propertyID = mw.text.trim(frame.args[1] or "") 
	-- this can really only be P659 right now.  I'm not sure of the value of including it as a parameter as other values will likely break this function
	local qualifierID = "P659" --mw.text.trim(frame.args[2] or "")
	-- Why do we include this here?  What should happen if FETCH_WIKIDATA is not included? 
	--local input_parm = mw.text.trim(frame.args[3] or "")
	-- this can needs to be fed to the function either by a call to {{#invoke:Wikidata|pageId}} or by setting it directly (e.g. if the function was applied on a page other than the targeted gene)
	--alert if this id is not a valid thing in wikidata, a Lua error will occur that says
	--The ID entered is unknown to the system. Please use a valid entity ID.
	--local itemID = mw.text.trim(frame.args[4] or "")
	-- will track the different builds pulled from the qualifiers
	local newest_build = "0"
	-- starts the process
	--local entity = mw.wikibase.getEntityObject(itemID)
	local claims
	--gets a table of claims on the (genomic start or end) property Q19847637
	if entity and entity.claims then
		claims = entity.claims[propertyID]
	end
	--will return nothing if no claims are found
	if claims then
		--checking to be sure claims is populated, not sure it its needed
		if (claims[1] ) then
			--useful for debugging
			--local out = {}
			--pulls the genome location from the claim
			for k, v in pairs(claims) do
				local location = v.mainsnak.datavalue.value
				--debugging
				--out[#out + 1] = k.." location:" .. location.. " || " 
				--gets the qualifiers linked to the current claim
				local quals 
				if v.qualifiers then
					quals = v.qualifiers.P659
				end
				--if there are any
				if quals then
					for qk, qv in pairs(quals) do
						local qual_obj_id = "Q"..qv.datavalue.value["numeric-id"]
						--get to the entity targeted by the qualifier property.  Genome builds are Items in wikidata
						local qual_obj = mw.wikibase.getEntityObject(qual_obj_id)
						local alias = ""
						--this uses the aliases to pull out version numbers
						--seems like there ought to be a better way to do this, but likely would need to change the data added by the bot
						if qual_obj["aliases"] ~= nil then
							local test = qual_obj["aliases"]["en"]
							for key, value in ipairs(test) do
								if string.match(value['value'], prefix) then
									alias = value['value']
									local build_no = alias:gsub(prefix,"")
									--report only the most location associated with the most recent build
									--if there is more than one location per build, just give one back as that is not our problem right now.
									if build_no > newest_build then
										output = location
										newest_build = build_no
									end
								end
							end
						end
					end
				--in case there are no qualifiers, but there is a location, might as well return it
				else output = location 
				end
			end
				return output
		else
			return ""
		end
	else
		return ""
		--debug
		--"no claims for "..itemID.." prop "..propertyID
	end
end

p.getAliasFromGenomeAssembly = function(entity, prefix)
	-- will contain the numeric value for the requested coordinate
	local output = ""
	local sep = " "
	local propertyID = "P644" --genomic start used 
	local qualifierID = "P659" --genomic assembly

	local newest_build = "0"
	local claims
	if entity.claims then
	 claims = entity.claims[propertyID]
	end
	--will return nothing if no claims are found
	if claims then
		--checking to be sure claims is populated, not sure it its needed
		if (claims[1] ) then
			--useful for debugging
			--local out = {}
			--pulls the genome location from the claim
			for k, v in pairs(claims) do
				local quals
				if v.qualifiers then
					quals = v.qualifiers.P659
				end
				--if there are any
				--as of Aug. 2017, P659-genomic assembly is stored only in human genomic data. GRCh38 (newer) or GRCh37(older).
				--Mouse genomic data doesn't have P659-genomic assembly data. But mouse has only one version. GRCm38/mm10.
				if quals then
					for qk, qv in pairs(quals) do
						local qual_obj_id = "Q"..qv.datavalue.value["numeric-id"]
						--get to the entity targeted by the qualifier property.  Genome builds are Items in wikidata
						local qual_obj = mw.wikibase.getEntityObject(qual_obj_id)
						local alias = ""
						--this uses the aliases to pull out version numbers
						--seems like there ought to be a better way to do this, but likely would need to change the data added by the bot
						if qual_obj["aliases"] ~= nil then
							local test = qual_obj["aliases"]["en"]
							for key, value in ipairs(test) do
								if string.match(value['value'], prefix) then
									alias = value['value']
									local build_no = alias:gsub(prefix,"")
									--For example, prefix is "hg" (this is set when the function was called),
									--alias is "hg38" (which is data stored in Wikidata). Then "build_no" becomes "38".
									--report only the most location associated with the most recent build
									--if there is more than one location per build, just give one back as that is not our problem right now.
									if build_no > newest_build then
										newest_build = build_no
									end
								end
							end
						end
					end
				--in case there are no qualifiers, but there is a location, might as well return it
				else output = location 
				end
			end
				return prefix..newest_build
		else
			return ""
		end
	else
		return ""
	end
end

-- *lclz*: Your language's wikidata may have different nouns for chromosome and
--         mitochodria.
p.trimChromosome = function(entity)
	local string_to_trim = p.getValue(entity, "P1057")
	local out = ''
	
	--"mitochondrion" and "chromosome MT" is used for mitochondrial DNA.
	--See [[d:Special:WhatLinksHere/Q18694495]]
	if string.find(string_to_trim, 'chromosome MT') or string.find(string_to_trim, 'mitochondri') then --match both 'mitochondrio'/'mitochondrial'
		out = "MT"
	elseif string.find(string_to_trim, 'chromosome') then
		out = string.match(string_to_trim, "%d+")--extract number from string
		if out == nil then
			out = string.match(string_to_trim, "X") or string.match(string_to_trim, "Y")
		end
	end
	return out	
end

p.locToMb = function(num, idp)
  num = tonumber(num)
  if num == nil then 
  	return ""
  else
  	local mb = num/1000000
  	local mult = 10^(idp or 0)
  	return math.floor(mb * mult + 0.5) / mult
  end
end

p.isempty = function(s)
  	return s == nil or s == ''
end


p.getGO = function(protein_entities, propertyID)
	--propertyID ie molecular, cellular, function
	
	local overall_results = {}
	local results = "" --string to return
	
	for key, val in pairs(protein_entities) do
	
		local claims
		local entity = val
		if entity.claims then
			claims = entity.claims[propertyID] -- ie molecular, cellular, function
		end
		local propertyID_child = "P686" -- Gene Ontology ID
		
		if claims then
			
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				--local out = {}
				for k, v in pairs(claims) do
					local itemID_child = "Q" .. v.mainsnak.datavalue.value["numeric-id"] --get Qid of property item so can get the GOid
					local entity = mw.wikibase.getEntityObject(itemID_child)
					local claims
					local result_GOID = ''
					if entity and entity.claims then claims = entity.claims[propertyID_child] end
					if claims then
						result_GOID = entity:formatPropertyValues(propertyID_child, mw.wikibase.entity.claimRanks).value
					else
						result_GOID = nil --no GO ID
					end
					local sitelink = "http://amigo.geneontology.org/amigo/term/"
					local label = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
					if label == nil then label = "Q" .. v.mainsnak.datavalue.value["numeric-id"] end
					local wiki_link	= ""
					if sitelink and result_GOID ~= nil then
						wiki_link = "<big>•</big> [" .. sitelink .. result_GOID .. " " .. label .."]<br>"
					else
						wiki_link = "<big>•</big> [[:d:Q" .. v.mainsnak.datavalue.value["numeric-id"] .. "|" .. label .. "]]<br>"
					end
					overall_results[#overall_results+1] = wiki_link
				end
				
			else
				results = entity:formatPropertyValues(propertyID, mw.wikibase.entity.claimRanks).value
			end
			
		end
		--overall_results[#overall_results+1] = results --each protein GO terms stored in this index, so table contains all the GO terms with duplicates 
	end

	local hash = {} --temp check
	local res = {} --no dups

	for _,v in ipairs(overall_results) do
   		if (not hash[v]) then
       		res[#res+1] = v 
       		hash[v] = true
   		end
	end
	return table.concat(res, "")
end

local function getReference(qID, entity, property_id, ref_index)
	local f = {"claims",property_id, ref_index, "references"} 
	local id = qID
	--if id and (#id == 0) then
	--	id = nil
	--end
	local data = entity
	if not data then
		return nil
	end
	
    
	local i = 1
	while true do
		local index = f[i]
		if not index then
			if type(data) == "table" then
				return mw.text.jsonEncode(data, mw.text.JSON_PRESERVE_KEYS + mw.text.JSON_PRETTY)
			else
				return tostring(data)
			end
		end
		
		data = data[index] or data[tonumber(index)]
		if not data then
			return ""
		end
		i = i + 1
	end
end

p.getDisease= function(entity, propertyID)
    local claims
	if return_val == nil then return_val = "" end
	if entity and entity.claims then
		claims = entity.claims[propertyID]
	end
	if claims then
		-- if wiki-linked value output as link if possible
		
		if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then

			local out = {}
			local datasource = {}
			--{{#invoke:Wikidata |ViewSomething |id=Q18023174 |claims|P2293|1|references|1|snaks|P854|1|datavalue|value}}
			--maybe there is a more direct way to find this than looping through the json object
			
			for k, v in pairs(claims) do
				local datav = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				
				if datav == nil then datav = " " end 
			   
				local id = "Q" .. v.mainsnak.datavalue.value["numeric-id"]
				local linkTarget = mw.wikibase.sitelink(id)
				local refLink = ""
				local ref = ""
				ref = getReference("", entity, "P2293", k)
				if (ref ~= nil and ref ~= '') then
				     --refLink = refLink..","..ref
				     refLink = ref
				end
		    
                --if refLink = "" then --skip if there isn't a reference found
				
				if linkTarget then
					out[#out + 1] = "[["..linkTarget.."|"..datav.."]]"
				else
					out[#out + 1] = "[[:d:" .. id .. "|" .. datav .. "]]"
				end
				datasource[#out] = refLink
				--end				
			end
			return out, datasource
		else
		-- just return best values
			--return entity:formatPropertyValues(propertyID).value
			return return_val, return_val
		end
	else
		return return_val
	end	
   return return_val
end

p.getDrug= function(protein_entities, propertyID)
    local out = {}
	local datasource = {}
	local pname = {}
	local pqid = {}


	for key, val in pairs(protein_entities) do
		local claims
		local entity = val
		local name = check_values(p.getLabel,{entity})
		if entity.claims then
			claims = entity.claims[propertyID] -- ie physically interacts with
		end
		local protein_id
		if entity then protein_id = entity.id else protein_id = "" end
		if claims then
			if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
				for k, v in pairs(claims) do
					local datav = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				
					if datav == nil then datav = "" end
					local id = "Q" .. v.mainsnak.datavalue.value["numeric-id"]
					local linkTarget = mw.wikibase.sitelink(id)
					local refLink = ""
					local ref = getReference(protein_id, entity, "P129",k)  --just check if anything returned
					if (ref ~= nil and ref ~= '') then
				    	refLink = ref
				    end
					if linkTarget then
					    out[#out + 1] = "[["..linkTarget.."|"..datav.."]]"
				    else
					    out[#out + 1] = "[[:d:" .. id .. "|" .. datav .. "]]"
				    end
					pname[protein_id] = name
				    pqid[#out] = protein_id
					datasource[#out] = refLink
				end --end k,v claims loop
			end --end claims[1]
		end --if claims
    end -- end protein_entities loop
	return out, datasource, pqid, pname
end

p.separateWithComma= function(bp)
	--Separate number with comma. For example when this function gets "12345678", returns "12,345,678"
  local commaSeparated = bp
  while true do  
    commaSeparated, k = string.gsub(commaSeparated, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return commaSeparated
end

return p