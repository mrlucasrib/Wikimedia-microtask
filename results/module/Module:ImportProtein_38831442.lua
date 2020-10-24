local p = {}

function p.main (frame)
    ---- Set up the initial frame parameters
   local debuglog="|}|}"
   local args=frame.args
   local parent=frame.getParent(frame)
   local pargs={}
   if parent then pargs=parent.args end
   local height=args.height or pargs.height or "50"
   local width=args.width or pargs.width or "600"
   local background=args.background or pargs.background or "#333333"
   local vtext=args.vtext or pargs.vtext or 25 -- characters of legend text to display vertically down from motifs
   local largeonlyregion=args.largeonlyregion or pargs.largeonlyregion or 20
   local vtext=tonumber(vtext) -- no meaning except as a number
   local tableoutput=args.tableoutput or pargs.tableoutput or "collapsed" -- I've decided to use the table as the legend much of the time after all, I think.  (previously defaulted to "nil" to suppress)
   if tableoutput=="no" then tableoutput=nil end
   local vwidth=args.vwidth or pargs.vwidth or 4 -- number of PIXELS to tag as not overwriteable with vertical text.
   local vclaim={} --- if vclaim[pixel] is true, that pixel is taken
   local vprotest='' --- list of positions not shown separated by spaces
   local nowiki=args.nowiki or pargs.nowiki
   
    ---- These parameters send text that needs to be processed into tables
    ---- include is nil to include everything.  If it exists then only what is in it is used.
    ---- format is "I want only this" (any junk) "and this" etc.  Note weakness - a stray quote would foul up the whole template.
   local include=args.include or pargs.include or "all"
   if include == "all" then include = nil end
   local tinclude={}
   if include then
      for i in mw.ustring.gmatch(include,[[%"(.-)%"]]) do
         tinclude[i]=1
      end
   end
    ---- replaceregion defines a section with too many features to note individually.
    ---- Instead you group them with a new text.
    ---- The format is xx..yy:"Use this text"
   local replaceregion=args.replaceregion or pargs.replaceregion or ""
   local treplaceregion={}
      treplaceregion.s={};treplaceregion.e={};treplaceregion.t={}
      for i,j,k in mw.ustring.gmatch(replaceregion,[[(%d+)%.%.(%d+):%"(.-)%"]]) do
          table.insert(treplaceregion.s,tonumber(i));table.insert(treplaceregion.e,tonumber(j));table.insert(treplaceregion.t,tostring(k))
      end
    ---- exclude "Forget about this" (junk between ignored).
    ---- this prevents things from showing up even in the table and all motifs of this kind
   local exclude=args.exclude or pargs.exclude or "" -- for these empty arrays will be ignored later.
   local texclude={}
   for i in mw.ustring.gmatch(exclude,[[%"(.-)%"]]) do
      texclude[i]=1
   end
    ---- usenotes "This is a crummy motif name" (junk between ignored).  Uses /note entries instead
   local usenotes=args.usenotes or pargs.usenotes or ""
   local tusenotes={}
   for i in mw.ustring.gmatch(usenotes,[[%"(.-)%"]]) do
      tusenotes[i]=1
   end
    ---- substitute "Don't like this wording":"That's what I want" (anything between these ignored)
   local substitute=args.substitute or pargs.substitute or ""
   local tsubstitute={}
   for i,j in mw.ustring.gmatch(substitute,[[%"(.-)%":%"(.-)%"]]) do
      tsubstitute[i]=j
   end
    ---- toprow "Put this motif in the top row, no vertical annotation"
    ---- If present, defines an upper part of the graphic to mark certain features by color only - most likely, helices and sheets and turns
   local toprowtext=args.toprow or pargs.toprow or ""
   local ttoprow={}
   local toprowheight=0 -- no height unless one exists
   local toprow -- boolean to mark if anything is actually on the top row
   for i in mw.ustring.gmatch(toprowtext,[[%"(.-)%"]]) do
      ttoprow[i]=1;toprow=true
   end
   if toprow then toprowheight=args.toprowheight or pargs.toprowheight or 10 end
    ---- Check there is a protein sequence file and figure out where the CDS in it starts and ends
   local file=args.file or pargs.file
   if not(file) then return "error: use 'file=some cut-and-pasted NCBI protein sequence' to input a protein to be diagrammed" end
   local cdsstart, cdsend = mw.ustring.match(file,"Protein%s-(%d+)%.%.(%d+)")
   cdsstart=tonumber(cdsstart);cdsend=tonumber(cdsend)
   if ((cdsstart<1) or (cdsend<1)) then return [[error: the module expected a line "Protein: ''start amino acid''..''end amino acid''" to define the CDS.]] end
   local cdswidth=cdsend-cdsstart
    ---- Find and replace Site and Region to create unique separators
    ---- so that every one of these sections can be individually processed in the main loop
   file = mw.ustring.gsub(file,"Site%s+","|##|S") -- there are no pipe characters in the input or it would have choked
   file = mw.ustring.gsub(file,"Region%s+","|##|R")
   file = mw.ustring.gsub(file,"$","|##|") --- close last feature at the EOF
    ---- Load a set of colors to use for the different motifs.
    ---- Any unicode separator changes them.  No format expectations.
   local colorpage=mw.title.new("Template:ImportProtein/DefaultColors")
   local content
   local color={}
   if colorpage then
       content=colorpage.getContent(colorpage)
       if content then
          for x in mw.ustring.gmatch(content,"(%S+)") do
              table.insert(color,x)
          end
       end
   end
   if #color<1 then color={"#000055","#000099","#0000CC","#0000FF","#550055","#550099","#5500CC","#5500FF","#990055","#990099","#9900CC","#9900FF","#CC0055","#CC0099","#CC00CC","#CC00FF","#FF0000","#FF0055","#FF0099","#FF00CC","#FF00FF","#005555","#005599","#0055CC","#0055FF","#55555","#555599","#5555CC","#5555FF","#995555","#995599","#9955CC","#9955FF","#CC5555","#CC5599","#CC55CC","#CC55FF","#FF5500","#FF5555","#FF5599","#FF55CC","#FF55FF"} end
   local claim={};local nextcolor=1 -- keeps track of the colors assigned to specific nkeys throughout the loop
       ---- Begin the output and graphics files
   local output
   local tlegend="" -- legend for top row entries only, shown above table
   if tableoutput=="collapsed" then output=[[{| class="wikitable collapsible collapsed" style="width:]].. width .. [[px;"]] .. "\n" .. [[!colspan=4|List of protein features]] .. "\n" .. [[|-]] else if tableoutput=="collapsible" then output=[[{| class="wikitable collapsible" style="width:]].. width .. [[px;"]] .. "\n" .. [[!colspan=4|List of protein features]] .. "\n" .. [[|-]] else output=[[{| class="wikitable"]] end end
   local graphics=[[<div style="position:relative;background-color:]].. background .. [[;width:]] .. width .. [[px;height:]] .. height .. [[px;">]]
    ---- MAIN LOOP ----
    ---- this goes through features one by one and marks them down in "output" (legend/table) and "graphics" (protein box and vertical annotation)
    ---- Note that this does NOT create an array of features to sort, but is purely once through.
    ---- This means, for example, that there is no easy way to reposition adjacent motifs left and right to fit automatically.
    ---- You could, of course, array the output and retroactively process it ... maybe even turn this into a sortable array of function tail calls???  (My head hurts)
   for feature, range in mw.ustring.gmatch(file,"#|(.-)|#") do
       local t=mw.ustring.match(feature,"^(%a)") -- S or R placed in previous find/replace
       local s=mw.ustring.match(feature,"(%d+)") -- first number is the beginning of site or region
       local e=mw.ustring.match(feature,"^.%s-%d+%.%.(%d+)") or s -- second number in xx..yy range ; this needs updating!
 
       if s then
           ---- decide on the name to be used for the motif and annotation
          local n,c
          if t=="R" then n=mw.ustring.match(feature,[[/region_name=%"(.-)%"]]) end
          if t=="S" then n=mw.ustring.match(feature,[[/site_type=%"(.-)%"]]) end
          n=tostring(n)
          if tusenotes[n] then n=mw.ustring.match(feature,[[/note=%"(.-)%"]]) or n end
          n=tostring(n)
          n=mw.ustring.match(n,"^%s+(.+)%s+$") or n -- kill white space
          n=mw.ustring.gsub(n,"\n"," ") or n -- remove line feeds
          n=tostring(n) -- am I paranoid?
          if tsubstitute[n] then n=tostring(tsubstitute[n]) end
          n = mw.ustring.match(n,"(.+)%.") or n -- Don't need the ubiquitous final periods
           ---- from the name (n) pull out an nkey that excludes parenthesized stuff
           ---- each unique nkey can claim its own color to use from here on out
          local nkey=mw.ustring.match(n,"(.+)[%.;,%(%[]") or n
          local newcolor=false; -- is this a new color (if so, then if it is toprow, then add to legend for those)
          if claim[nkey] then c=claim[nkey] else c=color[nextcolor];claim[nkey]=c;nextcolor=nextcolor+1;newcolor=true end
          local cstyle=[[style="color:]] .. c .. [[;"|]]
           ---- decide whether to show the motif, and crop it to the CDS
          local showthismotif=true
          s=tonumber(s);e=tonumber(e)
          if s<cdsstart then s=cdsstart end
          if e>cdsend then e=cdsend end
          if s==cdsstart and e==cdsend then showthismotif=nil end
          if include then if not (tinclude[n]) then showthismotif=nil end end -- if include is set, and n isn't in it, don't add to table or graphic
          if exclude then if texclude[n] then showthismotif=nil end end -- if exclude is set and n is in it don't add
          if showthismotif then
              ---- update the table output for the legend
             if tostring(t)=="R" then output = output .. "\n|" .. cstyle .. "region\n|" else output = output .. "\n|" .. cstyle .. "site\n|" end
             output = output .. cstyle .. tostring(s) .. "\n|" .. cstyle .. tostring(e) .. "\n|" .. cstyle .. n .. "\n|-"
              ---- update the graphic display: first determine if the block is large to be displayed full height and annotated inside itself
             nkey=mw.ustring.sub(nkey,1,vtext) -- for graphics purposes, truncate the string (default 25 characters)
             local large
             local boxleft=math.floor(width*tonumber(s)/cdswidth)
             local boxwidth=math.floor(width*tonumber(e)/cdswidth)-boxleft
             if boxwidth>8*tonumber(mw.ustring.len(nkey)) then large=true else large=nil end
              ---- then work out the horizontal or vertical display
             local vertical -- height substring of the drawn block
             local annot="" -- text contents of a large block
             if ttoprow[n] then
                vertical=tostring(toprowheight)
                if newcolor then tlegend=tlegend..[[<span style="background-color:]] .. c .. [[;">&nbsp;&nbsp;</span> ]] .. nkey .. "\n" end
                nkey=""
             else
                if large then
                    vertical=tostring(height-toprowheight)
                    if toprow then vertical=vertical .. "px;top:" .. tostring(toprowheight) end
                    annot="'''" .. nkey .."'''"
                    nkey="" -- no vertical text display
                else vertical=tostring(math.floor(height) - toprowheight - largeonlyregion) .. "px;top:" .. tostring(toprowheight + largeonlyregion)
                    nkey=mw.ustring.gsub(nkey,"(.)","%1<br />") -- verticalize the text 
                end
             end
             local z=10000-1*boxwidth --- smaller elements in front of larger ones
             if not(large) then z=z+10000 end --- large elements reliably to the back
               -- draw graphics within the protein rectangle
             graphics = graphics .. [[<div style="position:absolute;overflow:hidden;z-index:]] .. z .. [[;left:]] .. boxleft .. [[px;border-top:0px;border-bottom:0px;border-left:1px;border-right:1px;border-style:solid;border-color:]].. c .. [[;background-color:]].. c .. [[;width:]] .. boxwidth .. [[px;height:]] .. vertical .. [[px;text-align:center;">]] .. annot .. [[</div>]]
               -- draw annotations vertically below it
               -- don't do at all if no text (nkey=="", such as on the top row)
             if not (nkey=="") then
                  -- first decide if in a replaceregion - if so, don't draw
                local toreplace;local ri=1
                while treplaceregion.s[ri] do
                   local rs=treplaceregion.s[ri]
                   local re=treplaceregion.e[ri]
                   if s>=rs and e<=re then toreplace=true;break end
                   ri=ri+1
                end          
                if not toreplace and not large then 
                    --- center vt in the feature; then claim pixels one by one around it.
                    --- Don't draw in a claimed pixel, but file a protest at bottom.
                   local vt=math.floor(boxleft+boxwidth/2 - 2) -- vertical text's horizontal position
                   if not vclaim[vt] then
                      for i = vt-vwidth,vt+vwidth,1 do
                          vclaim[i]=true
                      end
                      graphics = graphics .. [[<span style="position:absolute;text-align:center;line-height:90%;font-size:85%;overflow:visible;z-index:100;left:]] .. vt .. [[px;top:]] .. math.floor(height+5) .. [[px;">]] .. nkey .. [[</span>]]
                      else vprotest=vprotest .. s .. "-" .. e .. " "
                   end -- (if not ttoprow[n])
                end -- (if not vclaim)
             end -- (if not toreplace)
          end -- (if showthismotif)
       end -- (if s)
   end -- for feature, range
    --- we're out of the loop - now draw annotations for the chosen replace regions based on user text
   local ri=1
      while treplaceregion.s[ri] do
         local rs=treplaceregion.s[ri]
         local re=treplaceregion.e[ri]
         local rt=mw.ustring.gsub(mw.ustring.sub(treplaceregion.t[ri],1,vtext),"(.)","%1<br />") -- verticalize the text
         local boxleft=math.floor(width*tonumber(rs)/cdswidth)
         local boxwidth=math.floor(width*tonumber(re)/cdswidth)-boxleft
         local vt = math.floor(boxleft+boxwidth/2 -2) -- this formula should be synchronized with above, but defining constants seems silly.
          -- this ignores vclaim - it's a user input, therefore repositionable field
         graphics = graphics .. [[<span style="position:absolute;text-align:center;line-height:90%;font-size:85%;overflow:visible;z-index:100;left:]] .. vt .. [[px;top:]] .. math.floor(height+5) .. [[px;">]] .. rt .. [[</span>]]
         ri=ri+1
      end
   if not(tableoutput) then output = "" end
   if tlegend == "" then else tlegend = [[<span style="width:]]..width..[[;">]] .. [[''Top row:'' ]] .. tlegend .. [[</span>]] end
   if vprotest == "" then else vprotest = "''Overlapping vertical annotations not shown above: " .. vprotest .. "''" end
   if debuglog == "|}|}" then debuglog="" else debuglog = debuglog .. "\n" end
   if vtext>2 then vtext=vtext-2 end -- make up for extra return required to start a table at the end there.
   local output = [=[{| style="width:]=]..width..[[px;"]] .. "\n|".. graphics .. [[</div><span style="line-height:90%;font-size:85%;">]] .. mw.ustring.rep("\n",vtext) .. "</span>" .. tlegend .. vprotest .. "\n" .. output .. "\n|}\n" .. debuglog .. "|}\n"
   if nowiki then output = frame.preprocess(frame,"<pre><nowiki>"..output.."</nowiki></pre>") end
   return output

end

return p