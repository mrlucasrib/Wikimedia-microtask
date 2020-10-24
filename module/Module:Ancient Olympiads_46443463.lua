local data = mw.loadData( 'Module:Ancient Olympiads/data' )
local lang = mw.language.getContentLanguage()
local TableTools = require('Module:TableTools')

local p = {}

function p._main( inputYear )
	-- Convert the input to an integer if possible. Return "N/A" if the input could
	-- not be converted, or if the converted input is too big or too small.
	inputYear = tonumber( inputYear )
	if not inputYear or inputYear > tonumber( lang:formatDate( 'Y' ) ) then
		return "''N/A''"
	end
	local dataLength = TableTools.length(data)

	-- Find the year in the data page and display the output.
	for i = dataLength, 1, -1 do
		local t = data[i]
		if inputYear - 1 == t.year then
			-- year of the Olympiad, test with = p._main( -495 )
			-- The input year in the calendar is one after the expected (-775 for the year 776 BC). This is why all values need to be corrected by 1. 
			-- Year of Olympiad creates autolink to same page, therefore eliminated here
			return string.format(
				'%s [[Olympiad]] ([[%s|victor]][[Winner of the Stadion race|)¹]]',
				t.numberOl, t.winner
			)
		end
        if inputYear > t.year then
			-- Years 2-4 of the Olympiad, test with = p._main( -494 )  etc.
			-- It would be nice, if the string could be as follows:
			-- '[[%s]] [[Olympiad]], [[%d BC|year %d]]',
			-- t.numberOl, inputYear * - 1 + 1, inputYear - t.year
			-- but unfortunately it links to the very same page and won't be displayed as a link but in bold.
			return string.format(
				'[[%s|%s]] [[Olympiad]], year %d',
				t.yearBC, t.numberOl, inputYear - t.year 
			)
		end
	end

	-- If input year is before 776 BC (-775), the year of the first Olympiad.
	return string.format(
		'%d before [[776 BC|1st]] [[Olympiad]]',
		inputYear * -1 - 775
	)
end

function p.main( frame )
	local args = require( 'Module:Arguments' ).getArgs( frame, {
		parentOnly = true
	} )
	return p._main( args[ 1 ] )
end

return p