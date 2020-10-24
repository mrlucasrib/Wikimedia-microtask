local p = {};

local monthName = function(I1)
	if(I1 == 1) then return 'January' end
	if(I1 == 2) then return 'February' end
	if(I1 == 3) then return 'March' end
	if(I1 == 4) then return 'April' end
	if(I1 == 5) then return 'May' end
	if(I1 == 6) then return 'June' end
	if(I1 == 7) then return 'July' end
	if(I1 == 8) then return 'August' end
	if(I1 == 9) then return 'September' end
	if(I1 == 10) then return 'October' end
	if(I1 == 11) then return 'November' end
	if(I1 == 12) then return 'December' end
	if(I1 == 0) then return 0 end
	end
	
local monthNum = function(I1)
	if(I1 == 'January') then return 1 end
	if(I1 == 'February') then return 2 end
	if(I1 == 'March') then return 3 end
	if(I1 == 'April') then return 4 end
	if(I1 == 'May') then return 5 end
	if(I1 == 'June') then return 6 end
	if(I1 == 'July') then return 7 end
	if(I1 == 'August') then return 8 end
	if(I1 == 'September') then return 9 end
	if(I1 == 'October') then return 10 end
	if(I1 == 'November') then return 11 end
	if(I1 == 'December') then return 12 end
	return I1
	end

local expand = function(frame,page,template,one,two,three)
	local result = (frame:expandTemplate{title='Template parameter value',args={page,template,one,two,three}})
	return result
end

local getDateDFull = function(frame,value,i)

	if(value ~= 'none none none none') then
		local number = (expand(frame,value,"Infobox television",1,"num_episodes",1)+i)
		value = expand(frame,value,"Episode list",number,"OriginalAirDate",1)
	end

	value = string.gsub(value, ",", "")
	
	local t = {}
	
	for substring in value:gmatch("%w+") do
		table.insert(t,substring)
	end
	
	return t
end

local getDateDPart = function(num,t)
	local value
	if(num==1) then
		value = tonumber(monthNum(t[5]))
		if(value == nil) then value = 0 end
	end
	if(num==2) then
		value = tonumber(monthNum(t[1]))
		if(value == nil) then value = 0 end
	end
	if(num==3) then
		value = tonumber(monthNum(t[3]))
		if(value == nil) then value = 0 end
	end
	return value
end

local getDateL = function(frame,num,L,T)
	local value
	value = tonumber(expand(frame,L,T,1,num,1))
	if(value == nil) then value = 0 end
	return value
end

local getS = function(frame,S,T1,T2)
	local value = tonumber(expand(frame,S,T1,1,T2,1))
	if(value == nil) then value = 0 end	
	return value
end

local getD = function(S)
	local value = S
	if(value == nil) then value = "none none none none" end
	value = tostring(value)
	return value
end

