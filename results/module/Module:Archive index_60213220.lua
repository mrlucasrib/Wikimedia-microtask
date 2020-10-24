--[[
Derived from https://github.com/legoktm/hbcai/blob/master/index_help.py, which is

Copyright (C) 2012 Legoktm
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
]]--
local p = {}
local plaintext = require("Module:Plain text")
local yesno = require("Module:Yesno")
local function split_into_threads(text, level3)
	local threads = {}
	local current_thread
	local header_pat 
	text = "\n" .. text
	if level3 then
		header_pat = '\n===[	]*([^=].-)[ 	]* === *\n' 
	else
		header_pat = '\n==[ 	]*([^=].-) *==[ 	]*\n' 
	end
	local last = 1
	while true do 
		local start, endindex, topic = text:find(header_pat, last)
		if current_thread then 
			current_thread.content = text:sub(last, start)
			threads[#threads + 1] = current_thread
		end
		current_thread = {topic = topic}
		if start == nil then
			-- hit end of page
			break
		end
		last = endindex + 1
	end
	if not threads and not level3 then
		return split_into_threads(text, true)
	end
	return threads
end
local function parse_archive(title, out)
	local frame = mw.getCurrentFrame()
	if title.isRedirect then
		title = title.redirectTarget
	end
	local threads = split_into_threads(title:getContent())
	local seen = {}
	for _, thread in ipairs(threads) do
		local __, reply_count = thread.content:gsub("%(UTC%)","")
		local linktopic
		local topic = thread.topic
		if seen[topic] then
			linktopic = topic .. " " .. tostring(seen[topic] + 1)
		else
			linktopic = topic
		end
		seen[topic] = (seen[topic] or 0) +1
		local link = string.format("[[%s#%s]]", title.prefixedText, frame:callParserFunction("anchorencode", {linktopic}))
		out = out .. string.format("\n|-\n| %s || %s || %s", thread.topic, tostring(reply_count), link)
	end
	return out
end	
-- End of copied code. The below code was written by me, without paying much attention to the relevant Legobot code
local function resolve_relative(mask, frame) 
	local title = frame:getParent():getTitle()
	local titleObj = mw.title.new(title)
	if titleObj.subpageText == "Archive index" then
		title = titleObj.nsText .. ":" .. titleObj.baseText
	end
	return title .. mask
end
function p._onemask(mask, frame)
	if frame == nil then
		frame = mw.getCurrentFrame()
	end
	if mask:sub(1,1) == "/" then
		mask = resolve_relative(mask, frame)
	end
	local out = ""
	if mask:find("<#>") then
		local archivecount = 0
		while true do
			archivecount = archivecount + 1
			local title = mw.title.new(mask:gsub("<#>",tostring(archivecount)))
			if not title.exists then
				return out
			end
			out = parse_archive(title, out)
		end
	else
		local title = mw.title.new(mask)
		out = parse_archive(title, out)
	end
	return out
end
function p.main(frame)
	local out = ""
	out = out .. frame:extensionTag("templatestyles","",{src="Module:Archive index/styles.css"})
	out = out .. '\n{| class="sortable"\n! Discussion Topic !! Replies (estimated) !! Archive Link'
	if frame.args.mask then
		out = out .. p._onemask(frame.args.mask, frame)
	end
	local masknum = 1
	while true do
		local maskArg = frame.args["mask" .. tostring(masknum)]
		if maskArg then
			out = out .. p._onemask(maskArg, frame)
			masknum = masknum + 1
		else
			break
		end
	end
	if yesno(frame.args.indexhere) then
		out = parse_archive(mw.title.new(resolve_relative("", frame)), out)
	end
	return out
end
return p