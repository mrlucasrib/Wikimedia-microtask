--- This module is supposed to take all the normal File:/Image: parameters from the call
--- to a parent template (though it will might use its own args in preference for debug purposes)
--- and return them back one by one for use by a template.  Most important, figure which is the caption.
--- (This is a bit experimental - I haven't really ''used'' the parent .args much, 
--- and there's a chance the whole template will just get wrapped up into one Lua script in the end)
--- usage: {{#invoke Pseudo-image:main|thumb}}, etc.

local p={}

function initialize(frame)
    local parent=frame:getParent() or {}
    local args=frame.args or {}
    local pargs=parent.args or {}
    return args,pargs
end

function p.main(frame,query)
    local args,pargs=initialize(frame)
    local query=query or args.query or pargs.query -- this leaves the door open for specifying query as a function
    local showdebug=args.debug or pargs.debug -- wasn't shutting off under name "debug"...
    local thumb,frame,px,float,border,vertical
    local debuglog=#pargs or "no#pargs"
    local debuglog=debuglog.."q="..tostring(query)
    local floatoptions = {left=true,right=true,center=true,none=true}
    local verticaloptions = {baseline=true,middle=true,sub=true,super=true,['text-top']=true,['text-bottom']=true,top=true,bottom=true}
    local default = {float='right',vertical='middle'}
    local output={}
    debuglog=debuglog..tostring(default['float'])
    for i, parm in ipairs(pargs) do
            debuglog=debuglog..i..tostring(pargs[i])
            local parm=pargs[i] or ""
            parm=mw.ustring.match(parm,"^%s*(%S.*)$") or parm -- strip leading space (not sure if there can be any)
            parm=mw.ustring.match(parm,"^(.*%S)%s*") or parm -- strip lagging space (" " ")
            if parm == "thumb" or parm == "thumbnail" then
                output.thumb = "yes"
            elseif parm == "frame" then
                output.frame = true
            elseif floatoptions[parm] then
                output.float = parm
            elseif parm == "border" then
                output.border = true -- technically this may need fine-tuning - does thumb with border make "border" the caption?
            elseif verticaloptions[parm] then
                output.vertical = parm
            elseif mw.ustring.match(parm,"^(%d+)px$") then
                output.px = mw.ustring.match(parm,"(%d+)px") -- there must be a better way to do this two-liner
            elseif mw.ustring.match(parm,"^(%d*)x(%d+)px$") then
                output.px,output.xpx = mw.ustring.match(parm,"^(%d*)x(%d+)px$") -- " "
            else output.caption = output.caption or parm
                 if output.caption == "" then output.caption = nil end -- for now I choose to auto-rescue if the caption isn't the first unidentified misc parameter
            end -- the mess of cases
    end -- for i,parms in ipairs(pargs)
    for k,v in pairs(pargs) do
        output[k]=v
    end
    for k,v in pairs(args) do --- note these allow the pseudo-parameters to be overridden in the Lua call
        output[k]=v
    end
    if showdebug then return debuglog..tostring(default[query])..tostring(output[query]) else return output[query] or default[query] end
end

return p