local getArgs = require('Module:Arguments').getArgs
local rawData = mw.loadData('Module:Sanctions/data')
local data = rawData.sanctions
local aliasMap = rawData.aliases

local messageBox = require('Module:Message box')

local function tableContainsValue(needle, haystack)
	for _, v in pairs(haystack) do
		if v == needle then
			return true
		end
	end
	return false
end

local function _getTopicData(topicAlias)
	if data[topicAlias] then
		return data[topicAlias]
	elseif aliasMap[topicAlias] then
		return data[aliasMap[topicAlias]]
	else
		return false
	end
end

-- Returns an invalid topic error, with a table of acceptable topics
local function syntaxHelp()
	return [[<span class="error">{{para|topic}} not specified. Available options:</span><div style="border-left: 5px dashed black; border-right: 5px dashed black; border-bottom: 5px dashed black; padding-left: 0.5em; padding-right: 0.5em; padding-bottom: 0.5em;">
	{{Gs/topics/table}}
	</div>]]
end

local function getTopicData(frame, topicAlias)
	if not topicAlias then
		return false
	end

	local topic = _getTopicData(topicAlias)
	if topic then
		return topic
	else
		return false
	end
end

-- This function builds a talk notice
-- TODO: split this up
--
-- @param frame
-- @param topicData data for the given topic from the /data page
-- @param args arguments passed to wrapper template
-- @returns String representation of notice
local function buildTalkNotice(frame, topicData, args)
	local restrictions = topicData.restrictions
	local type = args['type'] or args[2] or 'standard'
	local out = mw.html.create('')

	if type == 'long' then
		out
			:tag('span')
				:css('font-size', '120%')
				:wikitext("'''WARNING: ACTIVE COMMUNITY SANCTIONS'''")
	end

	if type == 'long' then
		out
			:tag('p')
				:wikitext("The article [[:{{SUBJECTPAGENAME}}]], along with other pages relating to "..topicData.scope..", is currently subject to '''[[WP:AC/DS|discretionary sanctions]]''' authorised by the community (see: [[".. topicData['wikilink'] .."]])." .. ((args['1rr'] or args['consensusrequired'] or args['brd'] or args['restriction1']) and ' An administrator has applied the following restrictions to this article:' or '') .. (restrictions['1rr'] and ' The current restrictions are:' or ''))
	else
		out
			:tag('p')
				:wikitext("<strong>The use of [[WP:AC/DS|discretionary sanctions]] has been [[".. topicData['wikilink'] .."|authorised]] by the community for pages related to ".. topicData['scope'] ..", including this page.</strong>" .. (type == 'mini' and ' Please consult the [[Wikipedia:Arbitration_Committee/Discretionary_sanctions#Awareness|awareness criteria]] and edit carefully.' or ''))
	end

	if not (type == 'mini') then
		local hasList = false
		local hasRevertRestrictions = false
		local restrictionList = mw.html.create('ul')

		if restrictions['1rr'] or args['1rr'] then
			hasList = true
			hasRevertRestrictions = true

			restrictionList
				:tag('li')
					:wikitext("'''Limit of one revert in 24 hours:''' This article is under [[Wikipedia:Edit warring#Other revert rules|WP:1RR]] (one [[Wikipedia:Reverting|revert]] per editor per article ''per 24-hour period'')")
		end

		if args['consensusrequired'] then
			hasList = true
			hasRevertRestrictions = true

			restrictionList
				:tag('li')
					:wikitext("'''Consensus required:''' All editors must obtain [[WP:Consensus|consensus]] on the talk page of this article before reinstating ''any edits that have been challenged (via reversion).'' This includes making edits similar to the ones that have been challenged. If in doubt, do not make the edit.")
		end

		if args['brd'] then
			hasList = true
			hasRevertRestrictions = true

			restrictionList
				:tag('li')
					:wikitext("'''24-hr [[Wikipedia:BOLD, revert, discuss cycle|BRD cycle]]:''' If a change you make to this article is reverted, you may not reinstate that change unless you discuss the issue on the talk page and wait 24 hours (from the time of the original edit). Partial reverts/reinstatements that reasonably address objections of other editors [[Wikipedia:BOLD, revert, discuss cycle#WP:BRR|are preferable]] to wholesale reverts.")
		end

		local ri = 1
		while true do
			if args['restriction'..ri] then
				restrictionList
					:tag('li')
						:wikitext(args['restriction'..ri])
				ri = ri + 1
				hasList = true
			else
				break
			end
		end

		if hasList then
			out:node(restrictionList)
		end

		out
			:tag('p')
				:wikitext("Provided the [[Wikipedia:Arbitration_Committee/Discretionary_sanctions#Awareness|awareness criteria]] are met, discretionary sanctions may be used against editors who repeatedly or seriously fail to adhere to the [[Wikipedia:Five_pillars|purpose of Wikipedia]], any expected [[Wikipedia:Etiquette|standards of behaviour]], or any [[Wikipedia:List_of_policies|normal editorial process]].")
			
		-- Further info box
		if type == 'long' and (restrictions['ds'] or restrictions['1rr'] or args['1rr']) then
			local furtherInfo = mw.html.create('')

			-- Enforcement procedures
			furtherInfo
				:tag('p')
					:wikitext('Enforcement procedures:')
					:done()

			local enforcementProcedures = mw.html.create('ul')

			if hasRevertRestrictions or args['restriction1'] then
				enforcementProcedures
					:tag('li')
						:wikitext("Violations of any restrictions (excluding 1RR violations) and other conduct issues should be reported to the [[Wikipedia:Administrators' noticeboard/Incidents|administrators' incidents noticeboard]]. Violations of the 1RR restriction should be reported to the [[WP:ANEW|administrators' edit warring noticeboard]].")
						:done()
					:tag('li')
						:wikitext("Editors who violate any listed restrictions may be blocked by any uninvolved administrator, even on a first offense.")
						:done()
			else
				enforcementProcedures
					:tag('li')
						:wikitext("Problems should be reported to the [[Wikipedia:Administrators' noticeboard/Incidents|administrators' incidents noticeboard]].")
						:done()
			end

			enforcementProcedures
				:tag('li')
					:wikitext("An editor must be [[Wikipedia:Arbitration_Committee/Discretionary_sanctions#Awareness|aware]] before they can be sanctioned.")
					:allDone()
			furtherInfo:node(enforcementProcedures)

			if hasRevertRestrictions then
				furtherInfo
					:tag('p')
						:wikitext("With respect to the WP:1RR restriction:")
						:done()
					:tag('ul')
						:tag('li')
							:wikitext("Edits made solely to enforce any clearly established consensus are exempt from all edit-warring restrictions. In order to be considered \"clearly established\" the consensus must be proven by prior talk-page discussion.")
							:done()
						:tag('li')
							:wikitext("Edits made which remove or otherwise change any material placed by clearly established consensus, without first obtaining consensus to do so, may be treated in the same manner as clear vandalism.")
							:done()
						:tag('li')
							:wikitext("Clear vandalism of any origin may be reverted without restriction.")
							:done()
						:tag('li')
							:wikitext("Reverts of edits made by anonymous (IP) editors that are not vandalism are exempt from the 1RR but are subject to [[Wikipedia:Edit warring|the usual rules on edit warring]]. If you are in doubt, contact an administrator for assistance.")
							:allDone()
					:tag('p')
							:wikitext("If you are unsure if your edit is appropriate, discuss it here on this talk page first. <strong>Remember: When in doubt, don't revert!</strong>")
			end

			local collapsed = frame:expandTemplate{ title = 'collapse', args = {	-- TODO not use template
				tostring(furtherInfo),
				(hasRevertRestrictions and '<span style="color:red">' or '')..'Remedy instructions and exemptions'..(hasRevertRestrictions and '</span>' or ''),
				['bg'] = '#EEE8AA'
			}}
			
			out
				:newline()
				:node(collapsed)
		end
		-- End further info box
	end

	local box = messageBox.main( 'tmbox', {
		type = 'notice',
		image = type == 'long' and '[[File:Commons-emblem-issue.svg|50px]]' or '[[Image:Commons-emblem-hand-orange.svg|40px]]',
		text = frame:preprocess(tostring(out))
    })

    return box
