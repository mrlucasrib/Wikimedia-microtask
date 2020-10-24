local p = {}

function p.main(frame)
	return frame:getParent():getTitle()
end

return p