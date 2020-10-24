local p = {}

function p.asc(frame)
    list = {}
    
	for key,value in pairs(frame.args) do
		-- Remove newlines
		stripped = string.gsub(value, "\n", "")
		
		if stripped:match("%S") ~= nil then
		    table.insert(list, stripped)
		end
	end
	
    table.sort( list, function (a, b)
    	indexA = a:find("%%")
    	indexB = b:find("%%")
    	numberA = tonumber(a:sub(1, indexA - 1))
    	numberB = tonumber(b:sub(1, indexB - 1))
    	return numberA < numberB 
    end )
    
    return table.concat( list, "<br>" )
end

function p.desc(frame)
	list = {}
	
	for key,value in pairs(frame.args) do
		-- Remove newlines
		stripped = string.gsub(value, "\n", "")
		
		if stripped:match("%S") ~= nil then
			mw.log("After processing")
			mw.log(stripped)
		    table.insert(list, stripped)
		end
	end
	
    table.sort( list, function (a, b)
    	indexA = a:find("%%")
    	indexB = b:find("%%")
    	mw.log("Logging index A")
    	mw.log(indexA)
    	mw.log("Logging index B")
    	mw.log(indexB)
    	numberA = tonumber(a:sub(1, indexA - 1))
    	mw.log("Number A")
    	mw.log(numberA)
    	numberB = tonumber(b:sub(1, indexB - 1))
    	mw.log("Number B")
    	mw.log(numberB)
    	return numberA > numberB 
    end )
    
    return table.concat( list, "<br>" )
end

return p