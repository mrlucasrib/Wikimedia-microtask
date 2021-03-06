-- This module implements {{archive list}} in Lua, and adds a few
-- new features.

-- Process a numeric argument to make sure it is a positive
-- integer.
local function processNumArg( num )
    if num then
        num = tonumber( num )
        if type( num ) == 'number' then
            num = math.floor( num )
            if num >= 0 then
                return num
            end
        end
    end
    return nil
end

-- Checks whether a page exists, going through pcall
-- in case we are over the expensive function limit.
local function checkPageExists( title )
    if not title then
        error('No title passed to checkArchiveExists', 2)
    end
    local noError, titleObject = pcall(mw.title.new, title)
    if not noError then
        -- If we are over the expensive function limit then assume
        -- that the page doesn't exist.
        return false
    else
        if titleObject then
            return titleObject.exists
        else
            return false -- Return false if given a bad title.
        end
    end
end

-- Checks every nth archive to see if it exists, and returns the
-- number of the first archive that doesn't exist. It is
-- necessary to do this in batches because each check is an
-- expensive function call, and we want to avoid making too many
-- of them so as not to go over the expensive function limit.
local function checkArchives( prefix, n, start )
    local i = start
    local exists = true
    while exists do
        exists = checkPageExists( prefix .. tostring( i ) )
        if exists then
            i = i + n
        end
    end
    return i
end

-- Return the biggest archive number, using checkArchives()
-- and starting in intervals of 1000. This should get us a
-- maximum of 500,000 possible archives before we hit the
-- expensive function limit.
local function getBiggestArchiveNum( prefix, start, max )
    -- Return the value for max if it is specified.
    max = processNumArg( max )
    if max then
        return max
    end
    
    -- Otherwise, detect the largest archive number.
    start = start or 1
    local check1000 = checkArchives( prefix, 1000, start )
    if check1000 == start then
        return 0 -- Return 0 if no archives were found.
    end
    local check200 = checkArchives( prefix, 200, check1000 - 1000 )
    local check50 = checkArchives( prefix, 50, check200 - 200 )
    local check10 = checkArchives( prefix, 10, check50 - 50 )
    local check1 = checkArchives( prefix, 1, check10 - 10 )
    -- check1 is the first page that doesn't exist, so we want to
    -- subtract it by one to find the biggest existing archive.
    return check1 - 1
end

-- Get the archive link prefix (the title of the archive pages
-- minus the number).
local function getPrefix( root, prefix, prefixSpace )
    local ret = root or mw.title.getCurrentTitle().prefixedText
    ret = ret .. '/'
    if prefix then
        ret = ret .. prefix
        if prefixSpace == 'yes' then
            ret = ret .. ' '
        end
    else
        ret = ret .. 'Archive '
    end
    return ret
end

-- Get the number of archives to put on one line. Set to
-- math.huge if there should be no line breaks.
local function getLineNum( links, nobr, isLong )
    local linksToNum = tonumber( links )
    local lineNum
    if nobr == 'yes' or (links and not linksToNum) then
        lineNum = math.huge
    -- If links is a number, process it. Negative values and expressions
    -- such as links=8/2 produced some interesting values with the old
    -- template, but we will ignore those for simplicity.
    elseif type(linksToNum) == 'number' and linksToNum >= 0 then
        -- The old template rounded down decimals to the nearest integer.
        lineNum = math.floor( linksToNum )
        if lineNum == 0 then
            -- In the old template, values of links between 0 and 0.999
            -- suppressed line breaks.
            lineNum = math.huge
        end
    else
    	if isLong==true then
    		lineNum = 3 -- Default to 3 links on long
    	else
        	lineNum = 10 -- Default to 10 on short
        end
    end
    return lineNum
end

-- Gets the prefix to put before the archive links.
local function getLinkPrefix( prefix, space, isLong )
    -- Get the link prefix.
    local ret = ''
    if isLong==true then ---- Default of old template for long is 'Archive '
    	if type(prefix) == 'string' then
    		if prefix == 'none' then -- 'none' overrides to empty prefix
    			ret = ''
    		 else
    		 	ret = prefix
    		 	if space == 'yes' then
    		 		ret = ret .. ' '
    		 	end
		 	end
	 	else
	 		ret = 'Archive '
		end
	else --type is not long
		if type(prefix) == 'string' then
        	ret = prefix
        	if space == 'yes' then
        	    ret = ret .. ' '
        	end
    	end
    end
    return ret
end

-- Get the number to start listing archives from.
local function getStart( start )
    start = processNumArg( start )
    if start then
        return start
    else
        return 1
    end
end

