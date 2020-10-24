-- For unit tests, see [[Module:NSW GNR/testcases]]
local p = {}
digit = {{"??", "JP", "Ma", "an", "uj", "TR", "SX", "KW", "Mn", "It"},
		 {"jL", "Kq", "qw", "IO", "ck", "Yb", "lp", "jt", "Ql", "wG"},
		 {"Wy", "vq", "lM", "wp", "BK", "oe", "Fx", "Xt", "jz", "Zx"},
		 {"rX", "ZT", "Km", "sE", "WA", "qb", "tL", "Ul", "sy", "xO"},
		 {"GH", "JP", "Ma", "an", "uj", "TR", "SX", "KW", "Mn", "It"}}

function p.convert(frame)
	converted = ""
	for i=1,5 do
	  if (#frame.args[1]>=i) then
        converted = converted .. digit[i][1+tonumber(string.sub(frame.args[1],i,i))]
      end
    end
    return converted
end
return p