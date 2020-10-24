local p = {}
function p.main(frame)
	local theString = mw.text.unstrip(frame.args[1])
	local onlyNumber
	onlyNumber = (string.match(theString, "%-?[%d%.]+"))
	checkedNumber = tonumber(onlyNumber)
	if checkedNumber == nil then
		error(" Input did not contain valid numeric data")
	else
		return checkedNumber
	end
end

function p.halve(frame)
	local checkedNumber = (p.main(frame))
	local halvedNumber
	halvedNumber = (checkedNumber / 2)
	return halvedNumber
end
function p.mainnull(frame)
	local theString = mw.text.unstrip(frame.args[1])
	local onlyNumber
	onlyNumber = (string.match(theString, "%-?[%d%.]+"))
	checkedNumber = tonumber(onlyNumber)
	if checkedNumber == nil then
		return nil
	else
		return checkedNumber
	end
end
return p