local p = {}

function p.factor(frame)
	-- Consider calling the parser function #expr
	--   to simplify a potential mathematical expression?
    number = tonumber(frame.args[1])
    if number == nil then
    	return '<strong class="error">Error: input not recognized as a number</strong>'
    end

    productSymbol = frame.args['product'] or '·'
    bold = frame.args['bold'] and true
    big = frame.args['big'] and true
    serif = frame.args['serif'] and true
    primeLink = frame.args['prime'] and true

    number = math.floor(number)
    if number < 2 or number > 1000000000 or number == math.huge then
        return '<strong class="error">Error: ' .. number .. ' out of range</strong>'
    end

    result = ""
    currentNumber = number
    power = 0
    divisor = 2

    -- Attempt factoring by the value of the divisor
    --   divisor increments by 2, except first iteration (2 to 3)
    while divisor <= math.sqrt(currentNumber) do
        power = 0
        while currentNumber % divisor == 0 do
            currentNumber = currentNumber / divisor
            power = power + 1
        end

		-- Concat result and increment divisor
		-- when divisor is 2, go to 3. All other times, add 2
		result = result .. powerformat(divisor, power, productSymbol)
        divisor = divisor + (divisor == 2 and 1 or 2)
    end

    if currentNumber ~= 1 then
        result = result .. currentNumber .. ' ' .. productSymbol .. ' '
    end

    if currentNumber == number and primeLink then
        return '[[prime number|prime]]'
    end

    result = string.sub(result,1,-4)

    return format(result)
end

function powerformat(divisor, power, productSymbol)
	if power < 1      then return ''
    elseif power == 1 then return divisor .. ' ' .. productSymbol .. ' '
    else return divisor .. '<sup>' .. power .. '</sup> ' .. productSymbol .. ' '
    end
end

function format(numString)
    if bold then
    	numString = '<b>'..numString..'</b>'
    end

	ret = (serif or big) and '<span ' or ''
	if serif then ret = ret .. 'class="texhtml" ' end
	if big   then ret = ret .. 'style="font-size:165%" ' end
	ret = ret .. ((serif or big) and '>' or '') .. numString .. ((serif or big) and '</span>' or '')

    return ret
end

return p