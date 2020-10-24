require('Module:No globals')

local p = {}

-- key is beginning of arg name. value is table with namespace number and link
-- alternatively, a function taking the namespace number and returning a validity
-- can be used
local namespaceCategories = {
	all = { function() return true end },
	main = { 0, '[[wp:mainspace|main]]' },
	help = { 12, '[[wp:help namespace|help]]' },
	portal = { 100, '[[wp:portal|portal]]' },
	talk = { function(n) return n > 0 and n%2 == 1 end, '[[Help:Using talk pages|talk]]' },
	template = { 10, '[[wp:template namespace|template]]' },
	wikipedia = { 4, '[[wp:project namespace|Wikipedia project]]' },
	category = { 14, '[[wp:categorization|category]]' },
	user = { 2, '[[wp:user pages|user]]' },
}

-- remove whitespaces from beginning and end of args
local function valueFunc(key, val)
	if type(val) == 'string' then
		val = val:match('^%s*(.-)%s*$')
		if val == '' then
			return nil
		end
	end
	return val
end

local function getPrettyName(args)
	for k in pairs(namespaceCategories) do
		if args[k .. ' category'] then
			return string.format("'''[[:Category:%s|%s]]''': ", args[k .. ' category'], args.name)
		end
	end
	return string.format("'''%s''': ", args.name)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {wrappers = 'Template:Redirect template', valueFunc = valueFunc})
	local namespace = mw.title.getCurrentTitle().namespace

	--- XXX: this is a HORRIBLE HACK. kill it with fire as soon as https://bugzilla.wikimedia.org/show_bug.cgi?id=12974 is fixed
	local beCompatibleWithBug12974 = args.info and (args.info:find('^[:;#*]', 1) == 1 or args.info:find('{|', 1, true) == 1) and '\n' or ' '
	
	local content = string.format('\n<div class="rcat %s">\n*%sThis is a redirect%s%s.%s%s\n</div>',
		args.id and ('rcat-' .. string.gsub(args.id, ' ', '_')) or '',
		args.name and getPrettyName(args) or '',
		args.from and (' from ' .. args.from) or '',
		args.to and (' to ' .. args.to) or '',
		args.info and beCompatibleWithBug12974 or '',
		args.info or ''
	)
	
	for k,v in pairs(namespaceCategories) do
		if args[k .. ' category'] then
			if type(v[1]) == 'function' and v[1](namespace) or v[1] == namespace then
				content = content .. string.format('[[Category:%s]]', args[k .. ' category'])
			elseif args['other category'] then
				content = content .. string.format('[[Category:%s]]', args['other category'])
			else
				content = content .. frame:expandTemplate{title = 'Incorrect redirect template', args = {v[2]}}
			end
		end
	end

	if namespace == 0 then
		local yesno = require('Module:Yesno')
		if yesno(args.printworthy) == true then
			return content .. '[[Category:Printworthy redirects]]'
		elseif yesno(args.printworthy) == false then
			return content .. '[[Category:Unprintworthy redirects]]'
		end
	end
	return content
end

return p