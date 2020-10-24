local getArgs = require('Module:Arguments').getArgs
local p = {}

function p.GetURL(frame)
	local args = getArgs(frame)
	return p._GetURL(args)
end
 
function p._GetURL(args)
	local ticker = args[1]
	local exchange = args.exchange
	local isin = args.isin
	
	if not isin then
		url = 'https://uk.finance.yahoo.com/lookup?s=' .. ticker ..'.IR'
	elseif exchange then
		url = 'https://live.euronext.com/en/product/equities/' .. isin ..'-' ..exchangeCode[exchange] .. '/quotes'
	else
		url = 'https://www.euronext.com/en/search_instruments/' .. isin
	end
	
	return url
end

-- Get codes
exchangeCode = {
	['Euronext Dublin'] = 'XMSM',
	['XMSM'] = 'XMSM',
	['Euronext Growth Dublin'] = 'XESM',
	['Growth'] = 'XESM',
	['XESM'] = 'XESM',
}

return p