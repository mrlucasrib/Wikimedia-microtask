--[=[ 2013-08-05
{{TemplateDataGenerator}}
Basic idea by [[w:en:User:Salix alba]]
]=]



local config = {
    luxury = false,    -- default alphabetical order for parameter list
    start  = false,    -- preceeding lines
    shift  = "   ",    -- (not used now) indentation, like "   " or "\t"
    suffix = false,    -- following lines
    scheme = [=["%s":
              { "label":       "%s",
                "description": "",
                "type":        "string",
                "required":    false
              }]=]
    -- config.scheme has placeholders %s
    -- for the parameter name and for "label".
    -- One of various indentation styles.
    -- Feel free to compose a different one, also using config.shift etc.
};



local function factory( analyze, alphabetical )
    -- Make parameter sequence from template source text
    --     analyze       -- string; template source text
    --     alphabetical  -- boolean or nil; sort parameter list
    -- Return:
    --     table (sequence) with parameter names
    local i, s;
    local r = { };
    for s in analyze:gmatch( "{{{([^|}\n]+)" ) do
        for i = 1, #r do
            if r[ i ] == s then
                s = false;
                break; -- for i
            end
        end -- for i
        if s then
            table.insert( r, s );
        end
    end -- for s in :gmatch()
    if alphabetical then
        table.sort( r, nil );
    end
    return r;
end -- factory()



local function format( analyze, alphabetical )
    -- Make JSON code from template source text
    --     analyze       -- string; template source text
    --     alphabetical  -- boolean or nil; sort parameter list
    -- Return:
    --     string with JSON code
    -- Uses:
    --     >  config.shift
    --     >  config.scheme
    --     factory()
    local i;
    local params = factory( analyze, alphabetical );
    local r      = '{ "description": "",\n';
--  local shift  = config.shift or "";    -- currently unused
    local start  = "            ";
    local show, symbol;
    r = r ..       '  "params": { ';
    for i = 1, #params do
        if i > 1 then
            r = string.format( "%s,\n%s  ", r, start );
        end
        symbol = params[ i ];
        if mw.ustring.match( symbol, "^%u%u" ) then
            show = mw.ustring.sub( symbol, 1, 1 ) ..
                   mw.ustring.lower( mw.ustring.sub( symbol, 2 ) );
        else
            show = "";
        end
        r = r .. string.format( config.scheme, symbol, show );
        -- common JSON pattern is ASCII; string.format() will do
    end -- for i
    r = string.format( "%s\n%s}\n}", r, start );
    return r;
end -- format()



local function fun( attempt, alphabetical )
    -- Retrieve used template params and build TemplateData skeleton
    -- Precondition:
    --     attempt       -- mw.title object; related to template code
    --     alphabetical  -- boolean or nil; sort parameter list
    -- Return:
    --     string to be applied
    -- Uses:
    --     >  config.luxury
    --     >  config.start
    --     >  config.suffix
    --     format()
    local r;
    local source = string.match( attempt.baseText .. "/",
                                 "^([^/]+)/" );
                   -- ensure top page in NS with no subpage property
                   -- note that pattern is ASCII; string.match() will do
    local title  = mw.title.makeTitle( attempt.namespace, source );
    if title.exists then
        local luxury = config.luxury;
        local spec   = "%s<templatedata>\n%s\n</templatedata>\n%s";
        if type( alphabetical ) == "boolean" then
            luxury = alphabetical;
        end
        if config.start then
            r = config.start .. "\n";
        else
            r = "";
        end
        r = string.format( spec,
                           r,
                           format( title:getContent(), luxury ),
                           config.suffix or "" );
        -- note that format spec is ASCII only; string.format() will do
    else    -- test only
        r = "ERROR * no page " .. title.fullText;
    end
    return r;
end -- fun()



-- Export
local p = {};

function p.getBlock( pagetitle, namespace, alphabetical )
    -- Precondition:
    --     pagetitle     -- string; page title related to template code
    --     namespace     -- string, number or nil; namespace (Template:)
    --     alphabetical  -- boolean or nil; sort parameter list
    -- Uses:
    --     fun()
    local title = mw.title.makeTitle( namespace or 10,  pagetitle );
    local lucky, r = pcall( fun, title, alphabetical );
    return r;
end -- .getBlock()



function p.f( frame )
    -- Precondition:
    --     frame  -- object
    --     Invoked on a template page or template subpage.
    -- Uses:
    --     fun()
    local luxury;
    local parental = frame:getParent().args;
    local sort     = parental[ 1 ] or parental[ "1" ] or parental.sort;
    if sort then
        luxury = ( tonumber( sort) == 1 );
    end
    local lucky, r = pcall( fun, mw.title.getCurrentTitle(), luxury );
    -- return "<pre>" .. r .. "</pre>";
    return r;

end -- .f()

return p;