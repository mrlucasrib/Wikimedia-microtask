-- This module is a replacement for the RfX report bot.

local rfx = require( 'Module:Rfx' )
local colours = mw.loadData( 'Module:RFX report/colour' )

local p = {}

local function getRfxes()
    -- Get the title object for [[Wikipedia:Requests for adminship]].
    local noError, rfa = pcall( mw.title.new, 'Wikipedia:Requests for adminship' )
    if not noError or ( noError and not rfa ) then
        return nil
    end
    local rfaText = rfa:getContent()
    if not rfaText then
        return nil
    end
    
    -- Return a table with a list of pages transcluded from
    -- [[Wikipedia:Requests for adminship]], minus the exceptions
    -- which are always transcluded there.
    local t = {}
    local exceptions = { 'Front matter', 'Header', 'bureaucratship' }
    for rfxPage, rfxSubpage in mw.ustring.gmatch( rfaText, '{{[ _]*([wW]ikipedia:[rR]equests for %w+/([^{}]-))[ _]*}}' ) do
        local isException = false
        for _, v in ipairs( exceptions ) do
            if rfxSubpage == v then
                isException = true
            end
        end
        if not isException then
            table.insert( t, rfxPage )
        end
    end
    return t
end

local function makeRow( rfxObject )
    if not ( type( rfxObject ) == 'table' and rfxObject.getTitleObject and rfxObject.getSupportUsers ) then
        return nil
    end
    local style = ''
    local styleInline = ''
    local status = rfxObject:getStatus()
    if status == 'pending closure' then
        style = ' style="background: #f8cdc6;" |'
        styleInline = ' background: #f8cdc6;'
    end
    local page = rfxObject:getTitleObject().prefixedText
    local user = rfxObject.user or rfxObject:getTitleObject().subpageText
    local supports = rfxObject.supports
    local opposes = rfxObject.opposes
    local neutrals = rfxObject.neutrals
    local percent = rfxObject.percent
    local colour
    if percent then
        colour = colours[ rfxObject.type ][ percent ]
    end
    colour = colour or ''
    local votes
    if supports and opposes and neutrals and percent then
        votes = mw.ustring.format( [==[
        
| style="text-align: right;%s" | [[%s#Support|%d]]
| style="text-align: right;%s" | [[%s#Oppose|%d]]
| style="text-align: right;%s" | [[%s#Neutral|%d]]
| style="text-align: right; background: #%s;" | %d]==],
            styleInline, page, supports,
            styleInline, page, opposes,
            styleInline, page, neutrals,
            colour, percent
        )
    else
        votes = '\n| colspan="4" style="background: #f8cdc6;" | Error parsing votes'
    end
    if status then
        status = mw.language.getContentLanguage():ucfirst( status )
        if status == 'Pending closure' then
            status = 'Pending closure...'
        end
        status = mw.ustring.format( '\n| %s %s', style, status )
    else
        status = '\n| style="background: #f8cdc6;" | Error getting status'
    end 
    local endTime = rfxObject.endTime
    local secondsLeft = rfxObject:getSecondsLeft()
    local timeLeft = rfxObject:getTimeLeft()
    local time
    if endTime and timeLeft then
        time = mw.ustring.format( '\n| %s %s\n| %s %s', style, endTime, style, timeLeft )
    else
        time = '\n| colspan="2" style="background: #f8cdc6;" | Error parsing end time'
    end
    local dupes = rfxObject:dupesExist()
    if dupes then
        dupes = "'''yes'''"
    elseif dupes == false then
        dupes = 'no'
    else
        dupes = '--'
    end
    local report = rfxObject:getReport()
    if report then
        report = mw.ustring.format( '\n|%s [%s report]', style, tostring( report ) )
    else
        report = '\n| style="background: #f8cdc6;" | Report not found'
    end
    return mw.ustring.format(
        '\n|-\n|%s [[%s|%s]]%s%s%s\n| style="text-align: center;%s" | %s%s',
        style, page, user, votes, status, time, styleInline, dupes, report
    )
end

local function makeHeading( rfxType )
    local rfxCaps
    if rfxType == 'rfa' then
        rfxCaps = 'RfA'
    elseif rfxType == 'rfb' then
        rfxCaps = 'RfB'
    else
        return nil
    end
    return mw.ustring.format(
        '\n|-\n! %s candidate !! S !! O !! N !! S%% !! Status !! Ending (UTC) !! Time left !! Dupes? !! Report',
        rfxCaps
    )
end

local function makeReportRows()
    local rfxes = getRfxes()
    if not rfxes then
        return nil
    end
    -- Get RfX objects and separate RfAs and RfBs.
    local rfas = {}
    local rfbs = {}
    for i, rfxPage in ipairs( rfxes ) do
        local rfxObject = rfx.new( rfxPage )
        if rfxObject then
            if rfxObject.type == 'rfa' then
                table.insert( rfas, rfxObject )
            elseif rfxObject.type == 'rfb' then
                table.insert( rfbs, rfxObject )
            end
        end
    end
    local ret = {}
    if #rfas > 0 then
        table.insert( ret, makeHeading( 'rfa' ) )
        for i, rfaObject in ipairs( rfas ) do
            table.insert( ret, makeRow( rfaObject ) )
        end
    end
    if #rfbs > 0 then
        table.insert( ret, makeHeading( 'rfb' ) )
        for i, rfbObject in ipairs( rfbs ) do
            table.insert( ret, makeRow( rfbObject ) )
        end
    end
    return table.concat( ret )
end

local function makeReport( args )
    local purgeLink = mw.title.getCurrentTitle():fullUrl( 'action=purge' )
    local header = mw.ustring.format(
        '\n|-\n! colspan="10" style="text-align: center;" | Requests for [[Wikipedia:Requests for adminship|adminship]] and [[Wikipedia:Requests for bureaucratship|bureaucratship]]<span class="plainlinks" style="float: right;"><small>[%s update]</small></span>',
        purgeLink
    )
    local rows = makeReportRows() or ''
    if rows == '' then
        rows = '\n|-\n| colspan="10" | No current discussions. <small>Recent RfAs: ([[Wikipedia:Successful requests for adminship|successful]], [[Wikipedia:Unsuccessful adminship candidacies (Chronological)|unsuccessful]]) Recent RfBs: ([[Wikipedia:Successful bureaucratship candidacies|successful]], [[Wikipedia:Unsuccessful bureaucratship candidacies|unsuccessful]])</small>'
    end
    local style = args.style
    if not style then
        local float = args.float or args.align or 'right'
        local clear = args.clear or 'left'
        style = mw.ustring.format(
            'style="white-space:wrap; clear: %s; margin-top: 0em; margin-bottom: .5em; float: %s; padding: .5em 0em 0em 1.4em; background: #ffffff; border-collapse: collapse; border-spacing: 0;"',
            clear, float
        )
    end
    return mw.ustring.format( '\n{| class="wikitable" %s%s%s\n|-\n|}', style, header, rows )
end

function p.main( frame )
    -- Process the arguments.
    local args
    if frame == mw.getCurrentFrame() then
        args = frame:getParent().args
        for k, v in pairs( frame.args ) do
            args = frame.args
            break
        end
    else
        args = frame
    end    
    return makeReport( args )
end

return p