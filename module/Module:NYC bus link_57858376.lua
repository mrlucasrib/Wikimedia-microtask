require('Module:No globals');
local getArgs = require('Module:Arguments').getArgs
local p = {}

function p.getLink(frame)
	local args = getArgs(frame);
	local result = {};
	local city;
	
	args.city = args.city:lower();
	
	if 'nyc' == args.city then
		city = 'New York City bus';
	elseif 'li' == args.city then
		city = 'Long Island bus';
	elseif 'nj' == args.city then
		city = 'New Jersey bus';
	else
		return table.concat ({'<span style=\"font-size:100%; font-style:normal;\" class=\"error\">unexpected city: ', args.city, '</span>'})
	end
		
	for _, name in ipairs (args) do
		table.insert (result, table.concat ({'[[', name, ' (', city, ')|', name, ']]'}))
	end
	
	if ('yes' == args.prose) or ('y' == args.prose) then
		return mw.text.listToText (result);
	else
		return table.concat (result, ', ');
	end
end

return p;