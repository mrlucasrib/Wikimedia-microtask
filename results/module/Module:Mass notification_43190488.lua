-- This module sends out notifications to multiple users.

local MAX_USERS = 50 -- The Echo user limit as of September 2015.
local GROUP_PAGE_PATH = 'Module:Mass notification/groups/'
local NO_NAME_ERROR = 'no group name was specified'
local LOAD_ERROR = 'the group "[[$1|$2]]" was not found'
local MAX_USER_ERROR = 'attempted to send notifications to more than $1 users'
local NO_USER_ERROR = 'could not find any usernames in $1'
local INTRO_BLURB = 'Notifying all members of $1'
	.. ' <small>([[Template:Mass notification|more info]]'
	.. " '''·''' "
	.. '<span class="plainlinks">[$2 opt out]</span>)</small>: '

local p = {}

local function message(msg, ...)
	return mw.message.newRawMessage(msg):params{...}:plain()
end

local function makeWikitextError(msg)
	return string.format(
		'<strong class="error">Error: %s.</strong>',
		msg
	)
end

function p.groupSubmodule(frame)
	-- Returns either the group link or the group name, depending on whether
	-- the submodule can be found. For use in edit notices.
	local groupName = frame.args[1]
	local success, data = pcall(mw.loadData, GROUP_PAGE_PATH .. groupName)
	if success and type(data) == 'table' and data.group_page then
		return string.format('[[%s|%s]]', data.group_page, groupName)
	else
		return groupName
	end
end

function p._main(groupName)
	-- Validate input.
	if type(groupName) ~= 'string' then
		return makeWikitextError(NO_NAME_ERROR)
	end

	local groupSubmodule = GROUP_PAGE_PATH .. groupName

	-- Load the group submodule and check for errors.
	local data
	do
		local success
		success, data = pcall(mw.loadData, groupSubmodule)
		if not success then
			return makeWikitextError(message(LOAD_ERROR, groupSubmodule, groupName))
		elseif type(data) ~= 'table' or not data[1] then -- # doesn't work with mw.loadData
			return makeWikitextError(message(NO_USER_ERROR, groupName))
		elseif data[MAX_USERS + 1] then -- # doesn't work with mw.loadData
			return makeWikitextError(message(MAX_USER_ERROR, tostring(MAX_USERS)))
		end
	end

	-- Make the intro blurb.
	local introBlurb
	do
		local optOutUrl = tostring(mw.uri.fullUrl(
			groupSubmodule,
			{action = 'edit'}
		))
		local groupLink
		if data.group_page then
			groupLink = string.format('[[%s|%s]]', data.group_page, groupName)
		else
			groupLink = groupName
		end
		introBlurb = message(INTRO_BLURB, groupLink, optOutUrl)
	end

	-- Make the user links.
	local userLinks
	do
		local userNamespace = mw.site.namespaces[2].name
		local links = {}
		for i, username in ipairs(data) do
			username = tostring(username)
			links[i] = string.format(
				'[[%s:%s]]',
				userNamespace,
				username
			)
		end
		userLinks = string.format(
			'<span style="display: none;">(%s)</span>',
			table.concat(links, ', ')
		)
	end

	return introBlurb .. userLinks
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Mass notification'
	})
	local groupName = args[1]
	return p._main(groupName)
end

return p