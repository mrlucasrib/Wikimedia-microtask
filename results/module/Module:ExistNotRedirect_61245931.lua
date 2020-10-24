local p = {}

function p.main(args)
	local myArgs = mw.getCurrentFrame():getParent().args
	local myPageName = myArgs[1]
	local forceFileOnly = myArgs.forcefile -- force File: namespace check only
	
	if not myPageName or myPageName == "" then
		return ""
	end
	
	local myPageTitle = mw.title.makeTitle("", myPageName)
	if not myPageTitle then
		error("Invalid page title passed, MediaWiki cannot understand it", 1)
	end
	if myPageTitle.exists
		or not forceFileOnly and myPageTitle.file and myPageTitle.file.exists
	then
		if not myPageTitle.isRedirect then
			return myArgs[1]
		end
	end
	
	return ""
end

return p