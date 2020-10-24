local retval = {
	main_box_raw_auto_width = 'border-spacing:2px;',
	header_raw = 'background-color:#C3D6EF;text-align:center;vertical-align:middle;font-size:110%;',
	sub_header_raw = 'background-color:#DCDCDC;text-align:center;vertical-align:middle;',
	header_color = 'background-color:#C3D6EF;',
	nav_box = 'margin:0;float:right;clear:right;width:25.5em;margin-bottom:0.5em;margin-left:1em;',
	nav_box_child = 'margin:0;float:right;clear:right;width:25em;margin-bottom:0.5em;',
	nav_box_wide =  '',
	nav_box_header = 'background-color:#C3D6EF;',
	nav_box_wide_header = 'background-color:#C3D6EF;',
	nav_box_label = 'background-color:#DCDCDC;',
	image_box_raw = 'text-align:center;border-bottom:1px solid #aaa;line-height:1.5em;',
	image_box_plain_raw = 'text-align:center;line-height:1.5em;',
	internal_border = '1px dotted #aaa;',
	section_border = '1px solid #aaa;'
}

retval.main_box_raw = 'width:25.5em;' .. retval.main_box_raw_auto_width
retval.header_bar = 'style="' .. retval.header_raw .. '"'
retval.sub_header_bar = 'style="' .. retval.sub_header_raw .. '"'
retval.image_box = 'style="' .. retval.image_box_raw .. '"'
retval.image_box_plain = 'style="' .. retval.image_box_plain_raw .. '"'

return retval