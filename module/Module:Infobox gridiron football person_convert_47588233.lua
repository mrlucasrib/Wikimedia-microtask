-- [SublimeLinter luacheck-globals:mw]

-- This module serves to convert <br>-delimited teams/years parameters in
-- [[Template:Infobox gridiron football person]] to their equivalent numbered pairs. Simply
-- replace "{{Infobox gridiron football person" with
-- "{{subst:#invoke:Infobox gridiron football person/convert|main" and press "Save".

local p = {}
local getBuffer, print = require("Module:OutputBuffer")()

local function printfd(formatString, ...)
	local default = ""

	local args, argsNum = {...}, select("#", ...)
	local newArgs = {}
	for i = 1, argsNum do
		if args[i] ~= nil then
			table.insert(newArgs, args[i])
		else
			table.insert(newArgs, default)
		end
	end
	print(string.format(formatString, unpack(newArgs)))
end

local function processTeamsYears(prefix, teams, years)
	local function extractItems(s, t)
		local sentinel = "😂"	-- WTF, Lua?
		string.gsub(string.gsub(s, "<[Bb][Rr] */?>", " " .. sentinel .. " "),
			"[^" .. sentinel .. "]+",
			function(c) table.insert(t, string.match(c, "^%s*(.-)%s*$")) end)
	end
	local newTeams = {}
	extractItems(teams, newTeams)
	local newYears = {}
	extractItems(years, newYears)

	if #newTeams ~= #newYears then
		printfd("<!-- Template:Infobox gridiron football person conversion error: " ..
			"%s_teams and %s_years are not of equal length. -->",
			prefix, prefix)
		printfd("| %s_teams = %s", prefix, teams)
		printfd("| %s_years = %s", prefix, years)
		return
	end

	c = 1
	for i = 1, #newTeams do
		if newYears[i] ~= "" or newTeams[i] ~= "" then
			printfd("| %s_years%s = %s", prefix, c,
				newYears[i] ~= "" and newYears[i] or
				"<!-- Template:Infobox gridiron football person conversion error: " ..
				"years missing. -->")
			printfd("| %s_team%s = %s", prefix, c,
				newTeams[i] ~= "" and newTeams[i] or
				"<!-- Template:Infobox gridiron football person conversion error: " ..
				"team missing. -->")
			c = c + 1
		end
	end
end

