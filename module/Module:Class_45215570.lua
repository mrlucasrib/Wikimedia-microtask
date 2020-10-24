-- This module implements [[Template:Class]], [[Template:Class/icon]] and
-- [[Template:Class/colour]].

local mArguments, mIcon -- modules to lazily load
local definitions = mw.loadData('Module:Class/importDefinitions')

local p = {}

-- Initialize helper function variables
local getDefinition, getRawArgs, makeInvokeFunction, normalizeValue

--------------------------------------------------------------------------------
-- Argument helper functions
--------------------------------------------------------------------------------

function getRawArgs(frame, wrapper)
	mArguments = mArguments or require('Module:Arguments')
	return mArguments.getArgs(frame, {
		wrappers = wrapper,
		trim = false,
		removeBlanks = false
	})
end

function makeInvokeFunction(func, wrapper)
	return function (frame)
		local args = getRawArgs(frame, wrapper)
		return func(args)
	end
end

--------------------------------------------------------------------------------
-- String helper functions
--------------------------------------------------------------------------------

function trim(str)
	if type(str) == 'string' then str = str:match('^%s*(.-)%s*$') end
	return str
end

function normalizeValue(val)
	if type(val) == 'string' then val = trim(val):lower() end
	if val == '' then val = nil end
	return val
end

function ucfirst(str)
	return mw.ustring.upper(mw.ustring.sub(str, 1, 1)) .. mw.ustring.sub(str, 2)
end

--------------------------------------------------------------------------------
-- Definition helper functions
--------------------------------------------------------------------------------

function getDefinition(code)
	local canonicalCode = normalizeValue(code)
	if code == 'DEFAULT' then canonicalCode = code end --DEFAULT special-case
	local class = definitions[canonicalCode]
	while class and class.alias do
		canonicalCode = class.alias
		class = definitions[class.alias]
	end
	if not class then
		return nil, nil
	end
	return class, canonicalCode
end

function getDefault() return getDefinition('DEFAULT') end

function getProperty(class, default, map)
	local pop = table.remove(map, 1)
	local prop, dProp = class and class[pop], default and default[pop]
	while #map > 0 do
		pop = table.remove(map, 1)
		prop = ((type(prop) == 'table') or nil) and prop[pop]
		dProp = ((type(dProp) == 'table') or nil) and dProp[pop]
	end
	if prop == nil then prop = dProp end
	return prop
end

--------------------------------------------------------------------------------
-- Color functions
--------------------------------------------------------------------------------

function p._colour(code)
	return getProperty(getDefinition(code), getDefault(), {'colour', 'base'})
end

function p.colour(frame)
	local args = getRawArgs(frame, 'Template:Class/colour')
	local colour = p._colour(args[1])
	-- We need nowiki tags as template output beginning with "#" triggers
	-- bug 14974.
	return frame:extensionTag('nowiki', colour)
end

--------------------------------------------------------------------------------
-- Icon functions
--------------------------------------------------------------------------------

function p._icon(args)
	local class = getDefinition(args.class or args[1])
	local default = getDefault()
	local file = getProperty(class, default, {"icon", "file"})
	local label = getProperty(class, default, {"labels", "full"})
	label = ucfirst(label)
	local attrib = getProperty(class, default, {"icon", "requiresAttribution"})
	local span = mw.html.create('span')

	span
		:cssText(args.style)
		:attr('title', label)
		:wikitext(
			string.format(
				'[[File:%s|%s|16px%s]]',
				file,
				label,
				attrib and '' or '|link=|alt='
			)
		)
	return tostring(span)
end

p.icon = makeInvokeFunction(p._icon, 'Template:Class/icon')

--------------------------------------------------------------------------------
-- Class functions
--------------------------------------------------------------------------------

function p._class(args)
	local classDef, classCode = getDefinition(args.class or args[1])
	local default = getDefault()
	local iconDefault = getProperty(classDef, default, {"icon", "default"})
	local shortLabel = getProperty(classDef, default, {"labels", "short"})
	local categoryRoot = getProperty(classDef, default, {"categoryRoot"})
	--o is short for "options", go for "get options". Bool true → case-sensitive
	local o, go = {}, {
		bold = false,
		heading = false,
		image = false,
		rowspan = false,
		fullcategory = true,
		category = true,
		topic = true
	}
	for k, v in pairs(go) do
		if v then o[k] = trim(args[k]) else o[k] = normalizeValue(args[k]) end
	end

	local cell = mw.html.create(o.heading and 'th' or 'td')
	--image=yes forces icon, image=no disables it, otherwise checks default
	local icon = iconDefault and (o.image ~= 'no') or (o.image == 'yes')
	icon = icon and p.icon(args) .. '&nbsp;' or ''

	local category
	if o.fullcategory then
		category = o.fullcategory
	elseif o.category then
		category = string.format('%s %s', categoryRoot, o.category)
	elseif o.topic then
		category = string.format('%s %s articles', categoryRoot, o.topic)
	else
		category = string.format('%s articles', categoryRoot)
	end
	local text = string.format ('[[:Category:%s|%s]]', category, shortLabel)
	cell
		:addClass('assess')
		:addClass('assess-' .. (classCode or ''))
		:css('text-align', 'center')
		:css('white-space', 'nowrap')
		:css('font-weight', o.bold ~= 'no' and 'bold' or nil)
		:css('background', p._colour(classCode))
		:attr('rowspan', tonumber(o.rowspan))
		:wikitext(icon, text)

		return tostring(cell)
end

p.class = makeInvokeFunction(p._class, 'Template:Class')

return p