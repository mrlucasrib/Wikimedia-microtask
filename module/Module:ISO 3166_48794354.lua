-- to enable us to replicate the current functioning of Country extract, we need to deal with:
-- 2 {{<name>}} DONE!
-- 3 [[<name>]] DONE!
-- 4 [[<name>|<junk>]] DONE!
-- 5 [[image:flag of <country>.[svg|gif|png|jpg]|\d+px]] DONE!

local p = {}
local getArgs = require("Module:Arguments").getArgs
local data = mw.loadData("Module:ISO 3166/data/National")

--[[----------F I N D N A M E----------]]--										-- Finds the name in the database

local function findname(code,cdata,qry)
	local sqry = p.strip(qry)
	if cdata["name"] and sqry==p.strip(cdata["name"])
		or cdata["isoname"] and sqry==p.strip(cdata["isoname"])
		or not cdata["nocode"] and sqry==code
		or sqry==cdata["alpha3"] or sqry==cdata["numeric"]
		then
		return true
	end
	for _,tname in pairs(cdata["isonames"] or {}) do
		if sqry==p.strip(tname) then
			return true
		end
	end
	for _,tname in pairs(cdata["altnames"] or {}) do
		if sqry==p.strip(tname) then
			return true
		end
	end
	return false
end

--[[----------I S O N A M E----------]]--										-- Find the ISO name of a country/region

local function isoname(data,code,lang)
	if data[code]["isonames"] then
		local name = data[code]["isodisplaynames"] and data[code]["isodisplaynames"][lang]
			 or data[code]["isonames"][lang]
			 or data[code]["isodisplaynames"] and data[code]["isodisplaynames"][data[code]["defaultlang"] or data["defaultlang"]]
			 or data[code]["isonames"][data[code]["defaultlang"] or data["defaultlang"]]
			 or data[code]["isodisplaynames"] and data[code]["isodisplaynames"]["en"]
			 or data[code]["isonames"]["en"]
		if name then return name end
		for _,iname in pairs(data[code]["isonames"]) do return iname end
		return data[code]["isodisplayname"] or data[code]["isoname"]
	else
		return data[code]["isodisplayname"] or data[code]["isoname"]
	end
end

--[[----------S T R I P----------]]--											-- Removes junk from the input

function p.strip(text)
	local accents = {["À"]="A",["Á"]="A",["Â"]="A",["Ã"]="A",					-- accent list
		["Ä"]="A",["Å"]="A",["Ç"]="C",["È"]="E",["É"]="E",
		["Ê"]="E",["Ë"]="E",["Ì"]="I",["Í"]="I",["Î"]="I",
		["Ï"]="I",["Ñ"]="N",["Ò"]="O",["Ó"]="O",["Ô"]="O",
		["Õ"]="O",["Ö"]="O",["Ø"]="O",["Ù"]="U",["Ú"]="U",
		["Û"]="U",["Ü"]="U",["Ý"]="Y"
	}
	local remove = {"NATION OF","COUNTRY OF","TERRITORY OF",					-- text to be removed list
		"FLAG OF","FLAG","KINGDOM OF","STATE OF"," STATE ",
		"PROVINCE OF","PROVINCE","TERRITORY"
	}
	local patterns = {[".+:"]="",["|.+"]="",["%(.-%)"]="",						-- patterns to follow (order may matter)
		["%..*"]="",["^THE "]="",["%_"]=" ",["%-"]=" ",
		["%d%d?%d?PX"]="",
	}
	
	text = mw.ustring.upper(text)												-- Case insensitivity
	text = mw.ustring.gsub(text,"[À-Ý]",accents)								-- Deaccent
	
	for pattern,value in pairs(patterns) do										-- Follow patterns
	text = mw.ustring.gsub(text,pattern,value) 
	end
	
	for _,words in pairs(remove) do												-- Remove unneeded words
	text = mw.ustring.gsub(text,words,"") 
	end
	
	text = mw.ustring.gsub(text,"%W","")										-- Remove non alpha-numeric
	
	return text
	
end

--[[----------P . C A L L S T R I P ---------]]--								-- Calls P.strip but using Module:Arguments

function p.callstrip(frame)
	
	local args = getArgs(frame)
	
	return p.strip(args[1]) or ""

end

--[[----------P . L U A C O D E---------]]--									-- Makes the ISO code of a country

