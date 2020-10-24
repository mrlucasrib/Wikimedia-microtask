require('Module:No globals')
-- All Lua modules on Wikipedia must begin by defining a variable that will hold their
-- externally accessible functions. They can have any name and may also hold data.
local p = {}  -- exposed variables
local g = {}  -- these are variables with global scope in this module

local info = {}          -- contains general purpose information (e.g. header background colour)
info.debug  = false -- ONLY SET THIS WHILE TESTING

--local paramData = require( 'Module:Sandbox/Jts1882/Biota Infobox/data' ) -- contains the taxon ranks in order
--local autotaxa = require("Module:Sandbox/Jts1882/Biota Infobox/Autotaxobox")
--local autotaxa = require("Module:Autotaxobox")
local parameters = require( 'Module:Biota infobox/param' ) 
local core = require( 'Module:Biota infobox/core' ) 

-- ######################### PARAMETER HANDLING ############################

local templateArgs = {}  -- contains preprocessed arguments from calling template
                          --TODO use info.args instead of templateArgs?


-- ########################### MAIN AND OTHER ENTRY FUNCTIONS ##################################

--[[ main function callable in Wikipedia via the #invoke command.
        creates a taxobox-style infobox
        handles preliminary parameter handling enulating taxobox and automatic taxobox templates
           -- the parameters are also checked for content, alias, valid names and valid combinations
           -- the parameter handling is in subpage Module:Sandbox/Jts1882/Biota Infobox/param
        these are passed the core function
           -- the core function emulates the template {{Taxobox/core})
           -- the function is found in subpage Module:Sandbox/Jts1882/Biota Infobox/core
           -- the core them creates the taxobox
                 creates main table and header section (with header, subheader and fossil ranges)
	             adds addition rows for template arguments with following subsidiary functions:
			        p.addImageSection() - images and range maps 
			        p.addStatusSection() - conservation status
			        p.addTaxonomySection() - listing of taxonomic heirarchy (manuel or using automatic taxonomy system)
			        p.addTaxonSection() - adds section with taxonomic information (binomial or trinomials; type genus or species; diversity)
			        p.addListSection()     - section containing list if subdivisions, synonyms, included or excluded groups
--]]
p.main = function(frame) 
	
	--p.getArgs(frame)
	parameters.getArgs(frame, templateArgs, info)  -- gets arguments, checks for value, aliases, and against valid parameter list

	if info.auto then
		p.AutomaticTaxoboxOptions(frame) -- this emulates the automatic taxobox templates that feed the core
	else
		--[[TODO manual taxobox options:
		            name or use Template:Taxonomy name |genus|species|binomial name
		            colour = p.getTaxoboxColor(frame)
		]]
	end

	--return p._core(frame)
	return core.core(frame, templateArgs, info)
end

-- this functions emulates Template:automatic taxobox and uses Template:Taxobox/core
p.auto = function(frame) 
	--info.auto = frame.args.auto or "automatictaxobox"
	
	p.getArgs(frame)  -- gets arguments, checks for value, aliases, and against valid parameter list

	if info.auto then
		p.AutomaticTaxoboxOptions(frame) -- this emulates the automatic taxobox templates that feed the core
	end
	
	-- additional parameters needed by Template:Taxobox/core
	templateArgs['edit link']="edit taxonomy"
	templateArgs['colour'] = p.getTaxoboxColor(frame)
    templateArgs['upright'] = templateArgs['image_upright'] or 1   
    templateArgs['upright2'] = templateArgs['image2_upright'] or 1
    
    -- use Template:Taxobox/core
 	return tostring(frame:expandTemplate{ title = 'taxobox/core',  args = templateArgs   } ) 
 	
end

--[[ ##################### CORE FUNCTIONS ###################################

       this core function emulates Template:Taxobox/core 
       it is followed by functions handling the different type of entry
       MOVED to subpage Module:Sandbox/Jts1882/Biota_Infobox/core
]]


