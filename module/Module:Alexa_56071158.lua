-- Module to implement Template:Alexa with Wikidata fetch

p = {}

local i18n =
{
    ["months"] =
    {
    	"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
    }
}

-- should use Module:Arguments if non-Wikidata values are allowed or required by RfC
p.main = function(frame)
	local args = frame.args
	-- can take a named parameter |qid which is the Wikidata ID for the article.
	-- This will not normally be used because it's an expensive call.
	local qid = frame.args.qid
	if qid and (#qid == 0) then qid = nil end
	
	-- can take a date format parameter df= ["dmy" / "mdy" / "y"]
	-- default will be "dmy"
	local datefmt = string.lower(frame.args.df or "dmy")
	
	local out = ""
	-- See what's on Wikidata:
	local entity = mw.wikibase.getEntityObject(qid)
	if entity and entity.claims then
		local props = entity.claims["P1661"]
		if props and props[1] then
			-- item has Alexa rank property
			local rank = {}
			local rankdate = {}
			for k, v in pairs(props) do
				local rnk = tonumber(v.mainsnak.datavalue.value.amount)
				if rnk then
					rank[#rank+1] = rnk
					if v.qualifiers and v.qualifiers["P585"] then
						local rd = v.qualifiers["P585"][1].datavalue.value.time
						if rd then
							rankdate[#rank] = rd:sub(2, 11)
						else
							-- this shouldn't happen
							rankdate[#rank] = "! no date !"
						end
					else
						-- we might have to look in references for date
						if v.references and v.references[1].snaks["P585"] then
							local rd = v.references[1].snaks["P585"][1].datavalue.value.time
							if rd then
								rankdate[#rank] = rd:sub(2, 11)
							else
								-- this shouldn't happen
								rankdate[#rank] = "! no ref !"
							end
						else
							-- no refs or point-in-time
							rankdate[#rank] = "1952-04-27"
						end
					end -- test for qualifiers
				end -- test for Alexa rank
			end -- loop through properties
			
			-- We have one or more Alexa ranks
			-- find the last two
			local now = "1900-01-01"
			local prev = now
			local ranknow = rank[1]
			local rankprev = rank[1]
			for k, v in ipairs(rankdate) do
				if v > now then
					prev = now
					now = v
					rankprev = ranknow
					ranknow = rank[k]
				end
			end
			
			-- pick the icon to display
			local icon = ""
			local alt = ""
			if ranknow == rankprev then
				icon = "Steady2.svg"
				alt = "Same rank (no relative change in site traffic)"
			elseif ranknow < rankprev then
				icon = "Decrease Positive.svg"
				alt = "Lower rank (relative increase in site traffic)"
			else
				icon = "Increase Negative.svg"
				alt = "Higher rank (relative decrease in site traffic)"
			end
			
			-- format the date
			if datefmt == 'y' then
				now = now:sub(1, 4)
			elseif datefmt == 'mdy' then
				now = i18n.months[tonumber(now:sub(6, 7))] .. " " .. tonumber(now:sub(9, 10)) .. ", " .. now:sub(1, 4)
			else
				now = tonumber(now:sub(9, 10)) .. " " .. i18n.months[tonumber(now:sub(6, 7))] .. " " .. now:sub(1, 4)
			end
			
			-- assemble the output
			out = "[[File:" .. icon .. "|11px|alt=" .. alt .. "|" .. alt .. "|link=]] " .. ranknow .. " (" .. now .. ")"
		else
			-- no property on Wikidata
			out = "No Alexa rank" --nil
		end -- test for properties
	elseif args[1] and args[2] and args[3] and args[4] then
		-- args.url or args[5] should be reference link, args.archive1 or args[6] should be newer archive URL and args.archive2 or args[7] should be older archive URL. alternately parameters could be reordered to sort of encourage archiving the URLs
		args[1] = mw.ustring.gsub(args[1], "%p", "")
		args[3] = mw.ustring.gsub(args[3], "%p", "")
		local icon = ""
		local alt = ""
		if args[1] == args[3] then
			icon = "Steady2.svg"
			alt = "Same rank (no relative change in site traffic)"
		elseif args[1] < args[3] then
			icon = "Decrease Positive.svg"
			alt = "Lower rank (relative increase in site traffic)"
		else
			icon = "Increase Negative.svg"
			alt = "Higher rank (relative decrease in site traffic)"
		end
		out = "[[File:" .. icon .. "|11px|alt=" .. alt .. "|" .. alt .. "|link=]] " .. args[1] .. " (" .. args[2] .. ")"
	else
	-- no item on Wikidata
		out = "No Wikidata item" --nil
	end -- test for item
	return out
end

return p