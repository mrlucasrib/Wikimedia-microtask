local p={} -- ultimate planned purpose is to create table rows of Refdesk questions, type, date, answerer including wikilinks in collaboration with a big template
function p.main(frame,input,label,desk,year,month,day,arcpage)
    local args=frame.args
    local parent=frame:getParent() or {}
    local pargs=parent.args or {}
    input=input or args.input or pargs.input
    desk=desk or args.desk or pargs.desk
    local label=label or args.label or pargs.label
    if not label then label=desk or "unlabelled" end
    local date=args.date or pargs.date or "undated"
    if year and month and day then date="20"..year..": "..month.." "..day end
    arcpage=arcpage or args.arcpage or pargs.arcpage or nil
    local cat=args.cat or pargs.cat or "yes"
    if cat=="no" then cat = nil end
    local output="[[Module:RDIndex]] error: no section headings found"

    local cursor, next_cursor, questioner, users, user_table, last_user;
    local input_length = mw.ustring.len( input );
    
    local breakpoints = {};
    local cut, item
    for cut, item in mw.ustring.gmatch( input, "\n()==+(.-)==+%s+" ) do                
        table.insert( breakpoints, cut );        
        table.insert( breakpoints, item );        
    end     
    
    index = 1;
    output = '';
    repeat
        cursor = tonumber( breakpoints[index] );
        title = breakpoints[index + 1];
             
        if cursor == nil then 
            break;
        end
        next_cursor = tonumber( breakpoints[index+2] ) or input_length;
      
        text = mw.ustring.sub(input,cursor,next_cursor-1)
        tt = mw.ustring.match(title,"[=%s]+(.-)[=%s]+$")
        if tt then 
            title=tt 
        else
            tt = mw.ustring.match(title,"UNIQ.-QINU.(.+)")
            if tt then 
                title=tt 
            end
        end
        local tcat=""
        if cat then tcat = (mw.ustring.match(text,"{{[Rr][Dd]cat%s*|%s*(.-)}}") or "&mdash;") end
        tcat=mw.ustring.match(tcat,"^(^|*)|.*$") or tcat
        text = mw.ustring.gsub(text, "%[%[Special:Contributions/", "[[User:")
        questioner = mw.ustring.gsub(mw.ustring.match(text,"%[%[User:(.-)[|%]]") or "","_"," ")
        user_table = {}
        for tt in mw.ustring.gmatch(text,"%[%[User:(.-)[|%]]" ) do
            tt = mw.ustring.gsub(tt,"_"," ")
            table.insert( user_table, tt );
        end
        table.sort( user_table );
        
        last_user = ''
        users = '';
        for index, tt in pairs( user_table ) do
            if tt ~= last_user and tt ~= questioner then
                users = table.concat( {users, "[[User:", tt, "|", tt, "]]", " "} );
            end
            last_user = tt;
        end        
        users = "[[User:" .. questioner .. "|" .. questioner .. "]]" .. " " .. users
        title = mw.ustring.gsub( title, '%[%[.-|(.-)%]%]', '%1' );
        title = mw.ustring.gsub( title, '%[', '' );
        title = mw.ustring.gsub( title, '%]', '' );
        title = mw.ustring.gsub( title, '%b<>', '' );
        
        if arcpage then 
            title= table.concat( {"[[", arcpage, "#", (title or ""), "|", title,  "]]"} );
        else 
            title= title or "" 
        end
        if (cat=="yes" or cat==tcat) then output = table.concat( {output, "\n|-\n|", title, "\n|", next_cursor-cursor, "\n|", label, "\n|", tcat, "\n|", date, "\n|", users} ) end

        index = index + 2;
    until next_cursor == input_length
  
    return output
end

function p.month(frame)
    local args=frame.args
    local parent=frame:getParent() or {}
    local pargs=parent.args or {}
        local title
    if not input then title=mw.title.getCurrentTitle() end
    
    local year=args.year or pargs.year
    local month=args.month or pargs.month
    local desk=args.desk or pargs.desk
    local label=args.label or pargs.label or desk
    local nowiki=args.nowiki or pargs.nowiki
    local desks={'Computing','Science','Mathematics','Humanities','Language','Entertainment','Miscellaneous'}
    local months={'January','February','March','April','May','June','July','August','September','October','November','December'}
    local days=31
    local output=""
    if not (desk and year and month) then -- I want to be able to plop this template empty of parameters into an archive page, even if it moves, as long as its name contains the data!
        local title=mw.title.getCurrentTitle()
        local page=title.fullText
        if not desk then
            for x=1,#desks do
                if mw.ustring.match(page,desks[x]) then desk=desks[x]; break end
            end
        end
        year=year or mw.ustring.match(page,"20(%d%d)") -- This has a Y2.1k bug.  Pity.
        if not month then
            for x=1,12 do
                if mw.ustring.match(page,months[x]) then month=months[x]; break end
            end
        end
    end
    year=tonumber(year)
    if month=='September' or month=='April' or month=='June' or month=='November' then days=30 end
    if month=='February' then
        days=28
        if year/4==math.floor(year/4) then days=29 end
    end
    for day=1,days do
        page='Wikipedia:Reference desk/Archives/'..desk..'/20'..year..' '..month..' '..day
        title=mw.title.new(page)
        if title then
            local input=title.getContent(title)
            if input then output=output..p.main(frame,input,label,desk,year,month,day,page) end
        end
    end
    output='{| class="wikitable sortable"\n!question\n!length\n!RefDesk\n!Category\n!Date\n!Editors'..output..'\n|}'
    if nowiki then
       return frame:preprocess("<pre><nowiki>"..output.."</nowiki></pre>")
    else
       return output
    end
end

return p