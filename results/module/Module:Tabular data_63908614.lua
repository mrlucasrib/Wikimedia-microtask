local p = {}
local lang = mw.getContentLanguage()
local navbar = require("Module:Navbar")

local messages = {
	["true"] = "Yes",
	["false"] = "No",
	null = "N/A",
}

local bgColors = {
	["true"] = "#9f9",
	["false"] = "#f99",
	null = "#ececec",
}

local colors = {
	null = "#2c2c2c",
}

function p._cell(args)
	local data = args.data or mw.ext.data.get(args[1])
	local rowIdx = tonumber(args.output_row)
	local outputFormat = args.output_format
	
	local outputColumnNames = {
		args.output_column1 or args.output_column,
	}
	while args["output_column" .. #outputColumnNames + 1] do
		table.insert(outputColumnNames, args["output_column" .. #outputColumnNames + 1])
	end
	
	local outputColumnIdxs = {}
	local numOutputColumnIdxs = 0
	for i, field in ipairs(data.schema.fields) do
		for j, outputColumnName in ipairs(outputColumnNames) do
			if field.name == outputColumnName then
				outputColumnIdxs[outputColumnName] = i
				numOutputColumnIdxs = numOutputColumnIdxs + 1
			end
		end
		if numOutputColumnIdxs == #outputColumnNames then
			break
		end
	end
	if numOutputColumnIdxs < #outputColumnNames then
		for i, outputColumnName in ipairs(outputColumnNames) do
			assert(outputColumnIdxs[outputColumnName],
				mw.ustring.format("Output column “%s” not found.", outputColumnName))
		end
	end
	
	if rowIdx > 0 then
		rowIdx = (rowIdx - 1) % #data.data + 1
	elseif rowIdx < 0 then
		rowIdx = rowIdx % #data.data + 1
	else
		error("0 is not a valid row index.")
	end
	
	local record = data.data[rowIdx]
	if record ~= nil then
		if outputFormat or numOutputColumnIdxs > 1 then
			local values = {}
			for i, columnName in ipairs(outputColumnNames) do
				local columnIdx = outputColumnIdxs[columnName]
				table.insert(values, record[columnIdx])
			end
			if outputFormat then
				return mw.ustring.format(outputFormat, unpack(values))
			else
				return mw.text.listToText(values)
			end
		else
			local columnIdx = outputColumnIdxs[outputColumnNames[1]]
			return record[columnIdx]
		end
	end
end

--- Returns the value of the cell at the given row index and column name.
--- A row index of 1 refers to the first row in the table. A row index of -1
--- refers to the last row in the table. It is an error to specify a row index
--- of 0.
--- Usage: {{#invoke:Tabular data | cell | Table name | output_row = Index of row to output | output_column = Name of column to output }}
function p.cell(frame)
	return p._cell(frame.args)
end

function p._lookup(args)
	local data = args.data or mw.ext.data.get(args[1])
	local searchValue = args.search_value
	local searchPattern = args.search_pattern
	local searchColumnName = args.search_column
	
	local searchColumnIdx
	for i, field in ipairs(data.schema.fields) do
		if field.name == searchColumnName then
			searchColumnIdx = i
		end
		if searchColumnIdx then
			break
		end
	end
	assert(searchColumnIdx, mw.ustring.format("Search column “%s” not found.", searchColumnName))
	
	local occurrence = tonumber(args.occurrence) or 1
	
	local numMatchingRecords = 0
	for i = (occurrence < 0 and #data.data or 1),
		(occurrence < 0 and 1 or #data.data),
		(occurrence < 0 and -1 or 1) do
		local record = data.data[i]
		if (searchValue and record[searchColumnIdx] == searchValue) or
			(searchPattern and mw.ustring.match(tostring(record[searchColumnIdx]), searchPattern)) then
			numMatchingRecords = numMatchingRecords + 1
			if numMatchingRecords == math.abs(occurrence) then
				local args = mw.clone(args)
				args.data = data
				args.output_row = i
				return p._cell(args)
			end
		end
	end
end

--- Returns the value of the cell(s) in the given output column(s) of the row
--- matching the search key and column.
--- Reminiscent of LOOKUP() macros in popular spreadsheet applications, except
--- that the search key must match exactly. (On the other hand, this means the
--- table does not need to be sorted.)
--- Usage: {{#invoke: Tabular data | lookup | Table name | search_value = Value to find in column | search_pattern = Pattern to find in column | search_column = Name of column to search in | occurrence = 1-based index of the matching row to output | output_column = Name of column to output | output_column2 = Name of another column to output | … | output_format = String format to output the values in }}
function p.lookup(frame)
	return p._lookup(frame.args)
end

function p._wikitable(args)
	local pageName = args[1]
	local data = mw.ext.data.get(pageName)
	
	local datatypes = {}
	
	local htmlTable = mw.html.create("table")
		:addClass("wikitable sortable")
	htmlTable
		:tag("caption")
		:wikitext(navbar.navbar({
			template = ":c:Data:" .. pageName,
			mini = "y",
			style = "float: right;",
			"view", "edit",
		}))
		:wikitext(data.description)
	
	local headerRow = htmlTable
		:tag("tr")
	for i, field in ipairs(data.schema.fields) do
		headerRow
			:tag("th")
			:attr("scope", "col")
			:attr("data-sort-type", datatypes[j] == "text" and "string" or datatypes[j])
			:wikitext(field.title)
		datatypes[i] = field.type
	end
	
	for i, record in ipairs(data.data) do
		local row = htmlTable:tag("tr")
		for j = 1, #data.schema.fields do
			local cell = row:tag("td")
			if record[j] then
				local formattedData = record[j]
				if datatypes[j] == "number" then
					formattedData = lang:formatNum(formattedData)
					cell:attr("align", "right")
				elseif datatypes[j] == "boolean" then
					cell
						:addClass(record[j] and "table-yes" or "table-no")
						:css({
							background = record[j] and bgColors["true"] or bgColors["false"],
							color = record[j] and colors["true"] or colors["false"],
							["vertical-align"] = "middle",
							["text-align"] = "center",
						})
						:wikitext(record[j] and messages["true"] or messages["false"])
				end
				cell:wikitext(formattedData)
			else
				cell
					:addClass("mw-tabular-value-null")
					:addClass("table-na")
					:css({
						background = bgColors.null,
						color = colors.null,
						["vertical-align"] = "middle",
						["text-align"] = "center",
					})
					:wikitext(messages.null)
			end
		end
	end
	
	local footer = htmlTable
		:tag("tr")
		:tag("td")
		:addClass("sortbottom")
		:attr("colspan", #data.schema.fields)
	footer:wikitext(data.sources)
	footer:tag("br")
	
	local licenseText = mw.message.new("Jsonconfig-license",
		mw.ustring.format("[%s %s]", data.license.url, data.license.text))
	footer
		:tag("i")
		:wikitext(tostring(licenseText))
	
	return htmlTable
end

--- Returns a tabular data page as a wikitext table.
--- Usage: {{#invoke:Tabular data | wikitable | Table name }}
function p.wikitable(frame)
	return p._wikitable(frame.args)
end

return p