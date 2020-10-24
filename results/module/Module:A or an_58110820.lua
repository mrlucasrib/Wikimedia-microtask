local p = {}
local words = mw.loadData('Module:A or an/words')

local lcVChars = 'aeiouà-æè-ïò-öø-üāăąēĕėęěĩīĭįıĳōŏőœũūŭůűų'
local ucVvChars = 'AEFHILMNORSXÀ-ÆÈ-ÏÒ-ÖØĀĂĄĒĔĖĘĚĨĪĬĮıĲŌŎŐŒÑĤĦĹĻĽĿŁŃŅŇŊŔŖŘŚŜŞ'

local function findWord(s, t)
	for i, v in ipairs(t) do
		if mw.ustring.find(s, '^' .. v .. '$') then
			return true
		end
	end
end

function p._main(args)
	local s = args[1] and mw.text.trim(args[1])
	local pron = 'a'
	local ret = ''
	
	if s and s ~= '' then
		local origStr = s
		
		s = mw.ustring.gsub(s, '</?[A-Za-z][^>]->', '') -- Remove HTML tags
		s = mw.ustring.gsub(s, '%[%[[^%|]+%|(..-)%]%]', '%1') -- Remove wikilinks
		s = mw.ustring.gsub(mw.ustring.gsub(s, '%[%[', ''), '%]%]', '')
		s = mw.ustring.gsub(s, '^["%$\'%(<%[%{¢-¥₠-₿]+', '') -- Strip some symbols at the beginning
		s = mw.ustring.match(s, '^%.?[0-9%u%l]+') or s -- Extract the first word
		
		if mw.ustring.find(s, '^[0-9]') then -- It begins with a number
			s = mw.ustring.match(s, '^[0-9]+') -- Extract the number
			if findWord(s, words.vNums) then -- '18' etc.
				pron = 'an'
			end
		elseif mw.ustring.match(s, '^[0-9%u]+$') then -- It looks like an acronym
			if mw.ustring.find(s, '^[' .. ucVvChars .. ']')
				and not findWord(s, words.cvAcronyms) -- Exclude 'NASA' etc.
				or findWord(s, words.vvAcronyms) -- 'UNRWA' etc.
			then
				pron = 'an'
			end
		else
			s = mw.ustring.lower(s) -- Uncapitalize
			if mw.ustring.find(s, '^['.. lcVChars .. ']') then -- It begins with a vowel
				if not findWord(s, words.vcWords) -- Exclude 'euro' etc.
					or findWord(s, words.vvWords) -- But not 'Euler' etc.
				then
					pron = 'an'
				end
			elseif args.variety and mw.ustring.lower(args.variety) == 'us' -- 'herb' etc.
				and findWord(s, words.cvWordsUS)
				or findWord(s, words.cvWords) -- 'hour' etc.
			then
				pron = 'an'
			end
		end
		ret = pron .. ' ' .. origStr
	end
	
	return ret
end

function p.main(frame)
	return p._main(frame:getParent().args)
end

return p