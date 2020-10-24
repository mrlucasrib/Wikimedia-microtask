local p = {}
local randomModule = require('Module:Random')

p.main = function(frame)
	local parent = frame.getParent(frame)
	local parentArgs = parent.args
	local args = cleanupArgs(parentArgs)
	local output = p._main(args)
	return frame:preprocess(output)
end

function cleanupArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				cleanArgs[key] = val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

p._main = function(args)
	if not args[1] then
		return error(linked and 'No page specified' or 'No page specified', 0)
	end
	local lines=makeGalleryLinesTable(args)
	return makeOutput(lines, args.overflow, args.maxheight, args.mode, args.croptop)
end

function makeGalleryLine(file, caption, link)
	local title = mw.title.new(file, "File" )
	local linktext = ( link and '{{!}}link=' .. link  or '' )
	local maxImageWidth = '{{!}}800px'
	return '[[' .. title.prefixedText ..(caption and'{{!}}'..caption or '').. maxImageWidth .. linktext ..']]' .. (caption and '\n<div style="text-align:center;">' .. caption ..'</div>' or '\n') 
end

function makeGalleryLineSlideshow(file, caption)
	local title = mw.title.new(file, "File" )
	local captiontext= '[[File:OOjs_UI_icon_info-progressive.svg|link=:'..title.prefixedText..']]&nbsp;<span style="font-size:110%;">'..(caption or '')..'</span>'
	return title.prefixedText .. '{{!}}' .. captiontext 
end


function makeGalleryLinesTable(args)
	local galleryLinesTable = {}
	local i = 1
	while args[i] do
		if not args.mode then 
			table.insert(galleryLinesTable, makeGalleryLine(args[i], args[i+1],args.link))
		else if args.mode=='slideshow' then
			table.insert(galleryLinesTable, makeGalleryLineSlideshow(args[i], args[i+1], args.link)) 
		else 
			error('Mode not supported')
			end
	end
		i = i + 2
	end
	return galleryLinesTable 
end
function makeOutput(imageLines, overflow, maxHeight, mode, croptop)
	local randomiseArgs = {	['t'] = imageLines }
	local randomisedLines = randomModule.main('array', randomiseArgs )
	local output, galleryContent
	if not mode then
	    galleryContent = table.concat(randomisedLines, '\n',1,1)
	    seperate=mw.text.split(galleryContent,'\n')
		output = '<div class="portal-banner-image" style="max-height:' .. (maxHeight or 'initial') .. '; overflow:'..(overflow or 'auto')..
		';"><div class="portal-banner-image-crop" style="position:relative; margin-top:-'..(croptop or '0')..'%;">'..seperate[1]..'</div></div>'..seperate[2]
	else if mode=='slideshow' then
      	galleryContent = table.concat(randomisedLines, '\n')
		output='<div class="portal-banner-image-slideshow nomobile" style="max-height:' .. (maxHeight or 'initial') .. '; overflow:'..(overflow or 'auto')..
		';"><div class="portal-banner-image-crop" style="position:relative; margin-top:-'..(croptop or '0')..'%;">'..'{{#tag:gallery|'..galleryContent..'|mode=slideshow}}'..'</div></div>'
	else
		error('Mode not supported')
		end
	end
	
		return output
	end
return p