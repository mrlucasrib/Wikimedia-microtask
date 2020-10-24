local p = {}

function p.fetch(frame)
	local template = nil
	local return_value = nil

	-- Use demo parameter if it exists, otherswise use current template name
	local namespace = mw.title.getCurrentTitle().namespace
	if frame.args["demo"] and frame.args["demo"] ~= "" then
		template = frame.args["demo"]
	elseif namespace == 10 then -- Template namespace
		template = mw.title.getCurrentTitle().text
	elseif namespace == 828 then -- Module namespace
		template = (mw.site.namespaces[828].name .. ":" .. mw.title.getCurrentTitle().text)
	end

	-- If in template or module namespace, look up count in /data
	if template ~= nil then
		namespace = mw.title.new(template, "Template").namespace
		if namespace == 10 or namespace == 828 then
			template =  mw.ustring.gsub(template, "/doc$", "") -- strip /doc from end
			local index = mw.ustring.sub(mw.title.new(template).text,1,1)
			local data = mw.loadData('Module:Transclusion_count/data/' .. (mw.ustring.find(index, "%a") and index or "other"))
			return_value = tonumber(data[mw.ustring.gsub(template, " ", "_")])
		end
	end
	
	-- If database value doesn't exist, use value passed to template
	if return_value == nil and frame.args[1] ~= nil then
		local arg1=mw.ustring.match(frame.args[1], '[%d,]+')
		if arg1 and arg1 ~= '' then
			return_value = tonumber(frame:callParserFunction('formatnum', arg1, 'R'))
		end
	end
	
	return return_value	
end

return p