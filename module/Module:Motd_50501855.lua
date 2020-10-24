local p = {}

function leapyear(year)
	local rem = year - 4 * math.floor(year/4)
	local leapyear
	if (rem>0.01) then
		leapyear = 0
	else
		leapyear = 1 -- i.e. add a day to dates beyond February 28
	end
    return leapyear
end
	

function p.random(frame)
	return p.main(frame, true)
end

function p.main(frame, rnd)
	local parent=frame.getParent(frame) or {}
	local yearparameter = (parent and parent.args.year) or frame.args.year
	local ydayparameter = (parent and parent.args.day) or frame.args.day
	local yday = ydayparameter
	if yday then
		yday = tonumber(yday) -- keep nil as nil, but tonumber otherwise; may be nil *now*.
	end
	local osdate = os.date("!*t", nil)
	math.randomseed(tonumber(osdate.sec) + 60 * tonumber(osdate.min) + 3600 * tonumber(osdate.hour) + 24 * 3600 * tonumber(osdate.yday)) -- random wasn't resetting, try this
	if rnd then
		yday = yday or math.random(366)
	else 
		yday = yday or osdate.yday
	end
	yday = tonumber(yday) or 1 -- setting to number.  Just in case, setting to 1
	local year
	if rnd then
		year = yearparameter or math.random(2006, 2015)
	else
		year = yearparameter or osdate.year
	end
	local flag, mottos = pcall(mw.loadData,"Module:Motd/data/" .. tostring(year))
	while ((flag == false) and (year > 2005)) do
		year = year - 1 -- look the year before for mottos
	    flag, mottos = pcall(mw.loadData,"Module:Motd/data/" .. tostring(year))
	    if ydayparameter and mottos then
	        if not mottos [yday+leapyear(year)] then
	    		flag = false -- if a specific day is required by parameter, throw out a year without this day
	        end
    	end
	end
	local motto
	local k = 0
	repeat
		k = k + 1
		motto = mottos[yday + leapyear(year)] -- if no motto for this day, try another day
		yday = math.random(366)
	until ((motto) or (k > 100))
	return frame:preprocess(motto or "No matter where you go, there you are")
end

function p.read(frame)
    local parent=frame.getParent(frame) or {}
    local currentpage, from, to
    ---- args in the #invoke itself trump args in the parent frame
    currentpage = (parent and parent.args.page) or frame.args.page
    from = (parent and parent.args.from) or frame.args.from or 0
    to = (parent and parent.args.to) or frame.args.to or 9999
    from, to = tonumber(from), tonumber(to) -- they get passed in as strings!
    -- from and to are kludges to get part of the data when I start getting too much expanded template errors (not needed!)
    -- I'm not sure getting the current page makes sense but I had the code handy so I'll leave it.
    local pagepointer
    if not(currentpage) then
        pagepointer=mw.title.getCurrentTitle()
        assert(pagepointer,"failed to access getCurrentTitle")
        currentpage=pagepointer.fullText
    else pagepointer=mw.title.new(currentpage)
        assert(pagepointer,"failed to access mw.title.new("..tostring(currentpage)..")")
    end
    ---- get the text of the currentpage
    local text=pagepointer.getContent(pagepointer)
    assert (text,"error: failed to get text from ".. currentpage)
    local linkmatch = "%[%[(.-)%]%]"
    local prowl=mw.ustring.gmatch(text,linkmatch)
    local archive={}
    local link=prowl()
    local count = 0
    while link do
    	if (count >= from) and (count <= to) then
    	    link = mw.ustring.gmatch(link,"(.-)%|")() or link
    	    flag, contents = pcall(frame.expandTemplate, frame, {title = link, args = nil})
            -- table.insert(archive,'[==[' .. link .. ']==],</nowiki><br><nowiki>')
            -- I don't think I actually need to include the link for this use
            table.insert(archive,'[==[' .. contents .. ']==],</nowiki><br><nowiki>')
        end
        count = count + 1
        link=prowl()
    end
    
    local output=""
    for i = 1, table.maxn(archive) do
        output=output..(archive[i] or "")
    end
    output = mw.ustring.gsub(output,",</nowiki><br><nowiki>$","</nowiki><br><nowiki>")
    output = "<nowiki>return {</nowiki><br><nowiki>"..output.."}</nowiki>"
    return frame.preprocess(frame,output)
end

