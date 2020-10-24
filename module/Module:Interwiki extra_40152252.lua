-- This module provides functions and objects for dealing with interwiki links.

local checkType = require('libraryUtil').checkType
local interwikiData = mw.loadData('Module:Interwiki extra/data')

--------------------------------------------------------------------------------
-- Prefix class
--------------------------------------------------------------------------------

local Prefix = {}
Prefix.__index = Prefix

function Prefix.new(code)
	checkType('Prefix.new', 1, code, 'string')
	local obj = setmetatable({}, Prefix)
	local data = interwikiData.prefixes[code]
	if not data then
		return nil
	end
	for k, v in pairs(data) do
		obj[k] = v
	end
	return obj
end

function Prefix:makeUrl(page)
	checkType('makeUrl', 1, page, 'string')
	-- In MediaWiki, interlanguage links are wiki-encoded (spaces are encoded
	-- as underscores), even if the site is not a wiki and underscores don't
	-- make sense. So we do the same here.
	page = mw.uri.encode(page, 'WIKI')
	return mw.message.newRawMessage(self.url, page):plain()
end

function Prefix:isValidUrl(url)
	checkType('isValidUrl', 1, url, 'string')
	local obj1 = mw.uri.new(self.url)
	local obj2 = mw.uri.new(url)
	if not obj2 then
		return false
	elseif obj1.protocol and obj1.protocol ~= obj2.protocol then
		-- Protocols only have to match if the prefix URL isn't protocol-relative
		return false
	elseif obj1.host ~= obj2.host then
		return false
	end
	local function makePathQuery(obj)
		return obj.path .. (obj.queryString or '')
	end
	local pathQuery1 = makePathQuery(obj1)
	local pathQuery2 = makePathQuery(obj2)
	-- Turn pathQuery1 into a string pattern by escaping all punctuation, then
	-- replacing the "$1" parameter (which will have become "%$1") with ".*"
	local pattern = pathQuery1:gsub('%p', '%%%0'):gsub('%%$1', '.*')
	pattern = '^' .. pattern .. '$'
	return pathQuery2:find(pattern) ~= nil
end
local langcode = {
	['bat_smg']      = 'bat-smg',
	['be_x_old']     = 'be-x-old',
	['cbk_zam']      = 'cbk-zam',
	['fiu_vro']      = 'fiu-vro',
	['map_bms']      = 'map-bms',
	['nds_nl']       = 'nds-nl',
	['roa_rup']      = 'roa-rup',
	['roa_tara']     = 'roa-tara',
	['zh_classical'] = 'zh-classical',
	['zh_min_nan']   = 'zh-min-nan', -- a comma have to be added when new lines are added
	['zh_yue']       = 'zh-yue'
	}

p460 = function(entity) -- access the first valid value of P460
	if entity and entity.claims and entity.claims["P460"] then
		for i, j in pairs(entity:getBestStatements( "P460" )) do
			if j.mainsnak.snaktype == 'value' then
				return 'Q' .. j.mainsnak.datavalue.value['numeric-id']
			end
		end
	end
	return nil
end
Prefix.interwiki = function(frame)
	local s = {}
	local entity = mw.wikibase.getEntity()
	local qid = frame.args.qid or frame:getParent().args.qid or p460(entity) -- uses parameter qid of the module if it exists, otherwise follow P460
	if frame.args.qid == '' or frame:getParent().args.qid == '' then
		qid = p460(entity)
	end
	if qid then
		local entity2 = mw.wikibase.getEntity(qid)
		if entity2 and entity2.sitelinks then
			for i, j in pairs(entity2.sitelinks) do
				if j.site ~= 'enwiki' and j.site ~= 'wikidatawiki' and j.site ~= 'commonswiki' and j.site ~= 'specieswiki' and j.site ~= 'metawiki' and j.site ~= 'mediawikiwiki' then -- excludes the own wiki and some wikiprojects that are not Wikipedia, even if their code ends with 'wiki'
					if mw.ustring.sub( j.site, mw.ustring.len(j.site) - 3 ) == 'wiki' then -- excludes Wikisource, Wikiquote, Wikivoyage etc
						local lang = langcode[mw.ustring.sub( j.site, 1, mw.ustring.len(j.site) - 4 )] or mw.ustring.sub( j.site, 1, mw.ustring.len(j.site) - 4 )
						if (entity and not entity.sitelinks[j.site]) or not entity then -- excludes interwiki to projects that already have sitelinks in the present page
							table.insert(s, '[[' .. lang .. ':' .. j.title .. ']]' ) -- put together a interwiki-link to other projects
						end
					end
				end
			end
		end
	end
	if #s > 0 then 
		table.insert(s, "[[Category:Module:Interwiki extra: additional interwiki links]]")
	end
	return table.concat(s, '')

end

return Prefix