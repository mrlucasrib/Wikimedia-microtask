local p = {}

function p.countdown(frame)
	local year1 = tonumber(frame.args.year1 or frame.args[1])
	local month1 = tonumber(frame.args.month1 or frame.args[2])
	local day1 = tonumber(frame.args.day1 or frame.args[3])
	local year2 = tonumber(frame.args.year2 or frame.args[4])
	local month2 = tonumber(frame.args.month2 or frame.args[5])
	local day2 = tonumber(frame.args.day2 or frame.args[6])
	local endtext = frame.args.endtext or "End of Event"
	local livetext = frame.args.livetext or "Live Event"
	local text = frame.args.text
	
	local time1 = nil
	local time2 = nil
	local bgcolor = "#666666"
	local textcolor = "#DDDDDD"
	
	local span = mw.html.create("span")
	span:css{
		["display"] = "inline-block",
		["font-weight"] = "bold",
		["font-style"] = "italic",
		["padding-left"] = "0.5em",
		["padding-right"] = "0.5em",
		["margin-bottom"] = "0.4em"
	}
	
	if text ~= nil or day1 == nil or month1 == nil or year1 == nil then
		span
			:css{background = bgcolor, color = textcolor}
			:wikitext(text or "Invalid input")
		return tostring(span)
	end
	
	time1 = frame:expandTemplate{title = "Age in days", args = {
		year2 = year1,
		month2 = month1,
		day2 = day1
	}}
	
	time1 = tonumber(time1:gsub("−", "-") .. "")
	
	if day2 == nil or month2 == nil or year2 == nil then
		time2 = time1
	else
		time2 = frame:expandTemplate{title = "Age in days", args = {
			year2 = year2,
			month2 = month2,
			day2 = day2
		}}
		time2 = tonumber(time2:gsub("−", "-") .. "")
	end
	
	if time1 > 0 then
		bgcolor = "#C66320"
		text = time1 .. " day"
		if time1 > 1 then text = text .. "s" end
		text = text .. " to go"
	elseif time2 < 0 then
		bgcolor = "#AA1111"
		text = endtext
	else
		bgcolor = "#00B000"
		text = livetext
	end
	
	textcolor = "#FFFFFF"
	
	span
		:css{background = bgcolor, color = textcolor}
		:wikitext(text)
	
	return tostring(span)
end

return p