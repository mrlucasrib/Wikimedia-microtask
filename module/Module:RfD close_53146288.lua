local rfd = {}

function rfd.rfdt_before_result(frame) --this bit creates the "closed discussion" notice
	--define function to check whether arguments are defined
	local args = frame.args

	local function argIsSet(key)
		if args[key] and args[key]:find('%S') then
			return true
		else
			return false
		end
	end

	local function match_result(result_parameter) --takes string as input, spews two strings as output
			
		local find_count = 0
		
		local result_match = ''
		local icon_filename = ''
		
		local parameter_lower = result_parameter:lower()
		
		--I thought about using an array and a for-loop, but the logic is 
		--sufficiently complicated (there is no built-in "or" in Lua string 
		--patterns) so I'll just lay it flat.
		if (parameter_lower:find('keep') or parameter_lower:find('withdraw') or parameter_lower:find('refine')) then
			result_match = 'Keep'
			icon_filename = 'File:White check mark in dark green rounded square.svg'
			find_count = find_count + 1
		end
		
		if (parameter_lower:find('delete')) then
			result_match = 'Delete'
			icon_filename = 'File:White x in red rounded square.svg'
			find_count = find_count + 1
		end
		
		if (parameter_lower:find('retarget') or parameter_lower:find('soft redirect'))then
			result_match = 'Retarget'
			icon_filename = 'File:Right-pointing white arrow in blue rounded square.svg'
			find_count = find_count + 1
		end
		
		if (parameter_lower:find('disambig') or parameter_lower:find('dab') or parameter_lower:find('sia') or parameter_lower:find('set index')) then
			result_match = 'Disambiguate'
			icon_filename = 'File:Three disambiguation arrows icon in rounded blue square.svg'
			find_count = find_count + 1
		end
		
		if (parameter_lower:find('no consensus') and find_count == 0) then
			--This catches instances of "no consensus" that isn't qualified by "default to [keep/delete]"
			result_match = 'No consensus'
			icon_filename = 'File:White equals sign on grey rounded square.svg'
			find_count = 1
		end
		
		if find_count >= 2 or (argIsSet('result') and find_count == 0) then
			result_match = 'Split or bespoke decisions'
			icon_filename = 'File:White i in purple rounded square.svg'
		elseif find_count <= 0 then
			result_match = 'No decision'
			icon_filename = 'File:50% grey rounded square.svg'
		end
		
		return result_match, icon_filename
	end
	
	--Detect result first, default to "no decision" if arg not set
	local result_match = 'No decision'
	local icon_filename = 'File:50% grey rounded square.svg'
	local result_string = ''
	if (argIsSet('result')) then
		result_string = ' Result was: '
		result_match, icon_filename = match_result(args['result'])
	end
	
	--Build wikitext for result icon
	local message_string1 = '<includeonly>' --includeonly tag
	--then dump the icon
	.. '[[' .. icon_filename
	.. '|16px|link=|alt=' .. result_match .. "]] '''Closed discussion''', see [["
	
	--Build wikilink to full discussion.
	--mw.title.getCurrentTitle() will resolve correctly if substed
	local timestamp_string = os.time()
	local link_string = tostring(mw.title.getCurrentTitle()) ..  '#' .. timestamp_string
	local message_string2 = '|full discussion]].'
	
	--Complete the includeonly result message and build the anchor on daily log page
	local end_string = '</includeonly><noinclude><span id="' .. timestamp_string .. '"></span>'

	--Put it all together and return from Lua
	return message_string1 .. link_string .. message_string2 .. result_string .. end_string
end

function rfd.rfdt_show_result(frame)
	return '</noinclude>' .. frame.args['result'] .. '<includeonly></div></includeonly><noinclude>'
end

function rfd.rfdb_noinclude(frame)
	return '</noinclude>'
end

return rfd