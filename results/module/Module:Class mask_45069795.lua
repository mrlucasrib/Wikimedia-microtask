-- This module implements [[Template:Class mask]].

local p = {}

local function getDocWarning(title)
	if title.namespace == 10 and title.subpageText == 'class' then
		return mw.getCurrentFrame():expandTemplate{
			title = 'Class mask/doc warning'
		}
	end
end

local function trim(s)
	return s:match('^%s*(.-)%s*$')
end

local function ucfirst(s)
	-- Returns the given string with the first character in upper case.
	-- Should not be used with non-ascii strings.
	return s:sub(1, 1):upper() .. s:sub(2, -1)
end

local function isTruthyBParam(s)
	s = s and s:lower()
	return not s or s == 'yes' or s == 'y' or s == '1' or s == 'pass' or s == 'na' or s == 'n/a' or s == '¬' or s == 'unused'
end

local function resolveFQSgrade(grade, args)
	if (args[grade] or args.FQS) == 'yes' then
		return ucfirst(grade)
	else
		return 'NA'
	end
end

local function resolveExtraGrade(grade, args)
	if args[grade] == 'yes' then
		return ucfirst(grade)
	else
		return 'NA'
	end
end

local function resolveDefaultGrade(args, title, talkDefault)
	local ns = title.namespace
	if ns == 1 then -- Talk
		return talkDefault
	elseif ns == 7 then -- File talk
		return resolveFQSgrade('file', args)
	elseif ns == 15 then -- Category talk
		return resolveFQSgrade('category', args)
	elseif ns == 101 then -- Portal talk
		return resolveFQSgrade('portal', args)
	elseif ns == 11 then -- Template talk
		return resolveFQSgrade('template', args)
	elseif ns == 5 then -- Wikipedia talk
		return resolveFQSgrade('project', args)
	elseif ns == 119 then -- Draft talk
		return resolveFQSgrade('draft', args)
	elseif ns == 109 then -- Book talk
		return resolveExtraGrade('book', args)
	else
		return 'NA'
	end
end

local function getGrade(args, title)
	local grade = args[1]
	-- We use string.lower here as it's faster than mw.ustring.lower and none
	-- of the standard grades have non-Ascii characters.
	grade = grade and trim(grade):lower()

	local ret

	-- Undefined
	if not grade or grade == '¬' then
		ret = '¬'

	-- Blank or empty
	elseif grade == '' then
		ret = args['']

	-- Ucfirst
	-- We put these near the start as they are probably the most common grades
	-- on the site. The other grades are also roughly in order of prevalence.
	elseif grade == 'start' or grade == 'stub' or grade == 'list' then
		if args[grade] ~= 'no' then
			ret = ucfirst(grade)
		end

	-- B
	elseif grade == 'b' then
		local bParams = {'b1', 'b2', 'b3', 'b4', 'b5', 'b6'}
		local isExtended = false
		for _, param in ipairs(bParams) do
			if args[param] then
				isExtended = true
				break
			end
		end
		if isExtended then
			local isB = true
			for _, param in ipairs(bParams) do
				if not isTruthyBParam(args[param]) then
					isB = false
					break
				end
			end
			ret = isB and 'B' or 'C'
		elseif args.b ~= 'no' then
			ret = 'B'
		end

	-- Upper-case
	elseif grade == 'fa' or grade == 'fl' or grade == 'a' or grade == 'ga' or grade == 'c' then
		if args[grade] ~= 'no' then
			ret = grade:upper()
		end

	-- NA
	elseif grade == 'na' then
		if args.forceNA == 'yes' then
			ret = resolveDefaultGrade(args, title, 'NA')
		else
			ret = 'NA'
		end

	-- File
	elseif grade == 'file' or grade == 'image' or grade == 'img' then
		ret = resolveFQSgrade('file', args)

	-- Category
	elseif grade == 'category' or grade == 'cat' or grade == 'categ' then
		ret = resolveFQSgrade('category', args)

	-- Disambguation
	elseif grade == 'dab' or grade == 'disambig' or grade == 'disambiguation' or grade == 'disamb' then
		ret = resolveFQSgrade('disambig', args)

	-- Redirect
	elseif grade == 'redirect' or grade == 'red' or grade == 'redir' then
		ret = resolveExtraGrade('redirect', args)

	-- Portal, Project and Draft
	elseif grade == 'portal' or grade == 'project' or grade == 'draft' then
		ret = resolveFQSgrade(grade, args)

	-- Template
	elseif grade == 'template' or grade == 'temp' or grade == 'tpl' or grade == 'templ' then
		ret = resolveFQSgrade('template', args)

	-- Book
	elseif grade == 'book' then
		ret = resolveExtraGrade('book', args)

	-- FM
	elseif grade == 'fm' then
		if args.fm == 'yes' then
			ret = 'FM'
		else
			ret = resolveFQSgrade('file', args)
		end

	else
		-- We can't guarantee that we will only have Ascii grades any more, so
		-- normalize the grade again using mw.ustring where necessary. 
		local trimmedGrade = trim(args[1])

		-- Upper-case syntax
		ret = args[mw.ustring.upper(trimmedGrade)]

		-- Lower-case syntax
		if not ret then
			local normalizedGrade = mw.ustring.lower(grade)
			if args[normalizedGrade] == 'yes' then
				ret = mw.language.getContentLanguage():ucfirst(normalizedGrade)
			end
		end

		-- Defaults
		if not ret then
			ret = resolveDefaultGrade(args, title)
		end
	end

	return ret
end

function p._main(args, title)
	title = title or mw.title.getCurrentTitle()
	local docWarning = getDocWarning(title) or ''
	local grade = getGrade(args, title) or ''
	return docWarning .. grade
end

function p.main(frame)
	return p._main(frame:getParent().args)
end

return p