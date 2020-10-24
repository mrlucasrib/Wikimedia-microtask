--[[
TODO:
		all non-English text wrapped in {{lang}}?
		distingush various scripts?  Kanji is ja-Hani ...
		every child infobox should support translit / transcription parameter(s)
		every child infobox should have a literal meaning parameter
		revise parameter names to be IETF language code or obvious derivations thereof
		for error messaging create a separate ibox? else messages are not necessarily visible
]]

require('Module:No globals');
local data = mw.loadData ('Module:Infobox multi-lingual name/data');
local lang_mod = require ('Module:Lang');										-- for various functions and templates provided by Module:Lang
local getArgs = require ('Module:Arguments').getArgs;


--[[--------------------------< I S _ S E T >------------------------------------------------------------------

Returns true if argument is set; false otherwise. Argument is 'set' when it exists (not nil) or when it is not an empty string.

]]

local function is_set( var )
	return not (var == nil or var == '');
end


--[[--------------------------< A N Y _ S E T >----------------------------------------------------------------

Returns true if any member of the table is set; false otherwise. Argument is 'set' when it exists (not nil) or when it is not an empty string.

]]

local function any_set (t)
	for _, v in pairs (t) do
		if is_set (v) then
			return true;
		end
	end
	
	return false;
end


--[[--------------------------< S H O W F L A G >--------------------------------------------------------------

This function handles the |showflag= parameter from the template {{Infobox Chinese}}.  That template passes the
value to {{Infobox Chinese/Chinese}} which calls this function.  This function does not take any frame parameters
but it does require a copy of the frame so that it can expand {{Infobox}}.  All arguments used by this function
come from the args table in the function call

returns a child infobox or an empty string

]]

local function showflag (frame, args)
	local show_flag = args.showflag; 

	if not is_set (show_flag) then
		return '';																-- |showflag= not set so nothing to do; return empty string
	end

	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	infobox_args['child'] = 'yes';												-- showflag infoboxen are always children
	infobox_args['labelstyle'] = 'font-weight:normal';							-- and always have this label style

	if data.transl_map[show_flag] then
		local i=1;
		while (1) do
			local labeln = 'label' .. i;										-- make label index that matches |labeln= parameter 
			local datan = 'data' .. i;											-- make data index that matches |datan= parameter 
			if not data.transl_map[show_flag][labeln] then
				break;															-- not found then done
			end
			infobox_args[labeln] = data.label_map[data.transl_map[show_flag][labeln]];	-- add |labeln=<label text / wikilink>
			infobox_args[datan] = args[data.transl_map[show_flag][datan]];		-- add |datan={{{data}}}
			i = i + 1;															-- bump to next label / data pair
		end
	else
		return '';																-- |showflag= value invalid; TODO: return error message?
	end
	
	return frame:expandTemplate ({title='Infobox', args = infobox_args});
	end


--[[--------------------------< A D D _ L A B E L _ D A T A _ P A I R >----------------------------------------

Adds a label parameter and matching data parameter to infobox arguments table; bumps the enumerator on return

]]

local function add_label_data_pair (infobox_args, label, data, i)
	if is_set (data) then
		infobox_args['label' .. i] = label;										-- make an enumerated label parameter
		infobox_args['data' .. i] = data;										-- make an enumerated data parameter
	
		return i + 1;															-- return bumped enumerator
	end

	return i;																	-- if here, no data so no need to add label or bump enumerator
end


--[[--------------------------< A D D _ T R A N S C R I P T I O N >--------------------------------------------

This function does that repetative work when assembling the parameter list for {{Infobox}} template

inputs are:
	infobox_args - table of infobox parameters
	args - args table from the {{#invoke:}} frame
	idx - index into xscript table
	show - pseudo-boolean (true or nil) header display flag; when true display the header
	i - enumerator for {{infobox}} parameters |headern=, |labeln=, |datan=; in this application i continually
		increments; there are no gaps as there are in the original template
	lang - language code used by {{tlansl}} - must be valid IETF code

returns i for the next time this function is called

]]

local function add_transcription (infobox_args, args, idx, show, i, lang)
	infobox_args['header' .. i] = show and data.xscript[idx].header;			-- if headers are displayed
	i = i + 1;																	-- bump the enumerator
	for _, v in ipairs (data.xscript[idx].t) do									-- each label / data pair in the xscript subtable
		i = add_label_data_pair (infobox_args, v[1], is_set (args[v[2]]) and lang_mod._transl ({lang, args[v[2]], italic = 'no'}), i);	-- enumerator is bumped here
	end
	
	return i;																	-- and done
end


--[[--------------------------< T R A N S C R I P T I O N S _ Z H >--------------------------------------------

transcriptions support for {{Infobox Chinese/Chinese}}.  This function adds headers and label data pairs to
infobox_arg table according to which parameters are set

returns the enumerator in case it is needed

]]

local function transcriptions_zh (infobox_args, args, show, i)
	if any_set ({args.p, args.bpmf, args.gr, args.w, args.tp, args.myr, args.mps, args.mi}) then
		i = add_transcription (infobox_args, args, 'standard mandarin', show, i, 'zh');
	end

	if any_set ({args.xej, args['zh-dungan'], args.sic}) then
		i = add_transcription (infobox_args, args, 'other mandarin', show, i, 'zh');
	end
		
	if any_set ({args.wuu, args.lmz, args.ouji, args.suz}) then					-- ???? ouji was not included here in original template; why?
		i = add_transcription (infobox_args, args, 'wu', show, i, 'wuu');
	end
	
	if is_set (args.gan) then
		i = add_transcription (infobox_args, args, 'gan', show, i, 'gan');
	end
	
	if is_set (args.hsn) then
		i = add_transcription (infobox_args, args, 'xiang', show, i, 'hsn');
	end

	if any_set ({args.h, args.phfs}) then
		i = add_transcription (infobox_args, args, 'hakka', show, i, 'hak');
	end

	if any_set ({args.y, args.ci, args.j, args.sl, args.gd, args.hk, args.mo}) then	-- ???? sl, hk, mo not here in original; why?
		i = add_transcription (infobox_args, args, 'yue cantonese', show, i, 'yue');
	end

	if is_set (args.toi) then
		i = add_transcription (infobox_args, args, 'other yue', show, i, 'yue');
	end

	if any_set ({args.poj, args.tl, args.bp, args.teo, args.hain, args.lizu}) then	-- ???? bp not here in original; why?
		i = add_transcription (infobox_args, args, 'southern min', show, i, 'nan');
	end

	if is_set (args.buc) then
		i = add_transcription (infobox_args, args, 'eastern min', show, i, 'cdo');
	end

	if is_set (args.hhbuc) then
		i = add_transcription (infobox_args, args, 'pu-xian min', show, i, 'cpx');
	end

	if is_set (args.mblmc) then
		i = add_transcription (infobox_args, args, 'northern min', show, i, 'mnp');
	end

	if is_set (args['phagspa-latin']) then										-- phagspa is a script
		i = add_transcription (infobox_args, args, 'old mandarin', show, i, 'zh');
	end

	if any_set ({args.mc, args.emc, args.lmc}) then
		i = add_transcription (infobox_args, args, 'middle chinese', show, i, 'ltc');
	end

	if any_set ({args['oc-b92'], args['oc-bs'], args['oc-zz']}) then
		i = add_transcription (infobox_args, args, 'old chinese', show, i, 'och');
	end

	return i;																	-- return current state of the enumerator
end


--[[--------------------------< T R A N S C R I P T I O N S >--------------------------------------------------

This function handles the transcription infobox called by various {{Infobox Chinese/xxx}}.  Creates header and
label / data pairs according to the presence of certain parameters provided to {{Infobox Chinese}}

]]

local function transcriptions (frame, args, lang)
	if not args then
		args = frame.args;
	end
	local show = 'no' ~= args.hide or nil;										-- make boolean-ish for controlling display of headers; |hide=no means show transcriptions without collapsed header

	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	local i = 1;																-- enumerator used with {{infobox}} |headern=, |labeln=, and |datan= parameters

	if show then
		infobox_args['subbox'] = 'yes';
		infobox_args['above'] = 'Transcriptions';
	else
		infobox_args['child'] = 'yes';
	end
	
	infobox_args['bodyclass'] = 'collapsible collapsed';
	infobox_args['abovestyle'] = 'font-size: 100%; text-align: left; background-color: #f9ffbc;';	-- TODO: #define various colors in a common config location; and function?
	infobox_args['headerstyle'] = 'background-color: #dcffc9;';					-- TODO: #define various colors in a common config location; and function?
	infobox_args['labelstyle'] = 'font-weight:normal;';

	if 'zh' == lang then
		transcriptions_zh (infobox_args, args, show, i);						-- special case because there are various headers etc
	else
		add_transcription (infobox_args, args, data.keys[lang], show, i, lang);			
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});		-- render the infobox and done
	end


