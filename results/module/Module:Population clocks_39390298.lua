--require "math"

local z = {}

function MJDN(date)
    local floor = math.floor
    local a = floor((14 - date.mon) / 12)
    local y = date.year + 4800 - a
    local m = date.mon + 12 * a - 3
    return date.day + floor((153 * m + 2) / 5) + 365 * y + floor(y / 4) - floor(y / 100) + floor(y / 400) - 2432046
end

function dayssince(epoch, now)
    return MJDN(now) - MJDN(epoch)
end

-- The population clock for India uses these data:
-- -- According to the 2011 census there were 1,21,01,93,422 people on 2011-03-01 00:00:00 +0530.
-- -- According to the 2011 census the 2001-2011 decadal growth rate was 17.64%.
-- Growth is slowing according to the census, so this is an OVER-estimate.
-- http://censusindia.gov.in/2011-prov-results/PPT_2.html
function z.india (frame)
    local pframe = frame:getParent()
    local args = pframe.args -- the arguments passed TO the template, in the wikitext that instantiates the template
    local config = frame.args -- the arguments passed BY the template, in the wikitext of the template itself
    local now = { year=config.as_of_year, mon=config.as_of_month, day=config.as_of_day }
    return 1210193422 + 58455.12 * dayssince({year=2011,mon=2,day=28}, now)
end

return z