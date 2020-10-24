local p = {}

local function getcontents(frame,country,params)
  return frame:expandTemplate({title="Country data "..country;args=params})
end

function p.gettable(frame,country,params)
--Returns the parameters of a country data template as a Lua table
  --If not a valid data template, return empty table
  local bool, s = pcall(getcontents,frame,country,params or {})
  if bool and (string.find(s,"^%{%{ *%{%{%{1") or string.find(s,"^%{%{safesubst: *%{%{%{1"))
  then
    --Replace parameter delimiters with arbitrary control characters
    --to avoid clashes if param values contain equals/pipe signs
    s = string.gsub(s,"|([^|=]-)=","\1\1%1\2")
    s = string.gsub(s,"}}%s*$","\1")
    --Loop over string and add params to table
    local part = {}
    for par in string.gmatch(s,"\1[^\1\2]-\2[^\1\2]-\1") do
      local k = string.match(par,"\1%s*(.-)%s*\2")
      local v = string.match(par,"\2%s*(.-)%s*\1")
      if v and not (v=="" and string.find(k,"^flag alias")) then
        part[k] = v
      end
    end
    return part
  else
  	return {}
  end
end

function p.getalias(frame)
--Returns a single parameter value from a data template
  local part = p.gettable(frame,frame.args[1])
  if frame.args.variant
    then return tostring(part[frame.args[2].."-"..frame.args.variant]
                         or part[frame.args[2]] or frame.args.def)
    else return tostring(part[frame.args[2]] or frame.args.def)
  end
end

function p.gettemplate(frame)
--For testing, recreates the country data from the created Lua table
  --Get data table
  local data = p.gettable(frame,frame.args[1])
  --Concatenate fields into a template-like string
  local out = "{{ {{{1}}}"
  for k,v in pairs(data) do
    out = out.."\n| "..k.." = "..v
  end
  return out.."\n}}"
end

return p