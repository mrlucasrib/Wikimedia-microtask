-- Generate Ulam spiral based on primes, fibonacci, triangular numbers etc.
-- Gts@el wiki, Sep. 2017

local p = {}

-- determine whether number is prime
-- params: n (number)
-- return: boolean
local function is_prime(n)
    for i = 2, n^(1/2) do
        if (n % i) == 0 then
            return false
        end
    end
    return true
end

-- determine whether number is triangular
-- params: n (number)
-- return: boolean
local function is_triangular(n)
   x = (math.sqrt(8*n + 1) - 1) / 2
   return (x % 1 == 0)
end

-- determine whether number is part of standard fibonacci sequence
-- params: n (number)
-- return: boolean
local function is_fib(n)
    if n == 0 then
      return true
    end

    phi = 0.5 + (0.5 * math.sqrt(5.0))
    a = phi * n
    return math.abs(math.floor(a+0.5) - a) < 1.0 / n
end

-- determine total divisors of a number
-- params: n (number)
-- return: int
local function divisors(n)
    limit = n;
    total = 0;

    if n == 1 then
       return 1
    end

    for i = 1, limit-1 do
        if n % i == 0 then
            limit = n / i
            if limit ~= i then
               total = total + 1
            end

            total = total + 1
        end
    end

    return total
end

-- CSS border for cells in order to recreate spiral
-- params: row (number), column (number), size (number)
-- return string
function border(row, column, size)

   local on = 'solid '
   local top, left, right, bottom = 'none ', 'none ', 'none ', 'none '
   local last = size - 1 

   if column == math.floor(size/2) and row == column then
       bottom = on
   elseif row == math.floor(size/2) and column==row+1 then
       bottom=on
       right=on
   end 

   if row < column and column < last - row then
      bottom = on
   elseif row > column and row < last - column then
      right = on
   elseif row >= column-1 and row < last and row > size/2 then
      bottom = on

      if column == row + 1 and column < last then
        right = on
      end 
   elseif column>row and column < last then
      right = on
   end 

   result = top .. right .. bottom .. left
   result = result:gsub("%s$", "") 

   return result

end


-- convert values to wikitable. The wikitable string is preproccessed in frame.
-- params: data (dictionary), size (int), fontSize (int)
-- return: string object
local function wikitable(data, size, fontSize)
	local fontSize = '1' --em
    if tonumber(size) > 15 and tonumber(size) <=30 then
    	fontSize = '0.8'
    elseif tonumber(size) > 30 and tonumber(size) <= 45 then
    	fontSize = '0.6'
    elseif tonumber(size) > 45 and tonumber(size) <= 60 then
    	fontSize = '0.4'
    elseif tonumber(size) > 60 then   
    	fontSize = '0.2'
    end
	
	local result = '{| style="font-size:' .. fontSize .. 'em;text-align:center;border-spacing:0px"'

    -- background colour of a number corresponding to number of divisors
    divi = {
                 [2] = '#8080ff',
                 [3] = '#80ff80',
                 [4] = '',
                 [5] = '',
                 [6] = '',
                 [7] = '',
                 [8] = '',
                 [9] = '',
               }

    -- create wikitable
	for row=0, size-1 do
		result = result .. '\n|-\n|'
		for column=0, size-1 do
            if column > 0 then
               result = result .. '||'
            end

            number = data[row .. ':' .. column]
            bgcolor =''

			divtotal = divisors(number)
            if divtotal >= 47 then
              bgcolor = '#ff8080'
            else
              bgcolor = tostring(divi[divtotal])
            end
            
            result = result .. 'title="' .. math.floor(number) .. '" style="border-color:#9e9e9e;border-size:1px;border-style:' .. border(row, column, size) ..  ';background-color:'.. bgcolor .. ';color:black"|'
            --result = result .. 'title="' .. math.floor(number) .. '" style="border-radius:50%;background-color:'.. bgcolor .. ';color:black !important"|'

            number = math.floor(data[row .. ':' .. column])
 			--if bgcolor ~= '' and bgcolor ~= 'nil' then
 				result = result .. '[[' ..	number .. ' (number)|' .. number .. ']]'
            --else  		
 			--    result = result .. number
 			--end
        end
	end

	result = result .. '\n|}'

    -- preprocess string in frame and render table
    local frame = mw.getCurrentFrame()
 	result = frame:preprocess(result)

	return result
end

-- calculate ulam spiral value for each x,y tabular point.
-- algorithm concept based on Python version at GPL 3 https://rosettacode.org/wiki/Ulam_spiral_(for_primes)#Python
-- use of bitwise ops was attempted but Mediawiki Scribunto Lua doesn't seem to like them
-- params: n (int), x (int), y (int), start (int)
-- return: int
local function cell(n, x, y, start)
	local d = 0

	local x = x - math.floor((n - 1) /2)
	local y = y - math.floor(n / 2)

	l = 2 * math.max(math.abs(x), math.abs(y))

	if y <= x then
		d = (l*3) + x + y
	else
		d = l - x - y
	end

	return math.pow(l - 1, 2) + d + start - 1
end

-- prepare spiral display for output type (i.e. wikitable, coords only, etc)
-- params: size (int), start (int)
-- return: mixed
local function show_spiral(size, start)
   local result = {}

   for i=0, size-1 do
       for x=0, i do
         for y=0, i do
           result[x .. ':' .. y] = cell(size, x, y, start)
         end
      end
   end

   return wikitable(result, size)
end

-- main
-- params: frame
-- return: mixed
function p.ulam(frame)
	local size = tonumber(frame.args[1])
	local start = tonumber(frame.args[2])
    
    if size > 75 then
       return '<span style="font-family:Roboto;">The maximum allowed size is 75x75</span>'	
    end
    
	return show_spiral(size, start)
end

return p