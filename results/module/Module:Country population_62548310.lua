require('Module:No globals')
local fn = require('Module:Formatnum')
local mm = require('Module:Math')
local p ={}
local pargs ={}
local args={}
local data={}


p.main = function(frame) -- called from template
	pargs = frame:getParent().args
	local output 

	if output then
		return frame:preprocess(output)
	end
	
   return p.errormsg("No valid options")
end
function p.getPattern(section)
	local pattern = '<section begin=' .. section ..'[ ]*/>(.-)<section end='..section..'[ ]*/>'
	return pattern
end
function p.getPopulationData(frame)

    local page = "List of countries by population (United Nations)"
	data['dates'] = {}
	data['total'] = {}
	data.total['latest'] = 0
	data.total['previous'] = 0
	data.total['projected'] = 0
	
	--local total = 0
	--local totalProjected = 0
	local count = 0
	local title = mw.title.new( page) -- , ns)  -- creates object if page doesn't exist (and valid page name)
	                                            --TODO: could use mw.title.makeTitle(), but that needs ns
	
	local content = title:getContent()
    
    -- get dates 
	for value in string.gmatch( content , p.getPattern("date_1") ) do
		data.dates['latest']=value                                    -- date of latest data 
	end
	for value in string.gmatch( content , p.getPattern("date") ) do
	    data.dates['previous']=mw.getContentLanguage():formatDate('j F Y', value)
	end		
	data.dates['today'] = mw.getContentLanguage():formatDate('j F Y')      -- today's date (for formatting see https://www.mediawiki.org/wiki/Help:Extension:ParserFunctions#.23time)
    
    -- get population data for each country passes as parameter
	for k,v in pairs(args) do
		local country = mw.text.trim(v)
		
		-- get population data from section 
	    local section = country .. "_1"
		for value in string.gmatch( content , p.getPattern(section) ) do

	    	count=count+1
	    	data[count] = {}
	        data[count]['country'] = country
			data[count]['populationString'] = frame:preprocess(value)
			local raw = string.gsub(data[count]['populationString'], ",", "") -- strip formatting from number string
            data[count]['populationNumber'] = tonumber(raw)
            data.total['latest'] = data.total['latest'] + data[count]['populationNumber']
            
            local section = country .. "_0"
           	for value2 in  string.gmatch( content , p.getPattern(section) ) do
				data[count]['populationString2'] = frame:preprocess(value2)
				local raw = string.gsub(data[count]['populationString2'], ",", "") -- strip formatting from number string
                data[count]['populationNumber2'] = tonumber(raw)
                data.total['previous'] = data.total['previous'] + data[count]['populationNumber2']
                
                data[count]['populationIncrement']=data[count]['populationNumber'] - data[count]['populationNumber2']
                data[count]['populationGrowth'] =data[count]['populationIncrement']/data[count]['populationNumber2']
                data[count]['populationDouble'] = p.getPopulationDoubleTime(data[count]['populationNumber'],data[count]['populationNumber2'])

                data[count]['populationProjected'] = p.getPopulationProjection(data[count]['populationNumber'],data[count]['populationNumber2'])
                data.total['projected'] = data.total['projected'] + data[count]['populationProjected'] 
            end

		end
	end
	
    return true
end

-- estimate time to double population based on latest growth rate
function p.getPopulationDoubleTime(latest,previous)
	local growth = (latest - previous) / previous
    local doubleTime = math.log( 2 ) / math.log(1 + growth)
    return doubleTime
end

-- estimate today's population based on latest growth rate
function p.getPopulationProjection(latest,previous)
	local ay =  ( mw.getCurrentFrame():callParserFunction{ name = '#time', args = { "U", data.dates['today'] } }
                - mw.getCurrentFrame():callParserFunction{ name = '#time', args = { "U", data.dates['previous'] } })
                /60/60/24/365.2425 -- number of years since first date until today‬
	local projected = math.pow(previous, 1 - ay ) * math.pow(latest, ay)
    return projected
end

