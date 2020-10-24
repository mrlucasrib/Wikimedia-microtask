-- This module generates a sorted plain list
-- It was created as a modification of [[Module:Sort]]
local p = {}

local lang = mw.getContentLanguage()

local function transformstring(s)
	local a = mw.text.trim(s)
	a = mw.ustring.gsub(a, '%[%[[^%[%]<>|][^%[%]<>|]*|([^%[%]<>|][^%[%]<>|]*)%]%]', '%1')
	a = mw.ustring.gsub(a, '%[%[([^%[%]<>|][^%[%]<>|]*)%]%]', '%1')
	a = mw.ustring.gsub(a, '[%s%‑]', 'AA' )
	a = mw.ustring.gsub(a, '([%D])([%d])$', '%10%2')
	return a
end

-- This function was copied/modified from [[Module:Wikidata]]
local function getValue(frame, propertyID)
	local entity = mw.wikibase.getEntityObject()
	local claims
	if entity and entity.claims then
		claims = entity.claims[propertyID]
	end
	if claims then
		-- if wiki-linked value output as link if possible
		if (claims[1] and claims[1].mainsnak.snaktype == "value" and claims[1].mainsnak.datavalue.type == "wikibase-entityid") then
			local out = {}
			for k, v in pairs(claims) do
				local sitelink = mw.wikibase.sitelink("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				local label = mw.wikibase.label("Q" .. v.mainsnak.datavalue.value["numeric-id"])
				if label == nil then label = "Q" .. v.mainsnak.datavalue.value["numeric-id"] end
				
				if sitelink then
					out[#out + 1] = "[[" .. sitelink .. "|" .. label .. "]]"
				else
					out[#out + 1] = label
				end
			end
			return out
		else
			-- just return best values
			return { entity:formatPropertyValues(propertyID).value }
		end
	else
		return {""}
	end
end

function p.asc(frame)
    local items
    if frame.args.propertyID then
    	items = getValue(frame, frame.args.propertyID)
    else
    	items = mw.text.split( frame.args[1] or '', frame.args[2] or ',', true)
    end
    if (frame.args['type'] or '') == 'number' then
    	table.sort( items, function (a, b) return ((lang:parseFormattedNumber(a) or math.huge) < (lang:parseFormattedNumber(b) or math.huge)) end )
    else
	    table.sort( items, function (a, b) return mw.text.trim(a) < mw.text.trim(b) end )
    end
    return '<div class="plainlist"><ul><li>' .. table.concat( items, "</li><li>" ) .. '</li></ul></div>'
end

function p.desc(frame)
    if frame.args.propertyID then
    	items = getValue(frame, frame.args.propertyID)
    else
    	items = mw.text.split( frame.args[1] or '', frame.args[2] or ',', true)
    end
    if (frame.args['type'] or '') == 'number' then
    	table.sort( items, function (a, b) return ((lang:parseFormattedNumber(a) or math.huge) > (lang:parseFormattedNumber(b) or math.huge)) end )
    else
    	table.sort( items, function (a, b) return mw.text.trim(a) > mw.text.trim(b) end )
    end
    return '<div class="plainlist"><ul><li>' .. table.concat( items, "</li><li>" ) .. '</li></ul></div>'
end

function p.ascd(frame)
    local items
    if frame.args.propertyID then
    	items = getValue(frame, frame.args.propertyID)
    else
    	items = mw.text.split( frame.args[1] or '', frame.args[2] or ',', true)
    end
    if (frame.args['type'] or '') == 'number' then
    	table.sort( items, function (a, b) return ((lang:parseFormattedNumber(a) or math.huge) < (lang:parseFormattedNumber(b) or math.huge)) end )
    else
	    table.sort( items, function (a, b) return ( transformstring(a) < transformstring(b) ) end)
    end
    return '<div class="plainlist"><ul><li>' .. table.concat( items, "</li><li>" ) .. '</li></ul></div>'
end

function p.descd(frame)
    local items
    if frame.args.propertyID then
    	items = getValue(frame, frame.args.propertyID)
    else
    	items = mw.text.split( frame.args[1] or '', frame.args[2] or ',', true)
    end
    if (frame.args['type'] or '') == 'number' then
    	table.sort( items, function (a, b) return ((lang:parseFormattedNumber(a) or math.huge) > (lang:parseFormattedNumber(b) or math.huge)) end )
    else
	    table.sort( items, function (a, b) return ( transformstring(a) > transformstring(b) ) end)
    end
    return '<div class="plainlist"><ul><li>' .. table.concat( items, "</li><li>" ) .. '</li></ul></div>'
end

return p