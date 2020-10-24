-- Get the raw leaderboard content.
local lb = mw.title.new('Wikipedia:STiki/leaderboard')
local lbtext = (lb and lb:getContent()) or error('Could not find the leaderboard text')

-- Get a specific data value for a given username.
local function findLeaderboardData(dfield, username)
	username = username:gsub('%p', '%%%0')
	local r = {}
	r.rank, r.uses, r.vand, r.agf, r.queue, r.first, r.last, r.avg, r.yest, r.last30 = string.match(
		lbtext,
		'\n| align=center | (%d+) || align=left | %[%[User:' .. username .. '|' .. username ..
		'%]%] %(%[%[User_Talk:' .. username .. '|talk%]%] | %[%[Special:Contributions/' ..
		username .. '|contribs%]%]%) || align=right | (%d+) || align=right | ([%d%.]+)%% ' ..
		'|| align=right | ([%d%.]+)%% || align=center | (%S+) || align=right ' ..
		'| {{ntsh|%d+}} (%d+) days ago || align=right | {{ntsh|%d+}} (%d+) days ago || align=right ' ..
		'| {{ntsh|[%d%.]+}} ([%d%.]+) edits || align=right | (%d+) || align=right | (%d+)'
	)
	return r[dfield]
end

-- Expose the data values to wikitext
return setmetatable({}, {
	__index = function (t, key)
		return function (frame)
			local username = frame.args[1] or ''
			username = mw.getContentLanguage():ucfirst(mw.text.trim(username))
			if username == '' then
				error('No username specified')
			end
			return findLeaderboardData(key, username)
		end
	end
})