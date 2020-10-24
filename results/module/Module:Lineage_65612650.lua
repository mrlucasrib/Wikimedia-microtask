require('Module:No globals')
local getArgs = require('Module:Arguments').getArgs
local errorCategory = '[[Categoria:Errors reported by Module Lineage]]'
local mwHtml = getmetatable( mw.html.create() ).__index

function mwHtml:attrIf( cond, name, value )
    if cond then
        return self:attr( name, value )
    else
        return self
    end
end

function mwHtml:cssIf( cond, name, value )
    if cond then
        return self:css( name, value )
    else
        return self
    end
end

function mwHtml:wikitextIf( cond, value1, value2 )
    if cond then
        return self:wikitext( value1 )
    elseif not (value2 == nil) then
        return self:wikitext( value2 )
    else
    	return self
    end
end

local p = {}
local pers = {}
local tabella = {}

local function errhandler(msg)
	local cat = mw.title.getCurrentTitle().namespace == 0 and errorCategory or ''
	return string.format('<span class="error">%s</span>%s', msg, cat)
end

local function dividi(dati)
	local n = 1
	local resto = 0
	local nx,px
	while (dati[n]) do n = n+1 end
	n = n-1
	for m=4,n,4 do
		nx = tonumber(dati[m-3])
		px = tonumber(dati[m-2])
		if (nx) then
			if (px) then
				if (pers[nx]) then
					error(string.format('Duplicated id %d',nx))
				else
					pers[nx] = { padre = px, testo = dati[m-1], nota = dati[m], id = -1, x = -1, y = -1, sp = 0, figli = {} }
				end
			else
				error(string.format('Erroneous parent id %s for id %d',dati[m-2],nx))
			end
		else
			error(string.format('Erroneous id %s',dati[m-3]))
		end
		resto = n-m
	end
	if (resto > 0) then
		error(string.format('Erroneous number of data %d (elementi in più: %d)',n))
	end
end

local function organizza(pid, y)
	local nn = 1
	pers[pid].y = y
	if (not tabella[y]) then tabella[y] = {} end
	table.insert(tabella[y], pid)
	for i, v in pairs(pers[pid].figli) do
		pers[v].id = i
		nn = nn + organizza(v, y+1)
	end
	return nn
end

local function limSx(pid, delta, dt)
	if (dt[pers[pid].y]) then
		dt[pers[pid].y] = math.min(dt[pers[pid].y], pers[pid].x+delta)
	else
		dt[pers[pid].y] = pers[pid].x + delta
	end
	for _, v in pairs(pers[pid].figli) do
		dt = limSx(v, delta+pers[pid].sp, dt)
	end
	return dt
end

local function limDx(pid, delta, dt)
	if (dt[pers[pid].y]) then
		dt[pers[pid].y] = math.max(dt[pers[pid].y], pers[pid].x+delta)
	else
		dt[pers[pid].y] = pers[pid].x + delta
	end
	for _, v in pairs(pers[pid].figli) do
		dt = limDx(v, delta+pers[pid].sp, dt)
	end
	return dt
end

local function riallinea(pid2, n1, n2)
	local distanza = n2 - n1
	local vrf = 0
	local pos, inizio, passo
	if (distanza > 1) then
		inizio = pers[pers[pid2].figli[n1]].x
		passo = (pers[pers[pid2].figli[n2]].x - inizio)/distanza
		for cc=1,(distanza-1) do
			pos = inizio + math.floor(cc*passo)
			if (pos - pers[pers[pid2].figli[n1+cc]].x > 0) then
				pers[pers[pid2].figli[n1+cc]].x = pos
				pers[pers[pid2].figli[n1+cc]].sp = pos
			end
		end
		vrf = 1
	end
	return vrf
end

local function verifica(pid)
	local tSx
	local tDx
	local sposta = 0

	local fine = pers[pid].id
	local frt2, n
	
	for frt=1,(fine-1) do
		frt2 = pers[pers[pid].padre].figli[frt]
		tDx = limDx(frt2, 0, {})
		tSx = limSx(pid, 0, {})
		n = pers[pid].y
		while ((tSx[n]) and (tDx[n])) do
			if (tSx[n] - tDx[n] + sposta < 2) then
				sposta = 2 + tDx[n] - tSx[n]
			end
			n = n + 1
		end
		if  (sposta > 0) then
			pers[pid].x = pers[pid].x + sposta
			pers[pid].sp = pers[pid].sp + sposta
			if (riallinea(pers[pid].padre, frt, fine) == 1) then verifica(pid) end
			sposta = 0
		end
	end
end