--[[ sort rows by population (defaults to latest population)
     TODO add options for sorting columns
  ]]
function p.sortPopulationData(ByColumn)
	
    local sort_function = function( a,b )
	    if (tonumber(a.populationNumber) > tonumber(b.populationNumber)) then                -- primary sort on 'population' -> a before b
	        return true
	    end
	end
		
    table.sort(data, sort_function)
end
--[[  Function to get flag icon and handle special cases 
      1.  There is an issue of non-standard sizes when used with static rank column 
	      The three countries with extra height (and the required size parameter) are 
	           Nepal/NPL (size=12px), Switzerland/CHE (size=15px), Vatican/VAT (size=15px)
	           a few have lower default heights so it doesn't matter (Poland, New Caledonia)
      2. Alias, e.g. NEP->NPL, TRI->TTO
  ]]
function p.getFlagLabel(countryCode)
	local output 
	local templateArgs = { countryCode }
	
	local size
    if countryCode == "CHE" or countryCode == "VAT" then
    	size="15px"
    elseif countryCode == "NPL" then
    	size="12px"
    end
    if size then templateArgs['size'] = size end

	-- simple version
	--output = mw.getCurrentFrame():expandTemplate{ title = "flagcountry", args = templateArgs } 
	
	-- method with fixed-height div and overflow
    output = '<div style="height:15px;overflow:visible;" >'
		  .. mw.getCurrentFrame():expandTemplate{ title = "flagcountry", args = templateArgs  }
	      .. '</div>'
	
	
	return output		          	        
end

--[[ output table of data as Wikitext table
  ]]
function p.tabulateDataWikitext(frame)

    local output
    local i = 1
    -- output table
    output = '{| class="wikitable sortable" style="text-align:right;" '    -- table
    
    output = output                                                        --headers (top row)
              .. '\n!rowspan=2|#'
              .. '\n!rowspan=2|Country'
              .. '\n!rowspan=2|Projected population<br/>(' .. data['dates']['today'] .. ')' 
              .. '\n!rowspan=2|Pct of total'
              .. '\n!colspan=2|UN Population estimates'
              .. '\n!colspan=2|Annual growth'
              .. '\n!rowspan=2|Doubling time<br/>(years)'
            
              .. '\n|-'                                                    -- headers (second row)
              .. '\n!' .. data.dates['latest'] 
              .. '\n!' .. data.dates['previous'] 
              .. '\n!Increment'
              .. '\n!Rate'                  
    
    while (data[i]) do                                                     -- add rows
       output = output .. '\n|-\n|' ..  i 
       output = output .. '\n|style="text-align:left;" |' .. frame:expandTemplate{ title = "flagcountry", args = {data[i]['country'] }  }
       output = output .. '\n| ' .. mm._precision_format(data[i]['populationProjected'],0)  
       output = output .. '\n| ' .. mm._precision_format(data[i]['populationProjected']/data.total['projected']*100,2) .. "%" -- projected
       output = output .. '\n| ' .. data[i]['populationString'] 
       output = output .. '\n| ' .. data[i]['populationString2'] 
       output = output .. '\n| ' .. mm._precision_format(data[i]['populationIncrement'],0) 
       output = output .. '\n| ' .. mm._round(data[i]['populationGrowth']*100,2) .. "%"
       output = output .. '\n| ' .. mm._round(data[i]['populationDouble'],0)
       i=i+1
    end
    
    local newcell = '\n! style="text-align:right;" | '    
    output = output .. '\n|-'                                              -- totals row
        .. '\n! !! Total' 
        .. newcell .. fn.formatNum(mm._round(data.total['projected'],0),"en",0) 
        .. newcell .. '100%'
        .. newcell .. fn.formatNum(data.total['latest'],"en",0) 
        .. newcell .. fn.formatNum(data.total['previous'],"en",0) 
        .. newcell .. fn.formatNum(data.total['latest']-data.total['previous'],"en",0)
        .. newcell .. fn.formatNum((data.total['latest']-data.total['previous'])/data.total['previous']*100,"en",2).."%"
        .. newcell .. mm._precision_format(p.getPopulationDoubleTime(data.total['latest'],data.total['previous']),0)
                                 
    output = output .. '\n|}'
    return output
