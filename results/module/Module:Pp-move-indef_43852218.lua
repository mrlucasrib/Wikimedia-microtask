-- This module implements [[Template:Pp-move-indef]].

local p = {}

function p.main(title)
	if type(title) == 'string' then
		title = mw.title.new(title)
	elseif type(title) ~= 'table' or not title.text or not title.getContent then
		-- The title parameter is absent or not a title object. It could be a
		-- frame object if we are being called from #invoke.
		title = mw.title.getCurrentTitle()
	end
	
	local level = title
		and title.protectionLevels
		and title.protectionLevels.move
		and title.protectionLevels.move[1]
	local namespace = title and title.namespace

	local category
	if level == 'sysop' or level == 'templateeditor' then
		if namespace == 2 or namespace == 3 then
			category = 'Wikipedia move-protected user and user talk pages'
		elseif namespace == 4 or namepace == 12 then
			category = 'Wikipedia move-protected project pages'
		elseif namespace == 100 then
			category = 'Wikipedia move-protected portals'
		elseif title.isTalkPage then
			category = 'Wikipedia move-protected talk pages'
		else
			category = 'Wikipedia indefinitely move-protected pages'
		end
	else
		category = 'Wikipedia pages with incorrect protection templates'
	end

	return string.format(
		'[[%s:%s|%s]]',
		mw.site.namespaces[14].name, -- "Category"
		category,
		title.text -- equivalent of {{PAGENAME}}
	)
end

return p