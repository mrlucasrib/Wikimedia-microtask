local Multilingual = { suite  = "Multilingual",
                       serial = "2018-04-16",
                       item   = 47541920 }
local User = { sniffer = "publishchanges" }



Multilingual.exotic = { simple = true,
                        no     = true }



local favorite = function ()
    -- Postcondition:
    --     Returns code of current project language
    if not Multilingual.self then
        Multilingual.self = mw.language.getContentLanguage():getCode()
                                                            :lower()
    end
    return Multilingual.self
end -- favorite()



function feasible( ask, accept )
    -- Is ask to be supported by application?
    -- Precondition:
    --     ask     -- lowercase code
    --     accept  -- sequence table, with offered lowercase codes
    -- Postcondition:
    --     nil, or true
    local r
    for i = 1, #accept do
        if accept[ i ] == ask then
            r = true
            break -- for i
        end
    end -- for i
    return r
end -- feasible()



local fetch = function ( access, allow )
    -- Attach config or library module
    -- Precondition:
    --     access  -- module title
    --     allow   -- permit non-existence
    -- Postcondition:
    --     Returns  table or false, with library
    --     Throws error, if not available
    if type( Multilingual.ext ) ~= "table" then
        Multilingual.ext = { }
    end
    if Multilingual.ext[ access ] == false then
    elseif not Multilingual.ext[ access ] then
        local lucky, got = pcall( require, "Module:" .. access )
        if lucky then
            if type( got ) == "table" then
                Multilingual.ext[ access ] = got
                if type( got[ access ] ) == "function" then
                    Multilingual.ext[ access ] = got[ access ]()
                end
            end
        end
        if type( Multilingual.ext[ access ] ) ~= "table" then
            if allow then
                Multilingual.ext[ access ] = false
            else
                got = string.format( "Module:%s invalid", access )
                error( got, 0 )
            end
        end
    end
    return Multilingual.ext[ access ]
end -- fetch()



function find( ask, alien )
    -- Derive language code from name
    -- Precondition:
    --     ask    -- language name, downcased
    --     alien  -- language code of ask
    -- Postcondition:
    --     nil, or string
    local codes = mw.language.fetchLanguageNames( alien, "all" )
    local r
    for k, v in pairs( codes ) do
        if mw.ustring.lower( v ) == ask then
            r = k
            break -- for k, v
        end
    end -- for k, v
    if not r then
        r = Multilingual.fair( ask )
    end
    return r
end -- find()



User.favorize = function ( accept, frame )
    -- Guess user language
    -- Precondition:
    --     accept  -- sequence table, with offered ISO 639 etc. codes
    --     frame   -- frame, if available
    -- Postcondition:
    --     Returns string with best code, or nil
    if not ( User.self or User.langs ) then
        if not User.trials then
            User.tell = mw.message.new( User.sniffer )
            if User.tell:exists() then
                User.trials = { }
                if not Multilingual.frame then
                    if frame then
                        Multilingual.frame = frame
                    else
                        Multilingual.frame = mw.getCurrentFrame()
                    end
                end
                User.sin = Multilingual.frame:callParserFunction( "int",
                                                           User.sniffer )
            else
                User.langs = true
            end
        end
        if User.sin then
            local s, sin
            for i = 1, #accept do
                s = accept[ i ]
                if not User.trials[ s ] then
                    sin = User.tell:inLanguage( s ):plain()
                    if sin == User.sin then
                        User.self = s
                        break -- for i
                    else
                        User.trials[ s ] = true
                    end
                end
            end -- for i
        end
    end
    return User.self
end -- User.favorize()



