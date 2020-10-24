-- this module provides a lookup from ATC codes to their associated navbox templates --

p = {}

local frame = mw.getCurrentFrame()

local input = tostring(frame.args[1])

p.lookuptable = {
{ code="A01", template="Stomatological preparations",},
{ code="A02A", template="Antacids", },
{ code="A02B", template="Drugs for peptic ulcer and GORD", },
{ code="A03", template="Drugs for functional gastrointestinal disorders", },
{ code="A04", template="Antiemetics", },
{ code="A05", template="Bile and liver therapy", },
{ code="A06", template="Laxatives", },
{ code="A07", template="Antidiarrheals, intestinal anti-inflammatory and anti-infective agents", },
{ code="A08", template="Antiobesity preparations", },
{ code="A09", template="Digestives", },
{ code="A10", template="Oral hypoglycemics and insulin analogs", },
{ code="A11", template="Vitamins", },
{ code="A12", template="Mineral supplements", },
{ code="A14A", template="Androgens and antiandrogens", },
{ code="A15", template="Appetite stimulants", },
{ code="A16", template="Other alimentary tract and metabolism products", },
{ code="B01", template="Antithrombotics", },
{ code="B02", template="Antihemorrhagics", },
{ code="B03", template="Antianemic preparations", },
{ code="B05", template="Blood substitutes and perfusion solutions", },
{ code="B06", template="Other hematological agents", },
{ code="C01A", template="Cardiac glycosides", },
{ code="C01B", template="Antiarrhythmic agents", },
{ code="C01C", template="Cardiac stimulants excluding cardiac glycosides", },
{ code="C01D", template="Vasodilators used in cardiac diseases", },
{ code="C02", template="ATC code C02", },
{ code="C03", template="Diuretics", },
{ code="C04", template="Peripheral vasodilators", },
{ code="C05", template="Vasoprotectives", },
{ code="C07", template="Beta blockers", },
{ code="C08", template="Ion channel modulators", },
{ code="C09", template="Agents acting on the renin-angiotensin system", },
{ code="C10", template="Lipid modifying agents", },
{ code="D01", template="Antifungals", },
{ code="D02", template="Emollients and protectives", },
{ code="D03", template="Preparations for treatment of wounds and ulcers", },
{ code="D04", template="Antipruritics", },
{ code="D05", template="Antipsoriatics", },
{ code="D06", template="Antibiotics and chemotherapeutics for dermatological use", },
{ code="D07", template="Glucocorticoids and antiglucocorticoids", },
{ code="D08", template="Antiseptics and disinfectants", },
{ code="D09", template="Medicated dressings", },
{ code="D10", template="Acne-treating agents", },
{ code="D11", template="Other dermatological preparations", },
{ code="G01", template="Gynecological anti-infectives and antiseptics", },
{ code="G02A", template="Uterotonics", },
{ code="G02B", template="Birth control methods", },
{ code="G02CA", template="Labor repressants", },
{ code="G02CB", template="Prolactin inhibitors and anti-inflammatory products for vaginal administration", },
{ code="G02CC", template="Prolactin inhibitors and anti-inflammatory products for vaginal administration", },
{ code="G03A", template="Birth control methods", },
{ code="G03G", template="GnRH and gonadotropins", },
{ code="G03X", template="Other sex hormones and modulators of the genital system", },
{ code="G04B", template="Urologicals, including antispasmodics", },
{ code="G04BE", template="Drugs for erectile dysfunction and premature ejaculation", },
{ code="G04C", template="Drugs used in benign prostatic hypertrophy", },
{ code="H01", template="Pituitary and hypothalamic hormones and analogues", },
{ code="H02", template="Corticosteroids", },
{ code="H03", template="Thyroid therapy", },
{ code="H05", template="Calcium homeostasis", },
{ code="J01A", template="Protein synthesis inhibitor antibiotics", },
{ code="J01B", template="Protein synthesis inhibitor antibiotics", },
{ code="J01F", template="Protein synthesis inhibitor antibiotics", },
{ code="J01G", template="Protein synthesis inhibitor antibiotics", },
{ code="J01C", template="Cell wall disruptive antibiotics", },
{ code="J01D", template="Cell wall disruptive antibiotics", },
{ code="J01E", template="Nucleic acid inhibitors", },
{ code="J01M", template="Nucleic acid inhibitors", },
{ code="J01X", template="Other antibacterials", },
{ code="J02", template="Antifungals", },
{ code="J04", template="Antimycobacterials", },
{ code="J05", template="ATC code J05", },
{ code="J06", template="Immune sera and immunoglobulins", },
{ code="J07", template="Vaccines", },
{ code="L01", template="ATC code L01", },
{ code="L02", template=42, },
{ code="L03", template="Immunostimulants", },
{ code="L04", template="Immunosuppressants", },
{ code="M01A", template="Anti-inflammatory products", },
{ code="M01C", template="Antirheumatic products", },
{ code="M02", template="Topical products for joint and muscular pain", },
{ code="M03", template="Muscle relaxants", },
{ code="M04", template="Antigout preparations", },
{ code="M05", template="Drugs for treatment of bone diseases", },
{ code="N01A", template="General anesthetics", },
{ code="N01B", template="Local anesthetics", },
{ code="N02A", template="Analgesics", },
{ code="N02B", template="Analgesics", },
{ code="N02C", template="Antimigraine preparations", },
{ code="N03", template="Anticonvulsants", },
{ code="N04", template="Antiparkinson agents", },
{ code="N05A", template="Antipsychotics", },
{ code="N05B", template="Anxiolytics", },
{ code="N05C", template="Hypnotics and sedatives", },
{ code="N06A", template="Antidepressants", },
{ code="N06B", template="Stimulants", },
{ code="N06D", template="Anti-dementia drugs", },
{ code="N07A", template="Cholinergics", },
{ code="N07B", template="Drugs used in addictive disorders", },
{ code="N07C", template="Antivertigo preparations", },
{ code="N07X", template="Other nervous system drugs", },
{ code="P01", template="ATC code P01", },
{ code="P02", template="Anthelmintics", },
{ code="P03", template="Anti-arthropod medications", },
{ code="R01", template="Nasal preparations", },
{ code="R02", template="Throat preparations", },
{ code="R03", template="Drugs for obstructive airway diseases", },
{ code="R05", template="Cough and cold preparations", },
{ code="R06", template="Antihistamines", },
{ code="R07", template="Other respiratory system products", },
{ code="S01A", template="Ophthalmological anti-infectives", },
{ code="S01E", template="Antiglaucoma preparations and miotics", },
{ code="S01F", template="Mydriatics and cycloplegics", },
{ code="S01H", template="Local anesthetics", },
{ code="S01L", template="Ocular vascular disorder agents", },
{ code="S02", template="Otologicals", },
{ code="V03AB", template="Antidotes", },
{ code="V03AC", template="Chelating agents", },
{ code="V03AE", template="Drugs for treatment of hyperkalemia and hyperphosphatemia", },
{ code="V03AF", template="Detoxifying agents for antineoplastic treatment", },
{ code="V03AG", template="Other therapeutic products", },
{ code="V03AH", template="Other therapeutic products", },
{ code="V03AK", template="Other therapeutic products", },
{ code="V03AM", template="Other therapeutic products", },
{ code="V03AN", template="Other therapeutic products", },
{ code="V03AX", template="Other therapeutic products", },
{ code="V03AZ", template="Other therapeutic products", },
{ code="V04", template="Diagnostic agents", },
{ code="V08", template="Contrast media", },
{ code="V09", template="Diagnostic radiopharmaceuticals", },
{ code="V10", template="Therapeutic radiopharmaceuticals", },
{ code="A02", template=42, },
{ code="C01", template=42, },
{ code="G02", template=42, },
{ code="G02C", template=42, },
{ code="G03", template=42, },
{ code="G04", template=42, },
{ code="J01", template=42, },
{ code="M01", template=42, },
{ code="N01", template=42, },
{ code="N02", template=42, },
{ code="N05", template=42, },
{ code="N06", template=42, },
{ code="N07", template=42, },
{ code="S01", template=42, },
{ code="V03", template=42, },
{ code="V03A", template=42, },

}

function p.translate ()
	for k,v in pairs(p.lookuptable) do
		if v.code == input then
			p.nameoftemplate = v.template
			if ( p.nameoftemplate == 42 ) then
				p.out = 1
				error("ATC code not specific enough - please use one further character (example: instead of M01, use M01A)")
				end
			if ( p.nameoftemplate == tostring(42) ) then
				p.out = 1
				error("ATC code not specific enough - please use one further character (example: instead of M01, use M01A)")
				end
			if ( p.nameoftemplate ~= nil ) then
				p.out = frame:expandTemplate{ title = p.nameoftemplate }
				end
			end
    	end
    if p.out == nil then
        error("Invalid ATC code (or the ATC code does not have a template matched to it)")
    end
    if ( p.out ~= 1 ) then
    	return p.out
	end
end

return p