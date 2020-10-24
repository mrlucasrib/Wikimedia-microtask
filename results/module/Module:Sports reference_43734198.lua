local function category(s)
	if mw.title.getCurrentTitle().namespace ~= 0 then
		return ""
	end
	return "[[Category:Sports-Reference template " .. s .. "]]"
end

local function linktext(s1,s2,s3)
	if (s3 == nil) or (s3 == "") then
		return "[https://timetravel.mementoweb.org/memento/20161204/https://www.sports-reference.com/olympics/athletes/" .. s1 .. ".html " .. s2 .. "] at [[Sports Reference#Olympics|Olympics at Sports-Reference.com]] (archived)" .. category("missing archive parameter")
	else
		return "[https://web.archive.org/web/" .. s3 .. "/https://www.sports-reference.com/olympics/athletes/" .. s1 .. ".html " .. s2 .. "] at [[Sports Reference#Olympics|Olympics at Sports-Reference.com]] (archived)"
	end
end

local p = {}

function p.link(frame)

	-- Optional first parameter contains ID portion of Sports-Reference URL.
	-- Trim any leading or trailing spaces. If it contains ".html", remove it.

	local id = string.gsub((mw.text.trim(frame.args[1]) or ""), ".html", "")

	-- Optional second parameter contains name for link. Trim leading or trailing spaces.
	-- If name is not provided, use article name without disambiguation.

	local name = mw.text.trim(frame.args[2])
	if (name == nil) or (name == "") then
		name = string.gsub(mw.title.getCurrentTitle().text, "%s+%b()$", "", 1)
	end

	-- Optional third parameter contains date/time portion of Archive.org URL.

	local archive = mw.text.trim(frame.args[3])

	-- For articles without Wikidata property:
	-- if ID not provided, return error text and tracking category
	-- if ID is provided, return link and tracking category

	local entity = mw.wikibase.getEntityObject() or {}
	local claims = entity.claims or {}
	local hasProp = claims["P1447"]
	if not hasProp then
		if (id == nil) or (id == "") then
			return "<span class='error'>Sports-Reference template missing ID and not present in Wikidata.</span> [[Template:Sports reference#Add ID in Wikidata|How do I fix this?]]" .. category("missing ID and not in Wikidata")
		else
			return linktext(id,name,archive) .. category("with ID not in Wikidata")
		end
	end

	-- For articles with Wikidata property:
	-- if ID not provided, return link (using Wikidata) and tracking category
	-- if ID is provided, return link (using ID) and one of two tracking categories

	local propValue = hasProp[1].mainsnak.datavalue.value
	if (id == nil) or (id == "") then
		return linktext(propValue,name,archive) .. " [[File:OOjs UI icon edit-ltr-progressive.svg |frameless |text-top |10px |alt=Edit this at Wikidata |link=https://www.wikidata.org/wiki/" .. entity.id .. "#P1447|Edit this at Wikidata]]"   -- .. category("using Wikidata")
	end
	for i, v in ipairs(hasProp) do
		propValue = (v.mainsnak.datavalue or {}).value
		if id == propValue then
			return linktext(id,name,archive)   -- .. category("with ID same as Wikidata")
		end
	end
	return linktext(id,name,archive) .. category("with ID different from Wikidata")

end

return p