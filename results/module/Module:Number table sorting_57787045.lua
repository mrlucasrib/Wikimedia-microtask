local lang = mw.language.getContentLanguage()
local Math = require('Module:Math')
local SortKey = require('Module:Sortkey')
-- constants
local INF = math.huge
local NEGINF = -math.huge
local MINUS = '−'  -- Unicode U+2212 MINUS SIGN (UTF-8: e2 88 92)

--------------------------------------------------------------------------------
-- Nts class
--------------------------------------------------------------------------------

local Nts = {}
Nts.__index = Nts

Nts.formats = {
	no = true,
	yes = true,
}

function Nts.new(args)
	local self = setmetatable({}, Nts)

	self:parseNumber(args[1])

	-- Set the format string
	self.format = args.format or 'yes'
	if not Nts.formats[self.format] then
		error(string.format(
			"'%s' is not a valid format",
			tostring(self.format)
		), 0)
	end
	
	-- To display some text before the display version of the number
	-- {{nts|123456789.00123|prefix=approx.&nbsp;}} → approx. 123,456,789.00123
	self.prefix = args.prefix or ''
	
	-- debug info
	self.debug = args.debug or 'no'
	self.quiet = args.quiet or 'no'

	return self
end


-- Parse the entered number
function Nts:parseNumber(s)
	-- sanitize
	s = s or '';
	s = string.gsub(s,'&minus;','-')
	s = string.gsub(s, MINUS, '-')
	self.rawNumberString = s
	
	-- fractions. was somewhat but completely broken at some point
	self.isFraction = (string.find(s, '/') ~= nil)
	if self.isFraction then
		error(string.format(
				"Fractions are not supported",
				tostring(s)
			), 0)
	end
	
	-- format detection
	self.isScientificNotation = (string.find(s, 'e') ~= nil)
	
	-- parse with language options
	self.number = lang:parseFormattedNumber(s)
	
	-- parse with fallback
	if not self.number then
		self.number = tonumber(s)
	end
	
	-- allow for empty string as a value
	if not self.number then
		-- error(string.format(
		-- 		"'%s' is not a valid number",
		-- 		tostring(s)
		-- 	), 0)
		self.number = NEGINF
	end
	
	if self.number < 0 then
		self.sign = MINUS
	else
		self.sign = ''
	end

	self.absNumber = math.abs(self.number)
	if self.absNumber ~= INF then
		self.magnitude = math.floor(math.log10(self.absNumber))
		self.significand = self.number / 10^self.magnitude
		self.precision = Math._precision(self.rawNumberString)
		self.integer = math.floor(self.absNumber)
		self.fractional = math.abs(self.number - self.integer)
	end
end

function Nts:makeDisplay()
	local ret ={}

	if self.quiet == 'yes' then
		return ''
	end

	ret[#ret + 1] = self.prefix
	local sciNotation = string.find(tostring(self.number),'e')
	if self.absNnumber == INF or isNaN(self.number) or self.magnitude ==nil or math.abs(self.magnitude) == INF then
		ret[#ret + 1] = string.gsub(self.rawNumberString, '-', MINUS)
	elseif sciNotation ~= nil or math.abs(self.magnitude) >= 9 then
		ret[#ret + 1] = self.sign
		if self.format == 'yes' then
			ret[#ret + 1] = lang:formatNum(math.abs(self.number * 10^-self.magnitude))
		else
			ret[#ret + 1] = math.abs(self.number * 10^-self.magnitude)
		end
		ret[#ret + 1] = '<span style="margin-left:0.2em">×<span style="margin-left:0.1em">10</span></span><s style="display:none">^</s><sup>'
		if self.magnitude<0 then
			ret[#ret + 1] = MINUS .. (-self.magnitude)
		else
			ret[#ret + 1] = self.magnitude
		end
		ret[#ret + 1] = '</sup>'
	else
		ret[#ret + 1] = self.sign
		if self.format == 'yes' then
			ret[#ret + 1] = Math._precision_format(self.absNumber, self.precision)
		else
			local newPrecision = Math._precision(self.absNumber)
			ret[#ret + 1] = tostring(self.absNumber)
			if newPrecision < self.precision then
				if self.integer == self.absNumber then
					ret[#ret + 1] = '.'
				end
				ret[#ret + 1] = string.rep('0', math.min(12, self.precision - newPrecision) )
			end
		end
	end
    return table.concat(ret) 
end

function Nts:makeSortKey()
	return SortKey._sortKeyForNumber(self.number) .. '♠'
end

function ifNaNThen(n,p)
	if isNaN(n) then
		return p
	end
	return n
end

function isNaN(n)
	return n ~= n
end

function Nts:renderTrackingCategories()
	if self.hasDeprecatedParameters then
		return '[[Category:Nts templates with deprecated parameters]]'
	else
		return ''
	end
end

function Nts:__tostring()
	local root = mw.html.create()
	local span = root:tag('span')
		:attr('data-sort-value', self:makeSortKey())

	if self.debug == 'yes' then
		span:tag('span')
			:css('border', '1px solid')
			:wikitext(self:makeSortKey())
	elseif self.quiet ~= 'no' then
		span:css('display', 'none')
	end

	-- Display
	if self.quiet == 'no' then
		span:wikitext(self:makeDisplay())
	end

	-- Tracking categories
	root:wikitext(self:renderTrackingCategories())

	return tostring(root)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

local p = {}

function p._exportClasses()
	return {
		Nts = Nts
	}
end

function p._main(args)
	local success, ret = pcall(function ()
		local nts = Nts.new(args)
		return tostring(nts)
	end)
	if success then
		return ret
	else
		ret = string.format(
			'<strong class="error">Error in [[Template:Nts]]: %s</strong>',
			ret
		)
		if mw.title.getCurrentTitle().namespace == 0 then
			-- Only categorise in the main namespace
			ret = ret .. '[[Category:Nts templates with errors]]'
		end
		return ret
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = { 'Template:Number table sorting' },
	})
	return p._main(args)
end

return p