local p = {}
local plain = require("Module:Plain text")._main
function p.main(frame) 
	local page = frame.args[1]
	local pipe = frame.args[2]
	local content = mw.title.new(page):getContent()
	-- Unfortunately, the bot that this is replacing uses "prop=sections", which isn't accessible to Lua.
	-- Therefore, we have to parse the page manuallly
	local sections = content:gmatch("\n== *([^=]+) *==")
	local count = 0
	local sect
	-- copy array to table so it can be iterated in reverse
	local secttable = {}
	for sect in sections do
		secttable[#secttable + 1] = sect
	end
	local plural, declutter
	if #secttable < 3 then
		declutter = "|class="
		if #secttable == 1 then
			plural = ""
		else
			plural = "s"
		end
	else
		plural = "s"
		declutter = ""
	end
	local output = string.format("{{Dashboard grouping%s|1='''[[%s|%s]]''' (%s thread%s)'''<div style='font-size:85%%; padding-left:1.5em;'>''Most recent:''",
	declutter, page, pipe, #secttable, plural)
	local count = 0
	for i = #secttable, 1, -1 do
		sect = secttable[i]
		output = output .. string.format("\n* [[%s#%s|%s]]", page, mw.uri.anchorEncode(sect), plain(sect))
		count = count + 1
		if count == 3 then
			output = output .. "\n</div>}}\n<div style=\"padding-left:3em;\">"
		end
	end
	if count < 3 then
		output = output .. "</div>}} {{end}}"
	else
		output = output .. "</div>\n{{end}}"
	end
	return frame:preprocess(output)
end
return p