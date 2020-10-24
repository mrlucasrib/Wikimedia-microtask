-- Low-overhead version of {{Subatomic particle|...}} to avoid exceeding
-- template include size at [[List of baryons]].

local particleTable, supsub

local function stripToNil(text)
	-- If text is a string, return its trimmed content, or nil if empty.
	-- Otherwise return text (which may, for example, be nil).
	if type(text) == 'string' then
		text = text:match('(%S.-)%s*$')
	end
	return text
end

local BREAK = "__BR__"

-- A group is a list of one or more particles with optional separating text.
-- Some items are defined with special meanings:
--   Parameter       Output
--    /               " / "
--    +               " + "
--    or              " or "
--    seen            " (seen) "
--    _word1_word2    " word1 word2" (wordN is any text)
--    (text)          "(text)" (text is any text)
--    br              "<br />" (and separates the group into logical lines)
-- Each logical line in the final text is in a nowrap span.
local Group
Group = {
	add = function (self, item)
		if item ~= nil then
			if item == BREAK then
				self:purgeCurrent()
			else
				self.nrCurrent = self.nrCurrent + 1
				self.current[self.nrCurrent] = item
			end
		end
	end,
	new = function ()
		return setmetatable({
			nrCurrent = 0,
			current = {},
			nrLines = 0,
			lines = {},
		}, Group)
	end,
	purgeCurrent = function (self)
		if self.nrCurrent > 0 then
			self.nrLines = self.nrLines + 1
			self.lines[self.nrLines] =
				'<span style="white-space:nowrap;">' ..
				table.concat(self.current) ..
				'</span>'
			self.nrCurrent = 0
			self.current = {}
		end
	end,
	text = function (self)
		self:purgeCurrent()
		return table.concat(self.lines, '<br />')
	end,
}
Group.__index = Group

local keyitems = {
	['/']    = " / ",
	['+']    = " + ",
	['or']   = " or ",
	['seen'] = " (seen) ",
	['br']   = BREAK,
}

local function expand(item, wantLink)
	-- Return text after expanding given item.
	-- Throw an error if item is not recognized.
	local function quit(reason)
		reason = reason or 'has an invalid definition'
		error('Particle "' .. item .. '" ' .. reason, 0)
	end
	local function su(sup, sub, align)
		local options = {
			align = align,
			lineHeight = '1.0em',
		}
		return supsub(sup, sub, options)
	end
	local kw = keyitems[item]
	if kw then
		return kw
	end
	if item:sub(1, 1) == '_' then
		return item:gsub('_', ' ')
	end
	if item:sub(1, 1) == '(' and item:sub(-1) == ')' then
		return item  -- no space wanted
	end
	local particle = particleTable[item:lower()] or quit('is not defined')
	local prefix, suffix
	if wantLink then
		prefix = '[[' .. (particle.link or quit('has no link defined')) .. '|'
		suffix = ']]'
	else
		prefix = ''
		suffix = ''
	end
	local symbol = particle[1] or quit('has no symbol defined')
	if particle.anti then
		symbol = '<span style="text-decoration:overline;">' .. symbol .. '</span>'
	end
	return
		prefix ..
		su(particle.TL, particle.BL, 'r') ..
		symbol ..
		su(particle.TR, particle.BR, 'l') ..
		suffix
end

local function main(frame, wantLink)
	-- Arguments are passed using #invoke in an article to avoid double-expansion.
	local sandbox = frame:getTitle():find('sandbox', 1, true) and '/sandbox' or ''
	particleTable = mw.loadData('Module:Particles/data' .. sandbox).particles
	supsub = require('Module:Su')._main
	local group = Group.new()
	for _, arg in ipairs(frame.args) do
		arg = stripToNil(arg)
		if arg then
			group:add(expand(arg, wantLink))
		end
	end
	return group:text()
end

local function link(frame)
	return main(frame, true)
end

local function nolink(frame)
	return main(frame, false)
end

return {
	link = link,
	nolink = nolink,
}