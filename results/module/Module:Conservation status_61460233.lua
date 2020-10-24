local p = {}

-- function main() - entry point for template
function p.main(frame)
    local system = mw.text.trim(frame:getParent().args[1]) -- needs trim() for unnamed parameters
	local status = mw.text.trim(frame:getParent().args[2]) 
	local refs = mw.text.trim(frame:getParent().args[3] or "" ) 
    return '! colspan = 2 | <div style = "text-align:center;">[[Conservation status]]</div>' -- header row
           .. '\n|-'
           .. '\n| colspan = 2 | <div style = "text-align:center;">' 
           .. p._main(frame, system, status, refs) -- status content 
           .. '</div>'
        
           
end
-- function status() - entry point for direct invoke testing (assumes table structure and adds cell content)
function p.status(frame) 
	local system = mw.text.trim(frame.args[1])
	local status = mw.text.trim(frame.args[2])
	local refs = mw.text.trim(frame.args[3] or "" )
	--TODO if system and status then return
	return p._main(frame, system, status, refs)
end
function p._main(frame, system, status, refs)
    
    local output = "ERROR"
    system = string.upper(system)
    status = string.upper(status)
    local systemText = ""
    
    --TODO check for system; if none give needs handling with long list of possible statuses to match current system
   
    if system == "IUCN3.1" or system == "IUCN" then
       output = p.IUCN31(frame, system, status)
       systemText = "[[IUCN Red List|IUCN 3.1]]"
    elseif system == "IUCN2.3" then
       output = p.IUCN23(frame, system, status)
       systemText = "[[IUCN Red List|IUCN 2.3]]"
    elseif system == "CNCFLORA" then
       --output = p.CNCFlora(frame, system, status)
       output = p.UsesIUCN31(frame, system, status)    -- uses IUCN3.1 system and criteria (need to block catgories)
       systemText = "[[CNCFlora]]"
    elseif system == "TPWCA" then
       output = p.UsesIUCN31(frame, system, status)    -- uses IUCN3.1 system and criteria (need to block catgories)
       systemText = "[[NTFlora#TPWCA|TPWCA]]"
    elseif system == "NATURESERVE" or system == "TNC" then
       output = p.NatureServe(frame, system, status)
       systemText = "[[NatureServe conservation status|NatureServe]]"
    elseif system == "EPBC" then
       output = p.EPBC(frame, system, status)
       systemText = "[[Environment Protection and Biodiversity Conservation Act 1999|EPBC Act]]"
    elseif system == "ESA" then
       output = p.ESA(frame, system, status)
       systemText = "[[Endangered Species Act|ESA]]"
  	elseif system == "COSEWIC" then
       output = p.COSEWIC(frame, system, status)
       systemText = "[[Committee on the Status of Endangered Wildlife in Canada|COSEWIC]]"
 	elseif system == "DECF" then
       output = p.DECF(frame, system, status)
       systemText = "[[Declared Rare and Priority Flora List|DEC]]"
 	elseif system == "QLDNCA" then
       output = p.QLDNCA(frame, system, status)
       systemText = "[[Nature Conservation Act 1992|NCA]]"
 	elseif system == "CITES" then
       output = p.CITES(frame, system, status)
       systemText = "[[CITES]]"
 	elseif system == "NZTCS" then
       output = p.NZTCS(frame, system, status)
       systemText = "[[New Zealand Threat Classification System|NZ TCS]]"
    else
       output = p.SystemNotRecognised(frame, system, status)
       systemText = "[[" .. system .. "]]"  -- should this be linked?
    end
    if output ~= "ERROR" then
    	--[=[  template code
    	       <small>&nbsp;({{#if:{{{status_text|}}}
    	          |[[{{{status_text|#Conservation status}}}|See text]]   --  links to section in article?
    	          |[[IUCN Red List|IUCN 3.1]]}}){{{3|}}}</small>
        ]=]
        local statusText = frame:getParent().args['status_text']
        --local systemText = " [[IUCN Red List|IUCN 3.1]]"
        if statusText then 
           if statusText == "" then statusText = "#Conservation status" end
    	   systemText = "[[" .. statusText .. "|See text]]"
        end
        output = output ..  "<small>&nbsp;(" .. systemText .. ")" .. refs .. "</small>" -- "</div>"
 
        return output
    end
end
--[[ OTHER SYSTEMS
        Territory Parks and Wildlife Conservation Act 2000 (TPWCA)

]]

function  p.SystemNotRecognised(frame, system, status)
	local output = system .. ' ' .. status
   if status == "EX" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status iucn3.1 EX.svg") .. extinct 
    elseif status == "CR" then
    	output = "[[Critically endangered species|Critically Endangered]]" 
    elseif status == "EN" then	
    	output = "[[Endangered species|Endangered]]" 
    elseif status == "NT" then	
    	output = "[[Near Threatened]]" 
    else
    	output = status
    end
	return output .. p.addCategory("Taxoboxes with an unrecognised status system")
end

--***************************************** IUCN 3.1 **********************************
function p.IUCN31(frame, system, status)
	
	-- | EX = [[file:Status iucn3.1 EX.svg|frameless|link=|alt=]]<br />[[Extinction|Extinct]] {{#if:{{{extinct|}}}|&nbsp;({{{extinct}}}) }} {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List extinct species]] | }}
	-- | EW = [[file:Status iucn3.1 EW.svg|frameless|link=|alt=]]<br />[[Extinct in the Wild]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List extinct in the wild species]] | }}
	-- | CR = [[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered species|Critically Endangered]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List critically endangered species]] |}}
	-- | EN = [[file:Status iucn3.1 EN.svg|frameless|link=|alt=]]<br />[[Endangered species|Endangered]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List endangered species]] | }}
	-- | VU = [[file:Status iucn3.1 VU.svg|frameless|link=|alt=]]<br />[[Vulnerable species|Vulnerable]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List vulnerable species]] |}}

    local output = system .. ' ' .. status
    if status == "EX" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status iucn3.1 EX.svg") .. extinct .. p.addCategory("IUCN Red List extinct species")
    elseif status == "EW" then
    	output = p.addImage("Status iucn3.1 EW.svg") .. "[[Extinct in the Wild]]" .. p.addCategory("IUCN Red List extinct in the wild species")
    elseif status == "CR" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered species|Critically Endangered]]" .. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "EN" then
    	output = p.addImage("Status iucn3.1 EN.svg") .. "[[Endangered species (IUCN status)|Endangered]]" .. p.addCategory("IUCN Red List endangered species")
    elseif status == "VU" then
    	output = p.addImage("Status iucn3.1 VU.svg") .. "[[Vulnerable species|Vulnerable]]" .. p.addCategory("IUCN Red List vulnerable species")

