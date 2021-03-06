local p = {}

function p.asc(frame)
    items = splitLine( frame.args[1] );
    table.sort( items );
    return table.concat( items, "\n" );    
end

function p.desc(frame)
    items = splitLine( frame.args[1] );
    table.sort( items, function (a, b) return a > b end );
    return table.concat( items, "\n" );
end

function splitLine( text )
    return mw.text.split( text, "\n", true );    
end



return p