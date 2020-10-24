--
-- This module implements {{Wikipedia:Co-op/Mentor profile}} and {{Wikipedia:Co-op/Learner profile}}
--
local getArgs = require('Module:Arguments').getArgs
local TableTools = require('Module:TableTools')
local p = {}

function chooseCategory(cat_table, cat_table_name, cat_path, args)
	-- adds categories to the child page based on template param values
	local cat
	if (args[cat_table_name] and string.len(args[cat_table_name]) > 0) then
		for k,v in pairs(cat_table) do
			if stringSpacesToUnderscores(stringToLowerCase(args[cat_table_name])) == k then
				cat = cat_path .. v
				break
			end
		end
	end
	return cat
end

function getCategories(data, args)
 	-- looks for args that have associated categories,
 	-- returns a string with a list of wikilinked categories
 	-- also appends any default categories you specify
	local cat_list = {}
	if data.categories.default then
		table.insert(cat_list, data.categories.default)
	end
	for k,v in pairs(data.fields) do
		if (data.fields[k].hasCategories == true and type(data.categories[k]) == "table") then
			table.insert(cat_list, chooseCategory(data.categories[k], k, data.fields[k].cat_path, args))
		elseif (data.fields[k].hasCategories == true and args[k] and stringToLowerCase(args[k]) == "1") then
			table.insert(cat_list, data.categories[k])
		end	
	end
	local page_categories = " [[" .. tostring(table.concat(cat_list, "]] [[")) .. "]]"
	return page_categories
end

function nodeBuilder(arg_data, arg_value)
	local field_div = mw.html.create('div')
	if arg_data.ftype == "image" then	
		field_div
			:cssText(arg_data.style1)
			:wikitext("[[" .. arg_value .. "|" .. arg_data.style2 .. "]]")
			:done()		
	elseif arg_data.ftype == "wikilink" then
		field_div
			:cssText(arg_data.style1)
			:wikitext("[[User_talk:" .. arg_value .. "|" .. arg_value .. "]]")
			:done()	
	elseif arg_data.ftype == "text" then
		field_div
			:cssText(arg_data.style1)
			:wikitext(arg_data.prefix .. arg_value)
			:done()	
	elseif arg_data.ftype == "choice" then
		field_div
			:cssText(arg_data.style1)
			:wikitext(arg_data.prefix)
			:done()			
	end
	field_div:allDone()
	return field_div
end			

function insertProfileFields(ranked_fields, profile_div)
	ranked_fields = TableTools.compressSparseArray(ranked_fields)
	for k, v in ipairs(ranked_fields) do
		profile_div:node(v)
	end	
	return profile_div
end

function makeProfile(data, args)
	-- what about a 'nodebuilder' instead?
    -- builds the template in html
    ranked_fields = {}
    local field_div
	local profile_div = mw.html.create('div')
	profile_div
		:cssText(data.styles.box.outer)
		:addClass("plainlinks")
	for k,v in pairs(args) do
		if ((data.fields[k] and data.fields[k].isRequired) or (data.fields[k] and string.len(v) > 0)) then
			field_div = nodeBuilder(data.fields[k], v)
			ranked_fields[data.fields[k].rank] = field_div
--			profile_div:node(field_div)
		end
	end
	profile_div = insertProfileFields(ranked_fields, profile_div)
	profile_div:allDone()		
	return profile_div
end

function deepCopyTable(data)
	-- the deep copy is a workaround step to avoid the restrictions placed on
	-- tables imported through loadData
	if type(data) ~= 'table' then
	    return data
	end
	local data_copy = {}
	for k,v in pairs(data) do
		if type(v) == 'table' then
		    v = deepCopyTable(v)
		end
		data_copy[k] = v
	end
	return data_copy
end

function getProfileData(args)
	-- loads the relevant stylesheet (/learner or /mentor), if a sub-template was called with a portal
	-- argument and a stylesheet exists with the same name. For example, calling
	-- {{#invoke:Co-op_profile|main|type=learner}} would load the
	-- Module:Co-op_profile/learner stylesheet
	-- member stylesheet is the default if no param set
	local data_readOnly = {}
	local data_writable = {}
	if (args.profile_type and mw.title.makeTitle( 'Module', 'Co-op_profile/' .. args.profile_type).exists) then
		data_readOnly = mw.loadData("Module:Co-op_profile/" .. args.profile_type)
	else
		data_readOnly = mw.loadData("Module:Co-op_profile/learner")
	end
	data_writable = deepCopyTable(data_readOnly)
	return data_writable
end

-- helper functions --

function stringToLowerCase(value)
    -- returns a string in all lowercase chars
	return mw.ustring.lower(value)
end

function stringSpacesToUnderscores(value)
    -- converts spaces to underscores in a string
	return mw.ustring.gsub(value, " ", "_")
end

function stringFirstCharToUpper(str)
    -- converts the first char of a string to uppercase
    return (str:gsub("^%l", string.upper))
end

function addMissingArgs(data, args)
    --if required args are not included in the calling template, adds
    -- them with default values
    for k,v in pairs(data.fields) do
        if data.fields[k].isRequired then
            if not args[k] then
                args[k] = data.fields[k].default
            end
        end
    end            
    return args
end

function setDefaultValues(data, args)
	for k,v in pairs(args) do
	    if (string.len(args[k]) == 0 and data.fields[k] and data.fields[k].isRequired == true) then
	        args[k] = data.fields[k].default
        end
    end
    return args
end

-- main --

function p.main(frame)
	local args = getArgs(frame, {removeBlanks = false})
	local data = getProfileData(args)
	args = setDefaultValues(data, args)
	args = addMissingArgs(data, args) --make this a sub-call of setDefaultValues
	local profile = tostring(makeProfile(data, args)) --added data param
	 if mw.title.getCurrentTitle().nsText == "Wikipedia" then
		 profile = profile .. getCategories(data, args)
	 end    
	return profile
end

return p