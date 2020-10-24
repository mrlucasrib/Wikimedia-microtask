--
-- This module implements {{GS pay}}
-- There are 150 cells in the GS Pay table. This LUA reduces the amount of
--   manual input needed to 46
--

local p = {}
local stepOnePay = {}
local GSOnePay = {}
local GSTwoPay = {}
local WIGIncrease = {}

-- UPDATE THESE. Last Update: 2020
-- https://www.opm.gov/policy-data-oversight/pay-leave/salaries-wages/salary-tables/pdf/2020/GS.pdf
	--For GS [Grade] Step 1 pay
	stepOnePay[3] = 23976
	stepOnePay[4] = 26915
	stepOnePay[5] = 30113
	stepOnePay[6] = 33567
	stepOnePay[7] = 37301
	stepOnePay[8] = 41310
	stepOnePay[9] = 45627
	stepOnePay[10] = 50246
	stepOnePay[11] = 55204
	stepOnePay[12] = 66167
	stepOnePay[13] = 78681
	stepOnePay[14] = 92977
	stepOnePay[15] = 109366
	-- Within Grade increase for GS [Grade]
	WIGIncrease[3] = 799
	WIGIncrease[4] = 897
	WIGIncrease[5] = 1004
	WIGIncrease[6] = 1119
	WIGIncrease[7] = 1243
	WIGIncrease[8] = 1377
	WIGIncrease[9] = 1521
	WIGIncrease[10] = 1675
	WIGIncrease[11] = 1840
	WIGIncrease[12] = 2206
	WIGIncrease[13] = 2623
	WIGIncrease[14] = 3099
	WIGIncrease[15] = 3646
	-- GS1 Pay Table (because it has inconsistent WIG)
	GSOnePay[1] = 19543
	GSOnePay[2] = 20198
	GSOnePay[3] = 20848
	GSOnePay[4] = 21494
	GSOnePay[5] = 22144
	GSOnePay[6] = 22524
	GSOnePay[7] = 23166
	GSOnePay[8] = 23814
	GSOnePay[9] = 23840
	GSOnePay[10] = 24448
	-- GS2 Pay Table (because it has inconsistent WIG}
	GSTwoPay[1] = 21974
	GSTwoPay[2] = 22497
	GSTwoPay[3] = 23225
	GSTwoPay[4] = 23840
	GSTwoPay[5] = 24108
	GSTwoPay[6] = 24817
	GSTwoPay[7] = 22526
	GSTwoPay[8] = 26235
	GSTwoPay[9] = 26944
	GSTwoPay[10] = 27653

-- Base pay calculation
function p.basePay(grade, step)
	-- For Step 1 pay for all grades
	if step == nil then
		if grade > 2 then
			-- Returns the Step 1 Pay for [grade]
			return stepOnePay[grade]
		elseif grade == 1 then
			-- Returns GS1 Step 1
			return GSOnePay[1]
		else
			-- Returns GS2 Step 1
			return GSTwoPay[1]
		end
	-- For grades where step is specified
	else
		if grade > 2 then
			-- Calculate GS [grade #], Step [step #] pay
			local pay = stepOnePay[grade] + (WIGIncrease[grade] * (step - 1))
			return pay
		elseif grade == 1 then
			return GSOnePay[step]
		else
			return GSTwoPay[step]
		end
	end
end
	
-- 'Main' function
function p.get(frame)
	-- Error checking
	if frame.args[1] == nil then
		if frame.args[2] == nil then
			return
		end
	else
		-- Grab the basic pay number based on inputs
		return p.basePay(tonumber(frame.args[1]), tonumber(frame.args[2]))
	end
end
	
return p