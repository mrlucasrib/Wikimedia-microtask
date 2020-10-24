-- 20181117
local getArgs = require('Module:Arguments').getArgs
local p = {}
local data_sy = {}
local data_id = {}
local data_property = {}
local data_nonmain = {}

function p.main(frame)
	local args = getArgs(frame)
	data_sy = {['H'] = true, ['Hg'] = true}
	data_id = {['H'] = {1, Q556}, ['Hg']= {80, Q925} } -- index: 1=Z, 2=QID
	return p._main(args)
end

function p._main(args)
local s -- symbol
local id = {} -- id set
local d -- data
local f -- format
local id

sy = data_sy[args["s"]]
if sy then else
	return args["s"] .. ": not a symbol"
end

id = data_id[args["s"]] or nil

	s = args["s"] or '-'
	d = args["d"] or '-'
	f = args["format"] or args["f"] or '-'
	return 's:' .. s .. ' d:' .. d .. ' f:' .. f .. ''
	
end
	
return p;