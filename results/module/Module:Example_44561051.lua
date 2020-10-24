local p = {};     --All lua modules on Wikipedia must begin by defining a variable 
                    --that will hold their externally accessible functions.
                    --Such variables can have whatever name you want and may 
                    --also contain various data as well as functions.
p.hello = function( frame )     --Add a function to "p".  
                                        --Such functions are callable in Wikipedia
                                        --via the #invoke command.
                                        --"frame" will contain the data that Wikipedia
                                        --sends this function when it runs. 
                                 -- 'Hello' is a name of your choice. The same name needs to be referred to when the module is used.
    
    local str = "Hello World!"  --Declare a local variable and set it equal to
                                --"Hello World!".  
    
    return str    --This tells us to quit this function and send the information in
                  --"str" back to Wikipedia.
    
end  -- end of the function "hello"
function p.hello_to(frame)		-- Add another function
	local name = frame.args[1]  -- To access arguments passed to a module, use `frame.args`
							    -- `frame.args[1]` refers to the first unnamed parameter
							    -- given to the module
	return "Hello, " .. name .. "!"  -- `..` concatenates strings. This will return a customized
									 -- greeting depending on the name given, such as "Hello, Fred!"
end
function p.count_fruit(frame)
	local num_bananas = frame.args.bananas -- Named arguments ({{#invoke:Example|count_fruit|foo=bar}}) are likewise 
	local num_apples = frame.args.apples   -- accessed by indexing `frame.args` by name (`frame.args["bananas"]`, or)
										   -- equivalently `frame.args.bananas`.
	return 'I have ' .. num_bananas .. ' bananas and ' .. num_apples .. ' apples'
										   -- Like above, concatenate a bunch of strings together to produce
										   -- a sentence based on the arguments given.
end

local function lucky(a, b) -- One can define custom functions for use. Here we define a function 'lucky' that has two inputs a and b. The names are of your choice.
	if b == 'yeah' then -- Condition: if b is the string 'yeah'. Strings require quotes. Remember to include 'then'.
		return a .. ' is my lucky number.' -- Outputs 'a is my lucky number.' if the above condition is met. The string concatenation operator is denoted by 2 dots.
	else -- If no conditions are met, i.e. if b is anything else, output specified on the next line.  'else' should not have 'then'.
		return a -- Simply output a.
	end -- The 'if' section should end with 'end'.
end -- As should 'function'.

function p.Name2(frame)
	-- The next five lines are mostly for convenience only and can be used as is for your module. The output conditions start on line 20.
	local pf = frame:getParent().args -- This line allows template parameters to be used in this code easily. The equal sign is used to define variables. 'pf' can be replaced with a word of your choice.
	local f = frame.args -- This line allows parameters from {{#invoke:}} to be used easily. 'f' can be replaced with a word of your choice.
	local M = f[1] or pf[1] -- f[1] and pf[1], which we just defined, refer to the first parameter. This line shortens them as 'M' for convenience. You could use the original variable names.
	local m = f[2] or pf[2] -- Second shortened as 'm'.
	local l = f.lucky or pf.lucky -- A named parameter 'lucky' is shortend as l. Note that the syntax is different from unnamed parameters.
	if m == nil then -- If the second parameter is not used.
		return 'Lonely' -- Outputs the string 'Lonely' if the first condition is met.
	elseif M > m then -- If the first condition is not met, this line tests a second condition: if M is greater than m.
		return lucky(M - m, l) -- If the condition is met, the difference is calculated and passed to the the self defined function along with l. The output depends on whether l is set to 'yeah'.
	else
		return 'Be positive!'
	end
end

return p    --All modules end by returning the variable containing their functions to Wikipedia.
-- Now we can use this module by calling {{#invoke: Example | hello }},
-- {{#invoke: Example | hello_to | foo }}, or {{#invoke:Example|count_fruit|bananas=5|apples=6}}
-- Note that the first part of the invoke is the name of the Module's wikipage,
-- and the second part is the name of one of the functions attached to the 
-- variable that you returned.

-- The "print" function is not allowed in Wikipedia.  All output is accomplished
-- via strings "returned" to Wikipedia.