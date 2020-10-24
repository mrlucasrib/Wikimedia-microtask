local p = {}
local mYesno = require('Module:Yesno')
-- a global per #invoke 
local linked_write_in = false

function formatnum( num )
	-- simple wrapper
	local lang = mw.getContentLanguage()
	return lang:formatNum( num )
end

function percent( part, total )
	if total >= 1000000 then
		-- if > 1 million votes, then round to 2 decimals
		round_to = 2
	else
		round_to = 1
	end
	local ret = mw.ext.ParserFunctions.expr( "" .. 100 * part / total .. " round " .. round_to )
	if not string.find( ret, ".", 1, true ) then
		-- add the decimals that expr doesn't
		ret = ret .. "." .. string.rep("0", round_to)
	end
	return ret
end

function p.make( invoke )
	frame = invoke:getParent()
	local state, year, contest, type = parse_args( frame.args )
	local ret = ""
	local no_headings = mYesno(frame.args["no headings"])
	if string.find(year, ",", 1, true )  then
		-- multi mode
		for i,v in pairs(mw.text.split( year, ",", true )) do
			if not no_headings then
				ret = ret .. "\n=== " .. v .. " ==="
			end
			ret = ret .. make( state, v, contest, type, year_args(v, frame.args) )
		end
	else
		ret = ret .. make( state, year, contest, type, frame.args )
	end
	return invoke:preprocess( ret )
end

function fmt_candidate(v, winner, total_votes,args, usestateparties)
	local temp = "{{"
	if v[2] == winner[2] then
		temp = temp .. "Election box winning candidate"
	else
		temp = temp .. "Election box candidate"
	end
	local n_party = normalize_parties( v[3], usestateparties )
	if n_party then
		temp = temp .. " with party link no change|party=" .. n_party
	else
		temp = temp .. " no party link no change"
	end
	link = args[v[2] .. " link"]
	if link then
		link = mw.title.new(link)
	else
		-- bypass redirects, which is mostly important for display names
		link = mw.title.new(v[2])
		-- except if the redirect goes to an "elections" article (e.g. Kim Vann), then
		-- we don't want a bypass
		if link.isRedirect and not string.find(link.redirectTarget.prefixedText, "elections", 1, true ) then
			link = link.redirectTarget
		end
	end
	-- Strip disambiguators since we can't use the pipe trick
	display_name, ignore = mw.ustring.gsub(link.prefixedText, "%b()", "")
	if args.redlinks or (link.exists and not link.isRedirect) then
		full_link = "[[" .. link.prefixedText .. "|" .. display_name .. "]]"
	else
		full_link = display_name
	end
	temp = temp .. "|candidate=" .. full_link
	if v[4] or args.incumbent == v[2] then
		-- incumbent
		temp  = temp .. " (Incumbent)"
	end
	if v[6] then
		-- write in
		if linked_write_in then
			temp = temp .. " (write-in)"
		else
			temp = temp .. " ([[Write-in candidate|write-in]])"
			linked_write_in = true -- only link it once
		end
	end
	temp = temp .. "|votes=" .. formatnum(v[5])
	temp = temp .. "|percentage=" .. percent(v[5], total_votes) .. "%"
	temp = temp .. "}}"
	return temp
end

function parse_args( args )
	local state = args[1]
	if not state then
		error("State is missing")
	end
	local year = args[2]
	if not year then
		error("Year is missing")
	end
	local contest = args[3]
	if not contest then
		error("Contest is missing")
	end
	local type = "General"
	if args.type then
		if args.type == "Primary" then
			type = "Primary"
		else
			error("Invalid value for |type=")
		end
	end
	return state, year, contest, type
end

function year_args( year, args )
	-- we want to turn year args like "|2018 foo=" into just foo
	-- drop any other year args like "|2016 foo="
	-- and have year args override general args
	-- finally have general args
	local new = {}
	for k,v in pairs(args) do
		local k_year = mw.ustring.match(k, "^%d%d%d%d ")
		if k_year then
			k_year = mw.text.trim(k_year)
		end
		if k_year and k_year == year then
			new[mw.ustring.sub(k, 6)] = v
		elseif k_year and k_year ~= year then
			-- do nothing
		else
			-- if k isn't set yet, set it.
			if not new[k] then
				new[k] = v
			end
		end
	end
	return new
end

