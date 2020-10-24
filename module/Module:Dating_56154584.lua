local p = {}
	function p.Dates (frame)
		local input = mw.text.trim(frame.args[1]) or 0
		if input ~= 0 then
			input = " " .. input .. " "
		end
		local xformat = frame.args.format or 0
		local xsuffix = frame.args.suffix or 0
		local sSuffix = 0
		local valid
		if input ~= 0 then valid = 1 else valid = 0 end
		local mnths = {}
		local yrs = {}
		local dts = {}
		local i = 1 
		local j = 1
		local k = 1
		local valid = 1
		local ly = 0
		local txt = ""
		local nums = {}
		local m = 1
		local Months = {
						"January",
						"February",
						"March",
						"April",
						"May",
						"June",
						"July",
						"August",
						"September",
						"October",
						"November",
						"December"
			           }
		for data in string.gmatch (input, "%w+") do
			data = " " .. data .. " "
			if data:find ("%s%d%a%a%s") then
				if tonumber(string.sub(data, 2, 2)) < 32 then
					dts[i] = tonumber(string.sub(data, 2, 2))
					i = i + 1
				end
			end
			if data:find ("%s%d%d%a%a%s") then
				if tonumber(string.sub(data, 2, 3)) < 32 then
					dts[i] = tonumber(string.sub(data, 2, 3))
					i = i + 1
				end
			end
		end
		if input:find ("%s%d%d%d%d%s") then
			yrs[k] = tonumber(string.sub(input, input:find ("%s%d%d%d%d%s")+1,  input:find ("%s%d%d%d%d%s")+4))
			k = k + 1
		end
		for l = 1, 12 do
			if input:find(string.sub(Months[l], 1, 3)) or input:find(string.lower(string.sub(Months[l], 1, 3))) then
				mnths[j] = l
				j = j + 1
			end
		end
		for data in string.gmatch (input, "%d+") do
			data = tonumber(data)
			if data > 31 then
				yrs[k] = data
				k = k + 1
			else
				if data > 12 then
					if #dts == 0 then
						dts[i] = data
						i = i + 1
					else
						nums[m] = data
						m = m + 1
					end
				else
					nums[m] = data
					m = m + 1
				end
			end
		end
		for l = 1, 3 do
			if nums[l] then
				if #dts == 0 then
					dts [i] = nums[l] 
					i = i + 1
				else 
					if #mnths == 0 then
						mnths [j] = nums[l]
						j = j + 1
					else
						if #yrs == 0 then
							yrs[k] = nums[l]
							k = k + 1
						end
					end
				end
			end
		end
		local date = dts[1] or 0
		local month = mnths[1] or 0
		local year = yrs[1] or 0
		if xformat == 0 then 
			if input:find ("/") or input:find ("-") then
				xformat = "iso"
			else
				if input:find (", ") then
					xformat = "mdy"
				else
					xformat = "dmy"
				end
			end
		end
		if date ~= 0 and year ~= 0 and month == 0 then
				xformat = "year"
		end
		if date == 0 and year ~= 0 and month == 0 then
				xformat = "year"
		end
		if input:find ("uncertain") or input:find("around") or input:find("sometime") then
			if input:find ("uncertain who") then
				sSuffix = 2
			else
				sSuffix = 1
			end
		end
		if xsuffix == 0 then 
			if input:find ("year") and input:find ("lord") then	xsuffix = "AD" 	end
			if input:find ("AD") then xsuffix = "AD" end
			if input:find ("BC") then xsuffix = "BC" end
			if input:find ("CE") then xsuffix = "CE" end
			if input:find ("BCE") then xsuffix = "BCE" end
		end
		if xsuffix ~= 0 then
			if year == 0 then
				if date ~= 0 and month ~= 0 then else
					if date ~= 0 then 
						year = date
						xformat = "year"
						date = 0
					end
					if month ~= 0 then
						year = month
						xforamt = "year"
						month = 0
					end
				end
			end
		end
		if date ~= 0 and year == 0 and month == 0 then valid = 0 end
		if month == 4 or month == 6 or month == 9 or month == 11 then 
			if date > 30 then
				valid = 0
			end
		end
		if year % 100 ~= 0 and year % 4 == 0 then
			ly = 1
		else
			if year % 400 == 0 then
				ly = 1
			end
		end
		if month == 2 then
			if ly == 1 then
				if date > 29 then
					valid = 0
				end
			else
				if date > 28 then
					valid = 0 
				end
			end
		end
		if date == 0 and month == 0 and year == 0 then valid = 0 end
		if year == 0 then
			for l = 1, 12 do
				if input:find(string.sub(Months[l], 1, 3)) or input:find(string.lower(string.sub(Months[l], 1, 3))) then
					valid = 1
					break
				else
					valid = 0
				end
			end
		end
		if valid == 0 then txt = "Invalid entry. "
		else
			if xformat == "iso" then
				if year ~= 0 then 
					txt = txt .. year
				end
				if month ~= 0 then
					if month > 10 then
						txt = txt .. "-" .. month
					else
						month = "0" .. month
						txt = txt .. "-" .. month
					end
				end
				if date ~= 0 then
					if date > 10 then
						txt = txt .. "-" .. date
					else
						date = "0" .. date
						txt = txt .. "-" .. date
					end
				end
			end
			if xformat == "dmy" then
				if date ~= 0 then
					txt = txt .. date
				end
				if month ~= 0 then
					txt = txt .. " " .. Months[month]
				end
				if year ~= 0 then 
					txt = txt .. " " .. year
				end
			end
			if xformat == "mdy" then
				if month ~= 0 then
					txt = txt .. Months[month]
				end
				if date ~= 0 then
					txt = txt .. " " .. date  
				end
				if year ~= 0 then 
					txt = txt .. ", " .. year
				end
			end
			if xformat == "year" then 
				if year ~= 0 then
					txt = txt .. year
				end
			end
			if xsuffix ~= 0 then
				txt = txt .. " " .. xsuffix
			end
			if sSuffix ~= 0 then
				if sSuffix == 1 then
					txt = "c. " .. txt
				end
				if sSuffix == 2 then
					txt = txt .. " (uncertain who was present)"
				end
			end
		end
		return txt .. " "
	end
return p