local p = {}

local function makeError(msg, frame)
	-- Show error only in preview
	if (frame:preprocess( "{{REVISIONID}}" ) ~= "") then return '' end
	msg ='<strong>Error in [[Template:Hidden ping]]:</strong> ' .. msg
	return mw.text.tag('div', {['class']='error'}, msg)
end

function p.hiddenping(frame)
	local origArgs = frame:getParent().args
	local args = {}
	local maxArg = 0
	local usernames = 0
	for k, v in pairs(origArgs) do
		if type(k) == 'number' and mw.ustring.match(v,'%S') then
			if k > maxArg then maxArg = k end
			local title = mw.title.new(v)
			if title then
				args[k] = title.rootText
				usernames = usernames + 1
			else
				return makeError('Input contains forbidden characters.', frame)
			end
		end
	end

	if usernames < 1 then
		return makeError('Username not given.', frame)
	elseif usernames > (tonumber(frame.args.max) or 50) then
		return makeError('More than '..tostring(frame.args.max or 50)..' names specified.', frame)
	else
		local outStr = ''
		for i = 1, maxArg do
			if args[i] then outStr = outStr..'[[:User:'..args[i]..'|&#x200B;]]' end
		end
		return outStr
	end
end

return p