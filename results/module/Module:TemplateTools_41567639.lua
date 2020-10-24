 -- The EVENTUAL goal of this module is to convert an arbitrary template into a Lua module automatically.
 -- That is a long, long way off.
 -- Interim goals:
 -- 1. Create a complete list of template parameters and immediate piped default values for each.
 -- 2. Develop a function to automatically format a generated module with appropriate indents.
 -- 2a. (sidetrack)  Generalize it to work with any human-written module.
 -- 3. Make a ''nominal'' Template to Module translation, using frame:preprocess() of most of the code with variables replaced.
 -- 4. Divide these frame:preprocess modules at any top-level text concatenation step.
 -- 5. (Hard) Move #switch, #if, #ifeq statements to the Lua module.
 -- 6. (Goose chase) Implement more obscure parser functions like #iferror
 -- 7. Expand transclusions keeping track of the variables involved.
 -- 8. (AI-level) Find a way to recognize a few situations where indexed variables something1 to something20 are treated identically and create a for loop.
 -- I'm thinking to actually do 1-4 and perhaps 2a, not sure what happens after that.

local TemplateTools = {}
local getArgs = require("Module:Arguments").getArgs
local debuglog = ""
 -- local PREFIX = "tv" -- this introduces too many extra concatenations to use; no includes in Lua!
local Template = {} -- this is intended as a class for templates to use

local function escapevarname(var) -- I should find out what other funny chars can be in a template variable name!
	var = mw.ustring.gsub(var, "%-", "_")
    return var
end

function Template:clear()
	 -- remove outdated content and list the default values for a new Template
	self.content = ""
	self.page = nil
	self.title = nil
	self.cuts = {}
	self.params = {}
end

function Template:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:clear()
    return o
end

function Template:setContent(text)
	self:clear()
    self.content = text
end

function Template:loadPage(page)
	self:clear()
	self.page = page
	self.title = mw.title.new(page)
	self.content = self.title and self.title:getContent()
    return self.content
end

function Template:cut(posn, endposn, pre, post, marker) -- pre, post are unused currently
	 -- the following two commands should cut but preserve all text EITHER in a new self.cuts[n] OR in the original.
    table.insert(self.cuts, mw.ustring.sub(self.content, posn, endposn))
    self.content = mw.ustring.sub(self.content, 1, posn - 1) .. (marker or "") .. mw.ustring.sub(self.content, endposn + 1, -1)
    return #self.cuts -- where to get your string back, if desired
end

