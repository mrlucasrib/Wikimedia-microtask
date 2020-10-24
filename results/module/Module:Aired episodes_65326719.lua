
function oneEpisode(value, one_return, more_return)
	return (tonumber(value) == 1 and one_return or more_return)
end

function lessThanTenEpisodes(frame, value)
	return (tonumber(value) < 10 and frame:expandTemplate{title='Number to word',args={value}} or value)
end

local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Aired episodes'
	})
	args = args or {}
	
	local airedEpisodes = ''
	local numberEpisodes = args.num or frame:expandTemplate{title='Template parameter value',args={args.showpage or args.title, 'Infobox television', 1, 'num_episodes', 1}}
	local showName = (args.showpage and frame:expandTemplate{title='PAGENAMEBASE',args={args.showpage}} or args.title):gsub("''", '')
	local isAllFinished = (args.finished == 'all')
	
	if isAllFinished then
		airedEpisodes = airedEpisodes .. 'During the course of the ' .. (args.uk and 'programme' or 'series') .. ','
	else
		if args.date then
			airedEpisodes = airedEpisodes .. 'As of' .. args.date .. ','
		else
			airedEpisodes = airedEpisodes .. frame:expandTemplate{title='As of',args={args[1], args[2], args[3], post=',', df=(args.uk and '' or 'US')}}
		end
	end
	 
	airedEpisodes = airedEpisodes .. ' ' .. lessThanTenEpisodes(frame, numberEpisodes) .. ' episode' .. oneEpisode(numberEpisodes, '', 's') .. " of ''" .. showName .. "''"
	
	if not isAllFinished then
		airedEpisodes = airedEpisodes .. ' ' .. oneEpisode(numberEpisodes, 'has', 'have')
	end
	
	airedEpisodes = airedEpisodes .. ' ' .. (args.released and ((isAllFinished and 'were' or 'been') .. ' released') or 'aired')
	
	if args.specials then
		airedEpisodes = airedEpisodes .. ', including ' .. lessThanTenEpisodes(frame, args.specials) .. ' special' .. oneEpisode(args.specials, '', 's')
	end
	
	if args.finished then
		if isAllFinished then
			if args.seasons then
				airedEpisodes = airedEpisodes .. ' over ' .. lessThanTenEpisodes(frame, args.seasons) .. ' ' .. (args.uk and 'series' or ('season' .. oneEpisode(args.seasons, '', 's')))
			end
			
			if args[1] then
				if args[4] then
					airedEpisodes = airedEpisodes .. ', between ' .. frame:expandTemplate{title='Date',args={args[1]..'-'..(args[2] or '')..'-'..(args[3] or ''), (args.uk and 'DMY' or 'MDY')}} .. (args.uk and '' or ',')	.. ' and ' .. frame:expandTemplate{title='Date',args={(args[4] or '')..'-'..(args[5] or '')..'-'..(args[6] or ''), (args.uk and 'DMY' or 'MDY')}}
				else
					airedEpisodes = airedEpisodes .. ', concluding on ' .. frame:expandTemplate{title='Date',args={args[1]..'-'..(args[2] or '')..'-'..(args[3] or ''), (args.uk and 'DMY' or 'MDY')}}
				end
			end
		else
			airedEpisodes = airedEpisodes .. ', concluding the ' .. ((tonumber(args.finished) == math.floor(tonumber(args.finished))) and '' or 'first half of the ') .. frame:expandTemplate{title='Ordinal to word',args={math.floor(tonumber(args.finished))}} .. ' ' .. (args.uk and 'series' or 'season')
		end
	elseif args.airing then
		airedEpisodes = airedEpisodes .. ', currently in its ' .. frame:expandTemplate{title='Ordinal to word',args={math.floor(tonumber(args.airing))}} .. ' ' .. (args.uk and 'series' or 'season')
	end
	
	airedEpisodes = airedEpisodes .. '.'
	
	local title = mw.title.getCurrentTitle()
	if title.namespace == 0 then
		if args.showpage == args.title then
			airedEpisodes = airedEpisodes .. '[[Category:Template:Aired episodes using equal showpage and title parameters]]'
		end
		
		if args.showpage and args.title then
			airedEpisodes = airedEpisodes .. '[[Category:Template:Aired episodes using both showpage and title parameters]]'
		end
	end
	
	return airedEpisodes
end

return p