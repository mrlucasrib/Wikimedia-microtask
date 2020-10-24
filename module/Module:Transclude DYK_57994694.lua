local p = {}

-- Transclude randomly selected "Did you know?" entries
function p.main(frame)
	-- args = { 1,2,... = page names, paragraphs = list e.g. "1,3-5", files = list, more = text}
	local args = {} -- args[k] = frame.args[k] or frame:getParent().args[k] for all k in either (numeric or not)
	for k, v in pairs(frame:getParent().args) do args[k] = v end
	for k, v in pairs(frame.args) do args[k] = v end -- args from a Lua call have priority over parent args from template

	-- Read the input page
	local page = args[1] or error("No page name given")
	local title = mw.title.new(page) or error("Missing input page " .. page)
	local text = title:getContent() or error("No content for page " .. page)

	-- Limit to the DYK section if present
	local sectionstart = mw.ustring.find(text, "\n==''Did you know?'' articles==", 1, true)
	if sectionstart then
		local sectionend = mw.ustring.find(text, "\n==", sectionstart + 1, true) or -1
		text = mw.ustring.sub(text, sectionstart, sectionend)
	end

	-- Parse the entries
	entries = {}
	for entry in mw.ustring.gmatch(text, "\n%*[.…%s]*([^\n]+)") do
		if not mw.ustring.find(entry, "article's talk page missing blurb", 1, true) then
			table.insert(entries, entry)
		end
	end

	-- Swap some random entries into the first n positions
	local n = math.min(#entries, args.count or 10) -- the number of entries to produce
	math.randomseed(os.time())
	for i = 1, n do
		j = math.random(i, #entries)
		entries[i], entries[j] = "*... " .. entries[j], entries[i]
	end

	-- Return the first n entries
	text = table.concat(entries, "\n", 1, n)
	return frame:preprocess(text)
end

return p