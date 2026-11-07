local codec = require('jproperty.codec')

local M = {}

--- Decode \uXXXX escapes in the entire buffer.
--- A single atomic change, undoable with 'u'.
---@param buf number Buffer handle
function M.decode(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for i, line in ipairs(lines) do
		lines[i] = codec.decode_line(line)
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_var(buf, 'java_props_decoded', 1)
end

--- Encode non-ASCII characters (cp > 0x7F) in the entire buffer.
--- A single atomic change, undoable with 'u'.
---@param buf number Buffer handle
function M.encode(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for i, line in ipairs(lines) do
		lines[i] = codec.encode_line(line)
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_var(buf, 'java_props_decoded', 0)
end

--- Toggle between encode and decode.
--- Uses b:java_props_decoded to track state; auto-detects if unset.
---@param buf number Buffer handle
function M.toggle(buf)
	local decoded
	if vim.fn.exists('b:java_props_decoded') == 1 then
		decoded = vim.api.nvim_buf_get_var(buf, 'java_props_decoded') == 1
	else
		-- Auto-detect: look for \uXXXX sequences in the buffer
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local has_unicode_escape = false
		for _, line in ipairs(lines) do
			if line:find('\\u%x%x%x%x', 1) then
				has_unicode_escape = true
				break
			end
		end
		decoded = not has_unicode_escape
	end

	if decoded then
		M.encode(buf)
	else
		M.decode(buf)
	end
end

return M
