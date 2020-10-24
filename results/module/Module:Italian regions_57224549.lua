local p = {}
local getArgs = require('Module:Arguments').getArgs
local data = {
	ABR = {name="Abruzzo", coa="Regione-Abruzzo-Stemma.svg"},
	BAS = {name="Basilicata", coa="Regione-Basilicata-Stemma.svg"},
	CAL = {name="Calabria", coa="Coat_of_arms_of_Calabria.svg"},
	CAM = {name="Campania", coa=""},
	EMR = {name="Emilia-Romagna", coa="Regione-Emilia-Romagna-Stemma.png"},
	FVG = {name="Friuli – Venezia Giulia", coa="Regione-Friuli-Venezia-Giulia-Stemma.png"},
	LAZ = {name="Lazio", coa="Lazio-Stemma.png"},
	LIG = {name="Liguria", coa="Regione-Liguria-Stemma.png"},
	LOM = {name="Lombardy", coa="Regione-Lombardia-Stemma.svg"},
	MAR = {name="Marche", coa="Coat of arms of Marche.svg"},
	MOL = {name="Molise", coa="Regione-Molise-Stemma.svg"},
	PMN = {name="Piedmont", coa="Regione-Piemonte-Stemma.svg"},
	PUG = {name="Apulia", coa="Regione Puglia-Stemma.png"},
	SAR = {name="Sardinia", coa="Sardegna-Stemma.svg"},
	SIC = {name="Sicily", coa="Regione-Sicilia-Stemma.png"},
	TOS = {name="Tuscany", coa="Regione-Toscana-Stemma.png"},
	TAA = {name="Trentino-Alto Adige/Südtirol", coa="Coat of arms of Trentino-South Tyrol.svg"},
	UMB = {name="Umbria", coa="Regione-Umbria-Stemma.svg"},
	VAO = {name="Aosta Valley", coa="Valle_d%27Aosta-Stemma.svg"},
	VEN = {name="Veneto", coa="Flag of Veneto.png"},
}
require('Module:No globals')

function p.main(frame)
	local args = getArgs(frame)
	local p_data = data[args[1]]
	local config = frame.args
	if p_data then
		if config.link=='false' then
			return p_data.name
		else
			return '[[' .. p_data.name .. ']]'
		end
	end
end

function p.coat_of_arms(frame)
	local args = getArgs(frame)
	local p_data = data[args[1]]
	if p_data then
		return p_data.coa
	end
end

return p