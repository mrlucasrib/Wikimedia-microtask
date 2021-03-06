-- This module implements {{collapsible list}}.

local p = {}

local function gettitlestyletracking( ts )
	if not ts then return '' end
	ts = mw.ustring.gsub(mw.ustring.lower(ts), '%s', '')
	local tsvals = mw.text.split(ts, ';')
	table.sort(tsvals)
	local skey = table.concat(tsvals,';')
	skey = mw.ustring.gsub(skey, '^;', '')
	skey = mw.text.encode(mw.text.encode(skey),'%c%[%]=')
	if (mw.ustring.match(';' .. ts, ';background:') or mw.ustring.match(';' .. ts, ';background%-color:')) 
		and mw.ustring.match(';' .. ts, ';text%-align:') then 
		return '[[Category:Pages using collapsible list with both background and text-align in titlestyle|' .. skey .. ' ]]'
	end
	return '[[Category:Pages using collapsible list without both background and text-align in titlestyle|' .. skey .. ' ]]'
end

local function getListItem( data )
    if not type( data ) == 'string' then
        return ''
    end
    return mw.ustring.format( '<li style="line-height: inherit; margin: 0">%s</li>', data )
end

-- Returns an array containing the keys of all positional arguments
-- that contain data (i.e. non-whitespace values).
local function getArgNums( args )
    local nums = {}
    for k, v in pairs( args ) do
        if type( k ) == 'number' and
            k >= 1 and
            math.floor( k ) == k and
            type( v ) == 'string' and
            mw.ustring.match( v, '%S' ) then
                table.insert( nums, k )
        end
    end
    table.sort( nums )
    return nums
end

-- Formats a list of classes, styles or other attributes.
local function formatAttributes( attrType, ... )
    local attributes = { ... }
    local nums = getArgNums( attributes )
    local t = {}
    for i, num in ipairs( nums ) do
        table.insert( t, attributes[ num ] )
    end
    if #t == 0 then
        return '' -- Return the blank string so concatenation will work.
    end
    return mw.ustring.format( ' %s="%s"', attrType, table.concat( t, ' ' ) )
end

local function buildList( args )
    -- Get the list items.
    local listItems = {}
    local argNums = getArgNums( args )
    for i, num in ipairs( argNums ) do
        table.insert( listItems, getListItem( args[ num ] ) )
    end
    if #listItems == 0 then
        return ''
    end
    listItems = table.concat( listItems )
    
    -- Get class, style and title data.
    local div1class = formatAttributes( 'class', 'NavFrame', not args.expand and 'collapsed' )
    local div1style = formatAttributes(
        'style',
        args.frame_style,
        args.framestyle,
        not ( args.frame_style or args.framestyle ) and 'border: none; padding: 0;'
    )
    local div2class = formatAttributes( 'class', 'NavHead' )
    local div2style = formatAttributes(
        'style',
        'font-size: 105%; background: transparent; text-align: left;',
        args.title_style,
        args.titlestyle
    )
    local title = args.title or 'List'
    local ulclass = formatAttributes( 'class', 'NavContent', args.hlist and 'hlist' )
    local ulstyle = formatAttributes( 
        'style',
        not args.bullets and 'list-style: none none; margin-left: 0;',
        args.list_style,
        args.liststyle,
        not ( args.list_style or args.liststyle ) and 'text-align: left;',
        'font-size: 105%; margin-top: 0; margin-bottom: 0; line-height: inherit;'
    )
    
    -- Build the list.
    return mw.ustring.format( 
        '<div%s%s>\n<div%s%s>%s</div>\n<ul%s%s>%s</ul>\n</div>',
        div1class, div1style, div2class, div2style, title, ulclass, ulstyle, listItems
    ) .. gettitlestyletracking(args.title_style or args.titlestyle)
end

function p.main( frame )
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
    
    local args = {}
    for k, v in pairs( origArgs ) do
        if type( k ) == 'number' or v ~= '' then
            args[ k ] = v
        end
    end
    return buildList( args )
end

return p