-- | NT = [[file:Status iucn3.1 NT.svg|frameless|link=|alt=]]<br />[[Near Threatened]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List near threatened species]] | }}
-- | LC = [[file:Status iucn3.1 LC.svg|frameless|link=|alt=]]<br />[[Least Concern]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List least concern species]] |}}
-- | DD = [[file:Status iucn3.1 blank.svg|frameless|link=|alt=]]<br/>[[Data Deficient]] {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List data deficient species]] |}}
-- | NE = ''Not evaluated''
-- | NR = ''Not recognized''
-- | PE = [[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List critically endangered species]] |}}
-- | PEW = [[file:Status iucn3.1 CR.svg|frameless|link=|alt=]]<br />[[Critically endangered]], possibly extinct in the wild {{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:IUCN Red List critically endangered species]]|}}


    elseif status == "NT" then
    	output = p.addImage("Status iucn3.1 NT.svg") .. "[[Near Threatened]]" .. p.addCategory("IUCN Red List near threatened species")
    elseif status == "LC" then
    	output = p.addImage("Status iucn3.1 LC.svg") .. "[[Least Concern]]" .. p.addCategory("IUCN Red List least concern species")
    elseif status == "DD" then
    	output = p.addImage("Status iucn3.1 blank.svg") .. "[[Data Deficient]]" .. p.addCategory("IUCN Red List data deficient species")
    elseif status == "NE" then
    	output = "''Not evaluated''" 
    elseif status == "NR" then
    	output =  "''Not recognized''" 
    elseif status == "PE" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered]], possibly extinct" .. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "PEW" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered]], possibly extinct in the wild" .. p.addCategory("IUCN Red List critically endangered species")
    else 
    	-- | '''''Invalid status'''''{{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:Invalid conservation status]]|}}
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
    end  
 
 -- | '''''Invalid status'''''{{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:Invalid conservation status]]|}}
 --}}<small>&nbsp;({{#if:{{{status_text|}}}|[[{{{status_text|#Conservation status}}}|See text]]|[[IUCN Red List|IUCN 3.1]]}}){{{3|}}}</small></div><!--
   
 --   local thirdParam = "" --mw.text.trim(frame:getParent().args[3] or "")
 --   local statusText = frame:getParent().args['status_text']
  --  local systemText = " [[IUCN Red List|IUCN 3.1]]"
 --   if statusText then 
 --   	systemText = "[[{{{status_text|#Conservation status}}}|See text]]"
 --   end
 --   output = output ..  "<small>&nbsp;(" .. systemText .. thirdParam .. ")</small></div>"
    return output 
end

-- ********************************* IUCN 2.3 **********************************************
function p.IUCN23(frame, system, status)
	
    local output = system .. ' ' .. status
    if status == "EX" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status iucn2.3 EX.svg") .. extinct .. p.addCategory("IUCN Red List extinct species")
    elseif status == "EW" then
    	output = p.addImage("Status iucn2.3 EW.svg") .. "[[Extinct in the Wild]]" .. p.addCategory("IUCN Red List extinct in the wild species")
    elseif status == "CR" then
    	output = p.addImage("Status iucn2.3 CR.svg") .. "[[Critically endangered species|Critically Endangered]]" .. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "EN" then
    	output = p.addImage("Status iucn2.3 EN.svg") .. "[[Endangered species (IUCN status)|Endangered]]" .. p.addCategory("IUCN Red List endangered species")
    elseif status == "VU" then
    	output = p.addImage("Status iucn2.3 VU.svg") .. "[[Vulnerable species|Vulnerable]]" .. p.addCategory("IUCN Red List vulnerable species")
    elseif status == "LR" then
    	output = p.addImage("Status iucn2.3 blank.svg") .. "Lower risk" .. p.addCategory("Invalid conservation status")
    elseif status == "CD" or status == "LR/CD" then
        output = p.addImage("Status iucn2.3 CD.svg") .. "[[Conservation Dependent]]" .. p.addCategory("IUCN Red List conservation dependent species")
    elseif status == "NT" or status == "LR/NT" then
    	output = p.addImage("Status iucn2.3 NT.svg") .. "[[Near Threatened]]" .. p.addCategory("IUCN Red List near threatened species")
    elseif status == "LC" or status == "LR/LC" then
    	output = p.addImage("Status iucn2.3 LC.svg") .. "[[Least Concern]]" .. p.addCategory("IUCN Red List least concern species")
    elseif status == "DD" then
    	output = p.addImage("Status iucn2.3 blank.svg") .. "[[Data Deficient]]" .. p.addCategory("IUCN Red List data deficient species")
    elseif status == "NE" then
    	output = "''Not evaluated''" 
    elseif status == "NR" then
    	output =  "''Not recognized''" 
    elseif status == "PE" then
    	output = p.addImage("Status iucn2.3 CR.svg") .. "[[Critically endangered]], possibly extinct" .. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "PEW" then
    	output = p.addImage("Status iucn2.3 CR.svg") .. "[[Critically endangered]], possibly extinct in the wild" .. p.addCategory("IUCN Red List critically endangered species")
    else     	-- | '''''Invalid status'''''{{#ifeq: {{NAMESPACEE}} | {{ns: 0}} | [[Category:Invalid conservation status]]|}}
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
    end  
 
    return output 
end

--******************************************* CNCFlora***************************************

-- Note: this is not needed if using IUCN 3.1 system and criteria; just use that function with no catgories
-- alternatively rename this function as p.UsesIUCN31()
--function p.CNCFlora(frame, system, status)
function p.UsesIUCN31(frame, system, status)
	

    local output = system .. ' ' .. status
    if status == "EX" then
    	output = p.addImage("Status iucn3.1 EX.svg") .. "[[Extinction|Extinct]]" --.. p.addCategory("IUCN Red List extinct species")
    elseif status == "EW" then
    	output = p.addImage("Status iucn3.1 EW.svg") .. "[[Extinct in the Wild]]" --.. p.addCategory("IUCN Red List extinct in the wild species")
    elseif status == "CR" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered species|Critically Endangered]]" --.. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "EN" then
    	output = p.addImage("Status iucn3.1 EN.svg") .. "[[Endangered species|Endangered]]" --.. p.addCategory("IUCN Red List endangered species")
    elseif status == "VU" then
    	output = p.addImage("Status iucn3.1 VU.svg") .. "[[Vulnerable species|Vulnerable]]" --.. p.addCategory("IUCN Red List vulnerable species")
    elseif status == "NT" then
    	output = p.addImage("Status iucn3.1 NT.svg") .. "[[Near Threatened]]" --.. p.addCategory("IUCN Red List near threatened species")
    elseif status == "LC" then
    	output = p.addImage("Status iucn3.1 LC.svg") .. "[[Least Concern]]" --.. p.addCategory("IUCN Red List least concern species")
    elseif status == "DD" then
    	output = p.addImage("Status iucn3.1 blank.svg") .. "[[Data Deficient]]" --.. p.addCategory("IUCN Red List data deficient species")
    elseif status == "NE" then
    	output = "''Not evaluated''" 
    elseif status == "NR" then
    	output =  "''Not recognized''" 
    elseif status == "PE" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered]], possibly extinct" --.. p.addCategory("IUCN Red List critically endangered species")
    elseif status == "PEW" then
    	output = p.addImage("Status iucn3.1 CR.svg") .. "[[Critically endangered]], possibly extinct in the wild" --.. p.addCategory("IUCN Red List critically endangered species")
    else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
    end  
 
   return output 
end
-- *************** Natureserve/TNC ********************************
function p.NatureServe(frame, system, status)

   local output = system .. ' ' .. status
   if status == "GX" then
    	local extinct = "Presumed [[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status TNC GX.svg") .. extinct .. p.addCategory("NatureServe presumed extinct species")
   elseif status == "GH" then
    	output = p.addImage("Status TNC GH.svg") .. "Possibly [[Extinction|Extinct]]" .. p.addCategory("NatureServe possibly extinct species")
   elseif status == "G1" then
    	output = p.addImage("Status TNC G1.svg") .. "Critically Imperiled" .. p.addCategory("NatureServe critically imperiled species")
   elseif status == "G2" then
    	output = p.addImage("Status TNC G2.svg") .. "Imperiled" .. p.addCategory("NatureServe imperiled species")
   elseif status == "G3" then
    	output = p.addImage("Status TNC G3.svg") .. "Vulnerable" .. p.addCategory("NatureServe vulnerable species")
   elseif status == "G4" then
    	output = p.addImage("Status TNC G4.svg") .. "Apparently Secure" .. p.addCategory("NatureServe apparently secure species")
   elseif status == "G5" then
    	output = p.addImage("Status TNC G5.svg") .. "Secure" .. p.addCategory("NatureServe secure species")
   elseif status == "GU" then
    	output = p.addImage("Status TNC blank.svg") .. "Unrankable"
   elseif status == "TX" then
    	local extinct = "Presumed [[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status TNC TX.svg") .. extinct .. p.addCategory("NatureServe presumed extinct species")
   elseif status == "TH" then
    	output = p.addImage("Status TNC TH.svg") .. "Possibly [[Extinction|Extinct]]" .. p.addCategory("NatureServe possibly extinct species")
   elseif status == "T1" then
    	output = p.addImage("Status TNC T1.svg") .. "Critically Imperiled" .. p.addCategory("NatureServe critically imperiled species")
   elseif status == "T2" then
    	output = p.addImage("Status TNC T2.svg") .. "Imperiled" .. p.addCategory("NatureServe imperiled species")
   elseif status == "T3" then
    	output = p.addImage("Status TNC T3.svg") .. "Vulnerable" .. p.addCategory("NatureServe vulnerable species")
   elseif status == "T4" then
    	output = p.addImage("Status TNC T4.svg") .. "Apparently Secure" .. p.addCategory("NatureServe apparently secure species")
   elseif status == "T5" then
    	output = p.addImage("Status TNC T5.svg") .. "Secure" .. p.addCategory("NatureServe secure species")
   elseif status == "TU" then
    	output = p.addImage("Status TNC blank.svg") .. "Unrankable"
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end  
   return output 
