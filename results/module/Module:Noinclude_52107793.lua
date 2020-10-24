local p = {}
function p.noinclude(frame)
	return frame:getParent():preprocess("<noinclude>" .. frame.args.text .. "</noinclude>");
end
return p