end

-- Builds an alert notice
--
-- @param frame
-- @param topicData data for the given topic from the /data page
-- @returns String representation of notice
local function buildAlert(frame, topicData)
	local out = mw.html.create('table')
		:addClass('messagebox')
		:cssText("border: 1px solid #AAA; background: #E5F8FF; padding: 0.5em; width: 100%;")

	out
		:tag('tr')
			:tag('td')
				:cssText("vertical-align:middle; padding-left:1px; padding-right:0.5em;")
				:wikitext("[[File:Commons-emblem-notice.svg|50px]]")
				:done()
			:tag('td')
				:wikitext("This is a standard message to notify contributors about an administrative ruling in effect. ''It does '''not''' imply that there are any issues with your contributions to date.''")
				:newline()
				:wikitext("You have shown interest in ".. topicData.scope ..". Due to past disruption in this topic area, the community has enacted a more stringent set of rules. Any administrator may impose [[Wikipedia:General sanctions|sanctions]] - such as [[Wikipedia:Editing restrictions#Types of restrictions|editing restrictions]], [[Wikipedia:Banning policy#Types of bans|bans]], or [[WP:Blocking policy|blocks]] - on editors who do not strictly follow [[Wikipedia:List of policies|Wikipedia's policies]], or the [[Wikipedia:Arbitration_Committee/Discretionary_sanctions#Page_restrictions|page-specific restrictions]], when making edits related to the topic.")
				:newline()
				:wikitext("For additional information, please see the [[".. topicData.wikilink .."|guidance on these sanctions]]. If you have any questions, or any doubts regarding what edits are appropriate, you are welcome to discuss them with me or any other editor.")

	return frame:preprocess(tostring(out))
