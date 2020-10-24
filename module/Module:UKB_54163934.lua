uk = {}

local messages = {
    ['and'] = 'and',
    ['or'] = 'or',
    ['page_at_site'] = '%(page)s at %(site)s',
    ['argument_missing'] = 'Argument missing: %s',
    ['anon_argument_missing'] = 'No %s specified',
    ['invalid_criterion'] = '"%s" is not a valid criterion',
    ['invalid_rule'] = '"%s" is not a valid points rule',


    -- Criteria

    ['templates'] = 'templates',
    ['templates_criterion_singular'] = 'having the template %s',
    ['templates_criterion_plural'] = 'having at least one of the templates %s',

    ['categories'] = 'categories',
    ['categories_criterion_singular'] = 'in the category %s',
    ['categories_criterion_plural'] = 'in at least one of the categories %s',
    ['categories_criterion_ignore'] = ', but not in %s',

    ['backlinks'] = 'backlinks',
    ['backlinks_criterion_singular'] = 'linked to from %s',
    ['backlinks_criterion_plural'] = 'linked to from %s',

    ['forwardlinks'] = 'forwardlinks',
    ['forwardlinks_criterion_singular'] = 'that links to %s',
    ['forwardlinks_criterion_plural'] = 'that links to %s',

    ['pages'] = 'pages',
    ['pages_criterion_singular'] = '%s',
    ['pages_criterion_plural'] = '%s',

    ['sparql_criterion'] = 'have a Wikidata item matching [%(queryLink)s this SPARQL query]',
    ['sparql_criterion_with_explanation'] = '%(description)s ([%(queryLink)s Wikidata query])',

    ['bytes_criterion'] = 'expanded with at least %s bytes',

    ['namespaces_criterion_singular'] = 'is a/an %s',
    ['namespaces_criterion_plural'] = 'is a/an %s',
    ['article'] = 'article',

    ['new_criterion'] = 'created during the contest',
    ['new_criterion_with_redirects'] = 'created during the contest (including redirects)',

    ['existing_criterion'] = 'created before the contest started (existing pages)',

    -- Rules

    ['base_rule_max'] = '%(baserule)s, but max %(maxpoints)s points per page',

    ['newpage_rule'] = '%(points)s points awarded for creating a new page (not redirect)',
    ['newredirect_rule'] = '%(points)s points awarded for creating a new redirect',
    ['page_rule'] = '%(points)s points awarded for every qualified page',
    ['edit_rule'] = '%(points)s points awarded for every edit',
    ['byte_rule'] = '%(points)s points awarded for every byte added',
    ['listbyte_rule'] = '%(points)s points awarded for every byte added to a a list article',
    ['word_rule'] = '%(points)s points awarded for every word added to the article body (excluding templates, tables etc.)',

    ['image_rule'] = '%(points)s points awarded for every media file added',
    ['image_rule_limited'] = '%(points)s points awarded for every media file added to pages that had no more than %(initialimagelimit)s from before',
    ['image_rule_own'] = '(%(ownimage)s for self-uploaded)',

    ['reference_rule'] = '%(points)s points awarded for every source added and %(refpoints)s points for every reference to an existing source',
    ['templateremoval_rule'] = '%(points)s points awarded for removal of %(templates)s',
    ['categoryremoval_rule'] = '%(points)s points awarded for removal of %(categories)s',
    ['exlink_rule'] = '%(points)s points awarded for every [[WP:EL|external link]] added',

    ['wikidata_rule_first'] = '%(points)s points awarded for addition of %(thing)s to items not already having such a statement',
    ['wikidata_rule_all'] = '%(points)s points awarded for every %(thing)s added',
    ['wikidata_rule_require_reference'] = '(only referenced)',
    ['properties'] = 'properties',
    ['labels'] = 'labels',
    ['aliases'] = 'aliases',
    ['descriptions'] = 'descriptions',
    ['label'] = 'Wikidata label',
    ['alias'] = 'Wikidata alias',
    ['description'] = 'Wikidata description',

    ['bytebonus_rule'] = '%(points)s bonus points when more than %(bytes)d byte were added to a page',
    ['wordbonus_rule'] = '%(points)s bonus points when %(action)s more than %(words)d words were added to a page',
}

