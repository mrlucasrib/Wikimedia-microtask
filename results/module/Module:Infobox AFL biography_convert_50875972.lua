-- [SublimeLinter luacheck-globals:mw]

-- This module serves to convert <br>-delimited teams/years parameters in
-- [[Template:Infobox AFL biography]] to their equivalent numbered pairs. Simply
-- replace "{{Infobox AFL biography" with
-- "{{subst:#invoke:Infobox AFL biography/convert|main" and press "Save".

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

local function processTeamsYears(teams, years, gamesGoals, teamsParam, yearsParam, gamesGoalsParam, oldGamesGoalsParam)
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
	local newGamesGoals = {}
	extractItems(gamesGoals, newGamesGoals)

	if #newTeams ~= #newYears or #newYears ~= #newGamesGoals or #newGamesGoals ~= #newTeams then
		printfd("<!-- Template:Infobox AFL biography conversion error: " ..
			"Parameters not of equal length. -->")
		printfd("| %ss = %s", teamsParam, teams)
		printfd("| %s = %s", yearsParam, years)
		printfd("| %s = %s", oldGamesGoalsParam, gamesGoals)
		return
	end

	c = 1
	for i = 1, #newTeams do
		if newYears[i] ~= "" or newTeams[i] ~= "" then
			printfd("| %s%s = %s", yearsParam, c,
				newYears[i] ~= "" and newYears[i] or
				"<!-- Template:Infobox AFL biography conversion error: " ..
				"years missing. -->")
			printfd("| %s%s = %s", teamsParam, c,
				newTeams[i] ~= "" and newTeams[i] or
				"<!-- Template:Infobox AFL biography conversion error: " ..
				"team missing. -->")
			printfd("| %s%s = %s", gamesGoalsParam, c,
				newGamesGoals[i] ~= "" and newGamesGoals[i] or
				"<!-- Template:Infobox AFL biography conversion error: " ..
				"games(goals) missing. -->")
			c = c + 1
		end
	end
end

