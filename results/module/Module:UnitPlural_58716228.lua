--[[
Module to create plurals for units (initially)
Might be split into code and data
--]]


--[[
Plurals by language
--]]
local plural = {
	-- English
	en = {
		-- standard suffix, and "per":
		"s",
		["per"] = "per",
		-- irregular plurals:
		["inch"] = "inches",
		["foot"] = "feet",
		["square foot"] = "square feet",
		["cubic foot"] = "cubic feet",
		["pound-force"] = "pounds-force",
		["kilogram-force"] = "kilograms-force",
		["horsepower"] = "horsepower",
		["gauss"] = "gauss",
		["solar mass"] = "solar masses",
		["hertz"] = "hertz",
		["degree Fahrenheit"] = "degrees Fahrenheit",
		["degree Celsius"] = "degrees Celsius",
		["standard gravity"] = "standard gravities",
	},
}


--[[
findLang takes a "langcode" parameter if if supplied and valid.
Otherwise it tries to create it from the user's set language ({{int:lang}})
Failing that, it uses the wiki's content language.
It returns a language object.
--]]
local function findLang(langcode)
	local langobj
	langcode = mw.text.trim(langcode or "")
	if mw.language.isKnownLanguageTag(langcode) then
		langobj = mw.language.new(langcode)
	else
		langcode = mw.getCurrentFrame():preprocess( '{{int:lang}}' )
		if mw.language.isKnownLanguageTag(langcode) then
			langobj = mw.language.new(langcode)
		else
			langobj = mw.language.getContentLanguage()
		end
	end
	return langobj
end


local p = {}


--[[
p.pl takes a unit name and an optional language code
It returns the plural of that unit in the given language, if it can.
it is exported for use in other modules.
--]]
function p.pl(unit, langcode)
	langcode = findLang(langcode).code
	unit = tostring(unit) or ""
	local ret = ""
	if plural[langcode] then
		if plural[langcode][unit] then
			-- irregular plural from lookup
			ret = plural[langcode][unit]
		else
			local per = plural[langcode].per
			local u1, u2 = unit:match("(.+) " .. per .. " (.+)")
			if u1 then
				-- recurse to give plural of bit before " per "
				ret = p.pl(u1) .. " per " .. u2
			else
				-- standard plural
				ret = unit .. plural[langcode][1]
			end
		end
	else
		-- unknown language, so return unchanged
		ret = unit
	end
	return ret
end


--[[
p.plural takes a quantity (number and unit name) and an optional language code
It returns the quantity with proper plural units in the given language, if it can.
it is exported for use in other modules.
--]]
function p.plural(quant, langcode)
	local num, unit = quant:match("([%d%.,]+)%A+(.*)")
	if tonumber(num) == 1 then
		return num .. " " .. unit
	else
		return num .. " " .. p.pl(unit, langcode)
	end
end


--[[
p.main takes a number and unit name (quantity=) and an optional language code (lang=) from the frame
It returns the quantity with proper plural units in the given language, if it can.
Example use: {{#invoke:Sandbox/RexxS/Plural|main|quantity=3 week}} returns "3 weeks"
--]]
function p.main(frame)
	local args = {}
	if frame.args.quantity then
		args = frame.args
	else
		args = frame:getParent().args
	end

	-- if nothing supplied, return nothing (or add an error message if debugging)
	if not args.quantity then return "" end

	return p.plural(args.quantity, args.lang)
end

return p