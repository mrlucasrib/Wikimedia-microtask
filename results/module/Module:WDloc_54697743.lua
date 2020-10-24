--
-- Lua functions for returning locations
-- may be used in infoboxes, so implements whitelist, blacklist, etc.
--

p = {}

----------------------------------------
-- location returns the various different locations available in Wikidata
--
-- located on terrain feature (P706)
-- location (P276)
-- located in the administrative territorial entity (P131)
-- country (P17)
-- continent (P30)
--
p.location = function(frame)
	local loc = frame.args.location or ""
	if loc and (#loc == 0) then loc = nil end

	-- can take a named parameter |qid which is the Wikidata ID for the article.
	local qid = frame.args.qid or ""
	if #qid == 0 then qid = mw.wikibase.getEntityIdForCurrentPage() or "" end

	-- The blacklist is passed in named parameter |suppressfields
	local blacklist = frame.args.suppressfields

	-- The whitelist is passed in named parameter |fetchwikidata
	local whitelist = frame.args.fetchwikidata

	-- The name of the field that this function is called from is passed in named parameter |name
	local fieldname = frame.args.name
	if blacklist then
		-- The name is compulsory when blacklist is used, so return nil if it is not supplied
		if not fieldname or (#fieldname == 0) then return nil end
		-- If this field is on the blacklist, then return nil
		if blacklist:find(fieldname) then return nil end
	end

	-- If we got this far then we're not on the blacklist
	-- The blacklist overrides any locally supplied parameter as well
	-- If a non-blank input parameter was supplied return it
	if loc then return loc end

	-- Otherwise see if this field is on the whitelist:
	if not (whitelist and (whitelist == 'ALL' or whitelist:find(fieldname))) then
		-- not on the whitelist so just return nil
		return nil
	end

	-- if qid is invalid or Wikidata item is nonexistent, return nothing
	if not (mw.wikibase.isValidEntityId(qid) and mw.wikibase.entityExists(qid)) then return nil end

	local sep = ", " -- internationalise / parameterise later

	-- There may be multiple values for each of these five types of location
	local geofeature, location, adminunit, country, continent
	-- so set up tables for Qid, label, and article
	-- for each of geofeature, location, adminunit, country, and continent
	local geofeatureQid, locationQid, adminunitQid, countryQid, continentQid = {}, {}, {}, {}, {}
	local geofeatureLbl, locationLbl, adminunitLbl, countryLbl, continentLbl = {}, {}, {}, {}, {}
	local geofeatureArt, locationArt, adminunitArt, countryArt, continentArt = {}, {}, {}, {}, {}

	-- located on terrain feature (P706)
	local bestP706 = mw.wikibase.getBestStatements(qid, "P706")
	if bestP706[1] then
		for k, v in ipairs(bestP706) do
			if v.mainsnak.datatype == "wikibase-item" and v.mainsnak.snaktype == "value" then
				local wid = v.mainsnak.datavalue.value["id"]
				local lbl = mw.wikibase.getLabel(wid)
				local art = mw.wikibase.getSitelink(wid)
				table.insert(geofeatureQid, wid)
				if lbl then table.insert(geofeatureLbl, mw.text.nowiki(lbl)) end
				if art then
					if lbl then
						table.insert(geofeatureArt, "[[" .. art .. "|" .. lbl .. "]]")
					else
						table.insert(geofeatureArt, "[[" .. art .. "|" .. art .. "]]")
					end
				end
			end
		end
		if geofeatureArt[1] then
			geofeature = table.concat(geofeatureArt, sep)
		else
			if geofeatureLbl[1] then
				geofeature = table.concat(geofeatureLbl, sep)
			end
		end
	end

	-- location (P276)
	local bestP276 = mw.wikibase.getBestStatements(qid, "P276")
	if bestP276[1] then
		for k, v in ipairs(bestP276) do
			if v.mainsnak.datatype == "wikibase-item" and v.mainsnak.snaktype == "value" then
				local wid = v.mainsnak.datavalue.value["id"]
				local lbl = mw.wikibase.getLabel(wid)
				local art = mw.wikibase.getSitelink(wid)
				table.insert(locationQid, wid)
				if lbl then table.insert(locationLbl, mw.text.nowiki(lbl)) end
				if art then
					if lbl then
						table.insert(locationArt, "[[" .. art .. "|" .. lbl .. "]]")
					else
						table.insert(locationArt, "[[" .. art .. "|" .. art .. "]]")
					end
				end
			end
		end
		if locationArt[1] then
			location = table.concat(locationArt, sep)
		else
			if locationLbl[1] then
				location = table.concat(locationLbl, sep)
			end
		end
	end

	-- located in the administrative territorial entity (P131)
	local bestP131 = mw.wikibase.getBestStatements(qid, "P131")
	if bestP131[1] then
		for k, v in ipairs(bestP131) do
			if v.mainsnak.datatype == "wikibase-item" and v.mainsnak.snaktype == "value" then
				local wid = v.mainsnak.datavalue.value["id"]
				local lbl = mw.wikibase.getLabel(wid)
				local art = mw.wikibase.getSitelink(wid)
				table.insert(adminunitQid, wid)
				if lbl then table.insert(adminunitLbl, mw.text.nowiki(lbl)) end
				if art then
					if lbl then
						table.insert(adminunitArt, "[[" .. art .. "|" .. lbl .. "]]")
					else
						table.insert(adminunitArt, "[[" .. art .. "|" .. art .. "]]")
					end
				end
			end
		end
		if adminunitArt[1] then
			adminunit = table.concat(adminunitArt, sep)
		else
			if adminunitLbl[1] then
				adminunit = table.concat(adminunitLbl, sep)
			end
		end
	end

	-- country (P17)
	local bestP17 = mw.wikibase.getBestStatements(qid, "P17")
	if bestP17[1] then
		for k, v in ipairs(bestP17) do
			if v.mainsnak.datatype == "wikibase-item" and v.mainsnak.snaktype == "value" then
				local wid = v.mainsnak.datavalue.value["id"]
				local lbl = mw.wikibase.getLabel(wid)
				local art = mw.wikibase.getSitelink(wid)
				table.insert(countryQid, wid)
				if lbl then table.insert(countryLbl, mw.text.nowiki(lbl)) end
				if art then table.insert(countryArt, art) end
			end
		end
		if countryArt[1] then
			country = table.concat(countryArt, sep)
		else
			if countryLbl[1] then
				country = table.concat(countryLbl, sep)
			end
		end
		-- apparently it should be "US", unless there is no other location information in which case it's "United States"
		if country == "United States" then country = "US" end
	end

	-- continent (P30)
	local bestP30 = mw.wikibase.getBestStatements(qid, "P30")
	if bestP30[1] then
		for k, v in ipairs(bestP30) do
			if v.mainsnak.datatype == "wikibase-item" and v.mainsnak.snaktype == "value" then
				local wid = v.mainsnak.datavalue.value["id"]
				local lbl = mw.wikibase.getLabel(wid)
				local art = mw.wikibase.getSitelink(wid)
				table.insert(continentQid, wid)
				if lbl then table.insert(continentLbl, mw.text.nowiki(lbl)) end
				if art then table.insert(continentArt, art) end
			end
		end
		if continentArt[1] then
			continent = table.concat(continentArt, sep)
		else
			if continentLbl[1] then
				continent = table.concat(continentLbl, sep)
			end
		end
	end

	-- for now, let's construct a table of what we've found
	local tbl = '<table class="wikitable">'
	tbl = tbl .. '<tr><th>Type</th><th>Article</th><th>Label</th><th>QID</th></tr>'
	tbl = tbl .. '<tr><th>Geo-feature</th><td>' .. (table.concat(geofeatureArt, sep) or "") .. '</td><td>' .. (table.concat(geofeatureLbl, sep) or "") .. '</td><td>' .. (table.concat(geofeatureQid, sep) or "") .. '</td></tr>'
	tbl = tbl .. '<tr><th>Location</th><td>' .. (table.concat(locationArt, sep) or "") .. '</td><td>' .. (table.concat(locationLbl, sep) or "") .. '</td><td>' .. (table.concat(locationQid, sep) or "") .. '</td></tr>'
	tbl = tbl .. '<tr><th>Admin unit</th><td>' .. (table.concat(adminunitArt, sep) or "") .. '</td><td>' .. (table.concat(adminunitLbl, sep) or "") .. '</td><td>' .. (table.concat(adminunitQid, sep) or "") .. '</td></tr>'
	tbl = tbl .. '<tr><th>Country</th><td>' .. (table.concat(countryArt, sep) or "") .. '</td><td>' .. (table.concat(countryLbl, sep) or "") .. '</td><td>' .. (table.concat(countryQid, sep) or "") .. '</td></tr>'
	tbl = tbl .. '<tr><th>Continent</th><td>' .. (table.concat(continentArt, sep) or "") .. '</td><td>' .. (table.concat(continentLbl, sep) or "") .. '</td><td>' .. (table.concat(continentQid, sep) or "") .. '</td></tr>'
	tbl = tbl .. '</table>'

	-- best candidate for location
	local wdloc = ""
	local wdloctbl = {}
	-- geo-feature and location are mutually exclusive, so we order doesn't matter
	--  then add the others: adminunit, country
	-- if none of them, fall back to continent alone
	if geofeature then table.insert(wdloctbl, geofeature) end
	if location then table.insert(wdloctbl, location) end
	if adminunit then table.insert(wdloctbl, adminunit) end
	if country then table.insert(wdloctbl, country) end
	if wdloctbl[1] then
		wdloc = table.concat(wdloctbl, ", ")
	else
		if continent then wdloc = continent end
	end

	-- deal with US vs United States as sole value
	if wdloc == "US" then wdloc = "United States" end

	return tbl .. "<p>Location = " .. wdloc .. "</p>"
end


return p