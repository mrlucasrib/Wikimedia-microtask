require('Module:No globals')

local getArgs = require('Module:Arguments').getArgs
local cd = require('Module:CountryData')
local list = require('Module:List');
local p = {}

local knownargs = {
	['format'] = true,
	['class'] = true,
	['style'] = true,
	['list_style'] = true,
	['item_style'] = true,
	['item1_style'] = true,
	['indent'] = true
}

local labels = {
	['NA'] = "[[North America|NA]]",
	['EU'] = "[[Europe|EU]]",
	['EUR'] = "[[Europe|EU]]",
	['AU'] = "[[Australasia|AU]]",
	['AUS'] = "[[Australasia|AU]]",
	['PAL'] = "[[PAL region|PAL]]",
	['SEA'] = "[[Southeast Asia|SEA]]",
	['AS'] = "[[Asia|AS]]",
	['SA'] = "[[South America|SA]]",
	['OC'] = "[[Oceania|OC]]",
	['WW'] = "<abbr title=\"Worldwide\">WW</abbr>"
}

local function getLocalLabel(alias)
	local label = labels[string.upper(alias)]

	return label
end

local countryData = {}; -- Used to store country data to avoid the need of repeated calls to Module:CountryData. This saves a little time if the same abbreviation appears multiple times in the template.

local function getCountryData(frame, alias)
	local ualias = string.upper(alias)

	if (countryData[ualias] == nil) then
		local cdtable = cd.gettable(frame, alias, {})
		countryData[ualias] = cdtable['alias']
	end

	return countryData[ualias]
end

local function splitLabel(s)
	local islist = true
	local res = {}
	for k,v in ipairs(mw.text.split(s or '', '%s*/%s*')) do
		local v1 = v:match('^%s*([A-Z][A-Z][A-Z]?)%s*$')
		if v1 then
			table.insert(res,v1)
		else
			local v2 = v:match('^%s*(%[%[[^%[%]|]*|[A-Z][A-Z][A-Z]?%]%])%s*$')
			if v2 then
				table.insert(res,v2)
			else
				islist = false
			end
		end
	end
	return islist and res or {s}
end

function p.main(frame)
	local args = getArgs(frame)
	local listformat = args['format']
	if (listformat == nil or listformat == "") then
		listformat = "unbulleted"
	end
	local items = {}

	-- Old syntax "Two parameter region" use case, where param 1 is an article, param 2 is a label, and param 3 is the date. We assume this case if argument 4 is nil.
	if (args[3] ~= nil and args[4] == nil) then
		local item = "<span style=\"font-size:95%;\">[["
		if (args[1] ~= nil) then
			item = item .. args[1]
		end
		item = item .. "|"
		if (args[2] ~= nil) then
			item = item .. args[2]
		end
		item = item .. "]]:</span> " .. args[3] .. "[[Category:Pages using vgrelease with two parameter region]]"
		table.insert(items, item)
		-- Old syntax "Blank region" use case, where param 1 is empty, and param 2 is the date.
	elseif (args[1] == nil and args[2] ~= nil) then
		local item = args[2] .. "[[Category:Pages using vgrelease without a region]]"
		table.insert(items, item)
		-- Normal use cases, region/date pairs in 1/2, 3/4, 5/6, etc.
	else
		local i = 1
		local j = 2
		while (args[i] and args[j]) do
			local labels = {}
			for k,v in ipairs(splitLabel(args[i])) do
				local label = getLocalLabel(v);

				-- Didn't find a local label? Check for country data.
				if (label == nil) then
					if not v:match('^%s*%[') then
						label = getCountryData(frame, v)
					end

					-- Found something? Build a sitelink with it.
					if (label ~= nil) then
						label = "[[" .. label .. "|" .. v .. "]]"
					else
						label = v
					end
				end
				table.insert(labels, label)
			end
			local item = "<span style=\"font-size:95%;\">" .. table.concat(labels,'/') .. ":</span> " .. args[j]
			table.insert(items, item)

			i = i + 2
			j = j + 2
		end
	end

	-- Add known parameters of Module:List to the table
	for k, v in pairs(args) do
		if (knownargs[k] == true) then
			items[k] = v
		end
	end

	local out = list.makeList(listformat, items)

	-- Set message for invalid parameters.
	local parameterMsg = "[[Category:Pages using vgrelease with named parameters|_VALUE_]]"

	-- Preview message.
	if (frame:preprocess("{{REVISIONID}}") == "") then
		parameterMsg = "<div class=\"hatnote\" style=\"color:red\"><strong>Warning:</strong> unknown parameter \"_VALUE_\" (this message is shown only in preview).</div>"
	end

	-- Check for invalid parameters	
	for k, v in pairs(args) do
		if (type(k) ~= 'number' and knownargs[k] ~= true) then
			local msg = parameterMsg:gsub('_VALUE_', k)
			out = out .. msg
		end
	end

	return out
end

return p