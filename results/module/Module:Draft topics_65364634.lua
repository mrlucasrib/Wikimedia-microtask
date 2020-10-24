local getArgs = require('Module:Arguments').getArgs
local p = {}
	
local categories = {
	['biography'] = 'biographies',
	['women'] = 'women',
	['food-and-drink'] = 'food and drink',
	['internet-culture'] = 'internet culture',
	['linguistics'] = 'linguistics',
	['literature'] = 'literature',
	['books'] = 'books',
	['entertainment'] = 'entertainment',
	['films'] = 'films',
	['media'] = 'media',
	['music'] = 'music',
	['radio'] = 'radio',
	['software'] = 'software',
	['television'] = 'television',
	['video-games'] = 'video games',
	['performing-arts'] = 'performing arts',
	['philosophy-and-religion'] = 'philosophy and religion',
	['sports'] = 'sports',
	['architecture'] = 'architecture',
	['comics-and-anime'] = 'comics and anime',
	['fashion'] = 'fashion',
	['visual-arts'] = 'visual arts',
	['geographical'] = 'geographical topics',
	['africa'] = 'Africa',
	['central-africa'] = 'Central Africa',
	['eastern-africa'] = 'Eastern Africa',
	['northern-africa'] = 'Northern Africa',
	['southern-africa'] = 'Southern Africa',
	['western-africa'] = 'Western Africa',
	['central-america'] = 'Central America',
	['north-america'] = 'North America',
	['south-america'] = 'South America',
	['asia'] = 'Asia',
	['central-asia'] = 'Central Asia',
	['east-asia'] = 'East Asia',
	['north-asia'] = 'North Asia',
	['south-asia'] = 'South Asia',
	['southeast-asia'] = 'Southeast Asia',
	['west-asia'] = 'West Asia',
	['eastern-europe'] = 'Eastern Europe',
	['europe'] = 'Europe',
	['northern-europe'] = 'Northern Europe',
	['southern-europe'] = 'Southern Europe',
	['western-europe'] = 'Western Europe',
	['oceania'] = 'Oceania',
	['business-and-economics'] = 'business and economics',
	['education'] = 'education',
	['history'] = 'history',
	['military-and-warfare'] = 'military and warfare',
	['politics-and-government'] = 'politics and government',
	['society'] = 'society',
	['transportation'] = 'transportation',
	['biology'] = 'biology',
	['chemistry'] = 'chemistry',
	['computing'] = 'computing',
	['earth-and-environment'] = 'earth and environment',
	['engineering'] = 'engineering',
	['libraries-and-information'] = 'libraries and information',
	['mathematics'] = 'mathematics',
	['medicine-and-health'] = 'medicine and health',
	['physics'] = 'physics',
	['stem'] = 'STEM',
	['space'] = 'space',
	['technology'] = 'technology'
}

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

function p._main(args)
	local ns = mw.title.getCurrentTitle().namespace
	if ns ~= 118 and ns ~= 2 then
		return '[[Category:Draft topics used in wrong namespace]]'
	end
	local str = ''
	for _, topic in ipairs(args) do
		if topic == 'unsorted' then
			str = str .. '[[Category:Draft articles (unsorted topic)]]'
			break
		end
		local cat = categories[topic]
		if cat ~= nil then
			str = str .. '[[Category:Draft articles on ' .. cat .. ']]'
		else 
			str = str .. '<div class=error>Invalid draft topic: ' .. topic .. 
				'</div>[[Category:Draft articles tagged with invalid topic parameter]]'
		end
	end
	return str
end

return p