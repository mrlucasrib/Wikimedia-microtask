--[[  
Modul für Hilfsfunktionen für Vorlage:InfoFlora
]]
local p = { }

function p.formatScientificName(frame)
--[[  
    Wissenschaftlichen Namen (einschl. Autorenangabe) formatieren
    Parameter: 
    *    wiss. Name ohne Formatierung
]]
    local sciname_pure = frame.args[1]
	sciname_pure = mw.ustring.gsub(sciname_pure, "''", "") -- Eventuelle Eigenformatierungen sicherheitshalber entfernen    
	local sciname_parts = mw.text.split(sciname_pure, "%s")

    --  besondere entkursivierende Besandteile (nicht abgekürzte Schlüsselworte
    local tab_keywords_non_abrev = { sensu = true;
    							     ["&"] = true
    	}
    	
	local first_part = true
		
	for key, part in ipairs(sciname_parts) do
		local firstchar = mw.ustring.sub(part, 1, 1)
		local lastchar = mw.ustring.sub(part, -1, -1)		
		if    (not first_part and mw.ustring.upper(firstchar) == firstchar)
		   or firstchar == '('		
		   or lastchar == '.'
		   or firstchar == '[' -- für Zusätze der Art "[s.str. prov.]", siehe https://www.infoflora.ch/de/flora/leucanthemopsis-alpina-sstr-prov.html
		   or lastchar == ']' -- dto.
		   or tab_keywords_non_abrev[part] == true
		   then 
		   		part = "''" .. part .. "''"
		   		sciname_parts[key]=part
		end
		first_part = false
	end
	
	local sciname_formatted = table.concat(sciname_parts, " ") -- wieder zusammensetzen
    
    -- Workaround: Brackets müssen escaped werden
	sciname_formatted  = mw.ustring.gsub(sciname_formatted, "%[", "&#91;")
	sciname_formatted  = mw.ustring.gsub(sciname_formatted, "%]", "&#93;")    

    sciname_formatted = "''" .. sciname_formatted .. "''" -- gesamten Namen Kursivsetzen

	-- Doppelte "''" entfernen
	sciname_formatted  = mw.ustring.gsub(sciname_formatted, "'' ''", " ")
	sciname_formatted  = mw.ustring.gsub(sciname_formatted, "''''", "")	
   
    return sciname_formatted 
end
 
return p