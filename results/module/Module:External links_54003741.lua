require('Module:No globals')
-- local genitive = require('Module:Genitive')._genitive
local contLang = mw.language.getContentLanguage()

local cmodule = {}
local conf = require 'Module:External links/conf'(contLang:getCode())
local hasdatafromwikidata = false
local hasdatafromlocal = false
local haswikidatalink = true -- we assume it's connected

local p = {}

local function getLabel(entity, use_genitive, pagetitle)
	local label = (pagetitle and pagetitle ~= '') and pagetitle or nil
	if not label and not entity then
		label = mw.title.getCurrentTitle().text
	elseif not label then
		label = mw.wikibase.label(entity.id) or mw.title.getCurrentTitle().text
	end
--	return use_genitive and genitive(label, 'sitt') or label
	return use_genitive and label .. "'s" or label
end

-- @todo cleanup, this is in production, use the console
local function dump(obj)
	return "<pre>" .. mw.dumpObject(obj) .. "</pre>"
end


local function stringFormatter( datavalue )
	if datavalue == nil or datavalue['type'] ~= 'string' then
		return nil
	end
	return datavalue.value
end

local pval = {}
pval.P1793 = { -- format as a regular expression
	types = {
		snaktype = 'value',
		datatype = 'string',
	},
}

pval.P407 = { -- language of work or name
	types = {
		snaktype = 'value',
		datatype = 'wikibase-item',
		datavalue = {
			type = 'wikibase-entityid', 
		}
	},
}

pval.P364 = { -- original language of work 
	types = {
		snaktype = 'value',
		datatype = 'wikibase-item',
		datavalue = {
			type = 'wikibase-entityid', 
		}
	},
}

pval.P218 = { -- ISO 639-1 language 
	types = {
		snaktype = 'value',
		datatype = 'external-id',
		datavalue = {
			type = 'string', 
		}
	},
}

pval.P305 = { -- IETF language tag
	types = {
		snaktype = 'value',
		datatype = 'external-id',
		datavalue = {
			type = 'string', 
		}
	},
}

pval.P582 = { -- end time
	types = {
		snaktype = 'value',
		datatype = 'time',
		datavalue = {
			type = 'string', 
		}
	},
}


-- This is a really makeshift crappy converter, but it'll do some basic
-- conversion from PCRE to Lua-style patterns (note that this only work
-- in very few cases)
local function regexConverter( regex )
	local output = regex
	output = string.gsub(output, "\\d{2}", "%%d%%d")
	output = string.gsub(output, "\\d{3}", "%%d%%d%%d")
	output = string.gsub(output, "\\d{4}", "%%d%%d%%d%%d")
	output = string.gsub(output, "\\d{5}", "%%d%%d%%d%%d%%d")
	output = string.gsub(output, "\\d{6}", "%%d%%d%%d%%d%%d%%d")
	output = string.gsub(output, "\\d{7}", "%%d%%d%%d%%d%%d%%d%%d")
	output = string.gsub(output, "\\d{8}", "%%d%%d%%d%%d%%d%%d%%d%%d")
	output = string.gsub(output, "\\d", "%%d")
	
	return output
end


local function getFormatterUrl( prop, value )
	local head = ""
	local tail = ""
	local entity = mw.wikibase.getEntity(prop)
	-- to avoid deep tests
	if not entity or not entity.claims then
		return head
	end
	-- get the claims for this entity
	local statements = entity.claims['P1630'] -- formatter URL
	-- to avoid deep tests
	if not statements then
		return head
	end
	local formatters = {}
	-- let's go through the claims
	for _, claim in ipairs( statements ) do
		-- to avoid deep tests
		if not claim then
			claim = {}
		end
		local valid = claim['type'] == 'statement'
			and claim['rank'] ~= 'deprecated'
		if valid then
			local mainsnak = claim.mainsnak or {}
			local preferred = claim['rank'] == 'preferred'
			-- get any qualifiers for this claim (we are interested in P1793 for
			-- indication of which claim is correct) 
			local qualifiers = claim.qualifiers or {}
			-- now let's check the qualifier we are interested in
			local qualid = 'P1793' -- format as a regular expression
			-- if the claim has this qualifier
			if qualifiers[qualid] then
				-- it's here, let's check it out!
				local items = {}
				-- traverse all snaks in this qualifier
				for _, qualsnak in ipairs( qualifiers[qualid] ) do
					if qualsnak and pval[qualid] then
						--mw.log("qualsnak = " .. dump(qualsnak))
						-- check if the snak is of the correct snaktype and datatype
						local valid = qualsnak.snaktype == pval[qualid].types.snaktype
							and qualsnak.datatype == pval[qualid].types.datatype
						if valid then
							-- we'll have to convert the regex to Lua-style
							local regex = regexConverter(qualsnak.datavalue.value)
							local test = string.match( value, '^'..regex..'$' )
							if test then
								-- it matched, this is correct and overrides any other.
								if preferred then
									head = mainsnak.datavalue.value
								else
									tail = mainsnak.datavalue.value
								end
							end
						end
					end
				end
			else
				-- we don't have any qualifier, is it preferred?
				if (head == '' and preferred) or (tail == '' and not preferred) then
					-- if we don't have any other, use this one
					if preferred and head == '' then
						head = mainsnak.datavalue.value
					elseif not preferred and tail == '' then
						tail = mainsnak.datavalue.value
					end
				end
			end
		end
	end
	return head ~= '' and head or tail

