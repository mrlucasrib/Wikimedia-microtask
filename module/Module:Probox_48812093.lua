--
-- This module implements {{Probox}}
--
local getArgs = require('Module:Arguments').getArgs
local TableTools = require('Module:TableTools')
local p = {}

function addTemplates(frame, data, args)
	-- adds additional template to the top of the page, above the infobox
	local page_template
	-- local tmplt_args = {}
	local template_div = mw.html.create('div')	
 	for k,v in pairs(data.templates) do -- if there is a matching arg, and it has a table of template possibilities
 		if (args[k] and string.len(args[k]) > 0 and type(data.templates[k]) == "table") then --convert args to lowercase before checking them against cats
 			for tmplt_key, tmplt_val in pairs(data.templates[k]) do
				if data.templates.passArg == true then
					template_div
						:cssText("")
						:wikitext(frame:expandTemplate{title=data.templates[k][tmplt_key], args={status = stringFirstCharToUpper(args[k])}}) --status is special casing. need to pass generic arg keys
						:done()
				break		
				elseif (stringToLowerCase(args[k]) == tmplt_key and mw.title.new("Template:" .. tmplt_val).exists) then 
                        template_div
                            :cssText("margin-bottom:1em;")
                            :wikitext(frame:expandTemplate{title=tmplt_val, args={}})
                            :done()
                end
                    --convert args to lowercase and subs spaces for underscores
                    --make sure specified template exists
                    -- if (type(tmplt_val) == "string" and stringToLowerCase(args[k]) == tmplt_key and mw.title.new("Template:" .. tmplt_val).exists) then 

			end	
		end
 	end	
 	page_template = tostring(template_div)		
	return page_template
end

function addCategories(data, args, open_roles)
	-- will also look for numbered categories
	local cat_list = {}
	local base_cat = data.categories.base
	-- table.insert(cat_list, base_cat) --always need a base category
	-- -- adding role categories
	if data.categories.default then
		table.insert(cat_list, data.categories.default)
	end	
	if data.categories.roles then
		role_cat = data.categories.roles
		for k,v in pairs(open_roles) do
			table.insert(cat_list, base_cat .. k:gsub("^%l", string.upper) .. role_cat)
		end
	end
 	for k,v in pairs(data.categories) do -- if there is a matching arg, and it has a table of category possibilities
 		if (args[k] and string.len(args[k]) > 0) then --convert args to lowercase before checking them against cats
 			if type(data.categories[k]) == "table" then
				for cat_key, cat_val in pairs(data.categories[k]) do
					if stringSpacesToUnderscores(stringToLowerCase(args[k])) == cat_key then --convert args to lowercase and subs spaces for underscores before checking them against cats
						table.insert(cat_list, base_cat .. cat_val)
						break
					end
				end
			elseif type(data.categories[k]) == "string" then --concat the value of the cat field with the default cat directly
				table.insert(cat_list, base_cat .. data.categories[k])
			end
		end
 	end	
 	local page_categories = " [[" .. tostring(table.concat(cat_list, "]] [[")) .. "]]"
	return page_categories
end		

function makeTextField(field, field_div)
	-- makes a formatted text field for output, based on parameter
	-- values or on default values provided for that field 
	-- type in the stylesheet
	field_div:cssText(field.style)
	if field.vtype2 == "body" then
		field_div
			:tag('span')
				:cssText(field.style2)--inconsistent use of styles 2/3 here
				:wikitext(field.title)--we probably aren't using this for most things now, after Heather's redesign	
				:done()
			:tag('span')
				:cssText(field.style3)
				:wikitext(field.values[1])
				:done()							
	elseif field.vtype2 == "title" then
		field_div
			:tag('span')
				:cssText(field.style3)
				:wikitext(field.values[1])
				:done()			
	elseif field.vtype2 == "link" then
		field_div
			:tag('span')
				:cssText(field.style3)	
				:wikitext("[[" .. field.values[1] .. "|<span style='" .. field.style2 .. "'>" .. field.title .."</span>]]")
				:done()
	end
	field_div:done()
	return field_div
end						

