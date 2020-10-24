-- This module implements [[Template:Request redirect]].

local p, templates = {}, {}

--------------------------------------------------------------------------------
-- Templates
--
-- These are templates used in the module's output. The templates use two
-- different kinds of parameter. Parameters that look like ${parameter} will be
-- replaced with the corresponding value from a data table. Parameters that 
-- look like ${@TEMPLATE_NAME} will be replaced recursively by other templates
-- in the templates table. This helps to reduce duplication of template code
-- while also avoiding tricky conditional logic inside templates.
-- 
-- Templates can contain arbitrary wikitext; wikitext will be expanded on
-- transclusion, and left as-is on substitution.
--------------------------------------------------------------------------------

templates.HEADING = '== Redirect request: [[:${title}]] =='

templates.BODY = [=[
* Target of redirect: [[:${target}]]
* Reason: ${reason}
* Source (if applicable): ${source}
~~~~]=]

templates.OPEN_REQUEST = [=[
${@HEADING}
${@BODY}]=]

templates.CLOSED_REQUEST = [=[
${@HEADING}
{{afc-c|d}}
${@BODY}

${afcredirect} <small>(Automatically declined)</small>
{{afc-c|b}}]=]

templates.REQUEST_WITH_ERROR = [=[
${@HEADING}
${@BODY}

{{error|Error: ${errormsg}}}<!--subst:afc redirect|${closereason}-->]=]

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Substitutes parameters like ${parameter} and ${@TEMPLATE_NAME}. Templates
-- are transcluded recursively.
local function substituteParameters(template, data)
	local content = templates[template]
	if not content then
		error(string.format(
			"the template '%s' does not exist",
			tostring(template)
		))
	end
	content = content:gsub('${(@?)([a-zA-Z_]+)}', function (at, param)
		if at == '@' then
			return substituteParameters(param, data)
		else
			return data[param] or ''
		end
	end)
	return content
end

-- Expand a template, substituting parameters and expanding wikitext as
-- appropriate.
local function expand(template, data, frame)
	frame = frame or mw.getCurrentFrame()
	local content = substituteParameters(template, data)
	if mw.isSubsting() then
		return content
	else
		return frame:preprocess(content)
	end
end

-- Finds a page's status. This can be either:
-- * "noinput" - for missing user input
-- * "invalid" - for invalid titles (e.g. page names containing the "|" symbol)
-- * "missing" - valid titles that don't exist
-- * "exists"  - valid titles that exist
local function getPageStatus(page)
	if not page then
		return 'noinput'
	end
	local title = mw.title.new(page)
	if not title then
		return 'invalid'
	elseif title.exists then
		return 'exists'
	else
		return 'missing'
	end
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

function p._main(args, frame)
	frame = frame or mw.getCurrentFrame()

	local data = {}
	data.title = args.title or args[1]
	data.target = args.target or args[2]
	data.reason = args.reason or args[3]
	data.source = args.source or args[4]

	-- Check parameters for errors.
	local titleStatus = getPageStatus(data.title)
	local targetStatus = getPageStatus(data.target)
	local closeReason
	if titleStatus == 'invalid' then
		closeReason = 'notitle'
		data.errormsg = string.format(
			'"%s" is an invalid title.',
			data.title
		)
	elseif targetStatus == 'invalid' then
		closeReason = 'notarget'
		data.errormsg = string.format(
			'"%s" is an invalid title.',
			data.target
		)
	elseif titleStatus == 'exists' then
		if targetStatus == 'exists' then
			closeReason = 'exist'
			data.errormsg = string.format(
				'[[:%s]] already exists on Wikipedia.',
				data.title
			)
		elseif targetStatus == 'missing' then
			-- Assume the user got the pages the wrong way round.
			data.title, data.target = data.target, data.title
		else
			-- targetStatus == 'noinput'
			closeReason = 'notitle'
			data.errormsg = 'You have not specified the title of the redirect that you want created.'
		end
	elseif titleStatus == 'missing' then
		-- If targetStatus == 'exists' the submission is good and we don't need
		-- to do anything.
		if targetStatus == 'missing' then
			closeReason = 'notarget'
			data.errormsg = string.format(
				"Redirect target [[:%s]] doesn't exist.",
				data.target
			)
		elseif targetStatus == 'noinput' then
			closeReason = 'notarget'
			data.errormsg = 'Redirect target was not specified.'
		end
	else
		-- titleStatus == 'noinput'
		if targetStatus == 'exists' then
			closeReason = 'notitle'
			data.errormsg = 'You have not specified the title of the redirect that you want created.'
		elseif targetStatus == 'missing' then
			closeReason = 'notarget'
			data.errormsg = string.format(
				"Redirect target [[:%s]] doesn't exist.",
				data.target
			)
		else
			-- targetStatus == 'noinput'
			closeReason = 'blank'
			data.errormsg = 'We cannot accept empty submissions.'
		end
	end

	-- Find the template we need, and expand {{Afc redirect}} if it is needed.
	local template
	if closeReason and args.close then
		template = 'CLOSED_REQUEST'
		data.afcredirect = frame:expandTemplate{
			title = 'afc redirect',
			args = {closeReason}
		}
	elseif closeReason then
		template = 'REQUEST_WITH_ERROR'
	else
		template = 'OPEN_REQUEST'
	end

	-- Return the template with parameters substituted.
	return expand(template, data, frame)
end

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Request redirect'
	})
	return p._main(args, frame)
end

return p