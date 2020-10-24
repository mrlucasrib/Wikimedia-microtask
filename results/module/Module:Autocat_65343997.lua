--by HastaLaVi2

---*---*---*---*---*---*---*---*---*---*---*---*---
-- CATEGORY OBJECT
---*---*---*---*---*---*---*---*---*---*---*---*---
local Category = {}


function Category:getName()
	return self._name
end


function Category:getCategoryName()
	local year = self._year
	local name = self:getName()
	
	local function check(year, name)
		return mw.title.new('Category:' .. fixBC(year) .. " " .. name).exists and fixBC(year) .. " " .. name
	end
	
	if self._type == "year" then
		return fixBC(year) .. " " .. name
	elseif self._type == "decade" then
		return fixBC(year.."s") .. " " .. name
	elseif self._type == "century" then
		return check(suffixToYear(year).." century", name) or fixBC(suffixToYear(year).."-century") .. " " .. name
	elseif self._type == "millennium" then
		return check(suffixToYear(year).." millennium", name) or fixBC(suffixToYear(year).."-millennium") .. " " .. name
	else
		return name
	end
end


function Category:getBarName()
	return self._type == "year" and fixBC(self._year)
		or (self._type == "decade" and fixBC(self._year.."s"))
		or (self._type == "century" and fixBC(suffixToYear(self._year)))
		or (self._type == "millennium" and fixBC(suffixToYear(self._year)))
end


function Category:getYear()
	return self._year
end


function Category:byCat()
	return self._rawData.byCat
end


function Category:stage()
	return self._rawData.stage
end


function Category:getUpYear()
	return self._type == "year" and getDecade(self._year) or
		(self._type == "decade" and getCentury(self._year) or
		(self._type == "century" and getMillennium(self._year) ))
end


function Category:getWikidata()
	return mw.wikibase.getEntity(mw.wikibase.getEntityIdForCurrentPage())
end


function Category:getParents()
	local parents = {}

	--[[
		if there is already a specified "by category" in parents table,
		we do not need to add a new one, but by default this boolean should always be true
	--]]
	local byCat = true

	--list of the parents
	local chain = self._rawData.parents or {}
	local _type = self._type

	--call objects for each parent
	for _,parent in ipairs(chain) do
		if parent == "categories" and _type ~= "byCat" then parent = "" end
		if parent == "years" or parent == "decades" or parent == "centuries" or parent == "millennia" then _type = "up" end
		parent = mw.ustring.gsub(parent, "{{{type}}}", _type)
		table.insert(parents, getByName(parent, self._year, _type))
		
		--and here we detect if one of the parents is a "by category"
		if mw.ustring.find(parent, "%sby%s") then
			byCat = nil
		end
	end
	
	--time to call the upper parent
	if self:getUpType() then
		table.insert(parents, getByName(self:getName(), self:getUpYear(), self:getUpType()))
	end

	--[[
		when we call the parents table, we should also call each of them as objects of their owns,
		but, other than normal parent listings on the data, each category has an "upper" category,
		which means for "2010 in art", the upper category is "2010s in art", and for "2010s in art"
		the upper category is "21st century in art", and so on
		
		but to detect the upper category we need to find which decade, century or millennium
		in the year we are currently (current for the page) in for the category
	--]]
	if self._name ~= "" and self._type ~= "byCat" and byCat then
		local name =  mw.ustring.gsub(self._name, "^in%sthe%s", "")
		name =  mw.ustring.gsub(name, "^in%s", "")
		table.insert(parents, getByName(name.." by "..self._type, self._year, self._type))
	end
	
	--export the objects
	return parents or {}
end


function Category:getPortals()
	return self._rawData.portals or {}
end


function Category:getSeeCat()
	local see = self._rawData.see or {}
	local last = {}
	
	if self._type == "byCat" then
		for _,b in ipairs(see) do
			table.insert(last, mw.getContentLanguage():ucfirst(b).." "..self._year)
		end
	else
		for _,b in ipairs(see) do
			table.insert(last, getByName(b, self._year, self._type):getCategoryName())
		end
	end
	
	return last
end


function Category:getDescription()
	if self._rawData.description then
		return mw.getContentLanguage():ucfirst(handleParams(self._rawData.description, self._year, self:getType())) .. "."
	else
		return "This category contains "..mw.getContentLanguage():lcfirst(mw.title.getCurrentTitle().text).."."
	end
end


function Category:getType()
	return self._type
end


