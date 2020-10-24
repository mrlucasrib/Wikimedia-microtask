local p = {}

local concat = table.concat
local insert = table.insert
local format = mw.ustring.format

local tConfig = mw.loadData("Module:Tennis performance timeline/data")
local rounds = tConfig.rounds
local tournaments = tConfig.tournaments
local environments = tConfig.environments
local surfaces = tConfig.surfaces
local tOrders = tConfig.orders

local curYear = os.date("!*t").year
local calendar = mw.loadData("Module:Tennis performance timeline/calendar")

local genders = {
	men = "Men's",
	women = "Women's"
}

local matchTypes = {
	singles = "Singles",
	doubles = "Doubles"
}

--[[Utility functions]]

local function checkNonNil(value, type)
	if value == nil then
		error("Expected " .. type .. ", but is nil", 2)
	end
	return value
end

local function checkFormat(str, pattern, type)
	if str == mw.ustring.match(str, pattern) then
		return str
	else
		error("Invalid " .. type .. ": " .. str, 2)
	end
end

local function checkYear(year)
	checkNonNil(year, "year")
	return checkFormat(year, "%d%d%d%d", "year")
end

local function checkNum(num, diagMsg)
	diagMsg = "number" .. (diagMsg and " for " .. diagMsg or "")
	checkNonNil(num, diagMsg);
	return checkFormat(num, "%d+", diagMsg)
end

local function checkMember(elem, arr, type, diagMsg)
	if arr[elem] then
		return elem
	else
		diagMsg = type .. (diagMsg and " for " .. diagMsg or "")
		checkNonNil(elem, diagMsg)
		local message = {}
		insert(message, "Invalid ")
		insert(message, diagMsg)
		insert(message, ": ")
		insert(message, elem)
		error(concat(message))
	end
end

-- Format an HTML element with link, tooltip, and colors.
local function tooltip(tag, link, tooltip, text, spec)
	spec = spec or {}
	if spec.color then
		tag:css('color', spec.color)
	end
	if spec.italic then
		tag:wikitext("''");
	end
	if spec.bold then
		tag:wikitext("'''");
	end
	if link then
		tag:wikitext("[[" .. link .. "|")
	end
	if tooltip then
		if spec.abbr then
			tag:tag('abbr'):attr('title', tooltip):wikitext(text)
		else
			tag:attr('title', tooltip):wikitext(text)
		end
	else
		tag:wikitext(text)
	end
	if link then tag:wikitext("]]") end
	if spec.bold then
		tag:wikitext("'''");
	end
	if spec.italic then
		tag:wikitext("''");
	end
end

-- Substitute "$[`param`]$" appearing in `str` with `value`.
-- For example, subst("$year$ ATP Tour", "year", "1990") -> "1990 ATP Tour"
local function subst(str, param, value)
	if str == nil then return str end
	return str:gsub("%$" .. param .. "%$", value)
end

local function tr()
	return mw.html.create('tr')
end

local function th(row)
	return row:tag('th')
end

local function td(row)
	return row:tag('td')
end

local years
local data
local usedRounds

-- parser for data tables
local function parse(entry, year, tStats)
	local entryType = type(entry)
	if entryType == "string" then
		return entry
	elseif entryType == "table" then
		if entry.type == "chrono" then
			local numericYear = tonumber(year)
			for _,elem in ipairs(entry) do
				if type(elem) == "table" and numericYear >= elem[1] then
					return parse(elem[2], year, tStats)
				end
			end
			return parse(entry.default, year, tStats)
		elseif entry.type == "switch" then
			local param = entry.param
			local arg = param == "year" and year or param == "gender" and data.gender or tStats[param]
			if entry[arg] then return parse(entry[arg], year, tStats) end
			return parse(entry.default, year, tStats)
		else
			return entry
		end
	end
end

