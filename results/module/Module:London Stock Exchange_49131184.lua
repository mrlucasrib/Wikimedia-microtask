local getArgs = require('Module:Arguments').getArgs
local p = {}

function p.GetURL(frame)
	local args = getArgs(frame)
	return p._GetURL(args)
end
 
function p._GetURL(args)
	local ticker = args[1]
	local isin = args.isin
	local fourway = args.fourway
	local otherinput = args[2]
	
	if not ticker then
		url = "https://www.londonstockexchange.com/home/homepage.htm"
		return url
	end
	
	-- Handle cases where people don't use the proper paraamter names
	if otherinput then
		-- If the isin wasn't explicitly passed check if it was the second variable
		if not isin and string.len(otherinput) == 12 then
			isin = otherinput
		-- If the four way key wasn't explicitly passed check if it was the second variable
		elseif not fourway and string.len(otherinput) > 12 then
			fourway = otherinput
		end
	end
	
	-- If you have the four way key then you know the isin 
	if fourway and not isin then
		isin = string.sub(fourway, 0, 12)
	end
	
	-- If you have the four way key you can link direclty to the security
	if fourway then
		url = 'https://www.londonstockexchange.com/exchange/prices-and-markets/stocks/summary/company-summary/' .. fourway .. ".html?lang=en"
	-- If you have the isin you can improve the search results
	elseif isin then 
		url = 'https://www.londonstockexchange.com/exchange/searchengine/search.html?lang=en&x=0&y=0&q=' .. isin
	-- Fallback to a simple ticker search
	else	
		url = 'https://www.londonstockexchange.com/exchange/searchengine/search.html?lang=en&x=0&y=0&q=' .. ticker
	end

	return url
end

return p