end


--[[ output table of data as use Lua HTML Library
]]
function p.tabulateData(frame)
    
    local hideYearsCols = frame.args['hide_years'] or false
    local doublingFootnote = frame.args['doubling_note'] or ""
    local growthFootnote = frame.args['growth_note'] or ""
    
    local i = 1
    local static = mw.html.create('table'):addClass('wikitable')
                                         
    static:tag('tr'):tag('th'):attr('rowspan', 1):wikitext('<br/>'):cssText('border-bottom-color:#eaecf0;')
    static:tag('tr'):tag('th'):wikitext('<br/>'):cssText('border-top-color:#eaecf0;')
    while (data[i]) do                                                     -- add rows
		static:tag('tr'):tag('td'):wikitext(i)
		i=i+1
	end
    static:tag('tr'):tag('th'):wikitext('<br/>')
    local numRows=i-1

    local tbl = mw.html.create('table'):addClass('wikitable')             -- start table
                                       :addClass('sortable')
                                       :addClass('nowrap')
                                       :css('text-align','right')
                                       
    local row = tbl:tag('tr')                                             -- header row
			--:tag('th'):attr('rowspan', 2):wikitext('#')
	row	    :tag('th'):attr('rowspan', 2):wikitext('Country')
			:tag('th'):attr('rowspan', 2):wikitext('Projected population<br/>(' .. data['dates']['today'] .. ')' )
		    :tag('th'):attr('rowspan', 2):wikitext('Pct of total')
    if not hideYearsCols then
		row :tag('th'):attr('colspan', 2):wikitext('UN Population estimates')
	end
	row	    :tag('th'):attr('colspan', 2):wikitext('Annual growth'..growthFootnote)
		    :tag('th'):attr('rowspan', 2):wikitext('Doubling time<br/>(years)'..doublingFootnote)
    
    row = tbl:tag('tr')                                                    -- headers (second row)
    if not hideYearsCols then
		row :tag('th'):wikitext(data.dates['latest'] )
		    :tag('th'):wikitext(data.dates['previous'] )
    end
	row		:tag('th'):wikitext('Increment')
		    :tag('th'):wikitext('Rate')     
    
    
    i = 1
    while (data[i]) do                                                     -- add country rows
		
		local row=tbl:tag('tr') 
		--row :tag('td'):wikitext(i)  
		row		:tag('td'):cssText("text-align:left;")
			              :wikitext( p.getFlagLabel(data[i]['country']) )
				:tag('td'):wikitext( mm._precision_format(data[i]['populationProjected'],0)  )
				:tag('td'):wikitext( mm._precision_format(data[i]['populationProjected']/data.total['projected']*100,2) .. "%" ) -- % of projected 
		if not hideYearsCols then
			row	:tag('td'):wikitext( data[i]['populationString'] )
				:tag('td'):wikitext( data[i]['populationString2'] )
		end
		row		:tag('td'):wikitext( mm._precision_format(data[i]['populationIncrement'],0) )
				:tag('td'):wikitext( mm._precision_format(data[i]['populationGrowth']*100,2) .. "%" )
				:tag('td'):wikitext( mm._precision_format(data[i]['populationDouble'],0) )
		i=i+1
    end
    
    local style = { ['text-align']='right' }    
    row = tbl:tag('tr')                                             -- totals row
		    --:tag('th')           :wikitext()
	row	    :tag('th')           :wikitext('Total')
		    :tag('th'):css(style):wikitext( fn.formatNum(mm._round(data.total['projected'],0),"en",0) ) 
		    :tag('th'):css(style):wikitext( '100%' )
	if not hideYearsCols then
	   row  :tag('th'):css(style):wikitext( fn.formatNum(data.total['latest'],  "en",0) )
		    :tag('th'):css(style):wikitext( fn.formatNum(data.total['previous'],"en",0) )
	end
	row		:tag('th'):css(style):wikitext( fn.formatNum(data.total['latest']  - data.total['previous'],"en",0) )
		    :tag('th'):css(style):wikitext( fn.formatNum((data.total['latest'] - data.total['previous']) / data.total['previous'] * 100,"en",2).."%" )
		    :tag('th'):css(style):wikitext( mm._precision_format(p.getPopulationDoubleTime(data.total['latest'],data.total['previous']),0) )
	                             
    return '{|\n|style="vertical-align:top;" |' .. tostring(static) .. '\n|' .. tostring(tbl) .. '\n|}'
    --return tostring(tbl)
