local p = {}

function p.main( frame )
    local version = mw.title.makeTitle( 'Wikipedia', 'AutoWikiBrowser/CheckPage/VersionJSON' )
    
    local decoded = mw.text.jsonDecode( version:getContent() )
    local output = ''
    for i, v in ipairs(decoded.enabledversions) do
    	output = output .. '* ' .. v.version
    	if v.dev then
    		output = output .. ' (svn)'
    	end
    	output = output .. '\n'
    end
    
    return output
end

return p