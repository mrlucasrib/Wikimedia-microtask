-- replacement for Template:Bar chart
local p = {}

function p.main(frame)
	local pframe = frame:getParent()
	local args = pframe.args
	
	local bar = mw.html.create("table")
	bar
		:addClass("BarChartTemplate" .. (args.class or ""))
		:css({
			width = (table_width or "") .. (width_units or "em"),
			["border-style"] = "solid",
			["border-width"] = "1px",
			["border-color"] = "#c0c0c0",
			["background-color"] = "#fdfdfd",
			["text-align"] = "left",
			})
		:attr("cellpadding", "1")
		:tag("tr")
			:tag("caption")
				:css({
					["font-weight"] = "bold",
					["text-align"] = "center"
				})
				:wikitext((args.title or "List of cities by population"))
				:done()
			:done()
		:tag("th")
			:attr("scope", "col")
			:wikitext((args.label_type or "City"))
			:css("font-weight", "bold")
			:done()
	if args.table_width then bar:css("width", args.table_width .. (args.width_units or "em")) end
	if args.class then bar:addClass(args.class) end
	if args.table_style then bar:cssText(args.table_style) end
	if args.float then
		if args.float == "left" then 
			bar:css({float = "left", clear = "left", margin = "0.5em 1em 0.5em 0"}) 
		elseif args.float == "right" then 
			bar:css({float = "right", clear = "right", margin = "0.5em 0 0.5em 1em"})
		elseif args.float == "center" then 
			bar:css({float = "none", ["margin-left"] = "auto", ["margin-right"] = "auto"}) 
		end
	end
	
	if args.data_type ~= nil and args.col1data_type == nil then
		args.col1data_type = args.data_type
	elseif args.data_type == nil and args.col1data_type == nil then
		args.col1data_type = "Population"
	end
	local i = 1
	while args["col" .. i .. "_data_type"] do
		local coltype = mw.html.create("th")
		coltype
			:attr("scope", "row")
			:css("font-weight", "bold")
			:wikitext(args["col" .. i .. "_data_type"])
			:done()
		if args.bar_width then 
			coltype:css("width", args.bar_width .. (args.width_units or "em")) 
		end
		bar:node(coltype)
		i = i + 1
	end
	
	bar:tag('tr', {unclosed = true})
	local m = 1
	while args["label" .. m] ~= nil do
		m = m + 1
	end
	
	if args["label1"] ~= nil then
		local collabel1 = mw.html.create("td")
		collabel1
			:css("font-size", "11px")
			:wikitext(args["label1"])
			:done()
		bar:node(collabel1)
	end
	if args["data1"] ~= nil then
		args["col1_data1"] = args["data1"]
	end
	local z = 1
	while args["col" .. z .. "_data1"] ~= nil and z < 7 do
		local coldata = mw.html.create("td")
		coldata
			:attr("rowspan", m)
			:wikitext(frame:extensionTag("graph", column(z, args)))
			:done()
		bar:node(coldata)
		z = z + 1
	end
	bar:tag('tr', {unclosed = true})
	local k = 2
	for k=2,m do
		local collabel = mw.html.create("tr")
		collabel
			:tag("td")
				:css("font-size", "11px")
				:wikitext(args["label" .. k])
				:done()
			:done()
		bar:node(collabel)
		k = k + 1
	end
	bar:tag('tr', {unclosed = true})
	local v = 1
	if args.col1_total then
		totaltr = mw.html.create("td")
		totaltr
			:attr("scope", "row")
			:css("font-weight", "bold")
			:wikitext("Total")
		while args["col" .. v .. "_total"] ~= nil do
			local totaltd = mw.html.create("td")
			totaltd
				:wikitext(formnum(args["col" .. v .. "_total"]))
				:css("font-weight", "bold")
				:done()
			totaltr:node(totaltd)
			v = v + 1
		end
		bar:node(totaltr)
	end

	
	bar:allDone()
	return tostring(bar)
end

function column(z, args)
	local gen = {}
	local datanum = {}
	local z = z
	local r = 1
	while args["col" .. z .. "_comment" .. r] ~= nil do
		args["col" .. z .. "_comment" .. r] = "(" .. args["col" .. z .. "_comment" .. r] .. ")"
		r = r + 1
	end
	local o = 1
	while args["comment" .. o] ~= nil do
		args["comment" .. o] = "(" .. args["comment" .. o] .. ")"
		o = o + 1
	end
	
	local n = 1
	if z == 1 then
		while args["label" .. n] ~= nil and args["col1_data" .. n] ~= nil or args["data" .. n] ~= nil do
			table.insert(gen, {t = args["label" .. n], v = parsenumber((args["col1_data" .. n] or args["data" .. n])), 
				e = (args["col1_data" .. n] or args["data" .. n]) .. " " .. (args["col1_comment" .. n] or  args["comment" .. n] or "")})
			table.insert(datanum, parsenumber((args["col1_data" .. n] or args["data" .. n]))) 
			n = n + 1
		end
	else
		while args["label" .. n] ~= nil and args["col" .. z .. "_data" .. n] ~= nil do
			table.insert(gen, {t = args["label" .. n], v = parsenumber(args["col" .. z .. "_data" .. n]), 
				e = args["col" .. z .. "_data" .. n] .. " " .. (args["col" .. z .. "_comment" .. n] or "")})
			table.insert(datanum, parsenumber(args["col" .. z .. "_data" .. n])) 
			n = n + 1
		end
	end
	
	if args.bar_width  ~= nil and tonumber(args.bar_width) then
		args.bar_width = units(math.max(args.bar_width, 22), (args.width_units or ""))
	else
		args.bar_width = 22
	end
	totalheight = args.bar_width * n
	
	local scale = {
    {
      name = "x",
      range = "width",
      domain = {data = "table", field = "v"}
    },
    {
      name = "y",
      range = "height",
      type = "ordinal",
      domain = {data = "table", field = "t"}
    }
  }
  if z == 1 then
  	if args["col1_data_max"] or args["data_max"] then scale[1].domainMax = units(parsenumber(args["col1_data_max"] or args["data_max"])) end
  else
  	if args["col" .. z .. "_data_max"] then scale[1].domainMax = units(parsenumber(args["col" .. z .. "_data_max"])) end
  end
  	
	local output = {
  version = 2, width = 200, height = totalheight,
  autosize = {
    type = "fit",
    contains = padding
  },
  data = {
    {
      name = "table",
      values = gen
    }
  },
  scales = scale,
  marks = {
    {
     type = "rect",
     from = {data = "table"},
      properties = {
        enter = {
          y = {scale = "y", field = "t"},
          height = {scale = "y", band = true, offset = -1, strokeWidth = args.bar_width},
          x = {scale = "x", value = 0},
          x2 = {scale = "x", field = "v"}
        },
        update = {
          fill = {
            r = {value = 206},
            g = {value = 223},
            b = {value = 242}
          }
        }
      }
    },
    {
      type = "text",
      properties = {
        enter = {
          baseline = {value = "middle"},
          text = {field = "e"},
          align = {value = "center"},
          y = {scale = "y", offset = 6, field = "t"},
          dx = {scale = "x", field = "v"},
          x = {scale = "x", value = 0},
          angle = {value = 0},
          fontSize = {value = 14},
          fill = {value = "black"}
        }
      },
      from = {data = "table"}
    }
  }
}

	return mw.text.jsonEncode(output)
end

function units(size, unit)
	if unit == "em" then
		return size * 1.1
	else
		return size
	end
end

function formnum(s)
	return tostring(s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

function parsenumber(g)
	return tonumber(tostring(string.gsub(g, ",", "")))
end

return p