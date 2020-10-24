data = require("Module:Format ISBN/data")
local p = {}

function errMsg(s)
	return '<span class="error">Can&#x27;t format invalid ISBN: '..s..'</span>'
end

function p.formatISBN(s, link)
	if link == nil then link = true end
	if (not s) or (#s == 0) then return '' end
	s = tostring(s) -- some other module may have fed us an unquoted number
	local test = require("Module:Check isxn").check_isbn({ args = { s, error = errMsg(s) }})
	if #test > 0 then return test end
	local s = string.gsub(s, "[^%dX]", "")
	if #s == 10 then
		s = string.sub("978"..s, 1, 12)
		local n = 0
		for i=1,12 do n = n + tonumber(string.sub(s,i,i)) * (3 - (i % 2) * 2) end
		s = s..((10-(n%10))%10)
	end		
	for i=1,#data do
		if s <= data[i][1] then
			local a = 4
			local r = { string.sub(s,1,3) }
			for j=1,3 do
				local n = data[i][2][j]
				r[j+1] = string.sub(s, a, a+n-1)
				a = a + n
			end
			r[5] = string.sub(s,13)
			local sFmt = table.concat(r, "-")
			if link then return '[[Special:BookSources/'..s..'|'..sFmt..']]'
			else return sFmt end
		end
	end
	return s -- should never actually be reached
end

function p.main(frame)
	local args = require("Module:Arguments").getArgs(frame)
	local isbn = args[1]
	local link = string.sub(string.lower(args["link"] or "yes"), 1, 1) ~= "n"
	return p.formatISBN(isbn, link)
end

return p