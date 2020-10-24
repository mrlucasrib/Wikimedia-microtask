local p = {}

function p.main(frame)

local args = require('Module:Arguments').getArgs(frame,{removeBlanks=false})

local list = ""
if args[1] then
  list = mw.html.create('table')
  list:css("background-color","#ecfcf4")
  for n,c in ipairs(args) do
    if c~="" then
      local title = mw.title.new("Template:Country data "..c)
      local link
      if title.isRedirect then
        link = "["..title:fullUrl("redirect=no").." "..title.fullText.."]"
      else
        link = "[["..title.fullText.."]]"
      end
      local var = args["var"..n] or ""
      local vartext = var=="" and "" or " (<code>"..var.."</code> variant)"
      local note = args["note"..n] or ""

      local row = list:tag("tr")
      row:tag("td"):css("padding","0px 10px"):addClass("plainlinks"):wikitext(link..vartext)
      row:tag("td"):css("padding","0px 10px"):wikitext(require("Module:Flagg").luaMain(frame,{"usc", c, variant=var}))
      row:tag("td"):css("padding","0px 10px"):wikitext(note)
    end
  end
end

local head = ""
if args["header"] and args["header"]~="" then
  if args["header"]=="related" then
    head = "====Related templates====\nPlease see the following related <code>country_data</code> templates:"
  elseif string.sub(args["header"],1,4)=="for:" then
    head = "<code>Country_data</code> templates are also available for "..string.sub(args["header"],5,-1)..":"
  else
    head = args["header"]
  end
end

return head..(head~="" and list~="" and "\n" or "")..tostring(list)

end

return p