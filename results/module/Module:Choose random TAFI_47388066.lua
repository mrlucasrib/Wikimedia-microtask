local p = {}

-- Named argument |list= used, like: {{#invoke:Choose random TAFI|choose|list=#[[item1]] #[[item2]] #[[item3]]}}
function p.choose(frame)
	if mw.isSubsting() then
		math.randomseed(mw.site.stats.edits + mw.site.stats.pages + os.time() + math.floor(os.clock() * 1000000000)) 
			-- Generates a different number every time the module is called, even from the same page.
			-- This is because of the variability of os.clock (the time in seconds that the Lua script has been running for).
	
		local list = frame.args.list                       -- List of articles inputed via a single paramtere
		local articles = mw.text.split(list, '#')          -- Split list into an array of substrings (each containing an article). 
		local chosen = articles[math.random(2, #articles)] -- Note: First substring is empty as list begins with a #
		return mw.text.trim(chosen)                        -- Trim whitespace before returning
	else return "Error: Must be substituted – use {{subst:#invoke: ... }}"
	end
end

return p