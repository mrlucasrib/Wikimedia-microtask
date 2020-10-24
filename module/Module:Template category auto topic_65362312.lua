local getArgs = require('Module:Arguments').getArgs

p = {}

local function main(frame)
	local args = getArgs(frame)
	local title = mw.title.getCurrentTitle()
	local pageName = args.demopage or title.text
	local formatStr = args[1]
	local defaultText = args[2]

	local suffixes = {
		' infobox templates',
		' sidebar templates',
		' stub templates',
		' user templates',
		' category header templates',
		' templates',
		' navboxes',
		' navigational boxes'
	}
	-- possible article name
	local s = pageName
	for _, suffix in pairs(suffixes) do
		if s == pageName then
			s = string.gsub(pageName, suffix, '', 1)
		else
			break
		end
	end
	if s == pageName then
		-- unknown template category naming convention
		return defaultText
	end

	local article = mw.title.makeTitle('', s)
	if article.exists then
		return string.format(formatStr, '[[' .. s .. ']]')
	end
	return defaultText
end
p.main = main

return p