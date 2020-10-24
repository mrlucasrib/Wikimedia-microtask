--[[
Power supply units
Custom module to autofill six parameters for use in Template:Infobox power station
Parameters are:
ps_units_operational
	→ The number of generation units operational and their nameplate capacity
	→ Example: 3 × 100 MW<br>1 × 110 MW
ps_units_manu_model
	→ The manufacturer and model of the generation units
	→ Example: Vestas V164
ps_units_uc
	→ The number of generation units under construction
	→ Example: 2 × 150 MW<br>1 × 160 MW
ps_units_decommissioned
	→ The number of generation units decommissioned
	→ Example: 1 × 75 MW<br>1 × 70 MW
ps_units_planned

ps_units_cancelled

--]]

local p = {}

local i18n = {
	["langcode"] = "en",
	["op_lbl"] = "Units&nbsp;operational",
	["mm_lbl"] = "Make&nbsp;and&nbsp;model",
	["uc_lbl"] = "Units&nbsp;under&nbsp;const.",
	["dc_lbl"] = "Units&nbsp;decommissioned",
	["pl_lbl"] = "Units&nbsp;planned",
	["ca_lbl"] = "Units&nbsp;cancelled",
}

-- numerically sort sequential tables whose values contain a number, like "350 MW"
-- sort on first number found
local function numcomp1( x, y )
	x = tonumber( tostring(x):match("%d+") ) or 0
	y = tonumber( tostring(y):match("%d+") ) or 0
	return x < y
end

-- numerically sort sequential tables whose values contain two numbers, like "1 x 350 MW"
-- sort on second number found
local function numcomp2( x, y )
	x = tonumber( tostring(x):match("%d+%D+(%d+)") ) or 0
	y = tonumber( tostring(y):match("%d+%D+(%d+)") ) or 0
	return x < y
end

-- alphabetically sort sequential tables whose values may contain wikilinks.
-- Formats: "[[Link|Text]]" or "[[Link]]" or "Text"
local function linkcomp( a, b )
	-- a = a:gsub("%[%[.*|", ""):gsub("%[%[", ""):gsub("]]","") -> test for best
	a = a:match("%[%[.*|(.*)]]") or a:match("%[%[(.*)]]") or a
	b = b:match("%[%[.*|(.*)]]") or b:match("%[%[(.*)]]") or b
	return a < b
end

--Render monolingual text
local function rendermlt(props, langcode)
	for k, v in ipairs(props) do
		v = v.mainsnak or v
		if v.snaktype == "value" and v.datavalue.value.language == langcode then
			return v.datavalue.value.text
		end
	end
end

-- Render quantity from snak
local function renderqty(snak, langcode)
	if snak and snak.snaktype == "value" then
		qty = tonumber(snak.datavalue.value.amount)
		if not qty then return end
		-- get qid of unit
		local uqid = (snak.datavalue.value.unit or ""):match("(Q%d+)")
		-- scan table of unit symbols
		local usym = ""
		for i2, v2 in ipairs( mw.wikibase.getAllStatements(uqid, "P5061") ) do
			if v2.mainsnak.snaktype == "value"
			and v2.mainsnak.datavalue.value.language == langcode then
				usym = "&nbsp;" .. v2.mainsnak.datavalue.value.text
				break
			end
		end
		return qty .. usym
	end
end

-- Take a qid and return the shortname (P1813) or label, linked to an article if possible
local function linkedname(qid, langcode)
	local props1813 = mw.wikibase.getBestStatements(qid, "P1813")
	-- may have to use mw.wikibase.getLabelByLang(qid, langcode) on multi-lingual wikis:
	local lbl = rendermlt(props1813, langcode) or mw.wikibase.getLabel(qid)
	local lnk = mw.wikibase.getSitelink(qid)
	return lnk and lbl and ("[[" .. lnk .. "|" .. lbl .."]]")
		or lnk and ("[[" .. lnk .. "]]")
		or lbl
end

