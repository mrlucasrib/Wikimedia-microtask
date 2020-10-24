require "Module:Log globals"


local p = {}

local Stats = require "Module:Climate/stats"
local mean = Stats.ops.mean

local map = require "Module:fun".map

local use_alt_CD_isotherm = false
local use_alt_hk_isotherm = false
local use_alt_w_isotherm = false

local minus_sign = '−' -- U+2212 (MINUS SIGN)

local function errorf(level, ...)
	if type(level) == "number" then
		return error(string.format(...), level + 1)
	else -- level is actually the format string.
		return error(string.format(level, ...), 2)
	end
end

local function logf(...)
	mw.log(string.format(...))
end

errorf = logf

local function in_range(val, low, high)
	if low < high then -- |---i+++j---|
		return low <= val and val <= high
	else -- |+++j---i+++|
		return val < high or low < val
	end
end

local function get_aridity_threshold(mean_temp, total_precip, total_summer_precip)
	local summer_precip_fraction = total_summer_precip / total_precip
	return mean_temp * 20
		+ (summer_precip_fraction >= 0.7 and 280
		or summer_precip_fraction >= 0.3 and 140
		or 0)
end

-- in C:      cond ? a : b
-- in Python: a if cond else b
local function ternary(cond, a, b)
	if cond then
		return a
	else
		return b
	end
end

local function mean_of_highs_and_lows(highs, lows)
	local high_count, low_count = #highs, #lows
	-- for now, no annual average accepted
	if not (high_count == 12 and low_count == 12) then
		errorf("Wrong number of highs or lows (%d, %d): expected 12 each",
			high_count, low_count)
	elseif high_count ~= low_count then
		errorf("Number of highs (%d) is not equal to number of lows (%d)",
			high_count, low_count)
	end
	
	local temperatures = {}
	
	for i = 1, high_count do
		if not highs[i] then
			errorf("High #%d is missing", i)
		elseif not lows[i] then
			errorf("Low #%d is missing", i)
		elseif highs[i] <= lows[i] then
			mw.logObject({ highs = highs, lows = lows })
			errorf("High #%d (%d) is not greater than low #%d (%d)",
				i, highs[i], i, lows[i])
		end
		temperatures[i] = mean(highs[i], lows[i])
	end
	
	return temperatures
end

