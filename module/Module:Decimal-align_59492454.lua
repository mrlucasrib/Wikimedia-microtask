--Align numbers in table cells on the decimal point	
local p = {}

function p.main(frame)
	local input_string_raw = frame.args[1]
	string = frame:preprocess( input_string_raw )

	local left_percent_default = tonumber(frame.args['left'])
	local left_percents = {}
	left_percents[1] = tonumber(frame.args['left1'])
	left_percents[2] = tonumber(frame.args['left2'])
	left_percents[3] = tonumber(frame.args['left3'])
	left_percents[4] = tonumber(frame.args['left4'])
	left_percents[5] = tonumber(frame.args['left5'])
	left_percents[6] = tonumber(frame.args['left6'])
	left_percents[7] = tonumber(frame.args['left7'])
	left_percents[8] = tonumber(frame.args['left8'])
	left_percents[9] = tonumber(frame.args['left9'])
	left_percents[10] = tonumber(frame.args['left10'])

	local column = 1
	for number in mw.ustring.gmatch( string, '%|[%d%.,]+' ) do
		local left_percent = left_percents[column] or left_percent_default or 50
		local right_percent = 100 - left_percent
		column = column + 1
		
		left_string = mw.ustring.sub(mw.ustring.match(number, '^%|[%d, ]*'),2)
		right_string = mw.ustring.match(number, '%.[%d ]*$')
		if left_string == '' then left_string = '0' end
		formatted_number = '%|<span style=\"float: left; text-align: right; width: ' .. tostring(left_percent) .. '%;\">' .. left_string .. '</span>'
		if right_string then
			formatted_number = formatted_number .. '<span style=\"float: right; text-align: left; width: ' .. tostring(right_percent) .. '%;\">' .. right_string .. '</span>'
		end
		string = mw.ustring.gsub( string, number, formatted_number )
	end

	return string
	end

return p