require('Module:No globals')
local dts = require('Module:Date table sorting')._main
local p = {}
--[[
The purpose of this file is to have a centralised place where the dates which File:Syrian,_Iraqi,_and_Lebanese_insurgencies.png (and related files) is updated can be managed, instead of having to update them in different articles. 

To update, edit the strings (the parts between quotes) underneath each function.
For maintainability of modules being used on other-language Wikipedias, you must use ISO date: YYYY-MM-DD (i.e. 2015-12-09)
The output will be a correct wordy date format (i.e. "9 December 2015", or "9 tháng 12 năm 2015" if you're on Vietnamese Wikipedia)

Example usage: "(as of {{#invoke:Iraq Syria map date|syriadate}})"
--]]

function p.date( frame )
	return dts{"2019-08-27"}   -- [[commons:File:Syrian, Iraqi, and Lebanese insurgencies-3.jpg]]
end
function p.iraqdate( frame )
	return dts{"2018-09-05"}   -- [[commons:File:Iraq_war_map.png]]
end
function p.syriadate( frame )
	return dts{"2019-04-09"}   -- [[commons:File:Syrian_Civil_War_map.svg]]
end
function p.aleppo2date( frame )
	return dts{"2019-01-10"}   -- [[commons:File:Rif_Aleppo2.svg]]
end
function p.damascusdate( frame )
	return dts{"2018-05-22"}   -- [[commons:File:Rif_Damashq.svg]]
end
function p.mosuldate( frame )
	return dts{"2017-10-20"}   -- [[commons:File:Battle_of_Mosul_(2016%E2%80%932017).svg]]
end
function p.lebanondate( frame )
	return dts{"2019-09-02"}   -- [[commons:File:Lebanese_insurgency.png]]
end
function p.raqqadate( frame )
	return dts{"2017-10-18"}   -- [[commons:File:Battle_of_Raqqa2.svg]]
end

return p