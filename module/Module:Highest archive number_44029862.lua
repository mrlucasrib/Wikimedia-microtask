-- This module finds the highest existing archive number for a set of talk
-- archive pages.

local expSearch = require('Module:Exponential search')
local p = {}

local function raiseStartNumberError(start)
	error(string.format(
		'Invalid start number "%s" supplied to [[Module:Highest archive number]] (must be an integer)',
		tostring(start)
	), 3)
end

local function pageExists(page)
	local success, exists = pcall(function()
		return mw.title.new(page).exists
	end)
	return success and exists
end

function p._main(prefix, start)
	-- Check our inputs
	if type(prefix) ~= 'string' or not prefix:find('%S') then
		error('No prefix supplied to [[Module:Highest archive number]]', 2)
	end
	if start ~= nil and (type(start) ~= "number" or math.floor(start) ~= start) then
		raiseStartNumberError(start)
	end
	start = start or 1
	
	-- Do an exponential search for the highest archive number
	local result = expSearch(function (i)
		local archiveNumber = i + start - 1
		local page = prefix .. tostring(archiveNumber)
		return pageExists(page)
	end, 10)
	
	if result == nil then
		-- We didn't find any archives for our prefix + start number
		return nil
	else
		-- We found the highest archive, but the number is always 1-based, so
		-- adjust it for our start number
		return result + start - 1
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		trim = false,
		removeBlanks = false,
		wrappers = 'Template:Highest archive number'
	})
	local prefix = args[1]
	
	-- Get the start archive number, if specified.
	local start = args.start
	if start == "" then
		start = nil
	elseif start then
		start = tonumber(start)
		if not start then
			raiseStartNumberError(args.start)
		end
	end

	return p._main(prefix, start)
end

return p