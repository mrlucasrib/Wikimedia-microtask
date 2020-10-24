local p = {}
local tableTools = require("Module:TableTools")
local ymd = require("Module:YMD to ISO")._main
local lang = mw.getContentLanguage()
local function getlog(name) 
	 -- Files for discussion has no /Log/ in the title for some reason, so it is optional
	 return mw.ustring.match(name, "Log/(.*)") or mw.ustring.match(name, "/(.*)")
end
function sortkey(name1, name2)
	local key1 = ymd(getlog(name1))
	local key2 = ymd(getlog(name2))
	return key1 > key2
end
function p._main(frame, makeoutput)
	local t = frame.args.title or frame:getParent():getTitle()
	local content = mw.title.new(t .. "/Old unclosed discussions"):getContent()
	local m = mw.ustring.gmatch(content, "* %[%[(" .. t .. "/L?o?g?/?[^#]*)#%{%{anchorencode:([^}]*)")
	local seen = {}
	while true do
		local logpage, header = m()
		if not logpage then
			break
		end
		if seen[logpage] == nil then
			seen[logpage] = {}
		end
		seen[logpage][#seen[logpage]+1] = header
	end
	local out = ""
	for k, v in tableTools.sortedPairs(seen, sortkey) do
		out = out .. (makeoutput(k, v) or "")
	end
	return mw.text.trim(out)
end
function p.list(frame) 
	local function listoutput(k, v)  
		return "* [[" .. k .. "]] (" .. tostring(#v) .. " open) \n"
	end
	return p._main(frame, listoutput)
end
function p.onemonth(frame) 
	local month = frame.args.month
	if not month then
		error("|month= is required")
	elseif month ~= lang:formatDate("F Y",month) then
		error("Illegal month format")
	end
	local count = 0
	local function bymonthoutput(k, v)
		if lang:formatDate("F Y",ymd(getlog(k))) == month then
			count = count + #v
		end
	end
	p._main(frame, bymonthoutput)
	return count
end
function p.transclude(frame) 
	local function transoutput(k, v)
		local out = ""
		out = out .. "=== [[" .. k .. "|" .. getlog(k):sub(5) .. "]] ===\n"
		local logContent = mw.title.new(k):getContent()
		local editSections = {}
		local i = 0
		for heading in mw.ustring.gmatch("\n" .. logContent, "\n==+([^\n]-)==+\n") do 
			i = i + 1
			editSections[mw.text.trim(heading)] = i
		end
		for _, discussion in pairs(v) do
			out = out .. "==== " .. discussion .. " ====\n"
			local section = editSections[discussion]
			if section ~= nil then
				out = out .. "<span class=\"noprint plainlinks xfdOldSectionEdit\" style=\"float:right;position:relative;top:-2em;\" title=\"Edit discussion\">[<!-- -->[//en.wikipedia.org/w/index.php?title=" .. k:gsub(" ", "_") .. "&action=edit&section=" .. section .. " edit]<!-- -->]</span>"
			end
			out = out .. frame:callParserFunction("#section-h", k, discussion)
			out = out .. "\n"
		end
		return out
	end
	return p._main(frame, transoutput)
end
function p.total(frame) 
	local total = 0
	local function dototal(k, v) 
		total = total + #v
	end
	p._main(frame, dototal)
	return total
end
return p