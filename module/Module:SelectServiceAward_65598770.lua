local p = {}

local editreq = {175000, 150000, 132000, 114000, 96000, 78000, 60000, 51000, 42000, 33000, 28000, 24000, 20000, 16000, 12000, 8000, 6000, 5500, 5000, 4500,
	4000, 3500, 3000, 2500, 2000, 1750, 1500, 1250, 1000, 800, 600, 400, 200, 150, 100, 50, 1}

local edittime = {'20 years', '18 years', '16 years', '14 years', '12 years', '10 years', '8 years', '7 years', '6 years', '5 years', '4 years + 6 months', 
	'4 years', '3 years + 6 months', '3 years', '2 years + 6 months', '2 years', '1 year + 6 months', '1 year + 4 months + 15 days', '1 year + 3 months', 
	'1 year + 1 month + 15 days', '1 year', '10 months + 15 days', '9 months', '7 months + 15 days', '6 months', '5 months + 8 days', '4 months + 15 days', 
	'3 months + 23 days', '3 months', '2 months + 15 days', '2 months', '1 month + 15 days', '1 month', '23 days', '15 days', '8 days', '1 day'}

function p.main(frame)
	local numedits = tonumber(frame.args.edits)
	local date = frame.args.date
	local numpos = 0
	
	local time = tonumber(frame:callParserFunction('#time', 'U'))
	
	for i=1, 37 do
		if numedits >= editreq[i] and numpos == 0 then
			local timestr = date .. " + " .. edittime[i]
			local acctime = tonumber(frame:callParserFunction('#time', 'U', timestr))
			if time >= acctime then
				numpos = (38 - i)
			end
		end
	end
	return (numpos)
end

return p