-- This template lets you make a long list of categories in a single entry. Generally cuts the number of characters dramatically, especially if there are many cats, and makes adding more easier.
-- Syntax:
----{{#invoke: multicat| cats | [unlimited list of categories separated by pipes]}}
-- Example:
----{{#invoke: multicat | cats |1870 births|1945 deaths|writers|biographers|critics|libertarians|Georgists|thinkers|jugglers}}
--Output:
----[[category:1870 births]][[category:1945 Deaths]][[category:writers]][[category:biographers]][[category:critics]][[category:libertarians]][[category:Georgists]][[category: thinkers]][[category:jugglers]]

local p = {}
function p.cats(frame)
	local holder = ""
	for count, parms in pairs(frame.args) do 
		holder = holder .. '[[category:' .. parms .. ']]'
	end
	return holder
end
return p