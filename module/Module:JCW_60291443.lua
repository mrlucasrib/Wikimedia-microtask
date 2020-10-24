local p = {}
local mArguments = require('Module:Arguments')
local TableTools = require('Module:TableTools')

function p.selected(frame)
	local n = mArguments.getArgs(frame, {parentOnly = true})
	local note = n.note
	local wantSource = {
		['User:JL-Bot/Questionable.cfg'] = true,
	}
	--local abbrev = {BLJ = '[https://beallslist.weebly.com/standalone-journals.html BLJ]', BLJU='[https://beallslist.weebly.com/standalone-journals.html BLJU]', BLP='[https://beallslist.weebly.com/ BLP]', BLPU='[https://beallslist.weebly.com/ BLPU]', SPJJ = '[https://predatoryjournals.com/journals/ SPJJ]', SPJP = '[https://predatoryjournals.com/publishers/ SPJP]', DOAJ='[https://blog.doaj.org/2014/08/28/some-journals-say-they-are-in-doaj-when-they-are-not/ Lying about DOAJ]', QW ='[https://www.quackwatch.org/04ConsumerEducation/nonrecperiodicals.html QW]',	DEPS ='[[WP:DEPS|DEPS]]', URF ='[[#Unreliable fields|URF]]'}
	local abbrev = {Bohannon = 'Bohannon', BLJ = 'BLJ', BLJU= 'BLJU', BLP = 'BLP', BLPU = 'BLPU', SPJJ ='SPJJ', SPJP ='SPJP', DOAJ = 'DOAJ', QW='QW', DEPS ='DEPS', URF = 'URF', Unknown = 'Unknown'}
	local source
	if wantSource[mw.title.getCurrentTitle().fullText] then
		source = n.source or 'Unknown'
		source = abbrev[source] or source
	end
	local sourcenote
	if note and source then
		sourcenote = string.format('&nbsp;(%s) &#91;%s&#93;', source, note)
	elseif source then
		sourcenote = string.format('&nbsp;(%s)', source)
	elseif note then
		sourcenote = string.format('&nbsp;&#91;%s&#93;', note)
	else
		sourcenote = ''
	end
	local rows = {}
	for i, v in ipairs(TableTools.compressSparseArray(n)) do
		if i == 1 then
			rows[i] = { string.format('* [[:%s]]%s', v, sourcenote) }
		else
			rows[i] = string.format('** [[:%s]]', v)
		end
	end
	if not rows[1] then
		error('Need at least one target parameter', 0)
	end
	for _, param in ipairs({ 'imprint', 'parent' }) do
		for i = 1, 10 do
			local arg = n[param .. i]
			if arg then
				table.insert(rows[1], string.format("''[[%s]]''", arg))
			end
		end
	end

	if n.doi and n.doi1 then
		error('Use doi or doi1, not both', 0)
	end
	local search = 'https://en.wikipedia.org/w/index.php?sort=relevance&title=Special%3ASearch&profile=advanced&fulltext=1&advancedSearch-current={}&ns0=1&ns118=1&search=insource%3A'
	local suffix = '%5C%2F%20*%2F'
	for i = 1, 10 do
		local doi
		if i == 1 then
			doi = n.doi or n.doi1
		else
			doi = n['doi'	.. i]
		end
		if not doi then
			break
		end
		table.insert(rows,
			string.format('** <code>&#123;{doi|[%s%s%s %s]}&#125;</code>', search, doi:gsub('10%.', '\/10\\.'), suffix, doi)
		)
	end
	rows[1] = table.concat(rows[1], ' / ')
	return table.concat(rows, '\n')
end

function p.exclude(frame)
	local n = mArguments.getArgs(frame, {parentOnly = true})
	local length = TableTools.length(n)
	local text = string.format('*[[:%s]]', n[1] or '')
	n[1] = nil
	for _, v in ipairs(TableTools.compressSparseArray(n)) do
		if length > 1 then
			text = text..string.format(" ≠ [[:%s]]", v)
		end
	end
	return text
end

function p.pattern(frame)
	local n = mArguments.getArgs(frame, {parentOnly = true})
	local text = string.format('*[[%s]]', n[1] or '')
	n[1] = nil --make next loop only target arguments >=2
	for _, v in ipairs(TableTools.compressSparseArray(n)) do
		text = text..string.format("\n** <code>%s</code>", v)
		text = mw.ustring.gsub(text, "%.%*", "<b><font style=color:#006400;>.*</font></b>")
		text = mw.ustring.gsub(text, "!", "<b><font style=color:#8B0000;>!</font></b>")
		text = mw.ustring.gsub(text, "'", "&rsquo;")
	end
	return text
end

return p