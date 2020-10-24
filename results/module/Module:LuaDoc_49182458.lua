--[[
This code is work in progress, with all the problems that imply.
Note that documentation in this module is made to test various aspects of the
module itself. Because of this the documentation isn't complete, and can even
be bogus.
--]]

--- Format documentation of a module and make it linkable
-- The module makes some assumptions about the layout, basically the same as
-- [[JavaDoc]] and [[LuaDoc]], but does not follow those examples strictly. Especially,
-- it makes no attempt to do a deeper analysis of the provided code.
-- @author [[User:Jeblad]]
-- @copyright [mailto:jeblad@gmail.com]
-- @license [https://creativecommons.org/licenses/by-sa/3.0/ Creative Commons: Attribution-ShareAlike 3.0 Unported] (CC BY-SA 3.0) 
local luadoc = {}

-- don't pollute with globals
require('Module:No globals')

--- Registry for fragment types
local fragTypes = {}

--- Registry for access points
local access = {}

--- Table acting as a baseclass for fragments
-- @access private
-- @var ..?
-- @field _class string acting as a class marker for the fragment
-- @field _summary table holding the summary (the first line of the description) for the fragment
-- @field _description table holding the description (the remaining text of the description) for the fragment
local Frag = {}
Frag.__index = Frag

setmetatable(Frag, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

--- Initialiser for the Frag class
-- @param t table holding data used during initialization
function Frag:_init( t )
  self['_class'] = t['_class']
  self['_weight'] = t['_weight']
  self['_summary'] = t['_summary']
  self['_description'] = t['_description']
end

--- Weight of the given class viewed as a possible Frag instance
-- @param t table holding data used during initialization
function Frag.weightOfClass( t )
	local weight = 0
	weight = weight + Frag.weightOfClassDescription( t )
	weight = weight + Frag.weightOfClassSignature( t['_code'] )
	return weight
end

--- Weight of the given description viewed as a possible Frag instance
-- @param s string holding a code snippet
function Frag.weightOfClassDescription( s )
	local weight = 0
	return weight
end

--- Weight of the given signature viewed as a possible Frag instance
-- @param s string holding a code snippet
function Frag.weightOfClassSignature( s )
	local weight = 0
	return weight
end

--- Render method for the class member field
-- @param t table for optional data used while rendering
function Frag:renderClass( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-tagline' )
	:wikitext( self['_class'] )
	return html
end

--- Render method for the weight member field
-- @param t table for optional data used while rendering
function Frag:renderWeight( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-weight' )
	:wikitext( self['_weight'] )
	return html
end

--- Render method for the summary member field
-- @param t table for optional data used while rendering
function Frag:renderSummary( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-summary' )
	:wikitext( self['_summary'] )
	return html
end

--- Render method for the description member field
-- @param t table for optional data used while rendering
function Frag:renderDescription( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-description' )
	:wikitext( self['_description'] )
	return html
end

--- Render method for the total Frag structure
-- @param t table for optional data used while rendering
-- @return table the extended parent
function Frag:render( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-fragment' )
	html
		:node(self:renderClass(t))
		:node(self:renderWeight(t))
		:node(self:renderSummary(t))
		:node(self:renderDescription(t))
	return html
end

--- Table acting as a subclass for varables
-- @var ..?
-- @field _var string ..?
-- @access private
local Var = {}
Var.__index = Var

fragTypes['variable'] = Var

setmetatable(Var, {
  __index = Frag,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

--- Initialiser for the Var class
-- @param t table holding data used during initialization
function Var:_init( t )
  Frag._init(self, t)
  self['_var'] = t['_var']
end

--- Weight of the given class viewed as a possible Var instance
-- @param t table holding data used during initialization
function Var.weightOfClass( t )
	local weight = 0
	weight = weight + Var.weightOfClassDescription( t )
	weight = weight + Var.weightOfClassSignature( t['_code'] )
	return weight
end

--- Weight of the given description viewed as a possible Var instance
-- @param t table holding data used during initialization
function Var.weightOfClassDescription( t )
	local weight = 0
	if not t then
		return weight
	end
	weight = weight + Frag.weightOfClassDescription(t)
	weight = weight + (t._class == 'variable' and 100 or 0)
	weight = weight + (t._var and 50 or 0)
	weight = weight + (t._field and 50 or 0)
	weight = weight - (t._param and 50 or 0)
	weight = weight - (t._return and 50 or 0)
	return weight
end

--- Weight of the given signature viewed as a possible Var instance
-- @param s string holding a code snippet
function Var.weightOfClassSignature( s )
	local weight = 0
	if not s then
		return weight
	end
	weight = weight + Frag.weightOfClassSignature(s)
	local exclude = {
		['function'] = true,
	}
	local loc, nme = s:match('(local)%s+([_%a][_%a%d]*)')
	if loc and not exclude[nme] then
		weight = weight + 25
	end
	local nme, eqv = s:match('([_%a][_%a%d]*)%s+(=)')
	if eqv and not exclude[nme] then
		weight = weight + 25
	end
	return weight
end

function Var:renderVar( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-variable' )
	:wikitext( self['_var'] )
	return html
end

--- Render method for the total Var structure
-- @param t table for optional data used while rendering
-- @return table the extended parent
function Var:render( t )
	local html = Frag.render(self, t)
	return html
end

--- Table acting as a subclass for modules
-- @var ..?
-- @access private
local Mod = {}
Mod.__index = Mod

fragTypes['module'] = Mod

setmetatable(Mod, {
  __index = Frag,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

--- Initialiser for the Mod class
-- @param t table holding data used during initialization
function Mod:_init( t )
  Frag._init(self, t)
end

--- Weight of the given class viewed as a possible Frag instance
-- @param t table holding data used during initialization
function Mod.weightOfClass( t )
	local weight = 0
	weight = weight + Mod.weightOfClassDescription( t )
	weight = weight + Mod.weightOfClassSignature( t['_code'] )
	return weight
end

--- Weight of the given description viewed as a possible Mod instance
-- @param t table holding data used during initialization
function Mod.weightOfClassDescription( t )
	local weight = 0
	if not t then
		return weight
	end
	weight = weight + Var.weightOfClassDescription(t)
	weight = weight + (t._class == 'module' and 100 or 0)
	weight = weight - (t._var and 10 or 0)
	weight = weight - (t._field and 10 or 0)
	weight = weight - (t._param and 10 or 0)
	weight = weight - (t._return and 10 or 0)
	return weight
end

--- Weight of the given signature viewed as a possible Mod instance
-- @param s string holding a code snippet
function Mod.weightOfClassSignature( s )
	local weight = 0
	if not s then
		return weight
	end
	weight = weight + Var.weightOfClassSignature(s)
	if s:match('^[ \t]*[\n\r]') then
		weight = weight + 25
	end
	return weight
end

--- Render method for the total Mod structure
-- @param t table for optional data used while rendering
-- @return table the extended parent
function Mod:render( t )
	local html = Frag.render(self, t)
	return html
end

--- Table acting as a subclass for modules
-- @var ..?
-- @access private
local Ret = {}
Ret.__index = Ret

fragTypes['return'] = Ret

setmetatable(Ret, {
  __index = Frag,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

--- Initialiser for the ret class
-- @param t table holding data used during initialization
function Ret:_init( t )
  Frag._init(self, t)
end

--- Weight of the given class viewed as a possible Ret instance
-- @param t table holding data used during initialization
function Ret.weightOfClass( t )
	local weight = 0
	weight = weight + Ret.weightOfClassDescription( t )
	weight = weight + Ret.weightOfClassSignature( t['_code'] )
	return weight
end

--- Weight of the given description viewed as a possible ret instance
-- @param t table holding data used during initialization
function Ret.weightOfClassDescription( t )
	local weight = 0
	if not t then
		return weight
	end
	weight = weight + Frag.weightOfClassDescription(t)
	return weight
end

--- Weight of the given signature viewed as a possible Ret instance
-- @param s string holding a code snippet
function Ret.weightOfClassSignature( s )
	local weight = 0
	if not s then
		return weight
	end
	weight = weight + Frag.weightOfClassSignature(s)
	if s:match('(return)%s+([_%a][_%a%d]*)') then
		weight = weight + 25
	end
	return weight
end

--- Render method for the total Ret structure
-- @param t table for optional data used while rendering
-- @return table the extended parent
function Ret:render( t )
	local html = Frag.render(self, t)
	return html
end

--- Table acting as a subclass for functions
-- @var ..?
-- @field _param table holding all params to the function
-- @field _return table holding all returns from the function
-- @access private
local Func = {}
Func.__index = Func

fragTypes['function'] = Func

setmetatable(Func, {
  __index = Frag,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

--- Initialiser for the Func class
-- @param t table holding data used during initialization
function Func:_init( t )
  Frag._init(self, t)
  self['_param'] = t['_param']
  self['_return'] = t['_return']
end

--- Weight of the given class viewed as a possible Func instance
-- @param t table holding data used during initialization
function Func.weightOfClass( t )
	local weight = 0
	weight = weight + Func.weightOfClassDescription( t )
	weight = weight + Func.weightOfClassSignature( t['_code'] )
	return weight
end

--- Weight of the given description viewed as a possible Func instance
-- @param t table holding data used during initialization
function Func.weightOfClassDescription( t )
	local weight = 0
	if not t then
		return weight
	end
	weight = weight + Var.weightOfClassDescription(t)
	weight = weight + (t._class == 'function' and 100 or 0)
	weight = weight - (t._var and 50 or 0)
	weight = weight - (t._field and 50 or 0)
	weight = weight + (t._param and 50 or 0)
	weight = weight + (t._return and 50 or 0)
	return weight
end

--- Weight of the given signature viewed as a possible Func instance
-- @param s string holding a code snippet
function Func.weightOfClassSignature( s )
	local weight = 0
	if not s then
		return weight
	end
	weight = weight + Var.weightOfClassSignature(s)
	local include = {
		['function'] = true,
	}
	local loc, nme = s:match('(local)%s+([_%a][_%a%d]*)')
	if loc and include[nme] then
		weight = weight + 25
	end
	local eqv,nme = s:match('(=)%s+([_%a][_%a%d]*)')
	if eqv and include[nme] then
		weight = weight + 25
	end
	return weight
end

function Func:renderParam( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-parameter' )
	:wikitext( self['_param'] )
	return html
end

function Func:renderReturn( t )
	local html = mw.html.create( 'div' )
	:addClass( 'luadoc-return' )
	:wikitext( self['_return'] )
	return html
end

--- Render method for the total Func structure
-- @param parent table reference to the containing element
-- @param t table for optional data used while rendering
-- @return table the parent make the method chainable
-- @return table the extended parent
function Func:render( t )
	local html = Frag.render(self, t)
	return html
end

--- Load page identified by text and namespace
-- @since somedate
-- @param text string base name and any subparts
-- @param namespace string containing the namespace on a valid form
-- @return string in a raw form according to the content model
-- @throw string verbatim 'Unknown' if can't find a valid title object
-- @throw string verbatim 'Got no content' if can't get content
local function loadDoc( text, namespace )
	local title = mw.title.new( text, namespace )
	assert( title, 'Unknown title')
	local content = title:getContent()
	assert( content, 'Got no content' )
	return content
end

--- Create a fragment according to a best guess
-- @param frag table containing a single fragment
-- @return table as a subclass of Frag
local function createFragment( frag )
	local maxWeight = -1000
	local clss = nil
	local name = nil
	for k,v in pairs(fragTypes) do
		local weight = v.weightOfClass( frag )
		if weight > maxWeight then
			maxWeight = weight
			clss = v
			name = k
		end
	end

	frag._weight = maxWeight
	
	if maxWeight>=0 then
		frag._class = name
		return clss( frag )
		--return Frag( frag )
	end
	
	frag._class = 'unknown'
	return Frag(frag)
end

--- Strip provided code for block comments
-- @since somedate
-- @param code string providing the program
-- @return string clensed for block comments
local function stripBlockComments( code )
	local collapse = function(s) return s:gsub('^%-%-%[(=*)%[.*]%1%]$', '') end
	return code:gsub('(%-%-+%b[])', collapse)
end

--- Split provided code in fragments
-- @x-access public this should be public if everything works out
-- @since somedate
-- @param code string providing the program
-- @return table of fragments
local function splitOutFragments( code )
	local fragments = {}
	local fragNum = 0
	for slice in mw.text.gsplit(code, "\n%s*%-%-%-%s*") do
		fragNum = 1+fragNum
		if not slice:match('^%s*$') then
			local fragment = { ['_description'] = { '' }, ['_code'] = { '' } }
			if fragNum == 1 then
				fragment._class = #fragment == 1 and 'module' or 'unknown'
				slice = slice:gsub( '^%s*%-%-%-[\ \t]*([^\n\r]+)[\n\r]*',
					function(str) fragment._summary = str; return '' end )
			else
				fragment._class = #fragment == 1 and 'module' or 'unknown'
				slice = slice:gsub( '^%s*([^\n\r]+)[\n\r]*',
					function(str) fragment._summary = str; return '' end )
			end
			local last = '_description'
			for line in slice:gmatch( '([^\n\r]+)' ) do
				if line:match( '^%s*%-%-' ) then
					local attr, text = line:match( '^%s*%-%-%s*@(%a+)%s+(.*)$' )
					if attr then
						last = '_'..attr
						if not fragment[last] then
							fragment[last] = {}
						end
						fragment[last][1+#fragment[last]] = text
					else
						local text = line:match( '^%s*%-%-%s*(.*)$' )
						if fragment[last][#fragment[last]]:match('^%s*$') then
							fragment[last][#fragment[last]] = text
						else
							local joiner = text:match('^%s*$') and '\n' or ' '
							fragment[last][#fragment[last]] =
								fragment[last][#fragment[last]] .. joiner .. text
						end
					end
				else
					last = '_code'
					fragment[last][#fragment[last]] =
						fragment[last][#fragment[last]] .. '\n' .. line
				end
			end
			fragment._description = fragment._description and table.concat(fragment._description, '\n') or nil
			fragment._code = fragment._code and table.concat(fragment._code, '\n') or nil
			if fragment._access then
				local access = { ['public'] = 0, ['private'] = 0 }
				for _,v in ipairs(fragment._access) do
					access[v] = (access[v] or 0) + 500
				end
				fragment._access = access
			end
			fragments[1+#fragments] = fragment
		end
	end
	return fragments
end

--- Parse provided code
-- @x-access public this will be private if everything works out
-- @deprecated somedate this call will not be used
-- @param code string providing the program
-- @return table of fragments
local function parseCode( code )
	local fragments = {}
	local fragment = { ["_class"] = 'module', ["lines"] = 0 }
	local last = nil
	for line in code:gmatch( '([^\n]+)' ) do
		local desc = line:match( '^\s*%-%-%-\s*(.+)' )
		if desc then
			if fragment.lines > 0 then
				fragments[1+#fragments] = parseFragment( fragment )
				fragment = { ["_class"] = nil, ["lines"] = 0 }
			end
			fragment ={}
			last = '_description'
			fragment[last] = desc
		else
			if line:match( '^\s*--' ) then
				local attr, text = line:match( '^\s*%-%-\s*@(\w+)\s+(.*)' )
				if attr then
					last = '_'..attr
					if not fragment[last] then
						fragment[last] = {}
					end
					fragment[last][1+#fragment[last]] = text
				else
					local text = line:match( '^\s*--\s*(.*)' )
					fragment[last][#fragment[last]] = text
				end
			else
				last = '_code'
				fragment[last] = line
			end
		end
	end
	-- @todo check if last fragment is empty
	return fragments
end

if 1 or _G['_BDD'] then
	luadoc.Frag = Frag
	luadoc.Mod = Mod
	luadoc.Ret = Ret
	luadoc.Var = Var
	luadoc.Func = Func
	luadoc.loadDoc = loadDoc
	luadoc.createFragment = createFragment
end

--- Invokable method to build a document
-- @access public
-- @param frame table for contextual information
-- @return string for display on a rendered page
function luadoc.build( frame )
	local docs = {}
	for _,v in ipairs( frame.args ) do
		local str = mw.text.trim( v )
		if str == '' then
			-- do nothing
		else
			-- local name or canonical name, at english only canonical name
			if str:match( '^[mM]odule:' ) then
				local namespace = str:match( '^(%S-)%s*:' )
				local text = str:match( ':%s*(.-)%s*$' )
				local code = loadDoc( text, namespace )
				local stripped = stripBlockComments( code )
				docs[1+#docs] = splitOutFragments( stripped )
			end
		end
	end
	local parent = mw.html.create( 'div' )
	for _,frags in ipairs( docs ) do
		for _,v in ipairs( frags ) do
			--local pre = mw.html.create( 'pre' )
			local frag = createFragment(v)
			parent:node(frag:render())
			--parent:node(v:render())
			--pre:wikitext(mw.dumpObject(Frag(v):render()))
			--parent:node(pre)
		end
	end
	return parent
end

--- Final return of the provided module
return luadoc