end

-- ********* EPBC: Environment Protection and Biodiversity Conservation Act 1999 (Australia) ************
function p.EPBC(frame, system, status)

   local output = system .. ' ' .. status
   if status == "EX" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status EPBC EX.svg") .. extinct .. p.addCategory("EPBC Act extinct biota")
   elseif status == "EW" then
    	output = p.addImage("Status EPBC EW.svg") .. "[[Extinct in the Wild]]" .. p.addCategory("EPBC Act extinct in the wild biota")
   elseif status == "CR" then
    	output = p.addImage("Status EPBC CR.svg") .. "[[Critically endangered species|Critically endangered]]" .. p.addCategory("EPBC Act critically endangered biota")
   elseif status == "EN" then
    	output = p.addImage("Status EPBC EN.svg") .. "[[Endangered species|Endangered]]" .. p.addCategory("EPBC Act endangered biota")
   elseif status == "VU" then
    	output = p.addImage("Status EPBC VU.svg") .. "[[Vulnerable species|Vulnerable]]" .. p.addCategory("EPBC Act vulnerable biota")
   elseif status == "CD" then
    	output = p.addImage("Status EPBC CD.svg") .. "[[Conservation Dependent]]" .. p.addCategory("EPBC Act conservation dependent biota")
   elseif status == "DL"  or status == "DELISTED" then
    	output = p.addImage("Status EPBC DL.svg") .. "Delisted" 
    	
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end  
  
   return output 