function makeImageField(field, field_div)
	-- makes a formatted image field for output, based on parameter values
	-- provided in the calling template or its parent template, or on default
	-- values provided in the stylesheet
	field_div:cssText(field.style)
	field_div
		:tag('span')
		:cssText(field.style3)
	if field.vtype2 == "thumb" then	
		field_div					
			:wikitext("[[" .. field.values[1] .. "|right|"  .. field.width .."]]")
	elseif field.vtype2 == "link" then
		field_div
			:wikitext("[[" .. field.values[1] .. "|" .. field.alignment .. "|" .. field.width .."|link=" .. field.link .. "]]")
	elseif field.vtype2 == "badge" then
		if mw.ustring.find( field.values[1], "http", 1, true ) then
			field_div
				:wikitext("[[" .. field.icon .. "|" .. field.alignment .. "|" .. field.width .."|link=" .. field.values[1] .. "]] " .. "[" .. field.values[1] .. " " .. field.title .. "]")
		end		
	elseif field.vtype2 == "ui_button" then
		field_div
			:addClass(field.class)			
			:wikitext(field.title)
			:done()	
	end		
	field_div:done()				
	return field_div		
end	

function makeParticipantField(field, ftype)
	local field_div = mw.html.create('div')
	local title_span
	if field.icon then 
		title_span = "[[" .. field.icon .. "|left" .. "|18px]] " .. field.title
	else
		title_span = field.title
	end	
	field_div
		:cssText(field.style)
		:tag('span')
			:cssText(field.style2)
			:wikitext(title_span)
			:done()
	if ftype == "filled" then
		local i = 1
		for k,v in ipairs(field.values) do
			if (i > 1 and field.icon) then --only insert extra padding if has icon
				field.style3 = "padding-left:25px; display:block"
			end
			if field.vtype2 then --ideally all configs should at least have this field for participants. FIXME
				if field.vtype2 == "username" then
					v = "• " .. "[[User:" .. v .. "|" .. v .. "]]"
				elseif field.vtype2 == "email" then
					v = "• " .. v
				end
			else
				v = "• " .. "[[User:" .. v .. "|" .. v .. "]]"
			end			
			field_div
				:tag('span')
					:cssText(field.style3)
					:wikitext(v)					
--					:wikitext("• " .. "[[User:" .. v .. "|" .. v .. "]]")
					:done()	
			i = i + 1
		end	
	end	
	field_div:allDone()
	return field_div
end

function makeSectionDiv(sec_fields, sec_style)
	local sec_div = mw.html.create('div'):cssText(sec_style)	
	sec_fields = TableTools.compressSparseArray(sec_fields)
	for findex, sec_field in ipairs(sec_fields) do -- should put this at the end of the function, and just append the other stuff
		sec_div:node(sec_field)
	end	
	return sec_div
end

