local p = {}

-- Unescape functionality grabbed from https://stackoverflow.com/a/14899740/1832568
local function unescape(str)
	str = string.gsub(str, '&#(%d+);', string.char)
	str = string.gsub(str, '&#x(%d+);', function(n) return string.char(tonumber(n, 16)) end)
	return str
end

-- Counting function accepting a string haystack and table of needles
local function count(haystack, needles)
	local number = 0
	-- While we have needles to look for
	for index, needle in ipairs(needles) do
		-- find them all in our haystack
		for m in string.gmatch(haystack, needle) do
			number = number + 1
		end
	end
	return number
end

-- Function takes any number of # delimited page names and section level numbers
function p.main(frame)
	local total = 0
	local needles = {}
	local haystack = ''
	-- Separate page names from # delimited string into table
	local pages = mw.text.split(unescape(frame.args[1]), '%s?#%s?')
	-- Separate whitespace delimited section level numbers into table
	local levels = mw.text.split(frame.args['level'], '%s*')
	-- Iterate through levels
	for level in mw.text.gsplit(table.concat(levels), '') do
		-- and add the level needle to needles
		needles[#needles + 1] = '\n'..string.rep('=', tonumber(level))..'[^=]'
	end
	-- For each page name in pages
	for index, page in ipairs(pages) do
		-- create a haystack to search from the page content
		haystack = mw.title.new(page):getContent()
		-- If we've requested the content of a legitimate page
		if haystack then
			--[[ pass the raw markup and needles to count
				 and add the return to total ]]
			total = total + count('\n' .. haystack, needles)
		end
	end
	--[[ then return how many sections of the required level
		 are in all the pages passed ]]
	return total
end

return p