function p._main(args)
	print("{{Infobox AFL biography")
	if args.embed then
		printfd("| embed = %s", args.embed)
	end
	if args.headercolor then
		printfd("| header-color = %s", args.headercolor)
	end
	if args.name or args.playername then
		printfd("| name = %s", args.name or args.playername)
	end
	printfd("| image = %s", args.image)
	if args.image_size or args.imagesize then
		printfd("| image_size = %s", args.image_size or args.imagesize)
	end
	if args.image or args.alt then
		printfd("| alt = %s", args.alt)
	end
	if args.image or args.caption then
		printfd("| caption = %s", args.caption)
	end
	if args.fullname then
		printfd("| fullname = %s", args.fullname)
	end
	if args.nickname then
		printfd("| nickname = %s", args.nickname)
	end
	printfd("| birth_date = %s", args.birth_date)
	printfd("| birth_place = %s", args.birth_place)
	printfd("| death_date = %s", args.death_date)
	printfd("| death_place = %s", args.death_place)
	if args.originalteam then
		printfd("| originalteam = %s", args.originalteam)
	end
	if args.draftpick then
		printfd("| draftpick = %s", args.draftpick)
	end
	if args.debutdate then
		printfd("| debutdate = %s", args.debutdate)
	end
	if args.debutteam then
		printfd("| debutteam = %s", args.debutteam)
	end
	if args.debutopponent then
		printfd("| debutopponent = %s", args.debutopponent)
	end
	if args.debutstadium then
		printfd("| debutstadium = %s", args.debutstadium)
	end
	printfd("| heightweight = %s", args.heightweight)
	printfd("| position = %s", args.position)
	if args.otheroccupation then
		printfd("| otheroccupation = %s", args.otheroccupation)
	end
	if args.currentclub then
		printfd("| currentclub = %s", args.currentclub)
	end
	if args.guernsey then
		printfd("| guernsey = %s", args.guernsey)
	end
	if args.statsend then
		printfd("| statsend = %s", args.statsend)
	end
	if args.coachstatsend then
		printfd("| coachstatsend = %s", args.coachstatsend)
	end
	if args.repstatsend then
		printfd("| repstatsend = %s", args.repstatsend)
	end
	if args.playingteams then
		printfd("| playingteams = %s", args.playingteams)
	end
	if args.coachingteams then
		printfd("| coachingteams = %s", args.coachingteams)
	end
	if args.clubs and args.years and args.gamesgoals then
		processTeamsYears(args.clubs, args.years, args.gamesgoals,
			"club", "years", "games_goals", "games(goals)")
	elseif args.clubs or args.years or args.gamesgoals then
		print("<!-- Template:Infobox AFL biography conversion error: " ..
		      "Template is missing expected parameters. -->")
		printfd("| clubs = %s", args.clubs)
		printfd("| years = %s", args.years)
		printfd("| games(goals) = %s", args.gamesgoals)
	end
	if args.club1 then
		printfd("| club1 = %s", args.club1)
	end
	if args.years1 then
		printfd("| years1 = %s", args.years1)
	end
	if args.games_goals1 then
		printfd("| games_goals1 = %s", args.games_goals1)
	end
	if args.club2 then
		printfd("| club2 = %s", args.club2)
	end
	if args.years2 then
		printfd("| years2 = %s", args.years2)
	end
	if args.games_goals2 then
		printfd("| games_goals2 = %s", args.games_goals2)
	end
	if args.club3 then
		printfd("| club3 = %s", args.club3)
	end
	if args.years3 then
		printfd("| years3 = %s", args.years3)
	end
	if args.games_goals3 then
		printfd("| games_goals3 = %s", args.games_goals3)
	end
	if args.club4 then
		printfd("| club4 = %s", args.club4)
	end
	if args.years4 then
		printfd("| years4 = %s", args.years4)
	end
	if args.games_goals4 then
		printfd("| games_goals4 = %s", args.games_goals4)
	end
	if args.club5 then
		printfd("| club5 = %s", args.club5)
	end
	if args.years5 then
		printfd("| years5 = %s", args.years5)
	end
	if args.games_goals5 then
		printfd("| games_goals5 = %s", args.games_goals5)
	end
	if args.club6 then
		printfd("| club6 = %s", args.club6)
	end
	if args.years6 then
		printfd("| years6 = %s", args.years6)
	end
	if args.games_goals6 then
		printfd("| games_goals6 = %s", args.games_goals6)
	end
	if args.club7 then
		printfd("| club7 = %s", args.club7)
	end
	if args.years7 then
		printfd("| years7 = %s", args.years7)
	end
	if args.games_goals7 then
		printfd("| games_goals7 = %s", args.games_goals7)
	end
	if args.club8 then
		printfd("| club8 = %s", args.club8)
	end
	if args.years8 then
		printfd("| years8 = %s", args.years8)
	end
	if args.games_goals8 then
		printfd("| games_goals8 = %s", args.games_goals8)
	end
	if args.club9 then
		printfd("| club9 = %s", args.club9)
	end
	if args.years9 then
		printfd("| years9 = %s", args.years9)
	end
	if args.games_goals9 then
		printfd("| games_goals9 = %s", args.games_goals9)
	end
	if args.club10 then
		printfd("| club10 = %s", args.club10)
	end
	if args.years10 then
		printfd("| years10 = %s", args.years10)
	end
	if args.games_goals10 then
		printfd("| games_goals10 = %s", args.games_goals10)
	end
	if args.gamesgoalstotal then
		printfd("| games_goalstotal = %s", args.gamesgoalstotal)
	end
	if args.sooteams and args.sooyears and args.soogamesgoals then
		processTeamsYears(args.sooteams, args.sooyears, args.soogamesgoals,
			"sooteam", "sooyears", "soogames_goals", "soogames(goals)")
	elseif args.sooteams or args.sooyears or args.soogamesgoals then
		print("<!-- Template:Infobox AFL biography conversion error: " ..
		      "Template is missing expected parameters. -->")
		printfd("| sooteams = %s", args.sooteams)
		printfd("| sooyears = %s", args.sooyears)
		printfd("| soogames(goals) = %s", args.soogamesgoals)
	end
	if args.sooteam1 then
		printfd("| sooteam1 = %s", args.sooteam1)
	end
	if args.sooyears1 then
		printfd("| sooyears1 = %s", args.sooyears1)
	end
	if args.soogames_goals1 then
		printfd("| soogames_goals1 = %s", args.soogames_goals1)
	end
	if args.sooteam2 then
		printfd("| sooteam2 = %s", args.sooteam2)
	end
	if args.sooyears2 then
		printfd("| sooyears2 = %s", args.sooyears2)
	end
	if args.soogames_goals2 then
		printfd("| soogames_goals2 = %s", args.soogames_goals2)
	end
	if args.sooteam3 then
		printfd("| sooteam3 = %s", args.sooteam3)
	end
	if args.sooyears3 then
		printfd("| sooyears3 = %s", args.sooyears3)
	end
	if args.soogames_goals3 then
		printfd("| soogames_goals3 = %s", args.soogames_goals3)
	end
	if args.sooteam4 then
		printfd("| sooteam4 = %s", args.sooteam4)
	end
	if args.sooyears4 then
		printfd("| sooyears4 = %s", args.sooyears4)
	end
	if args.soogames_goals4 then
		printfd("| soogames_goals4 = %s", args.soogames_goals4)
	end
	if args.sooteam5 then
		printfd("| sooteam5 = %s", args.sooteam5)
	end
	if args.sooyears5 then
		printfd("| sooyears5 = %s", args.sooyears5)
	end
	if args.soogames_goals5 then
		printfd("| soogames_goals5 = %s", args.soogames_goals5)
	end
	if args.sooteam6 then
		printfd("| sooteam6 = %s", args.sooteam6)
	end
	if args.sooyears6 then
		printfd("| sooyears6 = %s", args.sooyears6)
	end
	if args.soogames_goals6 then
		printfd("| soogames_goals6 = %s", args.soogames_goals6)
	end
	if args.sooteam7 then
		printfd("| sooteam7 = %s", args.sooteam7)
	end
	if args.sooyears7 then
		printfd("| sooyears7 = %s", args.sooyears7)
	end
	if args.soogames_goals7 then
		printfd("| soogames_goals7 = %s", args.soogames_goals7)
	end
	if args.sooteam8 then
		printfd("| sooteam8 = %s", args.sooteam8)
	end
	if args.sooyears8 then
		printfd("| sooyears8 = %s", args.sooyears8)
	end
	if args.soogames_goals8 then
		printfd("| soogames_goals8 = %s", args.soogames_goals8)
	end
	if args.sooteam9 then
		printfd("| sooteam9 = %s", args.sooteam9)
	end
	if args.sooyears9 then
		printfd("| sooyears9 = %s", args.sooyears9)
	end
	if args.soogames_goals9 then
		printfd("| soogames_goals9 = %s", args.soogames_goals9)
	end
	if args.sooteam10 then
		printfd("| sooteam10 = %s", args.sooteam10)
	end
	if args.sooyears10 then
		printfd("| sooyears10 = %s", args.sooyears10)
	end
	if args.soogames_goals10 then
		printfd("| soogames_goals10 = %s", args.soogames_goals10)
	end
	if args.soogamesgoalstotal then
		printfd("| soogames_goalstotal = %s", args.soogamesgoalstotal)
	end
	if args.nationalteams and args.nationalyears and args.nationalgamesgoals then
		processTeamsYears(args.nationalteams, args.nationalyears, args.nationalgamesgoals,
			"nationalteam", "nationalyears", "nationalgames_goals", "nationalgames(goals)")
	elseif args.nationalteams or args.nationalyears or args.nationalgamesgoals then
		print("<!-- Template:Infobox AFL biography conversion error: " ..
		      "Template is missing expected parameters. -->")
		printfd("| nationalteams = %s", args.nationalteams)
		printfd("| nationalyears = %s", args.nationalyears)
		printfd("| nationalgames(goals) = %s", args.nationalgamesgoals)
	end
	if args.nationalteam1 then
		printfd("| nationalteam1 = %s", args.nationalteam1)
	end
	if args.nationalyears1 then
		printfd("| nationalyears1 = %s", args.nationalyears1)
	end
	if args.nationalgames_goals1 then
		printfd("| nationalgames_goals1 = %s", args.nationalgames_goals1)
	end
	if args.nationalteam2 then
		printfd("| nationalteam2 = %s", args.nationalteam2)
	end
	if args.nationalyears2 then
		printfd("| nationalyears2 = %s", args.nationalyears2)
	end
	if args.nationalgames_goals2 then
		printfd("| nationalgames_goals2 = %s", args.nationalgames_goals2)
	end
	if args.nationalteam3 then
		printfd("| nationalteam3 = %s", args.nationalteam3)
	end
	if args.nationalyears3 then
		printfd("| nationalyears3 = %s", args.nationalyears3)
	end
	if args.nationalgames_goals3 then
		printfd("| nationalgames_goals3 = %s", args.nationalgames_goals3)
	end
	if args.nationalteam4 then
		printfd("| nationalteam4 = %s", args.nationalteam4)
	end
	if args.nationalyears4 then
		printfd("| nationalyears4 = %s", args.nationalyears4)
	end
	if args.nationalgames_goals4 then
		printfd("| nationalgames_goals4 = %s", args.nationalgames_goals4)
	end
	if args.nationalteam5 then
		printfd("| nationalteam5 = %s", args.nationalteam5)
	end
	if args.nationalyears5 then
		printfd("| nationalyears5 = %s", args.nationalyears5)
	end
	if args.nationalgames_goals5 then
		printfd("| nationalgames_goals5 = %s", args.nationalgames_goals5)
	end
	if args.nationalteam6 then
		printfd("| nationalteam6 = %s", args.nationalteam6)
	end
	if args.nationalyears6 then
		printfd("| nationalyears6 = %s", args.nationalyears6)
	end
	if args.nationalgames_goals6 then
		printfd("| nationalgames_goals6 = %s", args.nationalgames_goals6)
	end
	if args.nationalteam7 then
		printfd("| nationalteam7 = %s", args.nationalteam7)
	end
	if args.nationalyears7 then
		printfd("| nationalyears7 = %s", args.nationalyears7)
	end
	if args.nationalgames_goals7 then
		printfd("| nationalgames_goals7 = %s", args.nationalgames_goals7)
	end
	if args.nationalteam8 then
		printfd("| nationalteam8 = %s", args.nationalteam8)
	end
	if args.nationalyears8 then
		printfd("| nationalyears8 = %s", args.nationalyears8)
	end
	if args.nationalgames_goals8 then
		printfd("| nationalgames_goals8 = %s", args.nationalgames_goals8)
	end
	if args.nationalteam9 then
		printfd("| nationalteam9 = %s", args.nationalteam9)
	end
	if args.nationalyears9 then
		printfd("| nationalyears9 = %s", args.nationalyears9)
	end
	if args.nationalgames_goals9 then
		printfd("| nationalgames_goals9 = %s", args.nationalgames_goals9)
	end
	if args.nationalteam10 then
		printfd("| nationalteam10 = %s", args.nationalteam10)
	end
	if args.nationalyears10 then
		printfd("| nationalyears10 = %s", args.nationalyears10)
	end
	if args.nationalgames_goals10 then
		printfd("| nationalgames_goals10 = %s", args.nationalgames_goals10)
	end
	if args.nationalgamesgoalstotal then
		printfd("| nationalgames_goalstotal = %s", args.nationalgamesgoalstotal)
	end
	if args.coachclubs and args.coachyears and args.coachgameswins then
		processTeamsYears(args.coachclubs, args.coachyears, args.coachgameswins,
			"coachclub", "coachyears", "coachgames_wins", "coachgames(wins)")
	elseif args.coachclubs or args.coachyears or args.coachgameswins then
		print("<!-- Template:Infobox AFL biography conversion error: " ..
		      "Template is missing expected parameters. -->")
		printfd("| coachclubs = %s", args.coachclubs)
		printfd("| coachyears = %s", args.coachyears)
		printfd("| coachgames(wins) = %s", args.coachgameswins)
	end
	if args.coachteam1 then
		printfd("| coachteam1 = %s", args.coachteam1)
	end
	if args.coachyears1 then
		printfd("| coachyears1 = %s", args.coachyears1)
	end
	if args.coachgames_goals1 then
		printfd("| coachgames_goals1 = %s", args.coachgames_goals1)
	end
	if args.coachteam2 then
		printfd("| coachteam2 = %s", args.coachteam2)
	end
	if args.coachyears2 then
		printfd("| coachyears2 = %s", args.coachyears2)
	end
	if args.coachgames_goals2 then
		printfd("| coachgames_goals2 = %s", args.coachgames_goals2)
	end
	if args.coachteam3 then
		printfd("| coachteam3 = %s", args.coachteam3)
	end
	if args.coachyears3 then
		printfd("| coachyears3 = %s", args.coachyears3)
	end
	if args.coachgames_goals3 then
		printfd("| coachgames_goals3 = %s", args.coachgames_goals3)
	end
	if args.coachteam4 then
		printfd("| coachteam4 = %s", args.coachteam4)
	end
	if args.coachyears4 then
		printfd("| coachyears4 = %s", args.coachyears4)
	end
	if args.coachgames_goals4 then
		printfd("| coachgames_goals4 = %s", args.coachgames_goals4)
	end
	if args.coachteam5 then
		printfd("| coachteam5 = %s", args.coachteam5)
	end
	if args.coachyears5 then
		printfd("| coachyears5 = %s", args.coachyears5)
	end
	if args.coachgames_goals5 then
		printfd("| coachgames_goals5 = %s", args.coachgames_goals5)
	end
	if args.coachteam6 then
		printfd("| coachteam6 = %s", args.coachteam6)
	end
	if args.coachyears6 then
		printfd("| coachyears6 = %s", args.coachyears6)
	end
	if args.coachgames_goals6 then
		printfd("| coachgames_goals6 = %s", args.coachgames_goals6)
	end
	if args.coachteam7 then
		printfd("| coachteam7 = %s", args.coachteam7)
	end
	if args.coachyears7 then
		printfd("| coachyears7 = %s", args.coachyears7)
	end
	if args.coachgames_goals7 then
		printfd("| coachgames_goals7 = %s", args.coachgames_goals7)
	end
	if args.coachteam8 then
		printfd("| coachteam8 = %s", args.coachteam8)
	end
	if args.coachyears8 then
		printfd("| coachyears8 = %s", args.coachyears8)
	end
	if args.coachgames_goals8 then
		printfd("| coachgames_goals8 = %s", args.coachgames_goals8)
	end
	if args.coachteam9 then
		printfd("| coachteam9 = %s", args.coachteam9)
	end
	if args.coachyears9 then
		printfd("| coachyears9 = %s", args.coachyears9)
	end
	if args.coachgames_goals9 then
		printfd("| coachgames_goals9 = %s", args.coachgames_goals9)
	end
	if args.coachteam10 then
		printfd("| coachteam10 = %s", args.coachteam10)
	end
	if args.coachyears10 then
		printfd("| coachyears10 = %s", args.coachyears10)
	end
	if args.coachgames_goals10 then
		printfd("| coachgames_goals10 = %s", args.coachgames_goals10)
	end
	if args.coachgameswinstotal then
		printfd("| coachgames_winstotal = %s", args.coachgameswinstotal)
	end
	if args.umpireyears1 then
		printfd("| umpireyears1 = %s", args.umpireyears1)
	end
	if args.umpireleague1 then
		printfd("| umpireleague1 = %s", args.umpireleague1)
	end
	if args.umpirerole1 then
		printfd("| umpirerole1 = %s", args.umpirerole1)
	end
	if args.umpiregames1 then
		printfd("| umpiregames1 = %s", args.umpiregames1)
	end
	if args.umpireyears2 then
		printfd("| umpireyears2 = %s", args.umpireyears2)
	end
	if args.umpireleague2 then
		printfd("| umpireleague2 = %s", args.umpireleague2)
	end
	if args.umpirerole2 then
		printfd("| umpirerole2 = %s", args.umpirerole2)
	end
	if args.umpiregames2 then
		printfd("| umpiregames2 = %s", args.umpiregames2)
	end
	if args.umpireyears3 then
		printfd("| umpireyears3 = %s", args.umpireyears3)
	end
	if args.umpireleague3 then
		printfd("| umpireleague3 = %s", args.umpireleague3)
	end
	if args.umpirerole3 then
		printfd("| umpirerole3 = %s", args.umpirerole3)
	end
	if args.umpiregames3 then
		printfd("| umpiregames3 = %s", args.umpiregames3)
	end
	if args.umpireyears4 then
		printfd("| umpireyears4 = %s", args.umpireyears4)
	end
	if args.umpireleague4 then
		printfd("| umpireleague4 = %s", args.umpireleague4)
	end
	if args.umpirerole4 then
		printfd("| umpirerole4 = %s", args.umpirerole4)
	end
	if args.umpiregames4 then
		printfd("| umpiregames4 = %s", args.umpiregames4)
	end
	if args.umpireyears5 then
		printfd("| umpireyears5 = %s", args.umpireyears5)
	end
	if args.umpireleague5 then
		printfd("| umpireleague5 = %s", args.umpireleague5)
	end
	if args.umpirerole5 then
		printfd("| umpirerole5 = %s", args.umpirerole5)
	end
	if args.umpiregames5 then
		printfd("| umpiregames5 = %s", args.umpiregames5)
	end
	printfd("| careerhighlights = %s", args.careerhighlights)
	print("}}")

	return getBuffer("\n")
end

function p.main(frame)
	local args = require("Module:Arguments").getArgs(frame)
	return p._main(args)
end

return p