-- This module implements {{listen}}.

local mFileLink = require('Module:File link')
local mTableTools = require('Module:TableTools')
local mSideBox = require('Module:Side box')

local p = {}
local hasMissing -- For the tracking category

function p.main(frame)
	local origArgs = frame:getParent().args
	local args = {}
	for k, v in pairs(origArgs) do
		v = v:match('^%s*(.-)%s*$')
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

function p._main(args)
	-- Find whether we are outputting a plain or an embedded box.
	local isPlain = args.plain == 'yes'
	local isEmbedded = args.embed and true

	-- Organise the arguments by number.
	local numArgs = {}
	do
		local origNumArgs = mTableTools.numData(args)
		origNumArgs[1] = origNumArgs.other -- Overwrite args.filename1 etc. with args.filename etc.
		origNumArgs = mTableTools.compressSparseArray(origNumArgs)
		for i, t in ipairs(origNumArgs) do
			-- Check if the files exist.
			local obj = t.filename and mw.title.new('Media:' .. t.filename)
			if obj and obj.exists then
				numArgs[#numArgs + 1] = t
			else
				hasMissing = true
			end
		end
		-- Exit early if none exist.
		if #numArgs == 0 then
			return p.renderTrackingCategories(isPlain, true)
		end
	end

	-- Build the arguments for {{side box}}
	local sbargs = {}
	sbargs.class = 'noprint'
	sbargs.metadata = 'no'
	sbargs.position = args.pos

	-- Style arguments
	do
		local style = {}
		if isPlain then
			style[#style + 1] = 'border:none'
			style[#style + 1] = 'background:transparent'
			style[#style + 1] = 'float:none'
		end
		if isEmbedded then
			style[#style + 1] = 'border-collapse:collapse'
			style[#style + 1] = 'border-width:1px 0 0 0'
			style[#style + 1] = 'background:transparent'
			style[#style + 1] = 'float:none'
			style[#style + 1] = 'margin:0 -5px'
		end
		if args.pos == 'left' then
			style[#style + 1] = 'float:left'
		elseif args.pos == 'center' then
			style[#style + 1] = 'float:none'
			style[#style + 1] = 'margin-left:auto'
			style[#style + 1] = 'margin-right:auto'
		end
		
		style[#style + 1] = args.style
		sbargs.style = table.concat(style, '; ')
	end
	sbargs.textstyle = 'line-height:1.1em'

	-- Image
	if not isPlain and not isEmbedded then
		if args.image then
			sbargs.image = args.image
		else
			local images = {
				speech = 'Audio-input-microphone.svg',
				music = 'Gnome-mime-audio-openclipart.svg'
			}
			local image = args.type
				and images[args.type]
				or 'Gnome-mime-sound-openclipart.svg'
			sbargs.image = mFileLink._main{
				file = image,
				size = '65x50px',
				location = 'center',
				link = '',
				alt = ''
			}
		end
	end

	-- Text
	do
		local header
		if args.header then
			header = mw.html.create('div')
			header:css{
				background = 'transparent',
				['text-align'] = 'left',
				padding = args.embed and '2px 0' or '2px'
			}
				:wikitext(args.header)
			header = tostring(header)
			header = header .. '\n'
		else
			header = ''
		end
		local text = {}
		for i, t in ipairs(numArgs) do
			text[#text + 1] = p.renderRow(
				t.filename, t.title, t.play, t.alt, t.description, t.start
			)
			if numArgs[i + 1] then
				text[#text + 1] = '<hr/>'
			end
		end
		sbargs.text = header .. table.concat(text)
	end

	-- Below
	if not isPlain and not isEmbedded and args.help ~= 'no' then
		sbargs.below = string.format(
			'<hr/><i class="selfreference">Problems playing %s? See [[Help:Media|media help]].</i>',
			#numArgs == 1 and 'this file' or 'these files'
		)
	end

	-- Render the side box.
	local sideBox = mSideBox._main(sbargs)

	-- Render the tracking categories.
	local trackingCategories = p.renderTrackingCategories(isPlain)

	return sideBox .. trackingCategories
end

function p.renderRow(filename, title, play, alt, description, start)
	-- Renders the HTML for one file description row.
	if not filename then
		return nil
	end
	local root = mw.html.create('')
	root:tag('div')
		:addClass('haudio')
		:newline()
		:tag('div')
			:css('padding', '4px 0')
			:wikitext(string.format('[[:File:%s|%s]]', filename, title or ''))
			:done()
		:newline()
		:tag('div')
			:wikitext(
				play ~= 'no'
					and mFileLink._main{
						file = filename,
						size = '220px',
						alt = alt,
						start = start
					}
					or nil
			)
			:done()
		:newline()
		:tag('div')
			:css('padding', '2px 0 0 0')
			:addClass('description')
			:wikitext(description)
			:done()
		:done()
	return tostring(root)
end

function p.renderTrackingCategories(isPlain, isEmpty, titleObj)
	-- Renders all tracking categories produced by the template.
	-- isPlain and isEmpty are passed through from p._main,
	-- and the titleObj is only used for testing purposes.
	local cats = {}
	local currentTitle = titleObj or mw.title.getCurrentTitle()
	if currentTitle.namespace == 0 then
		-- We are in mainspace.
		if not isEmpty then
			cats[#cats + 1] = 'Articles with hAudio microformats'
		end
		if hasMissing then
			cats[#cats + 1] = 'Articles with empty listen template'
		end
	end
	if isPlain then
		cats[#cats + 1] = 'Listen template using plain parameter'
	end
	for i, cat in ipairs(cats) do
		cats[i] = string.format('[[Category:%s]]', cat)
	end
	return table.concat(cats)
end

return p