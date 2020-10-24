return {
	secondaryModules = {
		[[Module:Lebanese_insurgency_detailed_map]],
		[[Module:Iraqi insurgency detailed map]],
		[[Module:Syrian Civil War map images module]],
		[[Module:Syrian_and_Iraqi_insurgency_detailed_map]],
		[[Module:Syrian Civil War overview map]],
		--[[Module:Syrian Civil War detailed map]]--, --Syrian Civil War detailed map can't be included in this map because total module size will reach above the max size limit crashing it
	},
	marks = {
		-- The only marks that belong in this module are those on the Syrian-Lebanese border.
		-- Marks from the Iraqi-Syrian border belong to the Syrian_and_Iraqi_insurgency_detailed_map
		-- All others belong to their country's detailed map
	},
	containerArgs = {
		'Syria-Iraq-Lebanon',
		maplink = '',
		float = 'left',
		width = 4500,
		caption = [=['''Hold cursor over location to display name; click to go to location row in the "table of cities and towns" (if available).'''<br/>Control : &nbsp;[[File:Location dot red.svg|11px]] Ba'athist Syria, Iraqi Republic, Lebanese Republic (SIL); [[File:Dot green 0d0.svg|11px]] [[Syrian Interim Government]] ([[Syrian National Army|SNA]]) and [[Turkish Armed Forces]] ; [[File:Dot_yellow_ff4.svg|11px]] [[Rojava]] ([[Syrian Democratic Forces|SDF]]) and [[Iraqi Kurdistan]] ; [[File:Map-dot-grey-68a.svg|11px]] [[Syrian Salvation Government]] ([[Hayat Tahrir al-Sham|HTS]]) ; [[File:Location dot blue.svg|11px]] [[Hezbollah]] ; [[File:Location dot black.svg|11px]] [[Islamic State of Iraq and the Levant]] (ISIL) ; [[File:Location dot teal.svg|11px]] [[Revolutionary Commando Army]] (RCA) and [[United States Armed Forces]] ; [[File:LACMTA Circle Purple Line.svg|11px]] [[Syrian Government|Government]] & [[Syrian opposition|Opposition]] stable mixed control (truce)<br />
Stable mixed control (same colors) ''':''' [[File:Map-ctl2-red+lime.svg|11px]] [[File:Map-ctl2-red+yellow.svg|11px]] [[File:Map-ctl2-red+grey.svg|11px]] [[File:Map-ctl2-red+black.svg|11px]] [[File:Map-ctl2-red+blue.svg|11px]] [[File:Map-ctl2-lime+yellow.svg|11px]] [[File:Map-ctl2-lime+grey.svg|11px]] [[File:Map-ctl2-lime+black.svg|11px]] [[File:Map-ctl2-lime+blue.svg|11px]]&nbsp; [[File:Map-ctl2-yellow+grey.svg|11px]] [[File:Map-ctl2-yellow+black.svg|11px]] &nbsp; [[File:Map-ctl2-black+blue.svg|11px]] [[File:Map-ctl2-grey+black.svg|11px]] [[File:Map-ctl2-grey+blue.svg|11px]] &nbsp; [[File:Map-ctl3-red+lime+yellow.svg|11px]] [[File:Map-ctl3-red+lime+grey.svg|11px]] [[File:Map-ctl3-red+yellow+black.svg|11px]]<br/>
Rural presence :&nbsp; [[File:3x3dot-red.svg|11px]]&nbsp; [[File:3x3dot-lime.svg|11px]]&nbsp; [[File:3x3dot-yellow.svg|11px]]&nbsp; [[File:3x3dot-grey.svg|11px]]&nbsp; [[File:3x3dot-black.svg|11px]]&nbsp; [[File:3x3dot-blue.svg|11px]] &nbsp; &nbsp; [[File:4x4dot-red.svg|11px]]&nbsp; [[File:4x4dot-lime.svg|11px]]&nbsp; [[File:4x4dot-yellow.svg|11px]]&nbsp; [[File:4x4dot-grey.svg|11px]]&nbsp; [[File:4x4dot-black.svg|11px]]&nbsp; [[File:4x4dot-blue.svg|11px]]<br/>
Contested : [[File:80x80-red-lime-anim.gif|11px]] SIL/Syrian opposition ; [[File:80x80-red-yellow-anim.gif|11px]] SIL/Kurds ; [[File:80x80-red-grey-anim.gif|11px]] Ba'athist Syria/HTS ; [[File:80x80-red-black-anim.gif|11px]] SIL/ISIL ; [[File:80x80-lime-yellow-anim.gif|11px]] Syrian opposition/Kurds ; [[File:80x80-lime-grey-anim.gif|11px]] Syrian opposition/HTS ; [[File:80x80-lime-black-anim.gif|11px]] Syrian opposition/ISIL ; [[File:80x80-lime-blue-anim.gif|11px]] Syrian opposition/Hezbollah ; [[File:80x80-yellow-grey-anim.gif|11px]] Kurds/HTS ; [[File:80x80-yellow-black-anim.gif|11px]] Kurds/ISIL ; [[File:80x80-blue-black-anim.gif|11px]] Hezbollah/ISIL ; [[File:80x80-grey-blue-anim.gif|11px]] Hezbollah/HTS ; [[File:80x80-grey-black-anim.gif|11px]] HTS/ISIL ; [[File:80x80-red-lime-yellow-anim.gif|11px]] 3-way ;<br />
Besieged one side : [[File:map-arcNN-red.svg|11px]] [[File:map-arcNN-lime.svg|11px]] [[File:map-arcNN-yellow.svg|11px]] [[File:map-arcNN-grey.svg|11px]] [[File:map-arcNN-black.svg|11px]] [[File:map-arcNN-blue.svg|11px]]  
&nbsp; [[File:map-arcNE-red.svg|11px]] [[File:map-arcNE-lime.svg|11px]] [[File:map-arcNE-yellow.svg|11px]] [[File:map-arcNE-grey.svg|11px]] [[File:map-arcNE-black.svg|11px]] [[File:map-arcNE-blue.svg|11px]]
&nbsp; [[File:map-arcEE-red.svg|11px]] [[File:map-arcEE-lime.svg|11px]] [[File:map-arcEE-yellow.svg|11px]] [[File:map-arcEE-grey.svg|11px]] [[File:map-arcEE-black.svg|11px]] [[File:map-arcEE-blue.svg|11px]]
&nbsp; [[File:map-arcSE-red.svg|11px]] [[File:map-arcSE-lime.svg|11px]] [[File:map-arcSE-yellow.svg|11px]] [[File:map-arcSE-grey.svg|11px]] [[File:map-arcSE-black.svg|11px]] [[File:map-arcSE-blue.svg|11px]]
&nbsp; [[File:map-arcSS-red.svg|11px]] [[File:map-arcSS-lime.svg|11px]] [[File:map-arcSS-yellow.svg|11px]] [[File:map-arcSS-grey.svg|11px]] [[File:map-arcSS-black.svg|11px]] [[File:map-arcSS-blue.svg|11px]]
&nbsp; [[File:map-arcSW-red.svg|11px]] [[File:map-arcSW-lime.svg|11px]] [[File:map-arcSW-yellow.svg|11px]] [[File:map-arcSW-grey.svg|11px]] [[File:map-arcSW-black.svg|11px]] [[File:map-arcSW-blue.svg|11px]]
&nbsp; [[File:map-arcWW-red.svg|11px]] [[File:map-arcWW-lime.svg|11px]] [[File:map-arcWW-yellow.svg|11px]] [[File:map-arcWW-grey.svg|11px]] [[File:map-arcWW-black.svg|11px]] [[File:map-arcWW-blue.svg|11px]]
&nbsp; [[File:map-arcNW-red.svg|11px]] [[File:map-arcNW-lime.svg|11px]] [[File:map-arcNW-yellow.svg|11px]] [[File:map-arcNW-grey.svg|11px]] [[File:map-arcNW-black.svg|11px]] [[File:map-arcNW-blue.svg|11px]]<br />
Besieged : [[File:map-circle-red.svg|12px]] [[File:map-circle-lime.svg|12px]] [[File:map-circle-yellow.svg|12px]] [[File:map-circle-grey.svg|12px]] [[File:map-circle-black.svg|12px]] [[File:map-circle-blue.svg|12px]] &nbsp; 
Military base : [[File:Abm-red-icon.png|13px]] [[File:Abm-lime-icon.png|13px]] [[File:Abm-yellow-icon.png|13px]] [[File:Abm-grey-icon.png|13px]] [[File:Abm-black-icon.png|13px]] [[File:Abm-blue-icon.png|13px]] &nbsp; 
Airport/Air base (plane) : [[File:Fighter-jet-red-icon.svg|13px]] [[File:Fighter-jet-lime-icon.svg|13px]] [[File:Fighter-jet-yellow-icon.svg|13px]] [[File:Fighter-jet-grey-icon.svg|13px]] [[File:Fighter-jet-black-icon.svg|13px]] [[File:Fighter-jet-blue-icon.svg|13px]] &nbsp; 
Heliport/Helicopter base : [[File:Helicopter-red-icon.svg|13px]] [[File:Helicopter-lime-icon.svg|13px]] [[File:Helicopter-yellow-icon.svg|13px]] [[File:Helicopter-grey-icon.svg|13px]] [[File:Helicopter-black-icon.svg|13px]] [[File:Helicopter-blue-icon.svg|13px]]<br/>
[[File:Anchor_pictogram.svg|12px]] Major port or naval base ; [[File:Mountain pass 12x12 n.svg|20px]] Border Post ; [[File:Arch dam 12x12 w.svg|16px]] Dam ; [[File:Gota07.svg|12px]] Oil/gas ; [[File:Icon NuclearPowerPlant-black.svg|12px]] Industrial complex <br>'''2 nested circles: inner controls, outer sieges (or indicates strong enemy pressure) // 3 nested circles: mixed control with stable situation <br>Small icons within large circle: situation in individual neighbourhoods/districts''']=]
	}
}