local function calcolaX1(pid)
	for _, v in pairs(pers[pid].figli) do
		calcolaX1(v)
	end
	local tt = #pers[pid].figli
	if (tt == 0) then
		if (pers[pid].padre == -1 or pers[pid].id == 1) then
			pers[pid].x = 0
		else
			pers[pid].x = pers[pers[pers[pid].padre].figli[pers[pid].id - 1]].x + 2
		end
	elseif (tt == 1) then
		if (pers[pid].padre == -1 or pers[pid].id == 1) then
			pers[pid].x = pers[pers[pid].figli[1]].x
		else
			pers[pid].x = pers[pers[pers[pid].padre].figli[pers[pid].id - 1]].x + 2
			pers[pid].sp = pers[pid].x - pers[pers[pid].figli[1]].x
			verifica(pid)
		end
	else
		local media = math.floor((pers[pers[pid].figli[1]].x + pers[pers[pid].figli[tt]].x)/2)
		if (pers[pid].padre == -1 or pers[pid].id == 1) then
			pers[pid].x = media
		else
			pers[pid].x = pers[pers[pers[pid].padre].figli[pers[pid].id - 1]].x + 2
			pers[pid].sp = pers[pid].x - media
			verifica(pid)
		end
	end
end

local function calcolaX2(pid)
	local sposta = 0
	local tt = limSx(pid, 0, {})
	for _, v in pairs(tt) do
		if (v+sposta<0) then
			sposta = -v
		end
	end
	if (sposta > 0) then
		pers[pid].x = pers[pid].x + sposta
		pers[pid].sp = pers[pid].sp + sposta
	end
end

local function calcolaX3(pid, sposta)
	pers[pid].x = pers[pid].x + sposta
	for _, v in pairs(pers[pid].figli) do
		calcolaX3(v, sposta + pers[pid].sp)
	end
end

local function massimoXY(pid, t)
	if (pers[pid].x > t[1]) then t[1] = pers[pid].x end
	if (pers[pid].y > t[2]) then t[2] = pers[pid].y end
	for _, v in pairs(pers[pid].figli) do
		t = massimoXY(v,t)
	end
	return t
end