--[[--------------------------< I B O X _ B O I L E R P L A T E >----------------------------------------------

boilerplate style settings for the various child infoboxen (not for transcription infoboxen) beause they are
mostly the same child-infobox to child-infobox

TODO: |headercolor= is set to its default color in {{Infobox Chinese}}.  Better here than there isn't it?  less 
maintenence headache when a default value is set in only one place; override in the highest level appropriate
but leave the default here.  in the higher-level template(s) remove |headercolor= default values

]]

local function ibox_boilerplate (infobox_args, args)
	infobox_args['child'] = 'yes';
	local h_color;
	if is_set (args.headercolor) then
		h_color = args.headercolor;
	else
		h_color = '#b0c4de'														-- TODO: #define various colors in a common config location; and / or function?
	end
	
	infobox_args['headerstyle'] = 'background-color: ' ..  h_color .. ';';
	
	if is_set (args.fontstyle) then												-- ???? |fontstyle= not a documented parameter; supported by {{Infobox Chinese/Korean}} and {{Infobox Chinese/Vietnamese}}
		infobox_args['labelstyle'] = 'font-weight:' .. fontstyle .. ';';
	else
		infobox_args['labelstyle'] = 'font-weight:normal;';
	end
	
end


--[[--------------------------< I B O X _ M L N _ Z H >--------------------------------------------------------

bypasses {{Infobox Chinese/Chinese}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_zh}}

]]

local function ibox_mln_zh (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()

	ibox_boilerplate (infobox_args, args)	

	if 'none' ~= args.header and 'none' ~= args.chinese_header then
		infobox_args['header1'] = args.header or args.chinese_header or 'Chinese name';
	end

	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Chinese language|Chinese]]', is_set (args.c) and lang_mod._lang ({'zh-Hani', args.c, size = '1rem'}), i)

	if 'st' == args.order then
		i = add_label_data_pair (infobox_args, '[[Simplified Chinese characters|Simplified Chinese]]', is_set (args.s) and lang_mod._lang ({'zh-Hans', args.s, size = '1rem'}), i)
		i = add_label_data_pair (infobox_args, '[[Traditional Chinese characters|Traditional&nbsp;Chinese]]', is_set (args.t) and lang_mod._lang ({'zh-Hant', args.t, size = '1rem'}), i)
	else
		i = add_label_data_pair (infobox_args, '[[Traditional Chinese characters|Traditional&nbsp;Chinese]]', is_set (args.t) and lang_mod._lang ({'zh-Hant', args.t, size = '1rem'}), i)
		i = add_label_data_pair (infobox_args, '[[Simplified Chinese characters|Simplified Chinese]]', is_set (args.s) and lang_mod._lang ({'zh-Hans', args.s, size = '1rem'}), i)
	end

	if is_set (args.phagspa) then												-- ???? this parameter isn't passed from {{Infobox Chinese}} to {{infobox Chinese/Chinese}}
		i = add_label_data_pair (infobox_args, '[[\'Phags-pa script]]', frame:expandTemplate ({title='Phagspa', args = {'h', args.phagspa, args['phagspa-latin'], size = 12}}), i)
	end

	infobox_args['data' .. i] = showflag (frame, args);							-- needs frame so that it can frame:expandTemplate()
	i = i + 1;
																				-- ???? why is this transliteration here and not part of the transcription list?
	i = add_label_data_pair (infobox_args, '[[Chinese postal romanization|Postal]]', is_set (args.psp) and args.psp or nil, i)

	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.l) and args.l or nil, i)

	if 'no' == args.hide then
		infobox_args['rowstyle' .. i] = 'display:none;';
		infobox_args['rowcellstyle' .. i] = 'display:none;';
	end
	
	if any_set ({args.c, args.t, args.p, args.s, args.phagspa}) then			-- ???? phagspa not passed into {{infobox Chinese/Chinese}}  Why?
		infobox_args['data' .. i] = transcriptions (frame, args, 'zh');			-- needs frame so that it can frame:expandTemplate()
	end
	
	return frame:expandTemplate ({title='Infobox', args = infobox_args});
	end

	
--[[-------------------------< I B O X _ M L N _ A R >---------------------------------------------------------

implements {{Infobox Chinese/Arabic}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_ar}}

Template:Infobox_Arabic_term/testcases

TODO: standardize on lowercase parameter names for transcriptions

]]

local function ibox_mln_ar (frame, args)
	if not args then
		args = getArgs (frame);													--, {removeBlanks = false}?
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()

	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.arabic_header then
		infobox_args['header1'] = args.header or args.arabic_header or 'Arabic name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Arabic]]', is_set (args.arabic) and args.arabic or nil, i)
	i = add_label_data_pair (infobox_args, '[[Romanization of Arabic|Romanization]]', is_set (args.arabic_rom) and args.arabic_rom or nil, i)
	i = add_label_data_pair (infobox_args, '[[Help:IPA for Arabic|IPA]]', is_set (args.arabic_ipa) and args.arabic_ipa or nil, i)
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.arabic_lit) and args.arabic_lit or nil, i)

	if any_set ({args.chat, args.Chat, args['ala-lc'], args['ALA-LC'], args.iso, args.ISO, args.din, args.DIN}) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'ar');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ B L A N K >---------------------------------------------------

implements {{Infobox Chinese/Blank}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_blank}}

]]

local function ibox_mln_blank (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	local ietf_tag = lang_mod._is_ietf_tag (args.lang);
	local name_from_tag = ietf_tag and lang_mod._name_from_tag ({args.lang}) or nil;

	if 'none' ~= args.lang_hdr and 'none' ~= args.header and 'none' ~= args.blank_header then
		if is_set (args.lang_hdr) or is_set (args.header) or is_set (args.blank_header) then				-- if one of these
			infobox_args['header1'] = args.lang_hdr or args.header or args.blank_header;			-- make a header from it
		elseif ietf_tag then
			infobox_args['header1'] = name_from_tag .. ' name';				-- make a header from the language name
		else
			infobox_args['header1'] = args.lang .. ' name';						-- not a code so use whatever text is in {{{lang}}}
		end
	end
	
	local i = 2;
	local label;
	local data;
	
	if name_from_tag then
		if is_set (args.lang_article) then
			label = table.concat ({												-- make a linked label from provided article name
				'[[',
				args.lang_article,
				'|',
				args.lang_label or name_from_tag,
				']]'
				});
		else
			label = args.lang_label or lang_mod._name_from_tag ({args.lang, ['link'] = 'yes'})	-- let lang module make the correct linked label
		end
	
		data = lang_mod._lang ({args.lang, args.lang_content});	
	else
		label = args.lang_label or args.lang;									-- fall back
		data = args.lang_content;
	end
	
	i = add_label_data_pair (infobox_args, label, data, i);
	if is_set (args.lang_rom) and ietf_tag then
		i = add_label_data_pair (infobox_args, args.lang_std or 'Romanization', lang_mod._transl ({args.lang, args.lang_rom}), i);
	end
	i = add_label_data_pair (infobox_args, 'IPA', args.lang_ipa, i);
	i = add_label_data_pair (infobox_args, 'Literal meaning', args.lang_lit, i);

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ B O >---------------------------------------------------------

implements {{Infobox Chinese/Tibetan}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_bo}}

]]

