local yesno = require('Module:Yesno')
local ordinal = require('Module:Ordinal')._ordinal

local p = {}

function p.style(pos, host)
	local style = (host and "border:3px solid red;" or '')
	if     pos == '1' then style = style .. "background-color:gold;"
	elseif pos == '2' then style = style .. "background-color:silver;"
	elseif pos == '3' then style = style .. "background-color:#CC9966;"
	elseif pos == '4' then style = style .. "background-color:#9ACDFF;"
	end
	return (style ~= '' and ('style="' .. style .. '" ') or '')
end

function p.sort_value(pos)
	local n = ''
	if     pos == '.'    then n = 999
	elseif pos == 'W'    then n = 998
	elseif pos == 'Q'    then n = 997
	else n = pos
	end
	return 'data-sort-value="' .. n .. '" '
end

function p.content(pos)
	if     tonumber(pos) then return ordinal(pos)
	elseif pos == '.'    then return "•"
	elseif pos == 'W'    then return "{{Tooltip|WD|Withdrew}}"
	elseif pos == 'Q'    then return "{{Tooltip|Q|Qualified}}"
	else return pos
	end
end

function p.cell(pos)
	local host = false
	if pos == nil then return '' end
	if mw.ustring.sub(pos, 1, 1) == 'H' then
		host = true
		pos = mw.ustring.sub(pos, 2)
	end
	return p.style(pos, host) .. p.sort_value(pos) .. '| ' .. p.content(pos)
end

function p.appeared(pos)
	return mw.ustring.sub(pos, 1, 1) == 'H' and tonumber(mw.ustring.sub(pos, 2)) or tonumber(pos)
end

function p.main(frame)
    -- If called via #invoke, use the args passed into the invoking template.
    if frame == mw.getCurrentFrame() then
        args = frame:getParent().args
    else
        args = frame.args
    end
    local result = '| style="text-align:left;" | {{quid|' .. args[1] .. '}} || '
	local appearances = 0
    for key, value in ipairs(args) do
    	if key ~= 1 then
    		result = result .. p.cell(value) .. ' || '
    		if p.appeared(value) then appearances = appearances + 1 end
    	end
    end
    result = result .. " '''" .. appearances .. "'''\n|-\n"
	return frame:preprocess(result)
end

return p