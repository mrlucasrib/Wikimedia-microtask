local getArgs = require('Module:Arguments').getArgs
local TableTools = require('Module:TableTools')
local messages = mw.loadData('Module:Succession table monarch/messages')

local p = {}

p.fromArgs = function(argElements)
	local mainTag = mw.html.create('table')
		:attr('cellspacing', '0')
		:css('text-align', 'center')
		:tag('tr')
			:tag('th'):cssText('width: 25%; border: solid #aaa; border-width: 1px 1px 1px 1px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.name or 'Name'):done()
			:tag('th'):cssText('width: 10%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.lifespan or 'Lifespan'):done()
			:tag('th'):cssText('width: 10%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.reignStart or 'Reign start'):done()
			:tag('th'):cssText('width: 10%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.reignEnd or 'Reign end'):done()
			:tag('th'):cssText('width: 25%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.notes or 'Notes'):done()
			:tag('th'):cssText('width: 10%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.family or 'Family'):done()
			:tag('th'):cssText('width: 10%; border: solid #aaa; border-width: 1px 1px 1px 0px; background: #B9D1FF; font-size: 105%;'):wikitext(messages.image or 'Image'):done()
			:done()
	
	for _,eachElement in ipairs(argElements) do
		if eachElement.name then
			local namePlainList = ''
			if eachElement.nickname or eachElement.native then
				namePlainList = mw.getCurrentFrame():expandTemplate{
					title = messages.plainlistTemplateName or 'Plainlist',
					args = {'\n' .. 
						table.concat(TableTools.compressSparseArray({
							eachElement.nickname and ('* ' .. tostring(mw.html.create('small'):wikitext("<i>" .. eachElement.nickname .. "</i>"))) or nil,
							eachElement.native and ('* ' .. eachElement.native) or nil
					}), '\n')}
				}
			end
			local rowTr = mainTag:tag('tr')
			
			rowTr:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 1px; background: #F0F8FF; vertical-align: middle;')
					:wikitext(eachElement.name .. namePlainList)
					:done()
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
					:wikitext(eachElement.life)
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
					:wikitext(eachElement.reignstart)
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
					:wikitext(eachElement.reignend)
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
					:wikitext(eachElement.notes)
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
					:wikitext(eachElement.family)
			
			local imageTd = rowTr
				:tag('td')
					:cssText('border: solid #aaa; border-width: 0px 1px 1px 0px; background: white;')
			if eachElement.image then
				imageTd:tag('span')
					:addClass('photo')
					:wikitext('[[File:' .. eachElement.image .. '|80px|alt=' .. (eachElement.alt or '') .. ']]')
			end
		end
	end
	return tostring(mainTag)
end

p.fromArray = function(args)
	local argElements = TableTools.numData(args, true)
	return p.fromArgs(argElements)
end

p.fromFrame = function(frame)
	local args = getArgs(frame)
	return p.fromArray(args)
end

return p