local function mostraX(pid,allinea,largo,dida)
	local posx = {}
	local n1
	local stx
	local riga = {}
	local xx, xp
	local stileDiv = { ['width'] = largo..'px', ['padding'] = '3px', ['background'] = '#FFF', ['border'] = '1px solid #C8CCD1' }
	local stileTabella = { ['border-collapse'] = 'separate', ['text-align'] = 'center', ['font-size'] = '95%', ['line-height'] = '105%', ['margin'] = '10px auto !important', }
	local xy = massimoXY(pid, {0, 0})
	local lg = math.floor(100/(xy[1]+2))
	if (lg == 0) then lg = 1 end

	local bDiv = mw.html.create('div')
	if (allinea == 'right') then
		bDiv:css(stileDiv):addClass('floatright')
		stileTabella['margin'] = '0px auto !important'
	end
	local bTabella = mw.html.create('table')
		:css(stileTabella)
		:attr({['cellpadding']='1',['cellspacing']='0',['border']='0'})
	for n=1,xy[2] do
		local riga1 = mw.html.create('tr')
		local riga2 = mw.html.create('tr')
		local riga3 = mw.html.create('tr')
		posx[1] = 0; posx[2] = 0; posx[3] = 0
		n1 = 0
		if (n>1) then riga1:css('line-height','8px') end
		if (n<xy[2]) then riga3:css('line-height','8px') end
		for _, v in pairs(tabella[n]) do
			xx = pers[v].x
			xp = pers[v].padre
			
			if (n==1) then
				for m=1,(xy[1]+2) do
					riga1:node(mw.html.create('td'):css('width',lg..'%'))
				end
			else
				riga1:node(mw.html.create('td')
					:css('border-right','1px solid #000')
					:cssIf(n1 == xp,'border-top','1px solid #000')
					:attrIf(xx-posx[1]>0,'colspan',xx+1-posx[1])
					:wikitext('&nbsp;')
				)
				n1 = xp
				posx[1] = xx + 1
			end

			if (xx-posx[2]>0) then
				riga2:node(mw.html.create('td')
					:attrIf(xx-posx[2]>1,'colspan',xx-posx[2])
					:wikitext('&nbsp;')
				)
			end
			riga2:node(mw.html.create('td')
				:attr('colspan','2')
				:wikitextIf(pers[v].nota=='-', pers[v].testo, string.format('%s<br/><span style="font-size:90%%"><i>%s</i></span>',pers[v].testo,pers[v].nota))
			)
			posx[2] = xx + 2

			if (n<xy[2]) then
				if (#pers[v].figli > 0) then
					riga3:node(mw.html.create('td')
						:css('border-right','1px solid #000')
						:attrIf(xx-posx[3]>0,'colspan',xx+1-posx[3])
						:wikitext('&nbsp;')
					)
					posx[3] = xx + 1
				end
			end
		end

		bTabella:node(riga1):node(riga2):node(riga3)
	end

	bDiv:node(bTabella)
	if (allinea == 'right' and not (dida=='')) then
		bDiv:node(mw.html.create('p')
			:css({['font-size'] = '87%', ['font-style'] = 'normal', ['border-top'] = '1px solid #c8ccd1', ['margin'] = '8px 2px 3px'})
			:wikitext(dida)
		)
	end
	return tostring(bDiv)
end

local function calcolaY(pid, t)
	if (pers[pid].y > t) then t = pers[pid].y end
	for _, v in pairs(pers[pid].figli) do
		t = calcolaY(v,t)
		pers[pid].sp = pers[pid].sp + 1 + pers[v].sp
	end
	return t
end

local function mostraY(pid)
	local bTabella = mw.html.create('table')
		:attr({['cellpadding']='0',['cellspacing']='0',['border']='0'})
		:css({['border-collapse']='separate',['text-align']='left',['margin']='10px 0 10px 16px'})

local function mostraY2(pid, a)
	if (pers[pid].padre > -1) then
		local riga1 = mw.html.create('tr')
		local riga2 = mw.html.create('tr')
		local spd = pers[pers[pid].padre].sp
		if (pers[pid].id == 1 and pers[pers[pid].padre].padre > -1) then
			riga1:node(mw.html.create('td')
				:attr('rowspan',2*spd))
			riga1:node(mw.html.create('td')
				:attr('rowspan',2*spd)
				:cssIf(pers[pers[pid].padre].id < #pers[pers[pers[pid].padre].padre].figli,'border-left','1px solid #666')
			)
		end
		riga1
			:node(mw.html.create('td')
				:css('width','6px'))
			:node(mw.html.create('td')
				:css({['border-left']='1px solid #666',['border-bottom']='1px solid #666',['width']='10px',['line-height']='3px',['height']='12px'}))
			:node(mw.html.create('td')
				:attr({['colspan']=2*a-1, ['rowspan']=2})
				:css('padding', '0px 3px 2px 1px')
				:wikitextIf(pers[pid].nota=='', pers[pid].testo, pers[pid].testo..' - '..pers[pid].nota))
		riga2
			:node(mw.html.create('td'))
			:node(mw.html.create('td')
				:css({['line-height']='8px',['line-height']='3px',['height']='12px'})
				:cssIf(pers[pid].id < #pers[pers[pid].padre].figli,'border-left','1px solid #666'))
		bTabella:node(riga1):node(riga2)
	else
		bTabella:node(
			mw.html.create('tr')
				:node(mw.html.create('td')
					:attr('colspan',2*a-1)
					:css('padding','0px 0px 2px 2px')
					:wikitextIf(pers[pid].nota=='',pers[pid].testo,pers[pid].testo..' - '..pers[pid].nota)
				)
		)
	end
	if (pers[pid].sp > 0) then
		for _, v in pairs(pers[pid].figli) do
			mostraY2(v,a-1)
		end
	end
end

	mostraY2(pid,calcolaY(pid,0))
	return tostring(bTabella)
end

function p._lineage(args)
	local capo = -1
	local n1, n2
	local lato = args['align'] or 'center'
	local larg = args['width'] or '300'
	local tipo = args['show'] or 'h'
	local dida = args['caption'] or ''
	dividi(args)
	n1 = 0
	for i, v in pairs(pers) do
		n1 = n1+1
		if (v.padre == -1) then
			if (capo == -1) then
				capo = i
			else
				error(string.format('Duplicated progenitor (id = %d, %d)',capo,i))
			end
		else
			if (v.padre == i) then
				error(string.format('%d is parent of himself', i))
			elseif (pers[v.padre]) then
				table.insert(pers[v.padre].figli,i)
			else
				error(string.format('Erroneous parent id %d for row with id %d',v.padre,i))
			end
		end
	end

	if (capo == -1) then
		error('Progenitor not found')
	else
		n2 = organizza(capo, 1)
		if (n1 == n2) then
			if (tipo == 'v') then
				return mostraY(capo)
			elseif (tipo == 'h') then
				calcolaX1(capo)
				calcolaX2(capo)
				calcolaX3(capo, 0)
				return mostraX(capo, lato, larg, dida)
			end
		else
			error('Some elements are not linked to the progenitor')
		end
	end
end

function p.lineage(frame)
	local args = getArgs(frame, {
		valueFunc = function (key, value)
			if type(key) == "number" then
				if value == nil then
					return nil
				else
					value = mw.text.trim(value)
				end
			else
				if value == '' then return nil end
            end
			return value
		end
	})
	return p._lineage(args)
end

return p