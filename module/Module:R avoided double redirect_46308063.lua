local p = {}

local function noredir(page)
	local link = page:fullUrl("redirect=no")
	return "<span class=\"plainlinks\">[" .. link .. " " .. page.fullText .. "]</span>"
end


function p.main(frame)

	local args = require("Module:Arguments").getArgs(frame, {removeBlanks=false})

	-- Demo parameters, for demonstrating behavior with certain redirect 
	-- targets and avoiding categorization (do not use in articles)
	local noError = args.noerror
	local demo = args.demo or noError or args.thistarget or args.othertarget

	local function formatError(err)
		return "<span class=\"error\">Error in [[Module:R avoided double redirect]]: " .. err .. "</span>"
			.. (demo and "" or "[[Category:Avoided double redirects/error]]")
	end

	local thisPage = mw.title.getCurrentTitle()
	local otherPage = mw.title.new(args[1] or "")
	if not otherPage then
		return formatError("No other page was specified.");
	end
	if mw.title.equals(thisPage, otherPage) then
		return formatError("The current page was passed as the parameter.");
	end

	-- Get mw.title objects for redirect targets.
	-- Note that using mw.title's redirectTarget will correctly handle preview mode, unlike Module:Redirect.
	local thisTarget, otherTarget
	if demo and args.thistarget then
		thisTarget = mw.title.new(args.thistarget)
	else
		thisTarget = thisPage.redirectTarget
	end
	if demo and args.othertarget then
		otherTarget = mw.title.new(args.othertarget)
	else
		otherTarget = otherPage.redirectTarget
	end

	-- For double redirects
	local thisDoubleTarget = thisTarget and thisTarget.redirectTarget
	local otherDoubleTarget = otherTarget and otherTarget.redirectTarget

	local function formatOutput(update, info)
		local from, cat

		if otherTarget then
			from = "an alternative title for '''" .. noredir(otherPage) .. "''', another redirect to the same title"
		else
			from = "an alternative title for '''[[:" .. otherPage.fullText .. "]]''', a former redirect to the same title"
		end
		cat = demo and "" or update and "Avoided double redirects to be updated" or "Avoided double redirects"

		return frame:expandTemplate({
			title = "Redirect template",
			args = {
				from = from,
				info = update and "\n**" .. info or info,
				["all category"] = cat,
				name = "From an avoided double redirect"
			}
		})
	end

	if noError then
		-- Ignore all possible errors, for sample usage display at the top of [[Template:R avoided double redirect]]
	else
		if not thisTarget then
			return formatError("This page is not a redirect.", demo)
		end
		if mw.title.equals(thisPage, thisTarget) then
			return formatOutput(true, "<span class=\"error\">This is a broken redirect (it redirects to itself).</span>")
		end
		if not thisTarget.exists then
			return formatOutput(true, "<span class=\"error\">This is a broken redirect (its target does not exist).</span>")
		end
		if not otherPage.exists then
			return formatOutput(true, "<span class=\"error\">[[:" .. otherPage.fullText .. "]] does not exist.</span>")
		end
		if otherTarget and mw.title.equals(otherPage, otherTarget) then
			return formatOutput(true, "<span class=\"error\">[[:" .. otherPage.fullText .. "]] is a broken redirect (it redirects to itself).</span>")
		end
		if otherTarget and not otherTarget.exists then
			return formatOutput(true, "<span class=\"error\">[[:" .. otherPage.fullText .. "]] is a broken redirect (it redirects to a page that does not exist).</span>")
		end
		if mw.title.equals(thisTarget, otherPage) then
			if not otherTarget then
				return formatOutput(true, "<span class=\"error\">[[:" .. otherPage.fullText .. "]] is not a redirect, and this already points to it.</span> Most likely this template should be removed.")
			end
			if mw.title.equals(otherTarget, thisPage) then
				return formatOutput(true, "<span class=\"error\">This is a circular redirect.</span> Please change the target of both this redirect and " .. noredir(otherPage) .. " to the correct article.")
			end
			return formatOutput(true, "<span class=\"error\">This page redirects to " .. noredir(otherPage) .. ", which redirects to [[:" .. otherTarget.fullText .. "]].</span> Please change this redirect's target to [[:" .. otherTarget.fullText .. "]] or otherwise resolve the situation.")
		end
		if not otherTarget then
			return formatOutput(true, "<span class=\"error\">[[:" .. otherPage.fullText .. "]] is not a redirect.</span> Most likely this redirect should be updated to point to [[:" .. otherPage.fullText .. "]] now that it is no longer a redirect, and this template removed.\n** If that is not the correct target for this redirect, update or remove this template and/or the redirect itself and/or the other page as appropriate.")
		end
		if thisDoubleTarget then
			if otherDoubleTarget then
				if mw.title.equals(thisDoubleTarget, otherDoubleTarget) then
					return formatOutput(true, "<span class=\"error\">Both this page and " .. noredir(otherPage) .. " are double redirects.</span> Please change the redirect target of both to "
						.. (thisDoubleTarget.isRedirect and "the correct article." or "[[" .. thisDoubleTarget.fullText .. "]] (or some other correct article)."))
				end
				return formatOutput(true, "<span class=\"error\">Both this page and " .. noredir(otherPage) .. " are double redirects.</span> Please fix them.")
			end
			return formatOutput(true, "<span class=\"error\">This is a double redirect.</span> Please fix it, possibly by changing it to [[:" .. otherTarget.fullText .. "]].")
		end
		if not mw.title.equals(thisTarget, otherTarget) then
			return formatOutput(true, "<span class=\"error\">This page and " .. noredir(otherPage) .. " redirect to different articles.</span> Most likely you should change this redirect's target to [[:" .. otherTarget.fullText .. "]] to match.\n** If that is not the correct target for this redirect, update or remove this template and/or the redirect itself and/or the other page as appropriate.")
		end

		if thisTarget.fragment ~= otherTarget.fragment then
			-- Should this case report for update?
			return formatOutput(false, "Because [[Wikipedia:Double redirects|double redirects]] are disallowed,"
				.. " both pages currently point to [[" .. otherTarget.prefixedText .. "]] (but with different anchors).\n"
				.. "**If " .. noredir(otherPage) .. " is expanded into a separate article or it is retargeted, "
				.. " this redirect will be recategorized to be updated."
			)
		end
	end

	return formatOutput(false, "Because [[Wikipedia:Double redirects|double redirects]] are disallowed,"
		.. " both pages currently point to [[" .. otherTarget.fullText .. "]].\n"
		.. "**If " .. noredir(otherPage) .. " is expanded into a separate article or it is retargeted, "
		.. " this redirect will be recategorized to be updated."
	)

end

return p