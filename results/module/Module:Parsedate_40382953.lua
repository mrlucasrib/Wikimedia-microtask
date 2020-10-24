-- Helper functions for [[Template:Start date]]
-- This will accept a start_date returning a string that:
-- for a valid date, wraps a hidden copy of the date in ISO format in a microformat
-- returns start_date
-- See Module:Age for other date functions

local p = {}

-- This parses a valid date string into a Lua date table and returns a hidden microformat
-- Only valid for dates after 31 A.D.

p.parse_date = function(frame)
  local strdate = mw.text.trim(frame.args[1] or "")
  local invalid = false
  local wrd = {}
  local num = {} -- this is a list of indices of wrd where the value is a number < 32
  local yr = {}  -- this is a list of indices of wrd where the value is a number > 31
  local mth = {} -- this is a list of indices of wrd where the value is an alphabetical month

  for w in string.gmatch(strdate, "%w+") do
    -- catch numbers like '27th'
    local found1, found2 = string.find(w, "%d+")
    if found1 then w = string.sub(w, found1, found2) end
    -- now we can store what we found
    wrd[#wrd+1] = w
    if tonumber(w) then
      if tonumber(w) < 32 then num[#num+1] = #wrd else yr[#yr+1] = #wrd end
    end
    local s = string.sub(w, 1, 3) -- the first 3 chars of w
    local f1 = string.find("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", s, 1, true)
    if f1 then
      mth[#mth+1] = #wrd
      wrd[#wrd] = (f1 + 3)/4 -- replace Jan with 1, Feb with 2, etc.
    end
  end

  -- at this point #wrd contains the number of words and numbers and wrd contains the words and numbers
  -- num is an index of day or numeric month candidates
  -- yr is an index of year candidates
  -- mth is an index of alphabetic month candidates

  --  let's take out the garbage
  if not yr[1] then invalid = true end -- no year
  if not num[1] then invalid = true end -- no day
  if not mth[1] then
    -- no alpha month:
    if not num[2] then
      invalid = true -- no month
    else
      -- two numbers, but:
      if not yr[1] then
        invalid = true -- no year
      else
      -- two numbers and a year, but:
        if yr[1] > num[1] then invalid = true end -- year is not first, so date not in yyyy--mm--dd format
      end
    end
  end
  
  local msg -- the output string
  if invalid then
    msg = strdate
  else
    -- if we have an alpha month, then it's either dmy or mdy. Otherwise it may be yyyy-mm-dd:
    local ymddate
    local dt = {}
    if mth[1] then
      -- str_date contains an alpha month, so dmy or mdy work the same now.
      -- Put the first occurrence of each into the date table:
      dt.year = wrd[yr[1]]
      dt.month = wrd[mth[1]]
      dt.day = wrd[num[1]]
    else
      -- yyyymmdd has to have numeric month before numeric day
      dt.year = wrd[yr[1]]
      dt.month = wrd[num[1]]
      dt.day = wrd[num[2]]
    end
    ymddate = os.date("%Y-%m-%d", os.time(dt))
    msg = '<span style="display:none">&#160;(<span class="bday dtstart published updated">' .. ymddate .. '</span>)</span>' .. strdate
  end
  return msg
end

return p