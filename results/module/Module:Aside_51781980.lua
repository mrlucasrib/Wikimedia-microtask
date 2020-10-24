-- This module is an experiment in an altered discussion dynamic for Wikipedia forums.
-- It presents a brief digest of the referenced discussion on a user's talk subpage.
-- The full conversation remains available via V-D-E buttons (V = view the talk subpage, 
-- D = file a comment to the user's MAIN talk page like if there's something you want him to 'admin' or to request an invite as applicable
-- E = edit the talk subpage
-- The digest should present usernames and the first words of each comment, for the past N comments
-- One intention is to allow off-topic conversations to be less obtrusive on the parent thread.
-- Another is that, potentially, some of these may be invite-only conversations in some forum where that is deemed appropriate.
-- Discussions of this type might be indexed in multiple specialized forums.
-- Part of the experiment is that if users feel *invited* to a discussion, it gives editors a chance to express mutual esteem,
-- as a counterbalance against the usual where they only really talk personally when in conflict.  Not sure this will really happen...

-- To try to keep things more accessible, I think the Lua module should only do the text processing to create the talk page extract
-- This then should get wrapped up in V-D-E boxes and cute formatting by an enveloping template.
-- There are some things I can't be perfect about - if you reply in the middle of someone's comment you'll get their beginning attributed to you.

local p = {}

function p.main(frame,header)
    local parent=frame.getParent(frame) or {}
    local currentpage,top
    ---- args in the #invoke itself trump args in the parent frame - not sure if I should even access these but leaving them for now.
    user = frame.args.user or parent.args.user -- the location for discussion with whoever admins the aside, usually user talk:(x).  "D" defaults to (user)
    page = frame.args.page or parent.args.page -- the location of the page for the aside.
    -- In the template, "V/E" links to (page), usually user talk:(x)/subpage
    -- Here page is the talk page on which these operations are done
    -- page can contain a section using the # character.  Per https://en.wikipedia.org/wiki/Wikipedia:Naming_conventions_(technical_restrictions)#Forbidden_characters
    -- there can be no # in a page name, so this imposes no restrictions.  If a section is indicated then ONLY that section should be processed.
    local basepage, section = mw.ustring.match(page, "(.-)#(.*)")
    if section then page = basepage end
    comments = frame.args.comments or parent.args.comments -- the last N comments are returned
    length = frame.args.length or parent.args.length -- return at most N characters of text per comment
    order = frame.args.order or parent.args.order or "new" -- provides an option to sort the comments various ways
    -- order = "new" (default) : latest comments shown; order = "page" (or whatever) : just show the lowest ones on the page
    if (order == "") then order = "new" end -- I don't think I need this but I'm suspicious
    -- "position" (left, right, plain) is a template parameter that can be handled in the template, so will not be used here.
    ---- args in the parent frame come next
    ---- default values if parameters aren't provided
    comments = comments or 6
    comments = tonumber(comments)
    if (comments == 0 or not(comments)) then comments = 6 end
    length = length or 80 -- In homage to TRS, but probably this will get longer
    length = tonumber(length)
    -- get a pointer to the aside
    local pagepointer=mw.title.new(page)
    if not(pagepointer) then return "''[[Module:Aside]]: The page " .. '"' .. page .. '"' .. " could not be accessed.''" end
    ---- get the text of the aside
    local text=pagepointer.getContent(pagepointer)
    assert (text,"error: failed to get text from ".. page)

    if section then
    	local textbits = mw.text.split(text, section, true) -- this is one of the few functions that takes a plain text...
    	if #textbits > 1 then
    		local i = 2
    		repeat
    		    if (mw.ustring.match(textbits[i-1], "==*%s*$")) and (mw.ustring.match(textbits[i], "^%s*==*")) then
    			    text = mw.ustring.gsub(table.concat(textbits, "", i), "%s*==*", "", 1)
    			    text = mw.ustring.gsub(text, "\n%s*==*.*", "", 1) -- this kills everything after ANY section header, even a subsection
    			    break -- use the first section that matches this section heading, I suppose - omitting this would use the last
    		    end
    		    i = i + 1
	        until (i > #textbits)
	    else
	    	return "''[[Module:Aside]]: The section " .. '"' .. section .. '"' .. " could not be found in " .. '"' .. page .. '"'
	    end
    end
    		
    -- the first set of <banner> and <banner> puts arbitrary text at the beginning.
    local output=mw.ustring.match(text, "<!%-%-+banner%-%-+>(.-)<!%-%-+/banner%-%-+>") or ""
    output = output .. "<br />"
    -- now get rid of the banner so it isn't tacked on to the first comment
    text = mw.ustring.gsub(text, "<!%-%-+banner%-%-+>(.-)<!%-%-+/banner%-%-+>%s*", "", 1)
    -- while we're at it, get rid of all the headers.  Yegods, this looks dicey.
    text = mw.ustring.gsub(text, "==+([^\n=]*)=+=%s*", "")
    -- and all the other comments... this may indicate trouble...
    text = mw.ustring.gsub(text, "<!%-%-+.-%-%-+>", "")
    
    local signaturematch = "%[%[(.-)%]%]%s*%(%[%[(.-)%]%]%)%s*(%d+):(%d+)%s*,%s*(%d+)%s*(.-)%s*(%d+)%s*%(%a%a%a%)%s*"
    local monthlookup = {["January"] = "01", ["February"] = "02", ["March"] = "03", ["April"] = "04", ["May"] = "05", ["June"] = "06", ["July"] = "07", ["August"] = "08", ["September"] = "09", ["October"] = "10", ["November"] = "11", ["December"] = "12"}
    local prowl = mw.ustring.gmatch(text,":*%s*(.-)"..signaturematch)
    local archive = {} -- dictionary that pulls comment from the time
    local keys = {} -- shove all the times in here, then sort it later, use to pull out most recent comments wherever they are on the page
    repeat
        local comment, commentuser, commenttalk, commenthour, commentminute, commentday, commentmonth, commentyear = prowl()
        if not (comment) then break end
        -- could put some verification in here - weird days, months, years etc. could disqualify comments from display.
        -- doubt it's worth bothering at the moment.
        comment = mw.ustring.gsub(comment, "$[:%s\n]*", "", 1) -- remove initial whitespace and colons from comment
        comment = mw.ustring.gsub(comment, "\n:*", "  ") -- remove all newlines from comment and :'s afterward, replace with spaces
        comment = mw.ustring.gsub(comment, "<br ?\\?>", "  ") -- remove br's also
        local commentmonthno = monthlookup[commentmonth] or "00"
        if mw.ustring.len(commentday) == 1 then commentday = "0" .. commentday end -- pad days with leading zeroes for sort
        local key = commentyear .. commentmonthno .. commentday .. commenthour .. commentminute
        commentuser = mw.ustring.match(commentuser, "(.-)|") or commentuser -- get rid of the piped summaries of the links
        commentuser = mw.ustring.match(commentuser, "User:(.*)") or commentuser -- get rid of the User: before user
        commenttalk = mw.ustring.match(commenttalk, "(.-)|") or commenttalk
        commenttalk = mw.ustring.match(commenttalk, "(.-)#") or commenttalk -- get rid of the #crap after the link
        commentdate = commentmonthno .. "/" .. commentday -- just tracking the day of comments for now, seems enough
        archive[key] = {comment, commentuser, commenttalk, commentdate} -- should check user = talk, only store one
        table.insert(keys, key)
    until false

    -- sort keys from earliest to latest; maybe the opposite would be better but I'm not feeling creative.
    if (order == "new") then table.sort(keys) end
    
    -- pick the last N keys
    local lastkey = table.maxn(keys)
    local firstkey = math.max(1, lastkey - comments + 1)
    for i = firstkey, lastkey do
    	local key = keys[i]
    	local comment, commentuser, commenttalk, commentdate = archive[key][1], archive[key][2], archive[key][3], archive[key][4]
    	local longuser = mw.ustring.len(commentuser)
    	if (longuser>12) then commentuser = mw.ustring.sub(commentuser, 1, 5) .. ".." .. mw.ustring.sub(commentuser, longuser - 4, longuser) end
        output=output.. commentdate .." [["..commenttalk.."|"..commentuser.."]]: "..(mw.ustring.sub(comment, 1, length) or "").."<br />" -- this isn't really the output I want yet
    end
    return frame.preprocess(frame,output)
end

return p