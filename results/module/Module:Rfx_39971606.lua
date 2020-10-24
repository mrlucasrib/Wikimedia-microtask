----------------------------------------------------------------------
--                          Module:Rfx                              --
-- This is a library for retrieving information about requests      --
-- for adminship and requests for bureaucratship on the English     --
-- Wikipedia. Please see the module documentation for instructions. --
----------------------------------------------------------------------

local libraryUtil = require('libraryUtil')
local lang = mw.getContentLanguage()
local textSplit = mw.text.split
local umatch = mw.ustring.match
local newTitle = mw.title.new

local rfx = {}

--------------------------------------
--         Helper functions         --
--------------------------------------

local function getTitleObject(title)
	local success, titleObject = pcall(newTitle, title)
	if success and titleObject then
		return titleObject
	else
		return nil
	end
end

local function parseVoteBoundaries(section)
	-- Returns an array containing the raw wikitext of RfX votes in a given section.
	section = section:match('^.-\n#(.*)$') -- Strip non-votes from the start.
	if not section then
		return {}
	end
	section = section:match('^(.-)\n[^#]') or section -- Discard subsequent numbered lists.
	local comments = textSplit(section, '\n#')
	local votes = {}
	for i, comment in ipairs(comments) do
		if comment:find('^[^#*;:].*%S') then
			votes[#votes + 1] = comment
		end
	end
	return votes
end

local function parseVote(vote)
	-- parses a username from an RfX vote.
	local userStart, userEnd, userMatch = vote:find('%[%[[%s_]*[uU][sS][eE][rR][%s_]*:[%s_]*(.-)[%s_]*%]%].-$')
	local talkStart, talkEnd, talkMatch = vote:find('%[%[[%s_]*[uU][sS][eE][rR][%s_]+[tT][aA][lL][kK][%s_]*:[%s_]*(.-)[%s_]*%]%].-$')
	local username
	if userStart and talkStart then
		if userStart > talkStart then
			username = userMatch
		else
			username = talkMatch
		end
	elseif userStart then
		username = userMatch
	elseif talkStart then
		username = talkMatch
	else
		return string.format( "'''Error parsing signature''': ''%s''", vote )
	end
	username = username:match('^[^|/#]*')
	return username
end

local function parseVoters(votes)
	local voters = {}
	for i, vote in ipairs(votes) do
		voters[#voters + 1] = parseVote(vote)
	end
	return voters
end

local function dupesExist(...)
	local exists = {}
	local tables = {...}
	for i, usernames in ipairs(tables) do
		for j, username in ipairs(usernames) do
			username = lang:ucfirst(username)
			if exists[username] then
				return true
			else
				exists[username] = true
			end
		end
	end
	return false
end

------------------------------------------
--   Define the constructor function    --
------------------------------------------

function rfx.new(title)
	local obj = {}
	local data = {}
	local checkSelf = libraryUtil.makeCheckSelfFunction( 'Module:Rfx', 'rfx', obj, 'rfx object' )
	
	-- Get the title object and check to see whether we are a subpage of WP:RFA or WP:RFB.
	title = getTitleObject(title)
	if not title then
		return nil
	end
	
	function data:getTitleObject()
		checkSelf(self, 'getTitleObject')
		return title
	end
	
	if title.namespace == 4 then
		local rootText = title.rootText
		if rootText == 'Requests for adminship' then
			data.type = 'rfa'
		elseif rootText == 'Requests for bureaucratship' then
			data.type = 'rfb'
		else
			return nil
		end
	else
		return nil
	end

	-- Get the page content and divide it into sections.
	local pageText = title:getContent()
	if not pageText then
		return nil
	end
	local introText, supportText, opposeText, neutralText = umatch(
		pageText,
		'^(.-)\n====[^=\n][^\n]-====.-'
		.. '\n=====%s*[sS]upport%s*=====(.-)'
		.. '\n=====%s*[oO]ppose%s*=====(.-)'
		.. '\n=====%s*[nN]eutral%s*=====(.-)$'
	)
	if not introText then
		introText, supportText, opposeText, neutralText = umatch(
			pageText,
			"^(.-\n'''[^\n]-%(%d+/%d+/%d+%)[^\n]-''')\n.-"
			.. "\n'''Support'''(.-)\n'''Oppose'''(.-)\n'''Neutral'''(.-)"
		)
	end

	-- Get vote counts.
	local supportVotes, opposeVotes, neutralVotes
	if supportText and opposeText and neutralText then
		supportVotes = parseVoteBoundaries(supportText)
		opposeVotes = parseVoteBoundaries(opposeText)
		neutralVotes = parseVoteBoundaries(neutralText)
	end
	local supports, opposes, neutrals
	if supportVotes and opposeVotes and neutralVotes then
		supports = #supportVotes
		data.supports = supports
		opposes = #opposeVotes
		data.opposes = opposes
		neutrals = #neutralVotes
		data.neutrals = neutrals
	end

	-- Voter methods and dupe check.

	function data:getSupportUsers()
		checkSelf(self, 'getSupportUsers')
		if supportVotes then
			return parseVoters(supportVotes)
		else
			return nil
		end
	end

	function data:getOpposeUsers()
		checkSelf(self, 'getOpposeUsers')
		if opposeVotes then
			return parseVoters(opposeVotes)
		else
			return nil
		end
	end

	function data:getNeutralUsers()
		checkSelf(self, 'getNeutralUsers')
		if neutralVotes then
			return parseVoters(neutralVotes)
		else
			return nil
		end
	end

	function data:dupesExist()
		checkSelf(self, 'dupesExist')
		local supportUsers = self:getSupportUsers()
		local opposeUsers = self:getOpposeUsers()
		local neutralUsers = self:getNeutralUsers()
		if not (supportUsers and opposeUsers and neutralUsers) then
			return nil
		end
		return dupesExist(supportUsers, opposeUsers, neutralUsers)
	end

	if supports and opposes then
		local total = supports + opposes
		if total <= 0 then
			data.percent = 0
		else
			data.percent = math.floor((supports / total * 100) + 0.5)
		end
	end
	if introText then
		data.endTime = umatch(introText, '(%d%d:%d%d, %d+ %w+ %d+) %(UTC%)')
		data.user = umatch(introText, '===%s*%[%[[_%s]*[wW]ikipedia[_%s]*:[_%s]*[rR]equests[_ ]for[_ ]%w+/.-|[_%s]*(.-)[_%s]*%]%][_%s]*===')
		if not data.user then
			data.user = umatch(introText, '===%s*([^\n]-)%s*===')
		end
	end
	
	-- Methods for seconds left and time left.
	
	function data:getSecondsLeft()
		checkSelf(self, 'getSecondsLeft')
		local endTime = self.endTime
		if not endTime then
			return nil
		end
		local now = tonumber(lang:formatDate("U"))
		local success, endTimeU = pcall(lang.formatDate, lang, 'U', endTime)
		if not success then
			return nil
		end
		endTimeU = tonumber(endTimeU)
		if not endTimeU then
			return nil
		end
		local secondsLeft = endTimeU - now
		if secondsLeft <= 0 then
			return 0
		else
			return secondsLeft
		end
	end

	function data:getTimeLeft()
		checkSelf(self, 'getTimeLeft')
		local secondsLeft = self:getSecondsLeft()
		if not secondsLeft then
			return nil
		end
		return mw.ustring.gsub(lang:formatDuration(secondsLeft, {'days', 'hours'}), ' and', ',')
	end
	
	function data:getReport()
		-- Gets the URI object for X!'s RfA Analysis tool
		checkSelf(self, 'getReport')
		return mw.uri.new('//tools.wmflabs.org/xtools/rfa/?p=' .. mw.uri.encode(title.prefixedText))
	end
	
	function data:getStatus()
		-- Gets the current status of the RfX. Returns either "successful", "unsuccessful",
		-- "open", or "pending closure". Returns nil if the status could not be found.
		checkSelf( self, 'getStatus' )
		local rfxType = data.type
		if rfxType == 'rfa' then
			if umatch(
				pageText,
				'%[%[[%s_]*[cC][aA][tT][eE][gG][oO][rR][yY][%s_]*:[%s_]*[sS]uccessful requests for adminship(.-)[%s_]*%]%]'
			) then
				return 'successful'
			elseif umatch(
				pageText,
				'%[%[[%s_]*[cC][aA][tT][eE][gG][oO][rR][yY][%s_]*:[%s_]*[uU]nsuccessful requests for adminship(.-)[%s_]*%]%]'
			) then
				return 'unsuccessful'
			end
		elseif rfxType == 'rfb' then
			if umatch(
				pageText,
				'%[%[[%s_]*[cC][aA][tT][eE][gG][oO][rR][yY][%s_]*:[%s_]*[sS]uccessful requests for bureaucratship(.-)[%s_]*%]%]'
			) then
				return 'successful'
			elseif umatch(
				pageText,
				'%[%[[%s_]*[cC][aA][tT][eE][gG][oO][rR][yY][%s_]*:[%s_]*[uU]nsuccessful requests for bureaucratship(.-)[%s_]*%]%]'
			) then
				return 'unsuccessful'
			end
		end
		local secondsLeft = self:getSecondsLeft()
		if secondsLeft and secondsLeft > 0 then
			return 'open'
		elseif secondsLeft and secondsLeft <= 0 then
			return 'pending closure'
		else
			return nil
		end
	end
	
	-- Specify which fields are read-only, and prepare the metatable.
	local readOnlyFields = {
		getTitleObject = true,
		['type'] = true,
		getSupportUsers = true,
		getOpposeUsers = true,
		getNeutralUsers = true,
		supports = true,
		opposes = true,
		neutrals = true,
		endTime = true,
		percent = true,
		user = true,
		dupesExist = true,
		getSecondsLeft = true,
		getTimeLeft = true,
		getReport = true,
		getStatus = true
	}
	
	local function pairsfunc( t, k )
		local v
		repeat
			k = next( readOnlyFields, k )
			if k == nil then
				return nil
			end
			v = t[k]
		until v ~= nil
		return k, v
	end

	return setmetatable( obj, {
		__pairs = function ( t )
			return pairsfunc, t, nil
		end,
		__index = data,
		__newindex = function( t, key, value )
			if readOnlyFields[ key ] then
				error( 'index "' .. key .. '" is read-only', 2 )
			else
				rawset( t, key, value )
			end
		end,
		__tostring = function( t )
			return t:getTitleObject().prefixedText
		end
	} )
end

return rfx