local config = {
    ['decimal_separator'] = '.',
    ['template_link_template'] = 'Tl',
    ['error_message_template'] = 'Error',
    -- Map localized argument values for the criterion template
    ['criteria'] = {
        ['new'] = 'new',
        ['existing'] = 'existing',
        ['stub'] = 'stub',
        ['bytes'] = 'bytes',
        ['namespaces'] = 'namespaces',
        ['categories'] = 'categories',
        ['templates'] = 'templates',
        ['backlinks'] = 'backlinks',
        ['forwardlinks'] = 'forwardlinks',
        ['pages'] = 'pages',
        ['sparql'] = 'sparql',
    },
    -- Localized argument values for the rule template
    ['rules'] = {
        ['new'] = 'newpage',
        ['redirect'] = 'newredirect',
        ['qualified'] = 'page',
        ['edit'] = 'edit',
        -- ['stub'] = '(deprecated)',
        ['byte'] = 'byte',
        ['listbyte'] = 'listbyte',
        ['word'] = 'word',
        ['image'] = 'image',
        ['ref'] = 'reference',
        ['bytebonus'] = 'bytebonus',
        ['wordbonus'] = 'wordbonus',
        ['templateremoval'] = 'templateremoval',
        ['categoryremoval'] = 'categoryremoval',
        ['exlink'] = 'exlink',
        ['wikidata'] = 'wikidata'
    }
}

local category_prefix = {
    ['se'] = 'se:Kategoriija',
    ['nn'] = 'nn:Kategori',
    ['no'] = 'no:Kategori',
    ['commons'] = 'commons:Category',
    ['default'] = 'Category'
}

--[ Helper methods ] ------------------------------------------------------------------

