local getArgs = require('Module:Arguments').getArgs

function getpropertyvalue(ent, prop)
	local id = nil;
	if (ent and prop) then value = ent:getBestStatements(prop)[1] else return nil end
	if value then return value["mainsnak"]["datavalue"]["value"] end;
end

function getpropertyvaluewithdefaultvalues(ent, prop, value1, value2)
	return value1 or value2 or getpropertyvalue(ent, prop);
end	

function getname(frame, name1, name2)
	return name1 or name2 or frame:expandTemplate{title = 'PAGENAMEBASE'}; 
end	

function getexternallink(frame, linkformat, urlformat, prop, cat)
		local args = getArgs(frame); 
		local id = args[1] or args["id"];
		if (not id and prop) then id = getpropertyvalue(mw.wikibase.getEntityObject(), prop); end;
		if not id then return cat end	
	    local name = getname(frame, args[2], args["name"]);
	    local url = string.format(urlformat, id);
	    local code = string.format(linkformat, url, name);
	    return code;
end

local p = {}
function p.getpropertyvalue(frame)
local ent = mw.wikibase.getEntityObject();
local prop = frame.args[1];
return getpropertyvalue(ent, prop);
end	

function p.cagematch(frame)
	return getexternallink(frame, "[%s %s]'s profile at Cagematch.net", "https://www.cagematch.net/?id=2&nr=%s", 'P2728', "");
end

function p.wrestlingtitlespersonalities(frame)
	return getexternallink(frame, "[%s %s]'s profile at Wrestling-Titles.com", "http://www.wrestling-titles.com/personalities/%s/", nil, "[[Category:Wrestling Titles template with no id set]]");
end	

function p.rohroster(frame)
	return getexternallink(frame, "[%s %s]'s [[Ring of Honor]] profile", "http://www.rohwrestling.com/wrestlers/%s", nil, "");	
end	

function p.njpw(frame)
	local args = getArgs(frame);
	if args["newlink"] then return getexternallink(frame, "[%s %s]'s [[New Japan Pro-Wrestling]] profile", "http://www.njpw1972.com/profile/%s", nil, "");
		else return getexternallink(frame, "[%s %s]'s [[New Japan Pro-Wrestling]] profile", "http://www.njpw.co.jp/english/data/detail_profile.php?f=%s", nil, "");	
		end
end	

function p.gfw(frame)
	return getexternallink(frame, "[%s %s]'s [[Global Force Wrestling]] profile", "http://globalforcewrestling.com/roster/%s/", nil, "");	
end 

function p.dragongateusa(frame)
	return getexternallink(frame, "[%s %s] at the official [[Dragon Gate USA]] website", "http://dgusa.tv/bio/%s", nil, "");
end	

function p.chikara(frame)
	return getexternallink(frame, "[%s %s] at the official [[Chikara_(professional_wrestling)|Chikara]] website", "http://chikarapro.com/chikara-roster/%s", nil, "");
end	



function p.profiles(frame)
	local args = getArgs(frame);
	local ent = mw.wikibase.getEntityObject();
	local cagematchid = getpropertyvaluewithdefaultvalues(ent, 'P2728', args["cagematch"], nil);		
	local wrestlingdataid = getpropertyvaluewithdefaultvalues(ent, 'P2764', args["wrestlingdata"], nil);
	local iwdid = getpropertyvaluewithdefaultvalues(ent, 'P2829', args["iwd"], nil);
	if (not cagematchid) and (not wrestlingdataid) and (not iwdid) then return "[[Category:Professional wrestling profiles template without any identifiers]]" end
	local name = getname(frame, args["name"], nil);
	local text = name .. "'s profile at "; 
	if cagematchid then text = text .. "[https://www.cagematch.net/?id=2&nr=" .. cagematchid .. " Cagematch.net], " end
	if wrestlingdataid then text = text .. "[http://wrestlingdata.com/index.php?befehl=bios&wrestler=" .. wrestlingdataid .. " Wrestlingdata.com], " end
	if iwdid then text = text .. "[http://www.profightdb.com/wrestlers/" .. iwdid .. ".html Internet Wrestling Database], " end
	return string.sub(text, 1, -3);
end	

return p