---------- Module:Wikibase ----------------
require('Module:No globals')
local p = {}

-- Return the entity ID of the item linked to the current page.
function p.id(frame)
	if not mw.wikibase then
		return "no mw.wikibase"
	end
	return mw.wikibase.getEntityIdForCurrentPage() or "no entity"
end

-- Return the URL of an entity given its entity ID
-- or the item linked to the current page if no argument is provided.
function p.wdurl(frame)
	return mw.wikibase.getEntityUrl(frame.args[1] and mw.text.trim(frame.args[1])) -- defaults to entity URL of the item linked to the current page
end

-- Return the label of an entity given its entity ID
-- or the item linked to the current page if no argument is provided.
function p.label(frame)
	return mw.wikibase.getLabel(frame.args[1] and mw.text.trim(frame.args[1])) -- defaults to label of the item linked to the current page
end

-- Return the description of an entity given its entity ID
-- or the item linked to the current page if no argument is provided.
function p.description(frame)
	return mw.wikibase.getDescription(frame.args[1] and mw.text.trim(frame.args[1])) -- defaults to description of the item linked to the current page
end

-- Return the local title of an item given its entity ID
-- or the item linked to the current page if no argument is provided.
function p.page(frame)
	local qid = frame.args[1] and mw.text.trim(frame.args[1])
	if not qid or qid == '' then
		qid = mw.wikibase.getEntityIdForCurrentPage() -- default the item connected to the current page
	end
	return mw.wikibase.getSitelink(qid or '') -- requires one string arg
end

-- Return the data type of a property given its entity ID.
function p.datatype(frame)
	local prop = mw.wikibase.getEntity(frame.args[1] and mw.text.trim(frame.args[1]):upper():gsub('PROPERTY:P', 'P')) -- trim and remove any "Property:" prefix
	return prop and prop.datatype
end

return p