function p.luacode(args)

	if string.find(args[1] or '',"%-") then
		args[1], args[2] = string.match(args[1] or '',"^([^%-]*)%-(.*)$")
	end
	
	if args[1] then args[1] = p.strip(args[1]) end
	if args[2] then args[2] = p.strip(args[2]) end
	
	if args["codetype"]=="3" then
		args["codetype"]="alpha3"
	end
	
	local eot = args.error or ""
	
	local catnocountry = (args.nocat and args.nocat == 'true') and '' 
		or '[[Category:Wikipedia page with obscure country]]'
	local catnosubdivision = (args.nocat and args.nocat == 'true') and '' 
		or '[[Category:Wikipedia page with obscure subdivision]]'
	
	if not args[1] then
		if mw.title.getCurrentTitle().namespace ~= 0 then catnocountry = '' end
		return catnocountry, '<span style="font-size:100%" class="error">"No parameter for the country given"</span>'
	end
	
	if not args[2] then															--3166-1 code
		for alpha2,cdata in pairs(data) do
			if findname(alpha2,cdata,args[1]) then
				if args["codetype"]=="numeric" or args["codetype"]=="alpha3" then
					return cdata[args["codetype"]]
				else
					return alpha2
				end
			end
		end
		if mw.title.getCurrentTitle().namespace ~= 0 then catnocountry = '' end
		return catnocountry
	else																		--3166-2 code
		for alpha2,cdata in pairs(data) do                                       
			if findname(alpha2,cdata,args[1]) then
				if mw.ustring.match(alpha2,"GB") then							-- For England, Wales etc.
					alpha2 = "GB"
				end
				local sdata = mw.loadData("Module:ISO 3166/data/"..alpha2)
				local empty = true
				for scode,scdata in pairs(sdata) do
					if type(scdata)=="table" then
						empty = false
						if findname(scode,scdata,args[2]) then
							return alpha2.."-"..scode
						end
					end
				end
				if mw.title.getCurrentTitle().namespace ~= 0 then catnosubdivision = '' end
				return catnosubdivision
			end
		end
		if mw.title.getCurrentTitle().namespace ~= 0 then catnocountry = '' end
		return catnocountry
	end

end

--[[----------P . C O D E---------]]--											-- Calls P.Luacode but using Module:Arguments

function p.code(frame)

	return p.luacode(getArgs(frame)) or ""

end

--[[----------P . N U M E R I C---------]]--									-- Calls P.Luacode but using Module:Arguments and setting it to output a numeric value

function p.numeric(frame)

	local args = getArgs(frame)
	
	args["codetype"]="numeric"
	
	return p.luacode(args) or ""
	
end
	
--[[----------P . L U A N A M E---------]]--									-- Makes the ISO/common name of a country
	
function p.luaname(args)

	local code1 = p.luacode(args)
	local code2 = ''
	
	if string.find(code1,"%-") then
		code1, code2 = string.match(code1,"^([^%-]*)%-(.*)$")
	end
	
	if string.find(code1,"^%u%u$") then
		if code2=="" then														--3166-1 alpha-2 code
			if data[code1] then
				return (args.isoname or args.lang) and isoname(data,code1,args.lang)
					or (data[code1]["displayname"] or data[code1]["name"])
			else
				return '[[Category:Wikipedia page with obscure country]]'
			end
		else																	--3166-2 code
			local sdata
			if data[code1] then
				sdata = mw.loadData("Module:ISO 3166/data/"..code1)
			else
				return '[[Category:Wikipedia page with obscure country]]'
			end
			if sdata[code2] then
				return (args.isoname or args.lang) and isoname(sdata,code2,args.lang)
					or (sdata[code2]["displayname"] or sdata[code2]["name"])
			else
				return '[[Category:Wikipedia page with obscure country]]'
			end
		end
	end
	
end

--[[----------P . N A M E---------]]--											-- Calls P.Luaname but using Module:Arguments

function p.name(frame)

	return p.luaname(getArgs(frame)) or ""

end
	
--[[----------P . G E O C O O R D I N S E R T---------]]--						-- Wrapper for Module:Coordinates.coordinsert
function p.geocoordinsert(frame)
	-- {{#invoke:ISO 3166|geocoordinsert|{{coord|...}}
	-- |country=..|subdivision1=...|subdivision2=...
	-- |type=...|scale=...|dim=...|source=...|globe=...
	-- }}
	local args = frame.args
	local subdivisionqueried = false
	local catnocountry = (args.nocat and args.nocat == 'true') and '' 
		or '[[Category:Wikipedia page with obscure country]]'
	local catnosubdivision = (args.nocat and args.nocat == 'true') and ''
		or '[[Category:Wikipedia page with obscure subdivision]]' or ''
	local tracking = ''
	local targs = {}
	targs[1] = args[1] or ''
	for i, v in pairs(args) do
		if i == 'country' and not mw.ustring.find(targs[1], 'region:') then
			local country = v
			local k, region = 1, ''
			-- look for a valid subdivision
			while region == '' and k < 3 do
				local subdivision = args['subdivision' .. k] or ''
				if subdivision ~= '' then
					region = p.luacode({country, subdivision, nocat = 'true'})
					subdivisionqueried = true
				end
				k = k + 1
			end
			-- subdivision lookup failed or never attempted, try country only
			if region == '' then
				region = p.luacode({country, nocat = 'true'})
				if mw.title.getCurrentTitle().namespace ~= 0 then catnocountry, catnosubdivision = '', '' end
				if region == '' then
					tracking = tracking .. catnocountry
				elseif subdivisionqueried == true then
					tracking = tracking .. catnosubdivision
				end
			end
			-- something worked, add it to the targs
			if region ~= '' then
				targs[#targs + 1] = 'region:' .. region
			end
		elseif i == 'type' or i == 'scale' or i == 'dim' 
				or i == 'source' or i == 'globe' then
			targs[#targs + 1] = i .. ':' .. v
		end
	end
	-- call Module:Coordinates.coordinsert if there is something to insert
	if #targs > 1 then
		local coordinsert = require('Module:Coordinates').coordinsert
		return coordinsert({args = targs}) .. tracking
	end
	-- otherwise, just return the coordinates
	return targs[1] .. tracking
end

return p