-- ################## AUTOMATIC TAXOBOX SYSTEM HANDLING ################################
------------------------------------------------------------------------------------------------
-- handle specific requirements of different options: auto, speciesbox etc
function p.AutomaticTaxoboxOptions(frame)
  
    --TODO replace genus with first word (genus) to strip parenthetic term
    -- done in speciesbox?
    
    
    templateArgs['display_taxa']  = templateArgs['display_parents'] or 1  -- note change of parameter name 
   
    local extinct = ""
 	if  templateArgs['extinct']  then 
		--extinct = "†"
		extinct = frame:expandTemplate{ title = 'extinct' }  -- use template to get tooltip
		-- speciesbox also checks the genus taxonomy template for extinct parameter
    end

    ---------------------variables for SPECIESBOX, SUBSPECIESBOX and INFRASPECIESBOX---------------------
   	if info.auto == "hybridbox" then
   		
   		--templateArgs['parent'] = templateArgs['parent'] or templateArgs['genus'] or templateArgs['genus1']
   		
   		local species1 = templateArgs['species'] or templateArgs['species1'] or templateArgs['father'] or templateArgs['father_species'] or ""
   		local species2 = templateArgs['species2'] or templateArgs['mother'] or templateArgs['mother_species'] or templateArgs['species'] or ""
   		local genus1   = templateArgs['genus'] or templateArgs['genus1']  or templateArgs['father_genus']    -- TODO use page
   		local genus2   = templateArgs['genus2'] or templateArgs['mother_genus']   or templateArgs['genus']
        local species3 = templateArgs['species3'] or ""
        local genus3   = templateArgs['genus3'] or templateArgs['genus'] or ""

        local subspecies1, subspecies2, subspecies3 = "", "", ""
        --if (templateArgs['subspecies1'] and templateArgs['subspecies2'])
        if templateArgs['subspecies1'] or templateArgs['subspecies2'] 
           or (templateArgs['father_subspecies'] and templateArgs['mother_subspecies']) then
        	subspecies1 = " " .. ((templateArgs['subspecies1'] or templateArgs['father_subspecies']) or "")
        	subspecies2 = " " .. ((templateArgs['subspecies2'] or templateArgs['mother_subspecies']) or "")
        	if templateArgs['subspecies3'] then
        		subspecies3 = " " .. templateArgs['subspecies3']
        		species3 = species1
        	end
        end
        
   		local link1    = templateArgs['link1'] or templateArgs['father_link'] or (genus1 .. " " .. species1 .. subspecies1)
   		local link2    = templateArgs['link2'] or templateArgs['mother_link'] or (genus2 .. " " .. species2 .. subspecies2)
        local link3    = templateArgs['link3'] or (genus3 .. " " .. species3 .. subspecies3) 

   		if not templateArgs['parent'] then templateArgs['parent'] =  genus1 end
   		
        
        --TODO disambiguate genus pages -- not needed unless using page name
   		--genus1 = frame:expandTemplate{ title = 'Speciesbox/getGenus' , args = {"", genus1 } }
   	    --	genus2 = frame:expandTemplate{ title = 'Speciesbox/getGenus' , args = {"", genus2 } }
   		
   		if not templateArgs['genus2'] and not templateArgs['father_genus'] then 
   			genus1 = string.sub(genus1,1,1) .. "."   -- shorten generic names for intrageneric hybrids
   			genus2 = string.sub(genus2,1,1) .. "."
   			genus3 = string.sub(genus3,1,1) .. "."
   		end
   		
   		-- shorten species name if subspecies of same species
   		if subspecies1 ~= "" and not templateArgs['species2']  then
   			species1 = string.sub(species1,1,1) .. "."   -- shorten specific epithet for intraspecific hybrids
   			species2 = string.sub(species2,1,1) .. "."
   			if subspecies3 ~= "" then species3 = string.sub(species3,1,1) .. "." end
   		end

   		local maleSymbol, femaleSymbol = "", ""
   		if templateArgs['father'] or templateArgs['father_genus'] or templateArgs['father_species'] or templateArgs['father_subspecies'] then maleSymbol = "♂" end
   		if templateArgs['mother'] or templateArgs['mother_genus'] or templateArgs['mother_species'] or templateArgs['mother_subspecies'] then femaleSymbol = "♀" end
   		
   		templateArgs['hybrid'] = "'''''[[" .. link1 .. "|" .. genus1 .. " " .. species1 .. subspecies1 .."]]'''''" .. maleSymbol 
   		                       .. " × "
   		                       .. "'''''[[" .. link2 .. "|" .. genus2 .. " " .. species2 .. subspecies2 .. "]]'''''" .. femaleSymbol

   		if species3 ~= "" then
   			templateArgs['hybrid'] = templateArgs['hybrid']   .. " × "
   		                       .. "'''''[[" .. link3 .. "|" .. genus3 .. " " .. species3  .. subspecies3 .. "]]'''''" 
   		end
        
     	--templateArgs['hybrid species'] = templateArgs['hybrid']
     	if subspecies1 ~= "" and not templateArgs['species2'] then
     	     templateArgs['species'] = "''[[" .. templateArgs['genus'] .. " " .. templateArgs['species'] .. "|"
     	                                .. genus1 .. " " .. templateArgs['species'] .. "]]''" 
     	else templateArgs['species'] = nil
     	end
     	templateArgs['offset'] = 1
	    
    -- ======================= setup for SPECIESBOX =============================
	
	elseif info.auto == "speciesbox" then
        
        --[[ {{speciesbox}} gets genus and species from taxon, genus+species or page name
                1. uses 'taxon' paramter ( given as binomial) if available
                2. otherwise uses 'genus' and 'species' parameters
                3. uses page name
             the genus is used for the 'parent' taxon 
            	unless the parent is supplied (e.g. for subgenus)
            	else use genus (from taxon or genus parameter or page name)
            	
           {{Speciesbox}} now using {{Speciesbox/getGenus}} and  {Speciesbox/getSpecies}}
                code doing similar is commented out below
           
           TODO use {{{{Speciesbox/name}}
        --]]
       local genus, species = "", ""
       
       genus = frame:expandTemplate{ title = 'Speciesbox/getGenus' , args = {templateArgs['taxon'], templateArgs['genus']} }
       species = frame:expandTemplate{ title = 'Speciesbox/getSpecies' , args = {templateArgs['taxon'], templateArgs['genus']} }
       
		if templateArgs['taxon'] then
           
           -- following line disableas using getGenus/getSpecies templates	       
           -- genus, species = string.match(templateArgs['taxon'], "(%S+)%s(%S+)") -- %S: All characters not in %s
	       
	       templateArgs['genus'] = genus                 
	       templateArgs['species'] = species            
	   
	    elseif templateArgs['genus'] and templateArgs['species'] then
	    	
	    	--[[strip off (disambiguator) to handle multi-kingdom genus e.g.| genus = Acanthocarpus (plant)
	    	local genusParts =mw.text.split( templateArgs['genus'], " ", true )     -- string.match( s, '^%a*'', 1 )
	    	                                    
	    	if genusParts[1] ~= "" then 
	    		--templateArgs['parent']=templateArgs['genus']  -- set parent (NO, parent should override)
	    		genus = genusParts[1] 
	    	end
	    	now handled by getGenus/getSpecies templates --]]
	    	
	    	templateArgs['taxon'] = genus .. ' ' .. templateArgs['species']
	
	    else
	    	-- TODO no valid taxon yet; use page name
	    	-- use first word of pagename - handled by {{Speciesbox/getGenus}}
	    end
    
        if not templateArgs['parent'] or templateArgs['parent'] == "" then
        	templateArgs['parent'] = templateArgs['genus']       -- set parent to genus if not supplied
        end
        --[[if not templateArgs['name'] or templateArgs['name'] == "" then -- if page name not set
        	templateArgs['name'] = "''" .. templateArgs['taxon'] .. "''"
        end    ]]    	
        --TODO use {{Speciesbox/name}}
        templateArgs['name']  = frame:expandTemplate{ title = 'Speciesbox/name' , 
        	                           args = { templateArgs['name'], templateArgs['taxon'], 
        	                                    templateArgs['genus'], templateArgs['species'],
        	                                    mw.title.getCurrentTitle().baseText,
        	                                    templateArgs['italic_title' or 'yes']  
        	          	
        	          } }
            

        
        
		-- set binomial : the speciesbox template seems to use genus and species before taxon name
		-- "| binomial = ''{{Str letter/trim|{{{genus|{{{taxon|<includeonly>{{PAGENAME}}</includeonly><noinclude>Acacia</noinclude>}}}}}}}} {{{species|{{remove first word|{{{taxon|<includeonly>{{PAGENAMEBASE}}</includeonly><noinclude>Acacia aemula</noinclude>}}}}}}}}''"
		-- documentation suggest taxon, which is followed here
		templateArgs['binomial'] = "''" .. templateArgs['taxon'] .. "''"
		templateArgs['binomial_authority'] = templateArgs['authority'] or nil
				

    	-- set species_name e.g. Panthera leo -> P. leo
    	templateArgs['species_name'] = extinct .. "'''''" .. string.sub(templateArgs['genus'],1,1) .. '. ' .. templateArgs['species'] .. "'''''"
        templateArgs['species']=templateArgs['species_name']
        
        templateArgs['display_taxa']   = templateArgs['display_taxa'] -1
        templateArgs['offset'] = 1
	    if templateArgs['subgenus'] and templateArgs['subgenus'] ~= ""  then
	    	templateArgs['offset'] =  templateArgs['offset'] + 1
			templateArgs['subgenus_authority']              = templateArgs['parent_authority'] or ""
    	end
	    --templateArgs['species_authority']   = templateArgs['authority'] or "" -- don't show species_authority as duplicates binomial authority
	    
	    
	    --[[shift authorities for speciesbox (two steps if subgenus set)
	    if templateArgs['subgenus'] and templateArgs['subgenus'] ~= ""  then
			templateArgs['subgenus_authority']              = templateArgs['parent_authority'] or ""
			templateArgs['authority']                       = templateArgs['grandparent_authority'] or ""
			templateArgs['parent_authority']                = templateArgs['greatgrandparent_authority'] or ""
			templateArgs['grandparent_authority']           = templateArgs['greatgreatgrandparent_authority'] or ""
			templateArgs['greatgrandparent_authority']      = templateArgs['greatgreatgreatgrandparent_authority'] or ""
			templateArgs['greatgreatgrandparent_authority'] = templateArgs['greatgreatgreatgreatgrandparent_authority'] or ""
		else                                                                
			-- note: must set to "" if 'parent_authority's don't exist, otherwise the value of 'authority' is unchanged
			templateArgs['authority']                       = templateArgs['parent_authority'] or ""  
			templateArgs['parent_authority']                = templateArgs['grandparent_authority'] or ""
			templateArgs['grandparent_authority']           = templateArgs['greatgrandparent_authority'] or ""
			templateArgs['greatgrandparent_authority']      = templateArgs['greatgreatgrandparent_authority'] or ""
			templateArgs['greatgreatgrandparent_authority'] = templateArgs['greatgreatgreatgrandparent_authority'] or ""	
		end
        ]]
        templateArgs['taxon'] = nil -- For auto module
 
        
    -- =====================  set-up for SUBSPECIESBOX or INTRASPECIESBOX =================
	
	elseif info.auto == "subspeciesbox" or info.auto == "infraspeciesbox" then
	
	   --[[ From template description:
	          "The genus name, species name and subspecies name" 
	             [or "genus name, specific epithet and infraspecific epithet"] 
                 "
                 must be supplied separately: the combined taxon parameter cannot be used.""
              "The genus name is then the entry into the taxonomic hierarchy.""
              
		    The trinomial name is set from these parameters and the parameter ignored.
		   --NOTE no infraspeciebox is currently using trinomial parameter
        --]]
        
        -- Parameter checking. This could be here or moved to parameter checking function
        if templateArgs['genus'] and templateArgs['species'] and templateArgs['subspecies'] then
        	-- valid parameters for subspecies (may have variety as well)
        elseif templateArgs['genus'] and templateArgs['species'] and templateArgs['variety'] then
        	-- valid parameters for infraspecies (variety without subspecies)
        else
        	-- insufficient parameters
        	-- TODO add error message and return
        end
        local offset = 2  -- authority offset when subpecies OR variety 
        
        --TODO strip genus of disambiguator (need to check this works)
        	local genus =mw.text.split( templateArgs['genus'], " ", true )
	    	if genus[1] ~= "" then 
	    		templateArgs['genus'] = genus[1] 
	    	end
        templateArgs['parent'] = templateArgs['genus'] -- genus must be supplied
        
        local fullName = templateArgs['genus'] .. ' ' .. templateArgs['species']
 		templateArgs['species_name'] = "''[[" .. fullName  .. '|'.. string.sub(templateArgs['genus'],1,1) .. '. ' .. templateArgs['species'] .. "]]''"

        -- if subspecies is set (could be with or without variety)
        local separator = " "                               -- subspecies separator (default zoological)
	    if templateArgs['subspecies'] then                  -- might not be if variety
        	if info.auto == "infraspeciesbox"   then separator = " ''<small>subsp.</small>'' "   end
			templateArgs['subspecies_name']= extinct .. "'''''" .. string.sub(templateArgs['genus'],1,1) .. '.&nbsp;' .. string.sub(templateArgs['species'],1,1) .. '.' .. separator .. templateArgs['subspecies'] .. "'''''"
  			fullName = templateArgs['genus'] .. ' ' .. templateArgs['species'] .. separator .. templateArgs['subspecies'] 
			templateArgs['trinomial'] = "''" .. fullName .. "''"
            --templateArgs['subspecies_authority'] = templateArgs['authority']  -- replicates authoity in trinomial (unwanted?)
        end
        
        if templateArgs['variety'] or templateArgs['varietas'] then  -- should now be aliased
            local vSeparator = " ''<small>var.</small>'' " 
            --alias done? templateArgs['variety']= templateArgs['variety'] or templateArgs['varietas'] -- will use variety as parameter TODO alias this
			templateArgs['variety_name'] = extinct .. "'''''" .. string.sub(templateArgs['genus'],1,1) .. '.&nbsp;' .. string.sub(templateArgs['species'],1,1) .. '.' .. vSeparator .. templateArgs['variety'] .. "'''''"
  			templateArgs['trinomial'] = "''" .. templateArgs['genus'] .. ' ' .. templateArgs['species'] .. vSeparator .. templateArgs['variety'] .. "''"
            --templateArgs['variety_authority'] = templateArgs['authority'] -- replicates authority in trinomial
    	    
    	    if templateArgs['subspecies'] then 	-- subspecies needs to linked instead of bold 
	  			local redirectName = templateArgs['genus'] .. ' ' .. templateArgs['species'] .. " subsp. " .. templateArgs['subspecies'] 
				local shortName = "''" .. string.sub(templateArgs['genus'],1,1) .. '.&nbsp;' .. string.sub(templateArgs['species'],1,1) .. '.' .. separator .. templateArgs['subspecies'] .. "''" 
				templateArgs['subspecies_name'] =  "[[" .. redirectName .. '|' .. shortName .. "]]"
				offset = offset + 1 -- offset when susbpecies AND variety
                templateArgs['subspecies_authority'] = templateArgs['parent_authority']
        	end
        end
        
        --TODO what else do subspeciesbix and infraspeciesbox cover?)

       --[[ code from templates
            both:            |trinomial_authority = {{{authority|{{{trinomial authority|{{{trinomial_authority|}}} }}} }}}
            infraspeciesbox: |species_authority = {{{parent_authority|{{{parent authority|{{{binomial authority|{{{binomial_authority|}}}}}}}}}}}}
            subspeciesbox: | species_authority = {{{parent authority|{{{binomial authority|{{{binomial_authority|}}}}}}}}}
              note: subspeciesbox doesn't recognise patent_authority with underscore
          monthly reports on subspeciesbox and infraspeciesbox
              no uses of parent_authority, binomial_authority or trinomial authority
              no uses of grandparent, greatgrandparent etc authorites
        ]]
 		templateArgs['trinomial_authority'] = templateArgs['authority'] or nil

        if not templateArgs['name'] or templateArgs['name'] == "" then -- if page name not set
        	templateArgs['name'] = templateArgs['trinomial']
        end
        
        -- these are used by manual taxobox to complete the taxonomy table
        templateArgs['species'] = templateArgs['species_name']
        templateArgs['subspecies'] = templateArgs['subspecies_name']
		templateArgs['variety'] =templateArgs['variety_name']
        
        --QUESTION what happens to parent taxa when subspecies and variety? 
        -- set species and subgenus authorities
	    if templateArgs['subgenus'] then 
	    	offset = offset + 1
		    if offset == 4  then    -- when subgenus, species, subspecies and variety
		    	templateArgs['subgenus_authority']  = templateArgs['subgenus_authority'] or templateArgs['greatgrandparent_authority'] or ""
		    	templateArgs['species_authority']   = templateArgs['grandparent_authority'] or ""
	        elseif offset == 3  then -- when subgenus, species, (subspecies OR variety)
		    	templateArgs['subgenus_authority']  = 	templateArgs['subgenus_authority'] or templateArgs['grandparent_authority'] or ""
		    	templateArgs['species_authority']   = templateArgs['parent_authority'] or ""
		    end
		else -- only need to set species authority or subspecues (if also variety)
		    if offset == 3 then    -- species, subspecies and variety
		    	templateArgs['species_authority']   = templateArgs['grandparent_authority'] or ""
		    	templateArgs['subspecies_authority']   = templateArgs['parent_authority'] or ""
		    elseif offset == 2 then  -- species, (subspecies or variety)
		        templateArgs['species_authority']   = templateArgs['parent_authority'] or ""
		    end	    
		end
       
        templateArgs['display_taxa']   = (templateArgs['display_taxa'] or 1) -2
        templateArgs['offset'] = offset

	

	    -- need to set subgenus_authority, species_authority, subspecies_authority and variety_authority
        
	    --[[shift authorities for subspeciesbox (two steps or three if subgenus set)
	    if templateArgs['subgenus'] and templateArgs['subgenus'] ~= ""  then
			templateArgs['subgenus_authority']              = templateArgs['grandparent_authority'] or ""
			templateArgs['authority']                       = templateArgs['greatgrandparent_authority'] or ""
			templateArgs['parent_authority']                = templateArgs['greatgreatgrandparent_authority'] or ""
			templateArgs['grandparent_authority']           = templateArgs['greatgreatgreatgrandparent_authority'] or ""
			templateArgs['greatgrandparent_authority']      = templateArgs['greatgreatgreatgreatgrandparent_authority'] or ""
			templateArgs['greatgreatgrandparent_authority'] = templateArgs['greatgreatgreatgreatgreatgrandparent_authority'] or ""
		else
			templateArgs['authority']                       = templateArgs['grandparent_authority'] or ""
			templateArgs['parent_authority']                = templateArgs['greatgrandparent_authority'] or ""
			templateArgs['grandparent_authority']           = templateArgs['greatgreatgrandparent_authority'] or ""
			templateArgs['greatgrandparent_authority']      = templateArgs['greatgreatgreatgrandparent_authority'] or ""
			templateArgs['greatgreatgrandparent_authority'] = templateArgs['greatgreatgreatgreatgrandparent_authority']	 or ""
		end
		]]
	
	-- ========================= setup for AUTOMATIC TAXOBOX ================================
	        -- CHECK authomatic taxobox pagename overrides taxon (e.g. Tortrix? destructus) for header
        --         it does but no italics in header for Tortrix? destructus

    --elseif info.auto == "automatictaxobox" then
	
	elseif info.auto == "virus" or info.auto == "virusbox" then
			templateArgs['virus'] = "yes"
			templateArgs['color_as'] = "Virus"
			if not templateArgs['parent'] then
				if templateArgs['taxon'] then
			        templateArgs['parent'] = templateArgs['taxon']  
			    elseif templateArgs['species'] then 
			    	templateArgs['parent'] = templateArgs['species'] 
			    	templateArgs['species'] = nil
			    else
			    	templateArgs['parent'] = tostring( mw.title.getCurrentTitle()) or ""
			    end
			else
				templateArgs['link_parent'] = "yes"            -- if parent given, we want to link it
			end
		    
	else 

    	-- "the automated taxobox first looks for the taxonomy template that matches the supplied |taxon= parameter "
    	--       "(or, if none is supplied, the article's title, ignoring any parenthetical expressions). "
    	if not templateArgs['taxon'] or  templateArgs['taxon'] == "" then
    		--templateArgs['taxon'] = templateArgs['name'] or tostring( mw.title.getCurrentTitle())
    		templateArgs['taxon'] = tostring( mw.title.getCurrentTitle()) or ""
    		--TODO strip name of parenthetical terms off page title
    		if templateArgs['taxon'] ~= "" then
    			--TODO error message and exit
    		end
    	end		
    	if templateArgs['parent'] then
    		templateArgs['link_parent'] = "yes"              -- if parent given, we want to link it
    	else
  		   templateArgs['parent'] = templateArgs['taxon']   -- otherwise set parent
  		end
  		--TODO set name if parameter no supplies
  		
  		--[[ TODO if no taxonomy template, then call setup taxonomy template 
  		   {{#ifexist:Template:Taxonomy/{{{taxon|<includeonly>{{PAGENAME}}
  		   {{Automatic taxobox/floating intro|taxon={{{taxon|{{PAGENAME}}}}} }}
  		]]
	
	end	-- end special handling for speciesbox, subspeciesbox, and automatic taxobox
	
	-- check taxonomy templates for automatic taxobox systtem
	--{{#ifexist:Template:Taxonomy/{{{taxon|<includeonly>{{PAGENAME}}</includeonly><noinclude>Acacia</noinclude>}}}
	--       |<noinclude><!--do nothing if it exists--></noinclude>
	--       |{{Automatic taxobox/floating intro|taxon={{{taxon|{{PAGENAME}}}}} }}
-->}}

end



-------------------------------------------------------------------
function p.templateStyle( frame, src )
   return frame:extensionTag( 'templatestyles', '', { src = src } );
   
end	

-----------------------------------------
function p.testTables(frame)
	if 1==1 then return end  -- disable
	local root = mw.html.create('table'):addClass('wikitable')

	local row = root:tag('tr')                -- add row using lua library
	local cell = row:tag('td')
	cell:wikitext('row A:')
	cell = row:tag('td'):wikitext('content A')  

	row = root:tag('tr')                      -- add row using lua library 
	cell = row:tag('td'):wikitext('row B:')
	cell = row:tag('td')
	          :wikitext('\n{|\n|-\n|P\n|Q\n|}') --but include a wikitxt table in one cell
	         -- :done()

   -- row:done()
    --root=mw.html:allDone()
    root:wikitext('<tr><td>a</td><td>b</td></tr>') -- add row to root using html 
    root:wikitext('\n|-\n|X\n|Y\n')              -- add row to root using wikitext (FAILS) 
    
    root:wikitext('\r|-\r|I\r|J\r')              -- FAIL output |- |X |Y 
	
	root:wikitext(frame:preprocess('\n|-\n|U\n|V\n')) -- FAIL output |- |U |V 
	
	root:wikitext('<tr>\n|M\n|N\n</tr>')    
	

	row=root:tag('tr'):node('<td>c</td><td>d</td>')    -- adds row successfully
	row=root:tag('tr'):node('\n|Xc\n|Xd\n')    -- fails to adds row
	
	
	row = root:tag('tr')                       -- add another row using lua library
	cell = row:tag('td'):wikitext('row C:')
	cell = row:tag('td'):wikitext('content C')

	root:node('\n{|\n|-\n|Xx\n|Yx\n|}\n')    -- adds new table after

	--frame:preprocess
	return 	 tostring(root)

--[[ CONCLUSION: cannot mix wikitext freely in the node structure
           A complete wikitext table can be included in a cell (e.g. used for automatic taxonomy now)
           An alternative is to use wikitext for the whole taxobox table
]]
end

-- --------------------------- TEST AUTO TAXONOMY FUNCTIONS -----------------------------
function p.test(frame)
	
    local a = require("Module:Sandbox/Jts1882/Biota Infobox/auto")

	--local taxonTable = a.loadTaxonomyTable(frame) now done in showTaxonomyTable
	
    return a.showTaxonomyTable(frame)
end




-- All modules end by returning the variable containing its functions to Wikipedia.
return p