-- This module implements [[Template:Infobox tennis tournament event/events]].
-- [SublimeLinter luacheck-globals:mw]

local p = {}
local getBuffer, print = require("Module:OutputBuffer")()

local STYLES = {
	["singlesdoubles"] = {[=[|-
| [[{prefix} {year} {tournament} – Singles|Singles]]
| [[{prefix} {year} {tournamentd} – Doubles|Doubles]]]=]},
		["1"] = "singlesdoubles",
		["men"] = "singlesdoubles",
		["mens"] = "singlesdoubles",
		["women"] = "singlesdoubles",
		["womens"] = "singlesdoubles",
	["risingstarsinvitational"] = {[=[|-
| [[{prefix} {year} {tournament} – Singles|Singles]]
| [[{prefix} {year} {tournamentd} – Doubles|Doubles]]
|-
| colspan="2" | [[{prefix} {year} {tournament} – Rising Stars Invitational|Rising Stars]]]=]},
	["boysgirlssingles"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{prefix} {year} {tournament} – Men's Singles|men]]
| [[{prefix} {year} {tournament} – Women's Singles|women]]
| [[{prefix} {year} {tournament} – Boys' Singles|boys]]
| [[{prefix} {year} {tournament} – Girls' Singles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{prefix} {year} {tournament} – Men's Doubles|men]]
| [[{prefix} {year} {tournament} – Women's Doubles|women]]]=]},
		["miamimasters"] = "boysgirlssingles",
	["mixeddoubles"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{prefix} {year} {tournament} – Men's Singles|men]]
| [[{prefix} {year} {tournament} – Women's Singles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{prefix} {year} {tournament} – Men's Doubles|men]]
| [[{prefix} {year} {tournament} – Women's Doubles|women]]
| [[{prefix} {year} {tournament} – Mixed Doubles|mixed]]]=]},
		["mixed"] = "mixeddoubles",
		["grandslam"] = "mixeddoubles",
	["mixedandteam"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{prefix} {year} {tournament} – Men's Singles|men]]
| [[{prefix} {year} {tournament} – Women's Singles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{prefix} {year} {tournament} – Men's Doubles|men]]
| [[{prefix} {year} {tournament} – Women's Doubles|women]]
| [[{prefix} {year} {tournament} – Mixed Doubles|mixed]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Team
| [[{prefix} {year} {tournament} – Men's Team|men]]
| [[{prefix} {year} {tournament} – Women's Team|women]]]=]},
	["australianopen"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{year} {tournament} – Men's Singles|men]]
| [[{year} {tournament} – Women's Singles|women]]
|
| [[{year} {tournament} – Boys' Singles|boys]]
| [[{year} {tournament} – Girls' Singles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{year} {tournament} – Men's Doubles|men]]
| [[{year} {tournament} – Women's Doubles|women]]
| [[{year} {tournament} – Mixed Doubles|mixed]]
| [[{year} {tournament} – Boys' Doubles|boys]]
| [[{year} {tournament} – Girls' Doubles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Legends
| [[{year} {tournament} – Men's Legends' Doubles|men]]
| [[{year} {tournament} – Women's Legends' Doubles|women]]
| [[{year} {tournament} – Legends Mixed|mixed]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Singles
| [[{year} {tournament} – Wheelchair Men's Singles|men]]
| [[{year} {tournament} – Wheelchair Women's Singles|women]]
| [[{year} {tournament} – Wheelchair Quad Singles|quad]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Doubles
| [[{year} {tournament} – Wheelchair Men's Doubles|men]]
| [[{year} {tournament} – Wheelchair Women's Doubles|women]]
| [[{year} {tournament} – Wheelchair Quad Doubles|quad]]
]=]},
	["frenchopen"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{year} {tournament} – Men's Singles|men]]
| [[{year} {tournament} – Women's Singles|women]]
|
| [[{year} {tournament} – Boys' Singles|boys]]
| [[{year} {tournament} – Girls' Singles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{year} {tournament} – Men's Doubles|men]]
| [[{year} {tournament} – Women's Doubles|women]]
| [[{year} {tournament} – Mixed Doubles|mixed]]
| [[{year} {tournament} – Boys' Doubles|boys]]
| [[{year} {tournament} – Girls' Doubles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Legends
| [[{year} {tournament} – Legends Under 45 Doubles|−45]]
| [[{year} {tournament} – Legends Over 45 Doubles|45+]]
| [[{year} {tournament} – Women's Legends Doubles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Singles
| [[{year} {tournament} – Wheelchair Men's Singles|men]]
| [[{year} {tournament} – Wheelchair Women's Singles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Doubles
| [[{year} {tournament} – Wheelchair Men's Doubles|men]]
| [[{year} {tournament} – Wheelchair Women's Doubles|women]]
]=]},
	["wimbledonchampionships"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{year} {tournament} – Men's Singles|men]]
| [[{year} {tournament} – Women's Singles|women]]
|
| [[{year} {tournament} – Boys' Singles|boys]]
| [[{year} {tournament} – Girls' Singles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{year} {tournament} – Men's Doubles|men]]
| [[{year} {tournament} – Women's Doubles|women]]
| [[{year} {tournament} – Mixed Doubles|mixed]]
| [[{year} {tournament} – Boys' Doubles|boys]]
| [[{year} {tournament} – Girls' Doubles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Legends
| [[{year} {tournament} – Gentlemen's Invitation Doubles|men]]
| [[{year} {tournament} – Ladies' Invitation Doubles|women]]
| [[{year} {tournament} – Senior Gentlemen's Invitation Doubles|seniors]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Doubles
| [[{year} {tournament} – Wheelchair Men's Doubles|men]]
| [[{year} {tournament} – Wheelchair Women's Doubles|women]]
]=]},
	["usopen"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{year} {tournament} – Men's Singles|men]]
| [[{year} {tournament} – Women's Singles|women]]
|
| [[{year} {tournament} – Boys' Singles|boys]]
| [[{year} {tournament} – Girls' Singles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{year} {tournament} – Men's Doubles|men]]
| [[{year} {tournament} – Women's Doubles|women]]
| [[{year} {tournament} – Mixed Doubles|mixed]]
| [[{year} {tournament} – Boys' Doubles|boys]]
| [[{year} {tournament} – Girls' Doubles|girls]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Legends
| [[{year} {tournament} – Men's Champions Invitational|men]]
| [[{year} {tournament} – Women's Champions Invitational|women]]
| [[{year} {tournament} – Mixed Champions Invitational|mixed]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Singles
| [[{year} {tournament} – Wheelchair Men's Singles|men]]
| [[{year} {tournament} – Wheelchair Women's Singles|women]]
| [[{year} {tournament} – Wheelchair Quad Singles|quad]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | WC&nbsp;Doubles
| [[{year} {tournament} – Wheelchair Men's Doubles|men]]
| [[{year} {tournament} – Wheelchair Women's Doubles|women]]
| [[{year} {tournament} – Wheelchair Quad Doubles|quad]]
]=]},
	["abnamroworldtennistournament"] = {[=[|-
| [[{prefix} {year} {tournament} – Singles|singles]]
| [[{prefix} {year} {tournamentd} – Doubles|doubles]]
|-
| [[{prefix} {year} {tournament} – Wheelchair Singles|wheelchair singles]]
| [[{prefix} {year} {tournamentd} – Wheelchair Doubles|wheelchair doubles]]]=]},
	["doublestwotourneys"] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{prefix} {year} {tournament} – Singles|men]]
| [[{prefix} {year} {tournamentd} – Singles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{prefix} {year} {tournament} – Doubles|men]]
| [[{prefix} {year} {tournamentd} – Doubles|women]]]=]},
	[""] = {[=[|-
! scope="row" style="font-weight: normal; text-align: right;" | Singles
| [[{prefix} {year} {tournament} – Men's Singles|men]]
| [[{prefix} {year} {tournament} – Women's Singles|women]]
|-
! scope="row" style="font-weight: normal; text-align: right;" | Doubles
| [[{prefix} {year} {tournament} – Men's Doubles|men]]
| [[{prefix} {year} {tournament} – Women's Doubles|women]]]=]}}

local function pullItem(value, default)
	value = value and string.lower(string.gsub(value, "%A", ""))
	if type(STYLES[value]) == "string" then
		value = STYLES[value]
	end
	if STYLES[value] then
		return STYLES[value][1]
	else
		return STYLES[default][1]
	end
end

function p._main(args)
	local default = ""
	if args[2] ~= args[3] then
		default = "doublestwotourneys"
	end

	print('{| style="border-spacing: 0.6em 0; margin: auto; ' ..
		  'text-align: center;"')
	print(string.gsub(pullItem(args.type, default), "{(%a+)}",
		{prefix = args.prefix or "", year = args[1], tournament = args[2],
		 tournamentd = args[3]}))
	print("|}")
	return getBuffer("\n")
end

function p.main(frame)
	local args = require("Module:Arguments").getArgs(frame)
	return p._main(args)
end

return p