function p.read11(frame) -- this is a copy of p.read being customized for 2010-2011
    local parent=frame.getParent(frame) or {}
    local currentpage, from, to
    ---- args in the #invoke itself trump args in the parent frame
    currentpage = (parent and parent.args.page) or frame.args.page
    from = (parent and parent.args.from) or frame.args.from or 1
    to = (parent and parent.args.to) or frame.args.to or 9999
    from, to = tonumber(from), tonumber(to) -- they get passed in as strings!
    -- from and to are kludges to get part of the data when I start getting too much expanded template errors
    -- I'm not sure getting the current page makes sense but I had the code handy so I'll leave it.
    local pagepointer
    if not(currentpage) then
        pagepointer=mw.title.getCurrentTitle()
        assert(pagepointer,"failed to access getCurrentTitle")
        currentpage=pagepointer.fullText
    else pagepointer=mw.title.new(currentpage)
        assert(pagepointer,"failed to access mw.title.new("..tostring(currentpage)..")")
    end
    ---- get the text of the currentpage
    local text=pagepointer.getContent(pagepointer)
    assert (text,"error: failed to get text from ".. currentpage)
    local linkmatch = "(.-)%s*%*?<samp>%[%[Wikipedia:Motto of the day/(.-)%]%]%s*</samp>%s*"
    local prowl=mw.ustring.gmatch(text,linkmatch)
    local archive={}
    local contents, link = prowl()
    local count = 0
    while link do
    	if (count >= from) and (count <= to) then
    		contents = mw.ustring.gsub(contents,"%s*<br />$","")
    	    link = mw.ustring.gmatch(link,"(.-)%|")() or link
            -- table.insert(archive,'[==[' .. link .. ']==],</nowiki><br><nowiki>')
            -- I don't think I actually need to include the link for this use
            table.insert(archive,'[==[' .. contents .. ']==],</nowiki><br><nowiki>')
        end
        count = count + 1
        contents, link=prowl()
    end
    if contents then
    	table.insert(archive,'[==[' .. contents .. ']==],</nowiki><br><nowiki>')
    end
    
    local output=""
    for i = 1, table.maxn(archive) do
        output=output..(archive[i] or "")
    end
    output = mw.ustring.gsub(output,",</nowiki><br><nowiki>$","</nowiki><br><nowiki>")
    output = "<nowiki>return {</nowiki><br><nowiki>"..output.."}</nowiki>"
    return frame.preprocess(frame,output)
end

function p.read06(frame) -- this is a copy of p.read to be run once to get the 2006 data
    local parent=frame.getParent(frame) or {}
    local currentpage, from, to
    ---- args in the #invoke itself trump args in the parent frame
    currentpage = (parent and parent.args.page) or frame.args.page
    from = (parent and parent.args.from) or frame.args.from or 1
    to = (parent and parent.args.to) or frame.args.to or 9999
    from, to = tonumber(from), tonumber(to) -- they get passed in as strings!
    -- from and to are kludges to get part of the data when I start getting too much expanded template errors
    -- I'm not sure getting the current page makes sense but I had the code handy so I'll leave it.
    local pagepointer
    if not(currentpage) then
        pagepointer=mw.title.getCurrentTitle()
        assert(pagepointer,"failed to access getCurrentTitle")
        currentpage=pagepointer.fullText
    else pagepointer=mw.title.new(currentpage)
        assert(pagepointer,"failed to access mw.title.new("..tostring(currentpage)..")")
    end
    ---- get the text of the currentpage
    local text=pagepointer.getContent(pagepointer)
    assert (text,"error: failed to get text from ".. currentpage)
    local linkmatch = "(.-)%s*%*?<tt>(.-)</tt>%s*"
    local prowl=mw.ustring.gmatch(text,linkmatch)
    local archive={}
    local contents, link = prowl()
    local count = 0
    while link do
    	if (count >= from) and (count <= to) then
    		contents = mw.ustring.gsub(contents,"%s*<br />$","")
    	    link = mw.ustring.gmatch(link,"(.-)%|")() or link
            -- table.insert(archive,'[==[' .. link .. ']==],</nowiki><br><nowiki>')
            -- I don't think I actually need to include the link for this use
            table.insert(archive,'[==[' .. contents .. ']==],</nowiki><br><nowiki>')
        end
        count = count + 1
        contents, link=prowl()
    end
    if contents then
    	table.insert(archive,'[==[' .. contents .. ']==],</nowiki><br><nowiki>')
    end
    
    local output=""
    for i = 1, table.maxn(archive) do
        output=output..(archive[i] or "")
    end
    output = mw.ustring.gsub(output,",</nowiki><br><nowiki>$","</nowiki><br><nowiki>")
    output = "<nowiki>return {</nowiki><br><nowiki>"..output.."}</nowiki>"
    return frame.preprocess(frame,output)
end


return p