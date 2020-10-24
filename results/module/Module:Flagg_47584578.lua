local p = {}

function p.main(frame)

	--Get input arguments
	local args = require('Module:Arguments').getArgs(frame,{valueFunc =
		function(key,value)
			if value then
				value = mw.text.trim(value)
				--Change empty string to nil for all args except 'image' and 'border'
				if key=="image" or key=="border" or value~="" then
					return value
				end
			end
			return nil
		end
	})

	--Call main function
	return p.luaMain(frame,args)

end

function p.luaMain(frame,args)

	local function emp2nil(x)
		if x=="" then return nil else return x end
	end
	local function space2emp(x)
		if string.find(x,"^%s*$") then return "" else return x end
	end
	local function nopx(x)
		if x~=nil and (string.find(x,"^%d+$") or string.find(x,"^%d+px$")) then return string.gsub(x,"^(.*)px","%1") else return nil end
	end

	--Country & mode parameters
	local mode = string.lower(args[1] or "usc")
	local mi = string.sub(mode,1,1)
	local ms = string.sub(mode,2,2)
	local mn = string.sub(mode,3,3)
	local me = string.sub(mode,4,-1)

	local country = args[2] or ""
	local avar = args["avar"] or args["altvar"]
	local clink = args["clink"] or args["link"]

	--Get country data & altvar data
	local data, alink, amap, asuf
	if avar then
		local age = args["age"] or ""
		local aalias
		amap, aalias = require("Module:Flagg/Altvar data").alttable(age)
		avar = string.gsub(string.lower(avar or ""),"[ \-]","")
		avar = aalias[avar] or avar
		if not amap[avar] then error("Unknown avar") end
		local apar = {altvar=amap[avar].altvar;mw=amap[avar].mw;age=amap[avar].age;variant=args["variant"] or args[3]}
		data = require("Module:CountryData").gettable(frame,country,apar)
		asuf = amap[avar].altlink
		alink = data["link alias-"..amap[avar].altvar] or (clink or data["shortname alias"] or data.alias or country).." "..asuf
	else
		data = (args["nodata"] and {}) or require("Module:CountryData").gettable(frame,country,{variant=args["variant"] or args[3]})
		avar = ""
		amap = {[""]={altvar=""}}
	end

	--Name and link parameters
	clink = clink or data.alias or country

	local pref = args["pref"]
	local suff = args["suff"] or asuf
	if not pref and not suff then --Default prefix
		pref = "Flag of"
	end
	local yn_map = {[""]=0; ["0"]=0; ["no"]=0; ["n"]=0; ["1"]=1; ["yes"]=1; ["y"]=1}
	local fthe = (args["pthe"] and yn_map[args["pthe"]]~=0) or (args["the"] and yn_map[args["the"]]~=0)
	local nthe = (args["nthe"] and yn_map[args["nthe"]]~=0) or (args["the"] and yn_map[args["the"]]~=0)
	fthe = fthe and (pref and "t" or "T").."he " or ""
	nthe = nthe and (pref and "t" or "T").."he " or ""
	local flink = args["plink"] or args["flink"] or alink
	              or clink=="" and "" or space2emp((pref or "").." ")..fthe..clink..space2emp(" "..(suff or ""))
	local fsec = args["psection"] or args["section"]
	local csec = args["csection"] or args["section"]
	fsec = fsec and "#"..fsec or ""
	csec = csec and "#"..csec or ""

	if string.find(me,"f") then
		if mw.title.new( flink ).exists == false then
			flink = clink
		end
	end

	local name = args["name"]
	if not name then
		local cname = string.find(me,"e") and (data["name alias-"..amap[avar].altvar] or data["shortname alias"] or data.alias) or country
		if mn == "f" then
			name = cname=="" and "" or space2emp((pref or "").." ")..nthe..cname..space2emp(" "..(suff or ""))
		else
			name = cname
		end
	end

	--Image parameters
	local pimage = args["image"]
	local placeholder = "Flag placeholder.svg"
	local variant = args["variant"] or args[3] or ""
	local image_map = {[""]=placeholder; ["none"]=placeholder; ["blank"]=placeholder}
	if pimage then --Remove namespace
		pimage = string.gsub(pimage,"^[Ff][Ii][Ll][Ee]:","")
		pimage = string.gsub(pimage,"^[Ii][Mm][Aa][Gg][Ee]:","")
	end
	local iname = image_map[pimage] or pimage

	local size = args["size"] or args["sz"]
	local size_map = {xs="12x8px"; s="17x11px"; m="23x15px"; l="32x21px"; xl="46x30px"}
	if size==nil or string.find(size,"^%d*x?%d+px$") then
		--valid EIS size (..px, x..px or ..x..px) or unset
	elseif string.find(size,"^%d*x?%d+$") then --EIS size without "px" suffix
		size=size.."px"
	else --size from map, or invalid value
		size = size_map[size] or nil
	end
	local border = args["border"]

	if iname then
		size = size or "23x15px"
		if yn_map[border]==0 then border = "" else border = "|border" end
	else
		iname = data["flag alias-"..amap[avar].altvar.."-"..variant] or data["flag alias-"..variant] or data["flag alias-"..amap[avar].altvar] or data["flag alias"] or placeholder
		size = size or emp2nil(data.size) or "23x15px"
		if border then
			if yn_map[border]==0 then border = "" else border = "|border" end
		else
			local autoborder = data["border-"..variant] or data["border-"..amap[avar].altvar] or data.border
			if autoborder and autoborder~="border" then border = "" else border = "|border" end
		end
	end

	local am = ""
	if args["alt"] or string.find(me,"a") then
		am = args["alt"] or args["name"] or country
		am = am.."|"..am
	end

	--Build display name
	local text = args["text"]
	if not text then
		if mn=="x" then --no text
			text = ""
		elseif mn=="p" or mn=="f" then --prefix/suffix link
			text = flink=="" and name or "[["..flink..fsec.."|"..name.."]]"
		elseif mn=="b" then --both prefix/suffix and normal country link
			local preflink = pref and (flink=="" and pref.." " or "[["..flink..fsec.."|"..pref.."]] ") or ""
			local sufflink = suff and (flink=="" and " "..suff or " [["..flink..fsec.."|"..suff.."]]") or ""
			local namelink = (name=="" and "" or nthe)..(clink=="" and name or "[["..clink..csec.."|"..name.."]]")
			text = preflink..namelink..sufflink
		elseif mn=="d" then --data template
			local title = mw.title.new("Template:Country data "..country)
			--check if redirect
			if title.isRedirect then
				text = "<span class=\"plainlinks\">["..title:fullUrl("redirect=no").." "..name.."]</span>"
			else
				text = "[["..title.fullText.."|"..name.."]]"
			end
		elseif mn=="u" then --unlinked
			text = name
		else --country link (default)
			text = clink=="" and name or "[["..clink..csec.."|"..name.."]]"
		end
	end

	--Build image
	local ilink = args["ilink"]
	if not ilink then
		if mi=="x" or (iname==placeholder and pimage~=placeholder) then --no image/invisible image
			iname = placeholder
			border = ""
			ilink = "|link="
			am = ""
		elseif mi=="i" then --image page link
			ilink = ""
		elseif mi=="c" then --country link
			ilink = "|link="..clink..(clink=="" and "" or csec)
		elseif mi=="p" or mi=="f" then --prefix/suffix link
			ilink = "|link="..flink..(flink=="" and "" or fsec)
		elseif mi=="d" then --data template
			local title = mw.title.new("Template:Country data "..country)
			--check if redirect
			if title.isRedirect then
				ilink = "|link="..title:fullUrl("redirect=no")
			else
				ilink = "|link="..title.fullText
			end
		else --unlinked (default)
			ilink = "|link="
		end
	end
	if am == "" and string.find(me,"l") then
		am = mw.ustring.sub(ilink,7,-1)
	end
	local image = "[[File:"..iname.."|"..size..border..ilink.."|alt="..am.."]]"

	if iname==placeholder then
		if require('Module:yesno')(args["noredlink"]) == false then
			iname = ''
			image = "[[:Template:Country data "..country.."]]"
		end
		if (args["missingcategory"] or '') ~= '' then
			image = image..args["missingcategory"]
		end
		if string.find(me,"b") then
			text = ''
		end
	end

	--Combine image and name with separator
	local align = args["align"] or args["al"]
	local nalign = args["nalign"] or args["nal"]
	local align_map = {left="left", l="left", center="center", centre="center", c="center", middle="center", m="center", right="right", r="right"}
	local out
	if string.find(me,"r") then
		--image right of name
		if (ms=="x" and mi=="x") or (string.find(me,"o") and iname==placeholder and pimage~=placeholder) then --name only
			out = text
		elseif ms=="x" then --no separator
			out = text.."<span class=\"flagicon\">"..image.."</span>"
		elseif ms=="n" then --non-breaking space
			out = text.."<span class=\"flagicon\">&nbsp;"..image.."</span>"
		elseif ms=="l" then --line break
			out = text.."<span class=\"flagicon\"><br/>"..image.."</span>"
		elseif ms=="t" then --table cell
			out = "style=\"text-align:"..(align_map[nalign] or "left").."\"|"..text.."||style=\"text-align:"..(align_map[align] or "center")..";\"|<span class=\"flagicon\">"..image.."</span>"
		else --fixed-width span box (default)
			local width = args["width"] or args["w"] or require("Module:Flaglist").luawidth(size)
			out = text.."&nbsp;<span class=\"flagicon\" style=\"display:inline-block;width:"..width.."px;text-align:"..(align_map[align] or "right")..";\">"..image.."</span>"
		end
	else --image left of name
		if (ms=="x" and mi=="x") or (string.find(me,"o") and iname==placeholder and pimage~=placeholder) then --name only
			out = text
		elseif ms=="x" then --no separator
			out = "<span class=\"flagicon\">"..image.."</span>"..text
		elseif ms=="n" then --non-breaking space
			out = "<span class=\"flagicon\">"..image.."&nbsp;</span>"..text
		elseif ms=="l" then --line break
			out = "<span class=\"flagicon\">"..image.."<br/></span>"..text
		elseif ms=="t" then --table cell
			out = "style=\"text-align:"..(align_map[align] or "center")..";\"|<span class=\"flagicon\">"..image.."</span>||style=\"text-align:"..(align_map[nalign] or "left").."\"|"..text
		else --fixed-width span box (default)
			local width = nopx(args["width"] or args["w"]) or require("Module:Flaglist").luawidth(size)
			out = "<span class=\"flagicon\" style=\"display:inline-block;width:"..width.."px;text-align:"..(align_map[align] or "left")..";\">"..image.."</span>&nbsp;"..text
		end
	end
	if string.find(me,"w") then --avoid wrapping
		out = "<span class=\"nowrap\">"..out.."</span>"
	end

	--Tracking categories
	local cat = ""
	if pimage and not image_map[pimage] and country~="" and data["flag alias"] and not args.demo then
		cat = "[[Category:Pages using Flagg with specified image instead of data template image]]"
	end

	return out..cat

end

return p