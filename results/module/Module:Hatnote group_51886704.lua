local mHatnote = require('Module:Hatnote')
local p = {}

--Collates key-based table of classes into usable class list
function collateClassList (listTable)
	local list = {}
	for k, v in pairs(listTable) do
		if v and type(k) == "string" then table.insert(list, k) end
	end
	return table.concat(list, " ")
end

--Passes through single argument from parent frame
function p.group (frame)
	return p._group(frame:getParent().args[1], frame:getParent().args.category)	
end

function p._group (inputText, category)
	--If there's an error element, pass everything through unchanged for easier
	--error resolution
	if string.find(inputText, '<%a- class="error"', 1, true) then return inputText end
	
	--Heavily reused hatnote data capture pattern
	local hatnotePattern = '(<div role="note" class="hatnote navigation%-not%-searchable%s?(.-)">(.-)</div>)'
	
	--Capture hatnote divs and "loose" categories; we'll ignore everything else
	local rawDivs = {}
	local looseCategories = ''
	for x in string.gmatch(inputText, hatnotePattern) do
		table.insert(rawDivs, x)
	end
	for x in string.gmatch(inputText, '%[%[Category:.-%]%]') do
		looseCategories = looseCategories .. x
	end

	--if no inner hatnotes, return an error
	if not rawDivs[1] then
		return mHatnote.makeWikitextError(
			'no inner hatnotes detected',
			'Template:Hatnote group',
			category
		)
	end

	--Preprocess divs into strings and classes
	local innerHatnotes = {}
	for k, v in pairs(rawDivs) do
		row = {}
		row.text = string.gsub(v, hatnotePattern, '%3')
		--Here we set class names as keys for easier intersection later
		row.classes = {}
		for m, w in ipairs(
			mw.text.split(
				string.gsub(v, hatnotePattern, '%2'),
				' ',
				true
			)
		) do
			row.classes[mw.text.trim(w)] = true
		end
			
		table.insert(innerHatnotes, row)
	end
	
	--Identify any universal classes ("hatnote" ignored by omission earlier)
	local universalClasses = {}
	--clone first classes table to force passing by value rather than reference
	for k, v in pairs(innerHatnotes[1].classes) do universalClasses[k] = v end
	for k, v in ipairs(innerHatnotes) do
		for m, w in pairs(universalClasses) do
			universalClasses[m] = (universalClasses[m] and v.classes[m])
		end
	end
	
	--Remove universal classes from div items, then create class strings per row
	for k, v in ipairs(innerHatnotes) do
		for m, w in pairs(v.classes) do
			if universalClasses[m] then v.classes[m] = nil end
		end
		v.classString = collateClassList(v.classes)
	end
	
	--Process div items into classed span items
	local innerSpans = {}
	for k, v in ipairs(innerHatnotes) do
		table.insert(
			innerSpans,
			(v.classString ~= '') and
				string.format('<span class="%s">%s</span>', v.classString, v.text) or
				string.format('<span>%s</span>', v.text)
		)
	end

	--Concatenate spans and categories, and return wrapped as a single hatnote
	local outputText = table.concat(innerSpans, " ") .. looseCategories
	local hnOptions = {extraclasses = collateClassList(universalClasses)}
	return mHatnote._hatnote(outputText, hnOptions)
end

return p