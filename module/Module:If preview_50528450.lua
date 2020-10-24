local p = {}

--[[
main

This function returns the either the first argument or second argument passed to this module, depending on whether it is being previewed.

Usage:
{{#invoke:If preview|main|value_if_preview|value_if_not_preview}}

]]

function p.main(frame)
	local result = ''
	Preview_mode = frame:preprocess('{{REVISIONID}}');							-- use magic word to get revision id
	if not (Preview_mode == nil or Preview_mode == '') then										-- if there is a value then this is not a preiview
		result = frame.args[2] or '';
	else
		result = frame.args[1] or '';									-- no value (nil or empty string) so this is a preview
	end
	return result
end

--[[
pmain

This function returns the either the first argument or second argument passed to this module's parent (i.e. template using this module), depending on whether it is being previewed.

Usage:
{{#invoke:If preview|pmain}}

]]

function p.pmain(frame)
	return p.main(frame:getParent())
end

--[[
boolean

This function returns the either true or false, depending on whether it is being previewed.

Usage:
{{#invoke:If preview|boolean}}

]]

function p.boolean(frame)
	local result = ''
	Preview_mode = frame:preprocess('{{REVISIONID}}');							-- use magic word to get revision id
	if not (Preview_mode == nil or Preview_mode == '') then										-- if there is a value then this is not a preiview
		result = false;
	else
		result = true;									-- no value (nil or empty string) so this is a preview
	end
	return result
end
 
return p