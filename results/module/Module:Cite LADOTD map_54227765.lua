local p = { } --Package to be exported

function p.url1(frame)
	--This function builds URLs.
	local pframe = frame:getParent() --get arguments passed to the template
	local args = pframe.args
	local parish = args['parish'] or '' --this string holds the raw parish name
	local parishProcessed --this string holds the processed parish name to be added to the URL
	
	--Various parishes need special treatment to handle spaces and/or punctuation.
	if parish == "De Soto" then
		parishProcessed = "DeSoto"
	elseif parish == "East Baton Rouge" then
		parishProcessed = "East_Baton_Rouge"
	elseif parish == "East Carroll" then
		parishProcessed = "East_Carroll"
	elseif parish == "East Feliciana" then
		parishProcessed = "East_Feliciana"
	elseif parish == "Jefferson Davis" then
		parishProcessed = "Jefferson_Davis"
	elseif parish == "La Salle" then
		parishProcessed = "LaSalle"
	elseif parish == "Pointe Coupee" then
		parishProcessed = "Pointe_Coupee"
	elseif parish == "Red River" then
		parishProcessed = "Red_River"
	elseif parish == "St. Bernard" then
		parishProcessed = "St_Bernard"
	elseif parish == "St. Charles" then
		parishProcessed = "St_Charles"
	elseif parish == "St. Helena" then
		parishProcessed = "St_Helena"
	elseif parish == "St. James" then
		parishProcessed = "St_James"
	elseif parish == "St. John the Baptist" then
		parishProcessed = "St_John_the_Baptist"
	elseif parish == "St. Landry" then
		parishProcessed = "St_Landry"
	elseif parish == "St. Martin" then
		parishProcessed = "St_Martin"
	elseif parish == "St. Mary" then
		parishProcessed = "St_Mary"
	elseif parish == "St. Tammany" then
		parishProcessed = "St_Tammany"
	elseif parish == "West Baton Rouge" then
		parishProcessed = "West_Baton_Rouge"
	elseif parish == "West Carroll" then
		parishProcessed = "West_Carroll"
	elseif parish == "West Feliciana" then
		parishProcessed = "West_Feliciana"
	else
		parishProcessed = parish
	end
	
	return parishProcessed
	
end

function p.url2(frame)
	--This function builds URLs.
	local pframe = frame:getParent() --get arguments passed to the template
	local args = pframe.args
	local parish = args['parish'] or '' --this string holds the raw parish name
	local parishProcessed --this string holds the processed parish name to be added to the URL
	
	--Various parishes need special treatment to handle spaces and/or punctuation.
	if parish == "De Soto" then
		parishProcessed = "DeSoto"
	elseif parish == "East Baton Rouge" then
		parishProcessed = "EastBatonRouge"
	elseif parish == "East Carroll" then
		parishProcessed = "EastCarroll"
	elseif parish == "East Feliciana" then
		parishProcessed = "EastFeliciana"
	elseif parish == "Jefferson Davis" then
		parishProcessed = "JeffersonDavis"
	elseif parish == "La Salle" then
		parishProcessed = "LaSalle"
	elseif parish == "Pointe Coupee" then
		parishProcessed = "PointeCoupee"
	elseif parish == "Red River" then
		parishProcessed = "RedRiver"
	elseif parish == "St. Bernard" then
		parishProcessed = "StBernard"
	elseif parish == "St. Charles" then
		parishProcessed = "StCharles"
	elseif parish == "St. Helena" then
		parishProcessed = "StHelena"
	elseif parish == "St. James" then
		parishProcessed = "StJames"
	elseif parish == "St. John the Baptist" then
		parishProcessed = "StJohntheBaptist"
	elseif parish == "St. Landry" then
		parishProcessed = "StLandry"
	elseif parish == "St. Martin" then
		parishProcessed = "StMartin"
	elseif parish == "St. Mary" then
		parishProcessed = "StMary"
	elseif parish == "St. Tammany" then
		parishProcessed = "StTammany"
	elseif parish == "West Baton Rouge" then
		parishProcessed = "WestBatonRouge"
	elseif parish == "West Carroll" then
		parishProcessed = "WestCarroll"
	elseif parish == "West Feliciana" then
		parishProcessed = "WestFeliciana"
	else
		parishProcessed = parish
	end
	
	return parishProcessed
	
end

return p