end



local function getLanguageData(prop, qid)
	local head = {}
	local tail = {}
	-- mw.log("getLanguageData, prop="..dump(prop).." qid="..dump(qid))
	-- get the entity we are checking
	local entity = mw.wikibase.getEntityObject(qid)
	-- to avoid deep tests
	if not entity then
		return nil
	end
	if not entity.claims then
		return {}
	end
	-- get the claims for this entity
	local statements = entity.claims[prop]
	-- to avoid deep tests
	if not statements then
		return {}
	end
	-- mw.log("getLanguageData going through claims="..dump(statements))
	-- let's go through the claims
	for _, claim in ipairs( statements ) do
		-- to avoid deep tests
		if not claim then
			claim = {}
		end
		local valid = claim['type'] == 'statement'
			and claim['rank'] ~= 'deprecated'
		if valid then
			local mainsnak = claim.mainsnak or {}
			local preferred = claim['rank'] == 'preferred'
			-- verify the item is what we expect
			local valid = mainsnak.snaktype == pval[prop].types.snaktype
				and mainsnak.datatype == pval[prop].types.datatype
				and mainsnak.datavalue.type == pval[prop].types.datavalue.type
			if valid then
				-- mw.log("getLanguageData claim is valid="..dump(claim))
				-- if this is the correct P-value, dive into it and get P218 (ISO 639-1)
				if mainsnak.property == 'P364' then -- original language of work
					if preferred then
						head[#head+1] = table.concat(getLanguageData('P218', 'Q'..mainsnak.datavalue.value['numeric-id']), conf:a('mod-filter-separator'))
					else
						tail[#tail+1] = table.concat(getLanguageData('P218', 'Q'..mainsnak.datavalue.value['numeric-id']), conf:a('mod-filter-separator'))
					end
				elseif mainsnak.property == 'P218' or mainsnak.property == 'P305' then -- ISO 639-1 code or IETF language tag
					if preferred then
						head[#head+1] = stringFormatter(mainsnak.datavalue)
					else
						tail[#tail+1] = stringFormatter(mainsnak.datavalue)
					end
				end
			end
		end
	end
	-- mw.log("getLanguageData returning head="..dump(head).." tail="..dump(tail))
	return #head>0 and head or tail
end

local langqvalorder = {'P407','P364'}
local otherqvalorder = {'P582'}

local function getValuesFromWikidata(props)
	local head = {}
	local tail = {}
	-- mw.log("getValuesFromWikidata, props="..dump(props))
	-- get the entity we are checking
	local entity = mw.wikibase.getEntityObject()
	-- to avoid deep tests
	if not entity then
		--mw.log("getValuesFromWikidata no entity")
		return nil
	end
	if not entity.claims or not props or not props.prop or props.prop == '' then
		--mw.log("getValuesFromWikidata no claims or no props")
		return {}
	end
	-- get the claims for this entity
	local statements = entity.claims[props.prop]
	-- to avoid deep tests
	if not statements then
		return {}
	end
	-- let's go through the claims
	for _, claim in ipairs( statements ) do
		-- to avoid deep tests
		if not claim then
			claim = {}
		end
		local valid = claim['type'] == 'statement'
			and claim['rank'] ~= 'deprecated'
		if valid then
			-- mw.log("getValuesFromWikidata valid claim="..dump(claim))
			local mainsnak = claim.mainsnak or {}
			local preferred = claim['rank'] == 'preferred'
			-- get the content of the claim (the identifier)
			local langcode = props.langcode
			local checklangcode = nil
			if props.langcode and props.langcode ~= '' then
				checklangcode = string.find(langcode, "([pP]%d+)")
			end
			if checklangcode and checklangcode ~= "" then
				-- this is a P-value for language-code, so we'll check qualifiers for languagedata
				-- first get any qualifiers
				local qualifiers = claim.qualifiers or {}
				for _, qualid in ipairs( langqvalorder ) do
					-- if the claim has this qualifier
					if qualifiers[qualid] then
						-- it's here, let's check it out!
						local items = {}
						-- traverse all snaks in this qualifier
						for _, qualsnak in ipairs( qualifiers[qualid] ) do
							if qualsnak and pval[qualid] then
								-- mw.log("qualsnak = " .. dump(qualsnak))
								-- check if the snak is of the correct snaktype and datatype
								local valid = qualsnak.snaktype == pval[qualid].types.snaktype
									and qualsnak.datatype == pval[qualid].types.datatype
								if valid then
									-- now get the actual data
									langcode = table.concat(getLanguageData('P305', 'Q'..qualsnak.datavalue.value['numeric-id']), '')
								end
							end
						end
					end
					-- mw.log("langcode is now="..dump(langcode))
				end
				if string.find(langcode, "([pP]%d+)") then
					-- we still don't have any langcode, so we default to "en"
					langcode = nil
				end
			end
			local stillvalid = true
			-- we should check a couple of other qualifiers as well
			-- first get any qualifiers
			local qualifiers = claim.qualifiers or {}
			for _, qualid in ipairs( otherqvalorder ) do
				-- if the claim has this qualifier
				if qualifiers[qualid] then
					-- it's here, let's check it out!
					local items = {}
					-- traverse all snaks in this qualifier
					for _, qualsnak in ipairs( qualifiers[qualid] ) do
						if qualsnak and pval[qualid] then
							-- mw.log("qualsnak = " .. dump(qualsnak))
							-- check if the snak is of the correct snaktype and datatype
							local valid = qualsnak.snaktype == pval[qualid].types.snaktype
								and qualsnak.datatype == pval[qualid].types.datatype
							if not valid then
								-- sorry, this is not correct
								mw.log("qualsnak = INCORRECT")
								stillvalid = false
							end
						end
					end
				end
				-- mw.log("langcode is now="..dump(langcode))
			end
			if stillvalid then
				if preferred then
					head[#head+1] = { value=stringFormatter(mainsnak.datavalue) }
					if langcode and langcode ~= '' then
						head[#head]['langcode'] = langcode
					end
				else
					tail[#tail+1] = { value=stringFormatter(mainsnak.datavalue) }
					if langcode and langcode ~= '' then
						tail[#tail]['langcode'] = langcode
					end
				end
			end
		end
	end
	-- mw.log("getValuesFromWikidata returning head="..dump(head).." tail="..dump(tail))
	return #head>0 and head or tail
end

local function findMainLinksOnWikidata(props, pagetitle, short_links)
	local output = {}
	local pid = nil
	-- get the entity we are checking
	local entity = mw.wikibase.getEntityObject()
	-- to avoid deep tests
	if not entity then
		return nil
	end
	local values = getValuesFromWikidata(props)
	for _, value in ipairs( values ) do
		local verified_value = nil
		if props.regex then
			-- we have a local defined regex, so this will have to pass first
			-- maybe we'll have to convert the regex to Lua-style
			local regex = regexConverter(props.regex)
			local test = string.match( value.value, '^'..regex..'$' )
			--mw.log("testing with "..regex.. " and test="..dump(test).." and value="..id)
			if test then
				-- it matched, this is correct and overrides any other.
				verified_value = value.value
			end
		else
			verified_value = value.value
		end
		if verified_value then
			local url = ''
			output[#output+1] = {}
			output[#output].langcode = value.langcode
			output[#output].category = {}
			if props.url_f then
				-- we have a local defined url-formatter function, use it as first priority
				url = props.url_f(verified_value)
				if props.track and not string.find(props.langcode, "([pP]%d+)") then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-wd'), props.prop):plain()
				elseif props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
				end
			elseif props.url then
				-- we have a local defined url-formatter string, use it as second priority
				url = mw.message.newRawMessage(props.url, verified_value):plain()
				if props.track and not string.find(props.langcode, "([pP]%d+)") then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-wd'), props.prop):plain()
				elseif props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
				end
			else
				-- get the formatvalue from the property, if it exists
				local formatterUrl = getFormatterUrl(props.prop, verified_value)
				if formatterUrl ~= '' then
					url = mw.message.newRawMessage(formatterUrl, verified_value):plain()
					if props.track then 
						output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
					end
				end
			end
			if url ~= '' then
				local this_wiki = mw.getContentLanguage()
				local this_wiki_code = this_wiki:getCode()
				local langlink = (value.langcode and value.langcode ~= '' and value.langcode ~= this_wiki_code) and mw.message.newRawMessage(conf:g('msg-langcode'), value.langcode, mw.language.fetchLanguageName(value.langcode, this_wiki_code)) or ""
				if short_links and props.short then
					output[#output].text =
						mw.message.newRawMessage(props.short,
							getLabel(entity, props.genitive, pagetitle),
							url,
							langlink,
							verified_value,
							mw.uri.encode(verified_value, 'PATH'))
						:plain()
				else
					output[#output].text =
						mw.message.newRawMessage(props.message,
							getLabel(entity, props.genitive, pagetitle),
							url,
							langlink,
							verified_value,
							mw.uri.encode(verified_value, 'PATH'))
						:plain()
				end
			end
		end
	end
	--mw.log("findMainLinksOnWikidata returning="..dump(output))
	return output
end

local function getSitelinksFromWikidata(props, entity)
	local output = {}
	--mw.log("getSitelinksFromWikidata, props="..dump(props))
	-- to avoid deep tests
	if not entity then
		entity = mw.wikibase.getEntityObject()
		if not entity then
			--mw.log("getSitelinksFromWikidata no entity")
			return nil
		end
	end
	local requested_sitelink = string.match(props.prop, "SL(%l+)")
	local sitelinks = entity:getSitelink(requested_sitelink)
	if sitelinks and sitelinks ~= '' then
		output[#output+1] = { value = sitelinks }
	end
	--mw.log("getSitelinksFromWikidata returning output="..dump(output))
	return output
end


local function findSiteLinksOnWikidata(props, pagetitle, short_links)
	local output = {}
	local pid = nil
	-- get the entity we are checking
	local entity = mw.wikibase.getEntityObject()
	-- to avoid deep tests
	if not entity then
		return nil
	end
	local values = getSitelinksFromWikidata(props)
	for _, value in ipairs( values ) do
		local verified_value = nil
		if props.regex then
			-- we have a local defined regex, so this will have to pass first
			-- maybe we'll have to convert the regex to Lua-style
			local regex = regexConverter(props.regex)
			local test = string.match( value.value, '^'..regex..'$' )
			--mw.log("testing with "..regex.. " and test="..dump(test).." and value="..id)
			if test then
				-- it matched, this is correct and overrides any other.
				verified_value = value.value
			end
		else
			verified_value = value.value
		end
		if verified_value then
			--mw.log("it's verified..")
			local url = ''
			output[#output+1] = {}
			output[#output].langcode = value.langcode
			output[#output].category = {}
			if props.url_f then
				-- we have a local defined url-formatter function, use it as first priority
				url = props.url_f(verified_value)
				if props.track and not string.find(props.langcode, "(SL%l+)") then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-wd'), props.prop):plain()
				elseif props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
				end
			elseif props.url then
				-- we have a local defined url-formatter string, use it as second priority
				url = mw.message.newRawMessage(props.url, verified_value):plain()
				if props.track and not string.find(props.langcode, "(SL%l+)") then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-wd'), props.prop):plain()
				elseif props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
				end
			else
				url = verified_value:gsub(' ','_')
				if props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-wd'), props.prop):plain()
				end
			end
			if url ~= '' then
				local this_wiki = mw.getContentLanguage()
				local this_wiki_code = this_wiki:getCode()
				local langlink = (value.langcode and value.langcode ~= '' and value.langcode ~= this_wiki_code) and mw.message.newRawMessage(conf:g('msg-langcode'), value.langcode, mw.language.fetchLanguageName(value.langcode, this_wiki_code)) or ""
				if short_links and props.short then
					output[#output].text =
						mw.message.newRawMessage(props.short,
							getLabel(entity, props.genitive, pagetitle),
							url,
							langlink,
							verified_value,
							mw.uri.encode(verified_value, 'PATH'))
						:plain()
				else
					output[#output].text =
						mw.message.newRawMessage(props.message,
							getLabel(entity, props.genitive, pagetitle),
							url,
							langlink,
							verified_value,
							mw.uri.encode(verified_value, 'PATH'))
						:plain()
				end
			end
		end
	end
	--mw.log("findSiteLinksOnWikidata returning="..dump(output))
	return output
end


local function findMainLinksLocal(props, pagetitle, short_links, local_value)
	local output = {}
	-- to avoid deep tests
	if not props.prop then
		return nil
	end
	if not (local_value or local_value == '') then
		-- bail out if no value is present
		return output
	end
	-- get the formatvalue from the property
	local verified_value = local_value
	if props.regex and props.regex ~= '' then
		-- let's verify the id
		-- maybe we'll have to convert the regex to Lua-style
		local regex = regexConverter(props.regex)
		local test = string.match( local_value, '^'..regex..'$' )
		if test then
			-- it matched, this is correct
			verified_value = local_value
		else
			verified_value = nil
		end
		
	end
	if not verified_value then
		return output
	end
	local wikidata_property = string.find(props.prop, "([pP]%d+)")
	local wikidata_values = {}
	if wikidata_property then
		-- get any wikidata values to see if they are equal to local values
		wikidata_values = getValuesFromWikidata(props)
	end
	if wikidata_property or (props.url and props.url ~= '') or (props.url_f) then
		output[#output+1] = {}
		output[#output].langcode = string.find(props.langcode, "([pP]%d+)") and "" or props.langcode
		--mw.log("findMainLinksLocal - props="..dump(props).." langcode="..output[#output].langcode)
		output[#output].category = {}
		local url = ''
		if props.track and wikidata_property and wikidata_values and #wikidata_values then
			local local_value_in_wikidata = false
			for _,value in ipairs( wikidata_values ) do
				if value.value == verified_value then
					local_value_in_wikidata = true
				end
			end
			output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), (local_value_in_wikidata and 'track-cat-local-wd-equal' or 'track-cat-local-wd-unequal')), props.prop):plain()
		end
		if wikidata_property and wikidata_values and #wikidata_values then
			hasdatafromwikidata = true -- signal up the chain this article has a wikidata claim
		end
		if props.url_f then
			-- we have a local defined url-formatter function, use it as first priority
			url = props.url_f(verified_value)
			if props.track then 
				output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-local'), props.prop):plain()
			end
		elseif props.url then
			-- we have a local defined url-formatter string, use it as second priority
			url = mw.message.newRawMessage(props.url, verified_value):plain()
			if props.track then 
				output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-local'), props.prop):plain()
			end
		elseif wikidata_property then
			-- get the formatvalue from the property, if it exists
			local formatterUrl = getFormatterUrl(props.prop, verified_value)
			if formatterUrl ~= '' then
				url = mw.message.newRawMessage(formatterUrl, verified_value):plain()
				if props.track then 
					output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-local'), props.prop):plain()
				end
			end
		else
			-- no other choice, bail out
			return {}
		end
		local this_wiki = mw.getContentLanguage()
		local this_wiki_code = this_wiki:getCode()
		local langlink = (output[#output].langcode and output[#output].langcode ~= '' and output[#output].langcode ~= this_wiki_code) and mw.message.newRawMessage(conf:g('msg-langcode'), props.langcode, mw.language.fetchLanguageName(props.langcode, this_wiki_code)) or ""
		if short_links and props.short then
			output[#output].text =
				mw.message.newRawMessage(props.short,
					getLabel(nil, props.genitive, pagetitle),
					url,
					langlink,
					verified_value,
					mw.uri.encode(verified_value, 'PATH'))
				:plain()
		else
			output[#output].text =
				mw.message.newRawMessage(props.message,
					getLabel(nil, props.genitive, pagetitle),
					url,
					langlink,
					verified_value,
					mw.uri.encode(verified_value, 'PATH'))
				:plain()
		end
	end
	--mw.log("findMainLinksLocal returning="..dump(output))
	return output
end

local function findSiteLinksLocal(props, pagetitle, short_links, local_value)
	local output = {}
	-- to avoid deep tests
	if not props.prop then
		return nil
	end
	if not (local_value or local_value == '') then
		-- bail out if no value is present
		return output
	end
	-- get the formatvalue from the property
	local verified_value = local_value
	if props.regex and props.regex ~= '' then
		-- let's verify the id
		-- maybe we'll have to convert the regex to Lua-style
		local regex = regexConverter(props.regex)
		local test = string.match( local_value, '^'..regex..'$' )
		if test then
			-- it matched, this is correct
			verified_value = local_value
		else
			verified_value = nil
		end
		
	end
	if not verified_value then
		return output
	end
	local wikidata_property = string.find(props.prop, "(SL.+)")
	local wikidata_values = {}
	if wikidata_property then
		-- get any wikidata values to see if they are equal to local values
		wikidata_values = getSitelinksFromWikidata(props)
	end
	if wikidata_property or (props.url and props.url ~= '') or (props.url_f) then
		output[#output+1] = {}
		output[#output].langcode = string.find(props.langcode, "(SL.+)") and "" or props.langcode
		--mw.log("findSiteLinksLocal - props="..dump(props).." langcode="..output[#output].langcode .." wikidata_values="..dump(wikidata_values))
		output[#output].category = {}
		local url = ''
		if props.track and wikidata_property and wikidata_values and #wikidata_values then
			local local_value_in_wikidata = false
			for _,value in ipairs( wikidata_values ) do
				if value.value == verified_value then
					local_value_in_wikidata = true
				end
			end
			output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), (local_value_in_wikidata and 'track-cat-local-wd-equal' or 'track-cat-local-wd-unequal')), props.prop):plain()
		end
		if wikidata_property and wikidata_values and #wikidata_values then
			hasdatafromwikidata = true -- signal up the chain this article has a wikidata claim
		end
		if props.url_f then
			-- we have a local defined url-formatter function, use it as first priority
			url = props.url_f(verified_value)
			if props.track then 
				output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-local'), props.prop):plain()
			end
		elseif props.url then
			-- we have a local defined url-formatter string, use it as second priority
			url = mw.message.newRawMessage(props.url, verified_value):plain()
			if props.track then 
				output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-local-local'), props.prop):plain()
			end
		elseif wikidata_property then
			url = verified_value:gsub(' ','_')
			if props.track then 
				output[#output].category[#output[#output].category+1] = mw.message.newRawMessage(cmodule:getMessage(contLang:getCode(), 'track-cat-wd-local'), props.prop):plain()
			end
		else
			-- no other choice, bail out
			return {}
		end
		local this_wiki = mw.getContentLanguage()
		local this_wiki_code = this_wiki:getCode()
		local langlink = (output[#output].langcode and output[#output].langcode ~= '' and output[#output].langcode ~= this_wiki_code) and mw.message.newRawMessage(conf:g('msg-langcode'), props.langcode, mw.language.fetchLanguageName(props.langcode, this_wiki_code)) or ""
		if short_links and props.short then
			output[#output].text =
				mw.message.newRawMessage(props.short,
					getLabel(nil, props.genitive, pagetitle),
					url,
					langlink,
					verified_value,
					mw.uri.encode(verified_value, 'PATH'))
				:plain()
		else
			output[#output].text =
				mw.message.newRawMessage(props.message,
					getLabel(nil, props.genitive, pagetitle),
					url,
					langlink,
					verified_value,
					mw.uri.encode(verified_value, 'PATH'))
				:plain()
		end
	end
	--mw.log("findSiteLinksLocal returning="..dump(output))
	return output
end


local function addLinkback(str, property)
	local id = mw.wikibase.getEntityObject()
	if not id then
		return str
	end
	if type(id) == 'table' then
		id = id.id
	end
	
	local class = ''
	local url = ''
	if property then
		class = 'wd_' .. string.lower(property)
		url = mw.uri.fullUrl('d:' .. id .. '#' .. property)
		url.fragment = property
	else
		url = mw.uri.fullUrl('d:' .. id )
	end
	
	local title = conf:g('wikidata-linkback-edit')
	local icon = '[%s [[File:Blue pencil.svg|%s|10px|text-top|link=]] ]'
	url = tostring(url)
	local v = mw.html.create('span')
		:addClass(class)
		:wikitext(str)
		:tag('span')
			:addClass('noprint plainlinks wikidata-linkback')
			:css('padding-left', '.3em')
			:wikitext(icon:format(url, title))
		:allDone()
	return tostring(v)
end


local function getArgument(frame, argument)
	local args = frame.args
	if args[1] == nil then
		local pFrame = frame:getParent();
		args = pFrame.args;
		for k,v in pairs( frame.args ) do
			args[k] = v;
		end
	end
	if args[argument] then
		return args[argument]
	end
	return nil
end


local function removeEntry(conf_claims, identifier, property)
	for i, props in ipairs(conf_claims) do
		if props[identifier] == property then
			table.remove(conf_claims, i)
		end
	end
	return conf_claims
end

function p.getLinks(frame)
	local configured_conf = getArgument(frame, conf:a('arg-conf'))
	if configured_conf then
		cmodule = require ('Module:External_links/conf/'..configured_conf)
	else
		error(mw.message.newRawMessage(conf:g('missing-conf'), configured_conf):plain())
	end
	local output = {}
	local category = {}
	local conf_claims = cmodule:getConfiguredClaims(contLang:getCode())
	local limits = cmodule:getLimits()
	assert(limits, mw.message.newRawMessage(conf:g('missing-limits'), configured_conf):plain())
	local links_shown = getArgument(frame, conf:a('arg-maxlink'))
	local pagetitle = getArgument(frame, conf:a('arg-title'))
	-- get a list of tracked properties from the article itself
	local requested_tracking = getArgument(frame, conf:a('arg-track'))
	if requested_tracking and requested_tracking ~= '' then
		-- the properties should be written as P1234, P2345 and other 
		-- version corresponding to the applicable property-identifiers in the config
		for track_prop in string.gmatch(requested_tracking,"([^ ,;:]+)") do
			-- get the requested properties and be able to access them
			-- like req_prop['P345'] to verify if it was requested
			local remove_track = string.match(track_prop, "^\-(.*)")
			for i,claim in ipairs ( conf_claims )  do
				if remove_track == claim.prop or remove_track == conf:a('mod-filter-all') then
					-- if a property starts with "-", then we'll simply remove that 
					-- property from the conf_claims
					conf_claims[i]['track'] = false
				elseif track_prop == claim.prop or track_prop == conf:a('mod-filter-all') then
					conf_claims[i]['track'] = true
				end
			end
		end
	end
	-- get a list of "approved" properties from the article itself
	local requested_properties = getArgument(frame, conf:a('arg-properties'))
	--mw.log("requested_properties="..dump(requested_properties))
	-- assume all properties are allowed
	local req_prop = {}
	local no_req_prop = false  -- we'll allow properties to be filtered for now 
	if requested_properties and requested_properties ~= '' then
		-- the properties should be written as P1234, P2345 and other 
		-- version corresponding to the applicable property-identifiers in the config
		for i in string.gmatch(requested_properties,"([^ ,;:]+)") do
			-- get the requested properties and be able to access them
			-- like req_prop['P345'] to verify if it was requested
			if i == conf:a('mod-filter-all') then
				-- this is a special modifier, saying we should ignore 
				-- all previous and future positive filters and remove the
				-- filter (with exception of negative filters)
				req_prop = {}
				no_req_prop = true
			end
			local remove_prop = string.match(i, "^\-(.*)")
			if remove_prop then
				-- if a property starts with "-", then we'll simply remove that 
				-- property from the conf_claims
				conf_claims = removeEntry(conf_claims, 'prop', remove_prop)
			elseif not no_req_prop then -- only if we are allowing properties to be filtered 
				req_prop[i] = 1
				-- cheat to make #req_prop indicate populated table
				req_prop[1] = 1
			end
		end
	end
	local requested_langs = getArgument(frame, conf:a('arg-languages'))
	--mw.log("requested_langs="..dump(requested_langs))
	-- assume all languages are allowed
	local req_lang = {}
	local no_req_lang = false  -- we'll allow languages to be filtered for now
	if requested_langs and requested_langs ~= '' then
		-- the languages should be written as langcodes as used in the conf_claims
		for i in string.gmatch(requested_langs,"([^ ,;:]+)") do
			-- get the requested languages and be able to access them
			if i == conf:a('mod-filter-all') then
				-- this is a special modifier, saying we should ignore 
				-- all previous and future positive filters and remove the
				-- filter (with exception of negative filters)
				req_lang = {}
				no_req_lang = true
			end
			-- like req_lang['en'] to verify if it was requested
			local remove_lang = string.match(i, "^\-(.*)")
			if remove_lang then
				-- if a language starts with "-", then we'll simply remove that 
				-- language from the conf_claims
				conf_claims = removeEntry(conf_claims, 'langcode', remove_lang)
			elseif not no_req_lang then -- only if we are allowing languages to be filtered 
				req_lang[i] = 1
				-- cheat to make #req_lang indicate populated table
				req_lang[1] = 1
			end
		end
	end
	local short_links = getArgument(frame, conf:a('arg-short'))
	if short_links and short_links ~= '' then
		short_links = true
	else
		short_links = false
	end
	local showinline = getArgument(frame, conf:a('arg-inline'))
	if showinline and showinline ~= '' then
		showinline = true
	else
		showinline = false
	end
	if not links_shown or links_shown == '' then
		links_shown = limits['links-shown'] and limits['links-shown'] or 10
	else
		links_shown = tonumber(links_shown)
	end
	local somedataonwikidata = (short_links and false or true)
	--mw.log("conf_claims="..dump(conf_claims))
	--mw.log("req_prop="..dump(req_prop))
	--mw.log("req_lang="..dump(req_lang))
	--mw.log("short_links="..dump(short_links))
	for _, props in ipairs(conf_claims) do
		-- if we're called with a list of approved properties or languages, check if this one is "approved"
		if (#req_prop==0 or req_prop[props.prop]) and (#req_lang==0 or req_lang[props.langcode] or string.find(props.langcode, "([pP]%d+)")) then
			--mw.log("checking claim="..dump(props))
			local links = {}
			local checkedonwikidata = false
			-- get the any local overriding value from the call
			local wikivalue = getArgument(frame, props.prop)
			--mw.log("wikivalue="..dump(wikivalue))
			if (not wikivalue or wikivalue == "") and string.find(props.prop, "([pP]%d+)") then
				-- the property is a Pnnn type, and therefore on Wikidata
				links = findMainLinksOnWikidata(props, pagetitle, short_links)
				if links == nil then
					-- a nil-value indicated no wikidata-link
					haswikidatalink = false
					links = {}
				else
					checkedonwikidata = true
				end
			elseif (not wikivalue or wikivalue == "") and string.find(props.prop, "(SL%l+)") then
				-- this is a sitelink-type (SLspecieswiki)
				--mw.log("finding sitelinks..")
				links = findSiteLinksOnWikidata(props, pagetitle, short_links)
				if links == nil then
					-- a nil-value indicated no wikidata-link
					haswikidatalink = false
					links = {}
				else
					checkedonwikidata = true
				end
			elseif (wikivalue and wikivalue ~= "") and string.find(props.prop, "(SL%l+)") then
				-- this is a sitelink-type (SLspecieswiki)
				links = findSiteLinksLocal(props, pagetitle, short_links, wikivalue)
			elseif wikivalue and wikivalue ~= '' then
				-- the property is of another annotation, and therefore a local construct
				links = findMainLinksLocal(props, pagetitle, short_links, wikivalue)
			end
			--mw.log("links="..dump(links))
			for _,v in ipairs(links) do
				-- we'll have to check langcodes again as they may have come from wikidata
				if (#req_lang==0 or req_lang[v.langcode]) then
					if checkedonwikidata and not hasdatafromwikidata then
						-- add a general tracking category for articles with data from wikidata
						hasdatafromwikidata = true
						category[#category+1] = cmodule:getMessage(contLang:getCode(), 'with-data-cat')
					elseif not checkedonwikidata and not hasdatafromlocal then
						-- add a general tracking category for articles with data from template-calls in local articles
						hasdatafromlocal = true
						category[#category+1] = cmodule:getMessage(contLang:getCode(), 'with-local-cat')
					end
					if short_links and props.short and v.text and v.text ~= '' then
						-- if short links were requested, and a short definition exists for this property, let's use it
						if #output==0 then
							output[#output+1] = v.text
						else
							output[#output] = output[#output] .. cmodule:getMessage(contLang:getCode(),'short-list-separator') .. v.text
						end
						somedataonwikidata = true
					elseif not short_links and not showinline and v.text and v.text ~= '' then
						-- only if short links were not requested
						output[#output+1] = (#output>=1 and conf:g('msg-ul-prepend') or '')			-- if this is the first link, we won't output a list-element (msg-ul-prepend) 
							.. (checkedonwikidata and addLinkback(v.text, props.prop) or v.text)	-- if the link comes from wikidata, also output a linkback.
					elseif not short_links and showinline and v.text and v.text ~= '' then
						-- only if short links were not requested
						output[#output+1] = v.text
					end
					if props.track and v.category and #v.category then
						-- add category if tracking is on for this property and a category exists in the link-result.
						for _,cats in ipairs( v.category ) do
							category[#category+1] = cats
						end
					end
					if links_shown>0 then
						links_shown = links_shown - 1
					else
						break
					end
				end
			end
			if links_shown==0 then
				break
			end
		end
	end
	local outtext = "" 
	if short_links and #output>0 then
		-- if these are short links, output the whole thing with linkback to wikidata
		--mw.log("somedataonwikidata="..dump(somedataonwikidata).." and output="..dump(output).." and #output="..dump(#output))
		outtext = (somedataonwikidata 
			and addLinkback(table.concat(output,cmodule:getMessage(contLang:getCode(),'short-list-separator')), nil)
			or table.concat(output,cmodule:getMessage(contLang:getCode(),'short-list-separator')))
	elseif not short_links and not showinline and #output>0 then
		outtext = table.concat(output,"\n")
	elseif not short_links and showinline and #output>0 then
		outtext = table.concat(output,conf:g('msg-inline-separator'))
	end
	if not hasdatafromwikidata then
		category[#category+1] = cmodule:getMessage(contLang:getCode(), 'no-data-cat')
		if not hasdatafromlocal and not short_links then
			outtext = cmodule:getMessage(contLang:getCode(), 'no-data-text')
		end
	end
	if not haswikidatalink then
		category[#category+1] = cmodule:getMessage(contLang:getCode(), 'no-wikilink-cat')
		if not hasdatafromlocal and not short_links then
			outtext = cmodule:getMessage(contLang:getCode(), 'no-wikilink')
		end
	end
	local nocategory = getArgument(frame, conf:a('arg-no-categories'))
	category = #category>0 and "\n" .. table.concat(category,"\n") or ""
	--mw.log("nocategory="..dump(nocategory).." and outtext="..dump(outtext).." and category="..dump(category))
	outtext = outtext .. (nocategory and '' or category)
	return outtext
end

function p.getLanguageCode(frame)
	local prop = getArgument(frame, conf:a('arg-properties'))
	local output = getLanguageData(prop)
	return table.concat(output, conf:a('mod-filter-separator'))
end

return p