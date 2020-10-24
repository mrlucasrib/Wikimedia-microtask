local p={}
local getArgs = require('Module:Arguments').getArgs
local portalBar = require('Module:Portal bar')._main

p.main = function(frame)
     -- get module arguments and process
    local args = getArgs(frame)
    local portalArgs = {}
    if args.border then portalArgs.border = args.border end
    local talkpage = args.page or ''
     -- if the talk page isn't given, try to do something with the current page
     -- presently this assumes the template is called in mainspace; ought to work in Talk: also
    if mw.text.trim(talkpage) == '' then
        talkpage = "Talk:" .. mw.title.getCurrentTitle().text
    end
     -- get the talk page content; if it isn't there, abort and return nothing
    local talkpagetitle = mw.title.new(talkpage)
    local talkpagecontent = talkpagetitle and talkpagetitle:getContent()
    if (not talkpagecontent) then return end
     -- chop off everything after the first main top level header.
     -- note this assumes all relevant Wikiproject notices appear in the top section!
    talkpagecontent = mw.ustring.gsub(talkpagecontent, "\n%s*==[^=\n]==%s*\n.*", "")
     -- strip irrelevant templates; any common talk page templates can be put here
     -- NOTE do not add templates that wrap WikiProject templates, like the banner shell, or you'll lose one portal.
     -- NOTE any template in the following array is interpreted as pattern (special character meanings for +, -, etc.)
    local stripTemplates = {'Talkheader', 'OnThisDay', 'auto archiving notice', 'User:MiszaBot', 'WikiProjectBannerShell', 'aan'}
    for i = 1, #stripTemplates do
    	talkpagecontent = mw.ustring.gsub(talkpagecontent, "{{" .. stripTemplates[i], "")
    end
     -- now expand everything in the section fully
    talkpagecontent = frame:preprocess(talkpagecontent)
     -- go through and look for portals and add them to an output string
    local nextportal = mw.ustring.gmatch(talkpagecontent, "%[%[Portal:(.-)|(.-) portal%]%]")
    local portal = nextportal()
    local portallist = {}
    while portal do
        table.insert(portallist, portal)
        portal = nextportal()
    end
     -- send the output string to Module:Portal bar
    return portalBar(portallist, portalArgs)

end

p[""] = p.main

return p