function Category:getUpType()
	if self._type == "year" and self._rawData.stage and self._rawData.stage > 1 then
		return "decade"
	elseif self._type == "decade" and self._rawData.stage and self._rawData.stage > 2 then
		return "century"
	elseif self._type == "century" and self._rawData.stage and self._rawData.stage > 3 then
		return "millennium"
	end
end


function Category:getDataModule()
	return self._module
end


function Category:getSortKeys()
	local chain = {}
	local sortKeys = {}
	
	--years and their equivalent sort keys
	local keys = {["year"]="YLAST", ["decade"]="YLASTTWO", ["century"]="FOUR", ["millennium"]="FOUR"}
	
	for _,a in ipairs(self._rawData.sort_keys or {}) do table.insert(chain, a) end
	
	if self:getUpType() then
		table.insert(chain, keys[self._type])
	end
	
	table.insert(chain, "FOUR")

	for _,key in ipairs(chain) do
		if key == "YLAST" then key = mw.ustring.sub( self._year, -1 )
		elseif key == "YLASTTWO" then key = mw.ustring.sub( self._year, -2 )
		elseif key == "FOUR" then key = mw.ustring.find(self._year, "-") and "-"..tostring(9999+tonumber(self._year))
			or (string.len(self._year) == 1 and "000"..self._year
			or (string.len(self._year) == 2 and "00"..self._year
			or (string.len(self._year) == 3 and "0"..self._year
			or (string.len(self._year) == 4 and self._year)))) end
		table.insert(sortKeys, key)
	end

	return sortKeys or {}
end


function Category:toJSON()
	local ret = {
		parents = self:getParents(),
		description = self:getDescription(),
		name = self:getName(),
		year = _year,
		type = _type,
		sort_keys = self:getSortKeys(),
		}
	
	return require("Modül:JSON").toJSON(ret)
end


function Category:getRawData()
	return self._rawData
end


Category.__index = Category


function createObject(name, data, year, type, module)
	return data and
		setmetatable({ _rawData = data, _name = name, _year = year, _type = type, _module = module }
			, Category)or nil
end


function getByName(name, year, _type)
	local data_pages = {
		"data",
		"data/people",
		"data/arts",
	}
	
	local data_module
	
	for _, page in ipairs(data_pages) do
		data_module = "Module:Autocat/" .. page
		if require(data_module)[name] then
			name = type(require(data_module)[name]) == "string" and require(data_module)[name] or name
			break
		elseif require(data_module)["in the "..name] then
			name = "in the "..name
			break
		elseif require(data_module)["in "..name] then
			name = "in "..name
			break
		end
	end
	
	local data = mw.loadData(data_module)
	
	if not data[name] then
		data = {[name] = {}}
		if name == "" then
			local sp = {["century"]="centuries", ["millennium"]="millennia"}
			data[""] = {
				parents = {(sp[_type] or _type).."s"},
				sort_keys = {"FOUR"},
				stage = 4,
			}
		end
	end
	
	if mw.ustring.find(name, "%sby%s") then _type = "byCat" end

	return createObject(name, data[name], year, _type, data_module)
end

---*---*---*---*---*---*---*---*---*---*---*---*---
-- REFLECTING FUNCTIONS
---*---*---*---*---*---*---*---*---*---*---*---*---

--find and replace function
local function findandrep(text, one, two)
	return mw.ustring.sub( mw.ustring.gsub(text, one, two), 1, -1 )
end

--find function
local findIn = mw.ustring.find

local function editLink(category)
	--her kategoride "veriyi düzenle" bağlantısını eklemeye yarayan fonksiyon
	return "<div class=\"toccolours hlist plainlinks\" style=\"float: right; margin: 0.5em 0 0.5em 1em; font-weight: bold;\">[" ..
		mw.getCurrentFrame():callParserFunction{name = "fullurl", args = {category, action = "edit"}} ..
		" Edit category data]</div>"
end

--function to find the decade for a year
--for example if the year 2019, the result would be 2010
--and for 1888, the result is 1880
function getDecade(year)
	local dash = findIn(year, "^-") and "-" or nil
	local decade = findandrep(year, "^-", "")
	local result = string.len(decade) == 1 and "0" or mw.ustring.sub(decade, 1, -2) .. 0
	return (dash and dash or "") .. result
end

function getCentury(year)
	local dash = findIn(year, "^-") and "-" or nil
	local century = findandrep(year, "^-", "")
	local result = (string.len(century) == 1 or string.len(century) == 2) and 1 or tonumber(mw.ustring.sub(century, 1, -3)+1)
	return (dash and dash or "") .. tostring(result)
end