end


--[[  currently the main entry function
         takes list of country codes
         gets population data from "List of countries by population (United Nations)"
         outputs sorted table
  ]]
function p.populations(frame)
    
    args = frame.args  --TODO handle parent args for template
    
    local page = "List of countries by population (United Nations)"

	local title = mw.title.new( page) -- , ns)  -- creates object if page doesn't exist (and valid page name)
	                                            --TODO: could use mw.title.makeTitle(), but that needs ns
    local output = ""
	if title and title.exists then 
		local content = title:getContent()

        if not p.getPopulationData(frame) then
        	return p.errormsg("Error retrieving data.")
        end
		
		p.sortPopulationData("latest")
        
        --output =  p.tabulateDataWikitext(frame) -- version building table with Wikitext
        output =  p.tabulateData(frame)           -- version building table with mw.html library
        
    else
    	return  '<span class="error">No page title found</span>'
	end

    local test = "test: " 
	local number=5435.12345 
	test= 	fn.formatNum(5435.12345,"en",0)
	--test=   frame:expandTemplate{ title = "formatnum", args = { totalProjected ,"en",0 } }
	--test=frame:callParserFunction{ name = 'formatnum', args = { totalProjected, decs=2 } }   
   
   
   return output            --.. test
end
-- function for pie chart
function p.piechart(frame)
    
    args = frame.args  --TODO handle parent args for template
    
    local page = "List of countries by population (United Nations)"

	local title = mw.title.new( page) -- , ns)  -- creates object if page doesn't exist (and valid page name)
	                                            --TODO: could use mw.title.makeTitle(), but that needs ns
    local output = ""
	if title and title.exists then 
		local content = title:getContent()

        if not p.getPopulationData(frame) then
        	return p.errormsg("Error retrieving data.")
        end
		
		p.sortPopulationData("latest")
        
        --output =  p.tabulateDataWikitext(frame) -- version building table with Wikitext
        output =  p.makePieChart(frame)           -- version building table with mw.html library
        
    else
    	return  '<span class="error">No page title found</span>'
	end

   
   
   return output            --.. test
end

function p.makePieChart(frame)   
   
   --local args=frame.args
   local templateArgs = {}
   
   templateArgs['caption'] = args['caption'] or "" --'South American population by country'  --.. ' (top 8)'
   templateArgs['thumb'] = args['thumb'] or "right"
   templateArgs['other'] = args['other'] or nil
   local maxSlices = tonumber(args['slices']) -- nil if not a number
   if type(maxSlices) ~= "number" or maxSlices > 30 or maxSlices < 1 then
	   maxSlices = 30 -- limit of template                                -- get number from data
   end

    
   
   
   local i=1
   while data[i] and i <= maxSlices do
	   --templateArgs['label'..i] = data[i]['country'] 
	   templateArgs['label'..i] = mw.getCurrentFrame():expandTemplate{ title = "getalias", args = { data[i]['country'], raw='y' } }
	   templateArgs['value'..i] = mm._round( data[i]['populationNumber']/data.total['latest']*100,1)
	   templateArgs['color'..i] = args['color'..i] or nil
	   i=i+1
   end
   

