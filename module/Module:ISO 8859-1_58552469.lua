local p = {}

-- Convert pairs of hex digits (optionally separated by
-- non-hex-digit characters) in a string to the corresponding bytes.
local function from_hex_str(hex_str)
	return (hex_str:gsub("(%x%x)%X*",
		function (hex)
			return string.char(tonumber(hex, 16))
		end))
end

function p._show_file_signature(str)
	str = from_hex_str(str):gsub(".",
		function (char)
			local byte = char:byte()
			-- Show C0 and C1 control characters and the delete character as ".".
			if 0x00 <= byte and byte <= 0x1F or 0x7F <= byte and byte <= 0x9F then
				return "."
			-- Between 0xA0 and 0xFF, the byte value is the same as the code
			-- point for the character that the byte represents in ISO 8859-1.
			elseif byte >= 0xA0 then
				return mw.ustring.char(byte)
			end -- else don't change char
		end)
	
	return str
end

function p.show_file_signature(frame)
	local file_signature = frame:getParent().args[1]
	
	return frame:extensionTag("pre", p._show_file_signature(file_signature))
end

return p