function makeParticipantsSection(frame, args, data, filled_role_data, open_roles)
	local filled_role_fields = {}
	for role, val_table in pairs(filled_role_data) do
		local field = data.fields[role]
		field.title = mw.text.trim(frame:expandTemplate{title=args.translations, args={field.key}})
		field.values = {}			
		for val_num, val_text in ipairs(filled_role_data[role]) do
			field.values[#field.values + 1] = val_text		
		end
		local filled_field_div = makeParticipantField(field, "filled")	
        filled_role_fields[field.rank] = filled_field_div	
	end
	local sec_div = makeSectionDiv(filled_role_fields, data.styles.section["participants"]) 
	if (data.fields.more_participants and args.more_participants and stringToLowerCase(args.more_participants)) == "yes" then -- really need this here?
		-- if (args.portal == "Idealab" or args.portal == "Research") then -- beware, exceptions everywhere
		sec_div:tag('span'):cssText("font-style:italic; color: #888888"):wikitext(mw.text.trim(frame:expandTemplate{title=args.translations, args={data.fields.more_participants.key}})):done()
--		elseif args.portal == "Patterns" then	
--			sec_div:tag('span'):cssText("font-style:italic; color: #888888"):wikitext("a learning pattern for..."):done()
--		else			
		for role, val in pairs(open_roles) do -- should make these ordered using compressSparseArray, as above
			local field = data.fields[role]
			field.title = mw.text.trim(frame:expandTemplate{title=args.translations, args={field.key}})
			if field.icon then
				field.icon = field.icon_inactive
			end	
			local open_field_div = makeParticipantField(field, "open")		
			sec_div:node(open_field_div)
		end				
	end	
	sec_div:allDone()
	return sec_div
end		

function makeSectionFields(args, field)
	-- ui button is separate
	local field_div = mw.html.create('div'):cssText(field.style) --why declare this here?
	if field.vtype == "image" then
		if (field.isRequired == true or (args[field.arg] and string.len(args[field.arg]) > 0))  then --should move this up, may not just apply to images
			field_div = makeImageField(field, field_div)
		end	
	elseif field.vtype == "text" then
		field_div = makeTextField(field, field_div)	
	else
	end	
	return field_div -- make sure div is 'done'
end

function makeSection(frame, args, data, box_sec) 
	-- return a div for a section of the box including child divs
	-- for each content field in that section
	-- local sec_div = mw.html.create('div'):cssText(data.styles.section[box_sec])	
	local sec_fields = {}
	for k,v in pairs(data.fields) do
		if data.fields[k].section == box_sec then
			local field = data.fields[k]
			field.title = mw.text.trim(frame:expandTemplate{title=args.translations, args={field.key}})
			field.values = {}
			if (args[k] and string.len(args[k]) > 0) then
				field.values[1] = args[k] --does not accept numbered args
				if field.toLowerCase == true then -- special casing to make IEG status=SELECTED to display in lowercase
					field.values[1] = stringToLowerCase(field.values[1])
				end		
				local field_div = makeSectionFields(args, field)
				sec_fields[field.rank] = field_div					
			elseif field.isRequired == true then
				if field.vtype == "text" then
					field.values[1] = mw.text.trim(frame:expandTemplate{title=args.translations, args={field.default}})
				else
					field.values[1] = field.default
				end
				local field_div = makeSectionFields(args, field)
				sec_fields[field.rank] = field_div				
			else
				--don't make a section for this field
			end
		end
	end
	local sec_div = makeSectionDiv(sec_fields, data.styles.section[box_sec]) 
	return sec_div
end		

function makeInfobox(frame, args, data, filled_role_data, open_roles)
	-- builds the infobox. Some content sections are required, others 
	-- are optional. Optional sections are defined in the stylesheet.
	local box = mw.html.create('div'):cssText(data.styles.box.outer)
	local inner_box = mw.html.create('div'):cssText(data.styles.box.inner)
	if data.sections.above == true then
		local sec_top = makeSection(frame, args, data, "above")
		box:node(sec_top)
	end	
	if data.sections.nav == true then
		local sec_nav = makeSection(frame, args, data, "nav")
		box:node(sec_nav)
	end		
	local sec_head = makeSection(frame, args, data, "head")
	inner_box:node(sec_head)
	local sec_main = makeSection(frame, args, data, "main")
	inner_box:node(sec_main)
	if data.sections.participants == true then
		local sec_participants = makeParticipantsSection(frame, args, data, filled_role_data, open_roles)
		inner_box:node(sec_participants)
	end
	if data.sections.cta == true then
		local sec_cta = makeSection(frame, args, data, "cta")
		inner_box:node(sec_cta)
		inner_box:tag('div'):cssText("clear:both"):done() --clears buttons in the cta sections
	end	
	inner_box:allDone()
	box:node(inner_box)
	if data.sections.below == true then
		local sec_bottom = makeSection(frame, args, data, "below")
		box:node(sec_bottom)
	end	
	box:allDone()
	return box			
end

function orderStringtoNumber(array, val, num)
    if num > table.getn(array) then
        array[#array+1] = val
    else
        table.insert(array, num, val)
    end  
    return array
end    
    
function isJoinable(args, data)
	if args.more_participants == "NO" then
		data.fields.join = nil
		data.fields.endorse.style = "display:inline; float:right;"
	end	
	return data
end	

function deepCopyTable(data)
	-- the deep copy is a workaround step to avoid the restrictions placed on 
	-- tables imported through loadData
	if type(data) ~= 'table' then return data end
	local res = {}
	for k,v in pairs(data) do
		if type(v) == 'table' then
		v = deepCopyTable(v)
		end
		res[k] = v
	end
	return res
end
	
function getPortalData(args)
	-- loads the relevant stylesheet, if a sub-template was called with a portal
	-- argument and a stylesheet exists with the same name. For example, calling 
	-- {{#invoke:Probox/Idealab|main|portal=Idealab}} would load the
	-- Module:Probox/Idealab stylesheet
	local data_readOnly = {}
	local data_writable = {}
	if (args.portal and mw.title.makeTitle( 'Module', 'Probox/' .. args.portal).exists) then
		data_readOnly = mw.loadData("Module:Probox/" .. args.portal)
	else
		data_readOnly = mw.loadData("Module:Probox/Default")
	end	
	-- data_writable = TableTools.shallowClone(data_readOnly)
	data_writable = deepCopyTable(data_readOnly)
	return data_writable
end

function string.starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

function stringToLowerCase(value)
	return mw.ustring.lower(value)
end	
 
function stringSpacesToUnderscores(value)
	return mw.ustring.gsub(value, " ", "_")
end

function stringFirstCharToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function TCTlookup(args)
	local tct_path = tostring(args.translations)
	 --mw.log(mw.title.getCurrentTitle().subpageText)
	 local tct_subpage = mw.title.getCurrentTitle().subpageText
	if tct_subpage == "en" then
		tct_path = tct_path .. "/" .. tct_subpage
	elseif (mw.title.new("Template:" .. args.translations .. "/" .. tct_subpage).exists and mw.language.isSupportedLanguage(tct_subpage)) then
		tct_path = tct_path .. "/" .. tct_subpage
	else
		tct_path = tct_path .. "/" .. "en"
	end
	-- mw.log(tct_path)
	return tct_path
end	

function getRoleArgs(args, available_roles)
    -- returns:
    -- 1) a table of ordered values for valid role params, 
    -- even if numbered nonsequentially
    -- 2) a table of all roles with at least 1 empty param, 
    -- plus the default volunteer role
    local filled_role_data = {}
    local open_roles = {}
    if available_roles.default then -- some boxes have default role to join
    	open_roles[available_roles.default] = true
    end	
	for rd_key, rd_val in pairs(available_roles) do
		for a_key, a_val in pairs(args) do
    		if string.starts(a_key, rd_key) then
                if string.len(a_val) == 0 then
                    open_roles[rd_key] = true
                else   
                    if not filled_role_data[rd_key] then filled_role_data[rd_key] = {} end
                    local arg_num = tonumber(a_key:match('^' .. rd_key .. '([1-9]%d*)$'))
                    if arg_num then
                        filled_role_data[rd_key] = orderStringtoNumber(filled_role_data[rd_key], a_val, arg_num)
                    else
                        table.insert(filled_role_data[rd_key], 1, a_val)   
                    end
                end    
            end    
		end
	end
	return filled_role_data, open_roles
end	     

function p.main(frame)
	local args = getArgs(frame, {removeBlanks = false})
	local data = getPortalData(args)
 	data = isJoinable(args, data)
	if not (args.translations and mw.title.new("Template:" .. args.translations).exists) then
 		args.translations = "Probox/Default/Content"
 	end
 	-- mw.log(args.translations)
 	-- if the TCT content index is under translation, check for translations in the subpage language
 	if mw.title.new("Template:" .. args.translations .. "/en").exists then	
 		args.translations = TCTlookup(args)
 	end	
 	if data.sections.cta == true then
 		args.talk = tostring(mw.title.getCurrentTitle().talkPageTitle)  -- expensive
 	end	
 	local filled_role_data, open_roles = getRoleArgs(args, data.roles)
	local box = makeInfobox(frame, args, data, filled_role_data, open_roles)
	local infobox = tostring(box)
	-- only add cats if not in Template or User ns
	if (data.categories and (mw.title.getCurrentTitle().nsText ~= "Template" and mw.title.getCurrentTitle().nsText ~= "User" and mw.title.getCurrentTitle().nsText ~= "Meta") and not args.noindex) then
		-- FIXME specify namespace in config, so that categories only appear if template is translcuded in that namespace
		page_categories = addCategories(data, args, open_roles)
		infobox = infobox .. page_categories
	end	
	if data.templates then
		local top_template = addTemplates(frame, data, args)
		infobox = top_template .. infobox
	end		
	return infobox
end

return p