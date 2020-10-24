local p = {};

p.list = function(frame)
    text = "This article has been viewed enough times in a single week to make it into the [[Wikipedia:Top 25 Report|25 Most Popular Wikipedia Articles of the Week]]";
	txtstyle = "text-align: left;";
	
    frame = frame:getParent();

    args = frame.args
    
    Date = require('Module:Date')._Date

    local int count=0;
    local list="<ul>";

    local date;
    local isUntil = false;
    local errors = {}

    for _, dateStr in pairs( frame.args ) do
        dateStr = mw.text.trim(dateStr)
        if (string.lower(dateStr) == "until") then
            isUntil = true
        else
            local index = string.find(dateStr,'(',1,true)
            local place=""
            if not (index==nil) then
                place=string.sub(dateStr,index+1,-2)
                dateStr=string.sub(dateStr,0,index-1)
            end
            local newDate = Date(dateStr);
            if newDate == nil then
                table.insert(errors, dateStr);
            else
                if isUntil then
                    isUntil = false
                    date = date+7
                    while date<newDate do
                        list = list .. "<li>" .. line(date) .. "</li>"
                        count = count +1
                        date = date + 7
                    end
                end
                date = newDate
                list = list .. "<li>"

                list = list .. line(date)

                if not (place=="") then
                    list = list .. " ("..place..")"
                end
                list = list .."</li>"
                count=count+1
            end
        end
    end
    list = list .. "</ul>\n"

    if count>5 then
        list = '<table class="mw-collapsible autocollapse" width=100% style="border:1px solid silver; text-align:left; padding:1px;"><tr bgcolor=#fff1d2 style="text-align:center;><th>The weeks in which this happened:</th></tr><tr bgcolor=#fff><td><div style="{{column-count|4}}">' .. list .. '</div></td></tr></table>'
        txtstyle = "text-align: center;"
        text = text .. " '''" .. tostring(count) .. "''' times."
    elseif count==0 then
    	text = text .. "."
    elseif count==1 then
    	list = "<br/>The week in which this happened:" .. list
    	text = text .. "."
    else
        list = "<br/>The weeks in which this happened:" .. list
        text = text .. " '''" .. tostring(count) .. "''' times."
    end

    if mw.title.getCurrentTitle().namespace==1 then
        text = text .. "[[Category:Pages in the Top 25 Report]]";
    end
    text = text .. list
    if #errors > 0 then
        text = text .. "\n\n<big><span style=\"color:red\">'''The following dates couldn't be parsed:'''</span></big>\n#"
        text = text .. table.concat(errors,"\n#") .. "\n"
    end
    return  frame:expandTemplate{title="tmbox", args={text=text, image="[[File:Article blue.svg|35px|link=]]", textstyle=txtstyle}}

end

function range(date)
    date2 = date + 6;
    if not (date2:text("%Y")==date:text("%Y")) then
        return date:text("%B %-d, %Y").." to "..date2:text("%B %-d, %Y")
    else
        if not (date2:text("%B")==date:text("%B")) then
            return date:text("%B %-d") .. " to "..date2:text("%B %-d, %Y")
        else
            return date:text("%B %-d") .. " to "..date2:text("%-d, %Y")
        end
    end

end




function line(date)
    local link = "[[Wikipedia:Top 25 Report/"

    local range = range(date)

        
    link = link..range .."|"..range.."]]"
    return link

end

function userLink(username)
    return string.format("[[User:%s|%s]]", username, username)
end

p.header = function(frame)
    text=frame:expandTemplate{title="Wikipedia:Top 25 Report/Template:Header", args={}}
    text = text .. "__NOTOC__\n"
    if mw.title.getCurrentTitle().subpageText == "Report header" then
        return text
    end
    frame = frame:getParent()
    Date = require('Module:Date')._Date
    local date=Date(frame.args[1])
    text = text .. '<div style="height:10px;clear:both;"></div>\n'
    text = text .. "==Most Popular Wikipedia Articles of the Week ("
    text = text .. range(date).. ")==\n"

    
    count=0
    for index,nameStr in pairs(frame.args) do
        if not (index == 1) then
            count = count + 1
        end
    end

    if count>0 then
        text = text .. "''Prepared with commentary by "
    
        if count == 1 then
            text = text .. userLink(frame.args[2])
        elseif count == 2 then
            text = text .. userLink(frame.args[2]) .. " and " .. userLink(frame.args[3])
        else
            i = 2
            while i<= count do
                text = text .. userLink(frame.args[i]) .. ", "
                i = i+1
            end
            text = text .. " and " .. userLink(frame.args[count+1])
        end
    end

    key = " "

    text = text .. "''\n\n← [[Wikipedia:Top 25 Report/"
    if (frame.args[1] == "January 6, 2013") then
        text = text .. "December 2012|December 2012 monthly report]]"
    else
        text = text .. range(date-7) .. "|Last week's report]]"
    end
    if not (mw.title.getCurrentTitle().subpageText == "Top 25 Report") then
        text = text .. " – [[Wikipedia:Top 25 Report/" .. range(date+7) .. "|Next week's report]] →"
        key = "Top 25 " .. date:text("%Y%m%d")
    end
    if mw.title.getCurrentTitle().namespace==4 then
        text =  text.."[[Category:Wikipedia Top 25 Report|"..key.."]]"
    end
    return text
end

return p;