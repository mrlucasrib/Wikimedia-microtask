local p = {}

-- Loading the flag translations module --
local translations = mw.loadData("Module:Flags/LocaleData")
local master = mw.loadData("Module:Flags/MasterData")

-- check if name is an original name in translation.fullname and
-- return its value, otherwise return nil
function check_translation(name)
    local link
    for translation, commonsName in pairs(translations.fullName) do
        if commonsName == name then
            link = translation
            break --if found break out from the loop
        end
    end
    return link
end

-- Size of flag --
-- Function to define the default size for the flag if needed
function defaultSize()
    --todo: move exception to Module:Flags/MasterData
    local sizeExceptions = { "Nepal", "Switzerland", "the Vatican City", }
    local size = "20x22px" --initialize with default value
    for some,exceptions in pairs(sizeExceptions) do
        if commonsName == exceptions then
            size = "20x17px"
            break --if found break out from loop
        end
    end
    return size
end

-- Assigning the parameter to a flag and a link
function p.flag(territory)
   --always declare local variable, they are more efficient and dont pollute global namespace
   local  commonsName
   local flagOf = "Flag_of_" -- Converts "Flag of" in a variable in order to accept images that don't follow this name schema
   local link = ""
   -- more efficient to access
   local flag_code = territory.args[1] or ""
-- Searching in the master table only.
-- 2 letter code search
    if #flag_code == 2 then
        -- try to assign a value to commonsName and check for nil value
        commonsName = master.twoLetter[flag_code]
        --if check_translation return nil then it will execute the or part and assign commonsName to link
        if commonsName then link = check_translation(commonsName) or commonsName; end
    elseif #flag_code == 3 then -- 3 letter code search
        commonsName = master.threeLetter[flag_code]
        if commonsName then link = check_translation(commonsName) or commonsName; end
    end
--  check if commonsName is still nil
    if commonsName == nil then
        -- check master.fullName table
        commonsName = master.fullName[flag_code]
        if commonsName then
           link = check_translation(commonsName) or commonsName;
        else -- Searching in FlagTranslations
            commonsName = translations.fullName[flag_code]
            if commonsName then
                link = flag_code
            else -- Fallback to Commons when the parameter doesn't have an entry in the tables
               commonsName = flag_code
               link = flag_code
            end
        end
    end

-- Variant check for historical flags --
   local variant =  territory.args[3]
   if variant and variant ~= "" then
      commonsName = master.variant[commonsName .. "|" .. variant]
      flagOf=""
   end

-- Label check --
   variant = territory.args[2]
   if variant and variant ~="{{{2}}}" then
      commonsName = master.variant[commonsName .. "|" .. variant]
      flagOf=""
    end

-- Digesting Commons flag files not following the format "Flag of "
-- These filenamess must be preceded by "File:" in the table values.

    if commonsName ~= nil and string.find( commonsName, "File:", 1 ) == 1 then
        commonsName = string.sub( commonsName, 6)
        flagOf=""
    end

-- Fallback for non-identified variant/label flags --
    if commonsName == nil then commonsName = "Flag of None" end

-- Border for everybody except Nepal and Ohio
-- todo: move exception to Module:Flags/MasterData
    local border = "border|"
    if commonsName == "Nepal" or commonsName == "Ohio" then
        border = ""
    end

-- Checking whether a size parameter has been introduced, otherwise set default
    if territory.args[4]:find("px", -2) ~= nil then
        size = territory.args[4]
    else
        size = defaultSize(commonsName)
    end

-- Customizing the link
    openBrackets = "[["
    closeBrackets = "]]"
    if territory.args[5] == "" then
        flagLink = ""
        textLink = ""
        openBrackets = ""
        closeBrackets = ""
    elseif territory.args[5] ~= "{{{link}}}" then
        flagLink = territory.args[5]
        textLink = territory.args[5] .. "|"
    else flagLink = link
        textLink = link .. "|"
    end

-- Text in addition to flag
    if territory.args[6] == "" then
        text = " " .. openBrackets .. link .. closeBrackets
    elseif territory.args[6] ~= "{{{text}}}" then
        text = " " .. openBrackets .. textLink .. territory.args[6] .. closeBrackets
    else text = ""
    end

return '[[File:' .. flagOf .. commonsName .. '.svg|' .. border .. 'link=' .. flagLink .. '|'.. size .. ']]' .. text
end
return p