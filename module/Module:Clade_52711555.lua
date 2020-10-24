--[[NOTE: this module contains functions for generating the table structure of the clade tree: 

The main function is called by the template using the {{invoke}} instruction; the three main functions are:
        p.main(frame) - opens and closes table, loops through the children of node, main is invoked once and controls the rest, calling ...
        p.addTaxon(childNumber, nodeLeaf) - the nuts and bolts; code dealing with each child node
        p.addLabel(childNumber) - adds the label text
        
        now uses templatestyles
]]
require('Module:No globals')
local p = {}
local pargs = {}  -- parent arguments
local lastNode=0
local nodeCount=0
local cladeCount=0
local leafCount=0
local templateStylesCount=0
local infoOutput
local reverseClade = false

--[[============================== main function  ===========================
-- main function, which will generate the table structure of the tree

Test version:
Usage: {{#invoke:Module:Sandbox/Jts1882/CladeN|main|style={{{STYLE|}}} }}
Template:CladeN

Release version:
Usage: {{#invoke:Clade|main|style={{{STYLE|}}} }}
Template:Clade
]]

function p.main(frame)

	local cladeString = ""	
	local maxChildren = 20 -- was 17 in the clade/cladex templates
	local childNumber = 0
	local childCount = 0 -- number of leaves in the clade (can use to set bottom of bracket in addTaxon()
	local totalCount = 0
	
	pargs = frame:getParent().args -- parent arguments
	
    infoOutput = p.getCladeTreeInfo() -- get info about clade structure, e.g. lastNode (last |N= child number)
    
    --[[ add the templatestyles tag  conditionally to reduce expansion size (currently diabled)
        when added to every clade table, it increases post‐expand include size significantly
           e.g. the Neosuchia page (or test version) is increase by about 8% (672 bytes each)
                if template styles added to all pages there are 133 stripmarkers 
                with cladeCount==1 condition, this is reduced to 34
        however cladeCount==1 condition interfers with fix for additional line due to parser bug T18700
        killing the strip markers also removes backlinks to references using citation templates 
    --]]
    --cladeString =mw.text.killMarkers( cladeString ) -- also kills off strip markers using citation templates
    --cladeString = mw.text.unstrip(cladeString)
    --if cladeCount==1  then 
    	local src = "Template:Clade/styles.css"
    	cladeString = cladeString .. p.templateStyle( frame, src ) .. '\n'
    --end	
    
	local tableStyle = frame.args.style or ""

	if tableStyle ~= "" then
		tableStyle = ' style="' .. tableStyle .. '"' -- include style= in string to suppress empty style elements
	end
    
    reverseClade =frame.args.reverse or pargs.reverse or false -- a global
    --ENFORCE GLOBAL FOR DEVELOPMENT
    --reverseClade = true

	local captionName  = pargs['caption'] or ""
	local captionStyle = pargs['captionstyle'] or ""

    -- add an element to mimick nowiki WORKS BUT DISABLE FOR DEMO PURPOSES
    --cladeString = '<p class="mw-empty-elt"></p>\n'
    
	-- open table	
	-- (border-collapse causes problems (see talk) -- cladeString = cladeString .. '{| style="border-collapse:collapse;border-spacing:0;margin:0;' .. tableStyle .. '"'
    -- (before CSS styling) -- cladeString = cladeString .. '{| style="border-spacing:0;margin:0;' .. tableStyle .. '"'
    cladeString = cladeString .. '{|class="clade"' .. tableStyle

    -- add caption
	if captionName ~= "" then
		cladeString = cladeString .. '\n|+ style="' .. captionStyle .. '"|' .. captionName
	end
	
	
	local moreNeeded = true
	childNumber = 0
	--lastNode = 0

	--[[get child elements (add more rows for each child of node; each child is two rows)
	    the function addTaxon is called to add the rows for each child element;
	    each child add two rows: the first cell of each row contains the label or sublabel (below the line label), respectively;
	    the second cell spans both rows and contains the leaf name or a new clade structure
	    a third cell on the top row is sometimes added to contain a group  to the right
	]]
	
	-- main loop
	while 	childNumber < lastNode do -- use the last number determined in the preprocessing

		childNumber = childNumber + 1 -- so we start with 1
		local nodeLeaf = pargs[tostring(childNumber)] or ""  -- get data from |N=
		local nodeLabel = pargs['label'..tostring(childNumber)] or ""  -- get data from |labelN=
		
		
		local newickString = pargs['newick'..tostring(childNumber)] or ""  -- get data from |labelN=
		local listString   = pargs['list'..tostring(childNumber)] or "" 
		
		if listString ~= "" then
			cladeString = cladeString .. '\n' .. p.addTaxon(childNumber, p.list(0, listString), nodeLabel, lastNode)
		elseif newickString ~= "" then -- if using a newick string instead of a clade structure
			newickString = p.processNewickString(newickString,childNumber)
			if nodeLabel == "" then -- use labelN by default, otherwise use root name from Newick string
				nodeLabel = p.getNewickOuterterm(newickString) -- need to use terminal part of newick string for label
			end
			cladeString = cladeString .. '\n' .. p.addTaxon(childNumber, p.newick(0, newickString), nodeLabel, lastNode)
			--lastNode=lastNode+1 -- there is a counting problem with the newickstring
		elseif nodeLeaf ~= "" then -- if the node contains a leaf name or clade structue
			--if reverseClade2 then
			--	cladeString = cladeString .. '\n' .. p.addTaxonReverse(childNumber, nodeLeaf, nodeLabel, lastNode)
		    --else
				cladeString = cladeString .. '\n' .. p.addTaxon(childNumber, nodeLeaf, nodeLabel, lastNode)
			--end
		end
	end

	local footerText  = pargs['footer'] or ""
	local footerStyle = pargs['footerstyle'] or ""

	if footerText ~= "" then
	   cladeString = cladeString ..  '\n|-style="' .. footerStyle .. '"\n|colspan="2"|<p>' .. footerText .. '</p>||'
	   -- note the footer causes a problem with tr:last-child so need either
	   -- (1) use <tfoot> but it is not allowed or incompatable
	   --           cladeString = cladeString ..  '<tfoot><tr style="' .. footerStyle .. '"><td colspan="2"><p>' .. footerText .. '</p></td></tr></tfoot>'
	   -- (2) always add footer and use nth:last-child(2) but is this backwards compatible
	   -- (3) if footer= set the style inline for the last sublabel row (more a temp fix)
	   -- (4) set class for first and last element (DONE. Also works well with reverse class)
	end

	-- close table (wikitext to close table)
	cladeString = cladeString ..  '\n|}'
	
	cladeString = p.addSubTrees(cladeString) -- add subtrees
	
	return cladeString
	--return '<div style="width:auto;">\n' .. cladeString .. '</div>'
end

--[[ =============================function to add subtrees ========================================== ]]

function p.addSubTrees(cladeString)
	
	--local pargs = mw.getCurrentFrame():getParent().args 
	
	local suffix = { [1]="A", [2]="B", [3]="C", [4]="D", [5]="E", [6]="F", [7]="G", [8]="H", [9]="I", [10]="J", 
		             [11]="K", [12]="L", [13]="M", [14]="N", [15]="O", [16]="P", [17]="Q", [18]="R", [19]="S", [20]="T", 
		             [21]="U", [22]="V", [23]="W", [24]="X", [25]="Y", [26]="Z"}
	for i=1, 26, 1 do
		local subclade = pargs['subclade'..suffix[i]]
		local target = pargs['target'..suffix[i]] or "SUBCLADE_" .. suffix[i]
		if subclade  then 
			if string.find(cladeString, target) then
				cladeString = string.gsub(cladeString,target,subclade)
			end
		end
    end
	return cladeString
end
--[[ -------------------------------------- p.addTaxon() ------------------------------------------
     function to add child elements
     adds wikitext for two rows of the table for each child node, 
     	the first cell in each is used for the label and sublabel; the bottom border forms the horizonal branch of the bracket
     	the second cell is used for the leafname or a transcluded clade structure and spans both rows
     note that the first and last child nodes need to be handled differently from the middle elements
	     the middle elements (|2, |3 ...) use a left border to create the vertical line of the bracket
	     the first child element doesn't use a left border for the first cell in the top row (as it is above the bracket)
	     the last child doesn't use a left border for the first cell in the second row (as it is below the bracket)
]]
function p.addTaxon(childNumber, nodeLeaf, nodeLabel, lastNode)

	--[[ get border formating parameters (i.e. color, thickness, state)
    		nodeParameters for whole bracket (unnumbered, i.e. color, thickness, state) apply to whole node bracket, 
			branchParameters apply to individual branches
	    	the branch parameters have a number, e.g. |colorN, |thicknessN, |stateN
	    	the node parameters have no number, e.g. |color, |thickness, |state
	]]
    local nodeColor = pargs['color'] or ""                 -- don't set default to allow green on black gadget
	local nodeThickness = tonumber(pargs['thickness']) or 1
	local nodeState = pargs['state'] or "solid"
	-- get border formating parameters for branch (default to global nodeParameters)
	local branchColor = pargs['color'..tostring(childNumber)] or nodeColor 
	local branchThickness = tonumber(pargs['thickness'..tostring(childNumber)]) or nodeThickness
	local branchState = pargs['state'..tostring(childNumber)] or nodeState 
	if branchState == 'double' then 
		if branchThickness < 2 then branchThickness = 3 end -- need thick line for double
	end  
	
	local branchStyle = pargs['style'..tostring(childNumber)] or ""
	local branchLength = pargs['length'] or pargs['length'..tostring(childNumber)] or ""

    -- the left border takes node parameters, the bottom border takes branch parameters
    -- this has coding on the colours for green on black
   local bottomBorder =  tostring(branchThickness) ..'px ' .. branchState  .. (branchColor~="" and ' ' .. branchColor or '')
   local leftBorder   =  tostring(nodeThickness)   ..'px ' .. nodeState  .. (nodeColor~="" and ' ' .. nodeColor or '')
	
	--The default border styles are in the CSS (styles.css)
	--    the inline styling is applied when thickness, color or state are change
	
	local useInlineStyle = false
	-- use inline styling non-default color, line thickness or state have been set
	if branchColor ~= "" or branchThickness ~=  1 or branchState ~= "solid"  then
		useInlineStyle = true
	end
	
	
	-- variables for right hand bar or bracket
	--local barColor  = "" 
	local barRight  = pargs['bar'..tostring(childNumber)] or "0"
	local barBottom = pargs['barend'..tostring(childNumber)] or "0"
	local barTop    = pargs['barbegin'..tostring(childNumber)] or "0"
	local barLabel  = pargs['barlabel'..tostring(childNumber)] or ""
	local groupLabel      = pargs['grouplabel'..tostring(childNumber)] or ""
	local groupLabelStyle = pargs['grouplabelstyle'..tostring(childNumber)] or ""
	local labelStyle      = pargs['labelstyle'..tostring(childNumber)] or ""
	local sublabelStyle   = pargs['sublabelstyle'..tostring(childNumber)] or ""

	--replace colours with format string; need right bar for all three options
	if barRight  ~= "0" then barRight  = "2px solid " .. barRight  end 
	if barTop    ~= "0" then barRight  = "2px solid " .. barTop    end
	if barBottom ~= "0" then barRight  = "2px solid " .. barBottom end 
	if barTop    ~= "0" then barTop    = "2px solid " .. barTop    end
	if barBottom ~= "0" then barBottom = "2px solid " .. barBottom end 
	
	
	-- now construct wikitext 
	local cladeString = ''
	local styleString = ''
    local borderStyle = '' -- will be used if border color, thickness or state is to be changed
    local classString = ''
    local reverseClass = ''
    local widthClass = ''
    
    -- class to add if using reverse (rtl) cladogram; 
    if reverseClade then reverseClass = ' reverse' end 
    
    -- (1) wikitext for new row
    --cladeString = cladeString .. '\n|-'

	-- (2) now add cell with label
    
	if useInlineStyle then
		if childNumber == 1 then
	        borderStyle = 'border-left:none;border-right:none;border-bottom:' .. bottomBorder .. ';' 
	        --borderStyle = 'border-bottom:' .. bottomBorder .. ';' 
	 	else -- for 2-17
	 		if reverseClade then
	    		borderStyle  = 'border-left:none;border-right:' .. leftBorder .. ';border-bottom:' .. bottomBorder .. ';' 
	 	    else
	    		borderStyle  = 'border-left:' .. leftBorder .. ';border-bottom:' .. bottomBorder .. ';' 
	    	end
		end
	end
	
   	if useInlineStyle or branchStyle ~= '' or branchLength ~= "" or labelStyle ~= "" then
   		local branchLengthStyle = ""
   		if branchLength ~= "" then 
   			if childNumber == 1 then
   				branchLengthStyle = 'width:' .. branchLength .. ';'  -- add width to first element
   			end
   			--if childNumber > 1 then prefix = 'max-' end
   			branchLengthStyle = branchLengthStyle --= prefix  .. 'width:' .. branchLength .. ';' 
   										.. 'max-width:' .. branchLength ..';'
   			                            .. 'padding:0em;'         -- remove padding to make calculation easier
   						-- following moved to styles.css
   						--				.. 'white-space:nowrap'
   						--				.. 'overflow:hidden;'    -- clip labels longer than the max-width
   						--				.. 'text-overflow:clip;' -- ellipsis;'
   		    widthClass = " clade-fixed-width"
   		end
   		styleString = 'style="' .. borderStyle .. branchLengthStyle .. branchStyle .. labelStyle .. '"'
    end	

	if childNumber == 1 then
		classString= 'class="clade-label first'.. widthClass .. '" '                  -- add class "first" for top row
    else
    	classString = 'class="clade-label' .. reverseClass .. widthClass .. '" ' -- add "reverse" class if ltr cladogram
    end

    --  wikitext for cell with label
    local labelCellString = '\n|' .. classString .. styleString  .. '|' .. p.addLabel(childNumber,nodeLabel) -- p.addLabel(nodeLabel)
    
    --cladeString = cladeString .. labelCellString

	---------------------------------------------------------------------------------
	-- (3) add cell with leaf (which may be a table with transluded clade content)
    
    if barRight  ~= "0"  then 
    	if reverseClade then -- we want the bar on the left
    		styleString = ' style="border-left:' .. barRight .. ';border-bottom:' .. barBottom .. ';border-top:' .. barTop .. ';' .. branchStyle .. '"'
    	else
    		styleString = ' style="border-right:' .. barRight .. ';border-bottom:' .. barBottom .. ';border-top:' .. barTop .. ';' .. branchStyle .. '"'
    	end
    else
    	if (branchStyle ~= '') then
    		styleString = ' style="' .. branchStyle .. '"'
        else
        	styleString = '' -- use defaults in styles.css
        end
    end
   
    classString = 'class="clade-leaf' .. reverseClass .. '"'

     --[[note: the \n causes plain leaf elements get wrapped in <p> with style="margin:0.4em 0 0.5em 0;" 
    	       this adds spacing to rows, but is set by defaults rather than the clade template
    	       it also means there are two newlines when it is a clade structure (which might explain some past issues)
    ]]
    local content = '\n' .. nodeLeaf  -- the newline is not necessary, but keep for backward compatibility

    -- test using image parameter
    local image = pargs['image'..tostring(childNumber)] or ""  

    if image ~= "" then                                   
    	--content = content .. image -- basic version
      	content = '\n{| class="clade" style="width:auto;"'  --defaults to width:100% because of class "clade"
    	       .. '\n| class="clade-leaf" ' .. '|\n' .. nodeLeaf 
    	       .. '\n| class="clade-leaf" ' .. '|\n' .. image 
    	       .. '\n|}'
      	-- note: the classes interfere with the node counter, so try simpler version with style
        content = '\n{| style="width:100%;border-spacing:0;" '  --width:auto is "tight"; 100% needed for image alignment
    	       .. '\n| style="border:0;padding:0;" ' .. '|\n' .. nodeLeaf 
    	       .. '\n| style="border:0;padding:0;" ' .. '|\n' .. image 
    	       .. '\n|}'
    end


    -- wikitext for leaf cell (note: nodeLeaf needs to be on newline if new wikitable)
    --                         but that is no longer the case (newline is now forced)
    --                         the newline wraps plain leaf terminals in <P> with vertical padding (see above)

    --local leafCellString = '\n|rowspan=2 ' .. classString  .. styleString .. ' |\n' .. content -- the new line causes <p> wrapping for plain leaf terminals
    local leafCellString = '\n|rowspan=2 ' .. classString  .. styleString .. ' |' .. content
   
    --cladeString = cladeString .. leafCellString

    
    -------------------------------------------
    -- (4) stuff for right-hand bracket labels

  	classString='class="clade-bar' .. reverseClass .. '"'
    	
    local barLabelCellString = ''
	if barRight  ~= "0"  and barLabel ~= "" then 
	   barLabelCellString = '\n|rowspan=2 ' .. classString .. ' |' .. barLabel
	else -- uncomment following line to see the cell structure
	   --barLabelCellString = '\n|rowspan=2 ' .. classString .. ' |' .. 'BL'
	end 
	
	if groupLabel ~= "" then 		
		barLabelCellString = barLabelCellString .. '\n|rowspan=2 ' .. classString .. ' style="'.. groupLabelStyle .. '" |' .. groupLabel 
	else -- uncomment following line to see the cell structure
	    --barLabelCellString = barLabelCellString .. '\n|rowspan=2 ' .. classString .. '" |' .. 'GL' 
   end 	

   --cladeString = cladeString .. barLabelCellString
    
	-------------------------------------------------------------------------------------
	-- (5) add second row (only one cell needed for sublabel because of rowspan=2); 
	--     note: earlier versions applied branch style to row rather than cell
	--           for consistency, it is applied to the sublabel cell as with the label cell
	
	--cladeString = cladeString .. '\n|-' 
	
	-----------------------------------
	-- (6) add cell containing sublabel
	
	local subLabel = pargs['sublabel'..tostring(childNumber)] or ""  -- request in addLabel
	
	-- FOR TESTING: use subLabel for annotating the clade structues to use structure information (DEBUGGIING ONLY)
	--if childNumber==lastNode then subLabel= infoOutput end
	-- END TESTING
	
	borderStyle = ''
	styleString = ''
	if useInlineStyle then
		if childNumber==lastNode then 		-- if childNumber==lastNode we don't want left border, otherwise we do
			borderStyle = 'border-right:none;border-left:none;'
	    else
	 		if reverseClade then
	    		borderStyle  = 'border-left:none;border-right:' .. leftBorder .. ';' 
	 	    else
	    		borderStyle  = 'border-right:none;border-left:' .. leftBorder .. ';'  
	    	end
	    end 
    end
    if borderStyle ~= '' or  branchStyle ~= '' or  branchLength ~= '' or sublabelStyle ~= "" then         
   		local branchLengthStyle = ""
   		if branchLength ~= "" then 
   			if childNumber == 1 then
   				branchLengthStyle = 'width:' .. branchLength .. ';'  -- add width to first element
   			end
   			--if childNumber > 1 then prefix = 'max-' end
   			branchLengthStyle = branchLengthStyle --= prefix  .. 'width:' .. branchLength .. ';' 
   										.. 'max-width:' .. branchLength ..';'
   			                            .. 'padding:0em;'         -- remove padding to make calculation easier
   		end
   		styleString = 'style="' .. borderStyle .. branchLengthStyle .. branchStyle .. sublabelStyle .. '"'
        --styleString = ' style="' .. borderStyle .. branchStyle .. sublabelStyle .. '"'
    end

    --local sublabel = p.addLabel(childNumber,subLabel)

    if childNumber == lastNode then 
    	classString = 'class="clade-slabel last' .. widthClass .. '" ' 
    else
        classString = 'class="clade-slabel' .. reverseClass .. widthClass .. '" '
    end
    local sublabelCellString = '\n|' .. classString .. styleString .. '|' ..  p.addLabel(childNumber,subLabel)
    
    --cladeString = cladeString .. sublabelCellString

    -- constuct child element wikitext
    if reverseClade then
	    cladeString = cladeString .. '\n|-'
	    cladeString = cladeString .. barLabelCellString
	    cladeString = cladeString .. leafCellString
	    cladeString = cladeString .. labelCellString
		cladeString = cladeString .. '\n|-'     
		cladeString = cladeString .. sublabelCellString
    else	
	    cladeString = cladeString .. '\n|-'
	    cladeString = cladeString .. labelCellString
	    cladeString = cladeString .. leafCellString
	    cladeString = cladeString .. barLabelCellString
		cladeString = cladeString .. '\n|-'     -- add second row (only one cell needed for sublabel because of rowspan=2);
		cladeString = cladeString .. sublabelCellString
    end
    
	return cladeString
end



--[[ adds text for label or sublabel to a cell
]]
function p.addLabel(childNumber,nodeLabel)
	
	--local nodeLabel = mw.getCurrentFrame():getParent().args['label'..tostring(childNumber)] or ""

	--local firstChars = string.sub(nodeLabel, 1,2) -- get first two characters; will be {{ if no parameter (for Old method?)
	--if firstChars == "{{{" or nodeLabel == "" then
	if nodeLabel == "" then
		--return '<br/>' --'&nbsp;<br/>'  -- remove space to reduce post-expand include size (the width=1.5em handles spacing)
		--return '<br/>' -- must return something; this is critical for clade structure 
		return '&#8239;' -- &nbsp; &thinsp; &#8239;(thin nbsp)
	else
		-- spaces can cause  wrapping and can break tree structure, hence use span with nowrap class
		--return '<span class="nowrap">' .. nodeLabel .. '</span>'
		
		-- a better method for template expansion size is to replace spaces with nonbreaking spaces
		-- however, there is a problem if labels have a styling element (e.g. <span style= ..., <span title= ...)
		local stylingElementDetected = false
		if string.find(nodeLabel, "span ") ~= nil  then  stylingElementDetected = true end
		if string.find(nodeLabel, " style") ~= nil then stylingElementDetected = true end 
		--TODO test following alternative
		--if nodeLabel:find( "%b<>") then stylingElementDetected = true end 
		
		if stylingElementDetected == true then 
			return '<div style="display:inline;" class="nowrap">' .. nodeLabel .. '</div>'
    	else	
     		local nowrapString = string.gsub(nodeLabel," ", "&nbsp;")   -- replace spaces with non-breaking space
		    if not nowrapString:find("UNIQ.-QINU") and not nowrapString:find("%[%[.-%]%]") then                 -- unless a strip marker
			    nowrapString = string.gsub(nowrapString,"-", "&#8209;") -- replace hyphen with non-breaking hyphen (&#8209;)
            end
			return nowrapString
		end
	end
end



--[[=================== Newick string handling function =============================
]]
function p.getNewickOuterterm(newickString)
	return string.gsub(newickString, "%b()", "")   -- delete parenthetic term
end

function p.newick(count,newickString)
	
	local cladeString = ""
	count = count+1
	--start table
	--cladeString = cladeString .. '{| style="border-collapse:collapse;border-spacing:0;border:0;margin:0;'
	cladeString = cladeString .. '{| class="clade" '
	
	local j,k
	j,k = string.find(newickString, '%(.*%)')                 -- find location of outer parenthesised term
	local innerTerm = string.sub(newickString, j+1, k-1)      -- select content in parenthesis
	local outerTerm = string.gsub(newickString, "%b()", "")   -- delete parenthetic term
	if outerTerm == 'panthera' then outerTerm = "x" end     -- how is this set in local variable for inner nodes?
	
	outerTerm = tostring(count)
	
	-- need to remove commas in bracket terms before split, so temporarily replace commas between brackets
    local innerTerm2 =  string.gsub(innerTerm, "%b()",  function (n)
                                         	return string.gsub(n, ",%s*", "XXX")  -- also strip spaces after commas here
                                            end)
	--cladeString = cladeString .. '\n' .. p.addTaxon(1, innerTerm2, "")

    -- this needs a lastNode variable
	local s = p.strsplit(innerTerm2, ",")
	--oldLastNode=lastNode
	local lastNode=table.getn(s) -- number of child branches
	local i=1	
	while s[i] do	
		local restoredString = string.gsub(s[i],"XXX", ",")   -- convert back to commas
		--restoredString = s[i]
		local outerTerm = string.gsub(restoredString, "%b()", "")
		if string.find(restoredString, '%(.*%)') then
			--cladeString = cladeString .. '\n' .. p.addTaxon(i, restoredString, "x")
			cladeString = cladeString .. '\n' .. p.addTaxon(i, p.newick(count,restoredString), outerTerm, lastNode)
			-- p.addTaxon(2, p.newick(count,newickString2), "root")
		else
			cladeString = cladeString .. '\n' .. p.addTaxon(i, restoredString, "", lastNode) --count)
		end
		i=i+1
	end
   -- lastNode=oldLastNode
    
	-- close table
	--cladeString = cladeString ..  '\n' .. '| style="border: 0; padding: 0; vertical-align: top;" | <br/> \n|}'
	--cladeString = cladeString ..  '\n| <br/> \n|}' -- is this legacy for extra sublabel?
	cladeString = cladeString ..  '\n|}'
	return cladeString
end
-- emulate a standard split string function
-- why not use mw.text.split(s, sep)?
function p.strsplit(inputstr, sep) 
        if sep == nil then
                sep = "%s"
        end
        local t={} 
        local i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end


-- =================== experimental Newick to clade parser function =============================

--[[Function of convert Newick strings to clade format

Usage: {{#invoke:Module:Sandbox/Jts1882/CladeN|newickConverter|newickstring={{{NEWICK_STRING}}} }}
]]
function p.newickConverter(frame)
	
	local newickString = frame.args['newickstring'] or pargs['newick']
	
	--if newickString == '{{{newickstring}}}' then return newickString  end

    newickString = p.processNewickString(newickString,"") -- "childNumber")
    
    
	-- show the Newick string
	local cladeString = ''
	local levelNumber = 1           --  for depth of iteration
	local childNumber = 1           --  number of sister elements on node  (always one for root)
	
	--  converted the newick string to the clade structure
	cladeString = cladeString .. '{{clade'
	cladeString = cladeString .. p.newickParseLevel(newickString, levelNumber, childNumber) 
	cladeString = cladeString .. '\r}}'  

	local resultString = ''
    local option = pargs['option'] or ''
    if option == 'tree' then
	 	--show the transcluded clade diagram
		resultString =   cladeString    	
    else
    	-- show the Newick string
		resultString = '<pre>'..newickString..'</pre>'	
	    -- show the converted clade structure
	    resultString = resultString .. '<pre>'.. cladeString ..'</pre>'	
    end
    --resultString = frame:expandTemplate{ title = 'clade',  frame:preprocess(cladeString) }

    return resultString
end

--[[ Parse one level of Newick string
     This function receives a Newick string, which has two components
      1. the right hand term is a clade label: |labelN=labelname
      2. the left hand term in parenthesis has common delimited child nodes, each of which can be
           i.  a taxon name which just needs:  |N=leafname 
           ii. a Newick string which needs further processing through reiteration
]]
function p.newickParseLevel(newickString,levelNumber,childNumber)

    
	local cladeString = ""
	local indent = p.getIndent(levelNumber) 
	--levelNumber=levelNumber+1
	
	local j=0
	local k=0
	j,k = string.find(newickString, '%(.*%)')                 -- find location of outer parenthesised term
	local innerTerm = string.sub(newickString, j+1, k-1)      -- select content in parenthesis
	local outerTerm = string.gsub(newickString, "%b()", "")   -- delete parenthetic term

	cladeString = cladeString .. indent .. '|label'..childNumber..'='  .. outerTerm
	cladeString = cladeString .. indent .. '|' .. childNumber..'='  .. '{{clade'

	levelNumber=levelNumber+1
	indent = p.getIndent(levelNumber)
	
		-- protect commas in inner parentheses from split; temporarily replace commas between parentheses
	    local innerTerm2 =  string.gsub(innerTerm, "%b()",  function (n)
	                                         	return string.gsub(n, ",%s*", "XXX")  -- also strip spaces after commas here
	                                            end)
	
		local s = p.strsplit(innerTerm2, ",")
		local i=1	
		while s[i] do	
			local restoredString = string.gsub(s[i],"XXX", ",")   -- convert back to commas
	
			local outerTerm = string.gsub(restoredString, "%b()", "")
			if string.find(restoredString, '%(.*%)') then
				--cladeString = cladeString .. indent .. '|y' .. i .. '=' .. p.newickParseLevel(restoredString,levelNumber+1,i) 
				cladeString = cladeString  .. p.newickParseLevel(restoredString,levelNumber,i) 
			else
				cladeString = cladeString .. indent .. '|' .. i .. '=' .. restoredString --.. '(level=' .. levelNumber .. ')'
			end
			i=i+1
		end
--    end -- end splitting of strings

	cladeString = cladeString .. indent .. '}}'  
    return cladeString
end

function p.getIndent(levelNumber)
	local indent = "\r"
	local extraIndent = pargs['indent'] or mw.getCurrentFrame().args['indent'] or 0
	
	while tonumber(extraIndent) > 0 do
	    indent = indent .. " " -- an extra indent to make aligining compound trees easier
	    extraIndent = extraIndent - 1
	end
	
	while levelNumber > 1 do
		indent = indent .. "   "
		levelNumber = levelNumber-1
	end
	return indent
end

function p.newickstuff(newickString)

	
end
function p.processNewickString(newickString,childNumber)
	
	local maxPatterns = 5
	local i = 0
	local pargs = pargs
	local pattern = pargs['newick'..tostring(childNumber)..'-pattern'] -- unnumbered option for i=1
    local replace = pargs['newick'..tostring(childNumber)..'-replace']
	
	while i < maxPatterns do
		i=i+1
		pattern = pattern or pargs['newick'..tostring(childNumber)..'-pattern'..tostring(i)]
		replace = replace or pargs['newick'..tostring(childNumber)..'-replace'..tostring(i)] or ""
	
		if pattern then
			newickString = string.gsub (newickString, pattern, replace)
		end
        pattern = nil; replace = nil
	end
	newickString = string.gsub (newickString, "_", " ") -- replace underscore with space
	return newickString
end
------------------------------------------------------------------------------------------


function p.test2(target)
	local target ="User:Jts1882/sandbox/templates/Template:Passeroidea"
	local result = mw.getCurrentFrame():expandTemplate{ title = target, args = {['style'] = '' } }
	return result
end
-------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------

--[[function getCladeTreeInfo()
	    this preprocessing loop gets information about the whole structure (number of nodes, leaves etc)
		it makes a redundant calls to the templates through transclusion, but doen't affect the template depths; 
		it provides the global lastNode that is used to limit the main while loop
--]]
function p.getCladeTreeInfo()

    -- enable proprocessing loop
    local childNumber = 0
    local childCount =0
    local maxChildren =20
    
    --info veriables (these are global for now)
    nodeCount=0
    cladeCount=0
    leafCount=0
    
	while 	childNumber < maxChildren do -- preprocessing loop
		childNumber = childNumber + 1 -- so we start with 1
		local nodeLeaf,data = pargs[tostring(childNumber)] or ""  -- get data from |N=
        local newickString = pargs['newick'..tostring(childNumber)] or ""  -- get data from |labelN=
        local listString = pargs['list'..tostring(childNumber)] or ""  -- get data from |labelN=
		if newickString ~= "" or nodeLeaf ~= "" or listString ~= "" then
		--if nodeLeaf ~= "" then 
			childCount = childCount + 1  -- this counts child elements in this clade 
		    --[[]
		    for i in string.gmatch(nodeLeaf, "||rowspan") do -- count number of rows started (transclusion)
   				nodeCount = nodeCount + 1
     		end
		    for i in string.gmatch(nodeLeaf, '{|class="clade"') do -- count number of tables started (transclusion)
   				cladeCount = cladeCount + 1
     		end
     		]]
     		-- count occurences of clade structure using number of classes used and add to counters
            local _, nClades = string.gsub(nodeLeaf, 'class="clade"', "") 
            local _, nNodes = string.gsub(nodeLeaf, 'class="clade%-leaf"', "")
            cladeCount = cladeCount + nClades
            nodeCount = nodeCount  + nNodes
            
			lastNode = childNumber -- this gets the last node with a valid entry, even when missing numbers
		end
	end
--]]	
    -- nodes can be either terminal leaves or a clade structure (table)
    --    note: should change class clade-leaf to clade-node to reflect this
    nodeCount = nodeCount            -- number of nodes (class clade-leaf) passed down by transduction 
                    + childCount + 1 --  plus one for current clade and one for each of its child element
	cladeCount = cladeCount + 1       -- number of clade structure tables passed down by transduction (plus one for current clade)
	leafCount = nodeCount-cladeCount   -- number of terminal leaves (equals height of cladogram)
	
	-- output for testing: number of clades / total nodes / terminal nodes (=leaves)
	--                     (internal nodes)                   (cladogram height)
	infoOutput = '<small>[' .. cladeCount .. '/' .. nodeCount .. '/' .. leafCount .. ']</small>'
	
	return infoOutput 
	
end

--[[ code for placing TemplateStyles from the module
     source: Anomie (CC-0)  https://phabricator.wikimedia.org/T200442
]]

function p.templateStyle( frame, src )
   return frame:extensionTag( 'templatestyles', '', { src = src } );
end

function p.showClade(frame)
	--local code = frame.args.code or ""
    local code = frame:getParent().args['code2'] or ""
	
	--return  code 
	--return mw.text.unstrip(code)
	
	--local test = "<pre>Hello</pre>"
	--return string.sub(test,6,-7)
	
	local o1 =frame:getParent():getArgument('code2')
	return o1:expand()
	
	--return string.sub(code,2,-1)              -- strip marker  \127'"`UNIQ--tagname-8 hex digits-QINU`"'\127
	--return frame:preprocess(string.sub(code,3))
end


function p.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
--[[ function to generate cladogram from a wikitext-like list
         - uses @ instead of * because we don't want wikitext processed and nowiki elements are passed as stripmarkers (?)
]]
function p.list(count,listString)
	
	local cladeString = ""
	--count = count+1
    local list = mw.text.split(listString, "\n")
    local i=1
    local child=1
	local lastNode=0--table.getn(list) -- number of child branches (potential)

	cladeString = cladeString .. '{| class="clade" '
	
	while list[i]  do
		list[i]=list[i]:gsub("^@", "")               -- strip the first @
		
		if not string.match( list[i], "^@", 1 ) then -- count children at this level (not beginning wiht @)
			lastNode = lastNode+1  
		end
		i=i+1
	end
	
	i=1
	while list[i]  do

	    --[[ pseudocode: 
	         if next value begins with @ we have a subtree, 
	        	which must be recombined and past iteratively
	         else we have a simple leaf
	    ]]

	    -- if the next value begins with @, we have a subtree which should be recombined
	    if list[i+1] and string.match( list[i+1], "^@", 1 )  then
	    	
	        local label=list[i]
           	i=i+1
	    	local recombined = list[i]
	    	while list[i+1] and string.match( list[i+1], "^@", 1 ) do
	    		recombined = recombined .. "\n" .. list[i+1] 
	    		i=i+1
	    	end
	    	--cladeString = cladeString .. '\n' .. p.addTaxon(child, recombined, label, lastNode) 
	    	cladeString = cladeString .. '\n' .. p.addTaxon(child, p.list(count,recombined), label, lastNode) 
	    else
	    	cladeString = cladeString .. '\n' .. p.addTaxon(child, list[i], "", lastNode) 	
	    end
		i=i+1
		child=child+1
	end


	cladeString = cladeString .. '\n|}'
	
	mw.addWarning("WARNING. This is a test feature only.")
	return cladeString  
end
-- =================== experimental Newick to clade parser function =============================

--[[Function of convert Newick strings to clade format

Usage: {{#invoke:Module:Sandbox/Jts1882/CladeN|newickConverter|newickstring={{{NEWICK_STRING}}} }}
]]
function p.cladeConverter(frame)
	
end
function p.listConverter(frame)
	
	local listString = frame.args['list'] or pargs['list']

	-- show the list string
	local cladeString = ''
	local levelNumber = 1           --  for depth of iteration
	local childNumber = 1           --  number of sister elements on node  (always one for root)
	local indent = p.getIndent(levelNumber)
	--  converted the newick string to the clade structure
	cladeString = cladeString .. indent .. '{{clade'
	cladeString = cladeString .. p.listParseLevel(listString, levelNumber, childNumber) 
	--cladeString = cladeString .. '\r}}'  

	local resultString = ''
    local option = pargs['option'] or ''
    if option == 'tree' then
	 	--show the transcluded clade diagram
		resultString =   cladeString    	
    else
    	-- show the Newick string
		resultString = '<pre>'..listString..'</pre>'	
	    -- show the converted clade structure
	    resultString = resultString .. '<pre>'.. cladeString ..'</pre>'	
    end
    --resultString = frame:expandTemplate{ title = 'clade',  frame:preprocess(cladeString) }

    return resultString
end

function p.listParseLevel(listString,levelNumber,childNumber)

	local cladeString = ""
	local indent = p.getIndent(levelNumber)
    levelNumber=levelNumber+1

    local list = mw.text.split(listString, "\n")
    local i=1
    local child=1
    local lastNode=0
    
    while list[i]  do
		list[i]=list[i]:gsub("^@", "")               -- strip the first @
		
		if not string.match( list[i], "^@", 1 ) then -- count children at this level (not beginning wiht @)
			lastNode = lastNode+1  
		end
		i=i+1
	end
    i=1

	while list[i]  do

	    --[[ pseudocode: 
	         if next value begins with @ we have a subtree, 
	        	which must be recombined and past iteratively
	         else we have a simple leaf
	    ]]

	    -- if the next value begins with @, we have a subtree which should be recombined
	    if list[i+1] and string.match( list[i+1], "^@", 1 )  then
	    	
	        local label=list[i]
           	i=i+1
	    	local recombined = list[i]
	    	while list[i+1] and string.match( list[i+1], "^@", 1 ) do
	    		recombined = recombined .. "\n" .. list[i+1] 
	    		i=i+1
	    	end
	    	cladeString = cladeString .. indent .. '|label' .. child ..'=' ..  label	
	    	cladeString = cladeString .. indent .. '|' .. child ..'=' ..  '{{clade'
	    	                          .. p.listParseLevel(recombined,levelNumber,i)  
	    else
	    	cladeString = cladeString .. indent .. '|' .. child ..'=' ..  list[i]	
	    end
		i=i+1
		child=child+1
	end


	cladeString = cladeString .. indent .. '}}'  
	return cladeString
end



-- this must be at end
return p