Multilingual.fair = function ( ask )
    -- Format language specification according to RFC 5646 etc.
    -- Precondition:
    --     ask  -- string or table, as created by .getLang()
    -- Postcondition:
    --     Returns string, or false
    local s = type( ask )
    local q, r
    if s == "table" then
        q = ask
    elseif s == "string" then
        q = Multilingual.getLang( ask )
    end
    if q  and
       q.legal  and
       mw.language.isKnownLanguageTag( q.base ) then
        r = q.base
        if q.n > 1 then
            local order = { "extlang",
                            "script",
                            "region",
                            "other",
                            "extension" }
            for i = 1, #order do
                s = q[ order[ i ] ]
                if s then
                    r =  string.format( "%s-%s", r, s )
                end
            end -- for i
        end
    end
    return r or false
end -- Multilingual.fair()



Multilingual.fallback = function ( able, another )
    -- Is another language suitable as replacement?
    -- Precondition:
    --     able     -- language version specifier to be supported
    --     another  -- language specifier of a possible replacement
    -- Postcondition:
    --     Returns boolean
    local r
    if type( able ) == "string"  and
       type( another ) == "string" then
        if able == another then
            r = true
        else
            local s = Multilingual.getBase( able )
            if s == another then
                r = true
            else
                local others = mw.language.getFallbacksFor( s )
                r = feasible( another, others )
            end
        end
    end
    return r or false
end -- Multilingual.fallback()



Multilingual.findCode = function ( ask )
    -- Retrieve code of local (current project or English) language name
    -- Precondition:
    --     ask  -- string, with presumable language name
    --             A code itself will be identified, too.
    -- Postcondition:
    --     Returns string, or false
    local seek = mw.text.trim( ask )
    local r = false
    if #seek > 1 then
        if seek:find( "[", 1, true ) then
            seek = fetch( "WLink" ).getPlain( seek )
        end
        seek = mw.ustring.lower( seek )
        if Multilingual.isLang( seek ) then
            r = Multilingual.fair( seek )
        else
            local slang = favorite()
            r = find( seek, slang )
            if not r  and  slang ~= "en" then
                r = find( seek, "en" )
            end
        end
    end
    return r
end -- Multilingual.findCode()



Multilingual.format = function ( apply, alien, alter, active, alert,
                                 frame, assembly, adjacent, ahead )
    -- Format one or more languages
    -- Precondition:
    --     apply     -- string with language list or item
    --     alien     -- language of the answer
    --                  -- nil, false, "*": native
    --                  -- "!": current project
    --                  -- "#": code, downcased, space separated
    --                  -- "-": code, mixcase, space separated
    --                  -- any valid code
    --     alter     -- capitalize, if "c"; downcase all, if "d"
    --                  capitalize first item only, if "f"
    --                  downcase every first word only, if "m"
    --     active    -- link items, if true
    --     alert     -- string with category title in case of error
    --     frame     -- if available
    --     assembly  -- string with split pattern, if list expected
    --     adjacent  -- string with list separator, else assembly
    --     ahead     -- string to prepend first element, if any
    -- Postcondition:
    --     Returns string, or false if apply empty
    local r = false
    if apply then
        local slang
        if assembly then
            local bucket = mw.text.split( apply, assembly )
            local shift = alter
            local separator
            if adjacent then
                separator = adjacent
            elseif alien == "#"  or  alien == "-" then
                separator = " "
            else
                separator = assembly
            end
            for k, v in pairs( bucket ) do
                slang = Multilingual.format( v, alien, shift, active,
                                             alert )
                if slang then
                    if r then
                        r = string.format( "%s%s%s",
                                           r, separator, slang )
                    else
                        r = slang
                        if shift == "f" then
                            shift = "d"
                        end
                    end
                end
            end -- for k, v
            if r and ahead then
                r = ahead .. r
            end
        else
            local single = mw.text.trim( apply )
            if single == "" then
                r = false
            else
                local lapsus, slot
                slang = Multilingual.findCode( single )
                if slang then
                    if alien == "-" then
                        r = slang
                    elseif alien == "#" then
                        r = slang:lower()
                    else
                        r = Multilingual.getName( slang, alien )
                        if active then
                            local cnf = fetch( "Multilingual/config",
                                               true )
                            if cnf  and
                               type( cnf.getLink ) == "function" then
                                if not Multilingual.frame then
                                    if frame then
                                        Multilingual.frame = frame
                                    else
                                        Multilingual.frame
                                                   = mw.getCurrentFrame()
                                    end
                                end
                                slot = cnf.getLink( slang,
                                                    Multilingual.frame )
                                if slot then
                                    local wlink = fetch( "WLink" )
                                    slot = wlink.getTarget( slot )
                                else
                                    lapsus = alert
                                end
                            end
                        end
                    end
                else
                    r = single
                    if active then
                        local title = mw.title.makeTitle( 0, single )
                        if title.exists then
                            slot = single
                        end
                    end
                    lapsus = alert
                end
                if not r then
                    r = single
                elseif alter == "c" or alter == "f" then
                    r = mw.ustring.upper( mw.ustring.sub( r, 1, 1 ) )
                        .. mw.ustring.sub( r, 2 )
                elseif alter == "d" then
                    if Multilingual.isMinusculable( slang, r ) then
                        r = mw.ustring.lower( r )
                    end
                elseif alter == "m" then
                    if Multilingual.isMinusculable( slang, r ) then
                        r = mw.ustring.lower( mw.ustring.sub( r, 1, 1 ) )
                            .. mw.ustring.sub( r, 2 )
                    end
                end
                if slot then
                    if r == slot then
                        r = string.format( "[[%s]]", r )
                    else
                        r = string.format( "[[%s|%s]]", slot, r )
                    end
                end
                if lapsus and alert then
                    r = string.format( "%s[[Category:%s]]", r, alert )
                end
            end
        end
    end
    return r
