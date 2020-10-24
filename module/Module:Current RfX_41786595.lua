-- This module gets information about RfXes (requests for adminship and requests for bureaucratship)
-- that are currently open. It can return a list of page names or a list of rfx objects found using
-- [[Module:Rfx]].

local rfx = require('Module:Rfx')
local p = {}
 
local exceptions = {
	['Front matter'] = true,
	['Header'] = true,
	['bureaucratship'] = true
}
 
-- Get an array of title objects for current RfXs.
function p.titles()
	local content = mw.title.new('Wikipedia:Requests for adminship'):getContent()
	local ret = {}
	for transclusion in string.gmatch(content, '{{(.-)}}') do
		transclusion = transclusion:gsub('|.*$', '') -- Discard parameters
		local title = mw.title.new(transclusion)
		if title and
			title.namespace == 4 and ( -- Wikipedia namespace
				title.rootText == 'Requests for adminship' or
				title.rootText == 'Requests for bureaucratship'
			) and
			title.isSubpage and
			title.baseText == title.rootText and -- Is first-level subpage
			not exceptions[ title.subpageText ]
		then
			ret[#ret + 1] = title
		end
	end
	return ret
end

-- Get an array of page names for current RfXs.
function p.rfxNames()
	local titles = p.titles()
	local ret = {}
	for i, title in ipairs(titles) do
		ret[#ret + 1] = title.prefixedText
	end
	return ret
end

-- Get a table of RfA and RfB arrays containing rfx objects for current rfxes.
function p.rfx()
	local rfa, rfb = {}, {}
	local rfxNames = p.rfxNames()
	for i, rfxName in ipairs(rfxNames) do
		local rfxObj = rfx.new(rfxName)
		if rfxObj then
			local rfxType = rfxObj.type
			if rfxType == 'rfa' then
				rfa[#rfa + 1] = rfxObj
			elseif rfxType == 'rfb' then
				rfb[#rfb + 1] = rfxObj
			end
		end
	end
	return {rfa = rfa, rfb = rfb}
end

return p