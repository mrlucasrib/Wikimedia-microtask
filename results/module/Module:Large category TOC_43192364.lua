local p = {}

local azupper = mw.text.split('ABCDEFGHIJKLMNOPQRSTUVWXYZ','')
local azlower = mw.text.split('abcdefghijklmnopqrstuvwxyz','')
local aejot = mw.text.split('aejot','')

function p.scrollable(frame)
	return main('scrollable')
end

function p.collapsible(frame)
	return main('collapsible')
end

function p.aejot(frame)
	return main('aejot')
end

function main(toc_type)
	-- It should be much faster to only process these once, and just re use them as variables
	local pageurl = mw.title.getCurrentTitle():fullUrl()
	local toc = mw.message.new('Toc'):plain()
	
	-- Highest level div
	local toc_frame = mw.html.create('div')
				:addClass('plainlinks')
				:addClass('hlist')
				:addClass('toc')
				-- :attr('id','toc')
				:css({ display = 'block !important',
						background = 'WhiteSmoke',
						clear = 'both',
						width = '98%' })

	-- Contains "Content: Top 0-9 A - Z"
	local header = toc_frame:tag('div')
				:attr('id','toctitle')
				:attr('class','toctitle')
				:css('background','WhiteSmoke')
	
	-- Contains all the rest
	local body_wrapper
	local body = toc_frame:tag('div')
					:css('text-align', 'center')
	
	if toc_type == 'collapsible' then
		toc_frame:addClass('NavFrame')
		header:addClass('NavHead')
		body:addClass('NavContent')
			:css({ background = 'white',
					display = 'none' })
	elseif toc_type == 'scrollable' then
		body:css({ ['overflow-x'] = 'scroll',
					['overflow-y']= 'hidden',
					['white-space'] = 'nowrap' })
	end
	
	local header_content = {'<strong>',toc,':</strong>',
						' [',pageurl,' Top]',
						' [',pageurl,'?from=0 0–9]' }
	
	for _, v in ipairs(azupper) do
		table.insert(header_content,string.format(' [%s?from=%s %s]',pageurl,v,v))
	end
	header:wikitext(table.concat(header_content))
	
	local body_content = {}
	
	if toc_type == 'collapsible' then
		table.insert(body_content,'<b>#</b> ')
		body_wrapper = body:tag('code')
						:css('background','White')
	else
		table.insert(body_content,'['..pageurl..'?from=* <b>*</b>] <b>#</b> ')
		body_wrapper = body:tag('span')
	end
	
	for i=0,9 do
		table.insert(body_content,string.format(' [%s?from=%s %s]',pageurl,i,i))
	end
	
	local function atoz(letter)
		local azlist = {}
		local letterlist
		if toc_type == 'aejot' then
			letterlist = aejot
		else
			letterlist = azlower
		end
				
		if toc_type == 'aejot' or toc_type == 'scrollable' then
			table.insert(azlist,' • <b>'..letter..'</b> ')
		else
			table.insert(azlist,'<br /><b>'..letter..'</b> ')
		end
			
		for _, v in ipairs(letterlist) do
			table.insert(azlist,string.format(' [%s?from=%s%s %s%s] ',pageurl,letter,v,letter,v))
		end
		return table.concat(azlist)
	end
	
	for _, v in ipairs(azupper) do
		table.insert(body_content,atoz(v))
	end
	
	body_wrapper:wikitext(table.concat(body_content))
	
	return '__NOTOC__\n'..tostring(toc_frame)
end

return p