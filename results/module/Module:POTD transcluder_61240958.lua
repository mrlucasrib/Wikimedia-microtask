local p = {}

function p.transclude( frame )
	local page = frame.args[1] or error( 'No page was specified' )
	local wikitext = mw.title.new( page ):getContent()
	if wikitext == nil then
		return '[[:' .. page .. ']] does not exist'
	end
	
	local n = string.match( wikitext, '^{{POTD/%d%d%d%d%-%d%d%-%d%d/{{#invoke:random|number|(%d+)}}|{{{1|{{{style|default}}}}}}}}' )
	if n == nil then
		n = string.match( wikitext, '^{{POTD protected/%d%d%d%d%-%d%d%-%d%d/{{#invoke:random|number|(%d+)}}|{{{1|{{{style|default}}}}}}}}' )
	end
	if n == nil then
		return frame:expandTemplate{ title = page, args = { 'row' } }
	end
	
	local t = {}
	for i = 1, tonumber( n ) do
		t[i] = frame:expandTemplate{ title = page .. '/' .. i, args = { 'row' } }
	end
	return table.concat( t, "\n" )
end

return p