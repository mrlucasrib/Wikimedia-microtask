local p = {}

-- Color palette and wikitext for the opinion arguments. Each group is only mentioned once, e.g. majority stands for majority, 
-- majority1, majority2, majority3, majority4 and majority5
-- The color comes first in the table, then wikitext for numbered values, then wikitext for non-numbered values, 
-- and finally, human-friendly text that is output to screen reading software used by blind and low vision users.
-- Numbers in the wikitext are taken from the values themselves (e.g. majority1 has the wikitext "1" plus whatever wikitext that is
-- mentioned here.
-- Examples: plurality has the wikitext of "&#42;" and the color "#00CD00"
--           plurality1 has the wikitext of "1*" - "1" is taken from the value itself and "*" comes from this table. It has 
--           the color "#00CD00".
--           Both plurality and plurality1 output the text "delivered the court's opinion" to screen readers.
   
local palette = {
	majority = {"#00CD00", "", "", "delivered the court's opinion"},
	plurality = {"#00CD00", "*", "&#42;", "delivered the court's opinion"},
	concurrence = {"#00B2EE", "", "", "filed a concurrence"},
	concurrencewithoutopinion = {"#00B2EE", "", "-", "filed a concurrence"},
	concurrencedissent = {"#B23AEE", "", "", "filed a concurrence dissent"},
	concurrencedissentwithoutopinion = {"#B23AEE", "", "-", "filed a concurrence dissent"},
	dissent = {"red", "", "", "filed a dissent"},
	dissentwithoutopinion = {"red", "", "-", "filed a dissent without opinion"},
	joinmajority = {"#93DB70", "", "", "joined the court's opinion"},
	partjoinmajority = {"#93DB70", "*", "&#42;", "partially joined the court's opinion"},
	joinplurality = {"#93DB70", "", "", "joined the court's opinion"},
	partjoinplurality = {"#93DB70", "*", "&#42;", "partially joined the court's opinion"},
	joinconcurrence = {"#79CDCD", "", "", "joined a concurrence"},
	partjoinconcurrence = {"#79CDCD", "*", "&#42;", "partially joined a concurrence"},
	joinconcurrencedissent = {"#CC99CC", "", "", "joined a concurrence dissent"},
	partjoinconcurrencedissent = {"#CC99CC", "*", "&#42;", "partially joined a concurrence dissent"},
	joindissent = {"#EE9572", "", "", "joined a dissent"},
	partjoindissent = {"#EE9572", "*", "&#42;", "partially joined a dissent"},
	didnotparticipate = {"white", "", "", "did not participate"},
	statement = {"gray", "", "", "statement"},
	statementwithoutopinion = {"gray", "", "-", "statement without opinion"},
	joinstatement = {"silver", "", "", "joined a statement"},
	partjoinstatement = {"silver", "*", "&#42;", "partially joined a statement"},
	def = "",
}

function p.main(frame)
	local pframe = frame:getParent()
	local args = pframe.args
	
	if args.case then args.case = "''[[" .. args.case .. "]]''" else args.case = nil end
	if args["case1"] then args["case1"] = "''" .. args["case1"] .. "''" else args["case1"] = nil end
	if args["case-article"] then args["case-article"] = "''[[" .. args["case-article"] .. "|" .. args["case-display"] .. "]]''" 
		else args["case-article"] = nil end
	if args.page ~= nil and mw.text.trim(args.page) ~= "" then args.page = args.page else args.page = "___" end
	local entry = mw.html.create("tr")
	entry
		:tag("td")
		:css({
			width = "20px",
			["vertical-align"] = "center"
			})
		:wikitext(args["#"])
		:newline()
		:newline()
		:tag("td")
			:css({
				width = "200px",
				["vertical-align"] = "top"
				})
			:tag("small")
				:wikitext((args.case or "") .. (args["case1"] or "") .. (args["case-article"] or "") .. "," .. (args.note or "") .. 
					' <span class="nowrap">' .. args.volume .. " U.S. " .. (args.page) .. '</span>')
				:done()
			:done()
		:tag("td")
			:css({
				["vertical-align"] = "top",
				["text-align"] = "right"
				})
			:tag("small")
				:wikitext(args["argue-date"] or "")
				:done()
			:done()
		:tag("td")
			:css({
				["vertical-align"] = "top",
				["text-align"] = "right"
				})
			:tag("small")
				:wikitext(args["decision-date"])
	
	local width = {
		[1] = "",
		[2] = "24px",
		[3] = "16px",
		[4] = "12px",
		[5] = "9px",
	}
	local x = 1
	local z = 1
	while x < 9 or args["justice" .. x .. "-opinion1"] ~= nil do
		local entrysupp = mw.html.create("td")
		entrysupp
			:css({
				padding = "0px",
				margin = "0px",
				["vertical-align"] = "top",
				})
			:attr("data-sort-value", args["justice" .. x .. "-sortcode"])
		local entrysuppend = '</td>'
		if args["justice" .. x .. "-opinion1"] ~= nil then
			local subtable = mw.html.create("table")
			subtable
			:css({
				width = "100%",
				height = "3.7em",
				margin = "0px",
				})
			:attr("cellspacing", "0")
			while z < 6 and args["justice" .. x .. "-opinion" .. z] ~= nil and mw.text.trim(args["justice" .. x .. "-opinion" .. z]) ~= "" do
				z = z + 1
			end
			local i = 1
			while i < 6 and args["justice" .. x .. "-opinion" .. i] ~= nil and mw.text.trim(args["justice" .. x .. "-opinion" .. i]) ~= "" do
				if string.find(mw.text.trim(args["justice" .. x .. "-opinion" .. i]), "%d$") then
					opiniontext = string.match(args["justice" .. x .. "-opinion" .. i], "%d") .. (palette[
						string.match(args["justice" .. x .. "-opinion" .. i], "%a+")][2] or "")
				else
					opiniontext = (palette[mw.text.trim(args["justice" .. x .. "-opinion" .. i]) or "def"][3] or "")
				end
				opinion = mw.text.trim(args["justice" .. x .. "-opinion" .. i], "%d$")
				arialabel = 'aria-label="justice ' .. x .. ' ' .. palette[opinion][4] .. '" '
				secuential = '<td ' .. arialabel .. 'style="min-width:' .. width[z-1] .. '; text-align:center; border-right:1px solid lightgray;' ..  
				'background-color:' .. palette[(string.match(args["justice" .. x .. "-opinion" .. i], "%a+") or "def")][1] .. '">' .. 
				opiniontext .. '</td>'
				subtable:node(secuential)
				i = i + 1
			end
			entrysupp:node(subtable)
		end
		entry:node(entrysupp)
		entry:node(entrysuppend)
		x = x + 1
	end
	return tostring(entry)
end

return p