function Template:str(posn, endposn, pre, post)
    marker = "[Module:TemplateTools string #" .. tostring(#self.cuts) .. "]"
    return self:cut(posn, endposn, pre, post, marker)
end

function Template:tags(posn, endposn, pre, post)
	self:cut(endposn - post + 1, endposn)
    return self:cut(posn, posn + pre - 1)
end

function Template:restore(cuttype, cut) -- string, number
	return self.cuts[cut]
end

function Template:translate(cuttype, cut) -- string, number
	local cuttext = self.cuts[cut]
	local done -- tracks if the gsub happened
	local varfix = function(var, rest)
		local escvar = escapevarname(var)
		local defstring = rest or "&#123;&#123;&#123" .. var .. "&#125;&#125;&#125;"
		return "]====] .. (t_" .. escvar .. " or [====[" .. defstring .. "]====]) .. [====["
	end
	if "var" == cuttype then
		cuttext, done = mw.ustring.gsub(cuttext, "^{{{(.-)|(.-)}}}$", varfix)
		if (0 == done) then cuttext = mw.ustring.gsub(cuttext, "^{{{(.-)}}}$", varfix) end
	end
	return cuttext
end

function Template:unstrip(text, translate)
	-- nil defaults to the current self.content of the template, but note it doesn't actually change self.content
	newtext = text or self.content
	repeat
		text = newtext
	    if translate then
	        newtext = mw.ustring.gsub(text, "%[Module:TemplateTools (%a-) #(%d-)%]", function(cuttype, cut) return self:translate(cuttype, tonumber(cut)) end)
        else
            newtext = mw.ustring.gsub(text, "%[Module:TemplateTools (%a-) #(%d-)%]", function(cuttype, cut) return self:restore(cuttype, tonumber(cut)) end)
        end
    until (text == newtext)
    return text
end

function Template:strip(mode)
         -- mode is include (keep includes) or noinclude (keep noincludes)
         -- first set up the possible actions when pre-parsing tags are encountered
        local COMMENT, NOWIKI, INCLUDE, NOINCLUDE = 1, 2, 3, 4 
        local tags = {pre = {"<!--", "<nowiki>", "<includeonly>", "<noinclude>"}, post = {"-->", "</nowiki>", "</includeonly>", "</noinclude>"}, action = {self.cut, self.str, nil, nil} } -- *** not a complete list, I think!
        if ("noinclude" == mode) then
            tags.action[NOINCLUDE] = self.tags
            tags.action[INCLUDE] = self.cut
        else
            tags.action[INCLUDE] = self.tags
            tags.action[NOINCLUDE] = self.cut
        end
         -- replace relevant tags, left to right
        repeat
            local posn, kind = nil, 0 -- posn is nil whenever nothing is found
            for i = 1, #(tags.pre) do
                local newposn = mw.ustring.find(self.content, tags.pre[i], 1, plain)
                if (newposn and ((not posn) or (newposn < posn))) then
                    posn, kind = newposn, i
                end
            end
            if (not posn) then break end
            endposn = mw.ustring.find(self.content, tags.post[kind], posn, plain) + #tags.post[kind] - 1
            tags.action[kind](self, posn, endposn, #tags.pre[kind], #tags.post[kind])
        until (not posn)
end

function Template:nextParam()
	local newstart
	local nstart, nend = mw.ustring.find(self.content, "{{{.-}}}")
	if (not nstart) then return nil end
	local nextp = mw.ustring.sub(self.content, nstart + 3, nend - 3)
	repeat
		newstart = mw.ustring.find(nextp, "{{{.-$")
		if (not newstart) then break end
		nstart = nstart + newstart + 2
		nextp = mw.ustring.sub(nextp, newstart + 3, nend - 3)
	until false
	local marker = "[Module:TemplateTools var #" .. tostring(#self.cuts) .. "]"
	-- At this point we've settled on where to cut overall, but there's still a question of
	-- stuff like {{{d|{{#if:{{{a}}}|x|y}}}}}.  Count { and } and TRY to balance
	local ltextra = (mw.ustring.find(nextp, "{") or 0) - (mw.ustring.find(nextp, "}") or 0)
	for i = 1, ltextra do
		if "}" ~= mw.ustring.sub(self.content, nend + 1, nend + 1) then break end
        nend = nend + 1 -- expand the region to cut
    end
    self:cut(nstart, nend, 0, 0, marker) -- we have the smallest {{{ }}} unit, now CHOP IT OUT
	return nextp
end

function Template:updateParams()
	 -- WARNING: Template MUST be stripped (either noinclude or include) first or these may be mangled
	self.params = {}
	self.defaults = {}
	local param
	repeat
	    param = self:nextParam(cursor)
	    if (not param) then break end
	    local var, default = mw.ustring.match(param, "^(.-)|(.-)$")
	    var, default = var or param, default or false -- default is either a string or false (stand-in for nil)
	     -- after going half nuts, I want a separate stupid SEQUENCE of vars
	     -- self.defaults[var] also tracks if a var has been taken down already
	    if (not self.defaults[var]) then table.insert(self.params, var) end
	    self.defaults[var] = self.defaults[var] or {} -- start a table in self.defaults[this parameter name]
	    if (not self.defaults[var][default]) then self.defaults[var][default] = 0 end -- start countiung
	    self.defaults[var][default] = self.defaults[var][default] + 1 -- add a count of the usage
    until not param
    table.sort(self.params)
    return self.params, self.defaults
end

function Template:listParams()
     -- the purpose of this routine is to start with a newly loaded array and deliver a list of parameters
	 -- in alphabetical order, followed by a list of the defaults in the format {value, frequency} in order of value
	self.paramlist = {}
	for i = 1, #self.params do
		local defset = {}
		for k, v in pairs(self.defaults[self.params[i]]) do
			if k then
				k = '"' .. k .. '"'
				repeat
				    local kk = k
				    k = t:unstrip(kk)
				until k == kk
				k = mw.text.nowiki(k)
			else
				k = "[none]"
			end
			v = mw.text.nowiki(tostring(v))
			table.insert(defset, {['k'] = k, ['v'] = v})
		end
		table.insert(self.paramlist, {['var'] = t.params[i], ['defaults'] = defset})
    end
    return self.paramlist
end

function Template:toModule()
	local content = self:unstrip(nil, true)
	local paramlist = self:listParams()
	local vartable = {}
	for i = 1, #paramlist do
	    table.insert(vartable, "local t_" .. escapevarname(paramlist[i].var) .. " = args['" .. paramlist[i].var .. "']\n")
	end
	self.module = 'local p = {}\nlocal getArgs = require("Module:Arguments").getArgs\nfunction p.main(frame)\nlocal args = getArgs()\n' .. table.concat(vartable) .. 'return frame:preprocess([====['.. content .. ']====])\nend\nreturn p' -- I should really make SURE the quote isn't in it, but for now...
	return "<pre>" .. mw.text.nowiki(self.module .. debuglog) .. "</pre>"
end

 ------ USER FUNCTIONS -------
function TemplateTools.tomodule(frame)
    t = TemplateTools.main(frame)
    return t:toModule()
end

function TemplateTools.main(frame)
	local args = getArgs(frame)
	local page = args.page or args[1]
	local title
	local output = ""
	if (not page) then
		title = mw.title.getCurrentTitle()
		page = title.fullText
		page = mw.ustring.gsub(page, "(.-) talk:", "(%1):")
    end
    t = Template:new()
    t:loadPage(page)
	t:strip() -- should do nothing if already done; defaults to include version which is the only one with params
	t:updateParams()
	return t
end

function TemplateTools.params(frame)
     -- the purpose of this routine is to start with a newly loaded array and deliver a list of parameters
	 -- in alphabetical order, followed by a list of the defaults in the format {value, frequency} in order of value
	t = TemplateTools.main(frame)
	local paramlist = t:listParams()
	local output = ""
	for i = 1, #paramlist do
		local outsec = ""
        for j = 1, #(paramlist[i].defaults) do
			if outsec ~= "" then outsec = outsec .. "\n|-" end
			outsec = outsec .. "\n|" .. (paramlist[i].defaults[j].k or "[NIL]") .. " ''(" .. (paramlist[i].defaults[j].v or "[NIL]") .. ")'' "
		end
		output = output .. "\n|-\n|rowspan=" .. tostring(#(paramlist[i].defaults)) .. "|" .. paramlist[i].var .. "\n" .. outsec
    end
    output = '{| class = "wikitable"' .. output .. '\n|}'
    return output .. debuglog
end

function TemplateTools.test(frame)
        local testout = "test run:"
	t = Template:new()
	t:loadPage(args[1])
	t:strip()
	t:updateParams()
        for k, v in pairs(t.params) do
            testout = testout .. "*" .. tostring(k)
        end
        for i = 1, #t.cuts do
        	debuglog = debuglog .. "\nCUT: " .. mw.ustring.gsub(t.cuts[i],"<","&lt;") .. "\n"
        end
	return mw.text.nowiki(frame.args[1] .. "\n" .. testout .. debuglog)
end

return TemplateTools