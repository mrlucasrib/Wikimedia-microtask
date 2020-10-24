local p = {}

local format = mw.ustring.format
local concat = table.concat
local insert = table.insert

local roadDataModule = require("Module:Road data")

-- TODO transition
-- begin transition code
local region_special = {
	GA = "[[Georgia (U.S. state)|Georgia]]",
	NY = "[[New York (state)|New York]]",
	WA = "[[Washington (state)|Washington]]"
}

local indep_city = {
	CA = {
		["San Francisco"] = {
			prefix = "City and County of "
		}
	},
	CO = {
		["Denver"] = {
			prefix = "City and County of "
		},
		default = {
			prefix = "City and County of ",
			linksuffix = ", Colorado"
		}
	},
	MD = {
		["Baltimore"] = {
			namesuffix = " City"
		}
	},
	PR = {
		default = {
			linksuffix = ", Puerto Rico"
		}
	}
}

local sub1Config = {
	LA = "parish",
	PR = "municipality"
}

local sub1name = {
	LA = "Parish",
	PR = ""
}

local sub1span = {
	LA = {"cspan", "pspan"},
	PR = {"cspan", "munspan"}
}

local sub2params = {
	NY = {"town"},
	WI = {"town", "township"}
}

local subConfig = {
	county = {
		group = "county"
	},
	parish = {
		group = "parish"
	},
	municipality = {
		group = "municipal"
	},
	indep_city = {
		group = "city"
	},
	town = {
		sub2area = "town",
		group = "town",
		single = true
	},
	township = {
		sub2area = "township",
		group = "township",
		single = true,
		firstnonum = true
	}
}

local pspan = {
	LA = "plspan"
}

