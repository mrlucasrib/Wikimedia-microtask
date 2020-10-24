-- Usage: =p._caseTable({config="San Francisco Bay Area"})

local p = {}
local lang = mw.getContentLanguage()
local tabularData = require("Module:Tabular data")
local wd = require("Module:wd")
local mapFrame = require("Module:Mapframe")

local propertyIDsByDisposition = {
	-- tests = "P8011",
	cases = "P1603",
	-- hospitalizations = "P8049",
	recoveries = "P8010",
	deaths = "P1120",
}

local function round(x)
	return (math.modf(x + (x < 0 and -0.5 or 0.5)))
end

function p.pointInTime(statement)
	local qualifiers = statement.qualifiers and statement.qualifiers.P585
	local time = qualifiers and qualifiers[1].datavalue.value.time
	return time and tonumber(lang:formatDate("U", time))
end

-- =tonumber(p.mostRecentStatement("Q83873577", "P1120").mainsnak.datavalue.value.amount)
function p.mostRecentStatement(entityID, propertyID, startDate, endDate)
	local startTime = startDate and tonumber(lang:formatDate("U", startDate)) or -math.huge
	local endTime = endDate and tonumber(lang:formatDate("U", endDate)) or math.huge
	
	local statements = mw.wikibase.getBestStatements(entityID, propertyID)
	local latestTime = -math.huge
	local latestStatement
	for i, statement in ipairs(statements) do
		local time = p.pointInTime(statement)
		if time and time > startTime and time < endTime and time > latestTime then
			latestTime = time
			latestStatement = statement
		end
	end
	return latestStatement
end

function p.statementReference(statement)
	local reference = statement.references and statement.references[1]
	local referenceSnak = reference and reference.snaks.P248 and reference.snaks.P248[1]
	local declarationQID = referenceSnak and referenceSnak.datavalue.value.id
	if not declarationQID then
		return nil
	end
	local name = mw.wikibase.formatValue(referenceSnak)
	local url = mw.wikibase.getBestStatements(declarationQID, "P856")[1].mainsnak.datavalue.value
	return {
		name = declarationQID,
		wikitext = url and mw.ustring.format("[%s %s]", url, name) or name,
	}
end

