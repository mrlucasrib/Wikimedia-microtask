local p={};

wikitable_open = '{| class="wikitable"\n|-\n';
wikitable_caption = '|+$1\n';
wikitable_header = '! name !! description !! aliases !! type !! condition\n|-\n';
wikitable_row = '| $1 || $2 || $3 || $4 || $5\n|-\n';
wikitable_close = '|}\n';

json_open = '{\n"description": "$1",\n';				-- $1=ve-description
json_params_open = '"params":\n {';
json_name_label = '\n "$1":\n  {\n  "label": "$2"';		-- $1=name, $2=ve-label
json_description = '\n  "description": "$1"';			-- $1=ve-description
json_aliases = '\n  "aliases": [$1]';					-- $1= list of aliases "alias1", "alias2", "alias3"  note: no trailing comma
json_type = '\n  "type": "$1"';							-- $1=type
json_required = '\n  "required": true';					-- not included if |required= is empty, missing, or set to anything but true
json_suggested = '\n  "suggested": true';					-- not included if |required=true; or |suggested= is empty, missing, or set to anything but true
json_params_close = '\n  }';


--[[-------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not

]]
function is_set( var )
	return not (var == nil or var == '');
end

--[[-------------------------< S U B S T I T U T E >----------------------------------------------------------

Populates numbered arguments in a message string using an argument table.
 
]]

function substitute( msg, args )
	return args and mw.message.newRawMessage( msg, args ):plain() or msg;
end

--[[-------------------------< B U I L D _ R O W >------------------------------------------------------------
This function extracts information from a postional parameter (the content of {{Template parameter doc item}} after it has been rendered)
and creates a wikitable row from it.
]]

function build_row (raw_row)
	local alias;
	local alias_string = '<div class="plainlist">';
	local i = 1;
	local row;
	local condition;
	
	if 'true' == mw.ustring.match (raw_row, '├required┼([^┤]+)┤') then
		condition = 'required';
	elseif 'true' == mw.ustring.match (raw_row, '├suggested┼([^┤]+)┤') then
		condition = 'suggested';
	end

	while i <= 9 do
		alias = mw.ustring.match (raw_row, '├alias'.. i .. '┼([^┤]+)┤')
		if is_set (alias) then
			alias_string = alias_string .. '\n*' .. alias;
		else
			alias_string = alias_string .. '</div>\n';
			break;
		end
		i = i + 1;
	end

	row = substitute (wikitable_row,
		{
		mw.ustring.match (raw_row, '├name┼([^┤]+)┤'),
		mw.ustring.match (raw_row, '├description┼([^┤]+)┤'),
		alias_string,
		mw.ustring.match (raw_row, '├type┼([^┤]+)┤'),
		condition
		});
	
	return row;
end

--[[-------------------------< B U I L D _ W I K I T A B L E >------------------------------------------------

]]

function build_wikitable (args)
	local header = wikitable_open;
	local row_string = '';
	
	for k, v in pairs( args ) do
		if type( k ) ~= 'string' then
			row_string = row_string .. build_row (v);
		end
	end

	return table.concat ({header, substitute (wikitable_caption, {args['title']}), wikitable_header, row_string, wikitable_close});
end


--[[-------------------------< B U I L D _ J S O N _ P A R A M >----------------------------------------------

]]

function build_json_param (raw_row)
local param ={};
local alias_table = {};
local alias;
local i = 1;

	while i <= 9 do
		alias = mw.ustring.match (raw_row, '├alias'.. i .. '┼([^┤]+)┤')
		if is_set (alias) then
			table.insert (alias_table, '"' .. alias .. '"');
		else
			break;
		end
		i = i + 1;
	end

	alias = table.concat (alias_table, ',');


	table.insert (param,  substitute (json_name_label, {mw.ustring.match (raw_row, '├name┼([^┤]+)┤'), mw.ustring.match (raw_row, '├ve%-label┼([^┤]+)┤')}));
	table.insert (param,  substitute (json_description, {mw.ustring.match (raw_row, '├ve%-description┼([^┤]+)┤')}));
	if is_set (alias) then
		table.insert (param, substitute (json_aliases, alias));
	end
	table.insert (param,  substitute (json_type, {mw.ustring.match (raw_row, '├type┼([^┤]+)┤')}));

	if 'true' == mw.ustring.match (raw_row, '├required┼([^┤]+)┤') then
		table.insert (param,  json_required);
	elseif 'true' == mw.ustring.match (raw_row, '├suggested┼([^┤]+)┤') then
		table.insert (param,  json_suggested);
	end

	return table.concat (param, ',') .. json_params_close;
end


--[[-------------------------< B U I L D _ J S O N _ D A T A >------------------------------------------------

]]

function build_json_data (args)
	local json_data ={};
	local json_params ={};
	
	table.insert (json_data, substitute (json_open, {args['ve-description']}));
	table.insert (json_data, json_params_open);

	for k, v in pairs( args ) do
		if type( k ) ~= 'string' then
			table.insert (json_params, build_json_param (v));
		end
	end

	return table.concat ({table.concat (json_data), table.concat (json_params, ',')}) .. '\n }\n}';
end

--[[-------------------------< M A I N >----------------------------------------------------------------------

]]
function p.main(frame)
	local pframe = frame:getParent()
	local args = {};
	local wikitable;
	local json_data = 'JSON data placeholder';
	
	
	for k, v in pairs( pframe.args ) do
		args[k] = v;
	end
	
	wikitable = build_wikitable (args);
	json_data = build_json_data (args);
	return table.concat ({wikitable, '==Template data==\n<templatedata>', json_data, '</templatedata>'}, '\n');


--	return frame:extensionTag{ name = 'templatedata', content = table.concat ({wikitable, '==Template data==\n<templatedata>', json_data, '</templatedata>'}, '\n')}; this doesn't work
-- because its a single tag thing so the table and extra tag bugger it up
--	return frame:extensionTag{ name = 'templatedata', content = json_data};	-- this works to display a rendered templatedata table only
--	return frame:preprocess( table.concat ({wikitable, '==Template data==\n<templatedata>', json_data, '</templatedata>'}, '\n'));  -- this works
end
		
return p;