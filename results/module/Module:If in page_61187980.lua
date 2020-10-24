local p = {}
local getArgs = require('Module:Arguments').getArgs

--args: 1 - ustring pattern, 2 - value if present, 3 - value if absent, 
--      page - page to test if not this page

function p._main(args)
	if not args["page"] then
		args.page = mw.title.getCurrentTitle().fullText
	end
	local page = mw.title.new(args.page)
	if not page then
		--bad title
		return args["3"] or ""
	end
	local content = page:getContent()
	if not content then
		--page does not exist
		return args["3"] or ""
	end
	if mw.ustring.match(content, args["1"] or "") then
		if args["sub"] then
			--return value should have capture groups substed in
			local pattern = args["1"] or ""
			if mw.ustring.sub(pattern, 1, 1) ~= "^" then
				--pattern does not force it to be at start of page
				pattern = "^.-" .. pattern
			end
			if mw.ustring.sub(pattern, -1) ~= "$" then
				--pattern does not force it to be at end of page
				pattern = pattern .. ".*$"
			end
			--pattern will now match entire content, so running gsub will
			--return the string that has been passed in parameter 2 with things
			--like %1 substituted, NOTE: %0 does not work in this
			local out = mw.ustring.gsub(content, pattern, args["2"] or "")
			return out
		else
			return args["2"] or ""
		end
	else
		return args["3"] or ""
	end
end

function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

return p