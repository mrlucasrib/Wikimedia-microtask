require('Module:No globals')

local p = {}
local lang = mw.language.getContentLanguage();									-- language object for this wiki
local presentation ={};															-- table of tables that contain currency presentation data
local properties;


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Whether variable is set or not.  A variable is set when it is not nil and not empty.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[[--------------------------< R E N D E R _ C O N V E R T S T R I N G T O N U M E R I C >------------------------------------------------

Renders currency amount with symbol or long-form name.

Also, entry point for other modules.  Assumes that parameters have been vetted; amount is a number, code is upper
case string, long_form is boolean; all are required.

]]

local function render_ConvertStringToNumeric (amount)
	local name;
	local output;

	output = amount;
	output = string.gsub (output , 'thousand', '* 1000' );
	output = string.gsub (output , 'million',  '* 1000000' );
	output = string.gsub (output , 'billion',  '* 1000000000' );
	output = string.gsub (output , 'trillion', '* 1000000000000' );
	output = string.gsub (output , ',', '' );
	return output ;
end

--[[--------------------------< C O N V E R T S T R I N G T O N U M E R I C >--------------------------------------------------------------

Template:ConvertStringToNumeric entry point.  The template takes three parameters:
	positional (1st), |amount=, |Amount=	: digits and decimal points only

]]

local function ConvertStringToNumeric(frame)
	local args = require('Module:Arguments').getArgs (frame);

	local amount;

	if not is_set (args[1]) then
		return '<span style="font-size:inherit" class="error">{{ConvertStringToNumeric}} – invalid amount ([[Template:ConvertStringToNumeric/doc#Error_messages|help]])</span>';
	end
	
	amount = args[1];
	
	return render_ConvertStringToNumeric (amount);
end

return {
	ConvertStringToNumeric = ConvertStringToNumeric,														-- template entry point
	_render_ConvertStringToNumeric = render_ConvertStringToNumeric,											-- other modules entry point
	}