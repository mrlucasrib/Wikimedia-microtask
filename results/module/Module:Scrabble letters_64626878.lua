local p = {}
blank_label = "[blank]"
freq_symbol = "×"

function BuildArray(iterator)
	local arr = {}
	for v in iterator do
		arr[#arr + 1] = v
	end
	return arr
end

function p.SortTilesByScore(a,b)
	if a.score ~= b.score then
		return tonumber(a.score) < tonumber(b.score)
	end
	if a.freq ~= b.freq then
		return tonumber(a.freq) < tonumber(b.freq)
	end
	return a.label < b.label
end

function p.ReadArgs(args)
	local tiles = {}
	local lang = ""
	if args.blanks then
		tiles[1] = {label=blank_label, freq=args.blanks, score="0"}
	end
    for k,v in pairs(args) do
    	if k == "lang" then
    		lang = v
    	end
    	local parts = BuildArray(string.gmatch(v, "[^,]+"))
    	if #parts == 3 then
			tiles[#tiles + 1] = {label=parts[1], freq=parts[2], score=parts[3]}
    	end
    end
    return tiles, lang
end

function p.LinkWrap(str, args)
	local res = ""
	if args.links and str ~= blank_label then
		res = "[["
	end
	res = res .. str
	if args.links and str ~= blank_label then
		res = res .. "]]"
	end
	return res
end

function p._list(frame)
	local score = -1
	local res = ""
	local tiles = p.ReadArgs(frame.args)
   	table.sort(tiles, p.SortTilesByScore)

	for k,v in ipairs(tiles) do
		if score ~= v.score then
			if #res > 1 then
				res = res .. "\n"
			end
			res = res .. "*"
			if v.label == blank_label then
				res = res .. v.freq .. " blank tiles (scoring " .. v.score .. " points)"
			else
				res = res .. "''" .. v.score .. " point"
				if v.score ~= "1" then
					res = res .. "s"
				end
				res = res .. "'': "
				score = v.score
			end
		else
			res = res .. ", "
		end
		if v.label ~= blank_label then
			res = res .. "'''" .. p.LinkWrap(v.label, frame.args) .. "''' " .. freq_symbol .. v.freq
		end
	end
	return res
end

function p._table(frame)
	local res
	local score
	local i
	local freq
	local sorted_freq = {}
	local tiles, lang = p.ReadArgs(frame.args)

   	freq = -1
	table.sort(tiles, function(a,b) return tonumber(a.freq) < tonumber(b.freq) end)
   	for k,v in ipairs(tiles) do
   		if freq ~= v.freq then
   			sorted_freq[#sorted_freq + 1] = v.freq
   			freq = sorted_freq[#sorted_freq]
   		end
   	end
   	table.sort(sorted_freq, function(a,b) return tonumber(a) < tonumber(b) end)
   	res = "!"
   	for k,v in ipairs(sorted_freq) do
   		res = res .. " !! " .. freq_symbol .. v
   	end
   	table.sort(tiles, p.SortTilesByScore)
   	score = -1
   	i = 1
   	for k,v in ipairs(tiles) do
   		if score ~= v.score then
   			-- This fills in empty cells after the end of a row. Is this necessary?
   			while i < #sorted_freq and k > 1 do
   				res = res .. "|| "
	   			i = i + 1
   			end
   			res = res .. "\n|-\n! " .. v.score .. "\n| "
   			score = v.score
   			i = 1
   		end
   		while sorted_freq[i] ~= v.freq and i <= #sorted_freq do
   			res = res .. "|| "
   			i = i + 1
   		end
   		res = res .. p.LinkWrap(v.label, frame.args) .. " "
   	end
   	while i < #sorted_freq do
   		res = res .. "|| "
		i = i + 1
   	end
    return res
end

function p.table(frame)
	return p._table(frame:getParent())
end

function p.list(frame)
	return p._list(frame:getParent())
end

return p