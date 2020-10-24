--
-- This module checks whether any of a given set of input criteria are valid CSD criteria.
-- It is also possible to specify pre-defined or custom sets of CSD criteria to check against.
--

local p = {}

function critMatch(s,test_values) -- returns true if s matches one of the table of test_values
    if type(test_values) == "table" then
        for n,value in ipairs(test_values) do
           if s == value then
               return true
           end
        end
    else
        error("the second parameter passed to critMatch() must be a table",2)
    end
end

function p.check(frame) -- the main CSD check function

    -- get arguments
    local args;
    if frame == mw.getCurrentFrame() then
        -- We're being called via #invoke. If the invoking template passed any args, use
        -- them. Otherwise, use the args that were passed into the template.
        args = frame:getParent().args;
        for k, v in pairs(frame.args) do
            args = frame.args;
            break
        end
    else
        -- We're being called from another module or from the debug console, so assume
        -- the args are passed in directly.
        args = frame;
    end

    -- define variables
    local input_values = {};
    local test_criteria = {};
    local all_criteria = { -- all valid CSD criteria
        "G1" , "G2" , "G3" , "G4" , "G5" , "G6" , "G7" , "G8" , "G9" , "G10" , "G11" , "G12" , "G13" , "G14" ,
        "A1" , "A2" , "A3" , "A5" , "A7" , "A9" , "A10" , "A11",
        "F1" , "F2" , "F3" , "F4" , "F5" , "F6" , "F7" , "F8" , "F9" , "F10" , "F11" ,
        "C1" , "C2" ,
        "U1" , "U2" , "U3" , "U5" ,
        "R2" , "R3" , "R4" ,
        "T3" ,
        "P1" , "P2"
    };
    local tag_criteria = { -- all CSD criteria used by [[Template:Db-multiple]]
        "G1" , "G2" , "G3" , "G4" , "G5" , "G6" , "G7" , "G8" , "G10" , "G11" , "G12" , "G13" , "G14" ,
        "A1" , "A2" , "A3" , "A5" , "A7" , "A9" , "A10" , "A11",
        "F1" , "F2" , "F3" , "F7" , "F8" , "F9" , "F10" ,
        "C1" ,
        "U1" , "U2" , "U3" , "U5" ,
        "R2" , "R3" , "R4" ,
        "P1" , "P2"
    };
    local notice_criteria = { -- all CSD criteria used by [[Template:Db-notice-multiple]]
        "G1" , "G2" , "G3" , "G4" , "G10" , "G11" , "G12" , "G13" , "G14" ,
        "A1" , "A2" , "A3" , "A5" , "A7" , "A9" , "A10" , "A11",
        "F1" , "F2" , "F3" , "F7" , "F9" , "F10" ,
        "C1" ,
        "U3" , "U5" ,
        "R2" , "R3" , "R4" ,
        "P1" , "P2"
    };

    -- build tables of input values and test criteria
    for k,v in pairs(args) do
        v = mw.ustring.upper(v);

        -- insert positional parameter values into input_values
        if type(k) == "number" then
            v = mw.ustring.gsub(v,"^%s*(.-)%s*$","%1"); -- strip whitespace from positional parameters
            table.insert(input_values,v)

        -- insert critn parameter values into test_criteria
        elseif mw.ustring.match(k,"^crit[1-9]%d*$") then
            if critMatch(v,all_criteria) then -- check to make sure the criteria are valid
                table.insert(test_criteria,v)
            end
        end
    end

    -- work out which set of CSD criteria to check against
    local criteria_set = {}
    if next(test_criteria) then -- if any test criteria are specified, use those regardless of the "set" parameter
        criteria_set = test_criteria;
    elseif args["set"] == "tag" then
        criteria_set = tag_criteria;
    elseif args["set"] == "notice" then
        criteria_set = notice_criteria;
    else
        criteria_set = all_criteria;
    end

    -- check the input values against the criteria set and output "yes" if there is a match
    for i,v in ipairs(input_values) do
        if critMatch(v,criteria_set) then
            return "yes"
        end
    end
end

return p