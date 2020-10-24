local p = {}
local categoryHandler = require( 'Module:Category handler' ).main
local yesno = require('Module:Yesno')
local mArguments = require('Module:Arguments')
local n

function p.main (frame)
	local fulltitle = frame:getParent():getTitle()
	local templatetitle = string.sub(fulltitle, 10)
	local title = mw.title.getCurrentTitle()
	if mw.title.equals(title, mw.title.makeTitle('Template', title.rootText)) then --if it is on the main template page, load doc
		n = mArguments.getArgs(frame, {parentFirst = true})
		n.variant = n.variant or templatetitle --automatically use title generated from template name
		if  n.doc ~= 'no' then
			return frame:expandTemplate {title = 'English variant notice/documentation', args = n}
		end
	end
	return p._main (frame, templatetitle)
end

function p._main (frame, templatetitle)
	n = mArguments.getArgs(frame, {parentFirst = true})
	n.variant = n.variant or templatetitle --automatically use title generated from template name
	n.category = ''
	n.spelling_examples = n.spelling_examples or n['spelling examples']
	n.bid = not not n.id --bool of n.id, for making iupac and oxford not be added to the id if it doesn't exist
	--Generate the text if it isn't specified
	if not n.text then
		p.modify_text ()
		p.base_text (frame)
	end
	p.cat ('Wikipedia articles that use '..n.variant)
	return p.style(frame)..(n.category or '')
end

function p.cat (category)
	category = string.format ('[[Category:%s]]', category)
	n.category = n.category..(categoryHandler{category, nocat = n.nocat, page = n.page, talk = category, template = category} or '')
end

function p.modify_text ()
	n.spelling = ''
	n.extravariant = ''
	n.extraguide = ''
	bOxford = yesno(n.Oxford)
	bIUPAC = yesno(n.IUPAC)
	chemtext = "; ''aluminium'', ''sulfur'', and ''caesium''"
	if bOxford then
		n.spelling_examples = "''colour'', ''realize'', ''organization'', ''analyse''; note that '''-ize''' is used instead of -ise"
		p.cat ('Wikipedia articles that use Oxford spelling')
		if n.bid then n.id = n.id..n.Oxford end
		if bIUPAC then
			n.extravariant = ' with [[Oxford spelling|Oxford]] and [[IUPAC]] spelling'
			n.spelling_examples= n.spelling_examples..chemtext
			p.IUPAC ()
			return
		end
		n.extravariant = n.extravariant..' with [[Oxford spelling]]'
		return
	elseif bIUPAC then
		n.extravariant = ' with [[IUPAC]] spelling'
		n.spelling_examples = n.spelling_examples and n.spelling_examples..chemtext or "''aluminium'', ''sulfur'', and ''caesium''"
		p.IUPAC ()
		return
	end
	--only if there are spelling examples, put 'has its own spelling conventions'
	if n.spelling_examples then n.spelling = ', which has its own spelling conventions' end
end

function p.IUPAC ()
	n.extraguide = ' and [[Wikipedia:Naming conventions (chemistry)|chemistry naming conventions]]'
	p.cat('Wikipedia articles that use IUPAC spelling')
	n.flag = 'no'
	if n.bid then n.id = n.id..'iupac' end
end

function p.base_text (frame)
	n.subjectspace = require('Module:Pagetype').main()
	n.spelling_examples = n.spelling_examples and string.format(' (%s)', n.spelling_examples) or ''
	n.terms = n[1] or n.terms
	n.terms = n.terms and string.format(' (including %s)', n.terms) or ''
	n.compare = n.compare and (n.compare..' ') or ''
	n.text = string.format([=[This %s is '''written in [[%s]]%s'''%s%s, and some terms that are used in it%s may be different or absent from %sother [[List of dialects of English|varieties of English]]. According to the [[Wikipedia:Manual of Style#National varieties of English|relevant style guide]]%s, this should not be changed without broad consensus.]=],
		n.subjectspace, n.variant, n.extravariant, n.spelling, n.spelling_examples, n.terms, n.compare, n.extraguide)
end

function p.style (frame)
	local size
	if yesno(n.small) then size = '30px'
	elseif n.size then size = n.size
	else size = '50px'
	end
	if n.image then
		if n.flag == nil or yesno(n.flag) then
			n.image = string.format('[[File:%s|%s]]', n.image, size)
		else
			--check if the globe should be "color" instead of "colour"
			if yesno(n.color) then
				n.image = string.format('[[File:Globe spelling color.png|%s]]', size)
			else
				n.image = string.format('[[File:Globe spelling colour.svg|%s]]', size)
			end
		end
	end
	if n.form == 'editnotice' then
		if n.bid then n.id = n.id..'editnotice' end
		n.expiry = n.expiry or 'indefinite'
		--categorize editnotice if specified
		if yesno(n.editnotice_cat) then
			p.cat(string.format('Pages with editnotice %s editnotice', n.variant))
		end
		return frame:expandTemplate{title = 'editnotice', args = n}
	else
		local message_box = require('Module:Message box').main
		if not n.image then n.image = 'none' end
		n['type'] = 'style'
		return message_box ('tmbox', n)
	end	
end

return p