-- This implements Template:navboxes
local p = {}

local Navbox = require('Module:Navbox')

local function isnotempty(s)
	return s and s:match( '^%s*(.-)%s*$' ) ~= ''
end

local function navboxes(args, list)
	local navbar = (args['state'] and args['state'] == 'off') and 'off' or 'plain'
	local title = args['title'] or 'Links to related articles'
	local titlestyle = 'background:' .. (args['bg'] or '#e8e8ff') .. ';'
		.. (isnotempty(args['fg']) and ('color:' .. args['fg'] .. ';') or '')
		.. (isnotempty(args['bordercolor']) and ('border: 1px solid ' .. args['bordercolor'] .. ';') or '')
		.. (args['titlestyle'] or '')
	return Navbox._navbox({
			navbar = navbar, title = title, 
			list1 = list,
			state = args['state'] or 'collapsed',
			titlestyle = titlestyle,
			liststyle = 'font-size:114%',
			listpadding = '0px',
			tracking = 'no'
			})
end

function p.top(frame)		
	local args = frame:getParent().args
	local parts = mw.text.split(navboxes(args, '<ADD LIST HERE>'), '<ADD LIST HERE>')
	return parts[1]
end

function p.bottom(frame)		
	local args = {}
	local parts = mw.text.split(navboxes(args, '<ADD LIST HERE>'), '<ADD LIST HERE>')
	return parts[2]
end

function p.navbox(frame)
	local args = frame:getParent().args
	local list = args['list1'] or args['list'] or ''	
	local track_cats = ''
	if list == '' then
		if mw.title.getCurrentTitle().namespace == 0 then
			track_cats = '[[Category:Navboxes template with no content]]'
		end
	end
	return navboxes(args, list) .. track_cats
end

return p