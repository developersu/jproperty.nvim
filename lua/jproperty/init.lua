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
end

return M