function p._regionData(regionConfigs, populationDate)
	local regions = {}
	for i, regionConfig in ipairs(regionConfigs) do
		local outbreakEntity = regionConfig.entity
		local locationEntity = mw.wikibase.getBestStatements(outbreakEntity, "P276")[1].mainsnak.datavalue.value.id
		local dataTableName = mw.wikibase.getBestStatements(outbreakEntity, "P8204")[1]
		local dataTable
		if dataTableName then
			dataTableName = dataTableName.mainsnak.datavalue.value
			dataTable = mw.ext.data.get((dataTableName:gsub("^Data:", "")))
		end
		
		local region = {
			outbreakEntity = outbreakEntity,
			locationEntity = locationEntity,
			name = mw.wikibase.getLabel(locationEntity),
			link = mw.wikibase.getSitelink(locationEntity),
			population = tonumber(wd._property({
				"raw",
				locationEntity,
				"P1082",
				P585 = populationDate,
			})),
			dataTableName = dataTableName,
			note = regionConfig.note,
			sources = {},
		}
		
		local columns = regionConfig.columns
		local latestTableDate = dataTable and tabularData._cell({
			data = dataTable,
			output_row = -1,
			output_column = columns and columns.date or "date",
		})
		local latestTableTime = latestTableDate and tonumber(lang:formatDate("U", latestTableDate))
		local usesDataTable = false
		
		local casesStatement = p.mostRecentStatement(outbreakEntity, propertyIDsByDisposition.cases)
		local casesTime = casesStatement and p.pointInTime(casesStatement)
		if casesTime and (not latestTableTime or casesTime > latestTableTime) then
			region.cases = tonumber(casesStatement.mainsnak.datavalue.value.amount)
			local reference = p.statementReference(casesStatement)
			if reference then
				region.sources[reference.name] = reference.wikitext
			end
		elseif latestTableTime then
			region.cases = dataTable and (tabularData._cell({
				data = dataTable,
				output_row = -1,
				output_column = columns and columns.cases or "totalConfirmedCases",
			}) or tabularData._lookup({
				data = dataTable,
				search_pattern = "%d",
				search_column = columns and columns.cases or "totalConfirmedCases",
				occurrence = -1,
				output_column = columns and columns.cases or "totalConfirmedCases",
			})) + (columns and columns.cases2 and tabularData._cell({
				data = dataTable,
				output_row = -1,
				output_column = columns.cases2,
			}) or 0)
			usesDataTable = true
		end
		region.arrivalDate = dataTable and tabularData._lookup({
			data = dataTable,
			search_pattern = "[1-9]",
			search_column = columns and columns.cases or "totalConfirmedCases",
			occurrence = 1,
			output_column = columns and columns.date or "date",
		})
		
		local deathsStatement = p.mostRecentStatement(outbreakEntity, propertyIDsByDisposition.deaths)
		local deathsTime = deathsStatement and p.pointInTime(deathsStatement)
		if deathsTime and (not latestTableTime or deathsTime > latestTableTime) then
			region.deaths = tonumber(deathsStatement.mainsnak.datavalue.value.amount)
			local reference = p.statementReference(deathsStatement)
			if reference then
				region.sources[reference.name] = reference.wikitext
			end
		elseif latestTableTime then
			region.deaths = dataTable and (tabularData._cell({
				data = dataTable,
				output_row = -1,
				output_column = columns and columns.deaths or "deaths",
			}) or tabularData._lookup({
				data = dataTable,
				search_pattern = "%d",
				search_column = columns and columns.deaths or "deaths",
				occurrence = -1,
				output_column = columns and columns.deaths or "deaths",
			}))
			usesDataTable = true
		end
		
		local recoveriesStatement = p.mostRecentStatement(outbreakEntity, propertyIDsByDisposition.recoveries)
		local recoveriesTime = recoveriesStatement and p.pointInTime(recoveriesStatement)
		if recoveriesTime and (not latestTableTime or recoveriesTime > latestTableTime) then
			region.recoveries = tonumber(recoveriesStatement.mainsnak.datavalue.value.amount)
			local reference = p.statementReference(recoveriesStatement)
			if reference then
				region.sources[reference.name] = reference.wikitext
			end
		elseif latestTableTime then
			region.recoveries = columns and columns.recoveries and dataTable and tabularData._cell({
				data = dataTable,
				output_row = -1,
				output_column = columns.recoveries,
			})
			usesDataTable = true
		end
		
		local viewLinks = {
			mw.ustring.format("[[d:%s|d]]", region.outbreakEntity),
		}
		if dataTableName then
			table.insert(viewLinks, mw.ustring.format("[[c:%s|c]]", dataTableName))
		end
		region.viewLink = table.concat(viewLinks, "&nbsp;")
		
		if usesDataTable then
			local formattedDate = latestTableTime
			local reference = mw.ustring.format("%s. %s.", dataTable.sources:gsub("<br */?>.*", ""), lang:formatDate("F j, Y", latestTableDate))
			region.sources[dataTableName] = reference
		end
		
		table.insert(regions, region)
	end
	return regions
end

function addNumericCell(row, contents)
	if contents then
		row
			:tag("td")
			:attr("align", "right")
			:attr("data-sort-value", contents)
			:wikitext(lang:formatNum(contents))
	else
		row
			:tag("td")
			:addClass("unknown")
			:addClass("table-unknown")
			:attr("align", "center")
			:css({
				background = "#ececec",
				color = "#2c2c2c",
				["font-size"] = "smaller",
				["vertical-align"] = "middle",
			})
			:attr("data-sort-value", "0")
			:wikitext("?")
	end
	return row
end

