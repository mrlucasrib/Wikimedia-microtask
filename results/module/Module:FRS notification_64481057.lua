local p = {}

function p.notification(frame)
	local args = frame:getParent().args
	local argNums = getArgNums(args, "title")
	local out = ""
	local multipleInHeader = false
	for index, num in ipairs(argNums) do
		num = tostring(num)
		
		local ending = ""
		
		local argsForOutput = {
				title = args["title" .. num],
				rfcid = args["rfcid" .. num],
		}
		
		if index == 1
		or not isOffsetItemSameHeader(args, argNums, index, -1)
		then
			-- it's the first in the header! pass firstInHeader
			argsForOutput["firstInHeader"] = true
		end
		
		-- if there's multiple of a single type and header, i.e.
		-- the next item is of the same header, don't
		-- write the type every time; it's just not needed
		if index ~= #argNums
		and isOffsetItemSameHeader(args, argNums, index, 1)
		then
			multipleInHeader = true
			
			if index == #argNums - 1
			or not isOffsetItemSameHeader(args, argNums, index, 2)
			then
				-- it's the penultimate in the header; set the ending to " and "
				ending = frame:expandTemplate{title="MediaWiki:Word-separator"} ..
					frame:expandTemplate{title="MediaWiki:And"} ..
					frame:expandTemplate{title="MediaWiki:Word-separator"}
			else
				-- it's not the last or penultimate in the header;
				-- set the ending to ", "
				ending = frame:expandTemplate{title="MediaWiki:Comma-separator"} ..
					frame:expandTemplate{title="MediaWiki:Word-separator"}
			end
		else
			argsForOutput["type"] = args["type" .. num]
			argsForOutput["header"] = args["header" .. num]
			
			if multipleInHeader then
				-- if there've been multiple in the header, queue this
				-- as the last one, so it'll include the multiple end
				-- with the header name and type
				multipleInHeader = false
				argsForOutput["multipleEnd"] = true
			end
			if index ~= #argNums then
				-- this isn't the last in the list, but it's clearly the
				-- last in the header; start the next header with an
				-- "and" to separate the headers
				ending = frame:expandTemplate{title="MediaWiki:Comma-separator"} ..
					frame:expandTemplate{title = "MediaWiki:And"} ..
					frame:expandTemplate{title="MediaWiki:Word-separator"}
			end
		end
		
		argsForOutput["multipleInHeader"] = multipleInHeader
		out = out .. frame:expandTemplate{
			title = 'FRS notification/content',
			args = argsForOutput
		} .. ending
	end
    return out
end

function getArgNums(args, prefix)
	-- Returns a table containing the numbers of the arguments that exist
	-- for the specified prefix. For example, if the prefix was 'data', and
	-- 'data1', 'data2', and 'data5' exist, it would return {1, 2, 5}.
	
	-- This function is adapted from [[Module:Infobox]], and is released under
	-- the Creative Commons Attribution-Share-Alike License 3.0.
	-- https://creativecommons.org/licenses/by-sa/3.0/
	local nums = {}
	for k, v in pairs(args) do
		local num = tostring(k):match('^' .. prefix .. '([0-9]%d*)$')
		if num then table.insert(nums, tonumber(num)) end
	end
	table.sort(nums)
	return nums
end

-- isOffsetItemSameHeader takes the args, the argument numbers gathered,
-- the current index, and a given offset, and checks whether the item at that
-- offset is from the same type and the same header.
function isOffsetItemSameHeader(args, argNums, index, offset)
	return args["type" .. argNums[index + offset]] == args["type" .. argNums[index]]
		and args["header" .. argNums[index + offset]] == args["header" .. argNums[index]]
end

return p