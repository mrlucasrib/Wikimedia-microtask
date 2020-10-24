local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local Vgwd = require('Module:Video game wikidata')

local p = {}

local columns = {
	['mc'] = nil,
	['gr'] = nil,
	['fam'] = nil,
	['sales'] = nil,
	['year'] = nil,
}

local function sortByNumber(a,b)
	return a['num'] < b['num']
end;

local function sortByPublicationDate(a,b)
	local aP = a['pubDate'];
	local bP = b['pubDate'];
	if(aP ~= nil and bP ~= nil) then
		return aP < bP;
	end;
	
	-- fallback sorting, let's assume the oldest wikidata entity is the oldest game
	local aQ = a['qid'];
	local bQ = b['qid'];
	if(aQ ~= nil and bQ ~= nil) then
		return aQ < bQ;
	end;
	
	-- still nothing? okay, let's just use the initial order
	return a['num'] < b['num'];
end;

local function getVGWD(frame, reviewer)
	-- Obey local override on displaying this reviewer, don't bother trying to get Wikidata.
	if(columns[reviewer] == false) then
		return nil;
	end;

	local vgwdScore = Vgwd.setReviewer(reviewer);
	if(vgwdScore ~= nil) then
		return vgwdScore;
	end;
	
	-- Because a game with no platforms may disable show system, we have to reenable for each game.
	Vgwd.setShowSystem(true);	

	return Vgwd.printReviewScores(frame);
end;

local function checkColumn(game, column)
	if(game[column] ~= nil and game[column] ~= "" and columns[column] ~= false) then
		columns[column] = true;
	end;
end;

local function buildGameEntry(args, num, qid)
	local game = {}
	game['num'] = num;
	game['name'] = args["game"..num];
	game['mc'] = args["mc"..num];
	game['gr'] = args["gr"..num];
	game['fam'] = args["fam"..num];
	game['sales'] = args["sales"..num];
	game['year'] = args["year"..num];	
	if(qid ~= nil) then
		-- If a qid was supplied, we are doing a series pull and won't check columns here.
		game['qid'] = qid;		
	else
		-- Pulling game data purely from arguments, so check columns.
		game['qid'] = args["qid"..num];
		checkColumn(game, 'gr');
		checkColumn(game, 'fam');
		checkColumn(game, 'mc');
		checkColumn(game, 'year');
		checkColumn(game, 'sales');			
	end;

	return game;
end;	

local function buildGameWikidata(frame, game)
	if(game['qid'] ~= nil) then
		local vgwdScore = Vgwd.setGame(game["qid"]);
		if(vgwdScore == nil) then
			game['updateLink'] = Vgwd.getUpdateLink();
			if(game['mc'] == nil) then
				game['mc'] = getVGWD(frame, 'mc')
			end;
			if(game['gr'] == nil and columns['gr']) then
				game['gr'] = getVGWD(frame, 'gr')
			end;
			if(game['fam'] == nil and columns['fam']) then
				game['fam'] = getVGWD(frame, 'fam')
			end;
			if(game['name'] == nil) then
				local sitelink = Vgwd.getSitelink();
				local label = Vgwd.getLabel();
				if(sitelink ~= nil) then
					if(sitelink ~= label) then
						game['name'] = "[[" .. sitelink .. "|" .. label .. "]]";
					else
						game['name'] = "[[" .. sitelink .. "]]";									
					end;
				else
					game['name'] = label;
				end;
			end;
			if(game['year'] == nil) then
				local pubDate = Vgwd.getEarliestPublicationDate();
				game['pubDate'] = pubDate;
				if(pubDate ~= nil) then
					game['year'] = pubDate.year;
				end;
			end;
		else
			-- Entity wasn't found... How to represent? TODO.
		end;
	end;
				
	-- We don't check GR and FAM because they must be explicitly enabled by arguments.
	checkColumn(game, 'mc');
	checkColumn(game, 'year');
	checkColumn(game, 'sales');
	
	return game;
end;

function p.main(frame)
	local args = getArgs(frame)
	return p._main(frame, args)
end

