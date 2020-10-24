local messageBox = require('Module:Message box')
local navbarModule = require('Module:Navbar')

local p = {}

-- Get constants.
local lang = mw.language.getContentLanguage()
local currentUnixDate = lang:formatDate('U')
currentUnixDate = tonumber(currentUnixDate)

local function err(msg)
	return mw.ustring.format('<b class="error">%s</b>', msg)
end

local function getUnixDate(date)
	local success, unixDate = pcall(lang.formatDate, lang, 'U', date)
	if success then
		return tonumber(unixDate)
	end
end

local function unixDateError(date)
	return err(tostring(date) .. ' is not a valid date.')
end

local function makeOmbox(oargs)
	return messageBox.main('ombox', oargs)
end

local function makeNavbar(name)
	return navbarModule.navbar{name, mini = '1', nodiv = '1'}
end

local function randomizeArray(t)
	-- Iterate through the array backwards, each time swapping the entry "i" with a random entry.
	-- Courtesy of Xinhuan at http://forums.wowace.com/showthread.php?p=279756
	math.randomseed(mw.site.stats.edits)
	for i = #t, 2, -1 do
		local r = math.random(i)
		t[i], t[r] = t[r], t[i]
	end
	return t
end

local function getArgNums(args, prefix)
	-- Returns a table containing the numbers of the arguments that exist for the specified prefix. For example, if the prefix
	-- was 'data', and 'data1', 'data2', and 'data5' exist, it would return {1, 2, 5}.
	local nums = {}
	for k, v in pairs(args) do
		k = tostring(k)
		local num = mw.ustring.match(k, '^' .. prefix .. '([1-9]%d*)$')
		if num then
			table.insert(nums, tonumber(num))
		end
	end
	table.sort(nums)
	return nums
end

local function showBeforeDate(datePairs)
	-- Shows a value if it is before a given date.
	for i, datePair in ipairs(datePairs) do
		local date = datePair.date
		local val = datePair.val
		if not date then -- No date specified, so assume we have no more dates to process.
			return val
		end
		local unixDate = getUnixDate(date)
		if not unixDate then return unixDateError(date) end
		if currentUnixDate < unixDate then -- The specified date is in the future.
			return val
		end
	end
end

local function countdown(date, event)
	if type(event) ~= 'string' then return err('No event name provided.') end
	-- Get the current date unix timestamp.
	local unixDate = getUnixDate(date)
	if not unixDate then return unixDateError(date) end
	unixDate = tonumber(unixDate)
	-- Subtract the timestamp from the current unix timestamp to find the time left, and output that in a readable way.
	local secondsLeft = unixDate - currentUnixDate
	if secondsLeft <= 0 then return end
	local timeLeft = lang:formatDuration(secondsLeft, {'weeks', 'days', 'hours'})
	-- Find whether we are plural or not.
	local isOrAre
	if mw.ustring.match(timeLeft, '^%d+') == '1' then
		isOrAre = 'is'
	else
		isOrAre = 'are'
	end
	-- Make the numbers red and bold, because that's what {{countdown}} does and it makes them look important.
	local timeLeft = mw.ustring.gsub(timeLeft, '(%d+)', '<span style="color: #F00; font-weight: bold;">%1</span>')
	-- Make the refresh link, and join it all together.
	local refreshLink = mw.title.getCurrentTitle():fullUrl{action = 'purge'}
	refreshLink = mw.ustring.format('<small><span class="plainlinks">([%s refresh])</span></small>', refreshLink)
	return mw.ustring.format('There %s %s until %s. %s', isOrAre, timeLeft, event, refreshLink)
end

local function collapse(s, heading, bg)
	local ret = [=[
<div style="margin-left: 0px;">
{| class="navbox collapsible collapsed" style="background: transparent; text-align: left; border: 1px solid silver; margin-top: 0.2em;"
|-
! style="background-color: %s; text-align: center; font-size: 112%%;" | %s
|-
| style="border: solid 1px silver; padding: 8px; background-color: white; font-size: 112%%;" | %s
|}</div>]=]
	return mw.ustring.format(ret, bg or '#e0f8e2', heading, s)
end

