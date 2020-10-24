require('Module:No globals')

local p = {}

local getTargetFromText = require('Module:Redirect').getTargetFromText
local messageBox

local mboxText = "%s'''The purpose of this redirect is currently being discussed by the Wikipedia community."
	.. " The outcome of the discussion may result in a change of this page, or possibly its deletion in accordance with Wikipedia's [[Wikipedia:Deletion policy|deletion policy]].''' <br />"
	.. " Please share your thoughts on the matter at '''[[Wikipedia:Redirects for discussion/Log/%s %s %s#%s|this redirect's entry]]''' on the [[Wikipedia:Redirects for discussion|Redirects for discussion]] page.<br />"
	.. "  '''Click on the link below''' to go to the current destination page.<br />"
	.. "<small>Please notify the good-faith creator and any main contributors of the redirect by placing <code>&#123;&#123;[[Wikipedia:Substitution|subst]]:[[Template:Rfd notice|Rfd notice]]&#124;%s&#125;&#125; &#126;&#126;&#126;&#126;</code> on their talk page.</small>"
local errorMessage = '<span class="error">Error: Unable to determine the redirect\'s target. If this page is a soft redirect, then this error can be ignored. Otherwise, please make sure that [[WP:RFD#HOWTO|the instructions for placing this tag]] were followed correctly, in particular that the redirect\'s old content was passed in the <code>content</code> parameter.</span><br />'
local deleteReason = '[[Wikipedia:Redirects for discussion]] debate closed as delete'
local messageOnTransclusions = '<div class="boilerplate metadata plainlinks" id="rfd-t" style="'
    .. 'background-color: transparent; padding: 0; font-size:xx-small; color:#000000; text-align:'
    .. 'center; border-bottom:1px solid #AAAAAA;">&lsaquo;The [[Wikipedia:Template namespace|template]]'
    .. ' below is included via a [[Wikipedia:Redirect|redirect]] ([[%s]]) that has been proposed for deletion. '
    .. 'See [[Wikipedia:Redirects for discussion/Log/%s %s %s#%s|redirects for discussion]] to help reach a consensus' 
    .. ' on what to do.&rsaquo;</div >'
local function makeRfdNotice(args)
	local currentTitle = mw.title.getCurrentTitle()
	if not messageBox then
		messageBox = require('Module:Message box')
	end
	local discussionPage = args[1] and mw.text.trim(args[1])
	if discussionPage == '' then
		discussionPage = nil
	end
	local target = getTargetFromText(args.content)
	local isError = not target or not mw.title.new(target)
	local category
	if args.category then
		category = args.category
	elseif args.timestamp then
                -- Extract stable year and month from timestamp; args.month and args.year can change if the discussion is relisted (see [[Special:Diff/896302321]])
                local lang = mw.language.getContentLanguage()
                local catMonth = lang:formatDate('F', args.timestamp)
                local catYear = lang:formatDate('Y', args.timestamp)
		category = string.format('[[Category:Redirects for discussion from %s %s|%s]][[Category:All redirects for discussion|%s]]', catMonth, catYear, currentTitle.text, currentTitle.text)
	else
		category = string.format('[[Category:Redirects for discussion|%s]][[Category:All redirects for discussion|%s]]', currentTitle.text, currentTitle.text)
	end
	if category then category = category..'[[Category:Temporary maintenance holdings]]' end
	return string.format('%s<span id="delete-reason" style="display:none;">%s</span>%s%s',
		messageBox.main('mbox', {
			type = 'delete',
			image = 'none',
			text = string.format(mboxText, isError and errorMessage or '', args.year, args.month, args.day, discussionPage or currentTitle.prefixedText, mw.text.nowiki(currentTitle.prefixedText))
		}),
		mw.uri.encode(deleteReason),
		category,
		isError and '[[Category:RfD errors]]' or ''
	)
end

p[''] = function(frame)
	local args = frame.args
	if not args.content or mw.text.trim(args.content) == '' then
		return '<span class="error">Error: No content was provided. The original text of the page (the #REDIRECT line and any templates) must be placed inside of the content parameter.[[Category:RfD errors]]</span>'
	end
	local pframe = frame:getParent()
	if pframe:preprocess('<includeonly>1</includeonly>') == '1' then
		-- We're being transcluded, so display the content of our target.
		local target = getTargetFromText(args.content)
		if target then
			target = mw.title.new(target)
		end
		local redirect = pframe:getTitle()
		if target and not target.isRedirect and target ~= redirect then
			-- We should actually be calling expandTemplate on the grandparent rather than on the parent, but we can't do that yet
			-- Since we don't have grandparent access, though, it means the thing we're calling doesn't either, so it doesn't really matter yet
			local parsedTarget = pframe:expandTemplate{title = ':' .. target.prefixedText, args = pframe.args}
			if frame.args.showontransclusion and not mw.isSubsting() then
				local discussionPage = args[1] and mw.text.trim(args[1])
				if not discussionPage or discussionPage == '' then
					discussionPage = redirect
				end
				return messageOnTransclusions:format(redirect, args.year, args.month, args.day, discussionPage) .. parsedTarget
			else
				return parsedTarget
			end
		end
	end
	-- We're not being transcluded, or we can't figure out how to display our target.
	-- Display the RfD banner.
	return makeRfdNotice(frame.args) .. '\n' .. frame.args.content
end

local substText = "{{<includeonly>safesubst:</includeonly>#invoke:RfD||%s%s|%s%s\n"
	.. "<!-- The above content is generated by {{subst:rfd}}. -->\n<!-- End of RFD message. Don't edit anything above here, but feel free to edit below here. -->|content=\n%s\n"
	.. "<!-- Don't add anything after this line unless you're drafting a disambiguation page or article to replace the redirect. -->\n}}"
local dateText = 'month = %B\n|day = %e\n|year = %Y\n|time = %R\n|timestamp = %Y%m%d%H%M%S'

-- called during subst when the template is initially placed on the page
function p.main(frame)
	local titleText
	local pframe = frame:getParent()
	local pargs = pframe.args
	local Date
	if pargs.days then
		Date = os.date(dateText, os.time() - 86400*pargs.days)
	else
		Date = os.date(dateText)
	end
	local retval = string.format(substText, pargs.FULLPAGENAME or pargs[1] or '', pargs.showontransclusion and '|showontransclusion=1' or '', Date, pframe:getTitle() == mw.title.getCurrentTitle().prefixedText and '|category=' or '', pargs.content or '')
	if mw.isSubsting() then
		return retval
	else
		return frame:expandTemplate{title = 'Template:Error:must be substituted', args = {'rfd'}} .. frame:preprocess(retval)
	end
end

return p