-- This module implements {{Navbox Canada}}

local p = {}

local Navbox = require('Module:Navbox')
local templatestyles = 'Navbox Canada/styles.css'

function p.navbox(frame)
	-- table for args passed to navbox
	local targs = {}

	-- helper functions
	local function isnotempty(t) return t and t ~= '' end
	local function prependarg(k, v)	targs[k] = v .. (targs[k] or '') end

	local listcount = 0
	local collapsiblegroups = nil
	local firstnum = 1
	local lastnum = 0
	local leaf = nil
	local borders = ''
	local ischild = nil
	local topborder, notopborder = nil, nil
	local bottomborder, nobottomborder = nil, nil
	local tstyles = frame:extensionTag{ name = 'templatestyles', args = { src = templatestyles} }

	-- process args, almost all of which are just copied to targs
	for k,v in pairs(frame:getParent().args) do
		if type(k) == 'string' and k:match('^list[0-9][0-9]*$') then
			if isnotempty(v) then
				listcount = listcount + 1
				local num = mw.ustring.gsub(k,'^list([0-9][0-9]*)$', '%1')
				firstnum = (tonumber(num) < firstnum or listcount == 1) and tonumber(num) or firstnum
				lastnum = (tonumber(num) > lastnum or listcount == 1) and tonumber(num) or lastnum
				targs[k] = v
			end
		elseif k == 'leaf' and isnotempty(v) then
			leaf = 1
		elseif k == 'collapsible groups' and isnotempty(v) then
			collapsiblegroups = 1
		elseif k == 'topborder' and isnotempty(v) then
			topborder = 1
		elseif k == 'notopborder' and isnotempty(v) then
			notopborder = 1
		elseif k == 'bottomborder' and isnotempty(v) then
			bottomborder = 1
		elseif k == 'nobottomborder' and isnotempty(v) then
			nobottomborder = 1
		elseif isnotempty(v) then
			targs[k] = v
		end
	end
	-- child or subgroup
	if targs['border'] or targs[1] or targs['1'] then
		local v = targs['border'] or targs[1] or targs['1']
		if v == 'child' or v == 'subgroup' then
			ischild = 1
		end
	end

	-- hlist bodyclass
	prependarg('bodyclass', 'navbox-canada hlist ')

	-- leaf
	if leaf then
		prependarg('title', 
				'<span style="vertical-align: 1px; padding-right:0.2em">' ..
				'[[File:Maple Leaf (from roundel).svg|20x20px|link=|alt=]]' .. 
				'</span> ')
	end

	-- aboveclass
	prependarg('aboveclass', 'navbox-canada-t ')

	-- groupclass
	prependarg('groupclass', 'navbox-canada-a ')

	-- imageclass
	if targs['image'] then
		borders = (notopborder == nil and 't' or '')
		if targs['below'] or ischild ~= nil then
			borders = borders .. (nobottomborder == nil and 'b' or '')
		else
			borders = borders .. (bottomborder == 1 and 'b' or '')
		end
		if borders ~= '' then
			prependarg('imageclass', 'navbox-canada-' .. borders .. ' ')
		end
	end

	-- first and last list class
	if lastnum == firstnum then
		borders = ''
		if collapsiblegroups == nil and ischild == nil then
			borders = borders .. (notopborder == nil and 't' or '')
		end
		if targs['below'] or ischild ~= nil then
			borders = borders .. (nobottomborder == nil and 'b' or '')
		else
			borders = borders .. (bottomborder == 1 and 'b' or '')
		end
		if borders ~= '' then
			prependarg('list' .. firstnum .. 'class', 'navbox-canada-' .. borders .. ' ')
		end
	elseif lastnum > firstnum then
		if collapsiblegroups == nil and notopborder == nil then
			prependarg('list' .. firstnum .. 'class', 'navbox-canada-t ')
		end
		if (targs['below'] and nobottomborder == nil) or (bottomborder == 1) then
			prependarg('list' .. lastnum .. 'class', 'navbox-canada-b ')
		end
	end

	-- hack for https://phabricator.wikimedia.org/T200206
	if targs['title'] and targs['title'] ~= '' then
		prependarg('title', tstyles)
		tstyles = ''
	end
	-- pass the process args to navbox or navbox with collapsible groups
	if collapsiblegroups then
		return tstyles .. frame:expandTemplate{ title = 'Navbox with collapsible groups', args = targs }
	else
		return tstyles .. Navbox._navbox(targs)
	end

end

return p