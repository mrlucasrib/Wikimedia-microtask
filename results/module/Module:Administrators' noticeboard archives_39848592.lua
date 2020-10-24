-- This module is a replacement for {{Administrators' noticeboard navbox}}
-- and {{Administrators' noticeboard navbox all}}.

local archiveList = require( 'Module:Archive list' )

-- A table of the archives to display.
local archives = {
    an = { 
        root = "Wikipedia:Administrators' noticeboard",
        prefix = "Archive"
    },
    ani = {
        root = "Wikipedia:Administrators' noticeboard",
        prefix = "IncidentArchive"
    },
    ['3rr'] = {
        root = "Wikipedia:Administrators' noticeboard",
        prefix = "3RRArchive"
    },
    ae = {
        root = "Wikipedia:Arbitration/Requests/Enforcement",
        prefix = "Archive"
    },
    csn = {
        root = "Wikipedia:Administrators' noticeboard/Community sanction",
        prefix = "Archive"
    }
}

-- Gets wikitable rows filled with archive links, using
-- [[Module:Archive list]].
local function getLinks( funcArgs )
    if type( funcArgs ) ~= 'table' then
        error( 'Invalid input to getLinks', 2 )
    end
    funcArgs.sep = '\n| '
    funcArgs.linesep = '\n|-\n| '
    return  mw.ustring.format(
        '|-\n| %s',
        archiveList.main( funcArgs )
    )
end

-- Returns a Lua table with value being a list of archive links
-- for one of the noticeboards listed in the archives table
-- at the top of the module.
local function getLinksTable( all )
    local t = {}
    for board, archive in pairs( archives ) do
        local funcArgs = archive
        if not all then
            local archiveMax = archiveList.count( funcArgs )
            if type( archiveMax ) == 'number' and archiveMax >= 0 then
                funcArgs.max = math.floor( archiveMax )
                local start = funcArgs.max -19
                if start < 1 then
                    start = 1
                end
                funcArgs.start = start
            end
        end
        t[board] = getLinks( funcArgs )
    end
    return t
end

-- Build the wikitable using mw.ustring.format.
local function buildWikitable( args )
    local t = getLinksTable( args.all )
    local frame = mw.getCurrentFrame()

    -- The following are defined here for convenience, as they recur frequently
    -- in the wikitable.
    local headerStyle = 'style="font-size: 111%; line-height: 1.25em;" colspan="10"'
    local openSpan = '<span class="plainlinks" style="font-size: smaller;">'
    local closeSpan = '</span>'
    local searchLink = "[[Template:Administrators' noticeboard navbox/Search|search]]"
    
    -- Community sanction archive links plus header. We define it here as it is optional.
    local csn = ''
    if args.csn == 'yes' then
        csn = '\n|-\n! ' 
            .. headerStyle
            .. ' | Community sanction archives '
            .. openSpan
            .. "([[Template:Administrators' noticeboard navbox/Search|search]])"
            .. closeSpan
            .. '\n'
            .. t.csn
    end
    
    -- The inputbox plus header. We define it here as it is optional.
    local inputbox = ''
    if args.search == 'yes' then
        inputbox = '\n|-\n! colspan="10" style="white-space: nowrap;" | '
            .. frame:preprocess(
[==[
<inputbox>
bgcolor=transparent
type=fulltext
prefix=Wikipedia:Administrators' noticeboard
break=no
width=32
searchbuttonlabel=Search
placeholder=Search noticeboards archives
</inputbox>]==]
            )
    end
        
    return mw.ustring.format(
[==[
<div style="float: right; clear: right; margin: 0 0 1em 1em; text-align: right">
{| class="navbox noprint" style="font-size:88%%; line-height:1.2em; margin:0; width:auto; text-align:center"
|+ Noticeboard archives
|-
! %s | [[Wikipedia:Administrators' noticeboard|Administrators']] %s([[Wikipedia:Administrators' noticeboard/Archives|archives]], %s)%s
%s
|-
! %s | [[Wikipedia:Administrators' noticeboard/Incidents|Incidents]] %s([[Wikipedia:Administrators' noticeboard/IncidentArchives|archives]], %s)%s
%s
|-
! %s | [[Wikipedia:Administrators' noticeboard/Edit warring|Edit-warring/3RR]] %s([[Wikipedia:Administrators' noticeboard/3RRArchives|archives]], %s)%s
%s
|-
! %s | [[Wikipedia:Arbitration/Requests/Enforcement|Arbitration enforcement]] %s([[Wikipedia:Arbitration/Requests/Enforcement/Archive|archives]])%s
%s%s
|-
! %s |Other links
|-
|colspan="10" class="hlist" style="text-align: center;"|
* [[Wikipedia talk:Administrators' noticeboard|Talk]]
* [[Wikipedia:Sockpuppet investigations|Sockpuppet investigations]]
* [[:Category:Administrative backlog|Backlog]]%s
|}
</div>__NOINDEX__]==],
        headerStyle, openSpan, searchLink, closeSpan,
        t.an,
        headerStyle, openSpan, searchLink, closeSpan,
        t.ani,
        headerStyle, openSpan, searchLink, closeSpan,
        t['3rr'],
        headerStyle, openSpan, closeSpan,
        t.ae, csn,
        headerStyle,
        inputbox
    )        
end

function makeWrapper( all )
    return function( frame )
        -- If we are being called from #invoke, get the args from #invoke
        -- if they exist, or else get the arguments passed to the parent
        -- frame. Otherwise, assume the arguments are being passed directly
        -- in from another module or from the debug console.
        local origArgs
        if frame == mw.getCurrentFrame() then
            origArgs = frame:getParent().args
            for k, v in pairs( frame.args ) do
                origArgs = frame.args
                break
            end
        else
            origArgs = frame
        end
 
        -- Ignore blank values for parameters.
        local args = {}
        for k, v in pairs( origArgs ) do
            if v ~= '' then
                args[k] = v
            end
        end
        
        -- Find whether we are getting all the links or just the
        -- last 20 links.
        args.all = all
        
        return buildWikitable( args )
    end
end
 
return {
    compact = makeWrapper(),
    all = makeWrapper( true )
}