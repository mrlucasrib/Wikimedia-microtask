local description = {
	[1] = {
		[1] = "This episode is a crossover with %s."
	},
	[2] = {
		[1] = "This episode begins a crossover event that concludes on %s.",
		[2] = "This episode concludes a crossover event that begins on %s."
	},
	[3] = {
		[1] = "This episode begins a crossover event that continues on %s and concludes on %s.",
		[2] = "This episode continues a crossover event that begins on %s and concludes on %s.",
		[3] = "This episode concludes a crossover event that begins on %s and continues on %s."
	},
	[4] = {
		[1] = "This episode begins a crossover event that continues on %s and %s, and concludes on %s.",
		[2] = "This episode continues a crossover event that begins on %s continues on %s, and concludes on %s.",
		[3] = "This episode continues a crossover event that begins on %s and %s, and concludes on %s.",
		[4] = "This episode concludes a crossover event that begins on %s and continues on %s and %s."
	},
	[5] = {
		[1] = "This episode begins a crossover event that continues on %s, %s, and %s, and concludes on %s.",
		[2] = "This episode continues a crossover event that begins on %s, continues on %s and %s, and concludes on %s.",
		[3] = "This episode continues a crossover event that begins on %s and %s, continues on %s, and concludes on %s.",
		[4] = "This episode continues a crossover event that begins on %s, %s, and %s, and concludes on %s.",
		[5] = "This episode concludes a crossover event that begins on %s, and continues on %s, %s, and %s."
	}
}

local errorMessages = {
	["MISSING_VALUE"] = "missing |%s= value",
	["NOT_A_NUMBER"] = "value of |%s= should be a number",
}

local errors = {}

local p = {}

--[[
Local function which is used to create an error message.
--]]
local function createErrorMsg(errorText) 
	local errorMsg = '<span style="font-size:100%;" class="error"> <strong>Error: </strong>' .. errorText .. '.</span>'
	table.insert(errors, errorMsg)
end

--[[
Local function which gets the series list from either the numbered (positional) or named parameters,
and checks if the number of series parameters match the value of parts - creates an error message if they aren't.
Returns the series list or nil.
--]]
local function getSeriesList(parts, args)
	local seriesList = {}

	parts = parts - 1
	if (parts < 1) then
		parts = 1
	end
	
	for i = 1, parts do
		if (args[i] or args["series" .. i]) then
			seriesList[i] = args[i] or args["series" .. i]
		else
			createErrorMsg(string.format(errorMessages["MISSING_VALUE"], i)) 
			return nil
		end
	end
	
	return seriesList
end

--[[
Local function which checks if the parameters used are correct.
Creates an error message if they aren't.
--]]
local function isArgValidNumber(name, value)
	if (value) then
		if (tonumber(value)) then
			return tonumber(value)
		else
			createErrorMsg(string.format(errorMessages["NOT_A_NUMBER"], name))
			return nil 
		end
	else
		createErrorMsg(string.format(errorMessages["MISSING_VALUE"], name)) 
		return nil
	end
end

--[[
Local function which is used to handle the actual main proccess.
--]]
local function _main(args)
	local parts = isArgValidNumber("parts", args.parts)
	local currentPart = isArgValidNumber("part", args.part)

	-- If missing parts or current part values, show an error.
	if (not parts or not (currentPart or parts == 1)) then
		-- Error message handling.
		return table.concat(errors)
	end

	local seriesList = getSeriesList(parts, args)

	-- If missing series parts, show an error.
	if (not seriesList) then
		-- Error message handling.
		return table.concat(errors)
	end

	if (parts == 1) then
		currentPart = 1
	end

	local text = string.format(description[parts][currentPart], seriesList[1], seriesList[2], seriesList[3], seriesList[4], seriesList[5])
	if (args.no_hr) then
		return text
	else
		return "<hr>" .. text
	end
end

--[[
Public function which is used to handle the logic for creating a note for television crossover episodes.

Parameters:
	-- |part=					— required; The crossover part number of the current episode.
	-- |parts=					— required; The number of total crossover episodes.
	-- |no_hr=					— optional; Any value will disable the addition of the <hr> tag.
	-- |1...5=					— required; The TV series which are part of the crossover, by order of crossover appearance.
	-- |series1...series5=		— optional; Optional replacement for the positional series parameters.
--]]
function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	return _main(args)
end

return p