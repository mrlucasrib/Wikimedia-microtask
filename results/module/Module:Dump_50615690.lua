-- Dump a table to help develop other modules.
-- It is also possible to use mw.dumpObject() but the result from this
-- module is clearer and is close to valid Lua source.
-- The main purpose is to allow easy inspection of Wikidata items.
-- Preview the following in a sandbox to see entity Q833639 as a Lua table:
--   {{#invoke:dump|wikidata|Q833639}}
-- Preview the following to dump a built-in table:
--   {{#invoke:dump|testcase}}

local Collection  -- a table to hold items
Collection = {
	add = function (self, item)
		if item ~= nil then
			self.n = self.n + 1
			self[self.n] = item
		end
	end,
	join = function (self, sep)
		return table.concat(self, sep)
	end,
	remove = function (self, pos)
		if self.n > 0 and (pos == nil or (0 < pos and pos <= self.n)) then
			self.n = self.n - 1
			return table.remove(self, pos)
		end
	end,
	sort = function (self, comp)
		table.sort(self, comp)
	end,
	new = function ()
		return setmetatable({n = 0}, Collection)
	end
}
Collection.__index = Collection

local function pre_block(text)
	-- Pre tags returned by a module do not act like wikitext <pre>...</pre>.
	return '<pre>\n' ..
		mw.text.nowiki(text) ..
		(text:sub(-1) == '\n' and '' or '\n') ..
		'</pre>\n'
end

local function make_tabstr(indent)
	-- Return a string to generate one level of indent.
	if indent == 'tab' then
		-- Tabs do not work well in a browser edit window, but can force them.
		return '\t'
	end
	indent = tonumber(indent)
	if not (type(indent) == 'number' and 1 <= indent and indent <= 32) then
		indent = 4
	end
	return string.rep(' ', indent)
end

local function _dumphtml(html, tabwidth)
	-- Return a pretty-text formatted dump of an html string.
	-- This assumes clean html, for example, tag "<table>" not "< table >".
	if type(html) ~= 'string' then
		return ''
	end
	local selfClosingTags = {  -- from mw.html.lua
		area = true,
		base = true,
		br = true,
		col = true,
		command = true,
		embed = true,
		hr = true,
		img = true,
		input = true,
		keygen = true,
		link = true,
		meta = true,
		param = true,
		source = true,
		track = true,
		wbr = true,
	}
	local tabstr = make_tabstr(tabwidth)
	local function indent_pad(depth, isfirst)
		-- Return a string with an indent to match depth.
		if depth > 0 then
			return '\n' .. string.rep(tabstr, depth)
		end
		return isfirst and '' or '\n'
	end
	local function extract(result, html, pos, len, depth, currenttag)
		-- Dump more of html into table result and return new pos.
		local has_child
		while pos <= len do
			local s, e = html:find('<[^<>]*>', pos)
			if s then
				if s > pos then
					table.insert(result, html:sub(pos, s-1))
				end
				if html:sub(s+1, s+1) == '/' then
					-- A closing tag.
					local tag = html:match('^([a-zA-Z0-9]+)>', s+2) or 'NOTAG'
					if tag == currenttag then
						local indent = has_child and indent_pad(depth - 1) or ''
						table.insert(result, indent .. '</' .. tag .. '>')
					else
						-- Should never happen.
						table.insert(result, '\n</' .. tag .. '>')
					end
					return e + 1
				end
				local tag = html:match('^[a-zA-Z0-9]+', s+1) or 'NOTAG'
				if html:sub(e-1, e-1) == '/' or selfClosingTags[tag] then
					-- A self-closing tag.
					table.insert(result, html:sub(s, e))
					pos = e + 1
				else
					-- An opening tag.
					table.insert(result, indent_pad(depth, pos == 1) .. html:sub(s, e))
					pos = extract(result, html, e+1, len, depth+1, tag)
					has_child = true
				end
			else
				table.insert(result, html:sub(pos))
				break
			end
		end
		return len + 1
	end
	local result = {}
	html = html:gsub('>%s+<', '><'):gsub('\n%s*', ' ')
	extract(result, html, 1, #html, 0)
	return pre_block(table.concat(result))
end

local function dumphtml(frame)
	local args = frame.args
	local pargs = frame:getParent().args
	local text = args[1] or pargs[1]
	local indent = args.indent or pargs.indent
	return _dumphtml(text, indent)
end

local function quoted(str)
	return (string.format('%q', str):gsub('\\\n', '\\n'))
end

local function iterkeys(var, control)
	-- Return an iterator over the keys of var (which should be a table).
	-- The keys are sorted with numbered keys first, then other types.
	-- The iterator returns key, repr where key is the actual key, and
	-- repr is its representation: a number for the ipairs keys, or
	-- a string, including for number keys above the table length.
	if type(var) ~= 'table' then
		return function () return nil end
	end
	local nums = {}
	local results = Collection.new()
	for i, _ in ipairs(var) do
		nums[i] = true
		results:add({ i, i })
	end
	local keys = Collection.new()
	for k, _ in pairs(var) do
		if not nums[k] then
			keys:add(k)
		end
	end
	local autoname = control.autoname
	keys:sort(function (a, b)
			local ta, tb = type(a), type(b)
			if ta == tb then
				if ta == 'number' or ta == 'string' then
					return a < b
				end
				if ta == 'boolean' then
					return b and not a
				end
				return autoname(a) < autoname(b)
			end
			if ta == 'number' then
				return true
			elseif tb == 'number' then
				return false
			else
				return ta < tb
			end
		end)
	for _, k in ipairs(keys) do
		local repr
		local tk = type(k)
		if tk == 'number' then
			repr = '[' .. k .. ']'
		elseif tk == 'string' then
			if k:match('^[%a_][%w_]*$') then
				repr = k
			else
				repr = '[' .. quoted(k) .. ']'
			end
		elseif tk == 'boolean' then
			repr = '[' .. tostring(k) .. ']'
		else
			repr = autoname(k)
			control.needed[repr] = true
		end
		results:add({ k, repr })
	end
	local last = 0
	return function ()
		if last < results.n then
			last = last + 1
			return unpack(results[last])
		end
	end
end

local function vardump(var, vname, depth, control, self, parents)
	-- Update items in control with results from dumping a variable.
	local function put(value, options)
		options = options or {}
		local indent = options.indent or depth
		local comma = (options.kind == 'open' or indent == 0) and '' or ','
		control.items:add({
			key = (type(vname) == 'string' and options.kind ~= 'close') and vname or nil,
			value = value .. comma,
			depth = indent,
			note = options.note
		})
	end
	if var == nil then
		put('nil')
	elseif type(var) == 'string' then
		put(quoted(var))
	elseif type(var) == 'table' then
		local this = control.autoname(var)
		if depth >= control.limitdepth then
			put(this)
		elseif parents and parents[this] then
			control.needed[this] = true
			if self == this then
				put(this, {note = 'self'})
				control.needed['self'] = true
			else
				put(this, {note = 'repeat'})
				control.needed['repeat'] = true
			end
		else
			parents = parents or {}
			parents[this] = true
			self = this
			put('{', {kind = 'open', note = this})
			local mt = getmetatable(var)
			if mt then
				vardump(mt, '__metatable', depth + 1, control, self, parents)
			end
			local maxsize = control.items.n + control.limititems
			for key, keyrep in iterkeys(var, control) do
				if control.items.n > maxsize then
					put('...more...')
					break
				end
				vardump(var[key], keyrep, depth + 1, control, self, parents)
			end
			put('}', { kind = 'close' })
		end
	elseif type(var) == 'boolean' or type(var) == 'number' then
		put(tostring(var))
	else  -- function (or userdata or thread)
		put(control.autoname(var))
	end
end

local function dumper(var, vname, tabwidth, wantraw, limititems, limitdepth)
	-- Return a string representing var in almost-correct Lua syntax.
	-- There is no newline at the end of the result.
	local onames = {}
	local tcounts = {}
	local function autoname(var)
		-- Return a string that is a unique name for var, given it is not
		-- a number or string.
		if not onames[var] then
			local name = type(var)
			tcounts[name] = (tcounts[name] or 0) + 1
			onames[var] = name .. '_' .. tcounts[name]
		end
		return onames[var]
	end
	local control = {
		autoname = autoname,
		limititems = limititems or 10000,
		limitdepth = limitdepth or 50,
		items = Collection.new(),
		needed = {},
	}
	vardump(var, tostring(vname or 'variable'), 0, control)
	local tabstr = make_tabstr(tabwidth)
	local lines = Collection.new()
	for i, v in ipairs(control.items) do
		local indent = string.rep(tabstr, v.depth)
		local note = v.note
		if note and control.needed[note] then
			note = '  -- ' .. note
		else
			note = ''
		end
		local k = v.key and (v.key .. ' = ') or ''
		lines:add(indent .. k .. v.value .. note)
	end
	local raw = lines:join('\n')
	return wantraw and raw or pre_block(raw)
end

local function dump_testcase(frame)
	local item
	if type(frame) == 'table' then
		item = frame.args[1]
	else
		item = frame
	end
	if item == 'G' or item == '_G' then
		return dumper(_G, '_G', frame.args.indent)
	end
	local fruit = { 'apple', 'banana', [0] = 'zero', [{'anon'}] = 'anon' }
	local testcase = {
		[100] = 'one hundred',
		[99] = 'ninety nine',
		[0.5] = 'one half',
		[-1] = 'negative one',
		'one',
		'two',
		[' '] = 'space',
		['1 –◆— z'] = 'unicode',
		alpha = 'aaa',
		beta = 'bbb',
		c = 123,
		data = {
			dumper = dumper,
			[dumper] = 'dumper',
			'three',
			'four',
			T = true,
			[true] = 'T',
			alpha2 = 'aaa2',
			beta2 = 'bbb2',
			F = false,
			[false] = 'F',
			c2 = 1234,
			data2 = {
				'five',
				'six',
				alpha3 = 'aaa3',
				beta3 = 'bbb3',
				c3 = 12345,
				fruit = fruit,
				[fruit] = 'fruit',
			},
		},
		z = 'zoo',
	}
	testcase.testcase = testcase
	testcase.data.me = testcase.data
	testcase.data.data2.me = testcase
	testcase.data.data2.fruit.back = testcase.data
	setmetatable(testcase.data, {
		__index = function (self, key) return type(key) == 'string' and #key or nil end,
		__tostring = function (self) return tostring(#self) end,
	})
	if item == 'return table' then
		return testcase
	end
	return dumper(testcase, 'testcase', frame.args.indent)
end

local function execute(frame)
	-- Return a dump of the result from executing {{#invoke:dump|execute|EXPRESSION}}.
	-- In general that is not possible in Scribunto so this has built-in code
	-- to parse some expressions of interest.
	-- The primary aim is to test the result of calling a Wikidata function
	-- while previewing an edit in an article.
	-- Examples of EXPRESSION:
	--   mw.wikibase.getEntityIdForCurrentPage()
	--   mw.wikibase.getBestStatements('Q868', 'P214')
	--   mw.wikibase.getBestStatements(Q868, P214)       -- also accepted
	--   mw.wikibase.getEntity():getDescription('de')
	--   mw.wikibase.getEntity('Q868'):getDescription('de')
	-- getEntityObject is an alias for getEntity.
	-- Using the following gives an "out of memory" error presumably because
	-- the result is a table with a metatable that dump repeatedly expands.
	--   mw.title.getCurrentTitle()
	local function params(ptext, first)
		local p = { first }
		for item in (ptext .. ','):gmatch('(%S.-)%s*,') do
			-- Remove any quotes around each parameter because it is already a string.
			local _, s = item:match([[^%s*(['"])(.*)%1%s*$]])
			table.insert(p, s or tonumber(item) or item)
		end
		return unpack(p)
	end
	local expression = frame.args[1] or ''
	local text = expression:match('^%s*mw(%..-)%s*$')
	if not text then
		return 'Expression not recognized: "' .. expression .. '"'
	end
	-- Look for a supported expression of form 'mw.a.b(c):d.e(f)'.
	local entity
	local object = mw
	local item, ptext, rest = text:match('^%.wikibase%.(%w+)%s*%((.*)%):(.*)$')
	if item == 'getEntity' or item == 'getEntityObject' then
		entity = mw.wikibase.getEntity(params(ptext))
		if not entity then
			return 'No entity found for (' .. ptext .. ')'
		end
		object = entity
		text = '.' .. rest  -- treat ':' as '.'
	end
	local upto = 1
	for i1, item, i2 in text:gmatch('()%.(%w+)()') do
		if i1 == upto and type(object) == 'table' then
			object = object[item]
		else
			object = nil
		end
		if object == nil then
			return 'Invalid item "' .. item .. '"'
		end
		if type(object) == 'function' then
			if text:sub(i2, i2 + 1) == '()' then
				object = object()
				i2 = i2 + 2
			end
		end
		upto = i2
	end
	local parm = text:sub(upto):match('^%((.*)%)%s*$')
	if parm then
		object = object(params(parm, entity))
	end
	return dumper(object, expression)
end

local function parameters(frame)
	-- Return text dump of args and parent args from frame.
	-- This is for debugging a module to show what parameters it received.
	local control = {
		autoname = function (var) return tostring(var) end,  -- should not be called since keys should be numbers or strings
	}
	local pframe = frame:getParent()
	local lines = Collection.new()
	lines:add('')
	for _, parms in ipairs({
				{ frame.args, '[[' .. frame:getTitle() .. ']]' },
				{ pframe.args, '[[' .. pframe:getTitle() .. ']]' },
			}) do
		lines:add(parms[2])
		for key, keyrep in iterkeys(parms[1], control) do
			lines:add('&nbsp;&nbsp;' .. mw.text.nowiki(keyrep .. '=' .. parms[1][key]))
		end
	end
	lines:add('')
	return lines:join('<br>\n')
end

local function wikidata(frame)
	local item = frame.args[1]
	if item then
		local id = item:match('^%s*([PQ]%d+)%s*$')
		if id then
			local entity = mw.wikibase.getEntity(id)
			return dumper(entity, id, frame.args.indent)
		end
	end
	return 'Parameter should be a Wikidata identifier such as P2386 or Q833639'
end

local builtins = {
	-- Handle preview of wikitext like {{#invoke|dump|TEXT}}
	-- where TEXT is a built-in value that can be dumped.
	__index = function (self, key)
		local result
		local function caller()
			return result
		end
		if type(key) == 'string' then
			local title = key:match('^%s*[\'"]?(.*%.tab)[\'"]?%s*$')
			if title then
				-- Assume structured data from Commons at [[c:Data:<title>]].
				if title:match('^[Dd]ata:') then
					title = title:sub(6)
				end
				local data = mw.ext.data.get(title)  -- false if page does not exist
				result = dumper(data, '[[c:Data:' .. title .. ']]')
			end
		end
		result = result or ('UNKNOWN: ' .. tostring(key))
		return caller
	end
}

return setmetatable({
	_dump = dumper,
	_dumphtml = _dumphtml,
	dumphtml = dumphtml,
	execute = execute,
	parameters = parameters,
	testcase = dump_testcase,
	wikidata = wikidata,
}, builtins)