end

-- Builds an edit notice
local function buildEditNotice(frame, topicData, args)
	local restrictions = topicData.restrictions
	local enHeader = mw.html.create('')
	local restrictionMsgs = {}
	
	if restrictions['1rr'] or args['1rr'] then
		table.insert(restrictionMsgs, "are restricted to making no more than one [[Help:Reverting|revert]] per twenty-four (24) hours (subject to exceptions below)")
	end
	
	if args['consensusrequired'] then
		table.insert(restrictionMsgs, "must not reinstate any challenged (via reversion) edits without first [[WP:CRP|obtaining consensus]] on the talk page of this article")
	end

	local ri = 1
	while true do
		if args['restriction'..ri] then
			table.insert(restrictionMsgs, args['restriction'..ri])
			ri = ri + 1
		else
			break
		end
	end

	if #restrictionMsgs == 0 then
		return frame:preprocess(syntaxHelp())
	elseif #restrictionMsgs == 1 then
		enHeader
			:wikitext("Editors to this page " .. restrictionMsgs[1])
	else
		enHeader
			:wikitext("Editors to this page:")
		
		for _,v in ipairs(restrictionMsgs) do
			enHeader
				:newline()
				:wikitext("* " .. v)
		end
	end

	local enText = mw.html.create('')
	enText
		:tag('p')
			:wikitext("This is due to [["..topicData.wikilink.."|active community sanctions]] on all pages relating to "..topicData.scope..". <strong>If you breach the restriction on this page, you may be blocked or otherwise sanctioned" .. (restrictions['1rr'] and " <u>without warning</u>" or "") .. ".</strong> Please edit carefully.")
			:done()
		:tag('p')
			:wikitext("In addition, please note that discretionary sanctions are in force across this topic area, and can be used against individual editors who repeatedly or seriously fail to adhere to the [[Wikipedia:Five pillars|purpose of Wikipedia]], any expected [[Wikipedia:Etiquette|standards of behaviour]], or any [[Wikipedia:List of policies|Wikipedia policy and editorial norm]].")
			:done()
		:tag('p')
			:css("font-size", "85%")
			:wikitext("Before you make any more edits to pages in this topic area, please familiarise yourself with the [[Wikipedia:General sanctions|general sanctions system]] and the [["..topicData.wikilink.."|restrictions in this topic area]]." .. ((restrictions['1rr'] or args['1rr']) and " Clear vandalism of whatever origin may be reverted without restriction. Reverts of edits made by anonymous IP editors that are not vandalism are exempt from 1RR but are subject to the usual rules on edit warring." or "") .. (restrictions['500/30'] and " Edits by unregistered users and editors with less than 500 edits or 30 days tenure may be reverted without regarding the one revert rule." or ""))
		

	local editnotice = frame:expandTemplate{ title = 'editnotice', args = {
		expiry = "indefinite",
		headerstyle = "font-size: 120%;",
		style = "background: ivory;",
		image = "Commons-emblem-issue.svg",
		imagesize = "50px",
		header = tostring(enHeader),
		text = tostring(enText)
	}}

	return editnotice