end

-- *************** ESA ********************************
function p.ESA(frame, system, status)

   local output = system .. ' ' .. status
   if status == "EX" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status ESA EX.svg") .. extinct 
   elseif status == "LE" or status == "E" then
    	output = p.addImage("Status ESA LE.svg") .. "[[Endangered species|Endangered]]" 
   elseif status == "LT" or status == "T" then
    	output = p.addImage("Status ESA EX.svg") .. "[[Threatened species|Threatened]]" 
   elseif status == "DL"  or status == "DELISTED" then
    	output = p.addImage("Status ESA DL.svg") .. "Delisted" 
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end        

   return output 
end
-- ********** COSEWIC: Committee on the Status of Endangered Wildlife in Canada **************
function p.COSEWIC(frame, system, status)

   local output = system .. ' ' .. status
   if status == "X" then
    	local extinct = "[[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status COSEWIC X.svg") .. extinct 
   elseif status == "XT" then
   	    output = p.addImage("Status COSEWIC XT.svg") .. "Extirpated (Canada)"
   elseif status == "E" then
    	output = p.addImage("Status COSEWIC E.svg") .. "[[Endangered species|Endangered]]" 
   elseif  status == "T" then
    	output = p.addImage("Status COSEWIC T.svg") .. "[[Threatened species|Threatened]]" 
   elseif  status == "SC" then
    	output = p.addImage("Status COSEWIC SC.svg") .. "Special Concern" 
   elseif  status == "NAR" then
    	output = p.addImage("Status COSEWIC NAR.svg") .. "[[Least Concern|Not at risk]]" 
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end     
   return output 