local function ibox_mln_bo (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.tibetan_header then
		infobox_args['header1'] = args.header or args.tibetan_header or 'Tibetan name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Tibetan alphabet|Tibetan]]', is_set (args.tib) and frame:expandTemplate ({title='Bo-textonly', args = {lang = 'bo', args.tib}}) or nil, i)
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.literal_tibetan) and args.literal_tibetan or nil, i)

	if any_set ({args.wylie, args.thdl, args.zwpy, args.lhasa}) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'bo');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ D N G >-------------------------------------------------------

implements {{Infobox Chinese/Dunganese}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_dng}}

]]

local function ibox_mln_dng (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.dunganese_header then
		infobox_args['header1'] = args.header or args.dunganese_header or 'Dunganese name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Dungan language|Dungan]]', is_set (args.dungan) and args.dungan or nil, i)
	i = add_label_data_pair (infobox_args, '[[Xiao\'erjing]]', is_set (args['dungan-xej']) and args['dungan-xej'] or nil, i)
	i = add_label_data_pair (infobox_args, '[[Romanization]]', is_set (args['dungan-latin']) and args['dungan-latin'] or nil, i)
	i = add_label_data_pair (infobox_args, '[[Hanzi]]', is_set (args['dungan-han']) and args['dungan-han'] or nil, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ H O K K I E N >-----------------------------------------------

implements {{Infobox Chinese/Hokkien}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_hokkien}}

Template:Infobox Hokkien name/testcases

]]

local function ibox_mln_hokkien (frame, args)
	if not args then
		args = getArgs (frame);													--, {removeBlanks = false}?
	end
	local show = 'no' ~= args.hide or nil;										-- make boolean-ish for controlling display of headers; |hide=no means show transcriptions without collapsed header
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.hokkien_header then
		infobox_args['header1'] = args.header or args.hokkien_header or 'Hokkien name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Hàn-jī]]', is_set (args.hanji) and lang_mod._lang ({'nan', args.hanji, size = '115%'}) or nil, i);
	i = add_label_data_pair (infobox_args, '[[Pe̍h-ōe-jī]]', is_set (args.poj) and lang_mod._lang ({'nan', args.poj, size = '115%'}) or nil, i);
	i = add_label_data_pair (infobox_args, '[[Hàn-lô]]', is_set (args.hanlo) and lang_mod._lang ({'nan', args.hanlo, size = '115%'}) or nil, i);
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.lm) and args.lm or nil, i)

	if show then
		if any_set ({args.tl, args.bp, args.hokkienipa}) then
			infobox_args['data' .. i] = transcriptions (frame, args, 'hokkien');	-- needs frame so that it can frame:expandTemplate()
		end
	else
		i = add_label_data_pair (infobox_args, '[[Taiwanese Romanization System|Tâi-lô]]', is_set (args.tl) and args.tl or nil, i)
		i = add_label_data_pair (infobox_args, '[[Bbánlám pìngyīm|Bbánpìng]]', is_set (args.bp) and args.bp or nil, i)
		i = add_label_data_pair (infobox_args, '[[Help:IPA for Hokkien|IPA]]', is_set (args.hokkienipa) and args.hokkienipa or nil, i)
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ J A >---------------------------------------------------------

implements {{Infobox Chinese/Japanese}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_ja}}

]]

local function ibox_mln_ja (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.japanese_header then
		infobox_args['header1'] = args.header or args.japanese_header or 'Japanese name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Kanji]]', is_set (args.kanji) and lang_mod._lang ({'ja', args.kanji}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Kana]]', is_set (args.kana) and lang_mod._lang ({'ja', args.kana}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Hiragana]]', is_set (args.hiragana) and lang_mod._lang ({'ja', args.hiragana}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Katakana]]', is_set (args.katakana) and lang_mod._lang ({'ja', args.katakana}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Kyūjitai]]', is_set (args.kyujitai) and lang_mod._lang ({'ja', args.kyujitai}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Shinjitai]]', is_set (args.shinjitai) and lang_mod._lang ({'ja', args.shinjitai}) or nil, i)

	if any_set ({args.romaji, args.revhep, args.tradhep, args.kunrei, args.nihon}) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'ja');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ K O >---------------------------------------------------------

implements {{Infobox Chinese/Korean}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_ko}}

]]

local function ibox_mln_ko (frame, args)
	if not args then
		args = frame.args;
	end
	local show = 'no' ~= args.hide or nil;										-- make boolean-ish for controlling display of headers; |hide=no means show transcriptions without collapsed header
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.korean_header then
		infobox_args['header1'] = args.header or args.korean_header or 'Korean name';
	end
	
	local i = 2;
	
	if 'yes' == args.northkorea then
		i = add_label_data_pair (infobox_args, '[[Hangul|Chosŏn\'gŭl]]', is_set (args.hangul) and lang_mod._lang ({'ko', args.hangul, size = '1rem'}) or nil, i)
	elseif 'old' == args.northkorea then
		i = add_label_data_pair (infobox_args, '[[Hunminjeongeum]]', is_set (args.hangul) and lang_mod._lang ({'ko', args.hangul, size = '1rem'}) or nil, i)
	else
		i = add_label_data_pair (infobox_args, '[[Hangul]]', is_set (args.hangul) and lang_mod._lang ({'ko', args.hangul, size = '1rem'}) or nil, i)
	end

	if 'yes' == args.northkorea then
		i = add_label_data_pair (infobox_args, '[[Hanja|Hancha]]', is_set (args.hanja) and lang_mod._lang ({'ko', args.hanja, size = '1rem'}) or nil, i)
	else
		i = add_label_data_pair (infobox_args, '[[Hanja]]', is_set (args.hanja) and lang_mod._lang ({'ko', args.hanja, size = '1rem'}) or nil, i)
	end
	
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.lk) and args.lk or nil, i)

	if show then
		if any_set ({args.mr, args.rr}) then
			infobox_args['data' .. i] = transcriptions (frame, args, 'ko');		-- needs frame so that it can frame:expandTemplate()
		end
	else
		i = add_label_data_pair (infobox_args, '[[Revised Romanization of Korean|Revised Romanization]]', is_set (args.rr) and lang_mod._transl ({'ko', 'rr', args.rr}) or nil, i)
		i = add_label_data_pair (infobox_args, '[[McCune–Reischauer]]', is_set (args.mr) and lang_mod._transl ({'ko', 'mr', args.mr}) or nil, i)
		i = add_label_data_pair (infobox_args, '[[Help:IPA/Korean|IPA]]', is_set (args.koreanipa) and args.koreanipa or nil, i)
	end
	
	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ M N >---------------------------------------------------------

implements {{Infobox Chinese/Mongolian}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_mn}}

]]

local function ibox_mln_mn (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.mongolian_header then
		infobox_args['header1'] = args.header or args.mongolian_header or 'Mongolian name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Mongolian Cyrillic script|Mongolian Cyrillic]]',
		is_set (args.mon) and lang_mod._lang ({'mn', args.mon}) or nil, i)
