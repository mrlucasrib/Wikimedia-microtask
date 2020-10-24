--
-- This module implements {{Infobox rune}}
--
require('Module:No globals')

local p = {}

local getArgs = require('Module:Arguments').getArgs

local function buildunicode(s)
	local v = mw.text.split(s or '', '[^0-9A-F]')
	local count = 0

	for k = #v, 1, -1 do
		if v[k] and v[k]:match('^[0-9A-F][0-9A-F][0-9A-F][0-9A-F]$') then
			v[k] = '&#x' .. v[k] .. '; ' .. '<div style="display:block;font-size: 30%">U+' .. v[k] .. '</div>'
			count = count + 1
		else
			table.remove(v, k)
		end
	end
	
	if count > 1 then
		local res = mw.html.create()
		local row = res:tag('table')
						:addClass('multicol')
						:css('width', '100%')
						:attr('role', 'presentation')
						:tag('tr')
		for k = 1,#v do
			row:tag('td')
				:css('width', math.floor(100/count) .. '%')
				:wikitext(v[k])
		end
		
		return tostring(res)
	elseif count > 0 then
		return tostring(v[1])
	end
end

local function addCells(row, entries, subcols, fs)
	if type(entries) == 'string' then
		local colspan = subcols[1] + subcols[2] + subcols[3]
		row:tag('td')
			:css('font-size', fs)
			:css('padding', '1px')
			:attr('colspan', colspan)
			:wikitext(entries)
	else
		for k=1,3 do
			if subcols[k] > 0 then
				if entries[k] and type(entries[k]) == 'string' then
					if entries[k] ~= '<same>' then
						local colspan = subcols[k]
						for j=(k+1),3 do
							if entries[j] and entries[j] == '<same>' then
								colspan = colspan + subcols[j]
							else
								break
							end
						end
						row:tag('td')
							:css('font-size', fs)
							:css('padding', '1px')
							:attr('colspan', (colspan > 1) and colspan or nil)
							:wikitext(entries[k])
					end
				elseif entries[k] then
					for j=1,subcols[k] do
						if entries[k][j] then
							row:tag('td')
								:css('font-size', fs)
								:css('padding', '1px')
								:wikitext(entries[k][j])
						else
							row:tag('td')
						end
					end
				else
					for j=1,subcols[k] do
						row:tag('td')
					end
				end
			end
		end
	end
end