-- Process the separator parameter.
local function getSeparator( sep )
    if sep and type(sep) == 'string' then
        if sep == 'dot' 
            or sep =='pipe'
            or sep == 'comma'
            or sep == 'tpt-languages' then
            return mw.message.new( sep .. '-separator' ):plain()
        else
            return sep
        end
    else
        return nil
    end
end

-- Generates the list of archive links. glargs.max must be either zero (for
-- no archives) or a positive integer value.
local function generateLinks( glargs )
    if type( glargs ) ~= 'table' or not glargs.max or not glargs.prefix then
        error('insufficient arguments passed to generateLinks', 2)
    end
    -- If there are no archives yet, return a message and a
    -- link to create Archive one.
    if glargs.max == 0 then
    	if glargs.isLong == true then
    		glargs.max = 1 -- One archive redlink is displayed for Long format
    	else -- Short error and a creat link is displayed for short
        	return 'no archives yet ([[' .. glargs.prefix .. '1|create]])'
        end
    end
    -- Return an html error if the start number is greater than the 
    -- maximum number.
    local start = glargs.start or 1
    if start > glargs.max then
        return '<span class="error">Start value "' 
            .. tostring( start ) 
            .. '" is greater than the most recent archive number "' 
            .. tostring( glargs.max ) 
            .. '".</span>'
    end
    local linkPrefix = glargs.linkPrefix or ''
        local lineNum = glargs.lineNum or 10
    local sep = '' -- Long default separator is cell elements, short is ', '
    local lineSep = '' -- Long default linebreak is row elements short is '\n'
    if glargs.isLong==true then 
    	sep = glargs.sep or ''
    	sep = sep .. '</td><td>'
    	lineSep = glargs.lineSep or ''
		lineSep = lineSep .. '</td></tr><tr><td>'
    else
    	sep = glargs.sep or mw.message.new( 'comma-separator' ):plain()
    	lineSep = glargs.lineSep or '<br />'
    end
    -- Generate the archive links.
    local lineCounter = 1 -- The counter to see whether we need a line break or not.
    local ret = {} -- A table containing the strings to be returned.
    if glargs.isLong == true then --Long version is a table
    	table.insert(ret, "<table style=\"width: 100%; padding: 0px; text-align: center; background-color: transparent;\"><tr><td>")
    end
    for archiveNum = start, glargs.max do
        local link = mw.ustring.format(
            '[[%s%d|%s%d]]',
            glargs.prefix, archiveNum, linkPrefix, archiveNum
        )
        table.insert( ret, link )
        -- If we don't need a new line, output a comma. We don't need
        -- a comma after the last link. 
        if lineCounter < lineNum and archiveNum < glargs.max then
            table.insert( ret, sep )
            lineCounter = lineCounter + 1
        -- Output new lines if needed. We don't need a new line after
        -- the last link.
        elseif lineCounter >= lineNum and archiveNum < glargs.max then
            table.insert( ret, lineSep )
            lineCounter = 1
        end
    end
    if glargs.isLong == true then --Long version is a table
    	table.insert(ret, "</td></tr></table>")
    end
    return table.concat( ret )
end

-- Determine if format should be long
local function findFormType( auto )
	if auto == nil or auto == '' then
		return false
	elseif auto == 'long' then
			return true
	else
		return false
	end
end

-- Get the archive data and pass it to generateLinks().
local function _main( args )
	local isLong = findFormType( args.auto )
    local prefix = getPrefix( args.root, args.prefix, args.prefixspace )
    local lineNum = getLineNum( args.links, args.nobr, isLong )
    local linkPrefix = getLinkPrefix( args.linkprefix, args.linkprefixspace, isLong )
    local start = getStart( args.start )
    local max = getBiggestArchiveNum( prefix, start, args.max )
    local sep = getSeparator( args.sep )
    local lineSep = getSeparator( args.linesep )
    local glargs = {
        start = start,
        max = max,
        prefix = prefix,
        linkPrefix = linkPrefix,
        isLong = isLong,
        sep = sep,
        lineNum = lineNum,
        lineSep = lineSep
    }
    return generateLinks( glargs )
end

-- A wrapper function to make getBiggestArchiveNum() available from
-- #invoke.
local function _count( args )
    local prefix = getPrefix( args.root, args.prefix, args.prefixspace )
    local archiveMax = getBiggestArchiveNum( prefix )
    return archiveMax
end

function makeWrapper( func )
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
        
        -- Ignore blank values for parameters other than "links",
        -- which functions differently depending on whether it is
        -- blank or absent.
        local args = {}
        for k, v in pairs( origArgs ) do
            if k == 'links' or v ~= '' then
                args[k] = v
            end
        end
        
        return func( args )
    end
end

return {
    main = makeWrapper( _main ),
    count = makeWrapper( _count )
}