end
-- *************** DECF ********************************
function p.DECF(frame, system, status)

   local output = system .. ' ' .. status
   if status == "X" then
    	local extinct = "Declared Rare&nbsp;— Presumed [[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status DECF X.svg") .. extinct 
   elseif status == "R" then
    	output = p.addImage("Status DECF R.svg") .. "Declared [[Rare species|rare]]" 
   elseif status == "P1"  then
    	output = p.addImage("Status DECF P1.svg") .. "Priority One&nbsp;— Poorly Known Taxa" 
   elseif status == "P2"  then
    	output = p.addImage("Status DECF P2.svg") .. "Priority Two&nbsp;— Poorly Known Taxa" 
   elseif status == "P3"  then
    	output = p.addImage("Status DECF P3.svg") .. "Priority Three&nbsp;— Poorly Known Taxa" 
   elseif status == "P4"  then
    	output = p.addImage("Status DECF P4.svg") .. "Priority Four&nbsp;— Rare Taxa" 
   elseif status == "DL"  or status == "DELISTED" then
    	output = p.addImage("Status DECF DL.svg") .. "Delisted" 
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end        

   return output 
end



-- *************** QLDNCA ********************************
function p.QLDNCA(frame, system, status)

   local output = system .. ' ' .. status
   if status == "EX"  then
    	output = "[[Extinct]]" .. p.addCategory("Nature Conservation Act extinct biota")
   elseif status == "EW"  then
    	output = "[[Extinct in the Wild]]" .. p.addCategory("Nature Conservation Act extinct in the wild biota")
   elseif status == "CR" then
    	output = "[[Critically endangered species|Critically Endangered]]" .. p.addCategory("Nature Conservation Act critically endangered biota")
   elseif status == "EN" then
    	output = "[[Endangered species|Endangered]]" .. p.addCategory("Nature Conservation Act endangered biota")
   elseif status == "VU" then
    	output = "[[Vulnerable species|Vulnerable]] " .. p.addCategory("Nature Conservation Act vulnerable biota")
   elseif status == "R" then
    	output = "Rare" .. p.addCategory("Nature Conservation Act rare biota")
   elseif status == "NT" then
    	output = "[[Near Threatened]]" .. p.addCategory("Nature Conservation Act near threatened biota")
   elseif status == "LC" then
    	output = "[[Least Concern]]" .. p.addCategory("Nature Conservation Act least concern biota")
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end        
   
   return output 
