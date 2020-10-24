 --- The purpose of this module is to clip out a segment from a set of files that makes up a map
 --- various annotations and scale bars should be added.
 --- The spritedraw function is being considered as a possible direct copy (future "require")
 --- from Module:Sprite - however, both modules are too inchoate at this time to do that confidently,
 --- and some modification may be needed.


local p={}

function processdegrees(degreestring)
    local neg=mw.ustring.match(degreestring,"^%s*%-") or mw.ustring.match(degreestring,"S") or mw.ustring.match(degreestring,"W")
    if neg then neg=-1 else neg=1 end
    local onenumber=mw.ustring.match(degreestring,"^[^%d%.]*([%d%.]+)[^%d%.]*$")
    if onenumber then
        return (neg*tonumber(onenumber))
    else local deg=mw.ustring.match(degreestring,"^[^%d%.]*([%d%.]+)")
        if not(deg) then return nil end
        local min=mw.ustring.match(degreestring,"^[^%d%.]*[%d%.]+[^%d%.]*([%d%.]+)")
        local sec=mw.ustring.match(degreestring,"^[^%d%.]*[%d%.]+[^%d%.]*[%d%.]+[^%d%.]*([%d%.]+)")
        return neg*(tonumber(deg)+tonumber(min or 0)/60+tonumber(sec or 0)/3600)
    end
end
    
    
function spritedraw(left,right,top,bottom,image,imagewidth,scale,float)
    top=math.floor(top*scale)
    bottom=math.ceil(bottom*scale)
    left=math.floor(left*scale)
    right=math.ceil(right*scale)
    local scalestring=""
    if scale~=1 then scalestring=math.floor(imagewidth*scale)..'px|' end
    output='<div style="position:absolute;overflow:visible;'..float..'top:'..(15-top)..'px;left:'..(40-left)..'px;clip:rect('..top..'px,'..right..'px,'..bottom..'px,'..left..'px);">[[File:'..image..'|'..scalestring..']]</div>'
    return output
end

