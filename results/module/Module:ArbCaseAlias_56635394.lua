local me = { }

-- mw.loadData doesn't support loading data that has function type, so use require
local config = require('Module:ArbCaseAlias/data')

local function sortByLastPart(a, b)
	local lastPartPattern = '([^-]+)$'
	local aLastPart = string.match(a, lastPartPattern)
	local bLastPart = string.match(b, lastPartPattern)
	return tonumber(aLastPart) < tonumber(bLastPart)
end

local function reverseNumericCompare(a, b)
	return tonumber(a) > tonumber(b)
end

function me.luaListCases(args)
	local outputBuffer = { }
	local primaryCategories = { }
	for primaryCategory, caseInfoForCategory in pairs(config.arbCaseAliasInfo.caseInfoFor) do
		-- skip test year 1000
		if (primaryCategory ~= '1000') then
			table.insert(primaryCategories, primaryCategory)
		end
	end
	if (args['order'] == 'reverseyear') then
	    table.sort(primaryCategories, reverseNumericCompare)
	else
	    table.sort(primaryCategories)
	end
	for index, primaryCategory in pairs(primaryCategories) do
		table.insert(outputBuffer, '* ' .. primaryCategory .. '\n')
		local outputForCaseAlias = { }
		local caseAliases = { }
		for caseName, caseInfo in pairs(config.arbCaseAliasInfo.caseInfoFor[primaryCategory]) do
			outputForCaseAlias[caseInfo.byYear] = '** ' .. caseInfo.byYear .. ' — ' .. caseName .. '\n'
			table.insert(caseAliases, caseInfo.byYear)
		end
		table.sort(caseAliases, sortByLastPart)
		for caseAliasIndex, caseAlias in pairs(caseAliases) do
			table.insert(outputBuffer, outputForCaseAlias[caseAlias])
		end
	end
	return table.concat(outputBuffer)
end

function me.listCases(frame)
	local args = require('Module:Arguments').getArgs(frame)
	return me.luaListCases(args) or ''
end

function me.luaMain(args)
	local alias = args[1] or ''

    local primaryCategory = config.arbCaseAliasInfo.extractPrimaryKey(alias)
    if (primaryCategory == nil) then
    	return alias
    end

    if (config.arbCaseAliasInfo.caseInfoFor[primaryCategory] == nil) then
    	return alias
    end

	local aliasFor = { }
	for format, normalizer in pairs(config.arbCaseAliasInfo.normalizeAlias)	do
		local normalizedAlias = normalizer(alias)
		if (normalizedAlias ~= nil) then
			aliasFor[format] = normalizedAlias
		end
	end  -- loop over normalizers

	for caseName, caseInfo in pairs(config.arbCaseAliasInfo.caseInfoFor[primaryCategory]) do
		for format, caseAlias in pairs(caseInfo) do
			if (aliasFor[format] == caseAlias) then
				return caseName
			end
		end  -- loop over different case aliases
	end  -- loop over cases for given primary category

	-- failed to find a match
	return alias
end

function me.main(frame)
	local args = require('Module:Arguments').getArgs(frame)
	return me.luaMain(args) or ''
end


return me