end

-- *************** CITES ********************************
function p.CITES(frame, system, status)

   local output = system .. ' ' .. status
   if status == "CITES_A1" then
    	output = "[[CITES]] Appendix I" 
   elseif status == "CITES_A2" then
    	output = "[[CITES]] Appendix II" 
   elseif status == "CITES_A3" then
    	output = "[[CITES]] Appendix III" 
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end 
   return output 

end

-- *************** NZTCS ********************************
function p.NZTCS(frame, system, status)

   local output = system .. ' ' .. status
   if status == "EX" then
    	local extinct = "Declared Rare&nbsp;— Presumed [[Extinction|Extinct]]"
    	if frame:getParent().args['extinct'] then extinct = "&nbsp;(" .. frame:getParent().args['extinct'] .. ")" end
    	output = p.addImage("Status NZTCS EX.svg") .. extinct 
   elseif status == "NC" then
    	output = p.addImage("Status NZTCS NC.svg") .. "Nationally Critical" 
   elseif status == "NE"  then
    	output = p.addImage("Status NZTCS NE.svg") .. "Nationally endangered" 
   elseif status == "NV"  then
    	output = p.addImage("Status NZTCS NV.svg") .. "Nationally vulnerable" 
   elseif status == "SD"  then
    	output = p.addImage("Status NZTCS SD.svg") .. "Serious Decline" 
   elseif status == "GD"  then
    	output = p.addImage("Status NZTCS GD.svg") .. "Gradual Decline" 
   elseif status == "SP"  then
    	output = p.addImage("Status NZTCS SP.svg") .. "Sparse" 
   elseif status == "RR"  then
    	output = p.addImage("Status NZTCS RR.svg") .. "Range Restricted" 
   else 
    	output = "'''''Invalid status'''''" .. p.addCategory("Invalid conservation status")
   end        
   
   return output 

end


-- *************** functions  for image and category output ********
function p.addImage(file)
    if file ~= "" then
    	return "[[File:" .. file .. "|frameless|link=|alt=]]<br />"
    end
    return ""
end
function p.addCategory(category)
	local ns = mw.title.getCurrentTitle().namespace
    -- ns = 0 -- to test category put on page
	if category ~= "" and ns == 0 then
		return "[[Category:" .. category .. "]]"
    end
    return ""
end


return p