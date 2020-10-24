--[=[

This module is based on idea and original code of [[User:IKhitron]].

the source of this module is in //he.wikipedia.org/wiki/Module:ParamValidator

main purpose: use "templatedata" to verify the parameters passed to a template

Terminology: "numeric parameter" means order-based parameter. e.g. if the template is transcluded like so {{x  | k |  | a = m | b = }}
"a" and "b" are "named" parameters, and there are 2 "numeric", or order based parameters, 1 and 2. 
we say that the value of a is "m", the value of 1 is "k", and "b" and 2 are "empty".

This module exports two functions: calculateViolations( frame, subpages ), and validateParams( frame ). 

calculateViolations( frame, subpages ) finds templatedata, in template page or in one of its subpages in the list, if provided.
it returns a table with the violations. if there are none, the table is empty. otherwise it has the structure
{
	violation1 = { param1 = value1, param2 = value2 },
	violation2 = { ... },
	...
}

violation1, violation2 etc. are one of the names of specific violations, as described below. 
param1, param2 etc. are either the names of parameter passed to the template, or defined in templatedata.
value1, value2 etc. are the values passed to the template, or an empty string if no such parameter was passed.

the different violations are as follow:
	* "no-templatedata": 			no valid tempaltedata was found in tempalte page, or documentation subpage
	* "undeclared": 				named parameters with non-empty value, does not exist in templatedata
	* "empty-undeclared": 			named parameters with empty value, does not exist in templatedata
	* "undeclared-numeric": 		numeric parameters with non-empty value, does not exist in templatedata
	* "empty-undeclared-numeric": 	numeric parameters with empty value, does not exist in templatedata
	* "deprecated":  				parameters with non-empty value, marked as "deprecated" in tempaltedata
	* "empty-deprecated":  			parameters with empty value, marked as "deprecated" in tempaltedata
	* "empty-required": 			missing or empty parameter marked as "required" in tempaltedata
	* "incompatible":				a non-empty parameter passed to the template, incompatible with the parameter type defined in templatedata 
	* "duplicate":					a value is passed for the same parameter (or any of its aliases) more than once


The second function, validateParams( frame ), can be called from the tempalte' using #invoke.
it expects a parameter named "options", which contains the definition of the output. typically, it's used by placing something like so:

<includeonly>{{#invoke:ParamValidator | validateParams | options = {{PV default options}} }}</includeonly>

at the top of the template (be mindful not to add extra spaces and newlines to the template).
to bypass some mediawiki limitation, it is also possible to pass the options as "module", like so (use one of the two, but not both):
<includeonly>{{#invoke:ParamValidator | validateParams | module_options = Module:PV default options}} }}</includeonly>

the first form expects a template named "Template:PV default options" which contains the options, and the 2nd form expects a module, 
suitable for mw.loadData(), which returns a map of namespace => options (i.e. { [0] = <options>, [2] => <options> } .... )

the options parameter should be a JSON-encoded string, defining the output, and some special behaviors. 
the example above assumes that a wiki page named [[Template:PV default options]] exists, and contains valid JSON string. 
for each of the violations defined above, "options" may define an output string, so basically, "options" looks like so:
{
	violation1: outputstring1,
	violation2: outputstring2,
	.... ,
	behavior1: some value,
	....
}

not all violations have to be defined. a violation not defined in "options" will be ignored.

when invoked, it extract "subpages" from the options parameter, and calls:
 calculateViolations( frame, subpages )
if the returned table is empty, no violation were found, and an empty string is returned and nothing else happens.

otherwise, for each of the violations, i.e., the keys of the returned table, when "options" contains this key,
the corresonding value is appended to the output.

some further processing is done:
1) several tokens are replaced with calculated values. these are described below.
2) some "meta" violations are calculated: when any none-ignored violation occured, 
	the "any" meta-violation is added to the output in the same way, 
	i.e. the string keyed by "any" in the options is appended to output with appropriate substitutions.
	similarly, "multiple" meta-violation is created when more than one type of non-ignored violations occured.
3) if the output is not empty, a prefix and suffix strings are prepended and appended to it. 

these are the tokens and the replacement. 
	* "templatename":	full template name, including namespace.
	* "tname_naked":	template name without namespace.
	* "paramname":  	comma-separated list of parameters
	* "paramandvalue": is replaced by comma-separated list of "name: value" pairs of parameters and values
the first two are applied to the whole output, including the suffux and prefix,
and the rest are applied to the individual violations, each with its own list of offending parameters and values.


the rest of the if the value of some keys is null, this error condition will be ignored, and not counted when calculating "any" and "multiple" conditions.

some other optional fields can be passed via options:
	* "doc-subpage": can be either a string, or a list (in square bracktes) of strings, indicating subpages of the template 
			that may contain templatedata. 
	* "ignore": list of patterns. any parameter whose name matches any pattern, will not considered in violation of any of the rules.
	* "skip-empty-numeric": if a quoted number, the module will ignore non-declared empty numeric parameters up to this number
	* "wrapper-prefix": openning wrapper element of outpot (defaults to "<div class = 'paramvalidator-wrapper'>") 
	* "wrapper-suffix": closing wrapper element of output (defaults to "</div>") 

additional option parameters, named options1, options2, etc. can be passed. any entry defined in these options will 
override the previous value. a typical use may be like so:

	
typically, this JSON structure will be placed in a separate template, and retrieved for the module-use as shown above.
<includeonly>{{#invoke:ParamValidator | validateParams | options = {{PV default options}} | options1 = {"key":"value"} }}</includeonly>
"key" can override any of the options fields described above.


]=]

local util = {
	empty = function( s ) 
		return s == nil  or type( s ) == 'string' and mw.text.trim( s ) == ''   
	end
	, 
	extract_options = function ( frame, optionsPrefix )
		optionsPrefix = optionsPrefix or 'options' 
		

		local options, n, more = {}
		if frame.args['module_options'] then
			local module_options = mw.loadData( frame.args['module_options'] ) 
			if type( module_options ) ~= 'table' then return {} end
			local title = mw.title.getCurrentTitle()
			local local_ptions = module_options[ title.namespace ] or module_options[ title.nsText ] or {} 
			for k, v in pairs( local_ptions ) do options[k] = v end
		end
		
		repeat
			ok, more = pcall( mw.text.jsonDecode, frame.args[optionsPrefix .. ( n or '' )] )
			if ok and type( more ) == 'table' then
				for k, v in pairs( more ) do options[k] = v end
			end
			n = ( n or 0 ) + 1
		until not ok

		return options
	end
	, 
	build_namelist = function ( template_name, sp )
		local res = { template_name }
		if sp then
			if type( sp ) == 'string' then sp = { sp } end
			for _, p in ipairs( sp ) do table.insert( res, template_name .. '/' .. p ) end
		end
		return res
	end
	,
	table_empty = function( t ) -- normally, test if next(t) is nil, but for some perverse reason, non-empty tables returned by loadData return nil...
		if type( t ) ~= 'table' then return true end
		for a, b in pairs( t ) do return false end
		return true
	end
	,
}

local function _readTemplateData( templateName ) 
	local title = mw.title.makeTitle( 0, templateName )  
	local templateContent = title and title.exists and title:getContent() -- template's raw content
	local capture =  templateContent and mw.ustring.match( templateContent, '<templatedata%s*>(.*)</templatedata%s*>' ) -- templatedata as text
--	capture = capture and mw.ustring.gsub( capture, '"(%d+)"', tonumber ) -- convert "1": {} to 1: {}. frame.args uses numerical indexes for order-based params.
	local trailingComma = capture and mw.ustring.find( capture, ',%s*[%]%}]' ) -- look for ,] or ,} : jsonDecode allows it, but it's verbotten in json
	if capture and not trailingComma then return pcall( mw.text.jsonDecode, capture ) end
	return false
end

local function readTemplateData( templateName )
	if type( templateName ) == 'string' then 
		templateName = { templateName, templateName .. '/' .. docSubPage }
	end
	if type( templateName ) == "table" then
		for _, name in ipairs( templateName ) do
			local td, result = _readTemplateData( name ) 
			if td then return result end
		end
	end
	return nil
end


-- this is the function to be called by other modules. it expects the frame, and then an optional list of subpages, e.g. { "Documentation" }.
-- if second parameter is nil, only tempalte page will be searched for templatedata.
function calculateViolations( frame, subpages )
-- used for parameter type validy test. keyed by TD 'type' string. values are function(val) returning bool.
	local type_validators = { 
		['number'] = function( s ) return mw.language.getContentLanguage():parseFormattedNumber( s ) end
	}
	function compatible( typ, val )
		local func = type_validators[typ]
		return type( func ) ~= 'function' or util.empty( val ) or func( val )
	end
	
	local t_frame = frame:getParent()
	local t_args, template_name = t_frame.args, t_frame:getTitle()
	template_name = mw.ustring.gsub( template_name, '/sandbox', '', 1 )
	local td_source = util.build_namelist( template_name, subpages )
	local templatedata = readTemplateData( td_source )
	local td_params = templatedata and templatedata.params
	local all_aliases, all_series = {}, {}
	
	if not td_params then return { ['no-templatedata'] = { [''] = '' } } end
	-- from this point on, we know templatedata is valid.

	local res = {} -- before returning to caller, we'll prune empty tables

	-- allow for aliases
	for _, p in pairs( td_params ) do for _, alias in ipairs( p.aliases or {} ) do 
		all_aliases[alias] = p
		if tonumber(alias) then all_aliases[tonumber(alias)] = p end
	end end

	-- handle undeclared and deprecated
	local already_seen = {}
	local series = frame.args['series']
	for p_name, value in pairs( t_args ) do
		local tp_param, noval, numeric, table_name = td_params[p_name] or all_aliases[p_name], util.empty( value ), tonumber( p_name )
		local hasval = not noval

		if not tp_param and series then -- 2nd chance. check to see if series
			for s_name, p in pairs(td_params) do 
				if mw.ustring.match( p_name, '^' .. s_name .. '%d+' .. '$') then 
					-- mw.log('found p_name '.. p_name .. '  s_name:' .. s_name, ' p is:', p) debugging series support
					tp_param = p 
				end -- don't bother breaking. td always correct.
			end 				
		end
		
		if not tp_param then -- not in TD: this is called undeclared
			-- calculate the relevant table for this undeclared parameter, based on parameter and value types
			table_name = 
				noval and numeric and 'empty-undeclared-numeric' or
				noval and not numeric and 'empty-undeclared' or
				hasval and numeric and 'undeclared-numeric' or
				'undeclared' -- tzvototi nishar.
		else -- in td: test for deprecation and mistype. if deprecated, no further tests
			table_name = tp_param.deprecated and hasval and 'deprecated' 
				or tp_param.deprecated and noval and 'empty-deprecated' 
				or not compatible( tp_param.type, value ) and 'incompatible' 
				or not series and already_seen[tp_param] and hasval and 'duplicate'
				
			already_seen[tp_param] = hasval
		end
		-- report it.
		if table_name then 
			res[table_name] = res[table_name] or {}
			res[table_name][p_name] = value 
		end
	end

	-- test for empty/missing paraeters declared "required" 
	for p_name, param in pairs( td_params ) do 
		if param.required and util.empty( t_args[p_name] ) then
			local is_alias
			for _, alias in ipairs( param.aliases or {} ) do is_alias = is_alias or not util.empty( t_args[alias] ) end
			if not is_alias then
				res['empty-required'] = res['empty-required'] or {} 
				res['empty-required'][p_name] = '' 
			end
		end
	end
	
	return res
end

-- wraps report in hidden frame
function wrapReport(report, template_name, options)
	if util.empty( report ) then return '' end
	local naked = mw.title.new( template_name )['text'] 
	
	mw.log(report)
	report = ( options['wrapper-prefix'] or "<div class = 'paramvalidator-wrapper'><span class='paramvalidator-error'>" )
			.. report
			.. ( options['wrapper-suffix'] or "</span></div>" )
	
	report = mw.ustring.gsub( report, 'tname_naked', naked )
	report = mw.ustring.gsub( report, 'templatename', template_name )
	return report
end

-- this is the "user" version, called with {{#invoke:}} returns a string, as defined by the options parameter
function validateParams( frame )
	local options, report, template_name = util.extract_options( frame ), '', frame:getParent():getTitle()

	local ignore = function( p_name )
		for _, pattern in ipairs( options['ignore'] or {} ) do
			if mw.ustring.match( p_name, '^' .. pattern .. '$' ) then return true end
		end
		return false
	end

	local replace_macros = function( s, param_names )
		function concat_and_escape( t ) 
			local s = table.concat( t, ', ' )
			return ( mw.ustring.gsub( s, '%%', '%%%%' ) )
		end
		
		if s and ( type( param_names ) == 'table' ) then
			local k_ar, kv_ar = {}, {}
			for k, v in pairs( param_names ) do
				table.insert( k_ar, k )
				table.insert( kv_ar, k .. ': ' .. v)
			end
			s = mw.ustring.gsub( s, 'paramname', concat_and_escape( k_ar ) ) 
			s = mw.ustring.gsub( s, 'paramandvalue', concat_and_escape( kv_ar ) )
			
			if mw.getCurrentFrame():preprocess( "{{REVISIONID}}" ) ~= "" then
				s = mw.ustring.gsub( s, "<div.*<%/div>", "", 1 )
			end
		end
		return s
	end

	local report_params = function( key, param_names )
		local res = replace_macros( options[key], param_names )
		report = report ..  ( res or '' )
		return res
	end

	-- no option no work.
	if util.table_empty( options ) then return '' end

	-- get the errors.
	local violations = calculateViolations( frame, options['doc-subpage'] )
	-- special request of bora: use skip_empty_numeric
	if violations['empty-undeclared-numeric'] then 
		for i = 1, tonumber( options['skip-empty-numeric'] ) or 0 do 
			violations['empty-undeclared-numeric'][i] = nil 
		end
	end
	
	-- handle ignore list, and prune empty violations - in that order!
	local offenders = 0
	for name, tab in pairs( violations ) do 
		-- remove ignored parameters from all violations
		for pname in pairs( tab ) do if ignore( pname ) then tab[pname] = nil end end
		-- prune empty violations
		if util.table_empty( tab ) then violations[name] = nil end
	-- WORK IS DONE. report the errors.
	-- if report then count it.
		if violations[name] and report_params( name, tab ) then offenders = offenders + 1 end 
	end

	if offenders > 1 then report_params( 'multiple' ) end
	if offenders ~= 0 then report_params( 'any' ) end -- could have tested for empty( report ), but since we count them anyway...
	return wrapReport(report, template_name, options)
end

return {
	['validateparams'] = validateParams,
	['calculateViolations'] = calculateViolations,
	['wrapReport'] = wrapReport
}