-- Usage: =p._caseTable({config="San Francisco Bay Area"})
function p._caseTable(args)
	local frame = mw.getCurrentFrame()
	local config = args.config and mw.loadData("Module:Medical cases data/" .. args.config)
	local populationDate = config and config.populationDate or args.populationDate
	local regions = p._regionData(
		config and config.regions,
		populationDate)
	table.sort(regions, function (left, right)
		local leftCases = left.cases or 0
		local rightCases = right.cases or 0
		return leftCases == rightCases and left.name < right.name or leftCases > rightCases
	end)
	
	local totals = {
		regions = #regions,
		cases = 0,
		deaths = 0,
		recoveries = 0,
		population = 0,
	}
	for i, region in ipairs(regions) do
		totals.cases = totals.cases + (region.cases or 0)
		totals.deaths = totals.deaths + (region.deaths or 0)
		totals.recoveries = totals.recoveries and region.recoveries and (totals.recoveries + region.recoveries)
		totals.population = totals.population + (region.population or 0)
	end
	
	local htmlTable = mw.html.create("table")
		:addClass("wikitable")
		:addClass("sortable")
		:addClass("plainrowheaders")
		:attr("align", "right")
		:css({
			["font-size"] = "85%",
		})
	htmlTable
		:tag("caption")
		:wikitext(config and config.caption or args.caption)
	
	local headerRow = htmlTable
		:tag("tr")
	local totalRow = htmlTable
		:tag("tr")
	
	local columnNotes = config and config.columnNotes
	headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("data-sort-type", "text")
		:wikitext(config and config.regionTerm or args.regionTerm or "Regions")
		:wikitext(columnNotes and columnNotes.regions and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.regions
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:wikitext(lang:formatNum(totals.regions))
	headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("data-sort-type", "number")
		:wikitext("Cases")
		:wikitext(columnNotes and columnNotes.cases and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.cases
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:attr("data-sort-type", "number")
		:wikitext(lang:formatNum(totals.cases))
	local recoveriesHeader = headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("data-sort-type", "number")
	recoveriesHeader
		:tag("abbr")
		:attr("title", "Recoveries")
		:wikitext("Recov.")
	recoveriesHeader
		:wikitext(columnNotes and columnNotes.recoveries and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.recoveries
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:wikitext(totals.recoveries and lang:formatNum(totals.recoveries))
	headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("data-sort-type", "number")
		:wikitext("Deaths")
		:wikitext(columnNotes and columnNotes.deaths and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.deaths
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:attr("data-sort-type", "number")
		:wikitext(lang:formatNum(totals.deaths))
	local populationHeader = headerRow
			:tag("th")
			:attr("scope", "col")
			:attr("data-sort-type", "number")
	populationHeader
		:tag("abbr")
		:attr("title", "Population")
		:wikitext("Pop.")
	if populationDate then
		populationHeader
			:wikitext(mw.ustring.format(" (%d)", lang:formatDate("Y", populationDate)))
	end
	populationHeader
		:wikitext(columnNotes and columnNotes.population and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.population
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:attr("data-sort-type", "number")
		:wikitext(lang:formatNum(totals.population))
	headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("data-sort-type", "number")
			:tag("abbr")
			:attr("title", "Cases per 1 million inhabitants")
			:wikitext("C/1M")
		:wikitext(columnNotes and columnNotes.casesPerMillion and frame:expandTemplate {
			title = "efn",
			args = {
				columnNotes.casesPerMillion
			}
		})
	totalRow
		:tag("th")
		:attr("align", "right")
		:attr("data-sort-type", "number")
		:wikitext(lang:formatNum(round(totals.cases / totals.population * 1e6)))
	headerRow
		:tag("th")
		:attr("scope", "col")
		:attr("rowspan", 2)
		:addClass("unsortable")
			:tag("abbr")
			:attr("title", "Reference")
			:wikitext("Ref.")
	
	local regionNamePattern = config and config.regionNamePattern or args.regionNamePattern
	for i, region in ipairs(regions) do
		local row = htmlTable:tag("tr")
		local name = region.name
		if regionNamePattern then
			name = mw.ustring.match(region.name, regionNamePattern) or name
		end
		row
			:tag("th")
			:attr("scope", "row")
			:wikitext(mw.ustring.format("[[%s|%s]]", region.link, name))
			:wikitext(regionNote and frame:expandTemplate {
				title = "efn",
				args = {
					region.note,
				}
			})
		addNumericCell(row, region.cases)
		addNumericCell(row, region.recoveries)
		addNumericCell(row, region.deaths)
		addNumericCell(row, region.population)
		addNumericCell(row, region.cases and region.population and round(region.cases / region.population * 1e6))
		local refCell = row
			:tag("td")
			:attr("align", "center")
			:wikitext(region.viewLink)
		for name, wikitext in pairs(region.sources) do
			refCell:wikitext(frame:callParserFunction {
				name = "#tag:ref",
				args = {
					name = name,
					wikitext,
				},
			})
		end
	end
	
	local footerRow = htmlTable
		:tag("tr")
		:addClass("sortbottom")
	footerRow
		:tag("td")
		:attr("colspan", 7)
		:attr("align", "left")
		:css({
			width = 0,
		})
		:wikitext(frame:expandTemplate {
			title = "notelist",
		})
	
	return htmlTable
end

function p.caseTable(frame)
	return p._caseTable(frame.args)
end

function p._statistics(args)
	local frame = mw.getCurrentFrame()
	local config = args.config and mw.loadData("Module:Medical cases data/" .. args.config)
	local populationDate = config and config.populationDate or args.populationDate
	local regions = p._regionData(
		config and config.regions,
		populationDate)
	
	local stats = {
		regions = #regions,
		cases = 0,
		deaths = 0,
		recoveries = 0,
		recoveriesRegions = 0,
		population = 0,
	}
	for i, region in ipairs(regions) do
		stats.cases = stats.cases + (region.cases or 0)
		stats.deaths = stats.deaths + (region.deaths or 0)
		if region.recoveries then
			stats.recoveries = stats.recoveries + region.recoveries
			stats.recoveriesRegions = stats.recoveriesRegions + 1
		end
		stats.population = stats.population + (region.population or 0)
		if not stats.arrivalDate or region.arrivalDate < stats.arrivalDate then
			stats.arrivalDate = region.arrivalDate
		end
	end
	return stats
end

function p.statistics(frame)
	return p._statistics(frame.args)[mw.text.trim(frame.args[1])]
end

local function fillColor(casesPerCapita)
	-- [[c:Template:COVID-19 Prevalence in US by county]]
	local percent = casesPerCapita * 100
	if percent >= 3.00 then return "#99000d" end
	if percent >= 1.00 then return "#cb181d" end
	if percent >= 0.30 then return "#fb6a4a" end
	if percent >= 0.10 then return "#fc9272" end
	if percent >= 0.03 then return "#fcbba1" end
	if percent >= 0.00 then return "#fee5d9" end
	return "#cccccc"
end

-- Usage: =p._map({config="San Francisco Bay Area"})
function p._map(args)
	local frame = mw.getCurrentFrame()
	local config = args.config and mw.loadData("Module:Medical cases data/" .. args.config)
	local populationDate = config and config.populationDate or args.populationDate
	local regions = p._regionData(
		config and config.regions,
		populationDate)
	
	local params = {
		frame = "yes",
		["frame-width"] = args.frameWidth or (config and config.frameWidth),
		["frame-height"] = args.frameHeight or (config and config.frameHeight),
		text = args.caption or (config and config.caption),
	}
	for i, region in ipairs(regions) do
		i = i == 1 and "" or i
		params["type" .. i] = "shape"
		params["id" .. i] = region.locationEntity
		params["title" .. i] = region.name
		params["stroke-color" .. i] = "#ffffff"
		params["stroke-width" .. i] = 1
		params["fill" .. i] = fillColor(region.cases / region.population)
		
		local details = {
			mw.ustring.format("%s cases (%s/1M)", lang:formatNum(region.cases),
				lang:formatNum(round(region.cases / region.population * 1e6))),
			mw.ustring.format("%s deaths", lang:formatNum(region.deaths)),
		}
		if region.recoveries then
			table.insert(details, mw.ustring.format("%s recoveries", lang:formatNum(region.recoveries)))
		end
		params["description" .. i] = table.concat(details, "<br>")
	end
	
	return frame:preprocess(mapFrame._main(params))
end

function p.map(frame)
	return p._map(frame.args)
end

return p