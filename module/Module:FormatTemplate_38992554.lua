---- This module is intended to format templates to make them readable.
---- It should work by recognizing every beginning that ''should'' not be intermingled: [[, {{, {{#, {{{
---- It will count how many levels deep you've gone.
---- It will add 4 times that many spaces before each pipe | in a non-[[ element, removing any now present
---- It will label the beginning and end with a color specific to the type of element even when it can't indent
---- It will return everything in a nowiki wrapper (excluding the color formatting)

local p={}

local MAXPOSN = 30000 -- usually 50000 was 3 seconds .. not right now though ..
local HOLDABLE = {["{"] = true, ["["] = true, ["}"] = true, ["]"] = true}
local ACTABLE = {["{"] = true, ["["] = true, ["}"] = true, ["]"] = true, ["|"] = true, [":"] = true}
local MARKER = {["{{{"] = "|", ["{{"] = "|", ["{{#"] = ":", ["[["] = "|"}
local MATCH = {["{{{"] = "}}}", ["{{#"] = "}}", ["{{"] = "}}", ["[["] = "]]"}
local RENDER = {['{{{'] = { -- these are replaced by variables in module
    ['{{{'] = '</nowiki><span style="color:orange;">{{{</span><nowiki>',
    ['}}}'] = '</nowiki><span style="color:orange;">}}}</span><nowiki>',
    ['}}'] = '</nowiki><span style="color:orange;">}}</span><nowiki>',
    [']]'] = '</nowiki><span style="color:orange;">]]</span><nowiki>'
               }, ['{{#'] = { -- these will receive many different specific translations in module
    ['{{#'] = '</nowiki><span style="color:blue;">{{#</span><nowiki>',
    ['}}}'] = '</nowiki><span style="color:blue;">}}}</span><nowiki>',
    ['}}'] = '</nowiki><span style="color:blue;">}}</span><nowiki>',
    [']]'] = '</nowiki><span style="color:blue;">]]</span><nowiki>'
               }, ['{{'] = { -- these might eventually be expanded by the module, but not in the first versions (scotty, try and increase the power!)
    ['{{'] = '</nowiki><span style="color:red;">{{</span><nowiki>',
    ['}}}'] = '</nowiki><span style="color:red;">}}}</span><nowiki>',
    ['}}'] = '</nowiki><span style="color:red;">}}</span><nowiki>',
    [']]'] = '</nowiki><span style="color:red;">]]</span><nowiki>'
               }, ['[['] = { -- these can be left untouched, I think
    ['[['] = '</nowiki><span style="color:green;">[[</span><nowiki>',
    ['}}}'] = '</nowiki><span style="color:green;">}}}</span><nowiki>',
    ['}}'] = '</nowiki><span style="color:green;">}}</span><nowiki>',
    [']]'] = '</nowiki><span style="color:green;">]]</span><nowiki>'
               }}

local debuglog = ""
local text
local getletter -- this module is designed around reading ONCE, tracking state; getletter() gets each letter in text once
local out = ""
local flag = false -- true marks the end of the getletter() stream

function getContent(template)
    local title -- holds the result of the mw.title.xxx call
    if not(template) then
        title=mw.title.getCurrentTitle()
        if not(title) then return "error: failed to getCurrentTitle()" end
        local tdedoc=mw.ustring.match(title.fullText,"Template:(.-)/doc")
        if tdedoc then title=mw.title.new("Template:"..tdedoc) end -- SPECIAL CASE: Invoke in the template documentation processes the template instead
    else title=mw.title.new(page)
         if not (title) then return "error: failed to mw.title.new(" .. template .. ")" end
    end -- if not(template)
    return title.getContent(title) or ""
end

local function scanabort()
	flag = true
	return ":" -- an "actable" to prevent looping
end

function formatTemplate(text,importstack,posn,template) -- note template is just for the error message
    local debug=""
    local letter=""
    local output=""
    local outputtable={}
    posn=tonumber(posn) or 0
    if posn>0 then text=string.sub(text,posn,-1) end --- need to chop off the preceding text so it doesn't gmatch to it
    local stopposn = (string.find(text, "[^{}%[%]|:]", MAXPOSN))
    if stopposn then text= string.sub(text, 1, stopposn) end
    stack = {top = #importstack}
    for i = 0, stack.top do
        stack[i] = {}
        stack[i].feature = importstack[i]
    	stack[i].text = {}
    	stack[i].seg = 1 -- this is NOT ACCURATE, would need to be saved in the transition
    end
    stack.push = function(feature)
    	table.insert(stack[stack.top].text, out)
        stack.top = stack.top + 1
        stack[stack.top] = {}
        stack[stack.top].text = {RENDER[feature][feature]}
        stack[stack.top].seg = 1
        stack[stack.top].feature = feature
        out = ""
    end

    stack.pop = function(feature)
        local spillover = ""
        local pop = stack[stack.top].feature
        if (MATCH[pop] ~= feature and feature == "}}}") then
            feature = "}}"
            spillover = "}"
        end
        out = out .. RENDER[pop][feature]
        if (MATCH[pop] ~= feature) then
            out = out .. "<--- error? "
        end
        table.insert(stack[stack.top].text, out)
        table.insert(stack[stack.top - 1].text, table.concat(stack[stack.top].text))
        stack[stack.top] = nil
        stack.top = stack.top - 1
        out = ""
        return spillover
    end

    stack.field = function (letter)
        local ss = stack[stack.top].feature
        if (stack[stack.top].seg == 1 and letter == MARKER[ss]) then
            out = '</nowiki><span style = "color:gray;">' .. out .. '</span><nowiki>' .. letter
            stack[stack.top].seg = 2
        elseif (ss ~= "[[" and letter=="|") then
            out = out .. "</nowiki><br /><nowiki>"..string.rep("&nbsp;",4*stack.top).."|"
            table.insert(stack[stack.top].text, out)
            stack[stack.top].seg = stack[stack.top].seg + 1
            out = ""
        else
            out = out .. letter
        end
    end

    stack.write = function() -- out is a simple global variable for repeated concatenations; can't get too big though
        table.insert(stack[stack.top].text, out)
        out = ""
    end

    template=template or ""
    getletter = string.gmatch(text,".")
    out=""
    repeat
        local holding = ""
        repeat
        	letter = letter or "" -- bug that dumps nil letters comes up in the out = out ..letter, NOT while not ACTABLE[letter] ... why?
            while not ACTABLE[letter] do
    	        out = out .. letter
    	        letter = getletter() or scanabort()
            end
            if HOLDABLE[letter] then
                holding = letter
            else
                stack.field(letter)
            end
            letter = ""
        until holding ~= "" or flag
        if #out>20 then
            stack.write()
        end
        letter=getletter() or scanabort()
         -- add the letter to the next feature being parsed if possible
        if (holding == "[") then -- either [[ or just ignore
             -- cases based on the next letter after "["
            if (letter == "[") then
            	stack.push("[[")
                letter = ""
            else 
                out = out .. holding -- single [, treat normally
            end
        elseif (holding == "{") then
             -- cases based on the next letter after "{"
            if (letter == "{") then
                letter = getletter() or scanabort()
               if (letter == "#") then
             	 stack.push("{{#")
                 letter = ""
               elseif (letter == "{") then
             	 stack.push("{{{")
             	 letter = ""
               else
             	 stack.push("{{")
               end
            end
        elseif (holding == "]") then
            if (letter == "]") then -- we have a ]]
                stack.pop("]]")
                letter = ""
            else out = out .. holding
            end
        elseif (holding == "}") then
            if (letter == "}") then
                letter = getletter()
                if letter == "}" then
                    letter = stack.pop("}}}")
                else 
                    stack.pop("}}")
                end
            else out = out .. holding -- lone } is nothing
            end
        end
    until flag
    if stack.top>0 then
        out = string.sub(out, 1, -2) .. "<--- end of run ---></nowiki><br />'''run incomplete.'''"
        stack.write()
        local stackcrypt = ""
        for i = stack.top, 1, -1 do
        	table.insert(stack[i-1].text, table.concat(stack[i].text))
                stackcrypt = stackcrypt .. stack[i].feature
        end
        stackcrypt=string.gsub(stackcrypt,"{","<")
        stackcrypt=string.gsub(stackcrypt,"%[","(")
        stackcrypt=string.gsub(stackcrypt,"}",">")
        stackcrypt=string.gsub(stackcrypt,"%]",")")
        if string.len(text) >= MAXPOSN then
            out = out .. "<br />''Note: due to restrictions on Lua time usage, runs are truncated at MAXPOSN characters''"

            out = out .. "<br />''To continue this run, preview or enter <nowiki>{{#invoke:FormatTemplate|format|page="..template.."|stack="..stackcrypt.."|position="..#text.."}}"
        else out = out .. "<br />''If you have an additional segment of template to process, preview or enter <nowiki>{{#invoke:FormatTemplate|format|page="..template.."|stack="..stackcrypt.."|position=0}}"
        end
    end
    output=table.concat(stack[0].text) .. out
    return output
end

function p.main(frame,fcn)
    local args=frame.args
    local parent=frame.getParent(frame)
    if parent then pargs=parent.args else pargs={} end
    page=args.page or pargs.page
    text = getContent(page)
    local stackcrypt=args.stack or pargs.stack or ""
    stackcrypt=mw.ustring.gsub(stackcrypt,"<","{")
    stackcrypt=mw.ustring.gsub(stackcrypt,"%(","[")
    stackcrypt=mw.ustring.gsub(stackcrypt,">","}")
    stackcrypt=mw.ustring.gsub(stackcrypt,"%)","]")
    local stack={}
    local posn=args.position or pargs.position or 0
    local prowl=mw.ustring.gmatch(stackcrypt,"[^,%s]+")
    repeat
        local x=prowl()
        if x then table.insert(stack,x) end
    until not x
    fcn=fcn or args["function"] or pargs["function"] or ""
    fcn=mw.ustring.match(fcn,"%S+")
   -- text=text or args.text or pargs.text or args[1] or pargs[1] or "" -- doesn't work - gets interpreted or passed as "UNIQ..QINU", either way unusuable!
    local nowikisafehouse={}
    local nowikielementnumber=0
    local prowl=mw.ustring.gmatch(text,"<nowiki>(.-)</nowiki>")
    repeat
        local nowikimatch=prowl()
        if not(nowikimatch) then break end
        nowikielementnumber=nowikielementnumber+1
        table.insert(nowikisafehouse,nowikimatch)
    until false
    text=mw.ustring.gsub(text,"<nowiki>(.-)</nowiki>","<Module:FormatTemplate internal nowiki token>")
     -- this is the meat of the formatting
    if fcn=="format" then text=formatTemplate(text,stack,posn,page) end
     -- unprotect the nowikis from the template itself - but inactivate them on first display!
    for nw = 1,nowikielementnumber do
        text=mw.ustring.gsub(text,"<Module:FormatTemplate internal nowiki token>","<nowiki>"..nowikisafehouse[nw].."</now</nowiki>iki>",1)
    end
     -- preprocess as nowiki-bounded text
    return frame:preprocess("<nowiki>"..text.."</nowiki>" .. "\n" .. debuglog)
end

function p.format(frame)
    return p.main(frame,"format")
end

return p