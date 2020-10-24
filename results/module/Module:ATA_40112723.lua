-- The purpose of this module ("Articles To Avoid") is to allow people
-- who want to avoid editing specific articles to add the following in their signature:

-- {{subst:#invoke:ATA|block|User:Wnt/MyATABlacklist|allow=Some Article}}

-- The Lua script will go to the first anon parameter and import its content.
-- This is a list of articles you don't want to edit
-- (say, because you're topic banned, or you're worried Putin is out to get you), 
-- does a frame.preprocess on it to ensure (???) any transclusions are done, 
-- gets the current page you are editing, and sees if currentpage is in the list.
-- If so, it returns the link to Encyclopedia Dramatica
-- (eventually, a proposal should be made to add an error message added to the blacklist
-- that explains the program that is doing it and what you need to do to your signature to undo it).
-- Note that the signature preferences are not directly accessible to very many people, 
-- maintaining a certain sort of privacy
-- (if you elect to make a call to an existing blacklist posted by someone else, for example, or
-- if you opt out of the blacklist hoping you'll get away with it)
-- but of course, right now anyone can see what articles you've edited.
-- starting below from a straight copy of my Module:TrainingPages:
 
local p = {}
 
function anonymize(name)
    return mw.ustring.gsub(name,"^"..mw.site.siteName,"Project") or name
end
 
function p.block(frame)
    local debuglog=""
    local parent=frame.getParent(frame)
    local currentpage,indexmodule,defaultpage,noerr
    ---- args in the #invoke itself trump args in the parent frame
    currentpage = frame.args.page -- this is only useful for testing!
    debugout = frame.args.debug
    indexmodule = frame.args[1] or frame.args.index
    noerr=frame.args.noerr
    anonymizereturn = frame.args.anonymize
    whitelist = frame.args.allow
    ---- args in the parent frame come next
    if parent then
        currentpage=currentpage or parent.args.page
        indexmodule=indexmodule or parent.args[1] or parent.args.index
          -- index here is NOT generally a module, unlike TrainingPages, 
          -- because it needs to be accessible to newbies and possibly support transclusions
        noerr=noerr or parent.args.noerr
        debugout = debugout or parent.args.debug
        anonymizereturn = anonymizereturn or parent.args.anonymize
        whitelist = whitelist or parent.args.allow
        end
    ---- default values if parameters aren't provided
    whitelist = whitelist or ""
    if not(indexmodule) then
        if noerr then
            return ""
        else
            return "[[Module:ATA]] error:no index parameter specified"
        end
    end
    if not(currentpage) then
        local pp=mw.title.getCurrentTitle()
        if not pp then
            if noerr then
                return ""
            else return "[[Module:ATA]] error:failed to access getCurrentTitle" -- this shouldn't happen anyway, I don't think....
            end
        end
        currentpage=pp.fullText
    end
    -- process parameters
    whiteitem = {}
    for i in string.gmatch(whitelist, "%[%[(.-)%]%]") do
        debuglog = debuglog .. "WHITELIST" .. i
        whiteitem [mw.uri.encode(anonymize(i),"WIKI")] = true
    end
    currentpage = anonymize(currentpage) --- convert "Wikipedia:, "Meta:" etc. into "Project:
    currentpage = mw.uri.encode(currentpage,"WIKI") --- hopefully this gets the +'s and diacritics right...
    debuglog = debuglog .. currentpage
    local index={}
    if mw.ustring.sub(indexmodule,1,6)=="Module" then
        ---- get a table of the pages in order from indexmodule
        index=mw.loadData(indexmodule)
    else pp=mw.title.new(indexmodule)
        if not pp then
            if noerr then
                return ""
            else return "[[Module:ATA]] error (''index'' parameter): failed to access mw.title.new("..tostring(indexmodule)..") to load the index file"
            end
        end
        local textindex=pp.getContent(pp)
        if not textindex then
            if noerr then
                return ""
            else return "[[Module:ATA]] error (''index'' parameter):failed to access mw.title.new("..indexmodule.."):getContent() to load the index data",pp.fullText
            end
        end
        prowl=mw.ustring.gmatch(textindex,"%[%[(.-)[%]|]") -- first half of any wikilink
        index={}
        repeat
            link=prowl()
            if not(link) then break end
            link = mw.uri.encode(anonymize(link),"WIKI") 
            debuglog = debuglog .. "," .. link .. "?" .. tostring(link == currentpage) .. (tostring(whiteitem[link]) or "nope")
            if not(whiteitem[link]) and (link == currentpage) and not(debugout) then
                return "http://".."encyclopediadramatica.com/" -- blacklist token to STOP THE EDIT
            end
        until false
    end
    debuglog = "(begin debug)" .. debuglog .. "(end debug)"
    if debugout then
        return debuglog
    else
        return ""
    end
    -- successful return.  Detoxification of mainspace sigs should go here, IF it can be done.
end

return p