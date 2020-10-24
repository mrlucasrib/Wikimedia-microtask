local export = {}

-- XXX: OUTRAGEOUS ABUSE OF SCRIBUNTO API
-- Generates a transclusion without incrementing the "expensive function" count
local generate_transclusion
do 
	local mock_title = mw.title.new(mw.title.getCurrentTitle().id)
	local getContent = mock_title.getContent
	function generate_transclusion(title)
		local full_text = type(title) == 'table' and title.fullText or title
		rawset(mock_title, 'fullText', full_text)
		getContent(mock_title)
	end
end

local function make_wikitext_warning(msg)
	return string.format('<strong class="warning">Warning: %s.</strong>', msg)
end

function export.lock(frame)
	local warnings, transclusion_list = {}, {}
	
	-- Check if the transcluding page is cascade-protected.
	--
	-- Only pages transcluded from a cascade-protected page appear in
	-- CASCADINGSOURCES, so normally we would not be able to tell if the lockbox
	-- itself is cascade-protected. To work around this, we generate a
	-- transclusion from the lockbox to itself, so that it will have an entry
	-- for itself in CASCADINGSOURCES.
	--
	-- We cannot generate this transclusion using the title object for the
	-- parent title (the lockbox), as if the lockbox is transcluded on another
	-- page, we will generate a transclusion *from* the lockbox *to* that page
	-- as well, and the page will be cascade-protected. Instead we generate it
	-- with the title object for the current title.
	--
	-- When the current title is the parent title (i.e. we are rendering the
	-- lockbox page), this creates the required entry in the link table in the
	-- database. When the current title is the grandparent title or up (i.e. we
	-- are rendering a page transcluding the lockbox), transclusions are only
	-- created from the page itself, not from the lockbox, and it is not
	-- cascade-protected.
	-- 
	-- This creates an extaneous self-transclusion for all pages using the
	-- module, but we treat that as a necessary evil.
	do
		mw.title.getCurrentTitle():getContent() -- Generate self-transclusion
		local parent_title = frame:getParent():getTitle()
		if not mw.title.new(parent_title).cascadingProtection.sources[1] then
			warnings[#warnings + 1] = make_wikitext_warning(string.format(
				'the page "%s" is not cascade-protected',
				parent_title
			))
		end
	end

	-- Generate transclusions to the templates, and build the output list.
	for i, item in ipairs(frame.args) do
		item = mw.text.trim(item)
		local title = mw.title.new(item)
		if title then
			local ns = title.namespace
			local prefixed_text = title.prefixedText
			if ns == 0 then
				-- The item had no namespace text. If the item starts with a
				-- colon, assume it is a mainspace page. Otherwise, assume it is
				-- a template.
				if item:sub(1, 1) == ':' then
					generate_transclusion(title)
					table.insert(transclusion_list, '* [[' .. prefixed_text .. ']]')
				else
					generate_transclusion('Template:' .. prefixed_text)
					table.insert(transclusion_list, '* [[Template:' .. prefixed_text .. ']]')
				end
			elseif ns == 6 or ns == 14 then -- File or Category namespace
				generate_transclusion(title)
				table.insert(transclusion_list, '* [[:' .. prefixed_text .. ']]')
			else
				generate_transclusion(title)
				table.insert(transclusion_list, '* [[' .. prefixed_text .. ']]')
			end
		else
			warnings[#warnings + 1] = make_wikitext_warning(string.format(
				'invalid title "%s" in argument #%d',
				item,
				i
			))
		end
	end

	if frame.args.silent then
		return ''
	else
		-- If there were any warnings, show them at the top. Then show the list
		-- of transcluded pages.
		local ret = ''
		if #warnings > 0 then
			if #warnings > 1 then
				for i, warning in ipairs(warnings) do
					warnings[i] = '* ' .. warning
				end
			end
			ret = ret .. table.concat(warnings, '\n') .. '\n\n'
		end
		return ret .. table.concat(transclusion_list, '\n')
	end
end

return export