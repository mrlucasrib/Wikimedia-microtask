require('Module:No globals')

local p = {}

function p.main(frame)
	local n = tonumber(frame.args.n)
	assert(n, 'You must provide a number for n')
	assert(n == math.floor(n), 'n must be an integer')
	local base = tonumber(frame.args.base or 10)
	assert(base, 'You must provide a number for base')
	assert(base == math.floor(base), 'base must be an integer')
	local digits, counts, outputs = {}, {}, {}
	for k,v in ipairs(frame.args) do
		digits[k] = v
		counts[k] = n % base
		n = (n - counts[k]) / base
	end
	counts[#counts] = counts[#counts] + n * base
	local tail = #digits + 1
	for k,v in ipairs(digits) do
		outputs[k] = v:rep(counts[tail - k])
	end
	return table.concat(outputs)
end

return p