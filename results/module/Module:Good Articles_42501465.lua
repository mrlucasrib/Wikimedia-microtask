local p = {}

p.main = function (frame)
	local NNN = 2 -- provide counts only over this threshold
	local args = require("Module:Arguments").getArgs(frame)
	-- expect args.shortcut e.g. GA/H, args.type e.g. History, args.text a long list
	local subpage = frame:preprocess("{{SUBPAGENAME}}") -- I never did look up if there's a better way to do this...
	local header = ""
	local shortcuts = ""
	local type = args.type or "error: specify type = Good Articles type"
	local image = ''
	if args.image then image = '[[' .. args.image .. '|22px|left]]' end
	local sectioncount = 0
	if (subpage == type or args.override) then -- I haven't figured out how to deal with missing shortcut so why pretend
		shortcuts = frame:expandTemplate{ title = 'shortcut', args = { args.shortcut } }
		header = frame:expandTemplate{ title = 'Wikipedia:Good articles/header', args = { shortcuts = shortcuts } }
    end
    local introtext = args.text or ''
    replace = function(t)
        local xxxx, links = mw.ustring.gsub(t, "(%[%[[^%[%]]-%]%])", "%1", nil) -- count how many links
        if links >= NNN then
            t = t .. "<small> (" .. tostring(links) .. "&nbsp;articles)</small>"
        end
        return t .. "\n"
    end
    local sectionfooter = [===[
</div>
</div>
<!-- end of list -->]===]
    -- comments in the text below are historical from the page's own markup
    local output = header .. [===[<!-- only include header on this page -->
__NOTOC__
<div style="clear:both;">
<!-- DO NOT REMOVE THIS DIV, USED TO FORCE IE TO DISPLAY BACKGROUND FOR ARTS DIV -->
</div>
<div style="clear:both;">
<span id="]===] .. type .. [===[" ></span>
<div style="padding:5px 5px 8px 5px; background-color:#66CC66; text-align:left; font-size:larger;">]===] .. image .. [===[''']===] .. type .. [===['''</div>
<div style="text-align:left;">
</div>
</div>
]===] .. introtext
    local section = 0
    local finaltext = ''
    repeat
    	local wrap = true
    	section = section + 1
        local text = (args['section' .. tostring(section)] or args[section] or '')
        local title = args['title' .. tostring(section)]
    	if (not title) then
    		if (text == '') then
    			break
            else
    		    local wrap = false
    		    output = output .. text  -- sections without headers go in unwrapped
    	    end
    	else
    		local image = args['image' .. tostring(section)]
            text = mw.ustring.gsub(text .. "\n=", "(==.-)\n%s*%f[=]", replace)
            text = mw.ustring.sub(text,1,-2) -- ditching "=" mark from line above
    	    if (image) then 
    		    image = '[[' .. image .. '|22px|left]]'
    	    else
    		    image = '' -- make section without an image
    	    end
    		output = output .. [===[<div style="clear:both;" class="NavFrame">
<span id="World history"></span>
<div class="NavHead" style="padding:2px 2px 2px 30px; background-color:#FFFAF0; text-align:left; font-size:larger;">]===] .. image .. title .. [===[</div>
<div class="NavContent" style="text-align:left;">

==&shy;&nbsp;==
]===] .. text .. sectionfooter
        end
    until false
    return output
end

function p.subsection(frame)
	if not mw.ustring.find( (frame.args[1] or frame:getParent().args[1] or '') ,'[[',1,true) then
		return '<small>(0&nbsp;articles)</small>'
	else
		local linkList, count = mw.ustring.gsub(mw.text.trim(frame.args[1] or frame:getParent().args[1]), '\n', '&nbsp;–\n')
		return linkList .. '<small>&nbsp;&nbsp;(' .. (count + 1) .. '&nbsp;article' .. ( (count ~= 0) and 's' or '') .. ')</small>'
	end
end

return p