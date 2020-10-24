require('Module:No globals')

local yesno = require('Module:Yesno')
local makeMessageBox = require('Module:Message box').main
local getArgs

local activeBox -- lazily initialized if we get an active request

----------------------------------------------------------------------
-- Box class definition
----------------------------------------------------------------------

local box = {}
box.__index = box

function box.new(protectionType, args)
	local obj = {}
	obj.args = args
	setmetatable(obj, box)
	obj.tmboxArgs = {} -- Used to store arguments to be passed to tmbox by the box:export method.
	-- Set data fields.
	obj.tmboxArgs.attrs = { ['data-origlevel'] = protectionType }
	return obj
end

function box:setArg(key, value)
	-- This sets a value to be passed to tmbox.
	if key then
		self.tmboxArgs[key] = value
	end
end

function box:export()
	if not mw.title.getCurrentTitle().isTalkPage and not self.args.demo then
		return '<span class="error">Error: Protected edit requests can only be made on the talk page.</span>[[Category:Non-talk pages with an edit request template]]'
	end

	-- String together page names provided
	local titles = {}
	for k, v in pairs(self.args) do
		if type(k) == 'number' then
			table.insert(titles, self.args[k])
		end
	end
	local pagesText
	if #titles == 0 then
		pagesText = ''
	elseif #titles == 1 and mw.title.getCurrentTitle().subjectPageTitle.fullText == titles[1] then
		pagesText = ''
	else 
		for i, v in pairs(titles) do
		    if i == 1 then
		        pagesText = ' to [[:' .. v .. ']]'
		    elseif i == #titles then
		        pagesText = pagesText .. ' and [[:' .. v .. ']]'
		    else
		        pagesText = pagesText .. ', [[:' .. v .. ']]'
		    end
		end
	end
	
	self:setArg('smalltext', "This [[Wikipedia:Edit requests|edit request]]" .. pagesText ..
		" has been answered. Set the <code style=\"white-space: nowrap;\">&#124;answered&#61;</code> or <code style=\"white-space: nowrap;\">&#124;ans&#61;</code> parameter to '''no''' to reactivate your request.")
	self:setArg('small', true)
	self:setArg('class', 'editrequest')
	return makeMessageBox('tmbox', self.tmboxArgs)
end

----------------------------------------------------------------------
-- Process arguments and initialise objects
----------------------------------------------------------------------

local p = {}

function p._main(protectionType, args)
	local boxType = box
	if not yesno(args.answered or args.ans, true) then
		if not activeBox then
			activeBox = require('Module:Protected edit request/active')(box, yesno, makeMessageBox)
		end
		boxType = activeBox
	end
	local requestBox = boxType.new(protectionType, args)
	return requestBox:export()
end

local mt = {}

function mt.__index(t, k)
	if not getArgs then
		getArgs = require('Module:Arguments').getArgs
	end
	return function (frame)
		return t._main(k, getArgs(frame, {wrappers = {'Template:Edit fully-protected', 'Template:Edit semi-protected', 'Template:Edit template-protected', 'Template:Edit extended-protected', 'Template:Edit interface-protected'}}))
	end
end

return setmetatable(p, mt)