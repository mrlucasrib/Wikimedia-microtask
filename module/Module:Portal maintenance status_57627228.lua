local p = {}

function cleanupArgs(argsTable)
	local cleanArgs = {}
	for key, val in pairs(argsTable) do
		if type(val) == 'string' then
			val = val:match('^%s*(.-)%s*$')
			if val ~= '' then
				cleanArgs[key] = val
			end
		else
			cleanArgs[key] = val
		end
	end
	return cleanArgs
end

local content = {}

function makeTemplatePattern(template)
	local first = string.sub(template, 1, 1)
	local rest = string.sub(template, 2)
	local pattern = mw.ustring.format('%s[%s%s]%s%s', '%{%{%s*', mw.ustring.upper(first), mw.ustring.lower(first), rest, '%s*|?[^%}]*%}%}')
	return pattern
end

function makeParameterPattern(parameter)
	return mw.ustring.format('%s%s%s%s', '|%s*', parameter, '%s*=%s*', '([^|%}]*)', '%s*[|%}]')
end

function getMatchingTemplateWikitext(content, template, leadOnly)
	if leadOnly then
		content = mw.ustring.gsub(content, "%c%s*==.*","") -- remove first ==Heading== and everything after it
	end
	for templateWikitext in mw.ustring.gmatch(content, '%b{}') do
		local isCorrectTemplate = mw.ustring.match(templateWikitext, makeTemplatePattern(template))
		if isCorrectTemplate then
			return templateWikitext
		end
	end
	return false
end

function getSubjectPageContent(contentNamespaceNumber)
	local namespace = mw.site.namespaces[contentNamespaceNumber] ["name"]
	local talkTitle = mw.title.getCurrentTitle()
	if talkTitle.namespace ~= contentNamespaceNumber + 1 then
		return error('Wrong namespace', 0)
	end
	local subjectTitle = mw.title.new(namespace .. ":" .. talkTitle.text)
	return subjectTitle:getContent()
end

-- historical function
--   Looks for {{Historical}} on a Wikipedia_talk: page's related project page.
--   Returns 'yes' if found or '' (empty string) if not found, or an error if used in the wrong namespace.
p.historical = function(frame)
	local parent = frame.getParent(frame)
	local args = cleanupArgs(frame.args)
	local demo = args.demo and true or false
	local content
	if demo then
		local demoText = mw.ustring.gsub(args.demo, '%{%{%!%}%}', '|')
		content = '{{' .. demoText .. '}}'
		if args.demo2 then
			local demo2Text = mw.ustring.gsub(args.demo2, '%{%{%!%}%}', '|')
			content= portalContent  .. '{{' .. demo2Text .. '}}'
		end
	else
		content = getSubjectPageContent(4)
	end

	content = mw.ustring.gsub(content, "<!%-%-.-%-%->","") -- remove HTML comments
	content = mw.ustring.gsub(content, "%c%s*==.*","") -- remove first ==Heading== and everything after it
	content = mw.ustring.gsub(content, "<noinclude>.-</noinclude>", "") -- remove noinclude bits

	local isHistorical = mw.ustring.match(content, makeTemplatePattern('Historical')) and true or false
	return isHistorical and 'yes' or ''
end

-- featured function
--   Looks for {{Featured portal}} on a Portal_talk: page's related portal page.
--   Returns 'yes' if found or '' (empty string) if not found, or an error if used in the wrong namespace.
p.featured = function(frame)
	local parent = frame.getParent(frame)
	local args = cleanupArgs(frame.args)
	local demo = args.demo and true or false
	local content
	if demo then
		local demoText = mw.ustring.gsub(args.demo, '%{%{%!%}%}', '|')
		content = '{{' .. demoText .. '}}'
		if args.demo2 then
			local demo2Text = mw.ustring.gsub(args.demo2, '%{%{%!%}%}', '|')
			content= portalContent  .. '{{' .. demo2Text .. '}}'
		end
	else
		content = getSubjectPageContent(100)
	end

	content = mw.ustring.gsub(content, "<!%-%-.-%-%->","") -- remove HTML comments
	content = mw.ustring.gsub(content, "<noinclude>.-</noinclude>", "") -- remove noinclude bits

	local isFeatured = mw.ustring.match(content, makeTemplatePattern('Featured portal')) and true or false
	return isFeatured and 'yes' or ''
end

-- main function
--   Looks for {{Portal maintenance status}} (or earlier deprecated templates) on a Portal_talk: page's related portal page.
--   Returns an appropriate message string if found or '' (empty string) if not found, or an error if used in the wrong namespace.
p.main = function(frame)
	local parent = frame.getParent(frame)
	local args = cleanupArgs(frame.args)
	local demo = args.demo and true or false
	local portalContent
	if demo then
		local demoText = mw.ustring.gsub(args.demo, '%{%{%!%}%}', '|')
		portalContent = '{{' .. demoText .. '}}'
		if args.demo2 then
			local demo2Text = mw.ustring.gsub(args.demo2, '%{%{%!%}%}', '|')
			portalContent = portalContent  .. '{{' .. demo2Text .. '}}'
		end
	else
		portalContent = getSubjectPageContent(100)
	end

	local status = getMatchingTemplateWikitext(portalContent, 'Portal maintenance status') or getMatchingTemplateWikitext(portalContent, 'Portal flag')
	if not status then
		return ''
	end

	local output = mw.ustring.sub(status, 0, -3) .. '|embed=yes}}' 
	return frame:preprocess(output)
end

return p