local p = {}

local MARKUP = {['default'] = '<span style="border:solid red 1px">%1</span>',
                ['yellow'] = '<span style="background:yellow">%1</span>',
                ['oval'] = '<span style="border:solid red 2px;border-radius:10px;padding:1px">%1</span>'}
                    
function p.main(frame)
	if frame then
        local parent = frame.getParent and frame:getParent()
        if parent and parent.args then
        	regex = parent.args[1] or parent.args['regex']
        	page = parent.args[2] or parent.args['page']
        	style = parent.args[3] or parent.args['style']
        end
        if frame.args then
        	regex = frame.args[1] or frame.args['regex']
        	page = frame.args[2] or frame.args['page']
        	style = frame.args[3] or frame.args['style']
        end
    else
    	return ''
    end
	if not page or mw.text.trim(page) == '' then
		page = frame:preprocess("{{FULLPAGENAME}}")
		if string.sub(page,-10,-1)  == '/highlight' then
			page = string.sub(page,1, -11)
		end
    end
    if style and mw.text.trim(style) ~= "" then
    else
    	style = "default"
    end
    local replace = MARKUP[style]
    -- OK, we now are searching for regex in page
    pageobject = mw.title.new(page)
    if not pageobject then return '' end
    text = pageobject:getContent()
    text = mw.ustring.gsub(text, "(" .. regex .. ")", replace)
    return frame:preprocess(text)
end

return p