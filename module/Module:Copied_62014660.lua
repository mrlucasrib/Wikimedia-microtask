local MessageBox = require('Module:Message box')


local p = {}

local function singleText(args)
	local from_oldid = args["from_oldid"] or args["from_oldid1"] or ""
	local from = args["from"] or args["from1"] or ""
	local to = args["to"] or args["to1"] or ""
	local date = args["date"] or args["date1"] or ""
	local afd = args["afd"] or args["afd1"] or ""
	local merge = args["merge"] or args["merge1"] or ""
	local text = "Text and/or other creative content from" 
	if not (from_oldid == "") then
		text = string.format("%s [%s this version] of", text, tostring(mw.uri.fullUrl(from, {oldid=from_oldid} )))
	end
	text = string.format("%s [[%s]]",text,from)
	if (merge == "yes") or not (afd == "") then
		text = string.format("%s was merged into",text)
	else 
		text = string.format("%s was copied or moved into",text) 
	end 
	if (merge == "yes") and (to == "") then
		text = string.format("%s [[%s:%s]]",text,mw.title.getCurrentTitle().nsText,mw.title.getCurrentTitle().text) --If no merge target given assume current page is the target
	else 
		text = string.format("%s [[%s]]",text,to)
	end 
	local diff = args["diff"] or args["diff1"]
	local to_diff = args["to_diff"] or args["to_diff1"]
	local to_oldid = args["to_oldid"] or args["to_oldid1"] 
	if (diff) then
		text = string.format("%s with [%s this edit]",text,diff)
	elseif (to_oldid or to_diff) then
	local to_diff2 = args["to_diff"] or args["to_diff1"] or "prev"
	local to_oldid2 = args["to_oldid"] or args["to_oldid1"] or ""
		text = string.format("%s with [%s this edit]",text,tostring(mw.uri.fullUrl(to, {diff=to_diff or "prev", oldid = to_oldid or ""} )))
	end
	if not (date == "") then
		text = string.format("%s on %s",text,date)
	end
	if not (afd == "") then
		if (mw.ustring.match(afd, "Wikipedia:", 1 )) then --If no venue is given add AfD prefix
			text = string.format("%s after being [[%s|nominated for deletion]]",text,afd)
		else
			text = string.format("%s after being [[Wikipedia:Articles for deletion/%s|nominated for deletion]]",text,afd)
		end
	end
	text = string.format("%s.",text) -- Finish first sentance 
	text = string.format("%s The former page's [%s history] now serves to [[WP:Copying within Wikipedia|provide attribution]] for that content in the latter page, and it must not be deleted so long as the latter page exists.",text,tostring(mw.uri.fullUrl(from,{action="history"}) or ""))
	return text
end

local function row(args, i)
	local text = ""
	local afd = args["afd" .. i]
	if (afd or args["merge" .. i]) then
		text = string.format("%s\n*Merged",text)
	else 
		text = string.format("%s\n*Copied",text)
	end

	local from = args["from" .. i] or ""
	text = string.format("%s [%s %s] (",text,tostring(mw.uri.fullUrl(from, {redirect = "no"} )),from)

	local from_oldid = args["from_oldid" .. i]
	if (from_oldid) then
		text = string.format("%s[%s oldid], ",text,tostring(mw.uri.fullUrl(from, {oldid = from_oldid} )))
	end
	
	local to = args["to".. i] or ""
	text = string.format("%s[%s history]) → [[%s]]",text,tostring(mw.uri.fullUrl(from, {action = "history"} )), to)
	
	local diff = args["diff" .. i]
	if (diff) then
		text = string.format("%s ([%s diff])",text,diff)
	elseif (args["to_oldid" .. i] or args["to_diff".. i]) then
		local to_diff = args["to_diff".. i] or "prev"
		local to_oldid = args["to_oldid" .. i] or ""
		text = string.format("%s ([%s diff])",text,tostring(mw.uri.fullUrl(to, {diff=to_diff, oldid = to_oldid} )))
	end
	local date = args["date" .. i]
	if (date) then
		text = string.format("%s on %s",text,date)
	end

	if (afd) then
		if (mw.ustring.match(afd, "Wikipedia:", 1 )) then --If no venue is given add AfD prefix
			text = string.format("%s after being [[%s|nominated for deletion]]",text,afd)
		else
			text = string.format("%s after being [[Wikipedia:Articles for deletion/%s|nominated for deletion]]",text,afd)
		end
	end
	if (not (args["to_oldid" .. i] or args["to_diff".. i])) then
		text = string.format("%s[[Category:Wikipedia pages using copied template without oldid]]",text)
	end
	
	return text
end

local function list(args)
	local text = ""
	local from1 = args["from1"]
	if (from1) then --Support from1 and from in case of multiple rows
		text = string.format("%s%s",text,row(args, 1))
	else
		text = string.format("%s%s",text,row(args, ""))
	end
	local i = 2
	while i > 0 do
		if (args["from" .. i]) then 
			text = string.format("%s%s",text,row(args, i))
			i = i + 1 --Check if from(i+1) exist
		else
			i = - 1 --Break if fromi doesn't exist
		end
	end
	return text
end
	
local function multiText(args)
	local pageType
	if (mw.title.getCurrentTitle():inNamespace(0)) then
		pageType = "article"
	else
		pageType = "page"
	end
	
	local historyList = list(args)
	if (args["collapse"] == 'yes') then
		local collapsedText = '<table style="width:100%%; background: transparent;" class="collapsible collapsed">\n<tr><th>Copied pages:</th></tr>\n<tr><td> %s </td></tr></table>'
		historyList = string.format(collapsedText, historyList)
	end

	local text = "Text has been copied to or from this %s; see the list below. The source pages now serve to [[WP:Copying within Wikipedia|provide attribution]] for the content in the destination pages and must not be deleted so long as the copies exist. For attribution and to access older versions of the copied text, please see the history links below. %s"
	text = string.format(text, pageType, historyList)
	return text
end

local function BannerText(args)
	--Checks if there are multiple rows
	local text
	local from2 = args["from2"]
	if (from2) then
		text = multiText(args)
	elseif (not from2) then
		text = singleText(args)
	end
	return text
end

local function renderBanner(args)
	return MessageBox.main('tmbox', {
		small = args["small"],
		image = '[[File:Splitsection.svg|50px]]',
		text = BannerText(args)
	})
end

local function categories(args)
	local to_oldid = args["to_oldid"] or args["to_diff"] or args["diff"]
	local from_oldid = args["from_oldid"]
	local text = "[[Category:Wikipedia pages using copied template]]" 
	if ((not from_oldid) or (not to_oldid)) then
		text = string.format("%s[[Category:Wikipedia pages using copied template without oldid]]",text)
	end
	return text
end

function p.main(frame)
	local getArgs = require('Module:Arguments').getArgs
	local args = getArgs(frame)
	return renderBanner(args) .. categories(args)
end

return p