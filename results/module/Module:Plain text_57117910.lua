--converts text with wikilinks to plain text, e.g "[[foo|gah]] is [[bar]]" to "gah is bar"
--removes anything enclosed in tags that isn't nested, mediawiki strip markers (references etc), files, italic and bold markup
local p = {}

function p.main(frame)
	local text = frame.args[1]
	return p._main(text)
end

function p._main(text)
	if not text then return end
	text = mw.text.killMarkers(text)
		:gsub('&nbsp;', ' ') --replace nbsp spaces with regular spaces
		:gsub('<br ?/?>', ', ') --replace br with commas
		:gsub('<span.->(.-)</span>', '%1') --remove spans while keeping text inside
		:gsub('<i.->(.-)</i>', '%1') --remove italics while keeping text inside
		:gsub('<.->.-<.->', '') --strip out remaining tags and the text inside
		:gsub('<.->', '') --remove any other tag markup
		:gsub('%[%[%s*[Ff]ile%s*:.-%]%]', '') --strip out files
		:gsub('%[%[%s*[Ii]mage%s*:.-%]%]', '') --strip out use of image:
		:gsub('%[%[%s*[Cc]ategory%s*:.-%]%]', '') --strip out categories
		:gsub('%[%[[^%]]-|', '') --strip out piped link text
		:gsub('[%[%]]', '') --then strip out remaining [ and ]
		:gsub("'''''", "") --strip out bold italic markup
		:gsub("'''?", "") --not stripping out '''' gives correct output for bolded text in quotes
		:gsub('----', '') --remove ---- lines
		:gsub("^%s+", "") --strip leading
		:gsub("%s+$", "") --and trailing spaces
		:gsub("%s+", " ") --strip redundant spaces
	return text
end

return p