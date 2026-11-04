-- jproperty.codec -- pure single-line encode/decode logic.
--
-- No buffer access here; the buffer-level API lives in jproperty.init.
-- The UTF-8 helpers are hand-written on purpose: vim.u8 was removed from
-- Neovim in 0.11, so this keeps the plugin dependency-free.

local M = {}

--- Convert a Unicode codepoint to its UTF-8 byte representation.
---@param cp integer Unicode codepoint (0..0x10FFFF)
---@return string
local function codepoint_to_utf8(cp)
	if cp < 0x80 then
		return string.char(cp)
	elseif cp < 0x800 then
		return string.char(
			0xC0 | ((cp >> 6) & 0x1F),
			0x80 | (cp & 0x3F)
		)
	elseif cp < 0x10000 then
		return string.char(
			0xE0 | ((cp >> 12) & 0x0F),
			0x80 | ((cp >> 6) & 0x3F),
			0x80 | (cp & 0x3F)
		)
	else
		return string.char(
			0xF0 | ((cp >> 18) & 0x07),
			0x80 | ((cp >> 12) & 0x3F),
			0x80 | ((cp >> 6) & 0x3F),
			0x80 | (cp & 0x3F)
		)
	end
end

--- Decode \uXXXX sequences in a single line (lowercase 'u' only).
--- All other characters (including \n, \t, \\, etc.) are left untouched.
--- Handles surrogate pairs. Lone surrogates are preserved as-is.
---@param line string
---@return string
function M.decode_line(line)
	local result = {}
	local i = 1
	local len = #line

	while i <= len do
		local c = line:sub(i, i)

		if c == '\\' and i < len and line:sub(i + 1, i + 1) == 'u' and i + 5 <= len then
			local hex = line:sub(i + 2, i + 5)
			if hex:match('^%x%x%x%x$') then
				local cp = tonumber(hex, 16)

				if cp >= 0xD800 and cp <= 0xDBFF then
					-- High surrogate: check if immediately followed by a
					-- low surrogate escape
					local decoded = nil
					if i + 11 <= len then
						local prefix = line:sub(i + 6, i + 7)
						local lo_hex = line:sub(i + 8, i + 11)
						if prefix == '\\u' and lo_hex:match('^%x%x%x%x$') then
							local lo = tonumber(lo_hex, 16)
							if lo >= 0xDC00 and lo <= 0xDFFF then
								local combined = 0x10000
									+ ((cp - 0xD800) << 10)
									+ (lo - 0xDC00)
								decoded = codepoint_to_utf8(combined)
								i = i + 12
							end
						end
					end
					if decoded then
						result[#result + 1] = decoded
					else
						-- Lone high surrogate: keep as-is
						result[#result + 1] = line:sub(i, i + 5)
						i = i + 6
					end

				elseif cp >= 0xDC00 and cp <= 0xDFFF then
					-- Lone low surrogate: keep as-is
					result[#result + 1] = line:sub(i, i + 5)
					i = i + 6

				else
					result[#result + 1] = codepoint_to_utf8(cp)
					i = i + 6
				end

			else
				-- Not a valid \uXXXX: emit backslash literally
				result[#result + 1] = c
				i = i + 1
			end

		else
			result[#result + 1] = c
			i = i + 1
		end
	end

	return table.concat(result)
end

--- Encode a single line: convert non-ASCII characters (cp > 0x7F)
--- into \uXXXX escapes (uppercase hex). All other characters pass through
--- unchanged.
---@param line string
---@return string
function M.encode_line(line)
	local result = {}
	local i = 1
	local len = #line

	while i <= len do
		local b1 = line:byte(i)
		local cp, sz

		if b1 < 0x80 then
			cp = b1
			sz = 1
		elseif b1 >= 0xC0 and b1 < 0xE0 then
			local b2 = line:byte(i + 1)
			if b2 ~= nil and (b2 & 0xC0) == 0x80 then
				cp = ((b1 & 0x1F) << 6) | (b2 & 0x3F)
				sz = 2
			else
				cp = b1
				sz = 1
			end
		elseif b1 >= 0xE0 and b1 < 0xF0 then
			local b2 = line:byte(i + 1)
			local b3 = line:byte(i + 2)
			if b2 ~= nil and b3 ~= nil
				and (b2 & 0xC0) == 0x80 and (b3 & 0xC0) == 0x80 then
				cp = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
				sz = 3
			else
				cp = b1
				sz = 1
			end
		elseif b1 >= 0xF0 and b1 < 0xF8 then
			local b2 = line:byte(i + 1)
			local b3 = line:byte(i + 2)
			local b4 = line:byte(i + 3)
			if b2 ~= nil and b3 ~= nil and b4 ~= nil
				and (b2 & 0xC0) == 0x80 and (b3 & 0xC0) == 0x80 and (b4 & 0xC0) == 0x80 then
				cp = ((b1 & 0x07) << 18) | ((b2 & 0x3F) << 12)
					| ((b3 & 0x3F) << 6) | (b4 & 0x3F)
				sz = 4
			else
				cp = b1
				sz = 1
			end
		else
			cp = b1
			sz = 1
		end

		if cp > 0x7F then
			if cp < 0x10000 then
				result[#result + 1] = string.format('\\u%04X', cp)
			else
				local c = cp - 0x10000
				local hi = 0xD800 + (c >> 10)
				local lo = 0xDC00 + (c & 0x3FF)
				result[#result + 1] =
					string.format('\\u%04X\\u%04X', hi, lo)
			end
		else
			result[#result + 1] = line:sub(i, i + sz - 1)
		end

		i = i + sz
	end

	return table.concat(result)
end

return M