-- Transform `param` entry in `array` with supplied data.
local function transform(array, param, data, tournament, year, country)
	local entry = array[param]
	entry = subst(entry, "gender", genders[data.gender])
	entry = subst(entry, "matchType", matchTypes[data.matchType])
	entry = subst(entry, "year", year)
	if data[tournament] and data[tournament][year] then
		local tStats = data[tournament][year]
		if tournaments[tournament] and tournaments[tournament].region then
			entry = subst(entry, "region",
				parse(tournaments[tournament].region[country]
					or tournaments[tournament].region.default, year, tStats))
		end
		if tournaments[tournament].group then
			entry = subst(entry, "group", tournaments[tournament].group[tStats.group] or "")
		end
	end
	array[param] = entry
end

-- Return wiki page title for the tournament in a given year.
local function annualTournamentLink(year, tStats, tInfo)
	local annualLink = tInfo.annualLink
	return parse(annualLink, year, tStats)
end

--[[-
Prepare the header row of the performance timeline table.
@return three elements:
- table header wikitext
- header row
- the first cell in the header row
]]
local function header()
	local rows = {}
	local row = tr()
	local headerCell = th(row):attr('scope', 'col'):addClass('unsortable')
	local tooltipSpec = {abbr = true}
	if years.amateur or years.professional then
		headerCell:attr('rowspan', 2)
		local eras = {}
		if years.amateur then
			eras[#eras+1] = {years.amateur, "Amateur"}
		end
		if years.professional then
			eras[#eras+1] = {years.professional, "Professional"}
		end
		eras[#eras+1] = {"1968", "Open Era"}
		eras[#eras+1] = {tostring(years.last + 1)}
		local lastEra = "?"
		local idx = 1
		for _,era in ipairs(eras) do
			local count = 0
			while years[idx] and years[idx] ~= era[1] do
				count = count + 1
				idx = idx + 1
			end
			if count > 0 then
				th(row):attr('scope', 'col'):attr('colspan', count):wikitext(lastEra)
			end
			lastEra = era[2]
		end
		tooltip(th(row):attr('scope', 'col'):attr('rowspan', 2), nil, "Strike rate", "SR", tooltipSpec)
		tooltip(th(row):attr('scope', 'col'):attr('rowspan', 2), nil, "Win–Loss", "W–L", tooltipSpec)
		th(row):attr('scope', 'col'):attr('rowspan', 2):wikitext("Win %")
		insert(rows, row)
		row = tr()
	end
	if data.categories.count > 1 then
		headerCell:attr('colspan', 2):wikitext("Tournament")
	end
	for _,year in ipairs(years) do
		local link = subst(parse(tConfig.tours.link, year), "year", year)
		th(row):attr('scope', 'col'):addClass('unsortable')
			:wikitext(link and format("[[%s|%s]]", link, year) or year)
	end
	if #rows == 0 then
		tooltip(th(row):attr('scope', 'col'), nil, "Strike rate", "SR", tooltipSpec)
		tooltip(th(row):attr('scope', 'col'), nil, "Win–Loss", "W–L", tooltipSpec)
		th(row):attr('scope', 'col'):wikitext("Win %")
	end
	insert(rows, row)

	-- Add hatnote if needed.
	local headerText = {}
	if years.last and data.last and tournaments[data.last] then
		local tInfo = tournaments[data.last]
		local annualLink = {link = annualTournamentLink(years.last, nil, tInfo)}
		transform(annualLink, "link", data, data.last, years.last)
		local hatnote = {}
		insert(hatnote, "''This table includes results through the conclusion of the [[")
		annualLink = annualLink.link:gsub(" – .*$", "")
		local annualName = annualLink
		local annualSubst = tInfo.annualSubst or {}
		for _,subst in ipairs(annualSubst) do
			annualName = annualName:gsub(subst[1], subst[2])
		end
		if annualLink ~= annualName then
			insert(hatnote, annualLink)
			insert(hatnote, "|")
		end
		insert(hatnote, annualName)
		insert(hatnote, "]].''")
		insert(headerText, concat(hatnote))
	end
	insert(headerText, "{|class=\"plainrowheaders wikitable sortable\" style=text-align:center")
	return concat(headerText, "\n"), rows, headerCell
end

local function outputSpan(row, span, seenRounds)
	local cell = td(row):attr('colspan', span.span)
	tooltip(cell, nil,
		span.span < span.info.minSpellCols and span.info.tooltip,
		span.span >= span.info.minSpellCols and span.info.tooltip or span.round,
		span.info)
	if seenRounds and span.span < span.info.minSpellCols then
		seenRounds[span.info.round] = span.info
	end
end

local footnoteCount

-- Return the year a given tournament was first held.
local function eventFirstYear(entries, yearInfos, year, yearEntry)
	year = tonumber(year)
	local startYear
	if #entries > 0 then
		local endYear = entries[#entries][4]
		for testYear = endYear + 1, year do
			local testYearTournament = parse(yearInfos, testYear)
			if testYearTournament ~= entries[#entries][1] then
				entries[#entries][4] = testYear - 1
				break;
			end
		end
		for testYear = year, endYear, -1 do
			local testYearTournament = parse(yearInfos, testYear)
			if testYearTournament ~= yearEntry then
				startYear = testYear + 1
				break;
			end
		end
	end
	return startYear
end

local frame_

-- Format a footnote.
local function footnoteText(footnoteChunks, wikilinkFn)
	if #footnoteChunks > 1 then
		local footnote = {}
		local footnoteChunk = {"Held as"}
		for pos,entry in ipairs(footnoteChunks) do
			local link, name, abbr = wikilinkFn(entry)
			insert(footnoteChunk, format("[[%s%s]]",
				link and link .. "|" or "", name))
			-- Add abbr if doesn't appear in name
			if abbr and not name:match(abbr) then
				insert(footnoteChunk, "(" .. abbr .. ")")
			end
			if entry[3] == entry[4] then
				-- One-year event
				insert(footnoteChunk, "in")
				insert(footnoteChunk, entry[3])
			else
				if pos > 1 then
				insert(footnoteChunk, "from")
				insert(footnoteChunk, entry[3])
				end
				if pos < #footnoteChunks then
					insert(footnoteChunk, pos == 1 and "until" or "to")
					insert(footnoteChunk, entry[4])
				end
			end
			insert(footnote, concat(footnoteChunk, (" ")))
			footnoteChunk = {}
		end
		footnote[#footnote] = "and " .. footnote[#footnote]
		return frame_:callParserFunction{name = '#tag:ref', args = {
			concat(footnote, #footnote > 2 and ", " or " "),
			group = "lower-alpha"
		}}
	end
end

local function winLossStatsSummary(row, stats, boldmarkup, summaryRowspan)
	boldmarkup = boldmarkup or ""
	-- &#8722; is (nonbreaking) minus sign.
	local srCell = td(row):attr('data-sort-value', stats.count > 0 and stats.champs / stats.count or -1)
		:addClass('nowrap')
		:wikitext(format("%s%d / %d%s", boldmarkup, stats.champs, stats.count, boldmarkup))
	local matches = stats.wins + stats.losses
	local wlCell = td(row):attr('data-sort-value', matches > 0 and stats.wins / matches or -1)
	local wrCell = td(row)
	if summaryRowspan then
		wlCell:attr('rowspan', summaryRowspan)
		wrCell:attr('rowspan', summaryRowspan)
		srCell:attr('rowspan', summaryRowspan)
	end
	if matches > 0 then
		wlCell:wikitext(format("%s%d–%d%s", boldmarkup, stats.wins, stats.losses, boldmarkup))
		wlCell:addClass("nowrap")
		wrCell:wikitext(format("%s%.2f%%%s", boldmarkup, stats.wins * 100 / matches, boldmarkup))
	else
		wlCell:wikitext(format("%s–%s", boldmarkup, boldmarkup))
		wrCell:attr('data-sort-value', '-1%')
			:wikitext(format("%s–%s", boldmarkup, boldmarkup))
	end
end

-- Prepare a Win-Loss row in the performance timeline table.
local function winLossStatsRow(row, info, stats, bold, summaryRowspan)
	local boldmarkup = bold and "'''" or ""
	local headerName = info.name and info.name .. " " or ""
	th(row):attr('scope', 'row')
		:wikitext(format("%s%sWin–Loss%s", boldmarkup, headerName, boldmarkup))
	local span
	for _,year in ipairs(years) do
		local yStats = stats[year]
		local display = {}
		if yStats and yStats.wins + yStats.losses > 0 then
			display.text = format("%s%d–%d%s", boldmarkup, yStats.wins, yStats.losses, boldmarkup)
		    bg_col = 'background-color:EAECF0'
		else
			display.text = format("%s–%s", boldmarkup, boldmarkup)
			bg_col = 'background-color:EAECF0'
			if info.absence then
				local aConfig = parse(info.absence, year)
				if aConfig then
					display.text = aConfig.round
					display.config = aConfig
				end
			end
		end
		if span then
			if span.info.round == display.text then
				span.span = span.span + 1
			else
				outputSpan(row, span)
				span = nil
			end
		end
		if not span then
			if display.config and display.config.span then
				span = {round = display.text, span = 1, info = display.config}
			else
				td(row):wikitext(display.text)
					:addClass("nowrap")
			end
		end
	end
	if span then
		outputSpan(row, span)
		span = nil
	end
	winLossStatsSummary(row, stats, boldmarkup, summaryRowspan)
end

-- Return true if the player appears in a given tournament.
local function hasTournamentAppearance(tournament)
	local tournamentType = type(tournament)
	if tournamentType == "string" then
		if data[tournament] then
			return true
		end
	elseif tournamentType == "table" then
		if tournament.type == "chrono" then
			for _,entry in ipairs(tournament) do
				if data[entry[2]] then
					return true
				end
			end
			if data[tournament.default] then
				return true
			end
		else
			-- TODO other table type
		end
	end
	return false
end

-- Create a fresh statistics table.
local function statsFactory()
	return {count = 0, champs = 0, finals = 0, wins = 0, losses = 0}
end

-- Generate performance timeline rows for a given tournament level.
local function body(level, levelHeaderCell)
	local entries = {}
	local stats = statsFactory()
	local levelInfo = parse(tOrders[level])
	local levelInfos = {}
	local levelLastAppearance
	for pos,tournament in ipairs(levelInfo) do
		if hasTournamentAppearance(tournament) then
			local tStats = statsFactory()
			local row = tr()
			if #entries == 0 and data.categories.count > 1 then
				levelHeaderCell = th(row):attr('scope', 'row')
									:css('width', '6.5em')
									:css('max-width', '10em')
			end
			local headerCell = th(row):attr('scope', 'row')
			local tInfos = {}
			local lastAppearance
			local seenRounds = {}
			local span
			local country = data.country.default
			for _,year in ipairs(years) do
				country = data.country[year] or country
				local yearLevelName = parse(levelInfo.name or levelInfo.tooltip, year)
				if #entries == 0 and (#levelInfos == 0 or levelInfos[#levelInfos][1] ~= yearLevelName) then
					-- Add footnote noting series transition.
					local startYear = eventFirstYear(levelInfos, levelInfo.name or levelInfo.tooltip, year, yearLevelName)
					insert(levelInfos, {
						yearLevelName,
						{link = parse(levelInfo.link, year), abbr = parse(levelInfo.abbr, year)},
						startYear, tonumber(year)
					})
				else
					levelInfos[#levelInfos][4] = tonumber(year)
				end
				local yearTournament = parse(tournament, year)
				local tInfo = checkNonNil(tournaments[yearTournament], "entry for " .. yearTournament)
				if #tInfos == 0 or tInfos[#tInfos][2] ~= tInfo then
					-- Add footnote noting tournament transition.
					local startYear = eventFirstYear(tInfos, tournament, year, yearTournament)
					insert(tInfos, {yearTournament, tInfo, startYear, tonumber(year)})
				else
					tInfos[#tInfos][4] = tonumber(year)
				end
				local display = {}
				if data[yearTournament] and data[yearTournament][year] then
					if not levelLastAppearance or levelLastAppearance < year then
						levelLastAppearance = year
					end
					lastAppearance = tInfo
					local tyStats = data[yearTournament][year]
					if not rounds[tyStats.round].nocount then
						tStats.count = tStats.count + 1
						stats.count = stats.count + 1
					end
					if rounds[tyStats.round].strike then
						tStats.champs = tStats.champs + 1
						stats.champs = stats.champs + 1
					end
					if not stats[year] then
						stats[year] = statsFactory()
					end
					tStats.wins = tStats.wins + tyStats.wins
					stats[year].wins = stats[year].wins + tyStats.wins
					stats.wins = stats.wins + tyStats.wins
					tStats.losses = tStats.losses + tyStats.losses
					stats[year].losses = stats[year].losses + tyStats.losses
					stats.losses = stats.losses + tyStats.losses
					local annualLink = annualTournamentLink(year, tyStats, tInfo)
					display.round = tyStats.round
					display.group = tyStats.group
					display.link = annualLink
					transform(display, "link", data, yearTournament, year, country)
				else
					display.round = parse(tInfo.absence, year) or "A"
				end
				local round = rounds[display.round]
				if round.absence then
					local absence = false
					if year < years.last or not data.last and tonumber(year) < curYear then
						absence = true
					elseif year == years.last and data.last and calendar[year] and calendar[year][data.gender] then
						local tWeek = calendar[year][data.gender].week[yearTournament]
						local lWeek = calendar[year][data.gender].week[data.last]
						if tWeek and lWeek and tWeek <= lWeek then
							absence = true
						end
					end
					if not absence then display.round = nil end
				end
				local roundInfo = {}
				setmetatable(roundInfo, {__index = rounds[display.round]})
				transform(roundInfo, "tooltip", data, yearTournament, year)
				if roundInfo.group then
					roundInfo.round = display.round .. display.group
				else
					roundInfo.round = display.round
				end
				display.round = roundInfo.name or roundInfo.round
				if span then
					if span.round == display.round then
						span.span = span.span + 1
					else
						outputSpan(row, span, seenRounds)
						span = nil
					end
				end
				if not span then
					if roundInfo.span then
						span = {round = display.round, span = 1, info = roundInfo}
					else
						local cell = td(row)
						if roundInfo.round then
							if roundInfo.bgcolor then
								cell:css('background', roundInfo.bgcolor)
							end
							tooltip(cell, display.link, roundInfo.tooltip, display.round, roundInfo)
							seenRounds[roundInfo.round] = roundInfo
						end
					end
				end
			end
			if span then
				outputSpan(row, span, seenRounds)
				span = nil
			end
			if lastAppearance then
				headerCell:wikitext(
					format("[[%s%s]]",
						lastAppearance.link and lastAppearance.link .. "|" or
							lastAppearance.abbr and lastAppearance.name .. "|" or "",
						lastAppearance.abbr or lastAppearance.name))
				if #tInfos > 1 then
					local footnote = footnoteText(tInfos,
						function(entry)
							local tInfo = entry[2]
							return tInfo.link, tInfo.name, tInfo.abbr
						end)
					headerCell:wikitext(footnote)
					footnoteCount = footnoteCount + 1
				end
				winLossStatsSummary(row, tStats)
				insert(entries, row)
				for _,roundInfo in pairs(seenRounds) do
					local round = roundInfo.name and not usedRounds[roundInfo.name] and roundInfo.name or roundInfo.round
					usedRounds[round] = roundInfo
				end
			end
		end
	end
	if #entries == 0 then return nil end
	if levelHeaderCell then
		local levelLink = parse(levelInfo.link, levelLastAppearance)
		local levelName = parse(levelInfo.name, levelLastAppearance)
		local levelAbbr = parse(levelInfo.abbr, levelLastAppearance)
		local levelTooltip = parse(levelInfo.tooltip, levelLastAppearance)
		local levelString = levelAbbr or levelName
		if data.categories.count > 1 then
			levelHeaderCell:attr('rowspan', #entries + 1)
		end
		tooltip(levelHeaderCell, levelLink or levelAbbr and levelName,
			levelTooltip, levelString, {bold = true, abbr = true})
		if #levelInfos > 1 then
			local footnote = footnoteText(levelInfos,
				function(entry)
					return entry[2].link, entry[1], entry[2].abbr
				end)
			levelHeaderCell:wikitext(footnote)
			footnoteCount = footnoteCount + 1
		end
	end

	local row = tr()
	winLossStatsRow(row, {}, stats, true)
	insert(entries, row)
	local result = {}
	for _,entry in ipairs(entries) do
		insert(result, tostring(entry))
	end
	return concat(result, "\n")
end

-- Generate rows for career performance timeline.
local function summary(envSummary, headerCell)
	local entries = {}
	local stats = statsFactory()
	local environmentInfo = tOrders.environments
	local surfaceInfo = tOrders.surfaces
	local surfaceCount = 0
	for _,environment in ipairs(environmentInfo) do
		if data[environment] then
			for _,surface in ipairs(surfaceInfo) do
				if data[environment][surface] then
					surfaceCount = surfaceCount + 1
				end
			end
		end
	end
	if surfaceCount == 0 then return nil end
	-- Aggregate data.
	local eStats = {}
	local sStats = {}
	for _,env in ipairs(environmentInfo) do
		if data[env] then
			for _,surface in ipairs(surfaceInfo) do
				if data[env][surface] then
					for _,year in ipairs(years) do
						local esyStats = data[env][surface][year]
						if esyStats then
							if not eStats[env] then
								eStats[env] = statsFactory()
							end
							if not eStats[env][year] then
								eStats[env][year] = statsFactory()
							end
							if not sStats[surface] then
								sStats[surface] = statsFactory()
							end
							if not sStats[surface][year] then
								sStats[surface][year] = statsFactory()
							end
							if not stats[year] then
								stats[year] = statsFactory()
							end
							for key,value in pairs(esyStats) do
								sStats[surface][year][key] = sStats[surface][year][key] + value
								sStats[surface][key] = sStats[surface][key] + value
								eStats[env][year][key] = eStats[env][year][key] + value
								eStats[env][key] = eStats[env][key] + value
								stats[year][key] = stats[year][key] + value
								stats[key] = stats[key] + value
							end
						end
					end
				end
			end
		end
	end
	local function venueWinLossStatsRow(venues, vInfo, vStats)
		for _,venue in ipairs(venues) do
			if vStats[venue] then
				local row = tr()
				if #entries == 0 and data.categories.count > 1 then
					-- Add header cell.
					headerCell = th(row):attr('scope', 'row')
				end
				winLossStatsRow(row, vInfo[venue], vStats[venue])
				insert(entries, row)
			end
		end
	end
	venueWinLossStatsRow(surfaceInfo, surfaces, sStats)
	if envSummary then
		venueWinLossStatsRow(environmentInfo, environments, eStats)
	end

	local row = tr()
	winLossStatsRow(row, {name = "Overall"}, stats, true, 2)
	insert(entries, row)

	local row = tr()
	local wrHdrCell = th(row):attr('scope', 'row'):wikitext("'''Win %'''")
	for _,year in ipairs(years) do
		local cellContent = "'''–'''"
		if stats[year] then
			local wins = stats[year].wins
			local losses = stats[year].losses
			local matches = wins + losses
			if matches > 0 then
				cellContent = format("'''%.1f%%'''", wins * 100 / matches)
			end
		end
		td(row):wikitext(cellContent)
	end
	insert(entries, row)
	if headerCell then 
		if data.categories.count > 1 then
			headerCell:attr('rowspan', #entries)
		end
		headerCell:wikitext("'''Career'''")
	end

	local function counterStatsRow(row, name, type, bold)
		local boldmarkup = bold and "'''" or ""
		local rowHdrCell = th(row):attr('scope', 'row'):css('text-align', 'right')
			:wikitext(format("%s%s%s", boldmarkup, name, boldmarkup))
		if data.categories.count > 1 then rowHdrCell:attr('colspan', 2) end
		for _,year in ipairs(years) do
			td(row):wikitext(format("%s%s%s",
				boldmarkup,
				stats[year] and tostring(stats[year][type]) or "–",
				boldmarkup))
		end
		td(row):attr('colspan', 2)
			:wikitext(format("%s%d total%s", boldmarkup, stats[type], boldmarkup))
	end

	local row = tr():addClass('sortbottom')
	counterStatsRow(row, "Tournaments played", "count")
	td(row):wikitext(format("'''%.1f%%'''", stats.champs * 100 / stats.count))
	insert(entries, row)

	if stats.finals > 0 then
		local row = tr():addClass('sortbottom')
		counterStatsRow(row, "Finals reached", "finals")
		td(row):attr('rowspan', 2)
			:wikitext(format("'''%.1f%%'''", stats.champs * 100 / stats.finals))
		insert(entries, row)
	
		local row = tr():addClass('sortbottom')
		counterStatsRow(row, "Titles", "champs", true)
		insert(entries, row)
	end

	local row = tr():addClass('sortbottom')
	local yearEndHdrCell = th(row):attr('scope', 'row'):css('text-align', 'right')
		:wikitext("'''Year-end ranking'''")
	if data.categories.count > 1 then yearEndHdrCell:attr('colspan', 2) end
	for _,year in ipairs(years) do
		local cell = td(row)
		if data.rank and data.rank[year] then
			local rank = data.rank[year]
			local rankConfig = tConfig.rankings[rank] or {}
			if rankConfig.bgcolor then
				cell:css('background', rankConfig.bgcolor)
			end
			local boldmarkup = rankConfig.bold and "'''" or ""
			cell:wikitext(format("%s%s%s", boldmarkup, rank, boldmarkup))
		end
	end
	local cell = td(row):attr('colspan', 3)
	if data.prizemoney then
		tooltip(cell, nil, "Career prize money", data.prizemoney, {bold = true, abbr = true})
	end
	insert(entries, row)

	local result = {}
	for _,entry in ipairs(entries) do
		insert(result, tostring(entry))
	end

	return concat(result, "\n")
end

-- Generate wikitext to conclude performance timeline table, including footnotes.
local function footer()
	local result = {}
	insert(result, "|-\n|}")
	if footnoteCount > 0 then
		local reflistTag = mw.html.create("div")
		reflistTag:addClass("reflist"):css('list-style-type', 'lower-alpha')
			:wikitext(frame_:callParserFunction{
				name = '#tag:references', args = {"", group = "lower-alpha"}
			})
		insert(result, tostring(reflistTag))
	end
	return concat(result, "\n")
end

-- Return true if the player appears in a given tournament level.
local function hasLevelAppearance(level)
	local levelInfo = parse(tOrders[level])
	for _,tournament in ipairs(levelInfo) do
		if hasTournamentAppearance(tournament) then return true end
	end
	return false
end

function p._main(args, frame)
	frame_ = frame
	data = {}
	years = {}
	usedRounds = {}
	footnoteCount = 0
	data.gender = args.gender or "men"
	data.matchType = args.matchType or "singles"
	data.country = {}
	data.country.default = args.country or "UNK"
	local idx = 1
	local environmentSummary = true
	local year
	while args[idx] do
		local arg = args[idx]
		if arg == "year" then
			idx = idx + 1
			year = checkYear(args[idx])
			if years.last and year <= years.last then
				error(format("Nonincreasing year: %s appears after %s", year, years.last))
			end
			years.last = year
			insert(years, year)
		elseif arg == "country" then
			idx = idx + 1
			local country = checkNonNil(args[idx], year .. " country")
			data.country[year] = args[idx]
		elseif arg == "amateur" then
			years.amateur = year
		elseif arg == "professional" then
			years.professional = year
		elseif tournaments[arg] then
			local tournament = arg
			local diagMsg = year .." " .. tournament
			local tStats = {}
			idx = idx + 1
			local round = args[idx]
			-- Handle zones for Davis Cup.
			if round and round:sub(1, 2) == "WG" then
				tStats.round = "WG"
				tStats.group = round:sub(3)
			elseif round and round:sub(1, 2) == "PO" then
				tStats.round = "PO"
				tStats.group = round:sub(3)
			elseif round and round:sub(1, 1) == "Z" then
				tStats.round = "Z"
				tStats.group = checkNum(round:sub(2), diagMsg .. " zone")
			else
				tStats.round = round
			end
			checkMember(tStats.round, rounds, "round", diagMsg)
			idx = idx + 1
			tStats.wins = checkNum(args[idx], diagMsg)
			idx = idx + 1
			tStats.losses = checkNum(args[idx], diagMsg)
			if data[tournament] == nil then data[tournament] = {} end
			data[tournament][year] = tStats
		elseif environments[arg] then
			local environment = arg
			local diagMsg = year .. " " .. " " .. environment
			idx = idx + 1
			local surface = checkNonNil(args[idx], diagMsg .. " surface")
			if surfaces[surface] then
				diagMsg = diagMsg .. " " .. surface
				local sStats = {}
				idx = idx + 1
				sStats.count = checkNum(args[idx], diagMsg)
				idx = idx + 1
				sStats.wins = checkNum(args[idx], diagMsg)
				idx = idx + 1
				sStats.losses = checkNum(args[idx], diagMsg)
				idx = idx + 1
				sStats.champs = checkNum(args[idx], diagMsg)
				idx = idx + 1
				sStats.finals = sStats.champs + checkNum(args[idx], diagMsg)
				if data[environment] == nil then data[environment] = {} end
				if data[environment][surface] == nil then
					data[environment][surface] = {}
				end
				data[environment][surface][year] = sStats
			else
				error(format("Unknown surface (%s %s): %s", year, environment, arg))
			end
		elseif surfaces[arg] then
			local surface = arg
			local diagMsg = year .. " " .. surface
			local sStats = {}
			idx = idx + 1
			sStats.count = checkNum(args[idx], diagMsg)
			idx = idx + 1
			sStats.wins = checkNum(args[idx], diagMsg)
			idx = idx + 1
			sStats.losses = checkNum(args[idx], diagMsg)
			idx = idx + 1
			sStats.champs = checkNum(args[idx], diagMsg)
			idx = idx + 1
			sStats.finals = sStats.champs + checkNum(args[idx], diagMsg)
			if data.outdoor == nil then data.outdoor = {} end
			if data["outdoor"][surface] == nil then data["outdoor"][surface] = {} end
			data["outdoor"][surface][year] = sStats
			-- Disable summary by environment.
			environmentSummary = false
		elseif arg == "rank" then
			idx = idx + 1
			if data.rank == nil then data.rank = {} end
			data.rank[year] = checkNum(args[idx], year .. " rank")
		else
			error(format("Unknown argument at position %d (%s): %s", idx, year, arg))
		end
		idx = idx + 1
	end
	data.prizemoney = args.prizemoney
	data.last = args.last
	data.categories = {}
	if args.types then
		local count = 0
		for _,type in ipairs(mw.text.split(args.types, ",")) do
			if type == "Career" or tConfig.orders[type] and hasLevelAppearance(type) then
				data.categories[type] = true
				count = count + 1
			end
		end
		data.categories.count = count
	else
		local count = 0
		for _,type in ipairs(parse(tConfig.orders.order)) do
			if hasLevelAppearance(type) then
				data.categories[type] = true
				count = count + 1
			end
		end
		data.categories.Career = true
		data.categories.count = count + 1
	end
	local result = {}
	local tableHeader, headerRows, headerCell = header()
	insert(result, tableHeader)
	local function insertHeaderRowsIfNeeded()
		if #result == 1 then
			for _,headerRow in ipairs(headerRows) do
				insert(result, tostring(headerRow))
			end
		end
	end
	for _,level in ipairs(parse(tConfig.orders.order)) do
		if data.categories[level] then
			local levelRows = body(level, data.categories.count == 1 and headerCell)
			insertHeaderRowsIfNeeded()
			insert(result, levelRows)
		end
	end
	if data.categories.Career then
		local careerRows = summary(environmentSummary, data.categories.count == 1 and headerCell)
		insertHeaderRowsIfNeeded()
		if careerRows then insert(result, careerRows) end
	end
	insert(result, footer())
	return concat(result, "\n")
end

function p.main(frame)
	-- Import module function to work with passed arguments
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	return p._main(args, frame)
end

return p