-- STEP 1: Click on the "edit" tab at the top of the page to edit this module.

-- STEP 2: if you want to increment by a number other than 1, put that number below, after the equals sign. 
local increment = 1

-- STEP 3: Replace the example template text with the template text that you wish to increment.
local templatetext = [==========[
|header3  = Section 1
|label5   = Label A
|data5    = Data A
|label7   = Label C
|data7    = Data C
|header10 = Section 2
|label12  = Label D
|data12   = Data D
]==========]

-- STEP 4: Save this module.

-- STEP 5: You can now output the incremented text with the following code:
--                {{subst:#invoke:IncrementParams|main}}
-- Or you can simply copy and paste the text from this module's documentation.

-- STEP 6: Check the output! In rare cases this module might produce false positives.
-- For example, it will change the text "[[Some link|foo3=bar]]" to "[[Some link|foo4=bar]]".
-- You can use the "show changes" function in the edit window of the template you are editing
-- to find any false positives.

-- STEP 7: When you are finished, undo your changes to this page, so that the next person
-- won't be confused by seeing any non-default values. Thanks for using this module!

local p = {}
 
local function replace(prefix, num, suffix)
    return '|' .. prefix .. tostring(tonumber(num) + increment) .. suffix .. '='
end
 
function p.main(frame)
    -- Increment the template text.
    templatetext = mw.ustring.gsub(templatetext, '|(%s*%a?[%a_%-]-%s*)([1-9]%d*)(%s*[%a_%-]-%a?%s*)=', replace)
    -- Add pre tags and escape html etc. if the pre option is set.
    if frame and frame.args and frame.args.pre and frame.args.pre ~= '' then
        templatetext = mw.text.nowiki(templatetext)
        templatetext = '<pre style="white-space:-moz-pre-wrap; white-space:-pre-wrap; '
            .. 'white-space:-o-pre-wrap; white-space:pre-wrap; word-wrap:break-word;">' 
            .. templatetext .. '</pre>'
    end
    return templatetext
end
 
return p