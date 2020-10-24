local p = {}

p.main = function ( frame )
	local qid = frame.args.qId or ""
	if qid == "" then qid = mw.wikibase.getEntityIdForCurrentPage() end
	if not qid then return nil end
	local prevalenceClaims = mw.wikibase.getBestStatements(qid, "P1193")
	local pRange = ''
	-- Run through all prevalence claims - the table prevalenceClaims always exists but may be empty
	for i, prevalenceClaim in ipairs( prevalenceClaims ) do
		local prevalenceValue = prevalenceClaim.mainsnak.datavalue and prevalenceClaim.mainsnak.datavalue.value
		if prevalenceValue then
			if string.len( pRange ) > 0 then
				-- Split multiple claims
				-- Maybe line break instead?
				pRange = pRange .. ', '
			end
			if prevalenceValue.lowerBound and prevalenceValue.upperBound then
				local lowerBound = prevalenceValue.lowerBound * 100
				local upperBound = prevalenceValue.upperBound * 100
				pRange = pRange .. lowerBound
				if lowerBound ~= upperBound then
					pRange = pRange .. '—' .. upperBound
				end
			else
				local amount = prevalenceValue.amount * 100
				pRange = pRange .. amount
			end
			pRange = pRange .. '%'
			if prevalenceClaim.qualifiers then
				-- Qualifiers for prevalence are currently unstandardized.
				-- Keep guessing until the right one is found.
				local quals = prevalenceClaim.qualifiers.P276 or -- location
					prevalenceClaim.qualifiers.P1001 or          -- applies to jurisdiction
					prevalenceClaim.qualifiers.P17               -- country
				if quals then
					pRange = pRange .. ' ('
					for k, qual in pairs(quals) do
						if k > 1 then
							pRange = pRange .. ', '
						end
						local qualId = qual.datavalue.value[ 'numeric-id' ]
						local link = mw.wikibase.sitelink( 'Q' .. qualId )
						local label = ({
							-- Certain geographic locales might need a
							-- manual-ish override for labels. 
							[ 132453 ] = 'developed world'
						})[ qualId ] or mw.wikibase.label( 'Q' .. qualId )
						if link then
							label = '[[' .. link .. '|' .. label .. ']]'
						end
						pRange = pRange .. label
					end
					pRange = pRange .. ')'
				end
			end
		end
		--[[ Todo: References
		if prevalenceClaim.references then
		end
		--]]
	end
	return pRange
end

return p