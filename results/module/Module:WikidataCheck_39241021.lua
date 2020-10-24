local p = {}

function p.wikidatacheck(frame)
	local pframe = frame:getParent()
	local config = frame.args -- the arguments passed BY the template, in the wikitext of the template itself
	local args = pframe.args -- the arguments passed TO the template, in the wikitext that transcludes the template

	local property = config.property
	local value = config.value or ""
	local catbase = config.category
	local namespaces = config.namespaces
	local nocatsame = config.nocatsame or ""
	local ok = false -- one-way flag to check if we're in a good namespace
	local ns = mw.title.getCurrentTitle().namespace
	for v in mw.text.gsplit( namespaces, ",", true) do
		if tonumber(v) == ns then
			ok = true
		end
	end
	if not ok then -- not in one of the approved namespaces
		return ""
	end
	local entity = mw.wikibase.getEntityObject()
	if not entity then -- no Wikidata item
		return "[[Category:" .. catbase .. " not in Wikidata]]"
	end
	if value == "" then
		return nil -- Using Wikidata
	end
	local claims = entity.claims or {}
	local hasProp = claims[property]
	if not hasProp then -- no claim of that property
		return "[[Category:" .. catbase .. " not in Wikidata]]" -- bad. Bot needs to add the property
	end
	for i, v in ipairs(hasProp) do -- Now we try to iterate over all possible values?
		propValue = (v.mainsnak.datavalue or {}).value
		if propValue == value then
			if nocatsame == "" then
				return "[[Category:" .. catbase .. " same as Wikidata]]" -- yay!
			else
				return nil -- if nocatsame, the "same as" category is not added
			end
		end
	end
	return "[[Category:" .. catbase .. " different from Wikidata]]" -- needs human review :(
end

return p