--[[ Named Parameters with Formatting Codes
     Source: <http://lua-users.org/wiki/StringInterpolation>, author:RiciLake ]]
local function sprintf(s, tab)
    return (s:gsub('%%%((%a%w*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
            function(k, fmt) return tab[k] and ("%"..fmt):format(tab[k]) or
                '%('..k..')'..fmt end))
end

local function make_error(template, arg)
    return string.format(
        '{{%s|%s}}',
        config['error_message_template'],
        string.format(messages[template], arg)
    )
end

local function parse_args(frame)
    local args = {}
    local kwargs = {}
    for k, v in pairs(frame.args) do
        v = mw.text.trim(frame:preprocess(v))
        if v ~= '' then
            if type(k) == 'number' then
                args[k] = v
            else
                kwargs[k] = v
            end
        end
    end
    return args, kwargs
end

local function shift_args(in_args)
    local args = {}
    for i, v in ipairs(in_args) do
        if i > 1 then
            args[i - 1] = v
        end
    end
    return in_args[1], args
end


local function format_plural(items, item_type)
    if #items == 0 then
        return make_error('anon_argument_missing', messages[item_type])
    end
    if #items == 1 then
        return items[1]
    end
    return mw.text.listToText(items, ', ', ' ' .. messages['or'] .. ' ')
end

local function format_plural_criterion(items, item_type)
    local value = format_plural(items, item_type)
    if #items == 0 then
        return value
    end
    if #items == 1 then
        return string.format(messages[item_type .. '_criterion_singular'], value)
    end
    return string.format(messages[item_type .. '_criterion_plural'], value)
end

local function make_template_list(args)
    local templates = {}
    for i, v in ipairs(args) do
        local lang, link = string.match(v, '^([a-z]+):(.+)$')
        if lang then
            table.insert(templates, string.format('{{%s|%s|%s}}', config['template_link_template'], link, lang))
        else
            table.insert(templates, string.format('{{%s|%s}}', config['template_link_template'], v))
        end
    end
    return templates
end

local function make_category_link(v)
    local lang = 'default'
    local name = v
    local m, n = string.match(v, '^([a-z]+):(.+)$')
    if m then
        lang = m
        name = n
    end
    return string.format('[[:%s:%s|%s]]', category_prefix[lang], name, name)
end

local function make_category_list(args)
    local category_links = {}
    for i, v in ipairs(args) do
        v = mw.text.trim(v)
        if v ~= '' then
            table.insert(category_links, make_category_link(v))
        end
    end
    return category_links
end

local function pagelist(args)
    local r = {}
    for i, v in ipairs(args) do
        v = mw.text.trim(v)
        if v ~= '' then
            local lang, page = string.match(v, '^([a-z]+):(.+)$')
            if lang then
                table.insert(r, string.format('[[:%s:%s|%s]]', lang, page, page))
            else
                table.insert(r, string.format('[[:%s]]', v))
            end
        end
    end
    return r
end

local function nslist(args)
    local r = {}
    local namespaceName = messages['article']
    for i, namespaceId in ipairs(args) do
        namespaceId = mw.text.trim(namespaceId)
        if namespaceId ~= '' then
            if namespaceId ~= "0" then
                namespaceName = '{{lc:{{ns:' .. namespaceId .. '}}}}'
            end
            table.insert(r, namespaceName)
        end
    end
    return r
end

--[ Criterion format methods ]-------------------------------------------------------------

local criterion = {}

function criterion.backlinks(args, kwargs, frame)
    return format_plural_criterion(pagelist(args), 'backlinks')
end

function criterion.bytes(args, kwargs, frame)
   return string.format(messages['bytes_criterion'], args[1])
end

function criterion.categories(args, kwargs, frame)
    local msg = format_plural_criterion(make_category_list(args), 'categories')

    if args.ignore ~= nil then
        r = mw.text.split(args.ignore, ',')
        for i, v in ipairs(r) do
            v = mw.text.trim(v)
            r[i] = make_category_link(v)
        end
        msg = msg .. string.format(messages['category_criterion_ignore'], mw.text.listToText(r, ', ', ' ' .. messages['or'] .. ' '))
    end

    return msg
end

function criterion.existing(args, kwargs, frame)
    return messages['existing_criterion']
end

function criterion.forwardlinks(args, kwargs, frame)
    return format_plural_criterion(pagelist(args), 'forwardlinks')
end

function criterion.namespaces(args, kwargs, frame)
    local site = kwargs.site
    local msg = format_plural_criterion(nslist(args, site), 'namespaces')
    if site ~= nil then
        return sprintf(messages['page_at_site'], {
            ['page'] = msg,
            ['site'] = string.format('[https://%s %s]', site, site),
        })
    end
    return msg
end

function criterion.new(args, kwargs, frame)
    local msg = messages['new_criterion']
    if kwargs.redirects ~= nil then
        msg = messages['new_criterion_with_redirects']
    end
    return msg
end

function criterion.pages(args, kwargs, frame)
    return format_plural_criterion(pagelist(args), 'pages')
end

function criterion.sparql(args, kwargs, frame)
    local query = 'SELECT ?item WHERE {\n  ' .. kwargs.query .. '\n}'
    local url = 'http://query.wikidata.org/#' .. frame:callParserFunction('urlencode', { query, 'PATH' })
    local vizUrl = 'https://tools.wmflabs.org/hay/vizquery/#' .. frame:callParserFunction('urlencode', { query, 'PATH' })

    if kwargs.description ~= nil then
        return sprintf(messages['sparql_criterion_with_explanation'], {
            description = kwargs.description,
            queryLink = url,
            vizQueryLink = vizUrl
        })
    end

    return sprintf(messages['sparql_criterion'], {
        queryLink=url,
        vizQueryLink=vizUrl
    })
end

function criterion.stub(args, kwargs, frame)
    -- deprecated
    return messages['stub_criterion']
end

function criterion.templates(args, kwargs, frame)
    return format_plural_criterion(make_template_list(args), 'templates')
end

function criterion.format(frame)
    local args, kwargs = parse_args(frame)
    local criterion_arg, args = shift_args(args)

    -- Try to find the corresponding formatter or bail out if not found
    if criterion_arg == nil then
        return frame:preprocess(make_error('argument_missing', 'criterion'))
    end
    local formatter = config.criteria[criterion_arg]
    if formatter == nil or criterion[formatter] == nil then
        return frame:preprocess(make_error('invalid_criterion', criterion_arg))
    end

    -- Use manual description if given
    if kwargs.description ~= nil and formatter ~= 'sparql' then
        return kwargs.description
    end

    -- Generate auto-generated description
    return frame:preprocess(criterion[formatter](args, kwargs, frame))
end

--[ Rule format methods ]-------------------------------------------------------------

local rule = {}

function rule.image(points, args, kwargs)
    local out
    local tplargs = {
        ['points'] = points,
    }
    if kwargs.initialimagelimit ~= nil then
        out = messages['image_rule_limited']
        tplargs['initialimagelimit'] = kwargs.initialimagelimit
    else
        out = messages['image_rule']
    end
    if kwargs.ownimage ~= nil then
        out = out .. ' ' .. messages['image_rule_own']
        tplargs['ownimage'] = kwargs.ownimage
    end
    return sprintf(out, tplargs)
end

function rule.wikidata(points, args, kwargs)
    local out
    local params
    local arg_types = { messages['properties'], messages['labels'], messages['aliases'], messages['descriptions'] }
    local results = {}
    if kwargs.properties == nil and kwargs.labels == nil and kwargs.aliases == nil and kwargs.descriptions == nil then
        return make_error(
            'argument_missing',
            mw.text.listToText( arg_types, ', ', ' ' .. messages['or'] .. ' ' )
        )
    end
    if kwargs.properties ~= nil then
        params = mw.text.split(kwargs.properties, ',')
        for k, v in pairs(params) do
            params[k] = string.format('[[:d:Property:%s|%s]]', v, v)
        end
        table.insert(results, mw.text.listToText( params, ', ', ' ' .. messages['or'] .. ' ' ))
    end
    if kwargs.labels ~= nil then
        params = mw.text.split(kwargs.labels, ',')
        table.insert(results, messages['label'] .. ' (' .. mw.text.listToText( params, ', ', ' ' .. messages['or'] .. ' ' ) .. ')')
    end
    if kwargs.aliases ~= nil then
        params = mw.text.split(kwargs.aliases, ',')
        table.insert(results, messages['alias'] .. ' (' .. mw.text.listToText( params, ', ', ' ' .. messages['or'] .. ' ' ) .. ')')
    end
    if kwargs.descriptions ~= nil then
        params = mw.text.split(kwargs.descriptions, ',')
        table.insert(results, messages['description'] .. ' (' .. mw.text.listToText( params, ', ', ' ' .. messages['or'] .. ' ' ) .. ')')
    end
    results = table.concat( results, ' ' .. messages['and'] .. ' ' )
    if kwargs.all ~= nil then
        out = messages['wikidata_rule_all']
    else
        out = messages['wikidata_rule_first']
    end
    if kwargs.require_reference ~= nil then
        out = out .. ' ' .. messages['wikidata_rule_require_reference']
    end
    return sprintf(out, {
        ['points'] = points,
        ['thing'] = results,
    })
end

function rule.reference(points, args, kwargs)
    return sprintf(messages['reference_rule'], {
        ['points'] = points,
        ['refpoints'] = args[1],
    })
end

function rule.templateremoval(points, args, kwargs)
    local templates = format_plural(make_template_list(args), 'templates')
    return sprintf(messages['templateremoval_rule'], {
        ['points'] = points,
        ['templates'] = templates,
    })
end

function rule.categoryremoval(points, args, kwargs)
    local categories = format_plural(make_category_list(args), 'categories')
    return sprintf(messages['categoryremoval_rule'], {
        ['points'] = points,
        ['categories'] = categories,
    })
end

function rule.bytebonus(points, args, kwargs)
    return sprintf(messages['bytebonus_rule'], {
        ['points'] = points,
        ['bytes'] = args[1],
    })
end

function rule.wordbonus(points, args, kwargs)
    return sprintf(messages['wordbonus_rule'], {
        ['points'] = points,
        ['words'] = args[1],
    })
end

function rule.format(frame)
    -- Make tables of anonymous and named arguments
    local args, kwargs = parse_args(frame)
    rule_arg, args = shift_args(args)
    points, args = shift_args(args)

    -- Try to find the corresponding formatter or bail out if not found
    if rule_arg == nil then
        return frame:preprocess(make_error('argument_missing', 'rule'))
    end
    local formatter = config.rules[rule_arg]
    if formatter == nil then
        return frame:preprocess(make_error('invalid_rule', rule_arg))
    end

    -- All rules requires argument 1: number of points awarded
    if points == nil then
        return frame:preprocess(make_error('argument_missing', '1 (number of points)'))
    end

    points = points:gsub( '%.', config['decimal_separator'])

    -- If there's a rule formatter function, use it.
    -- Otherwise, use the string from the messages table.
    local out
    if rule[formatter] ~= nil then
        out = rule[formatter](points, args, kwargs)
    else
        out = sprintf(messages[formatter .. '_rule'], {
            ['points'] = points,
        })
    end

    if kwargs.max ~= nil then
        out = sprintf(messages['base_rule_max'], {
            ['baserule'] = out,
            ['maxpoints'] = kwargs.max:gsub( '%.', config['decimal_separator']),
        })
    end

    return frame:preprocess(out)
end

-- Export
return {
    ['criterion'] = criterion.format,
    ['rule'] = rule.format,
}