end

--/////////--
-- EXPORTS
--/////////--
local p = {}

-- Returns a talk notice
-- For documentation, see [[Template:Gs/talk notice]]
function p.talknotice(frame)
	local args = getArgs(frame, {
		wrappers = {
			'Template:Gs/talk notice',
			'Template:Gs/talk notice/sandbox'
		}
	})

	local topic = getTopicData(frame, args['topic'] or args[1])

	if not topic then
		return frame:preprocess(syntaxHelp())
	elseif not topic.restrictions or (not topic.restrictions['ds'] and not topic.restrictions['1rr']) then
		-- error: no relevant sanctions authorised
		return frame:preprocess('<span class="error">No relevant sanctions authorised for this topic.</span>')
	end
	
	return buildTalkNotice(frame, topic, args)
end

-- Returns an alert
-- For documentation, see [[Template:Gs/alert]]
function p.alert(frame)
	local args = getArgs(frame, {
		wrappers = {
			'Template:Gs/alert',
			'Template:Gs/alert/sandbox',
		}
	})

	local topic = getTopicData(frame, args['topic'] or args[1])
	if not topic then
		return frame:preprocess(syntaxHelp())
	elseif not topic.restrictions or not topic.restrictions['ds'] then
		-- error: DS not authorised, alert not needed
		return frame:preprocess('<span class="error">Discretionary sanctions are not authorised for this topic area. Alert is not required.</span>')
	end
	
	return buildAlert(frame, topic)
end

-- Returns an edit notice
-- For documentation, see [[Template:Gs/editnotice]]
function p.editnotice(frame)
	local args = getArgs(frame, {
		wrappers = {
			'Template:Gs/editnotice',
			'Template:Gs/editnotice/sandbox',
		}
	})

	local topic = getTopicData(frame, args['topic'] or args[1])
	if not topic then
		return frame:preprocess(syntaxHelp())
	elseif not topic.restrictions or (not topic.restrictions['1rr'] and not args['1rr'] and not args['consensusrequired'] and not args['restriction1']) then
		-- error: no custom restrictions authorised, alert not needed
		return frame:preprocess('<span class="error">Page sanctions are not authorised for this topic area. Edit notice is not required.</span>')
	end

	return buildEditNotice(frame, topic, args)
end

function p.table(frame)
	local args = getArgs(frame, {
		wrappers = {
			'Template:Gs/topics/table',
			'Template:Gs/topics/table/sandbox',
		}
	})

	local tbl = mw.html.create('table')
		:addClass('wikitable')
		:css('font-size', '9pt')
		:css('background', 'transparent')

	-- Headers
	tbl:tag('tr')
		:tag('th')
			:wikitext("Topic code")
			:done()
		:tag('th')
			:wikitext("Area of conflict")
			:done()
		:tag('th')
			:wikitext("Decision linked to")
			:allDone()
	
	-- sort alphabetically
	local sortedTable = {}
	for n in pairs(data) do
		table.insert(sortedTable, n)
	end
	table.sort(sortedTable)

	for _,v in ipairs(sortedTable) do
		local sanction = data[v]
		local title = mw.title.new(sanction.wikilink).redirectTarget			-- probably unnecessarily expensive; just add to config
		tbl:tag('tr')
			:tag('td')
				:wikitext(frame:preprocess("{{tlx"..(args['subst'] and "s" or "").."|{{PAGENAME}}|<nowiki>topic=</nowiki><b>"..(sanction.palias or v).."</b>}}"))
				:done()
			:tag('td')
				:wikitext(sanction.scope)
				:done()
			:tag('td')
				:wikitext("[["..title.fullText.."]]")
				:allDone()
	end

	return tostring(tbl)
end

function p.topicsHelper(frame)
	local args = getArgs(frame, {
		wrappers = {
			'Template:Gs/topics',
			'Template:Gs/topics/sandbox'
		}
	})

	if args['sanctions scope'] and data[args['sanctions scope']] then
		return _getTopicData(args['sanctions scope']).scope
	elseif args['sanctions link'] and data[args['sanctions link']] then
		return mw.title.new(_getTopicData(args['sanctions link']).wikilink).redirectTarget
	else
		return "" -- ?
	end
end

return p