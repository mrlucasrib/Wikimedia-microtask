local p = {}

local function removeFalsePositives(str)
	if not str then
		return ''
	end
	str = mw.ustring.gsub(str, "<!--.--->", "")
	str = mw.ustring.gsub(str, "<nowiki>.-</nowiki>", "")
	str = mw.ustring.gsub(str, "{{[Dd]raft categories[^{}]-{{[^{}]-}}[^{}]-}}", "")
	str = mw.ustring.gsub(str, "{{[Dd]raft categories.-}}", "")
	str = mw.ustring.gsub(str,"%[%[Category:Unsuitable for Wikipedia AfC submissions%]%]","")
	str = mw.ustring.gsub(str,"%[%[Category:[Dd]rafts.-%]%]","")
	str = mw.ustring.gsub(str,"%[%[Category:.-drafts%]%]","")
	return str
end

function p.checkforcats(frame)
    local t = mw.title.getCurrentTitle()
    tc = t:getContent()
    if tc == nil then 
        return ""
    end
    tc = removeFalsePositives(tc)
    if mw.ustring.match(tc, "%[%[%s-[Cc]ategory:" ) == nil then
        return ""
    else
        return "[[Category:AfC submissions with categories]]"
    end
end

function p.submitted(frame)
	if mw.ustring.find(removeFalsePositives(mw.title.getCurrentTitle():getContent()), '{{AFC submission||', 1, true) then
		return frame.args[1]
	else
		return frame.args[2]
	end
end

return p