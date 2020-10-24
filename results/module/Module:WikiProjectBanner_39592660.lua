-------------------------------------------------------------------------------
--                               WikiProjectBanner                           --
--                                                                           --
-- This module produces templates used by WikiProjects to track pages that   --
-- are within their scope.                                                   --
-------------------------------------------------------------------------------

-- Load necessary modules.
require('Module:No globals')
local Banner = require('Module:WikiProjectBanner/Banner')

local p = {}

function p._main(bannerName, args, cfg)
	-- Entry point from Lua.
	cfg = cfg or mw.loadData('Module:WikiProjectBanner/config')

	-- Set a metatable allowing us to track unused arguments.
	local unusedArgs, argsProxy = {}, {}
	for k, v in pairs(args) do
		unusedArgs[k] = true
	end
	setmetatable(argsProxy, {
		__index = function (t, key)
			unusedArgs[key] = nil
			local val = args[key]
			t[key] = val
			return val
		end,
		__pairs = function (t)
			for key, val in pairs(args) do
				unusedArgs[key] = nil
				t[key] = val
			end
			return next, t
		end,
		__ipairs = function (t)
			for i, val in ipairs(args) do
				unusedArgs[i] = nil
				t[i] = val
			end
			return function (t, i)
				i = i + 1
				local val = t[i]
				if val then
					return i, val
				end
			end, t, 0
		end
	})

	local success, bannerObj = pcall(Banner.new, bannerName, argsProxy, cfg)
	if not success then
		return string.format(
			'<strong class="error">Error: %s</strong>',
			bannerObj -- This is the error message.
		)
	end

	local ret = tostring(bannerObj)

	if next(unusedArgs) then
		ret = ret .. '[[Category:WikiProject banners with unused arguments]]'
	end

	return ret
end

function p.main(frame)
	-- Entry point from wikitext.

	-- Get the banner name.
	local parent = frame:getParent()
	local bannerName, isTemplate = parent:getTitle():gsub('^Template:', '')
	bannerName = bannerName:gsub('/sandbox$', '')
	isTemplate = isTemplate > 0

	-- Get the arguments.
	local args = {}
	for k, v in pairs(parent.args) do
		v = v:match('^%s*(.-)%s*$') -- Trim whitespace.
		if v ~= '' then
			args[k] = v
		end
	end

	-- Subst check.
	-- This must be done before any errors can be produced, otherwise the red
	-- "script error" text will be substituted instead of the template code.
	if mw.isSubsting() then
		local ret = {}
		ret[#ret + 1] = bannerName
		for k, v in pairs(args) do
			ret[#ret + 1] = k .. '=' .. v
		end
		return '{{' .. table.concat(ret, '|') .. '}}'
	end

	-- Check we are being invoked from a template.
	if not isTemplate then
		error('this module must be invoked from within a template')
	end

	return p._main(bannerName, args)
end

return p