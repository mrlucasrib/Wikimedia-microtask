-- this module may be used by [[Template:POTD row]] to allow for substitution of the
-- [[Template:POTD texttitle]] created when substituting a [[Template:POTD/YYYY-MM-DD]]
-- template with the textitle parameter.
--
-- For example, compare the result from
--   {{subst:POTD/YYYY-MM-DD|texttitle}}
-- with
--   {{subst:#invoke:POTD titletext|main|YYYY-MM-DD}}
--
local p = {}
function p.main(frame)
	local date = frame.args[1]
	local success, result = pcall(frame.expandTemplate, frame, {title = 'POTD/' .. date, args = { 'texttitle'}})
	if success then
		local t = mw.ustring.gsub(result, '[%s]', ' ')
		t = mw.ustring.gsub(t, '.*|[%s]*texttitle[%s]*=', '{{subst:#switch:texttitle|texttitle=')
		success, result = pcall(frame.preprocess, frame, {text = t})
		if success then
			return result
		else
			return '??'
		end
	else
		return '?'
	end
end

return p