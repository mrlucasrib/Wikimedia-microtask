local mOtheruses = require('Module:Other uses')
local mArguments = require('Module:Arguments')
local mHatnote = require('Module:Hatnote')
local mTableTools = require('Module:TableTools')
local p = {}

function p.otherPennsylvaniaTownships (frame)
	local title = mw.title.getCurrentTitle().text
	local options = {
		otherText = 'Pennsylvania townships with similar names',
		title = title
	}
	local pages = mArguments.getArgs(frame)
	if not pages[1] then
		local splits = {
			--paren wrappers force single values from string.gsub
			(string.gsub(title, ',.-,', ',', 1)),
			(string.gsub(title, ',.*', ''))
		}
		for k, v in pairs(splits) do
			local disambig = mHatnote.disambiguate(v) 
			if mw.title.makeTitle(0, disambig).exists then
				pages[1] = disambig
				break
			end
		end
	end
	pages = mTableTools.compressSparseArray(pages)
	return mOtheruses._otheruses(pages, options)
end

return p