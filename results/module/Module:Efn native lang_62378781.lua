local getArgs = require("Module:Arguments").getArgs
local lang = require("Module:Lang").lang
local p = {}

function p.main(frame)
	local args = getArgs(frame)
	local function nowrap(tag, s) -- Disables wrapping for words under four characters
		if string.len(s) < 12 then
			return table.concat{"<span class=\"nowrap\">", lang{tag, s}, "</span>"}
		else
			return lang{tag, s}
		end
	end
	return args[1] == "tw" and frame:expandTemplate{
		title = "Efn-ur",
		args = {
			name = args.name,
			require("Module:List").bulleted{
				args.t and "[[Traditional Chinese characters|Traditional Chinese script]]: " .. nowrap("zh-Hant-TW", args.t),
				args.p and "[[Taiwanese Mandarin|Mandarin]] [[Pinyin]]: " .. lang{"cmn-Latn-TW", args.p},
				args.m and "[[Taiwanese Hokkien|Hokkien]]: " .. lang{"nan-Latn-TW", args.m},
				args.s and "[[Sixian dialect|Sixian]] Hakka: " .. lang{"hak-Latn-TW", args.s},
				args.h and "[[Hailu dialect|Hailu]] Hakka: " .. lang{"hak-Latn-TW", args.h},
				args.a and "[[Amis language|Amis]]: " .. lang{"ami-Latn-TW", args.a},
				args.pw and "[[Paiwan language|Paiwan]]: " .. lang{"pwn-Latn-TW", args.pw},
				args.ma and "[[Matsu dialect|Matsu]]: " .. lang{"cdo-Latn-TW", args.ma},
			}
		}
	}
end

return p