function make( state, year, contest, type, args )
	function load_tabular( state, year, type )
		local tab_name = state .. " Elections/" .. year .. "/" .. type .. "/Candidates.tab"
		local tabular = mw.ext.data.get(tab_name)
		if tabular then
			return tabular
		else
			return {error="Unable to find tabular data: " .. tab_name}
		end
	end
	local tabular = load_tabular(state, year, type)
	if tabular.error then
		error(tabular.error)
	end
	function find_candidates(data, contest)
		local candidates = {}
		for k,v in pairs(data) do
			if v[1] == contest then
				table.insert(candidates, v)
			end
		end
		return candidates
	end
	local candidates = find_candidates(tabular.data, contest)
	function sum_totals(candidates)
		local total_votes = 0
		local incumb_party = false
		local winner = {}
		winner[5] = 0
		for k,v in pairs(candidates) do
			total_votes = total_votes + v[5]
			if v[5] > winner[5] then
				winner = v
			end
			if v[4] or args.incumbent == v[2] then
				incumb_party = v[3]
			end
		end
		return total_votes, winner, incumb_party
	end
	local total_votes, winner, incumb_party = sum_totals(candidates)
	local usestateparties = nil
	if mw.ustring.find(contest, "United States Representative", 1, true) then
		title = "[[United States House of Representatives elections, " .. year .. "]]"
	elseif mw.ustring.find(contest, "State Assembly Member", 1, true) then
		title = "[[" .. state .. " State Assembly election, " .. year .. "]]"
		usestateparties = state
	elseif contest == "President" then
		title = "U.S. presidential election in " .. state .. ", " .. year
	else
		title = "...????"
	end
	local primary = mYesno(args.primary)
	ptabular = load_tabular(state, year, "Primary")
	if ptabular.error then
		-- todo log an error here?
		primary = false
	end
	if primary then
		open = "Election box open primary begin no change"
	else
		open = "Election box begin no change"
	end
	function make_ref(tabular)
		return '<ref name="' .. tabular.description .. '">' .. tabular.sources .. "</ref>"
	end
	local ref = make_ref(tabular)
	if primary then
		-- primary ref goes first
		ref = make_ref(ptabular) .. ref
	end
	local ret = "{{" .. open .. "| title=" .. title .. ref .. "}}"
	function total_box(total_votes)
		return "{{Election box total no change|votes=" .. formatnum(total_votes) .. "|percentage = " .. percent(total_votes, total_votes) .. "%}}"
	end
	function sort_candidates(a,b)
		return a[5] > b[5]
	end
	table.sort(candidates, sort_candidates)
	if primary then
		local pcandidates = find_candidates(ptabular.data, contest)
		table.sort(pcandidates, sort_candidates)
		local ptotal_votes, pwinner, pincumb_party = sum_totals(pcandidates)
		local fake_winner = {}
		-- we don't want a winner in primaries, so use a fake one that no
		-- candidate will match
		fake_winner[2] = ""
		for k,v in pairs(pcandidates) do
			ret = ret .. fmt_candidate(v, fake_winner,ptotal_votes,args,usestateparties)
		end
		ret = ret .. total_box(ptotal_votes) .. "{{Election box open primary general election no change}}"
	end

	for k,v in pairs(candidates) do
		ret = ret .. fmt_candidate(v, winner,total_votes,args,usestateparties)
	end
	ret = ret .. total_box(total_votes)
	local hold = args.hold
	local gain = false
	if hold == "held" or winner[4] or args.incumbent == winner[2] then
		ret = ret .. "{{Election box hold with party link without swing|winner=" .. normalize_parties(winner[3],usestateparties) .. "}}"
	elseif hold == "flip" then
		-- shorthand for D->R/R->D
		win_party = winner[3]
		if win_party == "Democratic" then
			lose_party = normalize_parties("Republican",usestateparties)
		else
			lose_party = normalize_parties("Democratic",usestateparties)
		end
		win_party = normalize_parties(win_party)
		gain = true
	elseif args.gain then
		win_party = normalize_parties(args.gain,usestateparties)
		lose_party = normalize_parties(args.loser,usestateparties)
		gain = true
	elseif incumb_party and incumb_party ~= winner[3] then
		win_party = normalize_parties(winner[3],usestateparties)
		lose_party = normalize_parties(incumb_party,usestateparties)
		gain = true
	end
	if gain then
		ret = ret .. "{{Election box gain with party link without swing|winner=" .. win_party .. "|loser=" .. lose_party .. "}}"
	end

	ret = ret .. "{{Election box end}}"
	return ret
end

function normalize_parties( party, state )
	-- Drop all parties after the first one?
	party = mw.text.split( party, ",", true )[1]
	local specials = {
		Blank = "Independent (politician)",
		Independent = "Independent (politician)",
	}
	specials["No Party Preference"] = "No party preference"
	if specials[party] then
		return specials[party]
	end
	
	if state then
		-- ex "California Democratic Party"
		return state .. " " .. party .. " Party"
	end
	
	return party .. " Party (US)"
end

return p