local p = {}

function _getBoolean( boolean_str )
	-- from: module:String; adapted
	-- requires an explicit true
	local boolean_value

	if type( boolean_str ) == 'string' then
		boolean_str = boolean_str:lower()
		if boolean_str == 'true' or boolean_str == 'yes' or boolean_str == '1' then
			boolean_value = true
		else
			boolean_value = false
		end
	elseif type( boolean_str ) == 'boolean' then
		boolean_value = boolean_str
	else
		boolean_value = false
	end
	return boolean_value
end

function p.decode( frame )
	local s
	local subset_only 

	s = frame.args['s'] or ''
	subset_only = _getBoolean(frame.args['subset_only'] or false)

	return p._decode( s, subset_only )
end

function p._decode( s, subset_only )
	local ret = nil;

	ret = mw.text.decode( s, not subset_only )

	return ret
end

function p.encode( frame )
	local s
	local charset

	s = frame.args['s'] or ''
	charset = frame.args['charset']

	return p._encode( s, charset )
end

function p._encode( s, charset )
	-- example: charset = '_&©−°\\\"\'\=' -- do escape with backslash not %;
	local ret

	if charset ~= (nil or '') then
		ret = mw.text.encode( s, charset )
	else
		-- use default: chartset = '<>&"\' ' (outer quotes = lua required; space = NBSP)
		ret = mw.text.encode( s )
	end 
	
	return ret
end

return p