local p = {}

local function doLoop(frame, args, code, sep, offset, argstosub)
	local result = {}
	code = mw.text.unstripNoWiki(code)
	for i, value in ipairs(args) do
		if i > offset then
			argstosub["i"] = i - offset
			argstosub["1"] = value
			local actualCode = code:gsub("{{{([^{}|]*)|?[^{}]*}}}", argstosub)
			table.insert(result, frame:preprocess(actualCode))
		end
	end
	return table.concat(result, sep)
end

function p.main(frame)
	local args = frame:getParent().args
	local sep = args[1]
	local code = args.code or args[2]
	local offset = args.code and 1 or 2
	local start = args.start or 1
	local argstosub = {}
	for key, value in pairs(args) do
		if not tonumber(key) and key ~= "i" and key ~= "count" then
			argstosub[key] = value
		end
	end
	local countArg = args.count and tonumber(args.count);
	if countArg then
		offset = 0
		args = {}
		for i = 1, countArg do
		   args[i] = i + start - 1
		end
	end
	return doLoop(frame, args, code, sep, offset, argstosub)
end
function p.template(frame) 
	local sep = frame.args[1]
	local code = frame.args[2] or frame.args.code
	local offset = tonumber(frame.args.offset) or 0
	return doLoop(frame:getParent(), frame:getParent().args, code, sep, offset, {})
end
return p