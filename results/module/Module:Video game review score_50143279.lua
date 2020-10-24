local vgwd = require('Module:Video game wikidata')
local yesno = require('Module:Yesno')

local p = {}

function p._main(frame, args)
	local ret = vgwd.setReviewer(args["reviewer"])
	vgwd.setDateFormat(args["df"])
	ret = vgwd.setGame(args["game"])
	vgwd.setSystem(args["system"])
	vgwd.setGenerateReferences(args['showRefs'])
	vgwd.setSystemFormat(args['systemFormat'])
	vgwd.setUpdateLinkStyle(args['updateLinkStyle'])
	
	-- Old template argument, may change later
	if(args["proseScore"]) then
		local proseScore = yesno(args["proseScore"], false);
		if(proseScore and args["system"] ~= nil and args["system"] ~= '') then
			vgwd.setGenerateReferences(false)
			vgwd.setShowSystem(false)
			vgwd.setShowUpdateLink(false)
		end
	end;

	if(ret == nil) then
		ret = vgwd.printReviewScores(frame);
	end;
	
	return ret;
end;

-- Template main function
function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Video game review score'
	})
	return p._main(frame, args);
end;

return p