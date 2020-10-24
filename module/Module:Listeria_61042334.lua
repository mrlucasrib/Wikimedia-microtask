local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType
local p = {}

p.show_tabbed_data = function (frame)
	mArguments = require('Module:Arguments')
	args = mArguments.getArgs(frame)
	return p._show_tabbed_data(args)
end


p._show_tabbed_data = function (args)
	checkType('_show_tabbed_data', 1, args, 'table', true)
	args = args or {}
	local lang = "en" -- This should be generated automatically, but I don't know how it is exposed to Lua
	local wiki = "enwiki" -- This should be generated automatically, but I don't know how it is exposed to Lua
	local tab_file = "Listeria/" .. wiki .. "/" .. args.page .. ".tab"
	local ret = "Using: '" .. args.page .. "'" .. " as file " .. tab_file .. "\n"
	local tab = mw.ext.data.get(tab_file,lang)
	if tab == nil then
		error("Could not load data from "..tab_file)
	end
	ret = ret .. "{| class=\"wikitable sortable jquery-tablesorter\"\n"
	for colnum,col in pairs(tab.schema.fields) do
		if colnum > 1 then
			local header = col.title
			if header == nil then
				header = col.name
			end
			ret = ret .. "! " .. header .. "\n"
		end
	end
	for rownum,row in pairs(tab.data) do
		ret = ret .. "|-\n"
		for colnum,cell in pairs(row) do
			if colnum > 1 then
				ret = ret .. "| " .. cell .. "\n"
			end
		end
	end
	ret = ret .. "\n|}\n"
	return ret
end

return p