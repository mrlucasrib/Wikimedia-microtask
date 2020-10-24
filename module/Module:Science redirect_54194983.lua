local conf = require( "Module:Science redirect/conf" )

local p = {}

function p.R(frame)
	local template = mw.ustring.gsub(frame.args[1], ' ', '_')
	if conf.templates[template] then
		return p._main(frame, conf.templates[template].name, conf.templates[template].from, conf.templates[template].to, conf.templates[template].category, conf.templates[template].info, conf.templates[template].removeA)
	elseif template then
		return '<span class="error">The template '..template..'is not valid.</span>\n'
	else
		return '<span class="error">No template specified</span>\n'
	end
end

function p._main(frame, name, from, to, category, info, removeA)
	--initialize variables
	local args = frame:getParent().args
	local singleNoun, pluralNoun = '', ''
	local outStr = ''
	
	--Check for known parameter 1
	local cat = mw.ustring.match(mw.ustring.lower(args[1] or 'none'), '^(.-)s?$')
	if conf.cats[cat] then singleNoun, pluralNoun = conf.cats[cat][1], conf.cats[cat][2] else
		singleNoun, pluralNoun = 'an organism'
		outStr = '[[Category:Redirects '..category..' using unknown values for parameter 1]]'
	end
	
	--strip article from singleNoun if removeA is true
	if removeA == true then
		if singleNoun == 'an organism' then singleNoun = '' else singleNoun = (mw.ustring.match(singleNoun, '^an? (.*)$') or singleNoun) end
	end
	
	--support alternative indications for printworthy
	if args[2] == 'unprintworthy' or args['unprintworthy'] == 'true' then args['printworthy'] = 'no' end
	
	--build template arguments
	local main_category = 'Redirects '..category
	if pluralNoun then main_category = main_category..' of '..pluralNoun end
	local outArgs = {
		name = mw.ustring.gsub(name, '$1', singleNoun),
		from = mw.ustring.gsub(mw.ustring.gsub(from, '$1', singleNoun), '$2', (pluralNoun or 'organisms')),
		to = mw.ustring.gsub(mw.ustring.gsub(to, '$1', singleNoun), '$2', (pluralNoun or 'organisms')),
		['main category'] = main_category,
		printworthy = (args['printworthy'] or 'yes'),
		info = info,
	}
	
	--build output string
	if frame.args['debug'] == 'true' then
		local debugStr = '{{Redirect template<br />\n'
		for k,v in pairs( outArgs ) do
			debugStr = debugStr..'| '..k..' = '..v..'<br />\n'
		end
		outStr = debugStr..'}}'..frame:extensionTag{ name = 'nowiki', content = outStr}
	else
		outStr = frame:expandTemplate{ title = 'Redirect template', args = outArgs }..outStr
	end
	
	return outStr
end

return p