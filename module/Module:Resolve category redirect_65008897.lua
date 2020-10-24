local p = {}

--Returns the target of {{Category redirect}}, if it exists, else returns the original cat.
--Used by catlinkfollowr(), and so indirectly by all nav_*().
function rtarget( cat )
	local catcontent = mw.title.new( cat or '', 'Category' ):getContent()
	if string.match( catcontent or '', '{{ *[Cc]at' ) then
		local regex = {
			--the following 11 pages (7 condensed) redirect to [[Template:Category redirect]] (as of 6/2019):
			{ '1', '{{ *[Cc]ategory *[Rr]edirect' }, --most likely match 1st
			{ '2', '{{ *[Cc]at *redirect' },         --444+240 transclusions
			{ '3', '{{ *[Cc]at *redir' },            --8+3
			{ '4', '{{ *[Cc]ategory *move' },        --6
			{ '5', '{{ *[Cc]at *red' },              --6
			{ '6', '{{ *[Cc]atr' },                  --4
			{ '7', '{{ *[Cc]at *move' },             --0
		}
		for k, v in pairs (regex) do
			local rtarget = mw.ustring.match( catcontent, v[2]..'%s*|%s*([^|}]+)' )
			if rtarget then
				rtarget = mw.ustring.gsub(rtarget, '^1%s*=%s*', '')
				rtarget = string.gsub(rtarget, '^[Cc]ategory:', '')
				return rtarget
			end
		end
	end
	return cat
end

function p.main( frame )
	local args = frame:getParent().args
	local cat  = args[1]
	
	if (cat == "") or (cat == nil) then
		return ""
	end
	return rtarget( cat )
	
end

return p