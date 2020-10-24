local p = {}

function p.main(frame)
	local numeral = tonumber(frame.args[1])
	local forcenum = frame.args['forcenum']	-- Force numeral for intermediate cases
	local spell = 0

	if numeral<0 or math.fmod(numeral,1)~=0 then
	elseif numeral<10 then
		spell = 1
	elseif numeral>=10 then
		if frame:expandTemplate{ title = 'yesno', args = {forcenum} } ~= 'yes' then
			local spelled = frame:expandTemplate{title='spellnum',args={numeral}}
			if not mw.ustring.find(spelled,'%a+[ %-]%a+[ %-]%a+') then
				spell = 1
			end
		end
	end

	local number
	if spell==1 then
		number = frame:expandTemplate{ title = 'spellnum', args = { numeral, zero = frame.args['zero'], adj = frame.args['adj'], ord = frame.args['ord'], us = frame.args['us'] } }
	else
		number = numeral
	end
	return number
end

return p