require('Module:No globals')

local infoboxStyle = mw.loadData('Module:WPMILHIST Infobox style')
local templatestyles = 'Module:Infobox military conflict/styles.css'

local IMC = {}
IMC.__index = IMC

function IMC:renderPerCombatant(builder, headerText, prefix, suffix)
	prefix = prefix or ''
	suffix = suffix or ''
	local colspans = {}
	
	-- This may result in colspans[1] getting set twice, but
	-- this is no big deal. The second set will be correct.
	local lastCombatant = 1
	
	for i = 1,self.combatants do
		if self.args[prefix .. i .. suffix] then
			colspans[lastCombatant] = i - lastCombatant
			lastCombatant = i
		end
	end

	local jointText = self.args[prefix .. (self.combatants + 1) .. suffix]
	
	if headerText and (colspans[1] or jointText) then
		builder:tag('tr')
			:tag('th')
				:attr('colspan', self.combatants)
				:cssText(infoboxStyle.header_raw)
				:wikitext(headerText)
	end

	-- The only time colspans[1] wouldn't be set is if no
	-- combatant has a field with the given prefix and suffix.
	if colspans[1] then
		-- Since each found argument set the colspan for the previous
		-- one, the final one wasn't set above, so set it now.
		colspans[lastCombatant] = self.combatants - lastCombatant + 1
		builder = builder:tag('tr')
		for i = 1,self.combatants do
			-- At this point, colspans[i] will be set for i=1 unconditionally, and for
			-- any other value of i where self.args[prefix .. i .. suffix] is set.
			if colspans[i] then
				builder:tag('td')
					-- don't bother emitting colspan="1"
					:attr('colspan', colspans[i] ~= 1 and colspans[i] or nil)
					:css('width', math.floor(100 / self.combatants * colspans[i] + 0.5) .. '%')
					-- no border on the right of the rightmost column
					:css('border-right', i ~= lastCombatant and infoboxStyle.internal_border or nil)
					-- no padding on the left of the leftmost column
					:css('padding-left', i ~= 1 and '0.25em' or nil)
					-- don't show the border if we're directly under a header
					:css('border-top', not headerText and infoboxStyle.internal_border or nil)
					:newline()
					:wikitext(self.args[prefix .. i .. suffix])
			end
		end
	end

	if jointText then
		builder:tag('tr')
			:tag('td')
				:attr('colspan', self.combatants)
				:css('text-align', 'center')
				-- don't show the border if we're directly under a header
				:css('border-top', (not headerText or colspans[1]) and infoboxStyle.internal_border or nil)
				:newline()
				:wikitext(jointText)
	end
end

function IMC:renderHeaderTable(builder)
	builder = builder:tag('table')
		:css('width', '100%')
		:css('margin', 0)
		:css('padding', 0)
		:css('border', 0)

	if self.args.date then
		builder:tag('tr')
			:tag('th')
				:css('padding-right', '1em')
				:wikitext('Date')
			:done()
			:tag('td')
				:wikitext(self.args.date)
	end

	builder = builder:tag('tr')
		:tag('th')
			:css('padding-right', '1em')
			:wikitext('Location')
		:done()
		:tag('td')
			:tag('div')
				:addClass('location')
				:wikitext(self.args.place or '{&#123;{place}&#125;}') -- hack so that people who don't know Lua know that this parameter is required
			:done()
	if self.args.coordinates then
		builder:wikitext(self.args.coordinates)
	end
	builder = builder:done():done()

	-- only for "Putsch"
    if self.args.action then
		builder:tag('tr')
			:tag('th')
				:css('padding-right', '1em')
				:wikitext(self.args.action and 'Action')
			:done()
			:tag('td')
				:wikitext(self.args.action)
	end

	if self.args.status or self.args.result then
		builder:tag('tr')
			:tag('th')
				:css('padding-right', '1em')
				:wikitext(self.args.status and 'Status' or 'Result')
			:done()
			:tag('td')
				:addClass('status')
				:newline()
				:wikitext(self.args.status or self.args.result)
	end

	if self.args.territory then
		builder:tag('tr')
			:tag('th')
				:css('padding-right', '1em')
				:wikitext('Territorial<br />changes')
			:done()
			:tag('td')
				:newline()
				:wikitext(self.args.territory)
	end
end

