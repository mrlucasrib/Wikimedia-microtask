-- Replacement for [[Template:Time ago]]
local numberSpell = require('Module:NumberSpell')._main
local yesno = require('Module:Yesno')

local p = {}

function p._main( args )
	-- Initialize variables
	local lang = mw.language.getContentLanguage()
	local auto_magnitude_num
	local min_magnitude_num
	local result
	local result_unit
	local magnitude = args.magnitude
	local min_magnitude = args.min_magnitude
	local purge = args.purge
	local spell_out = args.spellout
	local spell_out_max = args.spelloutmax
	
	-- Add a purge link if something (usually "yes") is entered into the purge parameter
	if purge then
		purge = ' <span class="plainlinks">([' .. mw.title.getCurrentTitle():fullUrl('action=purge') .. ' purge])</span>'
	else
		purge = ''
	end

	-- Check that the entered timestamp is valid. If it isn't, then give an error message.
	local noError, inputTime = pcall( lang.formatDate, lang, 'U', args[1], true )
	if not noError then
		return '<strong class="error">Error: first parameter cannot be parsed as a date or time.</strong>'
	end

	-- Store the difference between the current time and the inputted time, as well as its absolute value.
	local timeDiff = lang:formatDate( 'U', nil, true ) - inputTime
	local absTimeDiff = math.abs( timeDiff )

	-- Calculate the appropriate unit of time if it was not specified as an argument.
	local autoMagnitudeData = {
		{ unit = 'days', amn = 86400 },
		{ unit = 'hours', amn = 3600 }
	}
	result = ''
	for i, t in ipairs( autoMagnitudeData ) do
		if absTimeDiff / t.amn >= 1 then
			local result_num = math.floor( absTimeDiff / t.amn )
			if t.unit == 'hours' then
				result = result .. tostring(result_num) .. ' ' .. t.unit
			else
				result = result .. tostring(result_num) .. ' ' .. t.unit .. ', '
			absTimeDiff = absTimeDiff - (t.amn * result_num)
			end
		end
	end
	if result == '' then
			local result_num = math.floor(absTimeDiff/60)
			result = tostring(result_num) .. ' minutes'
	end
	
	return result
end

function p.main( frame )
	local args = require( 'Module:Arguments' ).getArgs( frame, {
		valueFunc = function( k, v )
			if v then
				v = v:match( '^%s*(.-)%s*$' ) -- Trim whitespace.
				if k == 'ago' or v ~= '' then
					return v
				end
			end
			return nil
		end,
		wrappers = 'Template:DRNAgo'
	})
	return p._main( args )
end

return p