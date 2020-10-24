local p = {}

function p.main(frame)
	local args = frame.args
	if args['KML'] then
		args['raw'] = frame:expandTemplate{title = 'Wikipedia:Map data/Wikipedia KML/' .. args['KML']}
	else
		args['raw'] = frame:expandTemplate{title = 'Wikipedia:Map data/Wikipedia KML/' .. frame:getParent():getTitle()}
	end
	
	return frame:preprocess(require('Module:Mapframe')._main(args))
end

return p