function p._main(args)
	print("{{Infobox gridiron football person")
	if args.embed then
		printfd("| embed = %s", args.embed)
	end
	printfd("| name = %s", args.name)
	printfd("| image = %s", args.image)
	if args.image_upright then
		printfd("| image_upright = %s", args.image_upright)
	end
	printfd("| alt = %s", args.alt)
	printfd("| caption = %s", args.caption)
	if args.nickname then
		printfd("| nickname = %s", args.nickname)
	end
	printfd("| birth_date = %s", args.birth_date)
	printfd("| birth_place = %s", args.birth_place)
	printfd("| death_date = %s", args.death_date)
	printfd("| death_place = %s", args.death_place)
	printfd("| team = %s", args.team)
	printfd("| number = %s", args.number)
	printfd("| status = %s", args.status)
	if args.import then
		printfd("| import = %s", args.import)
	end
	printfd("| position1 = %s", args.position1 or args.position or
	        args.Position)
	if args.position2 then
		printfd("| position2 = %s", args.position2)
	end
	if args.position3 then
		printfd("| position3 = %s", args.position3)
	end
	if args.position4 then
		printfd("| position4 = %s", args.position4)
	end
	if args.position5 then
		printfd("| position5 = %s", args.position5)
	end
	if args.uniform_number or args.jersey then
		printfd("| uniform_number = %s", args.uniform_number or args.jersey)
	end
	printfd("| height_ft = %s", args.height_ft or args.Height_ft)
	printfd("| height_in = %s", args.height_in or args.Height_in)
	printfd("| weight_lb = %s", args.weight_lb or args.weight_lbs or
	        args.Weight_lb or args.Weight_lbs)
	if args.college or args.College then
		printfd("| college = %s", args.college or args.College)
	end
	if args.CIS then
		printfd("| CIS = %s", args.CIS)
	end
	if args.amateur_title or args.amateur_team then
		printfd("| amateur_title = %s", args.amateur_title)
		printfd("| amateur_team = %s", args.amateur_team)
	end
	if args.high_school then
		printfd("| high_school = %s", args.high_school)
	end
	if args.AFLRookieYear then
		printfd("| AFLRookieYear = %s", args.AFLRookieYear)
	end
	if args.AFLDraftedYear or args.AFLDraftedRound or args.AFLDraftedPick or
			args.AFLDraftedTeam then
		printfd("| AFLDraftedYear = %s", args.AFLDraftedYear)
		printfd("| AFLDraftedRound = %s", args.AFLDraftedRound)
		printfd("| AFLDraftedPick = %s", args.AFLDraftedPick)
		printfd("| AFLDraftedTeam = %s", args.AFLDraftedTeam)
	end
	if args.BAFLRookieYear or args.BAFLDraftedTeam then
		printfd("| BAFLRookieYear = %s", args.BAFLRookieYear)
		printfd("| BAFLDraftedTeam = %s", args.BAFLDraftedTeam)
	end
	if args.CFLDraftedYear or args.CFLDraftedRound or args.CFLDraftedPick or args.CFLDraftedTeam then
		printfd("| CFLDraftedYear = %s", args.CFLDraftedYear)
		printfd("| CFLDraftedRound = %s", args.CFLDraftedRound)
		printfd("| CFLDraftedPick = %s", args.CFLDraftedPick)
		printfd("| CFLDraftedTeam = %s", args.CFLDraftedTeam)
	end
	if args.CommonDraftedYear or args.CommonDraftedRound or
			args.CommonDraftedPick or args.CommonDraftedTeam then
		printfd("| CommonDraftedYear = %s", args.CommonDraftedYear)
		printfd("| CommonDraftedRound = %s", args.CommonDraftedRound)
		printfd("| CommonDraftedPick = %s", args.CommonDraftedPick)
		printfd("| CommonDraftedTeam = %s", args.CommonDraftedTeam)
	end
	if args.ExpDraftedYear or args.ExpDraftedRound or args.ExpDraftedPick or
			args.ExpDraftedTeam then
		printfd("| ExpDraftedYear = %s", args.ExpDraftedYear)
		printfd("| ExpDraftedRound = %s", args.ExpDraftedRound)
		printfd("| ExpDraftedPick = %s", args.ExpDraftedPick)
		printfd("| ExpDraftedTeam = %s", args.ExpDraftedTeam)
	end
	if args.NFLDraftedYear or args.NFLDraftedRound or args.NFLDraftedPick or args.NFLDraftedTeam or
			args.DraftedYear or args.DraftedRound or args.DraftedPick then
		printfd("| NFLDraftedYear = %s", args.NFLDraftedYear or args.DraftedYear)
		printfd("| NFLDraftedRound = %s", args.NFLDraftedRound or args.DraftedRound)
		printfd("| NFLDraftedPick = %s", args.NFLDraftedPick or args.DraftedPick)
		printfd("| NFLDraftedTeam = %s", args.NFLDraftedTeam)
	end
	if args.NFLSuppDraftedYear or args.NFLSuppDraftedRound or
		args.NFLSuppDraftedPick then
	printfd("| NFLSuppDraftedYear = %s", args.NFLSuppDraftedYear)
	printfd("| NFLSuppDraftedRound = %s", args.NFLSuppDraftedRound)
	printfd("| NFLSuppDraftedPick = %s", args.NFLSuppDraftedPick)
	end
	if args.hand then
		printfd("| hand = %s", args.hand)
	end
	if args.pass_style then
		printfd("| pass_style = %s", args.pass_style)
	end
	if args.administrating_teams and args.administrating_years then
		processTeamsYears("administrating", args.administrating_teams,
		                  args.administrating_years)
	elseif args.administrating_teams then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has administrating_teams but no administrating_years. -->")
		printfd("| administrating_teams = %s", args.administrating_teams)
		print("| administrating_years = ")
	elseif args.administrating_years then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has administrating_years but no administrating_teams. -->")
		print("| administrating_teams = ")
		printfd("| administrating_years = %s", args.administrating_years)
	end
	if args.coaching_teams and args.coaching_years then
		processTeamsYears("coaching", args.coaching_teams, args.coaching_years)
	elseif args.coaching_teams then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has coaching_teams but no coaching_years. -->")
		printfd("| coaching_teams = %s", args.coaching_teams)
		print("| coaching_years = ")
	elseif args.coaching_years then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has coaching_years but no coaching_teams. -->")
		print("| coaching_teams = ")
		printfd("| coaching_years = %s", args.coaching_years)
	end
	if args.playing_teams and args.playing_years or
			args.teams and args.years then
		processTeamsYears("playing", args.playing_teams or args.teams,
		                  args.playing_years or args.years)
	elseif args.playing_teams or args.teams then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has playing_teams but no playing_years. -->")
		printfd("| playing_teams = %s", args.playing_teams or args.teams)
		print("| playing_years = ")
	elseif args.playing_years or args.years then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has playing_years but no playing_teams. -->")
		print("| playing_teams = ")
		printfd("| playing_years = %s", args.playing_years or args.years)
	end
	if args.other_teams and args.other_years then
		printfd("| other_title = %s", args.other_title)
		processTeamsYears("other", args.other_teams, args.other_years)
	elseif args.other_teams then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has other_teams but no other_years. -->")
		printfd("| other_title = %s", args.other_title)
		printfd("| other_teams = %s", args.other_teams)
		print("| other_years = ")
	elseif args.other_years then
		print("<!-- Template:Infobox gridiron football person conversion error: " ..
		      "Template has other_years but no other_teams. -->")
		printfd("| other_title = %s", args.other_title)
		print("| other_teams = ")
		printfd("| other_years = %s", args.other_years)
	end
	if args.career_footnotes then
		printfd("| career_footnotes = %s", args.career_footnotes)
	end
	printfd("| career_highlights = %s", args.career_highlights)
	if args.AFLAllStar then
		printfd("| AFLAllStar = %s", args.AFLAllStar)
	end
	if args.CFLAllStar then
		printfd("| CFLAllStar = %s", args.CFLAllStar)
	end
	if args.CFLEastAllStar then
		printfd("| CFLEastAllStar = %s", args.CFLEastAllStar)
	end
	if args.CFLWestAllStar then
		printfd("| CFLWestAllStar = %s", args.CFLWestAllStar)
	end
	if args.ProBowls then
		printfd("| ProBowls = %s", args.ProBowls)
	end
	if args.awards or args.Awards then
		printfd("| awards = %s", args.awards or args.Awards)
	end
	if args.honors or args.Honors then
		printfd("| honors = %s", args.honors or args.Honors)
	elseif args.honours or args.Honours then
		printfd("| honours = %s", args.honours or args.Honours)
	end
	if args["retired #s"] or args["Retired #s"] then
		printfd("| awards = %s", args["retired #s"] or args["Retired #s"])
	end
	if args.records or args.Records then
		printfd("| records = %s", args.records or args.Records)
	end
	if args.statlabel1 or args.statvalue1 then
		printfd("| statlabel1 = %s", args.statlabel1)
		printfd("| statvalue1 = %s", args.statvalue1)
		printfd("| statlabel2 = %s", args.statlabel2)
		printfd("| statvalue2 = %s", args.statvalue2)
		printfd("| statlabel3 = %s", args.statlabel3)
		printfd("| statvalue3 = %s", args.statvalue3)
		printfd("| statlabel4 = %s", args.statlabel4)
		printfd("| statvalue4 = %s", args.statvalue4)
		printfd("| statlabel5 = %s", args.statlabel5)
		printfd("| statvalue5 = %s", args.statvalue5)
	end
	if args.AFL then
		printfd("| AFL = %s", args.AFL)
	end
	if args.ArenaFan then
		printfd("| ArenaFan = %s", args.ArenaFan)
	end
	if args.CFL then
		printfd("| CFL = %s", args.CFL)
	end
	if args.NFL then
		printfd("| NFL = %s", args.NFL)
	end
	if args.CBS then
		printfd("| CBS = %s", args.CBS)
	end
	if args.DatabaseFootball then
		printfd("| DatabaseFootball = %s", args.DatabaseFootball)
	end
	if args.CoachPFR then
		printfd("| CoachPFR = %s", args.CoachPFR)
	end
	if args.CFHOF then
		printfd("| CFHOF = %s", args.CFHOF)
	end
	if args.CFHOFYear then
		printfd("| CFHOFYear = %s", args.CFHOFYear)
	end
	if args.CollegeHOF then
		printfd("| CollegeHOF = %s", args.CollegeHOF)
	end
	if args.CollegeHOFYear then
		printfd("| CollegeHOFYear = %s", args.CollegeHOFYear)
	end
	if args.PFHOF or args.HOF then
		printfd("| PFHOF = %s", args.PFHOF or args.HOF)
	end
	if args.PFHOFYear or args.HOFYear then
		printfd("| PFHOFYear = %s", args.PFHOFYear or args.HOFYear)
	end
	if args.module then
		printfd("| module = %s", args.module)
	end
	print("}}")

	return getBuffer("\n")
end

function p.main(frame)
	local args = require("Module:Arguments").getArgs(frame)
	return p._main(args)
end

return p