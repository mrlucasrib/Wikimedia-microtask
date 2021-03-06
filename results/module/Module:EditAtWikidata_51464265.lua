-- Module to display an icon with a tooltip such as "Edit this at Wikidata".
-- Icon will be linked to the Wikidata entry for the article where this is placed.
-- This message is only displayed if a local_parameter is not supplied
-- i.e. when called from a template, it can be coded not to display the message
-- when a local parameter is in use, preventing the value form Wikidata being fetched.
-- The qid of a Wikidata entry can optionally be supplied for testing outside the article.
-- Usage:
-- {{#invoke:EditAtWikidata|showMessage|local_parameter}}
-- {{#invoke:EditAtWikidata|showMessage|qid=<ArticleID>|local_parameter}}

local p = {}

local i18n =
{
	["message"] = "Edit this at Wikidata"
}

p.showMessage = function(frame)
	-- There may be a local parameter supplied, if it's blank, set it to nil
	local local_parm =  mw.text.trim(frame.args[1] or "")
	if local_parm and (local_parm == "") then local_parm = nil end

	-- If there is a local parameter used, we don't want to display the message
	if local_parm then return nil end

	-- Can take a named parameter |qid which is the Wikidata ID for the article.
	-- This will not normally be used except for testing outside the article.
	local qid = frame.args.qid
	if qid and (qid == "") then qid = nil end

	-- The module can take a parameter pid=
	-- which will create a link to that property in the Wikidata entry for the article
	local propertyID = mw.text.trim(frame.args.pid or "")

	-- Get the object containing all the claims for the article
	local entity = mw.wikibase.getEntityObject(qid)
	if entity then
		local thisQid
		if qid then thisQid = qid else thisQid = entity.id end

		-- Named parameter nbsp allows replacing the leading space with &nbsp;
		local space
		if frame.args.nbsp and (frame.args.nbsp ~= "") then
			space = "&nbsp;"
		else
			space = " "
		end

		return
			space .. "[[File:OOjs UI icon edit-ltr-progressive.svg |frameless |text-top |10px |alt=" ..
			i18n.message ..
			" |link=https://www.wikidata.org/wiki/" ..
			thisQid ..
			(propertyID == "" and "" or ("#" .. propertyID)) ..
			"|" .. i18n.message .. "]]"
	end
end

return p