--	i = add_label_data_pair (infobox_args, '[[Mongolian language|Mongolian]]',	-- TODO: weird construct in original template; is this one required?
--		is_set (args.mong) and lang_mod._lang ({'mn', frame:expandTemplate ({title='MongolUnicode', args = {args.mong}}) }) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Mongolian script]]',
		is_set (args.mong) and lang_mod._lang ({'mn', frame:expandTemplate ({title='MongolUnicode', args = {args.mong}}) }) or nil, i)

	if is_set (args.monr) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'mn');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ M N C >-------------------------------------------------------

implements {{Infobox Chinese/Manchu}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_mnc}}

]]

local function ibox_mln_mnc (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.manchu_header then
		infobox_args['header1'] = args.header or args.manchu_header or 'Manchu name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Manchu alphabet|Manchu script]]', is_set (args.mnc) and frame:expandTemplate ({title='ManchuSibeUnicode', args = {lang='mnc', args.mnc}}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Transliterations of Manchu|Romanization]]', is_set (args.mnc_rom) and args.mnc_rom or nil, i)
	i = add_label_data_pair (infobox_args, '[[Transliterations of Manchu|Abkai]]', is_set (args.mnc_a) and args.mnc_a or nil, i)
	i = add_label_data_pair (infobox_args, '[[Transliterations of Manchu|Möllendorff]]', is_set (args.mnc_v) and args.mnc_v or nil, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ M Y >---------------------------------------------------------

implements {{Infobox Chinese/Burmese}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_my}}

]]

local function ibox_mln_my (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.burmese_header then
		infobox_args['header1'] = args.header or args.burmese_header or 'Burmese name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Burmese language|Burmese]]', is_set (args.my) and args.my or nil, i)
	i = add_label_data_pair (infobox_args, '[[Wikipedia:IPA_for_Burmese|IPA]]', is_set (args.bi) and args.bi or nil, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ R U >---------------------------------------------------------

implements {{Infobox Chinese/Russian}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_ru}}

]]

local function ibox_mln_ru (frame, args)
	if not args then
		args = getArgs (frame);
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.russian_header then
		infobox_args['header1'] = args.header or args.russian_header or 'Russian name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Russian language|Russian]]', is_set (args.rus) and lang_mod._lang ({'ru', args.rus}) or nil, i);
	i = add_label_data_pair (infobox_args, '[[Romanization of Russian|Romanization]]', is_set (args.rusr) and lang_mod._lang ({'ru-Latn', args.rusr}) or nil, i);	--TODO: use transl instead?
	i = add_label_data_pair (infobox_args, '[[Wikipedia:IPA for Russian|IPA]]', is_set (args.rusipa) and args.rusipa or nil, i);
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.ruslit) and args.ruslit or nil, i);

	if any_set ({args.scientific, args.Scientific, args.iso, args.ISO, args.gost, args.GOST, args['bgn/pcgn'], args['BGN/PCGN']}) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'ru');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ T H >---------------------------------------------------------

implements {{Infobox Chinese/Thai}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_th}}

]]

local function ibox_mln_th (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.thai_header then
		infobox_args['header1'] = args.header or args.thai_header or 'Thai name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Thai language|Thai]]', (is_set (args.th) or is_set (args.tha)) and lang_mod._lang ({'th', args.th or args.tha}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Royal Thai General System of Transcription|RTGS]]', is_set (args.rtgs) and lang_mod._transl ({'th', 'rtgs', args.rtgs}) or nil, i)
	i = add_label_data_pair (infobox_args, 'Romanization', is_set (args.rom) and lang_mod._transl ({'th', args.rom}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[International Phonetic Alphabet|IPA]]', is_set (args.ipa) and args.ipa, i)
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.lit) and args.lit, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ U G >---------------------------------------------------------

implements {{Infobox Chinese/Uyghur}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_ug}}

]]

local function ibox_mln_ug (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.uyghur_header then
		infobox_args['header1'] = args.header or args.uyghur_header or 'Uyghur name';
	end
	
	local i = 2;
	
	i = add_label_data_pair (infobox_args, '[[Uyghur language|Uyghur]]', is_set (args.uig) and frame:expandTemplate ({title='ug-textonly', args = {args.uig}}) or nil, i)
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.lu) and args.lu or nil, i)

	if any_set ({args.uly, args.uyy, args.sgs, args.usy, args.uipa}) then
		infobox_args['data' .. i] = transcriptions (frame, args, 'ug');			-- needs frame so that it can frame:expandTemplate()
	end

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ V I >---------------------------------------------------------

implements {{Infobox Chinese/Vietnamese}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_vi}}

]]

local function ibox_mln_vi (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.vietnamese_header then
		infobox_args['header1'] = args.header or args.vietnamese_header or 'Vietnamese name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Vietnamese language|Vietnamese]]', is_set (args.vie) and lang_mod._lang ({'vi', args.vie}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Vietnamese alphabet]]', is_set (args.qn) and lang_mod._lang ({'vi', args.qn}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Hán-Nôm]]', is_set (args.hn) and lang_mod._lang ({'vi-Hani', args.hn}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Chữ Hán]]', is_set (args.chuhan) and lang_mod._lang ({'vi-Hani', args.chuhan}) or nil, i)
	i = add_label_data_pair (infobox_args, '[[Chữ Nôm]]', is_set (args.chunom) and lang_mod._lang ({'vi-Hani', args.chunom}) or nil, i)
	i = add_label_data_pair (infobox_args, 'Literal meaning', is_set (args.lqn) and args.lqn or nil, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ Z A >---------------------------------------------------------

implements {{Infobox Chinese/Zhuang}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_za}}

]]

local function ibox_mln_za (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	
	ibox_boilerplate (infobox_args, args);

	if 'none' ~= args.header and 'none' ~= args.zhuang_header then
		infobox_args['header1'] = args.header or args.zhuang_header or 'Zhuang name';
	end
	
	local i = 2;

	i = add_label_data_pair (infobox_args, '[[Zhuang language|Zhuang]]', is_set (args.zha) and ('<span style="font-family: Arial Unicode MS, sans-serif;">' .. args.zha .. '</span>') or nil, i)
	i = add_label_data_pair (infobox_args, '[[Zhuang language|1957 orthography]]', is_set (args.zha57) and args.zha57 or nil, i)
	i = add_label_data_pair (infobox_args, '[[Sawndip]]', is_set (args.sd) and args.sd or nil, i)

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ M L N _ H E A D E R >-------------------------------------------------

bypasses {{Infobox Chinese/Header}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_header}}

]]

local function ibox_mln_header (frame, args)
	if not args then
		args = getArgs (frame);
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()

	infobox_args['decat'] = 'yes';
	infobox_args['child'] = is_set (args.child) and args.child or 'yes';
--	infobox_args['bodystyle'] = is_set (args.float) and 'float: left; clear: left; margin: 0 1em 1em 0;' or nil;
--	infobox_args['bodyclass'] =  is_set (args.collapse) and ('collapsible' .. ('yes' == args.collapse and ' collapsed' or '')) or nil;


	local h_color;
	if is_set (args.headercolor) then
		h_color = args.headercolor;
	else
		h_color = '#b0c4de'														-- TODO: #define various colors in a common config location; and function?
	end

