local p = {};

local args = {}
local origArgs
local root

local function preprocessSingleArg(argName, default)
    -- If the argument exists and isn't blank, add it to the argument table.
    -- Blank arguments are treated as nil to match the behaviour of ParserFunctions.
    if origArgs[argName] and origArgs[argName] ~= '' then
        args[argName] = origArgs[argName]:gsub("&#35;", "#")
    elseif default ~= nil then
    	args[argName] = default:gsub("&#35;", "#")
    end
end

local function preprocessArgs(prefixTable, step)
    -- Assign the parameters with the given prefixes to the args table, in order, in batches
    -- of the step size specified. This is to prevent references etc. from appearing in the
    -- wrong order. The prefixTable should be an array containing tables, each of which has
    -- two possible fields, a "prefix" string and a "depend" table. The function always parses
    -- parameters containing the "prefix" string, but only parses parameters in the "depend"
    -- table if the prefix parameter is present and non-blank.
    if type(prefixTable) ~= 'table' then
        error("Non-table value detected for the prefix table", 2)
    end
    if type(step) ~= 'number' then
        error("Invalid step value detected", 2)
    end
    
    -- Get arguments without a number suffix, and check for bad input.
    for i,v in ipairs(prefixTable) do
        if type(v) ~= 'table' or type(v.prefix) ~= "string" or (v.depend and type(v.depend) ~= 'table') then
            error('Invalid input detected to preprocessArgs prefix table', 2)
        end
        preprocessSingleArg(v.prefix, nil)
        -- Only parse the depend parameter if the prefix parameter is present and not blank.
        if args[v.prefix] and v.depend then
            for j, dependValue in ipairs(v.depend) do
                if type(dependValue) ~= 'string' then
                    error('Invalid "depend" parameter value detected in preprocessArgs')
                end
                preprocessSingleArg(dependValue, nil)
            end
        end
    end

    -- Get arguments with number suffixes.
    local a = 1 -- Counter variable.
    local moreArgumentsExist = true
    while moreArgumentsExist == true do
        moreArgumentsExist = false
        for i = a, a + step - 1 do
            for j,v in ipairs(prefixTable) do
                local prefixArgName = v.prefix .. tostring(i)
                if origArgs[prefixArgName] then
                    moreArgumentsExist = true -- Do another loop if any arguments are found, even blank ones.
                    preprocessSingleArg(prefixArgName, nil)
                end
                -- Process the depend table if the prefix argument is present and not blank, or
                -- we are processing "prefix1" and "prefix" is present and not blank, and
                -- if the depend table is present.
                if v.depend and (args[prefixArgName] or (i == 1 and args[v.prefix])) then
                    for j,dependValue in ipairs(v.depend) do
                        local dependArgName = dependValue .. tostring(i)
                        preprocessSingleArg(dependArgName, nil)
                    end
                end
            end
        end
        a = a + step
    end
end

local function getArgNums(prefix)
    -- Returns a table containing the numbers of the arguments that exist
    -- for the specified prefix. For example, if the prefix was 'data', and
    -- 'data1', 'data2', and 'data5' exist, it would return {1, 2, 5}.
    local nums = {}
    for k, v in pairs(args) do
        local num = tostring(k):match('^' .. prefix .. '([1-9]%d*)$')
        if num then table.insert(nums, tonumber(num)) end
    end
    table.sort(nums)
    return nums
end

local function defaultLink(pagename)
	if pagename == args.basepagename then
		return 'User:' .. pagename
	elseif pagename == "Talk" then
		return 'User talk:' .. args.basepagename
	elseif pagename == "Contributions" then
		return 'Special:Contributions/' .. args.basepagename
	else
		return 'User:' .. args.basepagename .. '/' .. pagename
	end
end

local function _userpage()
	local nameargs = getArgNums('name')
	local nameargslen = 0
	for _ in pairs(nameargs) do nameargslen = nameargslen + 1 end
	local width = 100 / nameargslen
	root = mw.html.create('table')
	root:css('width', '100%')
	    :css('background-color', args.background_normal)
	    :tag('tr')
	local cellnums = getArgNums('name')
    table.sort(cellnums)
    for k, num in ipairs(cellnums) do
    	local row = root:tag('td'):css('border',args.border .. " solid medium"):css('text-align', 'center'):css('width', width .. '%')
    	local pagename = args['name' .. num]
    	local pagelink = nil
    	local textcolor = nil
    	if args['link' .. num] ~= nil then
    		pagelink = args['link' .. num]
    	else
    		pagelink = defaultLink(pagename)
    	end
    	if pagelink == args.fullpagename then
    		row:css('background-color', args.background_select)
    		textcolor = args.text_highlight
    	else
    		row:css('background-color', args.background_normal)
    		textcolor = args.text_normal
    	end
    	local para = row:tag("p")
    	para:wikitext("[[" .. pagelink .. "|'''<span style='color:" .. textcolor .. "'>" .. pagename .. "</span>''']]")
    	para:done()
    	row:done()
    end
	return tostring(root)
end

function p.userpage(frame, fullpagename, basepagename)
	-- If called via #invoke, use the args passed into the invoking template.
    -- Otherwise, for testing purposes, assume args are being passed directly in.
    if frame == mw.getCurrentFrame() then
        origArgs = frame:getParent().args
    else
        origArgs = frame
    end
    preprocessSingleArg('user_title_color', 'black')
    preprocessSingleArg('background_normal', 'lightblue')
    preprocessSingleArg('background_select', 'blue')
    preprocessSingleArg('text_highlight', 'white')
    preprocessSingleArg('text_normal', 'navy')
    preprocessSingleArg('border', 'navy')
    preprocessSingleArg('fullpagename', frame.args[1])
    preprocessSingleArg('basepagename', frame.args[2])
    preprocessArgs({{prefix='name', depend={'link'}}}, 4)
    return _userpage()
end
	
return p;