function getMillennium(year)
	local dash = findIn(year, "^-") and "-" or nil
	local mill = findandrep(year, "^-", "")
	local first = mw.ustring.sub(mill, 1, 1)
	local last = mw.ustring.sub(mill, -1)
	
	local result = (string.len(mill) ~= 1 and last ~= "0") and tonumber(first)+1 or tonumber(last)
	result = string.len(mill) == 1 and 1 or result
	
	return (dash and dash or "") .. tostring(result)
end

function yearPlus(year, number)
	local result = tonumber(year) + number
	return tostring(result)
end

function fixBC(year)
	local BC = findIn(year, "^%-") and true or nil
	local result = findandrep(year, ".*%-(%d)", "%1")
	local function check(y,v) return findIn(y, "%s"..v) and " "..v or (findIn(y, "%-"..v) and "-"..v) end
	local suffix = check(year,"century") or check(year,"millennium")
	result = findandrep(result, "[%s%-].*", "") .. (suffix or "")
	return BC and result.." BC" or year
end

function handleParams(name, year, _type)
	local result = name
	local century = _type == "century" and year or (tonumber(year) and getCentury(year) or year)
	local mill = _type == "millennium" and year or (tonumber(year) and getMillennium(getCentury(year)) or year)
	
	local lYear = _type == "year" and year
		or (_type == "decade" and year.."s")
		or (_type == "century" and suffixToYear(year) .. "-century")
		or (_type == "millennium" and suffixToYear(year) .. "-millennium")
		or year
	
	_type = (_type == "byCat" or _type == "century" or _type == "millennium") and "" or _type
	
	result = findandrep(result, "{{{year}}}", lYear)
	result = findandrep(result, "{{{type}}}", _type)
	
	--hidden items for by categories
	if _type == "byCat" and findIn(result, '%{%{%{hiden%|([^%}%}%}]+)') then
		result = findandrep(result, '%{%{%{hide%|([^%}%}%}]+)', '')
	end
	
	result = findandrep(result, '%{%{%{hide%|', '')
	result = findandrep(result, '%}%}%}', '')

	return fixBC(result)
end

--header bar for the next and the previous 5 stages
function headerBar(category)
	--we will collect all the data inside this table
	local result = {}
	
	--[[
		:getName() value, is the part after the numbers in a
		category name, so for "2010s works", this value
		would be "works"
	--]]
	local suffix = category:getName()
	
	--getting the year for the category
	local year = category:getYear()

	local function repeatF(y, _type, name)
		local function ifExists(page)
			return mw.title.new('Category:' .. page).exists
		end
		--we need to call 5 down-level and 5 upper-level categories
		for i = -5, 5 do
			--this will give us the next year value
			--each time the loop starts
			local nextYear = yearPlus(y, i)
			if _type == "year" or _type == "century" or _type == "millennium" then
				last = getByName(name, nextYear, _type)
			elseif _type == "decade" then 
				nextYear = yearPlus(getDecade(y), i..0)
				last = getByName(name, nextYear, "decade")
			end
			--let us check the pages
			
			--special case for 0s BC
			if _type == "decade" and last:getBarName() == "0s" then
				if ifExists(findandrep(last:getCategoryName(), "0s", "0s BC")) then
					table.insert(result, '\n*[[:Category:' .. findandrep(last:getCategoryName(), "0s", "0s BC") .. "|" .. last:getBarName() .. " BC]]")
				else
					table.insert(result, '\n*<span style="color:#888">' .. last:getBarName() .. " BC</span>")
				end
			end
			
			--if category exists
			if ifExists(last:getCategoryName()) then
				table.insert(result, '\n*[[:Category:' .. last:getCategoryName() .. "|" .. last:getBarName() .. "]]")
			else
				--and if not
				table.insert(result, '\n*<span style="color:#888">' .. last:getBarName() .. "</span>")
			end
		end
	end
	
	local function checkParent(category, result, _type)
		if category:getUpType() and category:getUpType() == _type then
			table.insert(result, '\n|}')
			table.insert(result, '\n{| class="toccolours hlist" style="text-align: center; margin: auto; border: none; background: transparent;"'
				.. '\n|')
		end
	end
	
	--start of the main header bar
	table.insert(result, '<div style="padding-bottom: 10px;">\n{| class="toccolours hlist" style="text-align: center; margin: auto;"'
		.. '\n|')
	
	--check for the years
	if category:getType() == "year" then
		repeatF(year, "year", suffix)
	end
	
	--[[
		if we are in a decade categıry, the getCentury() function
	    would find the right century for that decade
	    
	    but if we are already in a century or in a millennium category
	    no need to run these functions, otherwise the results will be wrong
	--]]
	if category:getType() == "century" then
		function getCentury(year) return year end
	elseif category:getType() == "millennium" then
		function getMillennium(year) return year end
	end
	
	--DECADE
	checkParent(category, result, "decade")
	if (category:getUpType() and category:getUpType() == "decade") or category:getType() == "decade" then
		repeatF(year, "decade", suffix)
	end
	
	--CENTURY
	checkParent(category, result, "century")
	if (category:getUpType() and category:getUpType() == "century") or category:getType() == "century" then
		repeatF(getCentury(year), "century", suffix)
	end
	
	--MILLENNIUM
	checkParent(category, result, "millennium")
	if (category:getUpType() and category:getUpType() == "millennium") or category:getType() == "millennium" then
		repeatF(getMillennium(year), "millennium", suffix)
	end
	
	--the end of the header bar
	table.insert(result, '\n|}\n</div>')
	
	--export all data
	return table.concat(result)