--	infobox_args['subheaderstyle'] = 'font-size: 125%; background-color:' .. h_color .. ';';
--	infobox_args['subheader'] = is_set (args.title) and args.title or mw.title.getCurrentTitle().text;
	infobox_args['image'] = frame:callParserFunction ({name = '#invoke:InfoboxImage',
		args =
			{
			'InfoboxImage',
			image = args.pic,
			sizedefault = 'frameless',
			size = args.picsize,
			upright = args.picupright,
			alt = args.picalt or args.pictooltip
			}
		});

	infobox_args['caption'] = is_set (args.piccap) and args.piccap or nil;

	infobox_args['image2'] = frame:callParserFunction ({name = '#invoke:InfoboxImage',
		args =
			{
			'InfoboxImage',
			image = args.pic2,
			sizedefault = 'frameless',
			size = args.picsize2,
			upright = args.picupright2,
			alt = args.picalt2 or args.pictooltip2
			}
		});

	infobox_args['caption2'] = is_set (args.piccap2) and args.piccap2 or nil;
	
	infobox_args['headerstyle'] = 'background-color:' .. h_color;
	infobox_args['headerstyle'] = 'width: 50%; white-space: nowrap';

	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end	


--[[-------------------------< I B O X _ M L N _ F O O T E R >-------------------------------------------------

bypasses {{Infobox Chinese/Footer}}

Module entry point

{{#invoke:Infobox multi-lingual name|ibox_mln_footer}}

]]

local function ibox_mln_footer (frame, args)
	if not args then
		args = frame.args;
	end
	local infobox_args = {};													-- table to hold arguments for frame:expandTemplate()
	infobox_args['decat'] = 'yes';
	infobox_args['child'] = is_set (args.child) and args.child or 'yes';
	infobox_args['bodystyle'] = '';												-- present in wikisource template but not assigned a value there
	infobox_args['below'] = args.footnote;
	
	return frame:expandTemplate ({title='Infobox', args = infobox_args});
end


--[[-------------------------< I B O X _ Z H Z H _ E N U M _ P A R A M S _ G E T >----------------------------

]]

local function ibox_zhzh_enum_params_get (args, i)
	local ibox_args = {};
	local count = 0;															-- counts how many args got added to ibox_args {}

	for _, v in ipairs (data.ibox_zhzh_enum_params) do							-- add enumerated parameters
		if args[v .. i] then													-- only when there is an assigned value
			ibox_args[v] = args[v .. i];										-- add
			count = count + 1;													-- and tally
		end
	end

	return 0 ~= count and ibox_args or nil;										-- if table is empty return nil as a flag
end


--[[--------------------------< A R >--------------------------------------------------------------------------

----< A R A B I C >----

]]

local function ar (frame, args)
	if is_set ({args.arabic, args.arabic_rom, args.arabic_ipa, args.arabic_lit}) then
		local ibox_args = {
--			['arabic_header'] = args.tib and 'Arabic name',						-- redundant; TODO: support |arabic_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['arabic'] = args.arabic,
			['arabic_rom'] = args.arabic_rom,
			['arabic_ipa'] = args.arabic_ipa,
			['arabic_lit'] = args.arabic_lit or args['literal meaning'],		-- 'literal meaning' is from {{Infobox Arabic term}}; itis param name a good idea?  TODO: unify parameter names
			['chat'] = args.chat or args.Chat,									-- TODO: unify parameter names
			['ala-lc'] = args['ala-lc'] or args['ALA-LC'],						-- TODO: unify parameter names
			['iso'] = args.iso or args.ISO,										-- TODO: unify parameter names
			['din'] = args.din or args.DIN										-- TODO: unify parameter names
			}
			
		return ibox_mln_ar (frame, ibox_args);
	end
end


--[[--------------------------< A S >--------------------------------------------------------------------------

----< A S S A M E S E >----

]]

local function as (frame, args)
	if args.as or args.asm then
		local ibox_args = {
			['lang_hdr'] = args['as-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'as',
			['lang_content'] = args.as or args.asm,
			['lang_ipa'] = args['as-ipa'],
			['lang_rom'] = args['as-rom'],
			['lang_std'] = args['as-std'],
			['lang_lit'] = args['as-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< B N >--------------------------------------------------------------------------

----< B E N G A L I >----

]]

local function bn (frame, args)
	if args.bn or args.ben then
		local ibox_args = {
			['lang_hdr'] = args['bn-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'bn',
			['lang_content'] = args.bn or args.ben,
			['lang_ipa'] = args['bn-ipa'],
			['lang_rom'] = args['bn-rom'],
			['lang_std'] = args['bn-std'],
			['lang_lit'] = args['bn-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< B O >--------------------------------------------------------------------------

----< T I B E T A N >----

]]

local function bo (frame, args)
	if any_set ({args.tib, args.wylie, args.thdl, args.zwpy, args.lhasa}) then
		local ibox_args = {
--			['tibetan_header'] = args.tib and 'Tibetan name',					-- redundant; TODO: support |burmese_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['tib'] = args.tib,
			['wylie'] = args.wylie,
			['thdl'] = args.thdl,
			['zwpy'] = args.zwpy,
			['lhasa'] = args.lhasa,
			}
			
		return ibox_mln_bo (frame, ibox_args);
	end
end


--[[--------------------------< D N G >------------------------------------------------------------------------

----< D U N G A N E S E >----

]]

local function dng (frame, args)
	if any_set ({args.dungan, args['dungan-xej'], args['dungan-han']}) then
		local ibox_args = {
--			['dunganese_header'] = 'Dunganese name',							-- redundant; TODO: support |dungan_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['dungan'] = args.dungan,
			['dungan-xej'] = args['dungan-xej'],
			['dungan-han'] = args['dungan-han'],
			['dungan-latin'] = args['dungan-latin'],
			}
			
		return ibox_mln_dng (frame, ibox_args);
	end
end


--[[--------------------------< H I >--------------------------------------------------------------------------

----< H I N D I >----

]]

local function hi (frame, args)
	if args.hi or args.hin then
		local ibox_args = {
			['lang_hdr'] = args['hi-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'hi',
			['lang_content'] = args.hi or args.hin,
			['lang_ipa'] = args['hi-ipa'],
			['lang_rom'] = args['hi-rom'],
			['lang_std'] = args['hi-std'],
			['lang_lit'] = args['hi-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< I D >--------------------------------------------------------------------------

----< I N D O N E S I A N >----

]]

local function id (frame, args)
	if args.id or args.ind then
		local ibox_args = {
			['lang_hdr'] = args['id-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'id',
			['lang_content'] = args.id or args.ind,
			['lang_ipa'] = args['id-ipa'],
			['lang_rom'] = args['id-rom'],
			['lang_std'] = args['id-std'],
			['lang_lit'] = args['id-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< J A >--------------------------------------------------------------------------

----< J A P A N E S E >----

]]

local function ja (frame, args)
	if any_set ({args.kanji, args.kana, args.hiragana, args.katakana, args.kyujitai, args.shinjitai}) then
		local ibox_args = {
--			['japanese_header'] = 'Japanese name',								-- redundant; TODO: support |japanese_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['kanji'] = args.kanji,
			['kyujitai'] = args.kyujitai,
			['shinjitai'] = args.shinjitai,
			['kana'] = args.kana,
			['hiragana'] = args.hiragana,
			['katakana'] = args.katakana,
			['romaji'] = args.romaji,
			['revhep'] = args.revhep,
			['tradhep'] = args.tradhep,
			['kunrei'] = args.kunrei,
			['nihon'] = args.nihon,
			}
			
		return ibox_mln_ja (frame, ibox_args);
	end
end


--[[--------------------------< K M >--------------------------------------------------------------------------

----< K H M E R >----

]]

local function km (frame, args)
	if args.km or args.khm then
		local ibox_args = {
			['lang_hdr'] = args['km-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'km',
			['lang_content'] = args.km or args.khm,
			['lang_ipa'] = args['km-ipa'],
			['lang_rom'] = args['km-rom'],
			['lang_std'] = args['km-std'],
			['lang_lit'] = args['km-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< K O 1 >------------------------------------------------------------------------

TODO: handle ko same way as enumerated zh?
----< K O R E A N  (1) >----

]]

local function ko1 (frame, args)
	if any_set ({args.hanja, args.hangul}) then
		local ibox_args = {
--			['korean_header'] = 'Korean name',									-- redundant; TODO: support |korean_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['hangul'] = args.hangul,
			['hanja'] = args.hanja,
			['rr'] = args.rr,
			['mr'] = args.mr,
			['northkorea'] = args.northkorea,
			['lk'] = args.lk,
			}
			
			
		return ibox_mln_ko (frame, ibox_args);
	end
end


--[[--------------------------< K O 2 >------------------------------------------------------------------------

TODO: handle ko same way as enumerated zh?
----< K O R E A N  (2) >----

]]

local function ko2 (frame, args)
	if any_set ({args.cnhanja, args.cnhangul}) then
		local ibox_args = {
			['korean_header'] = '[[Korean language in China|Chinese Korean]] name',
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['hangul'] = args.cnhangul,
			['hanja'] = args.cnhanja,
			['rr'] = args.cnrr,
			['mr'] = args.cnmr,
			['northkorea'] = 'yes',
			['lk'] = args.cnlk,
			}
			
		return ibox_mln_ko (frame, ibox_args);
	end
end


--[[--------------------------< K O 3 >------------------------------------------------------------------------

TODO: handle ko same way as enumerated zh?
----< K O R E A N  (3) >----

]]

local function ko3 (frame, args)
	if any_set ({args.nkhanja, args.nkhangul}) then
		local ibox_args = {
			['korean_header'] = 'North Korean name',
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['hangul'] = args.nkhangul,
			['hanja'] = args.nkhanja,
			['rr'] = args.nkrr,
			['mr'] = args.nkmr,
			['northkorea'] = 'yes',
			['lk'] = args.nklk,
			}
			
		return ibox_mln_ko (frame, ibox_args);
	end
end


--[[--------------------------< K O 4 >------------------------------------------------------------------------

TODO: handle ko same way as enumerated zh?
----< K O R E A N  (4) >----

]]

local function ko4 (frame, args)
	if any_set ({args.skhanja, args.skhangul}) then
		local ibox_args = {
			['korean_header'] = 'South Korean name',
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['hangul'] = args.skhangul,
			['hanja'] = args.skhanja,
			['rr'] = args.skrr,
			['mr'] = args.skmr,
			['northkorea'] = nil,
			['lk'] = args.sklk,
			}
			
		return ibox_mln_ko (frame, ibox_args);
	end
end


--[[--------------------------< L O >--------------------------------------------------------------------------

----< L A O >----

]]

local function lo (frame, args)
	if args.lo or args.lao then
		local ibox_args = {
			['lang_hdr'] = args['lo-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'lo',
			['lang_content'] = args.lo or args.lao,
			['lang_ipa'] = args['lo-ipa'],
			['lang_rom'] = args['lo-rom'],
			['lang_std'] = args['lo-std'],
			['lang_lit'] = args['lo-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< M N >--------------------------------------------------------------------------

----< M O N G O L I A N >----

]]

local function mn (frame, args)
	if any_set ({args.mong, args.mon}) then
		local ibox_args = {
--			['mongolian_header'] = 'Mongolian name',							-- redundant; TODO: support |mongolian_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['mon'] = args.mon,
			['mong'] = args.mong,
			['monr'] = args.monr,
			}
			
		return ibox_mln_mn (frame, ibox_args);
	end
end


--[[--------------------------< M N C >------------------------------------------------------------------------

----< M A N C H U >----

]]

local function mnc (frame, args)
	if any_set ({args.mnc_rom, args.mnc}) then
		local ibox_args = {
--			['manchu_header'] = 'Manchu name',									-- redundant; TODO: support |manchu_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['mnc'] = args.mnc,
			['mnc_rom'] = args.mnc_rom,
			['mnc_a'] = args.mnc_a,
			['mnc_v'] = args.mnc_v,
			}
			
		return ibox_mln_mnc (frame, ibox_args);
	end
end


--[[--------------------------< M S >--------------------------------------------------------------------------

----< M A L A Y >----

]]

local function ms (frame, args)
	if args.ms or args.msa then
		local ibox_args = {
			['lang_hdr'] = args['ms-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'ms',
			['lang_content'] = args.ms or args.msa,
			['lang_ipa'] = args['ms-ipa'],
			['lang_rom'] = args['ms-rom'],
			['lang_std'] = args['ms-std'],
			['lang_lit'] = args['ms-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< M Y >--------------------------------------------------------------------------

----< B U R M E S E >----

]]

local function my (frame, args)
	if args.my then
		local ibox_args = {
--			['burmese_header'] = 'Burmese name',								-- redundant; TODO: support |burmese_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['my'] = args.my,
			['bi'] = args.bi,
			}
			
		return ibox_mln_my (frame, ibox_args);
	end
end


--[[--------------------------< N E >--------------------------------------------------------------------------

----< N E P A L I >----

]]

local function ne (frame, args)
	if args.ne or args.nep then
		local ibox_args = {
			['lang_hdr'] = args['ne-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'ne',
			['lang_content'] = args.ne or args.nep,
			['lang_ipa'] = args['ne-ipa'],
			['lang_rom'] = args['ne-rom'],
			['lang_std'] = args['ne-std'],
			['lang_lit'] = args['ne-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< P I >--------------------------------------------------------------------------

----< P A L I >----

]]

local function pi (frame, args)
	if args.pi or args.pli then
		local ibox_args = {
			['lang_hdr'] = args['pi-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'pi',
			['lang_content'] = args.pi or args.pli,
			['lang_ipa'] = args['pi-ipa'],
			['lang_rom'] = args['pi-rom'],
			['lang_std'] = args['pi-std'],
			['lang_lit'] = args['pi-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< P T >--------------------------------------------------------------------------

----< P O R T U G U E S E >----

]]

local function pt (frame, args)
	if args.pt or args.por then
		local ibox_args = {
			['lang_hdr'] = args['pt-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'pt',
			['lang_lbl'] = args['pt-label'],
			['lang_content'] = args.pt or args.por,
			['lang_ipa'] = args['pt-ipa'],
			['lang_rom'] = args['pt-rom'],
			['lang_std'] = args['pt-std'],
			['lang_lit'] = args['pt-lit'],
			['lang_lit'] = args['pt-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< P R A >------------------------------------------------------------------------

----< P R A K R I T >----

]]

local function pra (frame, args)
	if args.pra then
		local ibox_args = {
			['lang_hdr'] = args['pra-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'pra',
			['lang_content'] = args.pra,
			['lang_ipa'] = args['pra-ipa'],
			['lang_rom'] = args['pra-rom'],
			['lang_std'] = args['pra-std'],
			['lang_lit'] = args['pra-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< R U >--------------------------------------------------------------------------

----< R U S S I A N >----

]]

local function ru (frame, args)
	if any_set ({args.rus, args.russian}) then									-- TODO: unify parameter names
		local ibox_args = {
--			['russian_header'] = 'Russian name',								-- redundant; TODO: support |russian_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['rus'] = args.rus or args.russian,
			['rusr'] = args.rusr,
			['rusipa'] = args.rusipa or args['native pronunciation'],			-- TODO: unify parameter names
			['ruslit'] = args.ruslit or args['literal meaning'],				-- TODO: unify parameter names
			['scientific'] = args.scientific,
			['iso'] = args.iso,
			['gost'] = args.gost,
			['bgn/pcgn'] = args['bgn/pcgn'],
			}
			
		return ibox_mln_ru (frame, ibox_args);
	end
end


--[[--------------------------< S A >--------------------------------------------------------------------------

----< S A N S K R I T >----

]]

local function sa (frame, args)
	if args.sa or args.san then
		local ibox_args = {
			['lang_hdr'] = args['sa-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'sa',
			['lang_content'] = args.sa or args.san,
			['lang_ipa'] = args['sa-ipa'],
			['lang_rom'] = args['sa-rom'],
			['lang_std'] = args['sa-std'],
			['lang_lit'] = args['sa-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< T A >--------------------------------------------------------------------------

----< T A M I L >----

]]

local function ta (frame, args)
	if args.ta or args.tam then
		local ibox_args = {
			['lang_hdr'] = args['ta-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'ta',
			['lang_content'] = args.ta or args.tam,
			['lang_ipa'] = args['ta-ipa'],
			['lang_rom'] = args['ta-rom'],
			['lang_std'] = args['ta-std'],
			['lang_lit'] = args['ta-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< T E T >------------------------------------------------------------------------

----< T E T U M >----

]]

local function tet (frame, args)
	if args.tet then
		local ibox_args = {
			['lang_hdr'] = args['tet-hdr'],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'tet',
			['lang_content'] = args.tet,
			['lang_ipa'] = args['tet-ipa'],
			['lang_rom'] = args['tet-rom'],
			['lang_std'] = args['tet-std'],
			['lang_lit'] = args['tet-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< T H >--------------------------------------------------------------------------

----< T H A I >----

]]

local function th (frame, args)
	if args.th or args.tha then
		local ibox_args = {
--			['thai_header'] = 'Thai name',										-- redundant; TODO: support |thai_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['header'] = args['th-hdr'],
			['th'] = args.th or args.tha,
			['rtgs'] = args.rtgs,
			['ipa'] = args['th-ipa'],
			['rom'] = args['th-rom'],
			['std'] = args['th-std'],
			['lit'] = args['th-lit'],
			}
		return ibox_mln_th (frame, ibox_args);
	end
end


--[[--------------------------< T L >--------------------------------------------------------------------------

----< F I L I P I N O >----

]]

local function tl (frame, args)
--	if args.tl or args.tgl then
	if args.tgl then
		local ibox_args = {
--			['blank_header'] = 'Filipino name',
			['lang_hdr'] = args['tl-hdr'] or 'Filipino name',
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = 'tl',
--			['lang_content'] = args.tl or args.tgl,								-- tl is used for Taiwanese Romanization System of Hokkien
			['lang_content'] = args.tgl,
			['lang_ipa'] = args['tl-ipa'],
			['lang_rom'] = args['tl-rom'],
			['lang_std'] = args['tl-std'],
			['lang_lit'] = args['tl-lit'],
			}
			
		return ibox_mln_blank (frame, ibox_args);
	end
end


--[[--------------------------< U G >--------------------------------------------------------------------------

----< U Y G H U R >----

]]

local function ug (frame, args)
	if args.uig then
		local ibox_args = {
--			['uyghur_header'] = 'Uyghur name',									-- redundant; TODO: support |uyghur_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['uig'] = args.uig,
			['lu'] = args.lu,
			['uly'] = args.uly,
			['uyy'] = args.uyy,
			['sgs'] = args.sgs,
			['usy'] = args.usy,
			['uipa'] = args.uipa,
			}
			
		return ibox_mln_ug (frame, ibox_args);
	end
end


--[[--------------------------< V I >--------------------------------------------------------------------------

----< V I E T N A M E S E >----

]]

local function vi (frame, args)
	if any_set ({args.qn, args.vie, args.chuhan}) then
		local ibox_args = {
--			['vietnamese_header'] = 'Vietnamese name',							-- redundant; TODO: support |vietnamese_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['vie'] = args.vie,
			['qn'] = args.qn,
			['hn'] = args.hn,
			['chuhan'] = args.chuhan,
			['chunom'] = args.chunom,
			['lqn'] = args.lqn,
			}
			
		return ibox_mln_vi (frame, ibox_args);
	end
end


--[[--------------------------< Z A >--------------------------------------------------------------------------

----< Z H U A N G >----
 
]]

local function za (frame, args)
	if args.zha then
		local ibox_args = {
--			['zhuang_header'] = 'Zhuang name',									-- redundant; TODO: support |zhuang_header=
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['hide'] = args.hide,
			['zha'] = args.zha,
			['zha57'] = args.zha57,
			['sd'] = args.sd,
			}
			
		return ibox_mln_za (frame, ibox_args);
	end
end


--[[--------------------------< Z H >--------------------------------------------------------------------------

----------< C H I N E S E >----------

]]

local function zh (frame, args)
	local children = {};
	
	if any_set ({args.c, args.t, args.p, args.s}) then							-- first infobox zh/zh
		local ibox_args = ibox_zhzh_enum_params_get (args, '');					-- get the enumerated parameters (here enumerator is empty string)

		if ibox_args then
			ibox_args['hide'] = args.hide; 
			ibox_args['showflag'] = args.showflag;
			ibox_args['order'] = args.order;

			ibox_args['p'] = args.p or args.hp;									-- add special case parameters
			ibox_args['xej'] = args.xej and lang_mod._lang ({'zh-Arab', args.xej});

			if 'yes' == args.child then
				ibox_args['chinese_header'] = args.name1;						-- show the header name from parameter or default name from ibox_mln_zh()
			elseif any_set ({													-- when any of these are set there will be other child infoboxen so ...
					args.hangul, args.hanja, args.kana, args.kanji, args.hiragana,
					args.katakana, args.kyujitai, args.shinjitai, args.tam, args.hin,
					args.san, args.pli, args.tgl, args.msa, args.mnc, args.mon, args.mong,
					args.por, args.rus, args.tha, args.tib, args.qn, args.uig, args.vie,
					args.chuhan, args.chunom, args.hn, args.zha, args['dungan-xej'],
					args.dungan, args.lao, args.khm, args.tet, args.lang1, args.lang2,
					args.lang3, args.lang4, args.lang5, args.lang6, args.lang7, args.lang8,
					args.lang9, args.lang10, args.lang11, 
					}) then
						ibox_args['chinese_header'] = args.name1;				-- ... show the header name from parameter or default name from ibox_mln_zh()
			else
				ibox_args['chinese_header'] = args.name1 or 'none';				-- show the header name from parameter or no header (args.name1 missing or 'empty' - nil)
			end

			ibox_args['headercolor'] = args['child-hdr-color'] or args.headercolor;

			table.insert (children, ibox_mln_zh (frame, ibox_args));
		end
	end
	
	for i=2, 6 do
		if any_set ({args['c'..i], args['t'..i], args['p'..i], args['s'..i]}) then
			local ibox_args = ibox_zhzh_enum_params_get (args, i);				-- get the enumerated parameters

			if ibox_args then
				ibox_args['hide'] = args.hide;
				ibox_args['showflag'] = args.showflag;
				ibox_args['order'] = args.order; 

				ibox_args['p'] = args['p'..i] or args['hp'..i];					-- add special case parameters
				ibox_args['xej'] = args['xej'..i] and lang_mod._lang ({'zh-Arab', args['xej'..i]});

				if args[data.zh_hdr_names[i][1]] then
					ibox_args['chinese_header'] = args[data.zh_hdr_names[i][1]];	-- use value from parameter
				else
					ibox_args['chinese_header'] = data.zh_hdr_names[i][2];		-- use the default
				end

				ibox_args['headercolor'] = args['child-hdr-color'] or args.headercolor;
				
				table.insert (children, ibox_mln_zh (frame, ibox_args));
			end
		end
	end
	
	return table.concat (children) or '';										-- big string of zh infoboxen or an empty string if nothing was done here
end


--[[==========================<< I B O X _ M L N >>============================================================

implements {{Infobox Chinese}}

TODO: do a valueFunc () on getArgs() so that when they are blank we acknowledge the blank (|name1= present with
empty string or whitespace as assigned value)

]]

local function ibox_mln (frame)
	local args = getArgs(frame);												-- also gets parent frame params (there are no frame params for this function) TODO:, {removeBlanks = false}?
	local infobox_args = {};													-- table to hold arguments for ibox_mln frame:expandTemplate()
	local children = {};														-- table of returned infoboxen text

----------< H E A D E R   I N F O B O X >----------

	infobox_args['child'] = args.child;
	infobox_args['rowstyle1'] = 'display:none;';
	if 'yes' ~= args.child then
		local hdr_args = {
			['title'] = args.title or mw.title.getCurrentTitle().text:gsub ('%s+%b()$', '');	-- mimic {{PAGENAMEBASE}} (template not magic word)
			['headercolor'] = args.headercolor,
			['float'] = args.float,
			['collapse'] = args.collapse,
			['pic'] = args.pic or args.image,									-- TODO: unify parameter names
			['picsize'] = args.picsize or args.imgwidth,						-- TODO: unify parameter names
			['picupright'] = args.picupright,
			['picalt'] = args.picalt,
			['pictooltip'] = args.pictooltip,
			['piccap'] = args.piccap or args.caption,							-- TODO: unify parameter names
			['pic2'] = args.pic2,
			['picsize2'] = args.picsize2,
			['picupright2'] = args.picupright2,
			['picalt2'] = args.picalt2,
			['pictooltip2'] = args.pictooltip2,
			['piccap2'] = args.piccap2,
			}
		table.insert (children, ibox_mln_header (frame, hdr_args));
	end

----------< L A N G U A G E   I N F O B O X E N >----------

	local lang_iboxen = {														-- table of codes used in |ibox-order= and their matching function pointers
		['ar'] = ar, ['as'] = as, ['bn'] = bn, ['bo'] = bo, ['dng'] = dng,
		['hi'] = hi, ['id'] = id, ['ja'] = ja, ['km'] = km, ['ko1'] = ko1,
		['ko2'] = ko2, ['ko3'] = ko3, ['ko4'] = ko4, ['lo'] = lo, ['mn'] = mn,
		['mnc'] = mnc, ['ms'] = ms, ['my'] = my, ['ne'] = ne, ['pi'] = pi,
		['pra'] = pra, ['pt'] = pt, ['ru'] = ru, ['sa'] = sa, ['ta'] = ta,
		['tet'] = tet, ['th'] = th, ['tl'] = tl, ['ug'] = ug, ['vi'] = vi,
		['za'] = za, ['zh'] = zh
		}

	local lang_ibox_order = {													-- default list of lang ibox calling functions as used by legacy {{Infobox Chinese}}
		zh, my, bo, dng, vi, th, za, ko1, ko2, ko3, ko4, mn, ja, ms, id, tl,
		 ug, mnc, bn, as, ne, pra, ta, hi, sa, pi, pt, ru, lo, km, tet
		};
	
	if args['ibox-order'] then														-- parameter value is comma-separated list of lang iboxen to render and their order
		local t = mw.text.split (args['ibox-order'], '%s*,%s*')					-- make a table from the list
		lang_ibox_order = {};													-- reset; don't use default list
		for _, v in ipairs (t) do												-- spin through the lang_ibox_order list in order and 
			if lang_iboxen[v] then												-- if there is a matching ibox function
				table.insert (lang_ibox_order, lang_iboxen[v]);					-- add it to the list of functions to call; TODO: error message when specified language does not exist?
			end
		end
	end	

	for _, ibox_func in ipairs (lang_ibox_order) do								-- call each function in the list in the list order
		table.insert (children, ibox_func (frame, args) or '');					-- add ibox string (or empty string when there is no ibox string)
	end

----------< B L A N K #   I N F O B O X E N >----------

	local i = 1;																-- blank ibox enumerator
	while args['lang' .. i] and (args['lang-content' .. i] or args['lang' .. i .. '_content']) do		-- for as many ibox blank as there are ...
		local ibox_args = {
			['lang_hdr'] = args['lang-hdr' .. i],
			['headercolor'] = args['child-hdr-color'] or args.headercolor,
			['lang'] = args['lang' .. i],
			['lang_label'] = args['lang-lbl' .. i],
			['lang_content'] = args['lang-content' .. i] or args['lang' .. i .. '_content'],
			['lang_ipa'] = args['lang-ipa' .. i],
			['lang_rom'] = args['lang-rom' .. i],
			['lang_std'] = args['lang-std' .. i],
			['lang_lit'] = args['lang-lit' .. i],
			}
			
		table.insert (children, ibox_mln_blank (frame, ibox_args));
		i = i + 1;																-- bump the enumerator
	end

----------< F O O T E R   I N F O B O X >----------

	if 'yes' ~= args.child then
		table.insert (children, ibox_mln_footer (frame, {['footnote'] = args.footnote}));
	end

----------< R E N D E R >----------

	return table.concat (children);												-- concatenate all of the children together into a ginormous string
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------

these not used outside of old {{Infobox Chinese}}:
	ibox_mln_dng = ibox_mln_dng,												-- {{infobox Chinese/Dunganese}}
	ibox_mln_mn = ibox_mln_mn,													-- {{infobox Chinese/Mongolian}}
	ibox_mln_mnc = ibox_mln_mnc,												-- {{infobox Chinese/Manchu}}
	ibox_mln_my = ibox_mln_my,													-- {{infobox Chinese/Burmese}}
	ibox_mln_th = ibox_mln_th,													-- {{infobox Chinese/Thai}}
	ibox_mln_ug = ibox_mln_ug,													-- {{infobox Chinese/Uyghur}}
	ibox_mln_za = ibox_mln_za,													-- {{infobox Chinese/Zhuang}}

these templates require parameter-name unification before they can directly use this module (and avoid the subtemplates):
	{{Infobox Tibetan-Chinese}} uses:
		{{Infobox Chinese/Chinese}}
		{{Infobox Chinese/Tibetan}}
	{{Infobox East Asian name}} uses:
		{{Infobox Chinese/Chinese}}
		{{Infobox Chinese/Japanese}}
		{{Infobox Chinese/Korean}}
		{{Infobox Chinese/Russian}}
		{{Infobox Chinese/Blank}}

]]

return {
	ibox_mln = ibox_mln,														-- {{infobox Chinese}}
	ibox_mln_ar = ibox_mln_ar,													-- {{infobox Chinese/Arabic}} (used in Template:Infobox Arabic term)
	ibox_mln_blank = ibox_mln_blank,											-- {{infobox Chinese/Blank}}
	ibox_mln_bo = ibox_mln_bo,													-- {{infobox Chinese/Tibetan}}
	ibox_mln_footer = ibox_mln_footer,											-- {{infobox Chinese/Footer}}
	ibox_mln_header = ibox_mln_header,											-- {{infobox Chinese/Header}}
	ibox_mln_hokkien = ibox_mln_hokkien,										-- {{infobox Chinese/Hokkien}} (used in Template:Infobox Hokkien name)
	ibox_mln_ja = ibox_mln_ja,													-- {{infobox Chinese/Japanese}}
	ibox_mln_ko = ibox_mln_ko,													-- {{infobox Chinese/Korean}}
	ibox_mln_ru = ibox_mln_ru,													-- {{infobox Chinese/Russian}} (used in Template:Infobox Russian term)
	ibox_mln_vi = ibox_mln_vi,													-- {{infobox Chinese/Vietnamese}} (used in Template:Infobox Vietnamese)
	ibox_mln_zh = ibox_mln_zh,													-- {{infobox Chinese/Chinese}}
	}