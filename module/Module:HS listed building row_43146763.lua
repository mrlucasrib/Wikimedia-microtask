require('Module:No globals')
local genBuffer = require('Module:OutputBuffer')
local getArgs = require('Module:Arguments').getArgs
local delink = require('Module:Delink')._delink
local coord -- lazily loaded

local p = {}

function p.row(frame)
	local getBuffer, print, printf = genBuffer()
	local args = getArgs(frame, {wrappers = 'Template:HS listed building row'})
	local delinkedName = delink{args.name}
	printf('|- class="vcard %s;text-align:center"\n', args.image and 'with_image' or 'without_image')
	printf('| class="fn org" | %s\n', args.name or '')
	printf('| class="label" | %s\n', args.location or '')
	printf('| %s\n', args.date_listed or '')
	printf('| %s\n',
		args.grid_ref and frame:expandTemplate{title = 'Template:Gbmappingsmall', args = {args.grid_ref}} or ''
	)
	local coordText
	if args.lat then
		if not coord then
			coord = require('Module:Coordinates')._coord
		end
		coordText = coord{args.lat, args.lon, format = 'dms', display = 'inline', name = delinkedName}
	else
		coordText = ''
	end
	local categoryText
	if args.category then
		categoryText = "Category&nbsp;" .. args.category
	else
		categoryText = ''
	end
	printf('| %s\n', coordText)
	printf('| class="note" | %s\n', args.notes or categoryText or '')
	printf('| class="uid" | [http://portal.historicenvironment.scot/designation/LB%s %s]\n', args.hb or args.hbnum or '', args.hb or args.hbnum or '')
	if args.image then
		printf(
			' |[[File:%s|150x150px|%s]]<p class="plainlinks" style="margin: 0 auto;"><small>[//commons.wikimedia.org/w/index.php?title=Special:UploadWizard&campaign=wlm-gb-sct&id=%s&descriptionlang=en&description=%s&lat=%s&lon=%s&categories=%s Upload another image]</small><br><small>%s</small></p>\n',
			args.image or '',
			args.name or '',
			mw.uri.encode(args.hb or args.hbnum or ''),
			mw.uri.encode(delinkedName),
			args.lat or '',
			args.lon or '',
			mw.uri.encode(args.commonscat or ''),
			args.commonscat and ('[[:commons:Category:' .. args.commonscat .. '|See more images]]') or ''
		)
	else
		printf('| style="vertical-align:middle;text-align:center" | %s\n',
			frame:expandTemplate{title = 'Template:UploadCampaignLink', args = {campaign = 'wlm-gb-sct', id = args.hb, description = delinkedName, lat = args.lat, lon = args.lon}}
		)
	end
	return getBuffer()
end

return p