local function check_temperatures_and_precipitation(temperatures, precipitation, Southern_Hemisphere)
	local temperature_count = #temperatures
	if temperature_count == 2 then
		local highs_and_lows = temperatures
		temperatures = mean_of_highs_and_lows(unpack(temperatures))
	elseif temperature_count ~=  12 then
		errorf("Wrong number of temperatures (expected 12, got %d)",
			temperature_count)
	elseif #precipitation ~= 12 then
		errorf("Wrong number of precipitation stats (expected 12, got %d)",
			#precipitation)
	end
	
	temperatures = Stats(temperatures, Southern_Hemisphere)
	precipitation = Stats(precipitation, Southern_Hemisphere)
	
	return temperatures, precipitation
end

-- Temperatures and precipitation are tables of mean monthly temperature and
-- precipitation. Or temperatures can be a table containing a table of monthly
-- mean of daily highs and monthly mean of daily lows.
-- Units: °C, mm.
function p.Koeppen(temperatures, precipitation, Southern_Hemisphere, location)
	temperatures, precipitation =
		check_temperatures_and_precipitation(temperatures, precipitation, Southern_Hemisphere)
	
	-- E takes precedence over B, B over A, C, D:
	-- http://hanschen.org/koppen/
	if temperatures.max.value < 0 then
		return "EF"
	elseif temperatures.max.value < 10 then
		return "ET"
	end
		
	local aridity_threshold =
		get_aridity_threshold(temperatures.mean, precipitation.sum, precipitation.summer_sum)
	
	if precipitation.sum <= aridity_threshold then
		return "B"
			 .. (precipitation.sum > aridity_threshold / 2 and "S" or "W") -- semi-arid, arid
			 .. (ternary(use_alt_hk_isotherm, temperatures.mean >= 18,
			 	temperatures.min.value > 0)
			 	and "h" or "k")
	end
	
	local first_letter =
		temperatures.min.value >= 18 and "A"
		or temperatures.min.value >  (use_alt_CD_isotherm and -3 or 0) and "C"
		or "D"
	
	if first_letter == "A" then
		return first_letter
			.. (precipitation.min.value >= 60 and "f"
			or  precipitation.min.value / precipitation.sum > 0.04 and "m"
			or  in_range(precipitation.min.index, unpack(precipitation.summer_months))
				and "s"
			or  "w")
	else
		local second_letter =
			ternary(use_alt_w_isotherm, precipitation.sum / precipitation.summer_sum >= 0.7,
				precipitation.summer_max.value > precipitation.winter_min.value * 10)
				and "w"
			or precipitation.summer_min.value < 30
				and precipitation.winter_max.value > precipitation.summer_min.value * 3
				and "s"
			or "f"
		
		local third_letter
		if temperatures.above_10 <= 3 then
			if temperatures.min.value < -38 then
				third_letter = "d"
			else
				third_letter = "c"
			end
		elseif temperatures.max.value < 22 then
			third_letter = "b"
		else
			third_letter = "a"
		end
		
		return first_letter .. second_letter .. third_letter
	end
end

function p.Trewartha(temperatures, precipitation, Southern_Hemisphere)
	temperatures, precipitation =
		check_temperatures_and_precipitation(temperatures, precipitation, Southern_Hemisphere)
	
	if temperatures.max.value < 0 then
		return "Fi"
	elseif temperatures.max.value < 10 then
		return "Ft"
	end
	
	-- according to Wikipedia article
	local aridity_threshold =
		10 * (temperature.mean - 10) + 3 * precipitation.summer_sum / precipitation.sum
	
	if precipitation.sum < aridity_threshold then
		return "BW"
	elseif precipitation.sum < aridity_threshold * 2 then
		return "BS"
	end
	
	if temperature.min >= 18 then
		if precipitation.below_60 <= 2 then
			return "Ar"
		elseif in_range(precipitation.min.index, unpack(precipitation.winter_months)) then
			return "Aw"
		else
			return "As"
		end
	elseif temperature.above_10 >= 8 then
		return "C" -- TODO: Cf, Cs, Cw; a, b, c
	elseif temperature.above_10 >= 4 then
		if temperature.max.value > 0 then -- TODO: a, b, c?
			return "Do"
		else
			return "Dc"
		end
	else
		if temperature.min.value > -10 then
			return "Eo"
		else
			return "Ec"
		end
	end
	-- H excluded
	-- Universal Thermal Scale?
end

local function gather_numbers(str)
	str = str:gsub(minus_sign, '-') -- U+2212 (MINUS SIGN) -> U+002D (HYPHEN-MINUS)
	local arr = {}
	local i = 0
	for number in str:gmatch('%-?%d+%.?%d*') do
		i = i + 1
		arr[i] = tonumber(number)
	end
	return arr
end

local convert_functions = {
	C = {
		F = function(value) return (value - 32) * 5/9 end, -- F to C
	},
	F = {
		C = function(value) return (value * 9/5) + 32 end, -- C to F
	},
	mm = {
		inch = function(value) return value * 25.4 end, -- inch to mm
		cm = function(value) return value * 10 end, -- cm to mm
	},
}

local function convert(values, to, from)
	if to == from then
		return values
	elseif convert_functions[to] and convert_functions[to][from] then
		return map(convert_functions[to][from], values)
	end
	return errorf("Conversion from %s to %s not implemented", from or "nil", to or "nil")
end

function p.example(frame)
	local args = frame.args
	local temperatures, lows, highs, precipitation
	local yesno = require 'Module:yesno'
	
	local Southern_Hemisphere = yesno(args[3]) or false
	
	if args[1] then
		-- If args[3] can be parsed into a boolean, it is specifying the hemisphere.
		-- Otherwise, it must be a list of monthly average precipitation values, and
		-- args[1] and args[2] are monthly mean lows and highs.
		if args[3] and yesno(args[3]) == nil then -- args[3] is not boolean
			highs, lows, precipitation = args[1], args[2], args[3]
		else
			temperatures, precipitation = args[1], args[2]
		end
	else
		temperatures, lows, highs, precipitation = args.temp, args.lows, args.highs, args.precip
	end
	
	if lows and highs then
		lows, highs = gather_numbers(lows), gather_numbers(highs)
		
		if args.temp_unit then
			lows, highs = convert(lows, "C", args.temp_unit),
				convert(highs, "C", args.temp_unit)
		end
		
		temperatures = { highs, lows }
	else
		temperatures = gather_numbers(temperatures)
		
		if args.temp_unit then
			temperatures = convert(temperatures, "C", args.temp_unit)
		end
	end
	
	precipitation = gather_numbers(precipitation)
	
	if args.precip_unit then
		precipitation = convert(precipitation, "mm", args.precip_unit)
	end
	
	if yesno(args.alt_CD) then
		use_alt_CD_isotherm = true
	end
	if yesno(args.alt_hk) then
		use_alt_hk_isotherm = true
	end
	if yesno(args.alt_w) then
		use_alt_w_isotherm = true
	end
	
	local location = args.location
	local result = p.Koeppen(temperatures, precipitation, Southern_Hemisphere, location)
	-- mw.logObject{ temperatures = temperatures, precipitation = precipitation }
	
	if args.url and location then
		return ("[%s %s]: %s"):format(args.url, location, result)
	else
		return result
	end
end

local month_to_number = require "Module:TableTools".invert {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}
setmetatable(month_to_number, {
	__index = function (self, key)
		errorf("Month %s not recognized", key)
	end
})

local precipitation_units = require "Module:TableTools".listToSet {
	"inch", "cm", "mm"
}

function p.weather_box_Koeppen(frame)
	local errorf = logf
	local results = setmetatable({}, {
		__index = function (self, key)
			if key == "temperatures" or key == "precipitation" or key == "highs" or key == "lows" then
				local val = {}
				self[key] = val
				return val
			end
		end
	})

	local args = frame:getParent().args
	for k, v in pairs(args) do
		local month, stat_type, unit
		if type(k) == "string" then
			month, stat_type, unit = k:match("(%u%l%l) (%l+) (%a+)")
		end
		
		if month and month_to_number[month] and v ~= "" then
			local result
			if (stat_type == "high" or stat_type == "low" or stat_type == "mean")
					and (unit == "C" or unit == "F") then
				result = results[stat_type == "high" and "highs" or stat_type == "low" and "lows"
					or stat_type == "mean" and "temperatures"]
			elseif stat_type == "precipitation" and (unit == "mm" or unit == "cm" or unit == "inch") then
				result = results.precipitation
			end
			
			if result then
				if result.unit then
					if result.unit ~= unit then
						errorf("Unit %s conflicts with earlier unit %s", unit, result.unit)
					end
				else
					result.unit = unit
				end
				
				-- U+2212 (MINUS SIGN) -> U+002D (HYPHEN-MINUS)
				v = v:gsub(minus_sign, "-")
				result[month_to_number[month]] = tonumber(v)
					or errorf("Value of parameter '|%s=%s' cannot be parsed as a number",
						k, v)
			end
		end
	end
	
	setmetatable(results, nil)
	
	if not ((results.temperature or results.highs and results.lows)
			and results.precipitation) then
		mw.logObject(results)
		errorf("Something is missing; cannot determine climate classification.")
	end
	
	for name, result in pairs(results) do
		local length = require "Module:TableTools".length(result)
		if length == 13 then
			result[13] = nil
		elseif length ~= 12 then
			mw.logObject(results)
			errorf("Not the right number of %s stats (got %d, expected 12 or 13)",
				name, length)
		end
		
		if result.unit and (result.unit == "inch" or result.unit == "cm" or result.unit == "F") then
			results[name] = convert(result,
				(result.unit == "inch" or result.unit == "cm") and "mm" or "C",
				result.unit)
		end
	end
	
	mw.logObject(results)
	
	local Southern_Hemisphere = require "Module:Yesno" (args.south)
	
	if not results.temperature and results.lows and results.highs then
		results.temperature = { results.highs, results.lows }
		results.highs, results.lows = nil, nil -- not necessary
	end
	
	return " &ndash; [[Köppen climate classification|Köppen]] ''"
		.. p.Koeppen(results.temperature, results.precipitation, Southern_Hemisphere)
		.. "''"
end

p.Weather_box_Koeppen = p.weather_box_Koeppen

return p