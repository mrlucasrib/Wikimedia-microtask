-- This module implements [[Template:Energy meter]].

local lang = mw.language.getContentLanguage()
local yesno = require('Module:Yesno')

local p = {}

local function round(n)
	return math.floor(n + 0.5)
end

local function sanitizePercentage(n)
	if n < 0 then
		n = 0
	elseif n > 100 then
		n = 100
	end
	return n
end

local function getUnixTime(date)
	return tonumber(lang:formatDate('U', date))
end

local function calculateHumanPercentage(energyleft)
	if not energyleft then
		error("the 'energyleft' parameter must be specified for all non-bot users", 3)
	end
	energyleft = tonumber(energyleft)
	if not energyleft then
		error("the 'energyleft' parameter was not a valid number", 3)
	end
	return sanitizePercentage(energyleft)
end

local function calculateBotPercentage(expiry)
	if not expiry then
		error("the 'expiry' parameter must be specified for all bot users", 3)
	end
	local now = getUnixTime()
	local lifespan = getUnixTime('now + 6 months') - now
	local timeLeft = getUnixTime(expiry) - now
	local percentage = timeLeft / lifespan * 100
	return sanitizePercentage(percentage)
end

local function calculateDaysLeft(expiry)
	local seconds = getUnixTime(expiry) - getUnixTime()
	local days = seconds / 60 / 60 / 24
	if days < 0 then
		days = 0
	end
	return math.floor(days)
end

function p._main(args, frame)
	frame = frame or mw.getCurrentFrame()
	local isBot = yesno(args.isbot) or false
	local isHorizontal = yesno(args.ishorizontal) or false
	local isTopIcon = yesno(args.istopicon) or false
	local isThumb = not yesno(args.nothumb)

	-- Percentage
	local percentage
	if isBot then
		percentage = calculateBotPercentage(args.expiry)
	else
		percentage = calculateHumanPercentage(args.energyleft)
	end

	-- Power level
	local powerLevel = math.ceil(percentage / 100 * 6)

	-- Image name
	local image
	do
		local images = {
			'Empty',
			'Almost Empty',
			'Partially Empty',
			'Half',
			'Partially Full',
			'Almost Full',
			'Full'
		}
		image = images[powerLevel + 1]
		image = 'Battery ' .. image
		if isHorizontal then
			image = 'Horizontal ' .. image
		end
		image = image .. '.png'
	end

	-- Caption
	local caption
	if isBot then
		caption = 'This bot has ' .. round(percentage) .. '% power left.'
		if powerLevel == 2 then
			caption = caption .. '<br>This bot is running low on energy.'
		elseif powerLevel == 1 then
			caption = caption ..
				'<br>This bot has almost no energy left.' ..
				'<br>It will die in ' ..
				calculateDaysLeft(args.expiry) ..
				' day(s).' ..
				'<br>Contact operator.'
		elseif powerLevel == 0 then
			caption = caption .. '<br>This bot has died. Contact the operator.'
		end
	else
		-- Is a human
		caption = 'This user has ' .. round(percentage) .. '% energy left.'
		if powerLevel == 2 then
			caption = caption ..
				'<br>This user is running low on energy.' ..
				'<br>They may not be very active on Wikipedia.'
		elseif powerLevel == 1 then
			caption = caption ..
				'<br>This user has almost no energy left.' ..
				'<br>They may retire soon.'
		elseif powerLevel == 0 then
			caption = caption .. '<br>This user retired.'
		end
	end

	-- Width
	local width
	if isTopIcon then
		width = '25'
	else
		width = '200'
	end
	width = width .. 'px'

	-- Position
	local position
	if not isTopIcon then
		position = args.position or 'right'
	end

	-- File link
	local fileLink = string.format(
		'[[File:%s|%s|%s%s%s]]',
		image,
		caption,
		width,
		position and '|' .. position or '',
		not isTopIcon and isThumb and '|thumb' or ''
	)

	-- Output
	if isTopIcon then
		local name = 'energy-meter'
		if args.sortkey then
			name = args.sortkey .. '-' .. name
		end
		return frame:extensionTag{
			name = 'indicator',
			content = fileLink,
			args = {name = name}
		}
	else
		return fileLink
	end
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Energy meter'
	})
	return p._main(args, frame)
end

return p