function p.map(frame)
    --- variables "map" refer to the original image file
    --- variables "region" refer to the clipped area to be displayed
   local debuglog=""
   local args=frame.args
   local parent=frame.getParent(frame)
   local pargs=parent.args
    --- pixel values (setting regionwidth forces scaling.
    --- Regionheight may not be implemented because there's no way to 1-way scale I know of
   local mapwidthpx=args.mapwidthpx or pargs.mapwidthpx
   local mapheightpx=args.mapheightpx or pargs.mapheightpx
   local directions={'north','south','east','west'}
   local north,south,east,west=1,2,3,4
   local worldedge={90,-90,180,-180}
   local mapedgestring,mapedge,regionedgestring,regionedge={},{},{},{}
   for d =1,4 do
      mapedgestring[d]=args['map'..directions[d]..'edge'] or args['map'..directions[d]..'edge'] or ""
      mapedge[d]=processdegrees(mapedgestring[d]) or worldedge[d]
      regionedgestring[d]=args['region'..directions[d]..'edge'] or args['region'..directions[d]..'edge'] or ""
      regionedge[d]=processdegrees(regionedgestring[d]) or worldedge[d]
   end
   local mapwidthdeg=mapedge[east]-mapedge[west]
   if mapwidthdeg<=0 then mapwidthdeg=mapwidthdeg+360 end
   local regionwidthdeg=regionedge[east]-regionedge[west]
   if regionwidthdeg<=0 then regionwidthdeg=regionwidthdeg+360 end
   local mapfile=args.mapfile or pargs.mapfile or ""
   local mapfiles={}
   local row=0
   mapfile=mapfile.."|" -- last row will be processed like the others
   while mw.ustring.match(mapfile,"|") do
       row=row+1
       local rowtext=mw.ustring.match(mapfile,"^([^|]*)|")
       mapfiles[row]={}
       prowl=mw.ustring.gmatch(rowtext,"%[%[([^%[%]])*%]%]")
       repeat
           local f=prowl()
           if not f then break;end
           table.insert(mapfiles[row],f)
       until false
       mapfile=mw.ustring.gsub(mapfile,"^[^|]*|","")
   end
   if not mapfiles[1][1] then
       mapedge={90,-90,180,-180} -- ad hoc calibration was done here, but turned out to be a bug!
       if regionwidthdeg<=60 then
           mapwidthpx=1800
           mapheightpx=1800
           mapfiles=
{{'Topographic30deg_N60W150.png',
'Topographic30deg_N60W120.png',
'Topographic30deg_N60W90.png',
'Topographic30deg_N60W60.png',
'Topographic30deg_N60W30.png',
'Topographic30deg_N60W0.png',
'Topographic30deg_N60E0.png',
'Topographic30deg_N60E30.png',
'Topographic30deg_N60E60.png',
'Topographic30deg_N60E90.png',
'Topographic30deg_N60E120.png',
'Topographic30deg_N60E150.png'},
{'Topographic30deg_N30W150.png',
'Topographic30deg_N30W120.png',
'Topographic30deg_N30W90.png',
'Topographic30deg_N30W60.png',
'Topographic30deg_N30W30.png',
'Topographic30deg_N30W0.png',
'Topographic30deg_N30E0.png',
'Topographic30deg_N30E30.png',
'Topographic30deg_N30E60.png',
'Topographic30deg_N30E90.png',
'Topographic30deg_N30E120.png',
'Topographic30deg_N30E150.png'},
{'Topographic30deg_N0W150.png',
'Topographic30deg_N0W120.png',
'Topographic30deg_N0W90.png',
'Topographic30deg_N0W60.png',
'Topographic30deg_N0W30.png',
'Topographic30deg_N0W0.png',
'Topographic30deg_N0E0.png',
'Topographic30deg_N0E30.png',
'Topographic30deg_N0E60.png',
'Topographic30deg_N0E90.png',
'Topographic30deg_N0E120.png',
'Topographic30deg_N0E150.png'},
{'Topographic30deg_S0W150.png',
'Topographic30deg_S0W120.png',
'Topographic30deg_S0W90.png',
'Topographic30deg_S0W60.png',
'Topographic30deg_S0W30.png',
'Topographic30deg_S0W0.png',
'Topographic30deg_S0E0.png',
'Topographic30deg_S0E30.png',
'Topographic30deg_S0E60.png',
'Topographic30deg_S0E90.png',
'Topographic30deg_S0E120.png',
'Topographic30deg_S0E150.png'},
{'Topographic30deg_S30W150.png',
'Topographic30deg_S30W120.png',
'Topographic30deg_S30W90.png',
'Topographic30deg_S30W60.png',
'Topographic30deg_S30W30.png',
'Topographic30deg_S30W0.png',
'Topographic30deg_S30E0.png',
'Topographic30deg_S30E30.png',
'Topographic30deg_S30E60.png',
'Topographic30deg_S30E90.png',
'Topographic30deg_S30E120.png',
'Topographic30deg_S30E150.png'},
{'Topographic30deg_S60W150.png',
'Topographic30deg_S60W120.png',
'Topographic30deg_S60W90.png',
'Topographic30deg_S60W60.png',
'Topographic30deg_S60W30.png',
'Topographic30deg_S60W0.png',
'Topographic30deg_S60E0.png',
'Topographic30deg_S60E30.png',
'Topographic30deg_S60E60.png',
'Topographic30deg_S60E90.png',
'Topographic30deg_S60E120.png',
'Topographic30deg_S60E150.png'}}
       else
           mapwidthpx=1991
           mapheightpx=1990
           mapfiles={{'WorldMap_180-0-270-90.png','WorldMap_270-0-360-90.png','WorldMap_0-0-90-90.png','WorldMap_90-0-180-90.png'},{'WorldMap_-180,-90,-90,0.png','WorldMap_-90,-90,-0,0.png','WorldMap_0,-90,90,0.png','WorldMap_-270,-90,-180,0.png'}}
       end
   end
   if not (mapwidthpx and mapheightpx) then return "Module:MapClip error: mapwidthpx and mapheightpx must be supplied if a map image file is specified" end
   mapwidthpx=tonumber(mapwidthpx);mapheightpx=tonumber(mapheightpx)
   local totalmapwidthpx=mapwidthpx*#mapfiles[1]
   local totalmapheightpx=mapheightpx*#mapfiles
   local mapheightdeg=mapedge[north]-mapedge[south]
   if mapheightdeg<=0 then return "[[Module:MapClip]] error: mapnorthedge is south of mapsouthedge" end
   if ((regionedge[north]-regionedge[south])<0) then return "[[Module:MapClip]] error: regionnorthedge is south of regionsouthedge" end

   local widthratio=totalmapwidthpx/mapwidthdeg
   local heightratio=totalmapheightpx/mapheightdeg
   local left=(regionedge[west]-mapedge[west])*widthratio
   local xfile=math.floor(left/mapwidthpx)
   left=left-xfile*mapwidthpx
   local right=(regionedge[east]-mapedge[west])*widthratio-xfile*mapwidthpx
   local top=(mapedge[north]-regionedge[north])*heightratio
   local yfile=math.floor(top/mapheightpx)
   top=top-yfile*mapheightpx
   local bottom=(mapedge[north]-regionedge[south])*heightratio-yfile*mapheightpx
   local imagewidth=mapwidthpx
   local displaywidth=args.displaywidth or pargs.displaywidth or 220
   local float=args.float or pargs.float or nil
   if float then float="float:"..float..";" else float="" end
   local nowiki=args.nowiki or pargs.nowiki
   local i,featurelat,featurelong,featurename,featureimage,featuresize,featuretext=0,{},{},{},{},{},{}
   repeat -- import all feature names, longitude, latitude
       i=i+1
       featurename[i]=args['feature'..i] or pargs['feature'..i]
       featurelat[i]=args['feature'..i..'lat'] or pargs['feature'..i..'lat']
       featurelong[i]=args['feature'..i..'long'] or pargs['feature'..i..'long']
       featureimage[i]=args['feature'..i..'image'] or pargs['feature'..i..'image']
       featuresize[i]=args['feature'..i..'size'] or pargs['feature'..i..'size']
       featuretext[i]=args['feature'..i..'text'] or pargs['feature'..i..'text']
       if (featurelong[i]) then featurelong[i]=processdegrees(featurelong[i]) else featurelat[i]=nil end
       if (featurelat[i]) then featurelat[i]=processdegrees(featurelat[i]) end
   until (not featurelat[i])
   local output=""
    -- first map to display
   local image=mapfiles[yfile+1][xfile+1] or error("Module:MapClip error: "..tostring(yfile)..":"..tostring(xfile).." in "..tostring(mapfile).." not found")
   local scale=displaywidth/(right-left)
   output,errcode=spritedraw(left,right,top,bottom,image,imagewidth,scale,float)
   if right>mapwidthpx then
       local xnew=xfile+2
       if xnew>#mapfiles[1] then xnew=1 end
       if bottom>mapheightpx then
           local ynew=yfile+2
           if ynew>#mapfiles then ynew=1 end
           local image=mapfiles[ynew][xfile+1] or error("Module:MapClip error: "..tostring(yfile)..":"..tostring(xfile).." in "..tostring(mapfile).." not found")
           local output2,errcode2=spritedraw(left,right,top-mapheightpx,bottom-mapheightpx,image,imagewidth,scale,float)
           output=output..output2;errcode=errcode or errcode2
           local image=mapfiles[yfile+1][xnew]
           local output2,errcode2=spritedraw(left-mapwidthpx,right-mapwidthpx,top,bottom,image,imagewidth,scale,float)
           output=output..output2;errcode=errcode or errcode2
           local image=mapfiles[ynew][xnew]
           local output2,errcode2=spritedraw(left-mapwidthpx,right-mapwidthpx,top-mapheightpx,bottom-mapheightpx,image,imagewidth,scale,float)
           output=output..output2;errcode=errcode or errcode2
       else
           local image=mapfiles[yfile+1][xnew]
           local output2,errcode2=spritedraw(left-mapwidthpx,right-mapwidthpx,top,bottom,image,imagewidth,scale,float)
           output=output..output2;errcode=errcode or errcode2
       end
    else if bottom>mapheightpx then
       local ynew=yfile+2
       if ynew>#mapfiles then ynew=1 end
       local image=mapfiles[ynew][xfile+1] or error("Module:MapClip error: "..tostring(yfile)..":"..tostring(xfile).." in "..tostring(mapfile).." not found")
       local output2,errcode2=spritedraw(left,right,top-mapheightpx,bottom-mapheightpx,image,imagewidth,scale,float)
       output=output..output2;errcode=errcode or errcode2
       end
   end
   local grid=args.grid or pargs.grid
   if grid then -- for now only implementing an automagic grid
       md=regionedge[east]-regionedge[west]
       if md<0 then md=md+360 end
       if md<=30 then md=math.abs(md/2) else md=math.abs(md/3) end -- must be at least two divisions
       local pt=10
       if pt<=md then
           if (pt<=md/3) then pt=pt*3 end -- multiples of 30 degrees
           if (pt<=md/3) then pt=pt*3 end -- multiples of 90 degrees
       else while (pt>md) do
               if pt/2<md then pt=pt/2;break end -- first digit 5
               if pt/5<md then pt=pt/5;break end -- first digit 2
               pt=pt/10
               if pt<md then break end -- first digit 1
           end
       end
       local yheight=math.ceil((bottom-top)*scale)
       for gridline=math.ceil(regionedge[west]/pt)*pt,math.floor(regionedge[east]/pt)*pt,pt do
           local xpos=math.floor(((gridline-mapedge[west])*widthratio-xfile*mapwidthpx-left)*scale)
           output=output..'<div style="position:absolute;overflow:visible;border:solid '..grid..';border-width:0 1px 0 0;'..float..'top:15px;width:0px;height:'..yheight..'px;left:'..(xpos+40)..'px;"></div><div style="position:absolute;top:-2px;width:40px;font-size:75%;color:'..grid..';text-align:right;left:'..(xpos+10)..'px;">'..tostring(math.abs(gridline))..((gridline<0) and "W" or "E")..'</div>'
       end
       for gridline=math.floor(regionedge[north]/pt)*pt,math.ceil(regionedge[south]/pt)*pt,-1*pt do
           local ypos=math.floor(((regionedge[north]-gridline)*heightratio)*scale)
           output=output..'<div style="position:absolute;overflow:visible;border:solid '..grid..';border-width:0 0 1px 0;'..float..'top:'..(ypos+15)..'px;height:0px;width:'..displaywidth..'px;left:40px;"></div><div style="position:absolute;top:'..(ypos+6)..'px;width:40px;font-size:75%;color:'..grid..';text-align:right;left:0px;">'..tostring(math.abs(gridline))..((gridline<0) and "S" or "N")..'</div>'
       end
   end
   if featurelat[1] then
       for i=1,#featurelat do
           if featuretext[i] then
               output=output..'<div style="position:absolute;overflow:visible;top:'..math.floor(((regionedge[north]-featurelat[i])*heightratio)*scale+3)..'px;left:'..math.floor(((featurelong[i]-mapedge[west])*widthratio-xfile*mapwidthpx-left)*scale+33)..'px;">'..featuretext[i]..'</div>'
           else
               local linkstring=''
               if featurename[i] then linkstring='|link='..featurename[i]..'|'..featurename[i] end
               output=output..'<div style="position:absolute;overflow:visible;height:15px;width:15px;top:'..math.floor(((regionedge[north]-featurelat[i])*heightratio)*scale+10.5-(featuresize[i] or 15)/2)..'px;left:'..math.floor(((featurelong[i]-mapedge[west])*widthratio-xfile*mapwidthpx-left)*scale+40.5-(featuresize[i] or 15)/2)..'px;">[[File:'..(featureimage[i] or 'Full Star Yellow.svg')..'|'..(featuresize[i] or '15')..'px'..linkstring..']]</div>'
           end
       end
   end
   output = '<div style="position:relative;overflow:hidden;'..float..'width:'..(displaywidth+60)..'px;height:'..math.ceil((bottom-top)*scale+22)..'px;">'..output..'</div>'
   if nowiki or errcode then return frame:preprocess("<nowiki>"..output..debuglog.."</nowiki>") end
   return output
end

return p