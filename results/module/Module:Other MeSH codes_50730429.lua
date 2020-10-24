local otherUses = require('Module:Other uses')._otheruses
local p = {}
function p.otherMeSH ()
	return otherUses(
		nil,
		{defaultPage = 'List of MeSH codes', otherText = 'categories'}
	)
end
return p