local p = {}

function p.link_url_for_current_page()
    return p.link_url(mw.wikibase.getEntityIdForCurrentPage())
end

function p.asciify(ft_id)
    ft_id = mw.ustring.gsub(ft_id, 'æ', 'ae')
    ft_id = mw.ustring.gsub(ft_id, 'ø', 'oe')
    ft_id = mw.ustring.gsub(ft_id, 'ð', 'oe') -- e.g. Sjúrður Skaale
    ft_id = mw.ustring.gsub(ft_id, 'ö', 'oe') -- e.g. Özlem Cekic
    ft_id = mw.ustring.gsub(ft_id, 'å', 'aa')
    ft_id = mw.ustring.gsub(ft_id, 'ú', 'u')  -- e.g. Sjúrður Skaale
    ft_id = mw.ustring.gsub(ft_id, 'á', 'a')  -- e.g. Annita á Fríðriksmørk
    ft_id = mw.ustring.gsub(ft_id, 'í', 'i')  -- e.g. Annita á Fríðriksmørk
    return ft_id
end

local url_prefix = 'https://www.thedanishparliament.dk/members/'

function p.link_url(entity)
    local prop = entity and mw.wikibase.getBestStatements(entity, 'P7882')
    if prop and prop[1] and prop[1].mainsnak.snaktype == 'value' then
        local ft_id = prop[1].mainsnak.datavalue.value
        slash_position = mw.ustring.find(ft_id, '/')
        if slash_position ~= nil then
            -- There are politicians like e.g. Özlem Cekic where the property string will start with 'oe/'
            -- because this is needed in the Danish version of the biography URL.
            -- It isn't there in the English version, so we strip off that part.
            ft_id = mw.ustring.sub(ft_id, slash_position + 1)
        end
        ft_id = p.asciify(ft_id) -- The Danish version allows unicode but the English doesn't
        return url_prefix .. ft_id
    end
    return ''
end

return p