--The purpose of this module is to take a list of linked page, and use it to determine the next and previous page in the list as well as the total number of pages.
 
local p = {}
 
function anonymize(name)
    return mw.ustring.gsub(name,"^"..mw.site.siteName,"Project") or name
end

function out(name)
    return mw.ustring.gsub(name,"^Project",mw.site.siteName) or name
end

function keyize(pagename)
     -- there was a complaint about "_" breaking things.  Do all lookups with _ in place of any space.
     -- also spaces in the index file (non-module) were causing trouble
    pagename = mw.text.trim(pagename)
    pagename = mw.ustring.gsub(pagename, " ", "_")
    pagename = mw.uri.decode(pagename)
    pagename = anonymize(pagename)
    return pagename
end

function p.main(frame,displacement,varstoreturn)
    local parent=frame.getParent(frame)
    local currentpage,indexmodule,defaultpage,noerr
    ---- args in the #invoke itself trump args in the parent frame
    currentpage = frame.args.page and mw.text.trim(frame.args.page)
    defaultpage = frame.args.defaultpage and mw.text.trim(frame.args.defaultpage)
    indexmodule = frame.args.index and mw.text.trim(frame.args.index)
    displacement = displacement or frame.args.displacement -- can be passed from the other function names at the end
    noerr=frame.args.noerr -- used as boolean
    anonymizereturn = frame.args.anonymize -- used as boolean
    ---- args in the parent frame come next
    if parent then
        currentpage=currentpage or (parent.args.page and mw.text.trim(parent.args.page))
        indexmodule=indexmodule or (parent.args.index and mw.text.trim(parent.args.index)) -- index is a module return{'page1','page2', ...}
        defaultpage=defaultpage or (parent.args.defaultpage and mw.text.trim(parent.args.defaultpage))
        noerr=noerr or parent.args.noerr
        anonymizereturn = anonymizereturn or parent.args.anonymize
        end
    ---- default values if parameters aren't provided
    defaultpage=defaultpage or "" -- don't know where to send people by default
    if not(indexmodule) then
        return "[[Module:TrainingPages]] error:no index parameter specified"
    end
    if not(currentpage) then
        local pp=mw.title.getCurrentTitle()
        if not pp then
            if noerr then
                return "","",""
            else return "[[Module:TrainingPages]] error:failed to access getCurrentTitle" -- this shouldn't happen anyway, I don't think....
            end
        end
        currentpage=pp.fullText
    end
    currentpage=anonymize(currentpage) --- convert "Wikipedia:, "Meta:" etc. into "Project:
    local index={}
    if mw.ustring.sub(indexmodule,1,6)=="Module" then
        ---- get a table of the pages in order from indexmodule
        index=mw.loadData(indexmodule)
    else pp=mw.title.new(indexmodule)
        if not pp then
            if noerr then
                return "","",""
            else return "[[Module:TrainingPages]] error (''index'' parameter): failed to access mw.title.new("..tostring(indexmodule)..") to load the index file",false,false,true
            end
        end
        local textindex=pp.getContent(pp)
        if not textindex then
            if noerr then
                return "","",""
            else return "[[Module:TrainingPages]] error (''index'' parameter):failed to access mw.title.new("..indexmodule.."):getContent() to load the index data",false,false,true
            end
        end
        prowl=mw.ustring.gmatch(textindex,"%[%[(.-)[%]|]") -- first half of any wikilink
        index={}
        repeat
            link=prowl()
            if not(link) then break end
            link = mw.text.trim(link)
            if link~="" then table.insert(index,link) end
        until false
    end
    displacement=displacement or 0 -- assume a null parameter is just display the same
    ---- set up the reverse lookup in lookup.
    ---- it would be faster to set this up in the indexmodule
    ---- but we don't want inconsistencies from user input!
    local lookup={}
    local i=0
    repeat
        i=i+1
        local j=index[i]
        if j then lookup[keyize(j)]=i else break end -- lookup["page name"] => page number
    until false
    --- get the page to return
    local returnpage,currentpagenumber
    if tonumber(currentpage) then
        currentpagenumber=tonumber(currentpage)
        returnpage=index[currentpagenumber+displacement] or defaultpage
    else if (lookup[keyize(currentpage)]) then
            currentpagenumber=lookup[keyize(currentpage)]
            returnpage=index[currentpagenumber+displacement] or defaultpage
        else returnpage=defaultpage
        end
    end
    if anonymizereturn then
        returnpage=anonymize(returnpage)
    else
        returnpage=out(returnpage)
    end
    if returnpage then returnpage = mw.text.trim(returnpage) end
    if not(varstoreturn) then return tostring(returnpage) else return tostring(returnpage),currentpagenumber,#index end
end
 
-- Return the next page in the index
-- Used like if on a page that is part of the index:
--{{#invoke:TrainingPages| next_page | index=Project:Training/For students/Editing module index }}
-- Used like this to find the next page after a specified page:
--{{#invoke:TrainingPages| next_page | index=Project:Training/For students/Editing module index | currentpage=Project:Training/For students/My sandbox }}

function p.next_page(frame)
    local returnpage,pagenumber,totalpages,errcode=p.main(frame,1,true)
    return returnpage
end
p.next = p.next_page
 
-- Same as above, but returns the previous page
function p.last_page(frame)
    local returnpage,pagenumber,totalpages,errcode=p.main(frame,-1,true)
    return returnpage
end
p.last = p.last_page
 
function p.page_number(frame)
    local returnpage,pagenumber,totalpages,errcode=p.main(frame,0,true)
    if errcode then return returnpage else return pagenumber end
end
p.page = p.page_number

function p.total_pages(frame)
    local returnpage,pagenumber,totalpages,errcode=p.main(frame,0,true)
    if errcode then return returnpage else return totalpages end
end
p.total = p.total_pages

return p