end

--this function handles the year suffixes
--for example: if it gets the number "1",
--it exports the result "1st", "2nd" for "2" and "3rd" for "3" etc...
function suffixToYear(year)
	--detect the last digit
	local lastDigit = mw.ustring.sub( tostring(year), -1 )
	
	--special cases for 1, 2, 3
	local specials = {"st", "nd", "rd"}
	
	--if the last digit is 1, 2, or 3 get the special case or the default
	local suffix = specials[tonumber(lastDigit)] and specials[tonumber(lastDigit)] or "th"
	
	return tostring(year) .. suffix
end

--[[
	this function is the core to this module,
	it takes the page name automatically,
	and detects if the page is a year, decade, century, or a millennium category
	also, it splits the title into parts, so that we know
	which category objects to call
	
	for example, "2017 web series debuts";
	
	it is a year category
	and the year is: 2017
	category prefix is: web series debuts
	
	NOTE: the result type is always a table containing these data
--]]
function splitTitle(name)
	--start the year parameter
	local year = ""
	local _type
	
	--is this a BC category?
	if findIn(name, "%sBC") then
		name = findandrep( name, "%sBC", "" )
		BC = true
	end
	
	--if the category name has numbers as prefix
	--this means we can easily detach the numbers
	--from the beginning
	while findIn(name, "^[%d]") do
		year = year .. mw.ustring.sub(name, 1, 1)
		name = findandrep(name, "^[%d]", "")
		--do we have a valid year now?
		doWeHaveYear = true
	end
	
	--for century or millennium categories
	--there could be "st, nd, rd, or th" letters
	--after the number
	name = findandrep(name, "^st", "")
	name = findandrep(name, "^nd", "")
	name = findandrep(name, "^rd", "")
	name = findandrep(name, "^th", "")
	
	--if we have a valid year
	if doWeHaveYear then
		--now it is time to detect the category type
		--year, decade, century or millennium
		if findIn(name, "^s") then
			name = findandrep(name, "^s", "")
			_type = "decade"
		elseif findIn(name, "[%-%s]century") then
			name = findandrep(name, "[%-%s]century", "")
			_type = "century"
		elseif findIn(name, "[%-%s]millennium") then
			name = findandrep(name, "[%-%s]millennium", "")
			_type = "millennium"
		else
			_type = "year"
		end
		name = findandrep(name, "^%s", "")
		--the result table
		return {(BC and "-" or "") .. year, name, _type}
	else
		return {nil, name}
	end
end

function _main(frame)
	local category = getByName("births", "2000", "year")
	
	return fixBC("-1st century")
end

function main(frame)
	--our main parameter or the page name
	local name = frame:getParent().args[1] or mw.title.getCurrentTitle()["text"]
	
	--for all the categories
	local categories = {}
	--for all the display items
	local display = {}
	
	--our year parameter
	local year = splitTitle(name)[1]
	--the category object for the page
	local category = getByName(splitTitle(name)[2], year, splitTitle(name)[3])
	--parents table
	local parents = category:getParents()
	
	table.insert(display, headerBar(category))
	table.insert(display, editLink(category:getDataModule()))

	if category:getWikidata() and category:getWikidata().claims and category:getWikidata().claims["P373"] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Commons category",
			args = {category:getWikidata():formatPropertyValues("P373").value}})
	end
	
	if mw.title.new(name).exists then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Main",
			args = {name}})
	end
	
	if category:getPortals()[1] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Portal",
			args = {category:getPortals()[1], category:getPortals()[2], category:getPortals()[3], category:getPortals()[4]}})
	end
	
	if category:getSeeCat()[1] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Category see also",
			args = {category:getSeeCat()[1], category:getSeeCat()[2], category:getSeeCat()[3], category:getSeeCat()[4]}})
	end
	
	if category:getDescription() then
		table.insert(display, category:getDescription())
	end
	
	--CatAutoTOC
	table.insert(display, mw.getCurrentFrame():expandTemplate{title = "CatAutoTOC",args = {}})
	
	--insert the category to each parent categories
	for key,parent in ipairs(parents) do
		table.insert(categories, "[[Category:" .. parent:getCategoryName() .. "|" .. category:getSortKeys()[key] .. "]]")
	end
	
	--is this category empty?
	if mw.site.stats.pagesInCategory(mw.title.getCurrentTitle().text, "all") == 0 then
		table.insert(categories, "[[Category:Empty categories]]")
	end
	
	return table.concat(display) .. table.concat(categories)
