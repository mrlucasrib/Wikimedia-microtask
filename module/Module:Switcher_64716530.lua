local p = {}

function p.main(frame)
	local root = mw.html.create('div'):addClass('switcher-container')
	local default = (tonumber(frame.args.default) or 0) * 2 - 1
	for i,v in ipairs(frame.args) do
		if i % 2 == 1 then
			local span = root
				:tag('div')
					:wikitext(frame.args[i])
					:tag('span')
						:addClass('switcher-label')
						:css('display', 'none')
						:wikitext(mw.text.trim(frame.args[i + 1]))
			if i == default then
				span:attr('data-switcher-default', '')
			end
		end
	end
	return root
end

return p