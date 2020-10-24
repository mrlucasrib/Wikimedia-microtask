-- This module allows people to make templates that display data about current RfA and RfB discussions,
-- without them having to know how to program in Lua.

local getArgs = require('Module:Arguments').getArgs
local currentRfx = require('Module:Current RfX')

local p = {}

local function err(msg)
	return string.format('<strong class="error">Error: %s.</strong>', msg)
end

local rfxProperties = {
	supports = 'supports',
	opposes = 'opposes',
	neutrals = 'neutrals',
	percent = 'percent',
	endtime = 'endTime',
	user = 'user'
}

local rfxMethods = {
	page = function (obj)
		local title = obj:getTitleObject()
		return title.prefixedText
	end,
	dupes = function (obj)
		local dupes = obj:dupesExist()
		if dupes then
			return 'yes'
		else
			return 'no'
		end
	end,
	secondsleft = function (obj)
		return obj:getSecondsLeft()
	end,
	timeleft = function (obj)
		return obj:getTimeLeft()
	end,
	report = function (obj)
		local report = obj:getReport()
		return tostring(report)
	end,
	status = function (obj)
		return obj:getStatus()
	end
}

function p.main(frame)
	local args = getArgs(frame)
	local template = args.template
	if not template then
		return err('template not specified')
	end

	local rfxes = currentRfx.rfx()
	local rfas = rfxes.rfa
	local rfbs = rfxes.rfb
	
	local rfxTable
	if args.type == 'rfa' then
		rfxTable = rfas
	elseif args.type == 'rfb' then
		rfxTable = rfbs
	else
		return err('type parameter not specified; must be "rfa" or "rfb"')
	end

	-- Work out what properties and methods were specified in the arguments, so that
	-- we don't have to generate data from the rfx object needlessly, and so that 
	-- we don't have to check the arguments for every row.
	local propertiesToUse, methodsToUse = {}, {}
	for argName, property in pairs(rfxProperties) do
		if args[argName] then
			propertiesToUse[argName] = property
		end
	end
	for argName, func in pairs(rfxMethods) do
		if args[argName] then
			methodsToUse[argName] = func
		end
	end

	local ret = {}
	local renderRow = p.renderRow
	for _, rfxObj in ipairs(rfxTable) do
		ret[#ret + 1] = renderRow(rfxObj, propertiesToUse, methodsToUse, template, frame)
	end
	return table.concat(ret, '\n')
end

function p.renderRow(obj, propertiesToUse, methodsToUse, template, frame)
	local targs = {}
	for argName, property in pairs(propertiesToUse) do
		targs[argName] = obj[property]
	end
	for argName, func in pairs(methodsToUse) do
		targs[argName] = func(obj)
	end
	return frame:expandTemplate{title = template, args = targs}
end

return p