end -- Multilingual.format()



Multilingual.getBase = function ( ask )
    -- Retrieve base language from possibly combined ISO language code
    -- Precondition:
    --     ask  -- language code
    -- Postcondition:
    --     Returns string, or false
    local r
    if ask then
        local slang = ask:match( "^%s*(%a%a%a?)-?%a*%s*$" )
        if slang then
            r = slang:lower()
        else
            r = false
        end
    else
        r = false
    end
    return r
end -- Multilingual.getBase()



Multilingual.getLang = function ( ask )
    -- Retrieve components of a RFC 5646 language code
    -- Precondition:
    --     ask  -- language code with subtags
    -- Postcondition:
    --     Returns table with formatted subtags
    --             .base
    --             .region
    --             .script
    --             .year
    --             .extension
    --             .other
    --             .n
    local tags = mw.text.split( ask, "-" )
    local s    = tags[ 1 ]
    local r
    if s:match( "^%a%a%a?$" ) then
        r = { base  = s:lower(),
              legal = true,
              n     = #tags }
        for i = 2, r.n do
            s = tags[ i ]
            if #s == 2 then
                if r.region  or  not s:match( "%a%a" ) then
                    r.legal = false
                else
                    r.region = s:upper()
                end
            elseif #s == 4 then
                if s:match( "%a%a%a%a" ) then
                    r.legal = ( not r.script )
                    r.script = s:sub( 1, 1 ):upper() ..
                               s:sub( 2 ):lower()
                elseif s:match( "20%d%d" )  or
                       s:match( "1%d%d%d" ) then
                    r.legal = ( not r.year )
                    r.year = s
                else
                    r.legal = false
                end
            elseif #s == 3 then
                if r.extlang  or  not s:match( "%a%a%a" ) then
                    r.legal = false
                else
                    r.extlang = s:lower()
                end
            elseif #s == 1 then
                s = s:lower()
                if s:match( "[tux]" ) then
                    r.extension = s
                    for k = i + 1, r.n do
                        s = tags[ k ]
                        if s:match( "^%w+$" ) then
                            r.extension = string.format( "%s-%s",
                                                         r.extension, s )
                        else
                            r.legal = false
                        end
                    end -- for k
                else
                    r.legal = false
                end
                break -- for i
            else
                r.legal = ( not r.other )  and
                          s:match( "%a%a%a" )
                r.other = s:lower()
            end
            if not r.legal then
                break -- for i
            end
        end -- for i
    else
        r = { legal = false }
    end
    return r
end -- Multilingual.getLang()



Multilingual.getName = function ( ask, alien )
    -- Which name is assigned to this language code?
    -- Precondition:
    --     ask    -- language code
    --     alien  -- language of the answer
    --               -- nil, false, "*": native
    --               -- "!": current project
    --               -- any valid code
    -- Postcondition:
    --     Returns string, or false
    local r
    if ask then
        local slang   = alien
        local support = "Multilingual/names"
        local tLang
        if slang then
            if slang == "*" then
                slang = Multilingual.fair( ask )
            elseif slang == "!" then
                slang = favorite()
            else
                slang = Multilingual.fair( slang )
            end
        else
            slang = Multilingual.fair( ask )
        end
        if not slang then
            slang = ask or "?????"
        end
        slang = slang:lower()
        tLang = fetch( support, true )
        if tLang then
            tLang = tLang[ slang ]
            if tLang then
                r = tLang[ ask ]
            end
        end
        if not r then
            if not Multilingual.ext.tMW then
                Multilingual.ext.tMW = { }
            end
            tLang = Multilingual.ext.tMW[ slang ]
            if tLang == nil then
                tLang = mw.language.fetchLanguageNames( slang )
                if tLang then
                    Multilingual.ext.tMW[ slang ] = tLang
                else
                    Multilingual.ext.tMW[ slang ] = false
                end
            end
            if tLang then
                r = tLang[ ask ]
            end
        end
        if not r then
            r = mw.language.fetchLanguageName( ask:lower(), slang )
            if r == "" then
                r = false
            end
        end
    else
        r = false
    end
    return r
end -- Multilingual.getName()



Multilingual.int = function ( access, alien, apply )
    -- Translated system message
    -- Precondition:
    --     access  -- message ID
    --     alien   -- language code
    --     apply   -- nil, or sequence table with parameters $1, $2, ...
    -- Postcondition:
    --     Returns string, or false
    local o = mw.message.new( access )
    local r
    if o:exists() then
        if type( alien ) == "string" then
            o:inLanguage( alien:lower() )
        end
        if type( apply ) == "table" then
            o:params( apply )
        end
        r = o:plain()
    end
    return r or false
end -- Multilingual.int()



Multilingual.isLang = function ( ask, additional )
    -- Could this be an ISO language code?
    -- Precondition:
    --     ask         -- language code
    --     additional  -- true, if Wiki codes like "simple" permitted
    -- Postcondition:
    --     Returns boolean
    local r, s
    if additional then
        s = ask
    else
        s = Multilingual.getBase( ask )
    end
    if s then
        r = mw.language.isKnownLanguageTag( s )
        if not r  and  additional then
            r = Multilingual.exotic[ s ] or false
        end
    else
        r = false
    end
    return r
end -- Multilingual.isLang()



Multilingual.isLangWiki = function ( ask )
    -- Could this be a Wiki language version?
    -- Precondition:
    --     ask  -- language version specifier
    -- Postcondition:
    --     Returns boolean
    local r
    local s = Multilingual.getBase( ask )
    if s then
        r = mw.language.isSupportedLanguage( s )  or
            Multilingual.exotic[ ask ]
    else
        r = false
    end
    return r
end -- Multilingual.isLangWiki()



Multilingual.isMinusculable = function ( ask, assigned )
    -- Could this language name become downcased?
    -- Precondition:
    --     ask       -- language code, or nil
    --     assigned  -- language name, or nil
    -- Postcondition:
    --     Returns boolean
    local r   = true
    if ask then
        local cnf = fetch( "Multilingual/config", true )
        if cnf then
            local s = string.format( " %s ", ask:lower() )
            if type( cnf.stopMinusculization ) == "string"
               and  cnf.stopMinusculization:find( s, 1, true ) then
                r = false
            end
            if r  and  assigned
               and  type( cnf.seekMinusculization ) == "string"
               and  cnf.seekMinusculization:find( s, 1, true )
               and  type( cnf.scanMinusculization ) == "string" then
                local scan = assigned:gsub( "[%(%)]", " " ) .. " "
                if not scan:find( cnf.scanMinusculization ) then
                    r = false
                end
            end
        end
    end
    return r
end -- Multilingual.isMinusculable()



Multilingual.userLang = function ( accept, frame )
    -- Try to support user language by application
    -- Precondition:
    --     accept  -- space separated list of available ISO 639 codes
    --                Default: project language, or English
    --     frame   -- frame, if available
    -- Postcondition:
    --     Returns string with appropriate code
    local s = type( accept )
    local codes, r, slang
    if s == "string" then
        codes = mw.text.split( accept:lower(), " " )
    elseif s == "table" then
        codes = { }
        for i = 1, #accept do
            s = accept[ i ]
            if type( s ) == "string"  then
                table.insert( codes, s:lower() )
            end
        end -- for i
    else
        codes = { }
        slang = favorite()
        if mw.language.isKnownLanguageTag( slang ) then
            table.insert( codes, slang )
        end
    end
    slang = User.favorize( codes, frame )
    if not slang then
        slang = favorite()  or  "en"
    end
    if feasible( slang, codes ) then
        r = slang
    elseif slang:find( "-", 1, true ) then
        slang = Multilingual.getBase( slang )
        if feasible( slang, codes ) then
            r = slang
        end
    end
    if not r then
        local others = mw.language.getFallbacksFor( slang )
        for i = 1, #others do
            slang = others[ i ]
            if feasible( slang, codes ) then
                r = slang
                break -- for i
            end
        end -- for i
        if not r then
            if feasible( "en", codes ) then
                r = "en"
            else
                r = codes[ 1 ]
            end
        end
    end
    return r
end -- Multilingual.userLang()



Multilingual.userLangCode = function ()
    -- Guess a user language code
    -- Postcondition:
    --     Returns code of current best guess
    return User.self  or  favorite()  or  "en"
end -- Multilingual.userLangCode()



Multilingual.failsafe = function ( assert )
    -- Retrieve versioning and check for compliance
    -- Precondition:
    --     assert  -- string, with required version or "wikidata",
    --                or false
    -- Postcondition:
    --     Returns  string with appropriate version, or false
    local since = assert
    local r
    if since == "wikidata" then
        local item = Multilingual.item
        since = false
        if type( item ) == "number"  and  item > 0 then
            local entity = mw.wikibase.getEntity( string.format( "Q%d",
                                                                 item ) )
            if type( entity ) == "table" then
                local vsn = entity:formatPropertyValues( "P348" )
                if type( vsn ) == "table"  and
                   type( vsn.value) == "string" and
                   vsn.value ~= "" then
                    r = vsn.value
                end
            end
        end
    end
    if not r then
        if not since  or  since <= Multilingual.serial then
            r = Multilingual.serial
        else
            r = false
        end
    end
    return r
end -- Multilingual.failsafe()



-- Export
local p = { }



p.fair = function ( frame )
    -- Format language code
    --     1  -- language code
    return Multilingual.fair( frame.args[ 1 ] )  or  ""
end -- p.fair



p.fallback = function ( frame )
    -- Is another language suitable as replacement?
    --     1  -- language version specifier to be supported
    --     2  -- language specifier of a possible replacement
    local r = Multilingual.fallback( frame.args[ 1 ], frame.args[ 2 ]  )
    return r and "1" or ""
end -- p.fallback



p.findCode = function ( frame )
    -- Retrieve language code from language name
    --     1  -- name in current project language
    return Multilingual.findCode( frame.args[ 1 ] )  or  ""
end -- p.findCode



p.format = function ( frame )
    -- Format one or more languages
    --     1          -- language list or item
    --     slang      -- language of the answer, if not native
    --                   * -- native
    --                   ! -- current project
    --                   any valid code
    --     shift      -- capitalize, if "c"; downcase, if "d"
    --                   capitalize first item only, if "f"
    --     link       -- 1 -- link items
    --     scream     -- category title in case of error
    --     split      -- split pattern, if list expected
    --     separator  -- list separator, else split
    --     start      -- prepend first element, if any
    local r
    local link
    if frame.args.link == "1" then
        link = true
    end
    r = Multilingual.format( frame.args[ 1 ],
                             frame.args.slang,
                             frame.args.shift,
                             link,
                             frame.args.scream,
                             frame,
                             frame.args.split,
                             frame.args.separator,
                             frame.args.start )
    return r or ""
end -- p.format



p.getBase = function ( frame )
    -- Retrieve base language from possibly combined ISO language code
    --     1  -- code
    return Multilingual.getBase( frame.args[ 1 ] )  or  ""
end -- p.getBase



p.getName = function ( frame )
    -- Retrieve language name from ISO language code
    --     1  -- code
    --     2  -- language to be used for the answer, if not native
    --           ! -- current project
    --           * -- native
    --           any valid code
    local slang = frame.args[ 2 ]
    local r
    if slang then
        slang = mw.text.trim( slang )
    end
    r = Multilingual.getName( frame.args[ 1 ], slang )
    return r or ""
end -- p.getName



p.int = function ( frame )
    -- Translated system message
    --     1             -- message ID
    --     lang          -- language code
    --     $1, $2, ...   -- parameters
    local sysMsg = frame.args[ 1 ]
    local r
    if sysMsg then
        sysMsg = mw.text.trim( sysMsg )
        if sysMsg ~= "" then
            local n     = 0
            local slang = frame.args.lang
            local i, params, s
            if slang == "" then
                slang = false
            end
            for k, v in pairs( frame.args ) do
                if type( k ) == "string" then
                    s = k:match( "^%$(%d+)$" )
                    if s then
                        i = tonumber( s )
                        if i > n then
                            n = i
                        end
                    end
                end
            end -- for k, v
            if n > 0 then
                local s
                params = { }
                for i = 1, n do
                    s = frame.args[ "$" .. tostring( i ) ]  or  ""
                    table.insert( params, s )
                end -- for i
            end
            r = Multilingual.int( sysMsg, slang, params )
        end
    end
    return r or ""
end -- p.int



p.isLang = function ( frame )
    -- Could this be an ISO language code?
    --     1  -- code
    local lucky, r = pcall( Multilingual.isLang,
                            frame.args[ 1 ] )
    return r and "1" or ""
end -- p.isLang



p.isLangWiki = function ( frame )
    -- Could this be a Wiki language version?
    --     1  -- code
    local lucky, r = pcall( Multilingual.isLangWiki,
                            frame.args[ 1 ] )
    return r and "1" or ""
end -- p.isLangWiki



p.kannDeutsch = function ( frame )
    -- Kann man mit diesem Sprachcode deutsch verstehen?
    --     1  -- code
    local r = Multilingual.fallback( frame.args[ 1 ], "de" )
    return r and "1" or ""
end -- p.kannDeutsch



p.userLang = function ( frame )
    -- Which language does the current user prefer?
    --     1  -- space separated list of available ISO 639 codes
   return Multilingual.userLang( frame.args[ 1 ], frame )
end -- p.userLang



p.failsafe = function ( frame )
    -- Versioning interface
    local s = type( frame )
    local since
    if s == "table" then
        since = frame.args[ 1 ]
    elseif s == "string" then
        since = frame
    end
    if since then
        since = mw.text.trim( since )
        if since == "" then
            since = false
        end
    end
    return Multilingual.failsafe( since )  or  ""
end -- p.failsafe()



p.Multilingual = function ()
    return Multilingual
end -- p.Multilingual

return p