function p._main(frame, args)
	-- Get specified values of column display parameters. Nil = Unspecified.
	if(args["mc"]) then
		columns['mc'] = yesno(args.mc);
	end
	if(args["gr"]) then
		columns['gr'] = yesno(args.gr);
	end	
	if(args["fam"]) then
		columns['fam'] = yesno(args.fam);
	end		
	if(args["sales"]) then
		columns['sales'] = yesno(args.sales);
	end			
	if(args["years"]) then
		columns['year'] = yesno(args.years);
	end			
	
	local seriesQid = args["seriesQid"]; -- Should be nil, but for testing we have to be able to supply one.
	
	Vgwd.setDateFormat(args["df"]);
	Vgwd.setSystem(nil);
	Vgwd.setGenerateReferences(true);
	Vgwd.setShowUpdateLink(false);
	Vgwd.setUpdateLinkStyle("pen");
	
	local games = {};
	local gameRead = {};
	
	-- Look for locally provided gameN and qidN parameters first. Build a table containing all the arguments.
	for k, v in pairs(args) do
		if(string.find(k, "game%d+") or string.find(k, "qid%d+")) then
			local num = tonumber(string.match(k, "%d+"))
			if(num ~= nil) then
				if(gameRead[num] == nil) then
					gameRead[num] = true;
					table.insert(games, buildGameEntry(args,num));
				end;
			end;
		end;		
	end;

	-- Did we find any games specified on the arguments?
	if(#games > 0) then
		-- Sort by entry.
		table.sort(games, sortByNumber);
		
		-- Retrieve missing data with Wikidata if possible, for each entry.
		for i, game in ipairs(games) do
			games[i] = buildGameWikidata(frame,game);
		end;
	else
		-- If we didn't get any games from the arguments, try to pull the parts of the series from Wikidata.
		-- Reset vgwd to current page, presumably a series.
		local vgwdScore = Vgwd.setGame(seriesQid);
		if(vgwdScore == nil) then
			local parts = Vgwd.getParts();
			for i, qid in ipairs(parts) do
				-- Build an entry.
				local game = buildGameEntry({},i,qid)
				
				-- Retrieve the data from Wikidata and store in the table.
				table.insert(games, buildGameWikidata(frame,game));
			end;
			
			table.sort(games, sortByPublicationDate);
		else
			-- Entity wasn't found... How to represent? TODO.
		end;
	end;

	local ret = "{| class=\"wikitable plainrowheaders\" style=\"font-size: 90%; float: right; clear: right; margin:0.5em 0 0.5em 1em;\"\n"
	
	ret = ret .."|+ style=\"font-size: 111.11%;\" | "
	if args.title then
		ret = ret .. args.title
	elseif columns['sales'] then
		if columns['fam'] then
			ret = ret .. "Sales and review scores"
		elseif columns['gr'] or columns['mc'] then
			ret = ret .. "Sales and aggregate review scores"
		else
			ret = ret .. "Sales"
		end
	elseif columns['fam'] then
		if columns['gr'] or columns['mc'] then
			ret = ret .. "Japanese and Western review scores"
		else
			ret = ret .. "Famitsu review scores"
		end
	else
		ret = ret .. "Aggregate review scores"
	end

	if args.updated then
		ret = ret .. "<br /><small>''As of " .. args.updated ..".''</small>"
	end
	ret = ret .. " \n"
	
	ret = ret .. "! scope=\"col\" | Game \n"
	if columns['year'] then
		ret = ret .. "! scope=\"col\" | Year\n"
	end	
	if columns['sales'] then
		ret = ret .. "! scope=\"col\" | " .. (args.sales_title or "Units sold") .. " \n"
	end
	if columns['fam'] then
		ret = ret .. "! scope=\"col\" | " .. (args.fam_title or  "''[[Famitsu scores|Famitsu]]''") .. " \n"
	end
	if columns['gr'] then
		ret = ret .. "! scope=\"col\" | " .. (args.gr_title or  "[[GameRankings]]") .. " \n"
	end
	if columns['mc'] then
		ret = ret .. "! scope=\"col\" | " .. (args.mc_title or  "[[Metacritic]]") .. " \n"
	end
	
	-- Print the reviews
    for i,game in ipairs(games) do
		ret = ret .. "|-\n"
		ret = ret .. "! scope=\"row\" | ''" .. game['name'] .. "''"
		if(game['updateLink']) then
			ret = ret .. " " .. game['updateLink'];
		end;
		ret = ret .. "\n"
	
		if columns['year'] then
			ret = ret .. "| style=\"text-align: center;\" | " .. (game['year'] or '') .. " \n"
		end	
		if columns['sales'] then
			ret = ret .. "| style=\"text-align: center;\" | " .. (game['sales'] or '') .. " \n"
		end
		if columns['fam'] then
			ret = ret .. "| style=\"text-align: center;\" | " .. (game['fam'] or '') .. " \n"
		end
		if columns['gr'] then
			ret = ret .. "| style=\"text-align: center;\" | " .. (game['gr'] or '') .. " \n"
		end
		if columns['mc'] then
			ret = ret .. "| style=\"text-align: center;\" | " .. (game['mc'] or '') .. " \n"
		end	
	end;

	ret = ret .. "|}"

	return ret
end

return p