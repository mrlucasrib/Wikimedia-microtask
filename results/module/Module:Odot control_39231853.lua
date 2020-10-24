local p = { } --Package to be exported

local function countyNumber(county)
	local numbers = mw.loadData("Module:Odot control/counties")
	return numbers[county]
end

function p.url(frame)
	--This function builds URLs.
	local pframe = frame:getParent() --get arguments passed to the template
	local args = pframe.args
	local county = args['county'] or '' --this string holds the raw county name
	local countyProcessed --this string holds the processed county name to be added to the URL
	
	--Le Flore and Roger Mills need special treatment to handle the spaces.
	--Everything else just gets converted to lower case.
	if county == "Le Flore" then
		countyProcessed = "leflore"
	elseif county == "Roger Mills" then
		countyProcessed = "rogermills"
	else
		countyProcessed = county:lower()
	end
	
	local edition = p.edition(frame)
	if edition == "2012–2013" then
		local countyNumber = countyNumber(county)
		return "http://www.odot.org/maps/control-section/2012/map_csect_2012-" .. countyNumber .. '-' .. countyProcessed .. ".pdf"
	else
		return "http://www.odot.org/hqdiv/p-r-div/maps/control-maps/" .. countyProcessed .. ".pdf"
	end
end

function p.edition(frame)
	--This function fills in the edition field of cite map.
	local pframe = frame:getParent() --get arguments passed to the template
	local args = pframe.args
	local year = args['year'] or ''
	
	local editions = {["2004"] = "2004", ["2006"] = "2006", ["2008"] = "2008",
	                  ["2010"] = "2010–2011", ["2011"] = "2010–2011", ["2010–2011"] = "2010–2011", ["2010-2011"] = "2010–2011",
	                  ["2012"] = "2012–2013", ["2013"] = "2012–2013", ["2012–2013"] = "2012–2013", ["2012-2013"] = "2012–2013"}
	return editions[year] or ''
end

function p.dateOutput(frame)
	--This function fills in the date field of cite map.
	local edition = p.edition(frame)
	local dates = {["2004"] = "2004-01-01", ["2006"] = "2006-01-01", ["2008"] = "2008-01-01", ["2010–2011"] = "2010-01-01", ["2012–2013"] = "2012-01-01"}
	return dates[edition]
end

return p