function p.infobox(frame)
	local args = getArgs(frame)

	local langlinks = {
		pg = '[[Proto-Germanic language|Proto-Germanic]]',
		oe = '[[Old English]]',
		on = '[[Old Norse]]'
	}
		
	local shapelinks = {
		pg = '[[Elder Futhark]]',
		oe = '[[Anglo-Saxon runes|Futhorc]]',
		on = '[[Younger Futhark]]'
	}
	
	local let2num = {
		a = '1',
		b = '2',
		c = '3',
		d = '4',
		e = '5'
	}
	
	-- fill in the entries
	local entrynames = {'lang',	'name',	'meaning', 'shape', 'unicode hex', 
		'transliteration', 'transcription', 'IPA', 'position'}
	local entries = {}
	for i = 1, #entrynames do
		entries[entrynames[i]] = nil
	end
	
	for k, v in pairs(args) do
		k = '' .. k
		local pre, num, num2, let = nil, nil, nil, nil
		for i = 1, #entrynames do
			pre, num, let = k:match('^(' .. entrynames[i] .. ')([1-3])([a-e]?)$')
			num2 = nil
			if pre then break end
			pre, num, num2 = k:match('^(' .. entrynames[i] .. ')([1-3])([1-3]?)$')
			let = nil
			if pre then break end
		end
		if pre == 'unicode hex' then 
			v = buildunicode(v)
		end
		if num and num ~= '' then
			num = tonumber(num)
			if let and let ~= '' then
				if entries[pre] and type(entries[pre]) == 'table' then
					if entries[pre][num] and type(entries[pre][num]) == 'table' then
						entries[pre][num][tonumber(let2num[let])] = v
					else
						entries[pre][num] = {nil, nil, nil, nil, nil}
						entries[pre][num][tonumber(let2num[let])] = v
					end
				else
					entries[pre] = {nil, nil, nil}
					entries[pre][num] = {nil, nil, nil, nil, nil}
					entries[pre][num][tonumber(let2num[let])] = v
				end
			elseif num2 and num2 ~= '' then
				num2 = tonumber(num2)
				if entries[pre] and type(entries[pre]) == 'table' then
					entries[pre][num] = v
					for i = (num+1),num2 do
						entries[pre][i] = '<same>'
					end
				else
					entries[pre] = {nil, nil, nil}
					entries[pre][num] = v
					for i = (num+1),num2 do
						entries[pre][i] = '<same>'
					end
				end
			else
				if entries[pre] and type(entries[pre]) == 'table' then
					entries[pre][num] = v
				else
					entries[pre] = {nil, nil, nil}
					entries[pre][num] = v
				end
			end
		elseif pre then
			entries[pre] = v
		end
	end

	local subcols = {0, 0, 0}

	-- determine the number of subcolumns per column
	for i = 1, #entrynames do
		local e = entries[entrynames[i]]
		if e then
			if type(e) == 'table' then
				for j = 1,3 do
					if e[j] and type(e[j]) == 'table' then
						local n = #(e[j])
						if n > subcols[j] then
							subcols[j] = n
						end
					elseif e[j] then
						if 1 > subcols[j] then
							subcols[j] = 1
						end
					end
				end
			end
		end
	end

	local lets = {'a', 'b', 'c', 'd', 'e'}
	
	-- build the table
	local root = mw.html.create()

	root = root
		:tag('table')
		:addClass('wikitable')
		:addClass('plainrowheaders')
		:css('float', args.float or 'right')
		:css('clear', (args.float == 'none' and 'both') or args.float or 'right')
		:css('width', args.width or 'auto')
		:css('margin', args.float == 'left' and '0.5em 1.0em 0.5em 0' or '0.5em 0 0.5em 1.0em')
		:css('font-size', '88%')
		:css('text-align', 'center')
	
	local rowspan = 1 + (entries['name'] and 1 or 0) + (entries['meaning'] and 1 or 0)
	-- Name
	local row = root:tag('tr')
	row:tag('th')
		:attr('scope', 'row')
		:attr('rowspan', (rowspan > 1) and rowspan or nil)
		:css('vertical-align', 'middle')
		:wikitext('Name')
	for k=1,3 do
		if subcols[k] > 0 then
			local v = langlinks[(args['lang' .. k] or ''):lower()] or args['lang' .. k]
			row:tag('th')
				:attr('scope', 'col')
				:attr('colspan', (subcols[k] > 1) and subcols[k] or nil)
				:wikitext(v)
		end
	end
	if entries['name'] then
		row = root:tag('tr'):css('font-size', '150%')
		addCells(row, entries['name'], subcols, nil)
	end
	if entries['meaning'] then
		row = root:tag('tr')
		addCells(row, entries['meaning'], subcols, nil)
	end
	if entries['shape'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:attr('rowspan', 2)
			:css('vertical-align', 'middle')
			:wikitext('Shape')
		for k=1,3 do
			if subcols[k] > 0 then
				local v = shapelinks[(args['lang' .. k] or ''):lower()] or ''
				row:tag('th')
					:attr('scope', 'col')
					:attr('colspan', (subcols[k] > 1) and subcols[k] or nil)
					:wikitext(v)
			end
		end
		row = root:tag('tr')
		addCells(row, entries['shape'], subcols, nil)
	end
	if entries['unicode hex'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:css('vertical-align', 'middle')
			:wikitext('[[Runic (Unicode block)|Unicode]]')
		addCells(row, entries['unicode hex'], subcols, '300%')
	end
	if entries['transliteration'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:css('vertical-align', 'middle')
			:wikitext('[[Runic transliteration and transcription|Transliteration]]')
		addCells(row, entries['transliteration'], subcols, '120%')
	end
	if entries['transcription'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:css('vertical-align', 'middle')
			:wikitext(entries['transliteration'] and 'Transcription' 
				or '[[Runic transliteration and transcription|Transcription]]')
		addCells(row, entries['transcription'], subcols, '120%')
	end
	if entries['IPA'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:css('vertical-align', 'middle')
			:wikitext('[[International Phonetic Alphabet|IPA]]')
		addCells(row, entries['IPA'], subcols, '150%')
	end
	if entries['position'] then
		row = root:tag('tr')
		row:tag('th')
			:attr('scope', 'row')
			:css('vertical-align', 'middle')
			:css('line-height', '1.3em')
			:wikitext('Position in<br>rune-row')
		addCells(row, entries['position'], subcols, nil)
	end
	
	return tostring(root)
end

return p