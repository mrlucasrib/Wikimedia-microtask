local p = {}

function p._main(frame, name, mode, check)
	local categories = {
		Flagicon = '[[Category:Flagicons with missing country data templates]]',
		Flagdeco = '[[Category:Flagdeco with missing country data templates]]',
	}

	local args={}
	
	if require('Module:Yesno')(frame.args['getParent']) then
		for k,v in pairs(frame:getParent().args) do
			if (v or '') ~= '' then
				args[k] = v
			end
		end
	end
	for k,v in pairs(frame.args) do
		if (v or '') ~= '' then
			args[k] = v
		end
	end
	
	if name == 'Flag+link' then
		args['pref'] = args[1]
	else
		args['variant'] = args[2] or args['variant']
		args[2] = args[1]
	end
	
	args[1] = mode .. (args['opts'] and args['opts'] or '')
	args['missingcategory'] = categories[name] or ''
	args['noredlink'] = args['noredlink'] or 'no'
		
	if require('Module:Yesno')(args['placeholder']) ~= true then
		args[1] = args[1] .. 'o'
	end
	
	if check then
		local opts = {
		unknown=frame:expandTemplate{ title = 'main other', args = { '[[Category:Pages using ' .. mw.ustring.lower(name) .. ' template with unknown parameters|_VALUE_' .. frame:getParent():getTitle() .. ']]' } },
		preview='Page using [[Template:' .. name .. ']] with unknown parameter "_VALUE_"',
		ignoreblank='y',
		[1] = '1',
		[2] = '2',
		[3] = 'variant',
		[4] = 'image',
		[5] = 'size',
		[6] = 'sz',
		[7] = 'border',
		[8] = 'align',
		[9] = 'al',
		[10]= 'width',
		[11]= 'w',
		[12]= 'alt',
		[13]= 'ilink',
		[14]= 'noredlink',
		[15]= 'missingcategory',
		[16]= 'name',
		[17]= 'clink',
		[18]= 'link',
		[19]= 'pref',
		[20]= 'suff',
		[21]= 'plink',
		[22]= 'the',
		[23]= 'section',
		[24]= 'altvar',
		[25]= 'avar',
		[26]= 'age',
		[27]= 'nalign',
		[28]= 'nal',
		[29]= 'text',
		[30]= 'nodata',
		[31]= 'opts',
		[32]= 'placeholder',
		[33]= 'getParent'
		}
	
		check = require('Module:Check for unknown parameters')._check(opts,args)
	else
		check = ''
	end
	
	return require('Module:Flagg').luaMain(frame,args)..check
end
	
function p.main(frame) return p._main(frame,     'Flag',        'uncb',  false) end
p['flag'] = p.main
function p.deco(frame) return p._main(frame,     'Flagdeco',    'uxx',   false) end
p['flagdeco'] = p.deco
function p.icon(frame) return p._main(frame,     'Flagicon',    'cxxl',  true ) end
p['flagicon'] = p.icon
function p.pluslink(frame) return p._main(frame, 'Flag+link',   'unpof', false ) end
p['+link'] = p.pluslink
p['flag+link'] = p.pluslink
function p.country(frame) return p._main(frame,  'Flagcountry', 'unce',  false ) end
p['flagcountry'] = p.country

return p