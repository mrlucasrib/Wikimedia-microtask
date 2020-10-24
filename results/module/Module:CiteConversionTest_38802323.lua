c = {}

function c.test( frame )
    local target = frame.args[1] or frame.args.target;
    
    local tt = mw.title.new( target );
    
    local content = tt:getContent();
    
    local result = '';
    local template;
    local i = 1;
    for template in string.gmatch( content, '%b{}' ) do
        local mode, param;
        mode, param = string.match( template, '{{%s*cite (%w*)%s*|([^}]*)}}' );
        if mode ~= nil and mode ~= 'quick' then
            result = result .. '\n{{cite compare|mode=' .. mode .. " | " .. param .. "}}\n";
            i = i + 1;
        end        
        mode, param = string.match( template, '{{%s*cite quick%s*|%s*(%w*)%s*|([^}]*)}}' );
        if mode ~= nil then
            result = result .. '\n{{cite compare|mode=' .. mode .. " | " .. param .. "}}\n";
            i = i + 1;
        end        
        if i > 90 then break; end --prevent time outs
    end
    
    return frame:preprocess(result);
end

function c.gather( frame )
    local typ = frame.args[1] or frame.args.mode;
    local start = frame.args[2] or frame.args.start;
    local required = frame.args[3] or frame.args.require;

    local tt = mw.title.new( start );
    local content = tt:getContent();

    local targets = {};
    for w in string.gmatch( content, '%[%[(%w-)%]%]' ) do
        targets[w] = true;
    end   
    
    local targets2 = {}
    for k in pairs( targets ) do
        tt = mw.title.new( k );
        if tt ~= nil then
            content = tt:getContent() or "";
        else
            content = nil;
        end        
        if content ~= nil then 
            for w in string.gmatch( content, '%[%[(%w-)%]%]' ) do
                targets2[w] = true;
            end   
        end
    end
    targets = targets2;

    local result = '';
    local cnt = 0;
    local param_list = {};
    for k in pairs( targets ) do    
        local tt = mw.title.new( k );
        cnt = cnt + 1;
        
        if tt ~= nil then            
            local content = tt:getContent() or '';
            local template;
            local i = 1;
            
            for template in string.gmatch( content, '%b{}' ) do
                local param;   
                if typ == 'citation' then
                    param = string.match( template, '{{%s*' .. typ .. '%s*|([^}]*)}}' );
                else
                    param = string.match( template, '{{%s*[cC]ite ' .. typ .. '%s*|([^}]*)}}' );
                end

                if param ~= nil then
                    local good = false;
                    for kw in string.gmatch( param, "[%s|](%w-)%s*=" ) do
                        if required ~= nil then
                            if kw == required then
                                good = true;
                            end
                        else                            
                            if param_list[kw] == nil then
                                good = true;
                                param_list[kw] = true;
                            end
                        end                        
                    end
                    
                    if good or (required==nil and math.random(50) == 1) then 
                        result = result .. frame:preprocess( '<nowiki>{{cite compare|mode=' .. typ .. " | " .. param .. "}}</nowiki>" ) .. "\n<br />";
                    end
                end        
            end 
        end        
        if cnt > 150 then break; end
    end

    return result
end

function c.casing( frame )
    local start = frame.args[1] or frame.args.start;

    local tt = mw.title.new( start );
    local content = tt:getContent();

    local targets = {};
    for w in string.gmatch( content, '%[%[(%w-)%]%]' ) do
        targets[w] = true;
    end   
    
    local targets2 = {}
    for k in pairs( targets ) do
        tt = mw.title.new( k );
        content = tt:getContent();
        for w in string.gmatch( content, '%[%[(%w-)%]%]' ) do
            targets2[w] = true;
        end   
    end
    targets = targets2;

    local result = '';
    local cnt = 0;
    local param_list = {};
    for k in pairs( targets ) do    
        local tt = mw.title.new( k );
        cnt = cnt + 1;
        
        if tt ~= nil then            
            local content = tt:getContent() or '';
            local template;
            local i = 1;
            
            for template in string.gmatch( content, '%b{}' ) do
                local mode, param;                
                mode, param = string.match( template, '{{%s*cite (%w-)%s*|([^}]*)}}' );
                if param ~= nil then
                    local good = false;
                    for kw in string.gmatch( param, "[%s|](%w-)%s*=" ) do
                        if kw:match('[A-Z]') ~= nil then good = true; end
                    end
                    
                    if good then 
                        result = result .. frame:preprocess( '<nowiki>{{cite compare|mode=' .. mode .. " | " .. param .. "}}</nowiki>" ) .. "\n<br />";
                    end
                end        
            end 
        end        
        if cnt > 150 then break; end
    end

    return result
end


return c;