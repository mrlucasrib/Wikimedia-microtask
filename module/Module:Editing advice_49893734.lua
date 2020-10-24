local getArgs = require('Module:Arguments').getArgs
local p = {}

-- Fetch expansions of Editing advice meta templates
local function getRequestedAdvice(haystack, needle, pages)
	-- if a request is made for that advice
	if string.match(haystack, needle) then
		return mw.getCurrentFrame():expandTemplate{
					title = 'Editing advice/meta/' .. needle,
					args = pages or {}
			   }
	end
	return ''
end

-- Return concatenation of fetched template expansions
local function compileRequestedAdvice(about, pages)
	return getRequestedAdvice(about, 'preview', pages) ..
		   getRequestedAdvice(about, 'summary') ..
		   getRequestedAdvice(about, 'sandbox')
end

--[[ Main function: iterates through provided params and uses
		what is discovered to call for and organise the requested output ]]
function p._getAdvice(cleanargs)
	-- Create capturing vars for data
	local about = ''
	local pages = {}
	local section = {}
	local f = mw.getCurrentFrame()
	-- Iterate through provided params
	for key, value in pairs(cleanargs) do
		-- If the param specifies the advice requested
		if key == 'about' then
			-- store the value
			about = value
		-- If the param specifies the section heading option
		elseif key == 'section' then
			-- store the value
			section[1] = value
		else
		--[[ If neither of the above, these params must be pages
				 so store the values as they are processed ]]
			pages[#pages + 1] = value
		end
	end
	-- Output concatenation of fetched strings
	return f:expandTemplate{
				title = 'Editing advice/meta/start',
				args = section
		   } ..
		   compileRequestedAdvice(about, pages) ..
		   f:expandTemplate{
				title = 'Editing advice/meta/end'
		   }
end

--Get and cleanup frame args and pass them to _getAdvice
function p.getAdvice(frame)
	local args = getArgs(frame)
	return p._getAdvice(args)
end

return p