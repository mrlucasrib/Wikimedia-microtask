local p = {}

function p.main(frame)
	local pframe = frame:getParent()
	local currentTitle = mw.title.getCurrentTitle()
	local passedTitle = pframe and pframe.args[1]
	local targetPage = mw.title.makeTitle(currentTitle.namespace == 2 and 2 or 10, (passedTitle or currentTitle.text) .. ' graphical timeline')
	if targetPage.exists then
		if mw.isSubsting() then
			return '{{' .. (currentTitle.namespace == 2 and 'User:' or '') .. targetPage.text .. '}}'
		else
			return frame:expandTemplate{title = targetPage.prefixedText}
		end
	else
		if mw.isSubsting() then
			if passedTitle then
				return '{{safesubst:Include timeline|1=' .. passedTitle .. '}}'
			else
				return '{{safesubst:Include timeline}}'
			end
		else
			return require('Module:Message box').main('mbox', {
				type = 'move',
				image = '[[File:Splitsection.gif|40px|New article]]',
				text = string.format(
					"Click [%s here to start a '''horizontal''' timeline], or [%s here for a '''vertical''' one].\n\nOnce you've finished, save this article page; your timeline will be included here!\n\n''For more details, visit {{[[Template:Include timeline|include timeline]]}}''",
					targetPage:fullUrl('action=edit&editintro=Template%3AInclude_timeline%2Fhorizontal_instructions&preload=Template%3AInclude_timeline%2Fhorizontal_template'),
					targetPage:fullUrl('action=edit&editintro=Template%3AInclude_timeline%2Fvertical_instructions&preload=Template%3AInclude_timeline%2Fvertical_template')
				)
			})
		end
	end
	return ''
end

return p