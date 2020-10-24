-- This module powers {{interval}}.

local p = {}

-- Constants
local lang = mw.language.getContentLanguage()
local getArgs = require('Module:Arguments').getArgs

local function getArgNums(args)
    -- Returns an array containing the keys of all positional arguments
    -- that contain data (i.e. non-whitespace values).
    -- (from Module:Unbulleted_list)
    local nums = {}
    for k, v in pairs(args) do
        if type(k) == 'number' and
            k >= 1 and
            math.floor(k) == k and
            mw.ustring.match(v, '%S') then
                table.insert(nums, k)
        end
    end
    table.sort(nums)
    return nums
end

function p.main(frame)
    local args = getArgs(frame)
    return p._main(args)
end

function p._main(args)
    local n, rule, format = args.n, args.rule, args.format
    local numbers = getArgNums(args)
    local low, high, lowpos, highpos = nil, nil, 0, #numbers + 1

    -- If comparing times, convert them all to seconds after the epoch
    if format == 'time' then
        if n then
            n = lang:formatDate('U', '@' .. n)
        else
            n = os.time() -- Set n to now if no time provided
        end
    end

    n = tonumber(n)

    for i, num in ipairs(numbers) do
        local interval
        if format == 'time' then
            interval = tonumber(lang:formatDate('U', '@' .. args[num]))
        else
            interval = tonumber(args[num])
        end

        if n and ((n >= interval and not rule) or (n > interval and rule == '>')) then
            low = interval
            lowpos = num
        else
            high = high and math.min(interval, high) or interval
            if high == interval then highpos = num end
        end
    end
    return lowpos .. '-' .. highpos
end

return p