function p._main(args)
	-- Get data for the box, plus the box title.
	local year = lang:formatDate('Y')
	local name = args.name or 'ACE' .. year
	local navbar = makeNavbar(name)
	local electionpage = args.electionpage or mw.ustring.format(
		'[[Wikipedia:Arbitration Committee Elections December %s|%s Arbitration Committee Elections]]',
		year, year
	)
	-- Get nomination or voting link, depending on the date.
	local beforenomlink = args.beforenomlink or mw.ustring.format('[[Wikipedia:Requests for comment/Arbitration Committee Elections December %s/Electoral Commission|Electoral Commission RFC]]', year)
	local nomstart = args.nomstart or error('No nomstart date supplied')
	local nomlink = args.nomlink or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Candidates|Nominate]]', year)
	local nomend = args.nomend or error('No nomend date supplied')
	local votestart = args.votestart or error('No votestart date supplied')
	local votepage = args.votepage or '[[Special:SecurePoll|Vote]]'
	local votelog = args.votelog or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Log|Voter log]]', year)
	local votelink = args.votelink or mw.ustring.format("'''%s'''\n* %s", votepage, votelog)
	local voteend = args.voteend or error('No voteend date supplied')
	local voteendlink = args.voteendlink or votelog
	local scheduleText = showBeforeDate{
		{val = beforenomlink, date = nomstart},
		{val = nomlink, date = nomend},
		{val = countdown(votestart, 'voting begins'), date = votestart},
		{val = votelink, date = voteend},
		{val = voteendlink}
	}
	-- Get other links.
	local contact = args.contact or mw.ustring.format('[[WT:COORD%s|Contact the coordinators]]', mw.ustring.sub(year, 3, 4))
	local discuss = args.discuss or mw.ustring.format('[[WT:ACE%s|Discuss the elections]]', year)
	local cguide = args.cguide or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Candidates/Guide|Candidate guide]]', year)
	local cstatements = args.cstatements or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Candidates|Candidate statements]]', year)
	local cquestions = args.cquestions or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Questions|Questions for the candidates]]', year)
	local cdiscuss = args.cdiscuss or mw.ustring.format('[[Wikipedia:Arbitration Committee Elections December %s/Candidates/Discussion|Discuss the candidates]]', year)
	-- Get voter guides
	local guideNums = getArgNums(args, 'guide')
	local guides = {}
	for _, num in ipairs(guideNums) do
		table.insert(guides, '\n* ' .. args['guide' .. tostring(num)])
	end
	guides = randomizeArray(guides)
	guides = table.concat(guides)
	guides = '<div class="hlist">\nThese [[:Category:Wikipedia Arbitration Committee Elections 2020 voter guides|guides]] represent the thoughts of their authors. All individually written voter guides are eligible for inclusion. Guides to other guides are ineligible.\n' .. guides .. '</div>'
	guides = collapse(guides, 'Voter guides', '#e0f8e2')
	-- Get the text field of ombox.
	local text = [=[
<div style="float: right">%s</div><div class="hlist">
* '''%s'''
* %s
* %s
* %s
* [[Wikipedia:5-minute guide to ArbCom elections|Quick guide]]</div>
----
<div class="hlist">
; Candidates
: %s
: %s
: %s
: %s</div>
%s]=]
	text = mw.ustring.format(
		text,
		navbar,
		electionpage,
		scheduleText,
		contact,
		discuss,
		cguide,
		cstatements,
		cquestions,
		cdiscuss,
		guides
	)
	-- Build the ombox args
	local oargs = {}
	oargs.image = args.image or '[[File:Judges cupola.svg|50px|ArbCom|link=]]'
	oargs.style = args.style or 'background-color: #e0f8e2'
	oargs.text = text
	return makeOmbox(oargs)		
end
 
function p.main(frame)
        -- If called via #invoke, use the args passed into the invoking template, or the args passed to #invoke if any exist.
        -- Otherwise assume args are being passed directly in from the debug console or from another Lua module.
        local origArgs
        if frame == mw.getCurrentFrame() then
                origArgs = frame:getParent().args
                for k, v in pairs(frame.args) do
                        origArgs = frame.args
                        break
                end
        else
                origArgs = frame
        end
        -- Trim whitespace and remove blank arguments.
        local args = {}
        for k, v in pairs(origArgs) do
                if type(v) == 'string' then
                        v = mw.text.trim(v)
                end
                if v ~= '' then
                        args[k] = v
                end
        end
        return p._main(args)
end
 
return p