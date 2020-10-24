local p={}

function p.main(frame)
   local args=frame.args or {}
   local parent=frame.getParent(frame) or {}
   local pargs=parent.args or {}
   local textinput=args[1] or pargs[1] or ""
   local nowiki=args.nowiki or pargs.nowiki or nil
   local totalwidth=args.width or pargs.width or 220
   local totalheight=args.height or pargs.height or 200
   local debug=args.debug or pargs.debug
   local debuglog=""
    --- Allow searching of all text to end with:
   textinput=textinput.."<Module:Block diagram internal end token:END>"
    --- Give all RECOGNIZED markup a consistent searchable string
    --- more styling should be added; seeking a first proof of concept now
   local taglist={'left','top','right','bottom','color','background-color','text-align','vertical-align','vcentertext','border-style','border-color','border-width'}
   for i,v in pairs(taglist) do
       local vn=mw.ustring.gsub(v,"%-","") --- remove dashes from standard html attribute names to allow internal use
       local vs=mw.ustring.gsub(v,"%-","%-") -- escape those hyphens for pattern search
       textinput=mw.ustring.gsub(textinput,"<"..vs.."%s*([^>]*)>","<Module:Block diagram internal "..vn.." token:%1>")
       debuglog=debuglog..v..vs..vn..textinput
   end
   prowl=mw.ustring.gmatch(textinput,"(.-)<Module:Block diagram internal (%S+) token:([^>]*)>")
   local tableoutput={}
   local text,tag,value
   local default={}
   default['left']=0
   default['right']=100
   default['top']=0
   default['bottom']=100
   default['borderstyle']='solid'
   default['borderwidth']='1px'
   default['bordercolor']='black'
   default['color']='black'
   default['backgroundcolor']='white' -- elements should usually block elements behind them, like grid lines
   default['textalign']='center'
   default['verticalalign']='middle' -- pseudo html value, but this needs a special hack to work
   default['vcentertext']=''
   for i,j in pairs(default) do
      _G[i]=j
      debuglog=debuglog..i..j
   end
   repeat
      text,tag,value = prowl(textinput)
      debuglog=debuglog..(text or "nil")..(tag or "nil")
      if not tag then return debuglog end
      if (text or "")~="" then
         table.insert(tableoutput,'<div style="position:absolute;top:')
         table.insert(tableoutput,top)
         table.insert(tableoutput,'%;bottom:')
         table.insert(tableoutput,100-bottom)
         table.insert(tableoutput,'%;left:')
         table.insert(tableoutput,left)
         table.insert(tableoutput,'%;right:')
         table.insert(tableoutput,100-right)
         table.insert(tableoutput,'%;border-style:')
         table.insert(tableoutput,borderstyle)
         table.insert(tableoutput,';border-width:')
         table.insert(tableoutput,borderwidth)
         table.insert(tableoutput,';border-color:')
         table.insert(tableoutput,bordercolor)
         table.insert(tableoutput,';color:')
         table.insert(tableoutput,color)
         table.insert(tableoutput,';background-color:')
         table.insert(tableoutput,backgroundcolor)
         table.insert(tableoutput,';">')
         if textalign~='center' then
             table.insert(tableoutput,';text-align:'..textalign)
         end
         if verticalalign=='top' then
             table.insert(tableoutput,text)
         else
             table.insert(tableoutput,'{{vertical center|1=')
             table.insert(tableoutput,text)
             if vcentertext then table.insert(tableoutput,'|3='..vcentertext) end
             table.insert(tableoutput,'}}')
         end
         table.insert(tableoutput,'</div>')
      end
      _G[tag]=value or default[tag]
   until tag=="end"
   local textoutput=table.concat(tableoutput)
   textoutput='<div style="position:relative;text-align:center;top:0;left:0;width:'..totalwidth..'px;height:'..totalheight..'px;">'..textoutput..'</div>'
   if nowiki then textoutput=frame:preprocess("<pre><nowiki>"..textoutput.."</nowiki></pre>") else textoutput=frame:preprocess(textoutput) end
   if debug then textoutput=textoutput..debuglog end
   return textoutput
end

return p