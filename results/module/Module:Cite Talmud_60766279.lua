function inspect(str)
  str = tostring(str)
  local r = '"'
  for i = 1, #str do
    local c = string.byte(str:sub(i,i))
    if c > 32 and c < 127 then
      r = r .. str:sub(i,i)
    else
      r = r .. '&#' .. c .. ';'
    end
  end
  r = r .. '"'
  return r
end

function blanks_to_nil(template_args)
	for key, val in pairs(template_args) do
		if string.find(string.gsub(val, '&#32;', ''), '^%s*$') then
			template_args[key] = false
		end
	end
end

local talmud = {}

talmud.jb_key = {b = "Babylonian", y = "Jerusalem"}

function talmud.generate_citation(frame)
	local template_args = frame:getParent().args
	-- local invoke_args = frame.args -- parameters from {{#invoke:}}
	blanks_to_nil(template_args)
	jb       = template_args[1] or 'b'
	if not talmud.jb_key[jb] then
		str = frame:expandTemplate{ title = 'error', args = { 'First argument must be either b for Babylonian Talmud or y for Jerusalem Talmud. (Given ' .. inspect(jb) .. ')' } }
	end
    tractate = template_args[2]
    chapter  = template_args[3] -- Chapter name or number (optional)
    daf      = template_args[4] -- These are page or folio numbers as described at Talmud#Slavuta Talmud 1795 and Vilna Talmud 1835. Ranges are accepted, eg. 2b-4a
    url      = template_args['url']
    nobook   = template_args[5]
    if not url then
    	url = "https://www.sefaria.org/"
    	if(jb == 'y') then url = url .. 'Jerusalem_Talmud_' end 
    	url = url .. string.gsub(tractate, ' ', '_') .. '.' .. string.gsub(daf or '2a', ' ', '_')
    end
    -- str is only set if there has not been an error.
    if not str then
    	if nobook == 'yes' then
			str  = '[' .. url .. ' ' .. tractate .. ' ' .. ( daf or '' ) .. ']'
		else
			str = '[[Talmud]], <abbr title="' .. talmud.jb_key[jb] .. '">' .. jb .. '.</abbr> ['
			str = str .. url .. ' ' .. tractate .. ' ' .. ( daf or '' ) .. ']'
		end
	end
	return(str)
end

return talmud