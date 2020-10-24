local p = {}

function getstates(frame)
	local states = frame:expandTemplate{ title = 'section transclude', args = { frame.args['section'] } }
	if states == '' then
		states = frame.args[1]
	end
	return states
end

function p.EVs(frame)
	local states = getstates(frame)
	if not states then
		return frame:expandTemplate{ title = 'error', args = { 'Value not available when editing this section in isolation.' } }
	else
		local total = 0
		for state in mw.ustring.gmatch( states, "%a%a" ) do
			seats = frame:expandTemplate{ title = 'USHRseats', args = { state } }
			if state=='DC' then seats=1 end
			if type(tonumber(seats))=='nil' then
				total = error("Unrecognized state")
				break
			else
				total = total + seats + 2
			end
		end
		return total
	end
end

function p.percent(frame)
	local EVs = p.EVs(frame)
	if frame.args[1] then
		denom = frame.args[1]
	else
		denom = 538
	end
	if frame.args[2] then
		places = frame.args[2]
	else
		places = 1
	end
	percent = frame:expandTemplate{ title = 'percent', args = { EVs, denom, places} }
	return percent
end

function p.states(frame)
	local states = getstates(frame)
	local total = 0
	for state in mw.ustring.gmatch( states, "%a%a" ) do
		if state~='DC' then
			total = total + 1
		end
	end
	if total==0 then
		return frame:expandTemplate{ title = 'error', args = { 'Value not available when editing this section in isolation.' } }
	else
		if frame.args[1]=='spell' then
			total = frame:expandTemplate{ title = 'spellnum per MOS', args = { total } }
		end
		return total
	end
end

function p.overlays(frame)
	local states = getstates(frame)
	local size = frame.args['size'] or '325px'

	if frame.args['section']=='passed' then
		color = 'green'
	elseif frame.args['section']=='pending' then
		color = 'yellow'
	end
		
	local overlays = ''
	for state in mw.ustring.gmatch( states, "%a%a" ) do
		state_overlay = '<div style=\"position: absolute; left: 0px; top: 0px\">[[File:' .. state .. ' ' .. color .. '.svg|' .. size .. ']]</div>'
		overlays = overlays .. state_overlay
	end
	return overlays
end

function p.signatories(frame)
	local states = frame:expandTemplate{ title = 'section transclude', args = { 'passed' } }
	local signatories = ''
	for state in mw.ustring.gmatch( states, "%a%a" ) do
		state_name = frame:expandTemplate{ title = 'US State Abbrev', args = { state } }
		local dab = ''
		if state_name=='New York' or state_name=='Washington' then
			dab=' (state)'
		end
		signatories = signatories .. '\n* ' .. frame:expandTemplate{ title = 'flagicon', args = { state_name } } .. '&nbsp;[[' ..  state_name .. dab .. '|' ..  state_name .. ']]'
	end
	return signatories
end

--function p.progress_bar(frame)
--	local
--	
--end


return p