p.psunits = function(frame)
	local args = frame.args
	local psu_op = args.ps_units_operational or ""
	local psu_mm = args.ps_units_manu_model or ""
	local psu_uc = args.ps_units_uc or ""
	local psu_dc = args.ps_units_decommissioned or ""
	local psu_pl = args.ps_units_planned or ""
	local psu_ca = args.ps_units_cancelled or ""
	local qid = args.qid or ""
	if qid == "" then qid = mw.wikibase.getEntityIdForCurrentPage() end
	if not qid then return nil end

	local langcode = args.lang or ""
	if langcode == "" then langcode = i18n.langcode end

	local status = {}
	local mm = {}
	local cap = {}
	local num = {}

	local props516 = mw.wikibase.getBestStatements(qid, "P516")
	if #props516 > 0 then
		for i1, v1 in ipairs(props516) do
			-- set default count of this engine to 1
			num[i1] = 1
			-- set default status of this engine to planned
			status[i1] = "pl"
			-- model should be value of P516, get manufacturer from the linked P176 and capacity from linked P2109
			-- if there is a value that isn't a model, just use the value
			local mdlqid = (v1.mainsnak.snaktype == "value") and v1.mainsnak.datavalue.value.id
			if mdlqid then
				-- look for a shortname to use for model display label, otherwise use model label
				local mdl = linkedname(mdlqid, langcode)
				local mfr
				local props176snak = mw.wikibase.getBestStatements(mdlqid, "P176")[1]
				if props176snak then
					-- model has a manufacturer
					props176snak = props176snak and props176snak.mainsnak
					local mfrqid = (props176snak.snaktype == "value") and props176snak.datavalue.value.id
					if mfrqid then
						-- look for a shortname to use for manufacturer display label, otherwise use manufacturer label
						mfr = linkedname(mfrqid, langcode)
					end
				end
				mm[i1] = mfr and mdl and (mfr .. " " .. mdl) or mfr or mdl
				-- get default capacity
				local props2109snak = mw.wikibase.getBestStatements(mdlqid, "P2109")[1]
				props2109snak = props2109snak and props2109snak.mainsnak
				cap[i1] = renderqty(props2109snak, langcode)
			elseif v1.mainsnak.snaktype == "somevalue" then
				mm[i1] = "Unknown"
				-- set default capacity
				cap[i1] = 0
			end

			local quals = v1.qualifiers
			if quals then
				-- determine status from service retirement/entry/inception
				local dcsnak = quals.P730 and quals.P730[1].snaktype
				local opsnak = quals.P729 and quals.P729[1].snaktype
				local ucsnak = quals.P571 and quals.P571[1].snaktype
				if dcsnak == "value" or dcsnak == "somevalue" then
					status[i1] = "dc"
				elseif opsnak == "value" or opsnak == "somevalue" then
					status[i1] = "op"
				elseif ucsnak == "value" or ucsnak == "somevalue" then
					status[i1] = "uc"
				end
				-- override if state of use (P5817) is cancelled-abandoned (Q30108381)
				if quals.P5817
					and quals.P5817[1].snaktype == "value"
					and quals.P5817[1].datavalue.value.id == "Q30108381" then
					status[i1] = "ca"
				end

				-- override default capacity from qualifier P2109 if available
				if quals.P2109 and quals.P2109[1].snaktype == "value" then
					cap[i1] = renderqty(quals.P2109[1], langcode)
				end

				-- if quantity (P1114) is given, replace num value
				if quals.P1114 and quals.P1114[1].snaktype == "value" then
					num[i1] = tonumber(quals.P1114[1].datavalue.value.amount) or 1
				end
			end

			-- convert capacity in kW to MW
			if (cap[i1] or ""):sub(-2) == "kW" then
				local c = tonumber(cap[i1]:match("%d+"))
				cap[i1] = c/1000 .. "&nbsp;" .. "MW"
			end
		end
	end

	-- construct set of manufacturers and models of operational units
	-- key is the manufacturer + model and value is count of that
	local opmm = {}
	for i, v in ipairs(status) do
		if v == "op" and mm[i] then opmm[mm[i]] = (opmm[mm[i]] or 0) + num[i] end
	end
	-- construct html string from the set of manufacturers and models
	-- first make a sequential table
	local opmmseq = {}
	for k, v in pairs(opmm) do
		opmmseq[#opmmseq+1] = k .. " (" .. v .. ")"
	end
	table.sort(opmmseq, linkcomp)
	if psu_mm == "" then psu_mm = table.concat(opmmseq, "<br>") end

	-- construct sets of capacities of operational units (opcap),
	-- units under construction (uccap), decommissioned (dccap)],
	-- planned (plcap) and cancelled (cacap)
	-- key is the capacity and value is count of that capacity.
	local opcap, uccap, dccap, plcap, cacap = {}, {}, {}, {}, {}
	for i, v in ipairs(status) do
		if v == "uc" and cap[i] then uccap[cap[i]] = (uccap[cap[i]] or 0) + num[i] end
		if v == "op" and cap[i] then opcap[cap[i]] = (opcap[cap[i]] or 0) + num[i] end
		if v == "dc" and cap[i] then dccap[cap[i]] = (dccap[cap[i]] or 0) + num[i] end
		if v == "pl" and cap[i] then plcap[cap[i]] = (plcap[cap[i]] or 0) + num[i] end
		if v == "ca" and cap[i] then cacap[cap[i]] = (cacap[cap[i]] or 0) + num[i] end
	end
	-- construct html strings from the sets of capacities
	-- first make a sequential table
	-- under construction
	local uccapseq = {}
	for k, v in pairs(uccap) do
		uccapseq[#uccapseq+1] = v .. " × " .. k
	end
	table.sort(uccapseq, numcomp2)
	if psu_uc == "" then psu_uc = table.concat(uccapseq, "<br>") end
	-- operational
	local opcapseq = {}
	for k, v in pairs(opcap) do
		opcapseq[#opcapseq+1] = v .. " × " .. k
	end
	table.sort(opcapseq, numcomp2)
	if psu_op == "" then psu_op = table.concat(opcapseq, "<br>") end
	-- decommissioned
	local dccapseq = {}
	for k, v in pairs(dccap) do
		dccapseq[#dccapseq+1] = v .. " × " .. k
	end
	table.sort(dccapseq, numcomp2)
	if psu_dc == "" then psu_dc = table.concat(dccapseq, "<br>") end
	-- planned
	local plcapseq = {}
	for k, v in pairs(plcap) do
		plcapseq[#plcapseq+1] = v .. " × " .. k
	end
	table.sort(plcapseq, numcomp2)
	if psu_pl == "" then psu_pl = table.concat(plcapseq, "<br>") end
	-- cancelled
	local cacapseq = {}
	for k, v in pairs(cacap) do
		cacapseq[#cacapseq+1] = v .. " × " .. k
	end
	table.sort(cacapseq, numcomp2)
	if psu_ca == "" then psu_ca = table.concat(cacapseq, "<br>") end

	-- construct table rows
	local out = ""
	-- operational
	if psu_op ~= "" then
		out = out ..  "<tr><th>" .. i18n.op_lbl
		.. "</th><td>" .. psu_op .. "</td></tr>"
	end
	-- make & model
	if psu_mm ~= "" then
		out = out ..  "<tr><th>" .. i18n.mm_lbl
		.. "</th><td>" .. psu_mm .. "</td></tr>"
	end
	-- planned
	if psu_pl ~= "" then
		out = out ..  "<tr><th>" .. i18n.pl_lbl
		.. "</th><td>" .. psu_pl .. "</td></tr>"
	end
	-- cancelled
	if psu_ca ~= "" then
		out = out ..  "<tr><th>" .. i18n.ca_lbl
		.. "</th><td>" .. psu_ca .. "</td></tr>"
	end
	-- under const.
	if psu_uc ~= "" then
		out = out ..  "<tr><th>" .. i18n.uc_lbl
		.. "</th><td>" .. psu_uc .. "</td></tr>"
	end
	-- decommissioned
	if psu_dc ~= "" then
		out = out ..  "<tr><th>" .. i18n.dc_lbl
		.. "</th><td>" .. psu_dc .. "</td></tr>"
	end

	if args.dbug and args.dbug ~= "" then
		local debugstr = "debug info<br>"
		for i, v in pairs(status) do
			debugstr = debugstr .. i .. " - " .. v .. " - " .. (cap[i] or "") .. " - " .. (mm[i] or "") .. " x " .. (num[i] or "") .. "<br>"
		end

		local count = 0
		for k, v in pairs(opmm) do
			count = count +1
		end

		debugstr = debugstr .. "opmm size = " .. count
		out = out  ..  "<tr><td colspan='2'>" .. debugstr .. "</td></tr>"
	end

	-- Construct html hack to fit in when passed to Template:Infobox, which prefixes the data with
	-- <td colspan="2" style="text-align:center"> and suffixes it with </td></tr>
	if #out > 0 then
		out = "</td>" .. out:sub(1,-11)
	end

	return out
end

return p