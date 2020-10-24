
p = {}

-- carousel returns one of a list of image filenames
--
-- the index of the one chosen increments every 'switchsecs'
-- which is a parameter giving the number of seconds between switches
-- 3600 would switch every hour
-- 43200 would be every 12 hours
-- 86400 would be daily (the default)
--
-- The list of filenames is in a named submodule, so everyone can have their own list.
-- For Komodobish (the default), the module is [[Module:Carousel/Komodobish]].
-- For Serial Number 54129, the module is [[Module:Carousel/54129]].
-- See https://en.wikipedia.org/wiki/Special:PrefixIndex/Module:Carousel/
--
-- {{#invoke:carousel | main | name = name-of-datamodule | switchsecs = number-of-seconds }}
-- {{#invoke:carousel | main | name = 54129 | switchsecs = 10 }} for 10 sec switches using [[Module:Carousel/54129]]
-- {{#invoke:carousel | main }} for 24 hours between switches using the default data module
--

p.main = function(frame)
	-- get parameter switchsecs; if NaN or less than 1, set default
	local switchtime = tonumber(frame.args.switchsecs) or 86400
	if switchtime < 1 then switchtime = 86400 end

	-- get parameter dataname; if missing, use default
	local dataname = frame.args.name or mw.text.trim(frame.args[1]) or ""
	if dataname == "" then dataname = "Komodobish" end

	-- there should be a named data module as a submodule
	local imgs = require("Module:Carousel/" .. dataname)
	local numimgs = #imgs

	-- 'now' increments by 1 every switchtime seconds
	local now = math.floor( os.time() / switchtime )

	-- set an index between 1 and number of images
	local idx = now % numimgs + 1
	return imgs[idx]
end

return p