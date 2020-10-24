-- This module powers {{countdown}}.

local p = {}

-- Constants
local lang = mw.language.getContentLanguage()
local getArgs = require('Module:Arguments').getArgs

local function formatMessage(secondsLeft, event, color)
	local timeLeft = lang:formatDuration(secondsLeft, {'years', 'weeks', 'days', 'hours', 'minutes', 'seconds'})
	-- Find whether we are plural or not.
	local isOrAre
	if string.match(timeLeft, '^%d+') == '1' then
		isOrAre = 'is'
	else
		isOrAre = 'are'
	end
	-- Color and bold the numbers, because it makes them look important.
	timeLeft = string.gsub(timeLeft, '(%d+)', '<span style="color: ' .. (color or '#F00') .. '; font-weight: bold;">%1</span>')
	return string.format('There %s %s until %s.', isOrAre, timeLeft, event)
end

function p.main(frame)
	local args = getArgs(frame)

	if not (args.year and args.month and args.day) then
		return '<strong class="error">Error: year, month, and day must be specified</strong>'
	end

	local timeArgs = {year=args.year, month=args.month, day=args.day, hour=args.hour, min=args.minute, sec=args.second}
	for k,v in pairs(timeArgs) do
		if not tonumber(v) then
			error('Argument ' .. k .. ' could not be parsed as a number: ' .. v)
		end
	end
	local eventTime = os.time(timeArgs)
	local timeToStart = os.difftime(eventTime, os.time()) -- (future time - current time)
	local text
	if timeToStart > 0 then
		-- Event has not begun yet
		text = formatMessage(timeToStart, args.event or 'the event begins', args.color)
	elseif args.duration then
		local timeToEnd
		if args['duration unit'] then
			-- Duration is in unit other than seconds, use formatDate to add
			timeToEnd = tonumber(lang:formatDate('U', '@' .. tostring(timeToStart) .. ' +' .. tostring(args.duration) .. ' ' .. args['duration unit']))
		else
			timeToEnd = timeToStart + (tonumber(args.duration) or error('args.duration should be a number of seconds', 0))
		end
		if timeToEnd > 0 then
			-- Event is in progress
			text = args.eventstart or formatMessage(timeToEnd, (args.event or 'the event') .. ' ends', args.color)
		else
			-- Event had a duration and has now ended
			text = args.eventend or ((lang:ucfirst(args.event or 'The event')) .. ' has ended.')
		end
	else
		-- Event had no duration and has begun
		text = args.eventstart or ((lang:ucfirst(args.event or 'The event')) .. ' has started.')
	end
	local refreshLink
	if args.refresh == 'no' then
		refreshLink = ''
	else
		refreshLink = mw.title.getCurrentTitle():fullUrl({action = 'purge'})
		refreshLink = string.format(' <small><span class="plainlinks">([%s refresh])</span></small>', refreshLink)
	end
	return text .. refreshLink
end

return p