local function sub_special(args, subTypeConfig, specialPrefix, subType)
	-- Find parameter.
	local subParam
	for _,p in ipairs(subTypeConfig) do
		if args[p .. 1] or args[p] then
			subParam = p
			break
		end
	end
	if not subParam then
		return args[specialPrefix .. "_special"]
	end
	local config = subConfig[subParam] or {}
	local subs = {}
	-- Retrieve wikilinks for subdivisions.
	local num = 1
	while num == 1 or args[subParam .. num] do
		-- Save parameters.
		local saved = {}
		saved[subType]= args[subType]
		args[subType] = args[subParam .. num] or num == 1 and args[subParam]
		saved.sub1dab = args.sub1dab
		args.sub1dab = args["ctdab" .. num] or args.ctdab or num == 1 and config.firstnonum and args.county
		saved.area = args.area
		args.area = not (config.nosub1dab and args.sub1dab)
			and (config.sub2area or args["area" .. num] or num == 1 and config.firstnonum and args.area)
		local locns = roadDataModule.locations(args, "jctint", true)
		-- Restore parameters.
		args[subType] = saved[subType]
		args.sub1dab = saved.sub1dab
		args.area = saved.area
		subs[num] = locns[subType]
		num = num + 1
	end
	if #subs > 1 then
		-- Construct wikitext for multiple subs.
		local textParts = {}
		insert(textParts, subs[1])
		for i = 2, #subs do
			insert(textParts, "–")
			if i % 2 ~= 0 then
				-- Odd subs after first begin a new line.
				insert(textParts, "<br>")
			end
			insert(textParts, subs[i])
		end
		local groupSuffix = args[specialPrefix .. "_group"] or config.group
		if groupSuffix then
			insert(textParts,
				format("%s%s", #subs % 2 == 0 and "<br>" or " ", groupSuffix))
		end
		if #subs == 2 then
			insert(textParts, " line")
		elseif #subs == 3 then
			insert(textParts, " tripoint")
		elseif #subs == 4 then
			insert(textParts, " quadripoint")
		else
			insert(textParts, " [[Quadripoint#Multipoints of greater numerical complexity|multipoint]]")
		end
		return concat(textParts)
	elseif #subs == 1 and config.single then
		-- TODO transition
		-- Save parameters.
		local saved = {}
		saved[subType]= args[subType]
		args[subType] = args[subParam .. 1] or args[subParam]
		saved.sub1dab = args.sub1dab
		args.sub1dab = args.ctdab1 or args.ctdab or config.firstnonum and args.county
		saved.area = args.area
		args.area = not (config.nosub1dab and args.sub1dab)
			and (config.sub2area or args.area1 or config.firstnonum and args.area)
		local locns = roadDataModule.locations(args, "jctint")
		-- Restore parameters.
		args[subType] = saved[subType]
		args.sub1dab = saved.sub1dab
		args.area = saved.area
		return locns[subType]
	end
end
-- end transition code

local function trackedArray(arr)
	local origArr = arr
	arr = {}
	local mt = {
		__index = function(t, k)
			local result = origArr[k]
			origArr[k] = nil
			t[k] = result
			return result
		end
	}
	setmetatable(arr, mt)
	return arr
end

function p._jctint(args)
	local sub1config = sub1Config[args.state] or "county"
	-- Tracked parameters
	local msgs = {}
	if (args.township or args.township1) and args[sub1config] and not (args.ctdab or args.ctdab1) then
		insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "D"))
	elseif not (args.location3 or args.township3 or args.town3) and args.ctdab and (args.ctdab1 or args.ctdab2) then
		insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "D"))
	end
	if args.township2 and args.township then
		insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "T"))
	end
	if args.type == "mplex" then
		insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "M"))
	end
	local blanks = {"location", "altunit", "exit", "road", "notes"}
	for _,param in ipairs(blanks) do
		if args[param] == "&nbsp;" then
			insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "B"))
			break
		end
	end
	local spans = {"cspan", "lspan", "mspan", "auspan", "ospan", "espan", "namespan", "rspan", "nspan", "pspan", "xcspan", "munspan", "uspan", "kmspan"}
	for _,param in ipairs(spans) do
		if args[param] == "1" then
			insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", "S"))
			break
		end
	end
	local trackedParams = {
		R = "length_ref",
		X = "indep_city_special",
		Y = sub1config .. "_special",
		Z = "location_special"
	}
	for key,param in pairs(trackedParams) do
		if args[param] then
			insert(msgs, format("[[Category:Jctint template tracking category|%s %%page%%]]", key))
		end
	end

	-- Track used arguments
	local origArgs = args
	args = trackedArray(args)

	local lengthUnit = args.unitdef or "mile"
	-- Extra parameters
	local moduleArgs = {}
	-- Parameters to be renamed
	local paramSubst = {
		region_special = "state_special",
		regionspan = "sspan",
		sub1 = sub1config,
		sub1_note = sub1config .. "_note",
		sub1span = sub1span[args.state] or "cspan",
		sub1dab = "ctdab",
		sub2 = "location",
		sub2span = "lspan",
		unit = lengthUnit,
		unit2 = lengthUnit .. "2",
		unit_ref = {lengthUnit .. "_ref", "length_ref" --[[TODO transition]]},
		unit2_ref = {lengthUnit .. "2_ref", "length2_ref" --[[TODO transition]]},
		uspan = {"mspan", "kmspan"},
		place = {"place", "bridge", "tunnel"},
		pspan = pspan[args.state] or "pspan"
	}
	-- Redirect undefined arguments to passed arguments
	local mt = {
		__index = function(t, k)
			if paramSubst[k] then
				-- Renamed parameter
				local src = paramSubst[k]
				if type(src) == "table" then
					for _,param in ipairs(src) do
						if args[param] then return args[param] end
					end
				else
					if args[src] then return args[src] end
				end
			end
			return args[k]
		end
	}
	setmetatable(moduleArgs, mt)

	moduleArgs.country = "USA"
	-- TODO transition
	-- begin transition code
	moduleArgs.primary_topic = "no"
	moduleArgs.sub1name = sub1name[args.state] or "County"
	moduleArgs.region_special = region_special[args.state]
	moduleArgs.region = mw.loadData("Module:Jct/statename")[args.state]
	-- Independent city
	local indepCityText = sub_special(moduleArgs, {"indep_city"}, "indep_city", "sub2")
	if not indepCityText and args.indep_city then
		local indepCity = args.indep_city
		local spec = indep_city[args.state] and
			(indep_city[args.state][indepCity] or indep_city[args.state].default)
		if spec then
			local link = format("%s%s%s",
				spec.linkprefix or "", indepCity, spec.linksuffix or "")
			local name = format("%s%s%s",
				spec.nameprefix or "", indepCity, spec.namesuffix or "")
			indepCityText = format("%s[[%s|%s]]",
				spec.prefix or "", link, name)
		else
			-- Specialize independent city to the region.
			local cityLink = format('[[%s, %s|%s]]', indepCity, moduleArgs.region, indepCity)
			indepCityText = "[[Independent city (United States)|City]] of " .. cityLink
		end
		args.indep_city = nil
	end
	moduleArgs.indep_city_special = indepCityText
	moduleArgs.sub1_special = sub_special(moduleArgs, {sub1config}, sub1config, "sub1")
	local sub2Config = {}
	if args.sub2param then
		insert(sub2Config, args.sub2param)
	end
	if sub2params[args.state] then
		for _,param in ipairs(sub2params[args.state]) do
			insert(sub2Config, param)
		end
	end
	insert(sub2Config, "location")
	moduleArgs.sub2_special = sub_special(moduleArgs, sub2Config, "location", "sub2")
	-- end transition code
	moduleArgs.unitdef = args.unitdef or "mi"

	-- Crossing
	if args.xing then
		local colType
		local colAlignType
		if args.xcspan == "3" then
			colType = "unitary"
			colAlignType = "unitary_align"
		elseif args.xcspan == "2" then
			colType = "indep_city_special"
			colAlignType = "indep_city_align"
		else
			colType = "sub2_special"
			colAlignType = "sub2_align"
		end
		moduleArgs[colType] = args.xing
		moduleArgs[colAlignType] = "center"
	end

	local coreModule = require("Module:Jctint/core")
	local coreResult = coreModule._jctint(moduleArgs)

	-- Report unused arguments
	local unusedArgs = {}
	for key,_ in pairs(origArgs) do
		insert(unusedArgs, key)
	end

	local msg
	if #msgs > 0 then
		local page = mw.title.getCurrentTitle().prefixedText -- Get transcluding page's title
		msg = mw.ustring.gsub(concat(msgs), "%%page%%", page)
	end
	return coreResult .. (msg or ""), unusedArgs
end

function p.jctint(frame)
	-- Import module function to work with passed arguments
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)

	-- Remove parameters already used in the template definition
	if args.used_params then
		for param in mw.text.gsplit(args.used_params, ",") do
			args[param] = nil
		end
		args.used_params = nil
	end

	local result, unusedArgs = p._jctint(args)

	-- Check for overridden arguments
	local frameArgs = getArgs(frame, {frameOnly = true})
	local parentArgs = getArgs(frame, {parentOnly = true})
	for key,_ in pairs(frameArgs) do
		if parentArgs[key] then insert(unusedArgs, key) end
	end

	-- Report unused arguments
	local msg
	if #unusedArgs > 0 then
		msg = format("[[Category:Jctint template tracking category|%s %%page%%]]" ..
				'<tr style="display: none;"><td>Module:Jctint/USA warning: Unused argument(s): %s</td></tr>',
				"U", concat(unusedArgs, ", "))
		local page = mw.title.getCurrentTitle().prefixedText -- Get transcluding page's title
		msg = mw.ustring.gsub(msg, "%%page%%", page)
	end
	return result .. (msg or "")
end

return p