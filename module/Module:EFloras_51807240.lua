require('Module:No globals')

local p = {}

local data -- Load [[Module:eFloras/data]] if needed and assign to this variable.

local function getResource(floraID)
	data = data or mw.loadData("Module:eFloras/data")
	return data.resources[floraID] or data.resources[tonumber(floraID)]
end

function p.resource(frame)
	local floraID = string.match(frame.args[1], "%d+")
	if floraID == nil then
		return "<span style=\"color: red;\">Please provide a resource number (<code>flora_id</code>). See the list of supported resource numbers at [[Module:eFloras/doc]]</span>"
	else
		local familyToVolume = getResource(floraID)
		if familyToVolume == nil then
			return "<span style=\"color: red;\">The resource number (<code>flora_id</code>) <code>" .. floraID .. "</code> is not recognized. See the list of supported resource numbers at [[Module:eFloras/doc]]</span>[[Category:Pages using eFloras template with unsupported parameter values]]"
		else
			return familyToVolume
		end
	end
end

function p._volumeName(floraID, volume, family)
	floraID = tonumber(floraID)
	
	if not floraID then -- floraID is not a number.
		return
	end
	
	data = data or mw.loadData("Module:eFloras/data")
	
	if not volume then
		local familyToVolume = data.volumeTable[floraID]
		if not familyToVolume then
			return
		end
		
		volume = tonumber(familyToVolume[family])
	
		if not volume then
			return
		end
	end
	
	local floraVolumeNames = data.volumeNames and data.volumeNames[floraID]
	if floraVolumeNames and volume then
		return floraVolumeNames[volume]
	end
end

function p.volumeName(frame)
	if not (frame.args[1] and (frame.args[2] or frame.args[3] or frame.args.family)) then
		return
	end
	
	local floraID = string.match(frame.args[1], "%d+")
	local volume = tonumber(frame.args[2])
	local family = frame.args[3] or frame.args.family
	
	if not (floraID and (volume or family)) then
		return
	end
	
	return p._volumeName(floraID, volume, family)
end

function p._volumeDate(floraID, volume, family)
	floraID = tonumber(floraID)
	
	if not floraID then -- floraID is not a number.
		return
	end
	
	data = data or mw.loadData("Module:eFloras/data")
	
	if not volume then
		local familyToVolume = data.volumeTable[floraID]
		if not familyToVolume then
			return
		end
		
		volume = tonumber(familyToVolume[family])
	
		if not volume then
			return
		end
	end
	
	local floraVolumeDates = data.volumeDates and data.volumeDates[floraID]
	if floraVolumeDates then
		if volume and floraVolumeDates[volume] then
			return floraVolumeDates[volume]
		else
			return floraVolumeDates.default
		end
	end
end

function p.volumeDate(frame)
	if not (frame.args[1] and (frame.args[2] or frame.args[3] or frame.args.family)) then
		return
	end
	
	local floraID = string.match(frame.args[1], "%d+")
	local volume = tonumber(frame.args[2])
	local family = frame.args[3] or frame.args.family
	
	if not (floraID and (volume or family)) then
		return
	end
	
	return p._volumeDate(floraID, volume, family)
end

function p.volume(frame)
	local floraID = string.match(frame.args[1], "%d+")
	local family = frame.args[2] or frame.args.family
	data = data or mw.loadData("Module:eFloras/data")
	local familyToVolume = data.volumeTable[floraID] or data.volumeTable[tonumber(floraID)]
	if familyToVolume == nil then
		return ""
	else
		local volume = familyToVolume[family]
		if volume == "error" then
			return "19&ndash;21 [[Category:Pages using eFloras template with unsupported parameter values]]"
		elseif volume == nil then
			return ""
		else
			return volume
		end
	end
end

-- Italicize if name requires it.
function p.italicize(name)
	local orig = name
	name = string.gsub(name, "^%s*(.-)%s*$", "%1")
	
	local count
	name, count = string.gsub(name, "\'\'\'?", "")
	
	if count > 0 then
		-- A tracking method used on Wiktionary: [[wikt:Module:debug]].
		-- To see the results:
		-- [[Special:WhatLinksHere/Template:tracking/eFloras/italics or bolding]]
		local frame = mw.getCurrentFrame()
		pcall(frame.expandTemplate, frame, { title = 'tracking/eFloras/italics or bolding' })
		mw.log("Italics in input to the italicize function in Module:eFloras:", orig)
	end
	
	local rank
	local lowerName = name:lower()
	if name == "" or name == nil then
		return
	elseif string.find(name, "^%u%l+ae$") then
		if string.find(name, "eae$") then
			if string.find(name, "aceae$") then
				rank = "family"
			elseif string.find(name, "oideae$") then
				rank = "subfamily"
			else
				rank = "tribe"
			end
		elseif string.find(name, "inae$") then
			rank = "subtribe"
		end
	elseif string.find(lowerName, "subsp.", 1, true) then
		rank = "subspecies"
	elseif string.find(lowerName, "subg.", 1, true) then
		rank = "subgenus"
	elseif string.find(lowerName, "var.", 1, true) then
		rank = "variety"
	elseif string.find(lowerName, "sect.", 1, true) then
		rank = "section"
	elseif string.find(name, "^%a+%s[%a-]+$") or string.find(name, "^%a+%s×%s[%a-]+$") then
		rank = "species"
	elseif string.find(name, "^%u%a+$") -- No one-letter genera, probably.
			and not string.find(name, ".%u") then -- Uppercase letters can only appear at beginning of taxonomic name.
		rank = "genus"
	end
	
	if not rank then
		mw.log("Module:eFloras could not determine a taxonomic rank for the input that it received: " .. name)
		return orig
	end
	
	if rank == "genus" or rank == "subgenus" or rank == "species"
			or rank == "subspecies" or rank == "variety" or rank == "section" then
		
		name = "<i>" .. name .. "</i>"
		local hybrid = "×"
		
		if name:find(".", 1, true) then
			local abbreviations = {
				["subsp."] = true, ["ssp."] = true, ["var."] = true, ["f."] = true,
				["sect."] = true, ["subsect."] = true, ["subg."] = true,
			}
			
			local unrecognized
			name = name:gsub(
				"%s+(%S+%.)%s+",
				function (abbreviation)
					mw.log(name, abbreviation, abbreviation:lower(), abbreviations[abbreviation:lower()])
					if abbreviations[abbreviation:lower()] then
						return "</i> " .. abbreviation .. " <i>"
					else
						unrecognized = unrecognized or {}
						table.insert(unrecognized, abbreviation)
					end
				end)
			
			if unrecognized then
				mw.log(string.format("The abbreviation%s %s %s not recognized.",
					unrecognized[2] and "s" or "",
					table.concat(
						unrecognized,
						", "),
					unrecognized[2] and "are" or "is"))
				return orig
			end
		end
		
		name = name:gsub("%s+" .. hybrid .. "%s+", "</i> " .. hybrid .. " <i>")
	end -- Else do not modify name.
	
	return name
end

function p.name(frame)
	local name = frame.args[1]
	return p.italicize(name)
end 

p.get_volume = p.volume

return p