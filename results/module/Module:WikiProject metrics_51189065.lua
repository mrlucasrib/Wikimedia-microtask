local p = {}

local Date = require("Module:Date")._Date
local lang = mw.language.new(mw.language.getContentLanguage().code)

local function getMonths(start)
	local month = Date("1 " .. start)
	local current = Date("currentdate")
	current = Date(current.year, current.month, 1)

	if month > current then
		return {}
	end

	local months = {month}

	while month < current do
		month = month + "1 month"
		table.insert(months, month)
	end

	return months
end

function p.list(frame)
	local baseTitle = frame:getParent():getTitle()
	local startMonth = frame.args[1]

	local months = getMonths(startMonth)
	local list = {}

	for i, month in pairs(months) do
		if i == 1 or month:text("%B") == "January" then
			local tag = '<span style="font-size: 120%%;">%s</span>'
			table.insert(list,  string.format(tag, month:text("%Y")))
		end

		local line = "* [[%s|%s]]: %s"
		local title = baseTitle .. "/" .. month:text("%B %Y")

		if mw.title.new(title).exists then
			local count = frame:preprocess("{{#lst:" .. title .. "|count}}")
			count = lang:formatNum(tonumber(count))
			local item = string.format(line, title, month:text("%b"), count)
			table.insert(list, item)
		end
	end

	return table.concat(list, "\n")
end

local function getList(frame, baseTitle, month, cols)
	local title = baseTitle .. "/" .. month:text("%B %Y")

	if not mw.title.new(title).exists then
		return ""
	end

	local list = frame:preprocess("{{#lst:" .. title .. "|list}}")
	local output = string.format("== %s ==\n", month:text("%B %Y"))

	output = output .. frame:expandTemplate{ title = "Hatnote", args = {
		"[[" .. title .. "]] (" ..
		frame:expandTemplate{ title = "Edit", args = { title } } ..
		")"
	} }

	if cols ~= nil then
		local div = '\n<div style="-moz-column-width: %s; -webkit-column-width: %s; column-width: %s;">' 
		output = output .. string.format(div, cols, cols, cols)
	end

	output = output .. "\n" .. list

	if cols ~= nil then
		output = output .. "\n</div>"
	end

	return output
end

function p.recent(frame)
	local baseTitle = frame:getParent():getTitle()
	local cols = frame.args[1]
	local now = Date("currentdate")
	
	local output = getList(frame, baseTitle, now, cols)
	
	if now.day < 10 then
		local older = getList(frame, baseTitle, now - "1 month", cols)
		output = output .. "\n" .. older
	end
	
	return output
end

function p.chart(frame)
	local baseTitle = frame:getParent():getTitle()
	local startMonth = frame.args[1]
	local now = Date("currentdate")
	local currentMonth = Date(now.year, now.month, 1)

	local months = getMonths(startMonth)
	local xdata = {}
	local y1data = {}
	local y2data = {}

	for i, month in pairs(months) do
		local title = baseTitle .. "/" .. month:text("%B %Y")
		
		if mw.title.new(title).exists then
			local count = frame:preprocess("{{#lst:" .. title .. "|count}}")
		
			table.insert(xdata, month:text("%b %Y"))
			table.insert(y1data, count)
			if month ~= currentMonth then
				table.insert(y2data, count)
			end
		end
	end

	local chart = frame:expandTemplate{ title = "Graph:Chart", args = {
		width = "600",
		height = "200",
		type = "line",
		xAxisTitle = "Month",
		yAxisTitle = "Number of articles created",
		xType = "date",
		yAxisMin = "0",
		colors = "#501f77b4,#1f77b4",
		x = table.concat(xdata, ","),
		y1 = table.concat(y1data, ","),
		y2 = table.concat(y2data, ",")
	}}

	local div = '<div style="text-align: center; margin: auto;">%s</div>'
	return string.format(div, chart)
end

return p