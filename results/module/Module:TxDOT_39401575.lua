local p = {}

local insert = table.insert

function p.url(frame)
    local pframe = frame:getParent()
    local config = frame.args -- the arguments passed BY the template, in the wikitext of the template itself
    local args = pframe.args -- the arguments passed TO the template, in the wikitext that transcludes the template
    
    local type = args[1]
    local route = tonumber(args[2])
    local suffix = args[3] or ''
    
    local url = {"https://www.dot.state.tx.us/tpp/hwy/", type}
    if type == "FM" then
        if route < 500 then
            insert(url, '')
        elseif route < 1000 then
            insert(url, "0500")
        elseif route < 1500 then
            insert(url, "1000")
        elseif route < 2000 then
            insert(url, "1500")
        elseif route < 2500 then
            insert(url, "2000")
        elseif route < 3000 then
            insert(url, "2500")
        elseif route < 3500 then
            insert(url, "3000")
        elseif route >= 3500 then
            insert(url, "3500")
        end
    end
    insert(url, "/")
    insert(url, type)
    insert(url, string.format("%04d", route))
    insert(url, suffix)
    insert(url, ".htm")
    return table.concat(url)
end

return p