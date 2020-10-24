local mSep = require('Module:Separated entries')
local getArgs = require('Module:Arguments').getArgs

local p = {}

-- Some of the characters used do not render properly on all browsers.
local svaraDesc = mw.loadData('Module:Svara/equivalents')
local svaraResolve = mw.loadData('Module:Svara/resolve')

-- Convert shorthand notation into standard notation.
function p.resolve(input, type)
	local svaras = svaraResolve[type]

	for key, value in pairs(input) do
		if svaras[value] then
			input[key] = svaras[value];
		end
	end

	return input
end

-- Called by the svaraC template
-- print(p.carnatic({'S', 'r1', 'g2', 'm1', 'P', 'd2', 'N3', "S'"}))
function p.carnatic(frame)
	-- Carnatic notation is case-insensitive. Enable the capitalise option.
	local input = p.sanitiseArgs(frame, true)
	input = p.resolve(input, "carnatic")

	return p._main(frame, input, 'carnatic')
end

-- Called by the svaraH template
-- print(p.hindustani({'S', 'r', 'G', 'm', 'P', 'd', 'N', "S'"}))
function p.hindustani(frame)
	local input = p.sanitiseArgs(frame)
	input = p.resolve(input, "hindustani")

	return p._main(frame, input, 'hindustani')
end

-- Get the equivalent note in other notation standards.
-- print(p.getEquivalents({'S', 'R₂', 'G₃', 'M₁', 'P', 'D₂', 'N₃', 'Ṡ'}, 'carnatic'))
function p.getEquivalents(frame, args, type)
	local output = ''
	local western = {}
	local alternate = {}
	local altType = ""
	local altText = ""
	local entry

	if (type == "carnatic") then
		altType = "hindustani"
		altText = "Hindustani"
	else 
		altType = "carnatic"
		altText = "Carnatic"
	end

	for key, value in pairs(args) do
		if svaraDesc[value] then
			entry = svaraDesc[value]
			alternate[key] = entry[altType];
			western[key] = entry["western"];
		end
	end

	output = frame:expandTemplate{title = 'bulleted list', args = {altText .. ": " .. p._main(frame, alternate, nil),
		"Western: " .. p._main(frame, western, "western")}}
	
	output = "Alternate notations:" .. output
	
	return output
end

-- Generates the output.
function p._main(frame, input, type)
	local foot = nil
	local abbr = true
	local svaras = {}
	
	if input['foot'] then
		foot = true
		input['foot'] = nil
	end

	if input['abbr'] then
		abbr = false
		input['abbr'] = nil
	end
	
	for key, value in pairs(input) do
		svaras[key] = value

		if (abbr) then
			if type ~= "western" and svaraDesc[value] then
				-- Use the abbr tag to add a description; avoid the default dotted
				-- underline style as it messes up the macrons.
				svaras[key] = frame:expandTemplate{title = 'abbr', args = {value, svaraDesc[value]['desc'], style="text-decoration:none;"}}
			end
		end
	end

	svaras['separator'] = "&nbsp;"
	local output = mSep.main(svaras)

	if (foot) then
		local equivalents = p.getEquivalents(frame, input, type)
		output = output .. frame:expandTemplate{title = 'efn', args = {equivalents, group='svara'}}
	end
	
	return output
end

-- Currently cleans up and returns the input.
function p.sanitiseArgs(frame, capitalise)
	local args = getArgs(frame)

	-- Capitalise arguments.
	if (capitalise) then
		for key, value in pairs(args) do
			args[key] = mw.ustring.upper(args[key]);
		end
	end

	return args
end

-- Called by the svara template.
function p.main(frame)
	local args = p.sanitiseArgs(frame)
	
	return p._main(frame, args)
end

-- Runs through the entire functionality of this module.
function p.status(frame)
	local types = {'hindustani', 'carnatic'}
	local output = ''
	
	for key, value in pairs(types) do
		local temp = "<table class='wikitable'>\n"
		local input = svaraResolve[value]
		local name = 'svara' .. mw.ustring.upper(mw.ustring.sub(value, 0, 1))
		local anno = {foot = 'yes', separator = '&nbsp;'}

		temp = temp .. '<caption>' .. name .. '</caption>\n'

		for key1, value1 in pairs(input) do
			temp = temp .. "<tr><td>" .. key1 .. "</td><td>"
				.. frame:expandTemplate{title = name, args = {key1}} -- add foot='yes' to isolate individual errors.
				.. "</td><td>" .. value1 .. "</td></tr>\n"
			anno[#anno + 1] = key1
		end
		temp = temp .. "</table>\n"
		
		output = output .. temp
			.. mSep.main(anno) .. "\n\n"
			.. frame:expandTemplate{title = name, args = anno}
	end
	
	return output
end

return p