end

function byCat(frame)
	local args = frame:getParent().args
	
	local categories = {}
	local display = {}
	
	local year = args[1]
	local _type = args[2]
	local category = getByName(_type, "by "..year, "byCat")
	
	local by = type(category:byCat()) == "table" and category:byCat()[1] or category:byCat()

	if by and by ~= "no" and by ~= "up" then
		yukari = type(category:byCat()) == "table" and category:byCat()[2] or category:byCat()
	end
	
	local function catExists(cat) if mw.title.new('Category:'..cat).exists then return cat end end
	local perDateTime = catExists(_type..' by date') or catExists(_type..' by time') or catExists(_type..' by period')
	if category:stage() and category:stage() > 1 and by ~= "up" then
		if perDateTime then
			table.insert(display, '\n<div style="text-align:center;">'
				..'[[:Category:' .. perDateTime .. "|"..perDateTime.."]]</div>")
		end
		
		table.insert(display, '<div style="padding-bottom: 10px;">'
		.. '\n{| class="toccolours hlist" style="text-align: center; margin: auto;"'
		.. '\n|')
		
		if catExists(_type..' by year') then
			table.insert(display, "\n*[[:Category:" .. _type.." by year|by year]]")
		end
		if catExists(_type..' by decade') then
			table.insert(display, "\n*[[:Category:" .. _type.." by decade|by decade]]")
		end
		if catExists(_type..' by century') then
			table.insert(display, "\n*[[:Category:" .. _type.." by century|by century]]")
		end
		if catExists(_type..' by millennium') then
			table.insert(display, "\n*[[:Category:" .. _type.." by millennium|by millennium]]")
		end
		
		table.insert(display, '\n|}\n</div>')
	end

	table.insert(display, editLink(category:getDataModule()))
	
	if category:getWikidata() and category:getWikidata().claims and category:getWikidata().claims["P373"] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Commons category",
			args = {category:getWikidata():formatPropertyValues("P373").value}})
	end
	
	if category:getPortals()[1] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Portal",
			args = {category:getPortals()[1], category:getPortals()[2], category:getPortals()[3], category:getPortals()[4]}})
	end
	
	if category:getSeeCat()[1] then
		table.insert(display, mw.getCurrentFrame():expandTemplate{
			title = "Category see also",
			args = {category:getSeeCat()[1], category:getSeeCat()[2], category:getSeeCat()[3], category:getSeeCat()[4]}})
	end
	
	if category:getDescription() then
		table.insert(display, category:getDescription())
	end
	
	local periodCheck = year == "period" or year == "date" or year == "time"
	if periodCheck and by == "no" then
	elseif by == "up" or periodCheck then
		_type = up or _type
		table.insert(categories, "[[Category:" .. mw.getContentLanguage():ucfirst(_type) .. "|+]]")
	elseif findIn(category:getName(), "and "..year) then else
		if perDateTime then
			table.insert(categories, "[[Category:" .. perDateTime .. "| ]]")
		end
	end
	
	if category:getParents() then
		for k,parent in ipairs(category:getParents()) do
			local e =  mw.ustring.gsub(parent:getName(), "^in%sthe%s", "")
			local e =  mw.ustring.gsub(parent:getName(), "^in%s", "")
			if periodCheck then
				umbrella = catExists(e .. " by date") or catExists(e .. " by time") or e .. " by period"
			else
				umbrella = not findIn(category:getName(), "and "..year)
					and catExists(e .. " by type and " .. year) or e .. " by " .. year
			end
			table.insert(categories, "[[Category:" .. umbrella .. "|"
				.. (mw.site.stats.pagesInCategory(umbrella, "subcats") > 200
				and mw.ustring.char(0x0020) or category:getSortKeys()[k]) .. "]]")
		end
	end
	
	return table.concat(display) .. table.concat(categories)
end

return {main = main, byCat = byCat}