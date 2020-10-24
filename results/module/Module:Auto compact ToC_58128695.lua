local p = {}

local start = [[
__NOTOC__<!--
--><div role="navigation" id="toc" class="toc plainlinks hlist" aria-labelledby="tocheading" style="text-align:left;">
<div id="toctitle" class="toctitle" style="text-align:center;"><span id="tocheading" style="font-weight:bold;">Contents</span></div>
<div style="margin:auto;white-space:nowrap;">
]]

local close = [[</div></div>]]

local function make_TOC_item(anchor, link_text)
	link_text = link_text or anchor
	return ("* [[#%s|%s]]"):format(anchor, link_text)
end

local Array_mt = { __index = table }
local function Array()
	return setmetatable({}, Array_mt)
end

function p.make_TOC(frame)
	local content = mw.title.getCurrentTitle():getContent()
	
	if not content then
		error "The current page has no content"
	end
	
	local letters = Array()
	-- Find uppermost headers containing a single ASCII letter.
	for letter in content:gmatch "%f[^\n]==%s*(%a)%s*==%f[^=]" do
		letter = letter:upper()
		letters:insert(make_TOC_item(letter))
	end
	
	local yesno = require "Module:Yesno"
	local rest = Array()
	local other_headers = require "Module:TableTools".listToSet{
		"See also", "References", "Notes", "Further reading", "External links",
	}
	for header in content:gmatch "%f[^\n]==%s*(..-)%s*==%f[^=]" do
		if other_headers[header] then
			rest:insert(make_TOC_item(header))
		end
	end
	
	return start .. letters:concat("\n") .. "\n\n" .. rest:concat("\n") .. close
end

return p