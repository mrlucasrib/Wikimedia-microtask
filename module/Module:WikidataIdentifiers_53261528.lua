-- Functions for use in retrieving Wikidata for use in templates that deal with identifiers
-- getIdentifierQualifier returns the value of a qualifier for an Identifier

p = {}

-- getIdentifierQualifier returns the value of a qualifier for an Identifier
-- such as 'Art UK artist ID', P1367
-- the assumption is that one value exists for the property
-- and only one qualifier exists for that value
-- Constraint violations for P1367 are at:
-- https://www.wikidata.org/wiki/Wikidata:Database_reports/Constraint_violations/P1367#Single_value
p.getIdentifierQualifier = function(frame)
	local propertyID = mw.text.trim(frame.args[1] or "")

	-- The PropertyID of the qualifier
	-- whose value is to be returned is passed in named parameter |qual=
	local qualifierID = frame.args.qual
	
	-- Can take a named parameter |qid which is the Wikidata ID for the article.
	-- This will not normally be used because it's an expensive call.
	local qid = frame.args.qid
	if qid and (#qid == 0) then qid = nil end

	local entity = mw.wikibase.getEntityObject(qid)
	local props
	if entity and entity.claims then
		props = entity.claims[propertyID]
	end
	if props then
		-- Check that the first value of the property is an external id
		if props[1].mainsnak.datatype == "external-id" then
			-- get any qualifiers of the first value of the property
			local quals = props[1].qualifiers
			if quals and quals[qualifierID] then
				-- check what the dataype of the first qualifier value is
				-- if it's quantity return the amount
				if quals[qualifierID][1].datatype == "quantity" then
					return tonumber(quals[qualifierID][1].datavalue.value.amount)
				end
				-- checks for other datatypes go here:
				
			end
		end
	end
end


return p