function IMC:render()
	local builder = mw.html.create()
	if self.args.campaignbox then
		-- this should be the same as using {{stack|clear=right|...}}
		builder = builder:tag('div')
			:addClass('mw-stack desktop-float-right')
			:tag('div')
				:css('overflow', 'hidden')
				:css('margin', '1px')
	end
	builder = builder:tag('table')
		:addClass('infobox vevent')
		:cssText(infoboxStyle.main_box_raw)
		:css('width', self.args.width or nil)

	builder:tag('tr')
		:tag('th')
			:addClass('summary')
			:attr('colspan', self.combatants)
			:cssText(infoboxStyle.header_raw)
			:wikitext(self.args.conflict or mw.title.getCurrentTitle().text)
	if self.args.partof then
		builder:tag('tr')
			:tag('td')
				:attr('colspan', self.combatants)
				:cssText(infoboxStyle.sub_header_raw)
				:wikitext('Part of ' .. self.args.partof)
	end
	if self.args.image then
		builder:tag('tr')
			:tag('td')
				:attr('colspan', self.combatants)
				:cssText(infoboxStyle.image_box_raw)
				:wikitext(string.format('%s%s%s',
					require('Module:InfoboxImage').InfoboxImage{args = {
						image = self.args.image,
						size = self.args.image_size,
						sizedefault = 'frameless',
						upright = 1,
						alt = self.args.alt
					}},
					self.args.caption and '<br />' or '',
					self.args.caption or ''
				))
	end
	self:renderHeaderTable(builder:tag('tr'):tag('td'):attr('colspan', self.combatants))
	self:renderPerCombatant(builder, self.args.combatants_header or 'Belligerents', 'combatant')
	-- can be un-hardcoded once gerrit:165108 is merged
	for _,v in ipairs{'a','b','c','d'} do
		self:renderPerCombatant(builder, nil, 'combatant', v)
	end
	
	self:renderPerCombatant(builder, 'Commanders and leaders', 'commander')
	for _,v in ipairs{'a','b','c','d'} do
		self:renderPerCombatant(builder, nil, 'commander', v)
	end
	
	self:renderPerCombatant(builder, 'Units involved', 'units')
	self:renderPerCombatant(builder, 'Strength', 'strength')
	self:renderPerCombatant(builder, 'Political support', 'polstrength')
	self:renderPerCombatant(builder, 'Military support', 'milstrength')
	self:renderPerCombatant(builder, 'Casualties and losses', 'casualties')

	if self.args.notes then
		builder:tag('tr')
			:tag('td')
				:attr('colspan', self.combatants)
				:css('border-top', infoboxStyle.section_border)
				:newline()
				:wikitext(self.args.notes)
	end
	if self.args.map_type then
		builder:tag('tr')
			:tag('td')
				:attr('colspan', self.combatants)
				:css('border-top', infoboxStyle.internal_border)
				:node(require('Module:Location map').main(self.frame, {
					self.args.map_type,
					relief = self.args.map_relief,
					coordinates = self.args.coordinates,
					width = self.args.map_size or 220,
					float = 'center',
					border = 'none',
					mark = self.args.map_mark,
					marksize = self.args.map_marksize or 8,
					label = self.args.map_label,
					alt = self.args.map_alt,
					caption = self.args.map_caption or ('Location within ' 
						.. (require('Module:Location map').data(self.frame, {self.args.map_type, 'name'})))
				}))
	end
	builder = builder:done()
	if self.args.campaignbox then
		builder = builder:done()
			:tag('div')
				:css('overflow', 'hidden')
				:css('margin', '1px')
				:wikitext(self.args.campaignbox)
			:done()
		:done()
	end
	return builder
end

function IMC.new(frame, args)
	if not args then
		args = require('Module:Arguments').getArgs(frame, {wrappers = 'Template:Infobox military conflict'})
	end
	local obj = {
		frame = frame,
		args = args
	}

	-- until gerrit:165108 is merged, there's still a cap on combatants, but as soon as it merges, we can update this little bit of code to uncap it
	-- also, don't try to make this more efficient, or references could be in the wrong order
	obj.combatants = 2
	for _,v in ipairs{'', 'a', 'b', 'c', 'd'} do
		for i = 1,5 do
			if args['combatant' .. i .. v] then
				obj.combatants = math.max(obj.combatants, i)
			end
		end
	end

	return setmetatable(obj, IMC)
end

local p = {}

function p.main(frame)
	return frame:extensionTag{ name = 'templatestyles', args = { src = templatestyles} } .. tostring(IMC.new(frame):render())
end

return p