--[[{{Pie chart
|caption= South American population by country (top 8)
|other = yes
|label1 = {{getalias|BRA}}
|value1 = {{#expr: {{country population|BRA|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label2 = {{getalias|COL}}
|value2 = {{#expr: {{country population|COL|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label3 = {{getalias|ARG}}
|value3 = {{#expr: {{country population|ARG|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label4 = {{getalias|PER}}
|value4 = {{#expr: {{country population|PER|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label5 = {{getalias|VEN}}
|value5 = {{#expr: {{country population|VEN|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label6 = {{getalias|CHL}}
|value6 = {{#expr: {{country population|CHL|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label7 = {{getalias|ECU}}
|value7 = {{#expr: {{country population|ECU|raw=y}} / {{xyz|Total}} * 100 round 1}}
|label8 = {{getalias|BOL}}
|value8 = {{#expr: {{country population|BOL|raw=y}} / {{xyz|Total}} * 100 round 1}}
}}  ]] 
   
   local chart = mw.getCurrentFrame():expandTemplate{ title = "Pie chart", args = templateArgs  }
   
   return chart
   

end


function p.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
p.errormsg = function (message)
	return '<span class="error">' .. message .. '</span>' 
end	

-- Test why was the sort being applied to the wrong level? Fixed 
function p.test(frame) -- meant test()

    local tbl = mw.html.create('table'):addClass('wikitable'):addClass('sortable')
                                                   :css('text-align','right')
    
    tbl:tag('tr')                                             -- header row
		:tag('th'):attr('rowspan', 2):wikitext('#')
		:tag('th'):attr('rowspan', 2):wikitext('A')
	    :tag('th'):attr('rowspan', 2):wikitext('B')
	    :tag('th'):attr('colspan', 2):wikitext('C+D'):addClass('unsortable')
	    :tag('th'):attr('colspan', 2):wikitext('E+F'):addClass('unsortable')
	    :tag('th'):attr('rowspan', 2):wikitext('G')
    
    tbl:tag('tr')                                                    -- headers (second row)
	    :tag('th'):wikitext('C'):addClass('sortable')
	    :tag('th'):wikitext('D'):addClass('sortable')
	    :tag('th'):wikitext('E'):addClass('sortable')
	    :tag('th'):wikitext('F')   :addClass('sortable')  
    
    
    local i = 1
    while (i<5) do                                                     -- add rows
		tbl:tag('tr') 
			:tag('td'):wikitext(i)  
			:tag('td'):wikitext("A"..i)
			:tag('td'):wikitext("B"..i)
			:tag('td'):wikitext(tostring(math.fmod(5-i,2)) .. 'C' .. i )
			:tag('td'):wikitext("D"..i)
			:tag('td'):wikitext("E"..i)
			:tag('td'):wikitext(tostring(math.fmod(5-i,2)) .. 'F' .. i )
			:tag('td'):wikitext("G"..i)
		i=i+1
    end
    
    local output = '{| class="wikitable sortable" style="text-align:right;" '    -- table
    output = output
              .. '\n!rowspan=2|#'
              .. '\n!rowspan=2|A'
              .. '\n!rowspan=2|B' 
              .. '\n!colspan=2|C+D'
              .. '\n!colspan=2|E+F'
              .. '\n!rowspan=2|G'
            
              .. '\n|-'                                                    -- headers (second row)
              .. '\n!C' 
              .. '\n!D' 
              .. '\n!E'
              .. '\n!F'                  
    i=1
    while (i<5) do                                                     -- add rows
       output = output .. '\n|-\n|' ..  i 
       output = output .. '\n|A' .. i 
       output = output .. '\n|B' .. i
       output = output .. '\n|' .. tostring(math.fmod(5-i,2)) .. 'C' .. i 
       output = output .. '\n|D' .. i 
       output = output .. '\n|E' .. i 
       output = output .. '\n|' .. tostring(math.fmod(5-i,2)) .. 'F' .. i 
       output = output .. '\n|G' .. i
       i=i+1
    end
    output = output .. '\n|}'

    return output .. tostring(tbl)
end

-- function for static rank column

function p.rank(frame)

	--args = frame.args           -- for module TODO allow invoke to work
	args = frame:getParent().args -- parent arguments for template
	
	local caption         = args['caption']          
	local valign          = args['valign'] or "top"
	local rowHeader       = args['row-header'] 
	local headerPadding   = args['header-padding'] or "0px"
	local textAlign       = args['text-align'] or "right"
	local style           = args['style'] or ""
	local headerHeight    = args['header-height'] or ""
	local headerLines     = args['header-lines']  or 1
	local headerText      = args['header-text'] or ""
	local rows            = tonumber(args['rows']) or 0
	local rowHeader       = args['row-header'] 
	local rowHeight       = args['row-height'] 
	
	local marginRight = "0px"
	if rowHeader then marginRight = "-8px" end
	local headerValign    = "bottom"
	if rowHeader then headerValign = "center" end     -- copied from template; should be middle?
	local linebreaks = ""
	if headerLines then
		local i=0
		while i<tonumber(headerLines) do
			linebreaks = linebreaks ..  "<br />"
			i=i+1
		end
	end

--[[
{| 
|+'''{{{caption| }}}'''
| valign={{{valign|top}}} |
{| class="wikitable" style="margin-right:{{#if:{{{row-header|}}}|-8px|0px}}; padding:{{{header-padding|0px}}}; text-align:{{{text-align|right}}};{{{style|}}}"
! style=height:{{{header-height|}}} valign={{{header-valign|{{#if: {{{row-header|}}} | center | bottom}}}}} | {{#if:{{{header-lines|}}}|{{repeat|{{#expr:{{{header-lines}}}-1}}|<br>}}}}{{{header-text|}}}
]]
    local heightClass = "static-rank-col"
    if rowHeight and rowHeight == "large" then
    	heightClass = "static-rank-col-large"
    end
    
    
	local output =      '\n{| class="'..heightClass..'"'                                                          --start static rank table
    if caption then
    	output = output  .. "\n|+'''" .. caption .. "'''"
    end
    output = output  .. '\n|valign=' .. valign .. ' |'
        	    	 .. '\n{| class="wikitable" style="margin-right:'..marginRight
                    		                      ..'; padding:'..headerPadding
                            		              ..'; text-align:'..textAlign 
                                    		      ..';'.. style
        		     .. '\n! style="height:'..headerHeight..';" valign="'..headerValign ..';" | ' 
            		 ..  linebreaks .. headerText

--[[ {{#ifexpr:{{{rows}}}=0|<br />
{{end}}}}{{#ifexpr:{{{rows}}}>=1|{{Static column row |row-height={{{row-height|}}} |number=1 |row-header={{{row-header| }}} }}}}{{#ifexpr:{{{rows}}}=1|<br />
{{end}}}}{{#ifexpr:{{{rows}}}>=2|{{Static column row |row-height={{{row-height|}}} |number=2 |row-header={{{row-header| }}} }}}}{{#ifexpr:{{{rows}}}=2|<br />
{{end}}}
]]

	local i=0
	while i<rows do
		i=i+1
	    --output = output .. '\n|-\n|' .. tostring(i)           -- simple unformatted version
	    
--[[	    <br />
|- {{#if: {{{row-height|}}}|style="height:{{{row-height|}}}"|}}
{{#if: {{{row-header|}}} | ! | {{!}} }} {{{number}}}
]] 
                                                          -- version emulating Template:Static column row                                                
          local rowStyle = ""
          if rowHeight then rowStyle  = 'style="height:'..rowHeight..';" |' end
          local cellType = "|"
          if rowHeader then cellType = "!" end
          output = output .. '\n|-' .. rowStyle 
                          .. '\n' .. cellType .. tostring(i) .. '<br />'
	end

	output = output .. '\n|}'                                                      -- close the static rank table


	output = output .. '\n|'     -- new cell for the main table

	--output = output .. '\n|}'  -- unnecessary: the table will be closed with an {{end}} template

	return p.templateStyle( frame, "Static column begin/styles.css" ) .. output
	
end
function p.templateStyle( frame, src )
   return frame:extensionTag( 'templatestyles', '', { src = src } );
end
return p