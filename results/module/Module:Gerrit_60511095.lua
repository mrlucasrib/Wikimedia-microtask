local p = {}

p.link = function (frame)
	local hash = frame.args[1]
	local length = string.len(hash)
	
	if not string.match(hash, '^I?%x+$' ) then
		return hash
	end
	local text
	if length > 14 then
		text = string.format("%.7s", hash)
	else
		text = hash
	end
	
	local url
	if length > 6 then
		-- query
		url = 'https://gerrit.wikimedia.org/r/q/' .. mw.uri.encode(hash)
    else
    	-- probably a change
    	url = 'https://gerrit.wikimedia.org/r/c/' .. hash .. '/'
    end
        	
    return '<span class=plainlinks style="font-family: Consolas, Liberation Mono, Courier, monospace; text-decoration: none;">[' .. url .. ' ' .. text .. ']</span>'
end
return p