p.main = function( frame )
	
	local D1I = mw.getCurrentFrame():getParent().args.S1I or frame.args.S1I or 0
	local D2I = mw.getCurrentFrame():getParent().args.S2I or frame.args.S2I or 0
	local D3I = mw.getCurrentFrame():getParent().args.S3I or frame.args.S3I or 0
	local D4I = mw.getCurrentFrame():getParent().args.S4I or frame.args.S4I or 0
	local D5I = mw.getCurrentFrame():getParent().args.S5I or frame.args.S5I or 0
	
	local L1 = mw.getCurrentFrame():getParent().args.L1 or frame.args.L1
	local L2 = mw.getCurrentFrame():getParent().args.L2 or frame.args.L2
	local L3 = mw.getCurrentFrame():getParent().args.L3 or frame.args.L3
	local L4 = mw.getCurrentFrame():getParent().args.L4 or frame.args.L4
	local L5 = mw.getCurrentFrame():getParent().args.L5 or frame.args.L5
	local T1 = 'Aired episodes'
	local T2 = 'Infobox television'
	local T3 = 'num_episodes'
	local S1 = mw.getCurrentFrame():getParent().args.S1 or frame.args.S1
	local S2 = mw.getCurrentFrame():getParent().args.S2 or frame.args.S2
	local S3 = mw.getCurrentFrame():getParent().args.S3 or frame.args.S3
	local S4 = mw.getCurrentFrame():getParent().args.S4 or frame.args.S4
	local S5 = mw.getCurrentFrame():getParent().args.S5 or frame.args.S5
	local S6 = mw.getCurrentFrame():getParent().args.S6 or frame.args.S6
	local S7 = mw.getCurrentFrame():getParent().args.S7 or frame.args.S7
	local S8 = mw.getCurrentFrame():getParent().args.S8 or frame.args.S8
	local S9 = mw.getCurrentFrame():getParent().args.S9 or frame.args.S9
	local S10 = mw.getCurrentFrame():getParent().args.S10 or frame.args.S10
	local name = mw.getCurrentFrame():getParent().args.name  or frame.args.name
	name = tostring(name)
	if(name == 'nil') then name = "name" end
	local Date = mw.getCurrentFrame():getParent().args.Date or frame.args.Date
	local sum = mw.getCurrentFrame():getParent().args.sum or frame.args.sum

	local L1_1 = getDateL(frame,1,L1,T1)
	local L1_2 = getDateL(frame,2,L1,T1)
	local L1_3 = getDateL(frame,3,L1,T1)
	
	local L2_1 = getDateL(frame,1,L2,T1)
	local L2_2 = getDateL(frame,2,L2,T1)
	local L2_3 = getDateL(frame,3,L2,T1)
	
	local L3_1 = getDateL(frame,1,L3,T1)
	local L3_2 = getDateL(frame,2,L3,T1)
	local L3_3 = getDateL(frame,3,L3,T1)
	
	local L4_1 = getDateL(frame,1,L4,T1)
	local L4_2 = getDateL(frame,2,L4,T1)
	local L4_3 = getDateL(frame,3,L4,T1)
	
	local L5_1 = getDateL(frame,1,L5,T1)
	local L5_2 = getDateL(frame,2,L5,T1)
	local L5_3 = getDateL(frame,3,L5,T1)
	
	local D1Y = getDateDPart(1,getDateDFull(frame,getD(S1),D1I))
	local D1M = getDateDPart(2,getDateDFull(frame,getD(S1),D1I))
	local D1D = getDateDPart(3,getDateDFull(frame,getD(S1),D1I))
	
	local D2Y = getDateDPart(1,getDateDFull(frame,getD(S2),D2I))
	local D2M = getDateDPart(2,getDateDFull(frame,getD(S2),D2I))
	local D2D = getDateDPart(3,getDateDFull(frame,getD(S2),D2I))
	
	local D3Y = getDateDPart(1,getDateDFull(frame,getD(S3),D3I))
	local D3M = getDateDPart(2,getDateDFull(frame,getD(S3),D3I))
	local D3D = getDateDPart(3,getDateDFull(frame,getD(S3),D3I))
	
	local D4Y = getDateDPart(1,getDateDFull(frame,getD(S4),D4I))
	local D4M = getDateDPart(2,getDateDFull(frame,getD(S4),D4I))
	local D4D = getDateDPart(3,getDateDFull(frame,getD(S4),D4I))
	
	local D5Y = getDateDPart(1,getDateDFull(frame,getD(S5),D5I))
	local D5M = getDateDPart(2,getDateDFull(frame,getD(S5),D5I))
	local D5D = getDateDPart(3,getDateDFull(frame,getD(S5),D5I))
	
	local year, month, day
	local month1=0
	local month2=0
	local month3=0
	local month4=0
	local month5=0
	local month1D=0
	local month2D=0
	local month3D=0
	local month4D=0
	local month5D=0
	local day1=0
	local day2=0
	local day3=0
	local day4=0
	local day5=0
	local day1D=0
	local day2D=0
	local day3D=0
	local day4D=0
	local day5D=0

	year = math.max(L1_1,L2_1,L3_1,L4_1,L5_1,D1Y,D2Y,D3Y,D4Y,D5Y)
	
	if(year == L1_1) then month1=L1_2 end
	if(year == L2_1) then month2=L2_2 end
	if(year == L3_1) then month3=L3_2 end
	if(year == L4_1) then month4=L4_2 end
	if(year == L5_1) then month5=L5_2 end
	if(year == D1Y) then month1D=D1M end
	if(year == D2Y) then month2D=D2M end
	if(year == D3Y) then month3D=D3M end
	if(year == D4Y) then month4D=D4M end
	if(year == D5Y) then month5D=D5M end
	
	month = monthName(math.max(month1,month2,month3,month4,month5,month1D,month2D,month3D,month4D,month5D))
	
	if(monthNum(month) == L1_2) then day1=L1_3 end
	if(monthNum(month) == L2_2) then day2=L2_3 end
	if(monthNum(month) == L3_2) then day3=L3_3 end
	if(monthNum(month) == L4_2) then day4=L4_3 end
	if(monthNum(month) == L5_2) then day5=L5_3 end
	if(monthNum(month) == D1M) then day1D=D1D end
	if(monthNum(month) == D2M) then day2D=D2D end
	if(monthNum(month) == D3M) then day3D=D3D end
	if(monthNum(month) == D4M) then day4D=D4D end
	if(monthNum(month) == D5M) then day5D=D5D end
	
	day = math.max(day1,day2,day3,day4,day5,day1D,day2D,day3D,day4D,day5D)
	
	local S1 = getS(frame,S1,T2,T3)
	local S2 = getS(frame,S2,T2,T3)
	local S3 = getS(frame,S3,T2,T3)
	local S4 = getS(frame,S4,T2,T3)
	local S5 = getS(frame,S5,T2,T3)
	local S6 = getS(frame,S6,T2,T3)
	local S7 = getS(frame,S7,T2,T3)
	local S8 = getS(frame,S8,T2,T3)
	local S9 = getS(frame,S9,T2,T3)
	local S10 = getS(frame,S10,T2,T3)

	if(year == nil) then year = "year" end
	if(month == nil) then month = "month" end
	if(day == nil) then day = "day" end
	
	if(Date == nil) then Date = month .. " " .. day .. ", " .. year end
	
	if(sum == nil) then sum = (mw.getContentLanguage():formatNum(S1+S2+S3+S4+S5+S6+S7+S8+S9+S10)) end
	
	return "As of " .. Date .. ", " .. sum .. " episodes of the ''" .. name .. "'' franchise have aired."
end

return p